import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:abherbs_flutter/utils/utils.dart';

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
  static List<PurchasedItem> purchases = <PurchasedItem>[];
  static Map<String, PurchasedItem> offlineProducts = {
    productNoAdsIOS: PurchasedItem.fromJSON({'productId': productNoAdsIOS}),
    productNoAdsAndroid: PurchasedItem.fromJSON({'productId': productNoAdsAndroid}),
    productSearch: PurchasedItem.fromJSON({'productId': productSearch}),
    productCustomFilter: PurchasedItem.fromJSON({'productId': productCustomFilter}),
    productOffline: PurchasedItem.fromJSON({'productId': productOffline}),
    productObservations: PurchasedItem.fromJSON({'productId': productObservations}),
    productPhotoSearch: PurchasedItem.fromJSON({'productId': productPhotoSearch}),
    subscriptionMonthly: PurchasedItem.fromJSON({'productId': subscriptionMonthly}),
    subscriptionYearly: PurchasedItem.fromJSON({'productId': subscriptionYearly}),
  };

  static void initialize() {

  }

  static bool isPurchased(String productId) {
    for (var purchase in purchases) {
      if (purchase.productId == productId) {
        return true;
      }
    }
    return false;
  }

  static bool isNoAds() {
    for (PurchasedItem product in purchases) {
      if (product.productId == productNoAdsAndroid ||
          product.productId == productNoAdsIOS) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isSearch() {
    for (PurchasedItem product in purchases) {
      if (product.productId == productSearch) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isCustomFilter() {
    for (PurchasedItem product in purchases) {
      if (product.productId == productCustomFilter) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isOffline() {
    for (PurchasedItem product in purchases) {
      if (product.productId == productOffline) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isObservations() {
    for (PurchasedItem product in purchases) {
      if (product.productId == productObservations) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isPhotoSearch() {
    for (PurchasedItem product in purchases) {
      if (product.productId == productPhotoSearch) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isSubscribedMonthly() {
    for (PurchasedItem product in purchases) {
      if (product.productId == subscriptionMonthly) {
        return true;
      }
    }
    return false;
  }

  static bool isSubscribedYearly() {
    for (PurchasedItem product in purchases) {
      if (product.productId == subscriptionYearly) {
        return true;
      }
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
