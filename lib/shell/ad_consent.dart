import 'dart:async';

import 'package:abherbs_flutter/shell/guide_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Collects consent before the first ad request.
///
/// The published AdMob GDPR message is Google's CMP. It only produces a
/// Transparency and Consent string when the app asks for it. Outside the EEA,
/// the UK, and Switzerland this completes without a form.
///
/// Returns true when the request failed, so analytics stays on. A shown form
/// returns false and [applyAnalyticsConsent] reads the choice.
Future<bool> gatherAdConsent() async {
  final updated = Completer<void>();
  var failed = false;
  try {
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!updated.isCompleted) updated.complete();
      },
      (_) {
        failed = true;
        if (!updated.isCompleted) updated.complete();
      },
    );
    await updated.future.timeout(const Duration(seconds: 15), onTimeout: () {
      failed = true;
    });
    if (failed) return true;
    await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
    return false;
  } catch (_) {
    return true;
  }
}

/// Writes the ads-consent choice onto Firebase Analytics.
Future<void> applyAnalyticsConsent({
  bool umpFailed = false,
  bool? trackingAuthorized,
}) async {
  if (umpFailed) {
    await GuideAnalytics.applyConsent(
      umpFailed: true,
      trackingAuthorized: trackingAuthorized,
    );
    return;
  }
  try {
    final status = await ConsentInformation.instance.getConsentStatus();
    final canAds = await ConsentInformation.instance.canRequestAds();
    await GuideAnalytics.applyConsent(
      trackingAuthorized: trackingAuthorized,
      consentKnown: status != ConsentStatus.unknown,
      consentRequired:
          status == ConsentStatus.required || status == ConsentStatus.obtained,
      canRequestAds: canAds,
    );
  } catch (error) {
    debugPrint('analytics consent: $error');
    await GuideAnalytics.applyConsent(
      umpFailed: true,
      trackingAuthorized: trackingAuthorized,
    );
  }
}

/// True when the published message requires a way to change the choice.
Future<bool> adPrivacyOptionsRequired() async {
  try {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  } catch (_) {
    return false;
  }
}

Future<void> showAdPrivacyOptions() async {
  final done = Completer<void>();
  ConsentForm.showPrivacyOptionsForm((_) {
    if (!done.isCompleted) done.complete();
  });
  await done.future;
  await applyAnalyticsConsent();
}
