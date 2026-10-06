import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gma_mediation_meta/gma_mediation_meta.dart';

const _channel = MethodChannel('sk.ab.herbs/meta_ads');

/// Tells Meta whether this device allowed tracking.
///
/// Audience Network 6.15 and later reads App Tracking Transparency itself
/// on iOS 17. The app still runs on iOS 16, where the flag has to be set
/// before the first ad request. Referencing [GmaMediationMeta] keeps the
/// iOS adapter linked into the build.
Future<void> setMetaAdvertiserTracking(bool enabled) async {
  GmaMediationMeta();
  if (!Platform.isIOS) return;
  try {
    await _channel.invokeMethod<void>('setAdvertiserTracking', enabled);
  } catch (_) {}
}
