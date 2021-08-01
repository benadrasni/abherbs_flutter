import 'package:abherbs_flutter/utils/utils.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class Purchases {
  static bool hasOldVersion;
  static bool hasLifetimeSubscription;
  static bool isSearchPromotion;
  static DateTime searchPromotionFrom;
  static DateTime searchPromotionTo;
  static bool isObservationPromotion;
  static DateTime observationPromotionFrom;
  static DateTime observationPromotionTo;
  static bool isSearchByPhotoPromotion;
  static DateTime searchByPhotoPromotionFrom;
  static DateTime searchByPhotoPromotionTo;
  static Map<String, PurchaseDetails> purchases = {};

  static bool isPurchased(String productId) {
    return purchases[productId] != null;
  }

  static bool isNoAds() {
    if (purchases[productNoAdsAndroid] != null || purchases[productNoAdsIOS] != null) {
      return true;
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isSearch() {
    if (purchases[productSearch] != null) {
      return true;
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isCustomFilter() {
    if (purchases[productCustomFilter] != null) {
      return true;
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isOffline() {
    if (purchases[productOffline] != null) {
      return true;
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isObservations() {
    if (purchases[productObservations] != null) {
      return true;
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isPhotoSearch() {
    if (purchases[productPhotoSearch] != null) {
      return true;
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isSubscribedMonthly() {
    if (purchases[subscriptionMonthly] != null) {
      return true;
    }
    return false;
  }

  static bool isSubscribedYearly() {
    if (purchases[subscriptionYearly] != null) {
      return true;
    }
    return false;
  }

  static bool isSignNeeded() {
    return isObservations() || isPhotoSearch();
  }

  static bool isSubscribed() {
    return isSubscribedMonthly() || isSubscribedYearly() || (hasLifetimeSubscription != null && hasLifetimeSubscription);
  }

}
