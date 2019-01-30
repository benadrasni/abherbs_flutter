import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:abherbs_flutter/utils.dart';


class Purchases {
  static bool isAllowed = false;
  static List<PurchasedItem> purchases;

  static bool isNoAds() {
    for (PurchasedItem product in purchases) {
      if (product.productId == productNoAdsAndroid || product.productId == productNoAdsIOS) {
        return true;
      }
    }
    return false;
  }

  static bool isSearch() {
//    for (PurchasedItem product in purchases) {
//      if (product.productId == productSearch) {
//        return true;
//      }
//    }
//    return false;
    return true;
  }
}
