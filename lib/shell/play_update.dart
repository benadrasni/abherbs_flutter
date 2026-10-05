import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

enum PlayUpdateOutcome { accepted, denied, unavailable }

/// Play's immediate update. A sideload, a debug build, or a missing Play
/// Store comes back [PlayUpdateOutcome.unavailable] so the caller can open
/// the listing instead.
Future<PlayUpdateOutcome> playImmediateUpdate() async {
  if (!Platform.isAndroid) return PlayUpdateOutcome.unavailable;
  try {
    final info = await InAppUpdate.checkForUpdate();
    final available =
        info.updateAvailability == UpdateAvailability.updateAvailable ||
            info.updateAvailability ==
                UpdateAvailability.developerTriggeredUpdateInProgress;
    if (!available || !info.immediateUpdateAllowed) {
      return PlayUpdateOutcome.unavailable;
    }
    final result = await InAppUpdate.performImmediateUpdate();
    if (result == AppUpdateResult.success) return PlayUpdateOutcome.accepted;
    if (result == AppUpdateResult.userDeniedUpdate) {
      return PlayUpdateOutcome.denied;
    }
    return PlayUpdateOutcome.unavailable;
  } catch (error) {
    debugPrint('play update: $error');
    return PlayUpdateOutcome.unavailable;
  }
}
