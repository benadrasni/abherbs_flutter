import 'dart:async';

import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class AppBannerAd extends StatefulWidget {
  /// Field-guide bar above the tabs. Stays empty until the ad has loaded.
  final bool pinned;

  const AppBannerAd({super.key, this.pinned = false});

  @override
  _AppBannerAdState createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;
  StreamSubscription<List<PurchaseDetails>>? _purchases;

  @override
  void initState() {
    super.initState();
    if (!Purchases.showsAds()) return;
    _purchases = InAppPurchase.instance.purchaseStream.listen(
      (_) {
        if (mounted) _applyPurchase();
      },
      onError: (Object error) => debugPrint('banner: $error'),
    );

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
  void didUpdateWidget(AppBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!Purchases.showsAds()) _release(notify: false);
  }

  void _applyPurchase() {
    if (!Purchases.showsAds()) _release();
  }

  void _release({bool notify = true}) {
    final ad = _ad;
    _ad = null;
    ad?.dispose();
    _loaded = false;
    if (notify && mounted) setState(() {});
  }

  @override
  void dispose() {
    _purchases?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    if (!_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    final ad = SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
    if (widget.pinned) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border(top: BorderSide(color: colors.rule)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Center(child: ad),
        ),
      );
    }
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 5.0, top: 5.0),
      child: ad,
    );
  }
}
