package sk.ab.herbs

import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyGuideOrientation()
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
