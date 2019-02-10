import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/purchases.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class EnhancementsMerged {
  final List<IAPItem> products;
  final List<PurchasedItem> purchases;

  EnhancementsMerged({this.products, this.purchases});
}

class EnhancementsScreen extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Map<String, String> filter;
  EnhancementsScreen(this.onChangeLanguage, this.onBuyProduct, this.filter);

  @override
  _EnhancementsScreenState createState() => new _EnhancementsScreenState();
}

class _EnhancementsScreenState extends State<EnhancementsScreen> {
  FirebaseAnalytics _firebaseAnalytics;
  final List<String> _productLists = Platform.isAndroid
      ? [
          productNoAdsAndroid,
          productSearch,
          productCustomFilter,
          productOffline,
        ]
      : [
          productNoAdsIOS,
          productSearch,
          productCustomFilter,
          productOffline,
        ];
  Future<List<IAPItem>> _productsF;
  Future<List<PurchasedItem>> _purchasesF;

  Future<void> _logFailedPurchaseEvent(String productId) async {
    await _firebaseAnalytics.logEvent(
        name: 'purchase_failed', parameters: {'productId': productId});
  }

  @override
  void initState() {
    super.initState();
    _firebaseAnalytics = FirebaseAnalytics();
    _productsF = Connectivity().checkConnectivity().then((result) {
      if (Platform.isIOS && result == ConnectivityResult.none) {
        throw PlatformException(
            code: Platform.operatingSystem, message: "IAP not prepared. Check if Platform service is available.");
      } else {
        return FlutterInappPurchase.getProducts(_productLists);
      }
    });
    _purchasesF = Connectivity().checkConnectivity().then((result) {
      if (Platform.isIOS && result == ConnectivityResult.none) {
        throw PlatformException(
            code: Platform.operatingSystem, message: "IAP not prepared. Check if Platform service is available.");
      } else {
        return FlutterInappPurchase.getAvailablePurchases();
      }
    });

    Ads.hideBannerAd();
  }

  List<Widget> _getButtons(IAPItem product, bool isPurchased, key) {
    var buttons = <Widget>[];
    buttons.add(
      RaisedButton(
        color: isPurchased
            ? Theme.of(context).buttonColor
            : Theme.of(context).accentColor,
        onPressed: () {
          if (!isPurchased) {
            FlutterInappPurchase.buyProduct(product.productId)
                .then((PurchasedItem purchased) {
              widget.onBuyProduct(purchased);
            }).catchError((error) {
              _logFailedPurchaseEvent(product.productId);
              if (key.currentState.mounted) {
                key.currentState.showSnackBar(new SnackBar(
                  content: new Text(S.of(context).product_purchase_failed),
                ));
              }
            });
          }
        },
        child: Text(
          isPurchased
              ? S.of(context).product_purchased
              : S.of(context).product_purchase,
          style: TextStyle(color: isPurchased ? Colors.black : Colors.white),
        ),
      ),
    );

    if ([productOffline, productCustomFilter].contains(product.productId) &&
        isPurchased) {
      buttons.add(RaisedButton(
        color: Theme.of(context).accentColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    SettingsScreen(widget.onChangeLanguage, widget.filter)),
          );
        },
        child: Text(
          S.of(context).settings,
          style: TextStyle(color: Colors.white),
        ),
      ));
    }

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();

    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text(S.of(context).enhancements),
      ),
      body: FutureBuilder<EnhancementsMerged>(
        future: Future.wait([_productsF, _purchasesF]).then((response) {
          return EnhancementsMerged(
              products: response[0], purchases: response[1]);
        }),
        builder:
            (BuildContext context, AsyncSnapshot<EnhancementsMerged> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              var _cards = <Card>[];
              if (snapshot.hasError) {
                _cards.add(
                  Card(
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        snapshot.error is PlatformException
                            ? (snapshot.error as PlatformException).message
                            : snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
                );
              } else {
                Purchases.purchases = snapshot.data.purchases;
                Prefs.setStringList(keyPurchases, Purchases.purchases.map((item) => item.productId).toList());
                _cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: RaisedButton(
                      onPressed: () {
                        setState(() {
                          _purchasesF =
                              FlutterInappPurchase.getAvailablePurchases();
                        });
                      },
                      child: Text(
                        S.of(context).product_restore_purchases,
                      ),
                    ),
                  ),
                ));
                _cards.addAll(snapshot.data.products.map((IAPItem product) {
                  bool isPurchased = Purchases.isPurchased(product.productId);
                  return Card(
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  getProductTitle(context, product.productId,
                                      product.title),
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                Text(
                                  product.localizedPrice,
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 18.0,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                            SizedBox(height: 10.0),
                            Text(
                              getProductDescription(context, product.productId,
                                  product.description),
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                              textAlign: TextAlign.start,
                            ),
                            SizedBox(height: 10.0),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    _getButtons(product, isPurchased, key)),
                          ]),
                    ),
                  );
                }).toList());
              }

              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10.0),
                children: _cards,
              );
            default:
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(),
                  CircularProgressIndicator(),
                  Container(),
                ],
              );
          }
        },
      ),
    );
  }
}
