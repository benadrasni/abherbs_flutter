import 'package:abherbs_flutter/data/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class Purchases {
  static bool hasOldVersion = false;

  /// Receipts on this phone, so a plan change can replace one. Not a grant.
  static Map<String, PurchaseDetails> purchases = {};

  /// Product ids a checked receipt granted to the signed-in account.
  /// Cleared on sign-out and when the account changes. The old paid app is
  /// [hasOldVersion], on the feature methods, so it is not Field Guide.
  static final Set<String> accountProducts = <String>{};

  /// A checked product on the signed-in account. [purchases] is not read.
  static bool owns(String productId) {
    return accountProducts.contains(productId);
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
  /// still say the old paid app after a reinstall, and Find must not treat
  /// that as this account until [namesReady].
  static bool namesReady = false;
  static String? _namesUid;
  static final ValueNotifier<int> namesRevision = ValueNotifier(0);

  /// The signed-in account changed. Keep the monthly meter until its record
  /// is read, and drop the previous account's products. The same account
  /// refreshing its token does not flash. Returns whether the account changed.
  static bool holdNamesFor(String? uid) {
    if (_namesUid == uid) return false;
    _namesUid = uid;
    namesReady = false;
    clearAccountProducts();
    namesRevision.value++;
    return true;
  }

  /// The account record could not be read. Drop the previous account
  /// before [finishNames], so its products are not treated as ready.
  static void failedAccountRead() {
    hasOldVersion = false;
    clearAccountProducts();
  }

  /// The account record has been applied. Find and Person both listen.
  static void finishNames() {
    namesReady = true;
    namesRevision.value++;
  }

  /// Unlimited photo names for the meter. False until [finishNames].
  static bool get namesUnlimited {
    if (!namesReady) return false;
    return isPhotoSearch();
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

  /// The offline product and the old paid app.
  static bool isOffline() {
    return hasOldVersion || owns(productOffline);
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

  /// Photo storage and the Field Guide plans. The old paid app is not this
  /// plan, and the Field Guide row stays available.
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

  /// Copies Seen photos to the account. Field Guide, the Observations
  /// purchase, and the old paid app.
  static bool syncsSeenPhotos() {
    return hasFieldGuide() || hasOldVersion || owns(productObservations);
  }

  static bool isSubscribed() {
    return hasFieldGuide();
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
