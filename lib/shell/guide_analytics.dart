import 'package:abherbs_flutter/data/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Where a plant page was opened. Values are analytics parameters.
class GuidePlantSource {
  static const search = 'search';
  static const key = 'key';
  static const list = 'list';
  static const photo = 'photo';
  static const notification = 'notification';
  static const link = 'link';
  static const favorite = 'favorite';
  static const seen = 'seen';
  static const outside = 'outside';
}

/// Find, Book, and Seen stay on one route, so each tab is its own screen.
const guideAnalyticsTabFind = 'Find';
const guideAnalyticsTabBook = 'Book';
const guideAnalyticsTabSeen = 'Seen';

String guideAnalyticsTab(int index) {
  switch (index) {
    case 1:
      return guideAnalyticsTabBook;
    case 2:
      return guideAnalyticsTabSeen;
    default:
      return guideAnalyticsTabFind;
  }
}

/// Consent to send to Firebase after the ads form and the tracking prompt.
class GuideAnalyticsConsent {
  final bool analyticsStorage;
  final bool adStorage;
  final bool adUserData;
  final bool adPersonalization;

  const GuideAnalyticsConsent({
    required this.analyticsStorage,
    required this.adStorage,
    required this.adUserData,
    required this.adPersonalization,
  });
}

/// A failed consent request leaves collection on. A required choice that
/// was refused or not given denies storage. Ad personalization also needs
/// permission to track.
GuideAnalyticsConsent guideAnalyticsConsent({
  required bool umpFailed,
  required bool consentKnown,
  required bool consentRequired,
  required bool canRequestAds,
  required bool trackingAuthorized,
}) {
  final storage =
      umpFailed || (consentKnown && (!consentRequired || canRequestAds));
  final ads = storage && trackingAuthorized;
  return GuideAnalyticsConsent(
    analyticsStorage: storage,
    adStorage: storage,
    adUserData: ads,
    adPersonalization: ads,
  );
}

/// Last segment of a list path, safe to put in a screen name.
///
/// `lists_custom/2026-10-15/list` becomes `2026-10-15`. An account path is
/// not used: favorites pass `favorites` themselves.
String guideAnalyticsListId(String raw) {
  var value = raw.trim();
  if (value.startsWith('/')) value = value.substring(1);
  const suffix = '/list';
  if (value.endsWith(suffix)) {
    value = value.substring(0, value.length - suffix.length);
  }
  final parts = value.split('/').where((part) => part.isNotEmpty);
  final last = parts.isEmpty ? '' : parts.last;
  final safe = last.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  if (safe.isEmpty) return '';
  return safe.length <= 40 ? safe : safe.substring(0, 40);
}

/// `GuideCustom` is one route for every editorial list. The list id is the
/// route argument, and the screen name keeps both.
String? guideAnalyticsScreenName(
  String? routeName,
  Object? arguments, {
  String customName = 'GuideCustom',
}) {
  if (routeName == customName && arguments is String) {
    final id = arguments.trim();
    if (id.isNotEmpty) return '$customName/$id';
  }
  return routeName;
}

String? guideAnalyticsText(String? value, {int max = 100}) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
}

String guideAnalyticsAuthMethod(String providerId) {
  switch (providerId) {
    case 'google.com':
      return 'google';
    case 'apple.com':
      return 'apple';
    case 'password':
      return 'email';
    case 'phone':
      return 'phone';
    default:
      return 'other';
  }
}

String guideAnalyticsProductCategory(String productId) {
  switch (productId) {
    case fieldGuideMonthly:
    case fieldGuideYearly:
    case subscriptionMonthly:
    case subscriptionYearly:
      return 'subscription';
    case productNoAdsAndroid:
    case productNoAdsIOS:
      return 'no_ads';
    case productOffline:
      return 'offline';
    case productObservations:
      return 'observations';
    case productPhotoSearch:
      return 'photo_search';
    default:
      return 'other';
  }
}

String guideAnalyticsOfflineScope({
  required bool everything,
  required int regions,
  bool update = false,
}) {
  if (update) return 'update';
  if (everything) return 'everything';
  if (regions < 0) return '0';
  return '$regions';
}

