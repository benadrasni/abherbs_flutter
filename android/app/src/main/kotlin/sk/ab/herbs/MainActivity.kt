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

    // The manifest keeps a phone in portrait. A large screen (guide_allow_rotation)
    // follows the user, including upside down, so the window size changes and the
    // guide can leave the portrait tablet layout for the landscape rail.
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
