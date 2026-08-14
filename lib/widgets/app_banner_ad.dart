import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppBannerAd extends StatefulWidget {
  @override
  _AppBannerAdState createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (Purchases.isNoAds()) {
      return;
    }

    final ad = BannerAd(
      adUnitId: getBannerAdUnitId(),
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (mounted) {
            setState(() {
              _loaded = true;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Banner failed: ${error.code} ${error.message}');
          ad.dispose();
          if (_ad == ad) {
            _ad = null;
          }
          if (mounted) {
            setState(() {
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) {
      return Container(height: 0.0);
    }
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(bottom: 5.0, top: 5.0),
      child: AdWidget(ad: _ad!),
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
    );
  }
}
