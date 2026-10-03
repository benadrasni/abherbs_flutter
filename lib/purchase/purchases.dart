import 'package:abherbs_flutter/data/utils.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class Purchases {
  static bool hasOldVersion = false;
  static bool hasLifetimeSubscription = false;
  static Map<String, PurchaseDetails> purchases = {};

  static bool isPurchased(String productId) {
    return purchases.containsKey(productId);
  }

  static bool isNoAds() {
    return hasOldVersion ||
        purchases.containsKey(productNoAdsAndroid) ||
        purchases.containsKey(productNoAdsIOS);
  }

  /// Free accounts see banners. Remove ads, the old paid app, and a Field
  /// Guide plan (including photo storage) do not.
  static bool showsAds() {
    return !isNoAds() && !isSubscribed();
  }

  static bool isSearch() {
    return hasOldVersion || purchases.containsKey(productSearch);
  }

  static bool isCustomFilter() {
    return hasOldVersion || purchases.containsKey(productCustomFilter);
  }

  /// The offline product, the old paid app, and a lifetime purchase.
  static bool isOffline() {
    return hasOldVersion ||
        hasLifetimeSubscription ||
        purchases.containsKey(productOffline);
  }

  static bool isObservations() {
    return hasOldVersion || purchases.containsKey(productObservations);
  }

  static bool isPhotoSearch() {
    return hasOldVersion || purchases.containsKey(productPhotoSearch);
  }

  static bool isSubscribedMonthly() {
    return purchases.containsKey(subscriptionMonthly);
  }

  static bool isSubscribedYearly() {
    return purchases.containsKey(subscriptionYearly);
  }

  /// Photo storage and the Field Guide plans. The old paid app and a lifetime
  /// purchase are not this plan, and the Field Guide row stays available.
  static bool hasFieldGuide() {
    return isSubscribedMonthly() ||
        isSubscribedYearly() ||
        purchases.containsKey(fieldGuideMonthly) ||
        purchases.containsKey(fieldGuideYearly);
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
