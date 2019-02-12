import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:abherbs_flutter/utils.dart';

class Purchases {
  static List<PurchasedItem> purchases = <PurchasedItem>[];
  static Map<String, PurchasedItem> offlineProducts = {
    productNoAdsIOS: PurchasedItem.fromJSON({'productId': productNoAdsIOS}),
    productNoAdsAndroid: PurchasedItem.fromJSON({'productId': productNoAdsAndroid}),
    productSearch: PurchasedItem.fromJSON({'productId': productSearch}),
    productCustomFilter: PurchasedItem.fromJSON({'productId': productCustomFilter}),
    productOffline: PurchasedItem.fromJSON({'productId': productOffline}),
  };

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
    return false;
  }

  static bool isSearch() {
    for (PurchasedItem product in purchases) {
      if (product.productId == productSearch) {
        return true;
      }
    }
    return false;
  }

  static bool isCustomFilter() {
    for (PurchasedItem product in purchases) {
      if (product.productId == productCustomFilter) {
        return true;
      }
    }
    return false;
  }

  static bool isOffline() {
    for (PurchasedItem product in purchases) {
      if (product.productId == productOffline) {
        return true;
      }
    }
    return false;
  }
}
