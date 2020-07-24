import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/cupertino.dart';

class Ads {
  static int adsFrequency = 5;
  static Widget admobBanner;
  static Widget admobBigBanner;

  static void initialize() {
    Admob.initialize();
  }

  static Widget getAdMobBanner() {
    if (Purchases.isNoAds())
      return Container(
        height: 0.0,
      );
    else {
      if (admobBanner == null) {
        admobBanner = Container(
          margin: EdgeInsets.only(bottom: 5.0),
          child: AdmobBanner(
            adUnitId: getBannerAdUnitId(),
            adSize: AdmobBannerSize.BANNER,
          ),
        );
      }
      return admobBanner;
    }
  }

  static Widget getAdMobBigBanner() {
    if (Purchases.isNoAds())
      return Container(
        height: 0.0,
      );
    else {
      if (admobBigBanner == null) {
        admobBigBanner = Container(
          margin: EdgeInsets.only(bottom: 5.0),
          child: AdmobBanner(
            adUnitId: getBigBannerAdUnitId(),
            adSize: AdmobBannerSize.LARGE_BANNER,
          ),
        );
      }
      return admobBigBanner;
    }
  }
}
