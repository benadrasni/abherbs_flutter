import 'package:abherbs_flutter/camera/guide_camera.dart';
import 'package:abherbs_flutter/data/guide_data.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:abherbs_flutter/shell/guide_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('consent stays on outside the form and off when the choice is refused',
      () {
    final abroad = guideAnalyticsConsent(
      umpFailed: false,
      consentKnown: true,
      consentRequired: false,
      canRequestAds: true,
      trackingAuthorized: true,
    );
    expect(abroad.analyticsStorage, isTrue);
    expect(abroad.adPersonalization, isTrue);

    final refused = guideAnalyticsConsent(
      umpFailed: false,
      consentKnown: true,
      consentRequired: true,
      canRequestAds: false,
      trackingAuthorized: true,
    );
    expect(refused.analyticsStorage, isFalse);
    expect(refused.adStorage, isFalse);

    final trackingOff = guideAnalyticsConsent(
      umpFailed: false,
      consentKnown: true,
      consentRequired: false,
      canRequestAds: true,
      trackingAuthorized: false,
    );
    expect(trackingOff.analyticsStorage, isTrue);
    expect(trackingOff.adUserData, isFalse);
    expect(trackingOff.adPersonalization, isFalse);

    final unknown = guideAnalyticsConsent(
      umpFailed: false,
      consentKnown: false,
      consentRequired: false,
      canRequestAds: false,
      trackingAuthorized: true,
    );
    expect(unknown.analyticsStorage, isFalse);

    final failed = guideAnalyticsConsent(
      umpFailed: true,
      consentKnown: false,
      consentRequired: false,
      canRequestAds: false,
      trackingAuthorized: false,
    );
    expect(failed.analyticsStorage, isTrue);
    expect(failed.adPersonalization, isFalse);
  });

  test('list ids keep the last safe segment', () {
    expect(guideCustomRouteName, 'GuideCustom');
    expect(
      guideAnalyticsListId('lists_custom/2026-10-15/list'),
      '2026-10-15',
    );
    expect(guideAnalyticsListId('favorites'), 'favorites');
    expect(guideAnalyticsListId('lists custom/blume des jahres'),
        'blumedesjahres');
    expect(guideAnalyticsListId('///'), '');
    expect(
      guideAnalyticsScreenName(guideCustomRouteName, '2026-10-15'),
      'GuideCustom/2026-10-15',
    );
    expect(guideAnalyticsScreenName('GuideSpecies', null), 'GuideSpecies');
    expect(guideAnalyticsScreenName(guideCustomRouteName, ''), 'GuideCustom');
  });

  test('auth methods and product categories stay short', () {
    expect(guideAnalyticsAuthMethod('google.com'), 'google');
    expect(guideAnalyticsAuthMethod('apple.com'), 'apple');
    expect(guideAnalyticsAuthMethod('password'), 'email');
    expect(guideAnalyticsAuthMethod('phone'), 'phone');
    expect(guideAnalyticsAuthMethod('facebook.com'), 'other');
    expect(guideAnalyticsProductCategory(fieldGuideYearly), 'subscription');
    expect(guideAnalyticsProductCategory(productNoAdsIOS), 'no_ads');
    expect(guideAnalyticsProductCategory(productOffline), 'offline');
    expect(guideAnalyticsProductCategory('mystery'), 'other');
  });

  test('offline scope and photo outcomes use the agreed words', () {
    expect(
      guideAnalyticsOfflineScope(everything: true, regions: 4),
      'everything',
    );
    expect(
      guideAnalyticsOfflineScope(everything: false, regions: 3),
      '3',
    );
    expect(
      guideAnalyticsOfflineScope(everything: false, regions: 3, update: true),
      'update',
    );
    expect(guideAnalyticsTab(0), guideAnalyticsTabFind);
    expect(guideAnalyticsTab(1), guideAnalyticsTabBook);
    expect(guideAnalyticsTab(2), guideAnalyticsTabSeen);
    expect(
      guideCameraAnalyticsOutcome(GuideCameraOutcomeKind.notPlant),
      'not_plant',
    );
    expect(
      guideCameraAnalyticsOutcome(GuideCameraOutcomeKind.pausedToday),
      'paused',
    );
    expect(guideAnalyticsText('  Bellis perennis  '), 'Bellis perennis');
    expect(guideAnalyticsText('   '), isNull);
    expect(guideAnalyticsText('abcdef', max: 3), 'abc');
  });
}
