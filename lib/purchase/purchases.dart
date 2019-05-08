import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
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
  static List<PurchasedItem> purchasesOld = <PurchasedItem>[];
  static List<PurchaseDetails> purchases = [];
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
    for (var purchase in purchasesOld) {
      if (purchase.productId == productId) {
        return true;
      }
    }
    return false;
  }

  static bool isNoAds() {
    for (PurchaseDetails product in purchases) {
      if (product.productID == productNoAdsAndroid ||
          product.productID == productNoAdsIOS) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isSearch() {
    for (PurchaseDetails product in purchases) {
      if (product.productID == productSearch) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isCustomFilter() {
    for (PurchaseDetails product in purchases) {
      if (product.productID == productCustomFilter) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isOffline() {
    for (PurchaseDetails product in purchases) {
      if (product.productID == productOffline) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isObservations() {
    for (PurchaseDetails product in purchases) {
      if (product.productID == productObservations) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isPhotoSearch() {
    for (PurchaseDetails product in purchases) {
      if (product.productID == productPhotoSearch) {
        return true;
      }
    }
    return hasOldVersion != null && hasOldVersion;
  }

  static bool isSubscribedMonthly() {
    for (PurchaseDetails product in purchases) {
      if (product.productID == subscriptionMonthly) {
        return true;
      }
    }
    return false;
  }

  static bool isSubscribedYearly() {
    for (PurchaseDetails product in purchases) {
      if (product.productID == subscriptionYearly) {
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
