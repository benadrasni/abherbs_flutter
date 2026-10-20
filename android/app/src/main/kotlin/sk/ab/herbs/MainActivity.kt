package sk.ab.herbs

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        val kept = retainedEngine ?: return null
        retainedEngine = null
        return kept
    }

    override fun shouldDestroyEngineWithHost(): Boolean {
        // A configuration change builds a new activity. The open pick still
        // has a listener on this engine, so the engine has to move with it.
        if (isChangingConfigurations && pickInFlight) return false
        return super.shouldDestroyEngineWithHost()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // A new engine cannot answer the previous pick. Drop that reply so
        // the next pick is not stuck reporting busy.
        if (pickerMessenger != null && pickerMessenger !== messenger) {
            pickerResult = null
            pickerMessenger = null
            pickInFlight = false
        }
        MethodChannel(messenger, "sk.ab.herbs/photo")
            .setMethodCallHandler { call, result ->
                if (call.method != "pick") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pickerResult != null) {
                    result.error("busy", "photo picker already open", null)
                    return@setMethodCallHandler
                }
                val width = call.argument<Number>("maxWidth")?.toInt() ?: 0
                val intent = Intent(MediaStore.ACTION_PICK_IMAGES)
                    .setType("image/*")
                    .putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, 1)
                // API 37.1 name. This compile SDK has no constant for it yet.
                // The photo picker reads the string and asks whether to keep
                // location. The person's choice is final.
                intent.putExtra(
                    "android.provider.extra.REQUEST_LOCATION_METADATA_ACCESS",
                    true,
                )
                pickerResult = result
                pickerMaxWidth = width
                pickerMessenger = messenger
                pickInFlight = true
                try {
                    // FlutterActivity is not a ComponentActivity, so the
                    // activity-result registry is not available.
                    @Suppress("DEPRECATION")
                    startActivityForResult(intent, requestPick)
                } catch (error: Exception) {
                    // resolveActivity is the wrong probe: from API 30 the
                    // photo picker is hidden from package queries, so it
                    // looks missing on phones that have it.
                    pickerResult = null
                    pickerMessenger = null
                    pickInFlight = false
                    if (error is ActivityNotFoundException) {
                        result.error("unavailable", "photo picker missing", null)
                    } else {
                        Log.e("GuideGalleryPick", "launch failed", error)
                        result.error("failed", error.message, null)
                    }
                }
            }
    }

    private fun pickedUri(data: Intent?): Uri? {
        data?.data?.let { return it }
        val clip = data?.clipData ?: return null
        if (clip.itemCount == 0) return null
        return clip.getItemAt(0).uri
    }

    @Deprecated("FlutterActivity is not a ComponentActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == requestPick) {
            finishPick(resultCode, pickedUri(data))
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun finishPick(resultCode: Int, uri: Uri?) {
        val pending = pickerResult ?: return
        pickerResult = null
        pickerMessenger = null
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pickInFlight = false
            pending.success(null)
            return
        }
        val maxWidth = pickerMaxWidth
        val app = applicationContext
        Thread {
            val path = try {
                GuideGalleryPick.save(app, uri, maxWidth)
            } catch (error: Exception) {
                Log.e("GuideGalleryPick", "save failed", error)
                null
            }
            runOnUiThread {
                pickInFlight = false
                try {
                    // The activity may already have been recreated. The reply
                    // belongs to the engine, which was kept for that change.
                    pending.success(path)
                } catch (error: Exception) {
                    Log.e("GuideGalleryPick", "result failed", error)
                }
            }
        }.start()
    }

    override fun onDestroy() {
        if (isChangingConfigurations && pickInFlight) {
            retainedEngine = flutterEngine
        } else if (isFinishing) {
            // The person left. Answer the waiting call so the next pick can open.
            val pending = pickerResult
            pickerResult = null
            pickerMessenger = null
            pickInFlight = false
            try {
                pending?.success(null)
            } catch (error: Exception) {
                Log.e("GuideGalleryPick", "result failed", error)
            }
        }
        super.onDestroy()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Before the Flutter view is attached. Android 15+ already forces
        // edge-to-edge; this makes Android 14 and earlier match without the
        // deprecated bar-color setters or the short-edges cutout mode.
        enableGuideEdgeToEdge()
        super.onCreate(savedInstanceState)
        applyGuideOrientation()
    }

    private fun enableGuideEdgeToEdge() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Turns off the contrast scrim. These still have an effect, and
            // Play's edge-to-edge scan does not list them. The color setters do.
            @Suppress("DEPRECATION")
            window.isStatusBarContrastEnforced = false
            @Suppress("DEPRECATION")
            window.isNavigationBarContrastEnforced = false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val params = window.attributes
            if (params.layoutInDisplayCutoutMode !=
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
            ) {
                params.layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                window.attributes = params
            }
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        applyGuideOrientation()
    }

    // Phones stay portrait. Android 16 still honors that below sw600dp.
    // A large screen (guide_allow_rotation) is left on FULL_USER, which is not
    // one of the portrait or landscape locks Android 16 ignores, so the window
    // can rotate, including upside down, and resize with the display.
    private fun applyGuideOrientation() {
        val target = if (resources.getBoolean(R.bool.guide_allow_rotation)) {
            ActivityInfo.SCREEN_ORIENTATION_FULL_USER
        } else {
            ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        }
        if (requestedOrientation != target) {
            requestedOrientation = target
        }
    }

    companion object {
        private const val requestPick = 48121

        // The result is delivered to whichever instance is resumed. A
        // configuration change builds a new activity; the reply and the
        // engine move with the process, not with the instance.
        private var pickerResult: MethodChannel.Result? = null
        private var pickerMaxWidth = 0
        private var pickerMessenger: BinaryMessenger? = null
        private var pickInFlight = false
        private var retainedEngine: FlutterEngine? = null
    }
}
