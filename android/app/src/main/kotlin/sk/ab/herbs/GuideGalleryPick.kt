package sk.ab.herbs

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import android.util.Log
import android.webkit.MimeTypeMap
import androidx.exifinterface.media.ExifInterface
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import kotlin.math.max
import kotlin.math.roundToInt

/// Copies a photo-picker item into the cache and bakes its orientation into
/// the pixels. Flutter draws a file as stored, so a sensor orientation tag
/// would show the photo sideways and send those sideways bytes on.
/// A JPEG that already fits and is already upright is kept byte for byte,
/// so its GPS stays until the observation has read it. A rewritten JPEG
/// keeps the place and date, and the orientation tag is set back to normal.
/// A photo that cannot be re-encoded is kept for that same read. Nothing
/// uploads those bytes unless the location metadata comes off.
object GuideGalleryPick {
    private const val maxDecodedPixels = 8_000_000L
    private val placeTags = arrayOf(
        ExifInterface.TAG_GPS_LATITUDE,
        ExifInterface.TAG_GPS_LATITUDE_REF,
        ExifInterface.TAG_GPS_LONGITUDE,
        ExifInterface.TAG_GPS_LONGITUDE_REF,
        ExifInterface.TAG_GPS_ALTITUDE,
        ExifInterface.TAG_GPS_ALTITUDE_REF,
        ExifInterface.TAG_DATETIME,
        ExifInterface.TAG_DATETIME_ORIGINAL,
    )

    fun save(context: Context, uri: Uri, maxWidth: Int): String? {
        val dir = File(context.cacheDir, "guide-pick").apply { mkdirs() }
        val extension = extensionOf(context, uri)
        val original = File(dir, "${UUID.randomUUID()}.$extension")
        var scaled: File? = null
        try {
            context.contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(original).use { output -> input.copyTo(output) }
            } ?: return abandon(original, null)
            if (!original.exists() || original.length() == 0L) {
                return abandon(original, null)
            }
            val orientation = readOrientation(original)
            val bounds = boundsOf(original)
            val uprightWidth =
                displayedWidth(bounds.outWidth, bounds.outHeight, orientation)
            val tooWide = maxWidth > 0 && uprightWidth > maxWidth
            if (isJpeg(original) && !tooWide && !needsTurn(orientation)) {
                return original.absolutePath
            }
            val written = transcode(original, maxWidth, orientation)
            if (written == null) return original.absolutePath
            scaled = written
            copyPlace(original, written)
            original.delete()
            return written.absolutePath
        } catch (error: Throwable) {
            Log.e("GuideGalleryPick", "save failed", error)
            original.delete()
            scaled?.delete()
            return null
        }
    }

    private fun abandon(original: File, scaled: File?): String? {
        original.delete()
        scaled?.delete()
        return null
    }

    private fun extensionOf(context: Context, uri: Uri): String {
        val mime = context.contentResolver.getType(uri)
        val mapped = MimeTypeMap.getSingleton().getExtensionFromMimeType(mime)
        return if (mapped.isNullOrEmpty()) "jpg" else mapped.lowercase()
    }

    private fun isJpeg(file: File): Boolean {
        file.inputStream().use { input ->
            val header = ByteArray(3)
            if (input.read(header) != 3) return false
            return header[0] == 0xFF.toByte() &&
                header[1] == 0xD8.toByte() &&
                header[2] == 0xFF.toByte()
        }
    }

    private fun boundsOf(file: File): BitmapFactory.Options {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.absolutePath, bounds)
        return bounds
    }

    private fun readOrientation(file: File): Int {
        return try {
            ExifInterface(file.absolutePath).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        } catch (_: Throwable) {
            ExifInterface.ORIENTATION_NORMAL
        }
    }

    private fun needsTurn(orientation: Int): Boolean {
        return when (orientation) {
            ExifInterface.ORIENTATION_UNDEFINED,
            ExifInterface.ORIENTATION_NORMAL,
            -> false
            else -> true
        }
    }

    private fun swapsAxes(orientation: Int): Boolean {
        return when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90,
            ExifInterface.ORIENTATION_ROTATE_270,
            ExifInterface.ORIENTATION_TRANSPOSE,
            ExifInterface.ORIENTATION_TRANSVERSE,
            -> true
            else -> false
        }
    }

    private fun displayedWidth(width: Int, height: Int, orientation: Int): Int {
        if (width <= 0 || height <= 0) return 0
        return if (swapsAxes(orientation)) height else width
    }

    private fun transcode(original: File, maxWidth: Int, orientation: Int): File? {
        val bounds = boundsOf(original)
        val width = bounds.outWidth
        val height = bounds.outHeight
        if (width <= 0 || height <= 0) return null
        val sample = sampleSize(
            width,
            height,
            displayedWidth(width, height, orientation),
            maxWidth,
        )
        val decoded = BitmapFactory.decodeFile(
            original.absolutePath,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return null
        val upright = applyOrientation(decoded, orientation)
        val target = scaleToWidth(upright, maxWidth)
        val out = File(original.parentFile, "${UUID.randomUUID()}.jpg")
        try {
            FileOutputStream(out).use { stream ->
                if (!target.compress(Bitmap.CompressFormat.JPEG, 92, stream)) {
                    out.delete()
                    return null
                }
            }
            return out
        } catch (error: Throwable) {
            out.delete()
            throw error
        } finally {
            if (target !== upright) target.recycle()
            if (upright !== decoded) upright.recycle()
            decoded.recycle()
        }
    }

    /// EXIF orientation, applied in the order the tag describes.
    private fun applyOrientation(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> {
                matrix.setRotate(180f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.setRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.setRotate(-90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
            else -> return bitmap
        }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    /// Power-of-two [BitmapFactory.Options.inSampleSize]. The decoded bitmap
    /// stays near [maxWidth] and under [maxDecodedPixels], so a large photo
    /// does not throw [OutOfMemoryError] on the way to the picker result.
    private fun sampleSize(width: Int, height: Int, displayed: Int, maxWidth: Int): Int {
        if (width <= 0 || height <= 0) return 1
        var sample = 1
        val target = if (maxWidth > 0) maxWidth else 2048
        val along = if (maxWidth > 0) displayed else max(width, height)
        if (along > target) {
            while (sample < 128 && along / (sample * 2) > target) sample *= 2
        }
        while (sample < 128 &&
            (width.toLong() / sample) * (height.toLong() / sample) > maxDecodedPixels
        ) {
            sample *= 2
        }
        return sample
    }

    private fun scaleToWidth(bitmap: Bitmap, maxWidth: Int): Bitmap {
        if (maxWidth <= 0 || bitmap.width <= maxWidth) return bitmap
        val height = max(1, (bitmap.height * (maxWidth.toDouble() / bitmap.width)).roundToInt())
        return Bitmap.createScaledBitmap(bitmap, maxWidth, height, true)
    }

    private fun copyPlace(from: File, to: File) {
        try {
            val source = ExifInterface(from.absolutePath)
            val dest = ExifInterface(to.absolutePath)
            for (tag in placeTags) {
                val value = source.getAttribute(tag) ?: continue
                dest.setAttribute(tag, value)
            }
            dest.setAttribute(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL.toString(),
            )
            dest.saveAttributes()
        } catch (_: Throwable) {
        }
    }
}
