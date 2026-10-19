package sk.ab.herbs

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.exifinterface.media.ExifInterface
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import kotlin.math.max
import kotlin.math.roundToInt

/// Copies a photo-picker item into the cache. A JPEG that already fits is
/// kept byte for byte, so its GPS stays. Anything scaled or transcoded gets
/// the place and date tags written back onto the JPEG.
object GuideGalleryPick {
    private val placeTags = arrayOf(
        ExifInterface.TAG_GPS_LATITUDE,
        ExifInterface.TAG_GPS_LATITUDE_REF,
        ExifInterface.TAG_GPS_LONGITUDE,
        ExifInterface.TAG_GPS_LONGITUDE_REF,
        ExifInterface.TAG_GPS_ALTITUDE,
        ExifInterface.TAG_GPS_ALTITUDE_REF,
        ExifInterface.TAG_DATETIME,
        ExifInterface.TAG_DATETIME_ORIGINAL,
        ExifInterface.TAG_ORIENTATION,
    )

    fun save(context: Context, uri: Uri, maxWidth: Int): String? {
        val dir = File(context.cacheDir, "guide-pick").apply { mkdirs() }
        val extension = extensionOf(context, uri)
        val original = File(dir, "${UUID.randomUUID()}.$extension")
        context.contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(original).use { output -> input.copyTo(output) }
        } ?: return null
        if (!original.exists() || original.length() == 0L) {
            original.delete()
            return null
        }
        // Magic bytes, not the mime extension. A JPEG that already fits is
        // returned unchanged so its GPS rationals stay exact.
        val tooWide = maxWidth > 0 && widthOf(original) > maxWidth
        if (isJpeg(original) && !tooWide) return original.absolutePath
        val scaled = transcode(original, maxWidth) ?: return original.absolutePath
        copyPlace(original, scaled)
        original.delete()
        return scaled.absolutePath
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

    private fun widthOf(file: File): Int {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.absolutePath, bounds)
        return bounds.outWidth
    }

    private fun transcode(original: File, maxWidth: Int): File? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(original.absolutePath, bounds)
        val width = bounds.outWidth
        val height = bounds.outHeight
        if (width <= 0 || height <= 0) return null
        val sample = sampleSize(width, maxWidth)
        val decoded = BitmapFactory.decodeFile(
            original.absolutePath,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return null
        val target = scaleToWidth(decoded, maxWidth)
        val out = File(original.parentFile, "${UUID.randomUUID()}.jpg")
        try {
            FileOutputStream(out).use { stream ->
                if (!target.compress(Bitmap.CompressFormat.JPEG, 92, stream)) {
                    out.delete()
                    return null
                }
            }
        } finally {
            if (target != decoded) target.recycle()
            decoded.recycle()
        }
        return out
    }

    private fun sampleSize(width: Int, maxWidth: Int): Int {
        if (maxWidth <= 0 || width <= maxWidth) return 1
        var sample = 1
        while (width / (sample * 2) > maxWidth) sample *= 2
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
            dest.saveAttributes()
        } catch (_: Exception) {
        }
    }
}