/// Firebase Analytics for the field guide.
///
/// Debug builds send nothing. A debug install also turns collection off,
/// because that switch is stored on the phone and would otherwise keep a
/// later release build quiet. Release builds deny storage until the consent
/// form returns, then [applyConsent] sets the choice.
class GuideAnalytics {
  static bool _trackingAuthorized = false;

  static Future<void> start() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final analytics = FirebaseAnalytics.instance;
      if (kDebugMode) {
        await analytics.setAnalyticsCollectionEnabled(false);
        return;
      }
      await analytics.setAnalyticsCollectionEnabled(true);
      await _consent(
          analytics,
          const GuideAnalyticsConsent(
            analyticsStorage: false,
            adStorage: false,
            adUserData: false,
            adPersonalization: false,
          ));
    } catch (error) {
      debugPrint('analytics: $error');
    }
  }

  static Future<void> applyConsent({
    bool umpFailed = false,
    bool? trackingAuthorized,
    bool consentKnown = false,
    bool consentRequired = false,
    bool canRequestAds = false,
  }) async {
    if (trackingAuthorized != null) _trackingAuthorized = trackingAuthorized;
    if (kDebugMode || Firebase.apps.isEmpty) return;
    try {
      await _consent(
        FirebaseAnalytics.instance,
        guideAnalyticsConsent(
          umpFailed: umpFailed,
          consentKnown: consentKnown,
          consentRequired: consentRequired,
          canRequestAds: canRequestAds,
          trackingAuthorized: _trackingAuthorized,
        ),
      );
    } catch (error) {
      debugPrint('analytics: $error');
    }
  }

  static Future<void> _consent(
    FirebaseAnalytics analytics,
    GuideAnalyticsConsent consent,
  ) {
    return analytics.setConsent(
      analyticsStorageConsentGranted: consent.analyticsStorage,
      adStorageConsentGranted: consent.adStorage,
      adUserDataConsentGranted: consent.adUserData,
      adPersonalizationSignalsConsentGranted: consent.adPersonalization,
    );
  }

  static Future<void> screen(String name) {
    final clean = guideAnalyticsText(name, max: 100);
    if (clean == null) return Future<void>.value();
    return _run((analytics) => analytics.logScreenView(screenName: clean));
  }

  static Future<void> plant(String name, {String source = ''}) {
    return _event('select_content', {
      'content_type': 'plant',
      'item_id': guideAnalyticsText(name),
      'source': guideAnalyticsText(source, max: 24),
    });
  }

  static Future<void> searchPhoto({
    required String source,
    required String outcome,
    bool counted = false,
  }) {
    return _event('search_photo', {
      'source': guideAnalyticsText(source, max: 24),
      'outcome': guideAnalyticsText(outcome, max: 24),
      if (counted) 'counted': 'true',
    });
  }

  static Future<void> search({
    required String term,
    required int resultCount,
  }) {
    final clean = guideAnalyticsText(term);
    if (clean == null) return Future<void>.value();
    return _event('search', {
      'search_term': clean,
      'result_count': resultCount < 0 ? 0 : resultCount,
    });
  }

  static Future<void> filterResult({
    required String color,
    required String habitat,
    required String petal,
    required int count,
  }) {
    return _event('filter_result', {
      'color': guideAnalyticsText(color, max: 40),
      'habitat': guideAnalyticsText(habitat.isEmpty ? 'any' : habitat, max: 40),
      'petal': guideAnalyticsText(petal, max: 40),
      'count': count < 0 ? 0 : count,
    });
  }

  static Future<void> language(String tag) {
    return _event('setting', {
      'type': 'preferred_language',
      'language': guideAnalyticsText(tag.isEmpty ? 'default' : tag, max: 36),
    });
  }

  static Future<void> setLanguage(String code) {
    final clean = guideAnalyticsText(code.toLowerCase(), max: 8);
    if (clean == null) return Future<void>.value();
    return _run(
      (analytics) => analytics.setUserProperty(name: 'language', value: clean),
    );
  }

  static Future<void> login(String method, {String? userId}) {
    return _run((analytics) async {
      final id = guideAnalyticsText(userId, max: 256);
      if (id != null) await analytics.setUserId(id: id);
      await analytics.logLogin(loginMethod: method);
    });
  }

  static Future<void> signUp(String method, {String? userId}) {
    return _run((analytics) async {
      final id = guideAnalyticsText(userId, max: 256);
      if (id != null) await analytics.setUserId(id: id);
      await analytics.logSignUp(signUpMethod: method);
    });
  }

  /// A null [userId] clears the id. Null properties clear those properties.
  static Future<void> syncAccount({
    String? userId,
    String? account,
    String? plan,
    String? ads,
    bool? legacyPaid,
  }) {
    return _run((analytics) async {
      await analytics.setUserId(id: guideAnalyticsText(userId, max: 256));
      await analytics.setUserProperty(
        name: 'account',
        value: guideAnalyticsText(account, max: 24),
      );
      await analytics.setUserProperty(
        name: 'plan',
        value: guideAnalyticsText(plan, max: 24),
      );
      await analytics.setUserProperty(
        name: 'ads',
        value: guideAnalyticsText(ads, max: 24),
      );
      await analytics.setUserProperty(
        name: 'legacy_paid',
        value: legacyPaid == null ? null : (legacyPaid ? 'true' : 'false'),
      );
    });
  }

  static Future<void> purchase(String productId) {
    final id = guideAnalyticsText(productId);
    if (id == null) return Future<void>.value();
    final category = guideAnalyticsProductCategory(id);
    return _run((analytics) => analytics.logPurchase(
          items: [
            AnalyticsEventItem(
              itemId: id,
              itemName: id,
              itemCategory: category,
            ),
          ],
          parameters: const {'confirmed': 'true'},
        ));
  }

  static Future<void> purchaseFailed(
      {String? productId, required String reason}) {
    return _event('purchase_failed', {
      'product_id': guideAnalyticsText(productId),
      'reason': guideAnalyticsText(reason, max: 24),
    });
  }

  static Future<void> offlinePack({
    required String scope,
    required String result,
  }) {
    return _event('offline_pack', {
      'scope': guideAnalyticsText(scope, max: 24),
      'result': guideAnalyticsText(result, max: 24),
    });
  }

  static Future<void> seenSave({required String source, required bool shared}) {
    return _event('seen_save', {
      'source': guideAnalyticsText(source, max: 24),
      'shared': shared ? 'true' : 'false',
    });
  }

  static Future<void> favorite({required bool on}) {
    return _event('favorite', {'action': on ? 'add' : 'remove'});
  }

  static Future<void> notificationOpen({
    required String action,
    required bool accepted,
  }) {
    return _event('notification_open', {
      'action': guideAnalyticsText(action, max: 24),
      'accepted': accepted ? 'true' : 'false',
    });
  }

  static Future<void> viewItem(List<String> productIds) {
    final items = <AnalyticsEventItem>[];
    for (final productId in productIds) {
      final id = guideAnalyticsText(productId);
      if (id == null) continue;
      items.add(AnalyticsEventItem(
        itemId: id,
        itemName: id,
        itemCategory: guideAnalyticsProductCategory(id),
      ));
    }
    if (items.isEmpty) return Future<void>.value();
    return _run((analytics) => analytics.logViewItem(items: items));
  }

  static Future<void> adReward({required bool earned}) {
    return _event('ad_reward', {'result': earned ? 'earned' : 'dismissed'});
  }

  static Future<void> _event(String name, Map<String, Object?> parameters) {
    return _run((analytics) => analytics.logEvent(
          name: name,
          parameters: _parameters(parameters),
        ));
  }

  static Map<String, Object> _parameters(Map<String, Object?> raw) {
    final out = <String, Object>{};
    raw.forEach((key, value) {
      if (value == null) return;
      if (value is String) {
        final text = guideAnalyticsText(value);
        if (text == null) return;
        out[key] = text;
      } else if (value is num) {
        out[key] = value;
      }
    });
    return out;
  }

  static Future<void> _run(
    Future<void> Function(FirebaseAnalytics analytics) write,
  ) async {
    if (kDebugMode || Firebase.apps.isEmpty) return;
    try {
      await write(FirebaseAnalytics.instance);
    } catch (error) {
      debugPrint('analytics: $error');
    }
  }
}
