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
  static List<PurchaseDetails> purchases = [];
  static Map<String, PurchaseDetails> offlineProducts = {
    productNoAdsIOS: PurchaseDetails(purchaseID: '', productID: productNoAdsIOS, verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: IAPSource.AppStore), transactionDate: ''),
    productNoAdsAndroid: PurchaseDetails(purchaseID: '', productID: productNoAdsAndroid, verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: IAPSource.AppStore), transactionDate: ''),
    productSearch: PurchaseDetails(purchaseID: '', productID: productSearch, verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: IAPSource.AppStore), transactionDate: ''),
    productCustomFilter: PurchaseDetails(purchaseID: '', productID: productCustomFilter, verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: IAPSource.AppStore), transactionDate: ''),
    productOffline: PurchaseDetails(purchaseID: '', productID: productOffline, verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: IAPSource.AppStore), transactionDate: ''),
    productObservations: PurchaseDetails(purchaseID: '', productID: productObservations, verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: IAPSource.AppStore), transactionDate: ''),
    productPhotoSearch: PurchaseDetails(purchaseID: '', productID: productPhotoSearch, verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: IAPSource.AppStore), transactionDate: ''),
    subscriptionMonthly: PurchaseDetails(purchaseID: '', productID: subscriptionMonthly, verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: IAPSource.AppStore), transactionDate: ''),
    subscriptionYearly: PurchaseDetails(purchaseID: '', productID: subscriptionYearly, verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: IAPSource.AppStore), transactionDate: ''),
  };

  static bool isPurchased(String productId) {
    for (var purchase in purchases) {
      if (purchase.productID == productId) {
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
