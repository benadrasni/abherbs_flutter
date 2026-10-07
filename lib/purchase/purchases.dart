import 'package:abherbs_flutter/data/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class Purchases {
  static bool hasOldVersion = false;
  static bool hasLifetimeSubscription = false;
  static Map<String, PurchaseDetails> purchases = {};

  /// Product ids a checked receipt granted to the signed-in account.
  /// Cleared on sign-out. Store purchases stay in [purchases].
  static final Set<String> accountProducts = <String>{};

  static bool owns(String productId) {
    return purchases.containsKey(productId) || accountProducts.contains(productId);
  }

  static void replaceAccountProducts(Set<String> ids) {
    if (accountProducts.length == ids.length && accountProducts.containsAll(ids)) {
      return;
    }
    accountProducts
      ..clear()
      ..addAll(ids);
    if (namesReady) namesRevision.value++;
  }

  static void clearAccountProducts() {
    replaceAccountProducts(<String>{});
  }

  /// Photo-name entitlements from the last account read. Device prefs can
  /// still say the old paid app or a lifetime purchase after a reinstall,
  /// and Find must not treat those as this account until [namesReady].
  static bool namesReady = false;
  static String? _namesUid;
  static final ValueNotifier<int> namesRevision = ValueNotifier(0);

  /// The signed-in account changed. Keep the monthly meter until its record
  /// is read. The same account refreshing its token does not flash.
  static void holdNamesFor(String? uid) {
    if (_namesUid == uid) return;
    _namesUid = uid;
    namesReady = false;
    namesRevision.value++;
  }

  /// The account record has been applied. Find and Person both listen.
  static void finishNames() {
    namesReady = true;
    namesRevision.value++;
  }

  /// Unlimited photo names for the meter. False until [finishNames].
  static bool get namesUnlimited {
    if (!namesReady) return false;
    return isPhotoSearch() || hasLifetimeSubscription;
  }

  /// Field Guide for the meter. False until [finishNames].
  static bool get namesFieldGuide {
    if (!namesReady) return false;
    return hasFieldGuide();
  }

  static bool isNoAds() {
    return hasOldVersion ||
        owns(productNoAdsAndroid) ||
        owns(productNoAdsIOS);
  }

  /// Free accounts see banners. Remove ads, the old paid app, and a Field
  /// Guide plan (including photo storage) do not.
  static bool showsAds() {
    return !isNoAds() && !isSubscribed();
  }

  static bool isSearch() {
    return hasOldVersion || owns(productSearch);
  }

  /// The offline product, the old paid app, and a lifetime purchase.
  static bool isOffline() {
    return hasOldVersion || hasLifetimeSubscription || owns(productOffline);
  }

  static bool isPhotoSearch() {
    return hasOldVersion || owns(productPhotoSearch);
  }

  static bool isSubscribedMonthly() {
    return owns(subscriptionMonthly);
  }

  static bool isSubscribedYearly() {
    return owns(subscriptionYearly);
  }

  /// Photo storage and the Field Guide plans. The old paid app and a lifetime
  /// purchase are not this plan, and the Field Guide row stays available.
  static bool hasFieldGuide() {
    return isSubscribedMonthly() ||
        isSubscribedYearly() ||
        owns(fieldGuideMonthly) ||
        owns(fieldGuideYearly);
  }

  /// Field Guide bought from the store on this phone, so a plan change can
  /// replace it. A plan that arrived from the account cannot.
  static bool get fieldGuideOnThisStore {
    return purchases.containsKey(subscriptionMonthly) ||
        purchases.containsKey(subscriptionYearly) ||
        purchases.containsKey(fieldGuideMonthly) ||
        purchases.containsKey(fieldGuideYearly);
  }

  static bool get fieldGuideFromAccountOnly {
    return hasFieldGuide() && !fieldGuideOnThisStore;
  }

  /// Copies Seen photos to the account. Field Guide, the old paid app, and a
  /// lifetime purchase.
  static bool syncsSeenPhotos() {
    return hasFieldGuide() || hasOldVersion || hasLifetimeSubscription;
  }

  static bool isSubscribed() {
    return hasLifetimeSubscription || hasFieldGuide();
  }
}

/// The person dismissed the store sheet. That is not a failed purchase, and
/// it must not drop a plan this phone already owns.
bool storePurchaseCanceled(PurchaseDetails purchase) {
  if (purchase.status == PurchaseStatus.canceled) return true;
  final code = purchase.error?.code.toLowerCase() ?? '';
  if (code.isEmpty) return false;
  return code == '2' ||
      code == '15' ||
      code == 'paymentcancelled' ||
      code == 'skerrorpaymentcancelled' ||
      code == 'skerroroverlaycancelled' ||
      code.contains('user_cancell') ||
      code.contains('usercancell');
}
