import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Collects consent before the first ad request.
///
/// The published AdMob GDPR message is Google's CMP. It only produces a
/// Transparency and Consent string when the app asks for it. Outside the EEA,
/// the UK, and Switzerland this completes without a form.
Future<void> gatherAdConsent() async {
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
    if (failed) return;
    await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
  } catch (_) {}
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

Future<void> showAdPrivacyOptions() {
  final done = Completer<void>();
  ConsentForm.showPrivacyOptionsForm((_) {
    if (!done.isCompleted) done.complete();
  });
  return done.future;
}
