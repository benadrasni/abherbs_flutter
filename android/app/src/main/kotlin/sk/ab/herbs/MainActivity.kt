package sk.ab.herbs

import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
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
}
