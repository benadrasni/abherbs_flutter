import 'package:abherbs_flutter/utils/utils.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class Purchases {
  static bool hasOldVersion = false;
  static bool hasLifetimeSubscription = false;
  static bool isSearchPromotion = false;
  static DateTime searchPromotionFrom = DateTime.now();
  static DateTime searchPromotionTo = DateTime.now();
  static bool isObservationPromotion = false;
  static DateTime observationPromotionFrom = DateTime.now();
  static DateTime observationPromotionTo = DateTime.now();
  static bool isSearchByPhotoPromotion = false;
  static DateTime searchByPhotoPromotionFrom = DateTime.now();
  static DateTime searchByPhotoPromotionTo = DateTime.now();
  static Map<String, PurchaseDetails> purchases = {};

  static bool isPurchased(String productId) {
    return purchases.containsKey(productId);
  }

  static bool isNoAds() {
    return hasOldVersion || purchases.containsKey(productNoAdsAndroid) || purchases.containsKey(productNoAdsIOS);
  }

  static bool isSearch() {
    return hasOldVersion || purchases.containsKey(productSearch);
  }

  static bool isCustomFilter() {
    return hasOldVersion || purchases.containsKey(productCustomFilter);
  }

  static bool isOffline() {
    return hasOldVersion || purchases.containsKey(productOffline);
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

  static bool isSignNeeded() {
    return isObservations() || isPhotoSearch();
  }

  static bool isSubscribed() {
    return hasLifetimeSubscription || isSubscribedMonthly() || isSubscribedYearly();
  }

}
