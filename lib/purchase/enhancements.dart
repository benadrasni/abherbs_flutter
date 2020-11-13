import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:abherbs_flutter/settings/setting_my_filter.dart';
import 'package:abherbs_flutter/settings/settings_remote.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/purchase/subscription.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class EnhancementsScreen extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  EnhancementsScreen(this.onChangeLanguage, this.filter);

  @override
  _EnhancementsScreenState createState() => new _EnhancementsScreenState();
}

class _EnhancementsScreenState extends State<EnhancementsScreen> {
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics();
  final InAppPurchaseConnection _connection = InAppPurchaseConnection.instance;
  final List<String> _productLists = Platform.isAndroid
      ? [
          productNoAdsAndroid,
          productSearch,
          productCustomFilter,
          productOffline,
          productObservations,
          productPhotoSearch,
        ]
      : [
          productNoAdsIOS,
          productSearch,
          productCustomFilter,
          productOffline,
          productObservations,
          productPhotoSearch,
        ];
  Future<ProductDetailsResponse> _productsF;

  Future<void> _logCancelledPurchaseEvent(key, String productId) async {
    if (key.currentState != null && key.currentState.mounted) {
      key.currentState.showSnackBar(new SnackBar(
        content: new Text(S.of(context).product_purchase_failed),
      ));
    }
    await _firebaseAnalytics.logEvent(name: 'purchase_canceled', parameters: {'productId': productId});
  }

  @override
  void initState() {
    super.initState();
    _productsF = _connection.queryProductDetails(_productLists.toSet());
  }

  Widget _getVideoLink(BuildContext context, ProductDetails product) {
    Widget button = Container();
    String config = "";
    switch (product.id) {
      case productCustomFilter:
        config = remoteConfigCustomFilterVideo;
        break;
      case productObservations:
        config = remoteConfigObservationsVideo;
        break;
      case productSearch:
        config = remoteConfigSearchByNameVideo;
        break;
      case productPhotoSearch:
        config = remoteConfigSearchByPhotoVideo;
        break;
    }
    String value = RemoteConfiguration.remoteConfig.getString(config);
    if (value.isNotEmpty) {
      button = FlatButton(
        color: Colors.lightBlueAccent,
        child: Text(S
            .of(context)
            .video,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            )),
        onPressed: () {
          launchURL(value);
        },
      );
    }
    return button;
  }

  List<Widget> _getButtons(ProductDetails product, bool isPurchased, key) {
    var buttons = <Widget>[];
    buttons.add(
      RaisedButton(
        color: isPurchased ? Theme.of(context).buttonColor : Theme.of(context).accentColor,
        onPressed: () {
          if (!isPurchased) {
            _connection.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product)).then((value) {
              if (!value) {
                _logCancelledPurchaseEvent(key, product.id);
              }
            }).catchError((error) {
              _logCancelledPurchaseEvent(key, product.id);
            });
          }
        },
        child: Text(
          isPurchased ? S.of(context).product_purchased : S.of(context).product_purchase,
          style: TextStyle(color: isPurchased ? Colors.black : Colors.white),
        ),
      ),
    );

    if (isPurchased) {
      switch (product.id) {
        case productOffline:
          buttons.add(RaisedButton(
            color: Theme.of(context).accentColor,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen(widget.onChangeLanguage, widget.filter), settings: RouteSettings(name: 'Settings')),
              );
            },
            child: Text(
              S.of(context).settings,
              style: TextStyle(color: Colors.white),
            ),
          ));
          break;
        case productCustomFilter:
          buttons.add(RaisedButton(
            color: Theme.of(context).accentColor,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingMyFilter(widget.onChangeLanguage, widget.filter), settings: RouteSettings(name: 'SettingMyFilter')),
              );
            },
            child: Text(
              S.of(context).my_filter,
              style: TextStyle(color: Colors.white),
            ),
          ));
          break;
        case productObservations:
          if (Purchases.hasLifetimeSubscription == null || !Purchases.hasLifetimeSubscription) {
            buttons.add(RaisedButton(
              color: Theme.of(context).accentColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Subscription(), settings: RouteSettings(name: 'Subscription')),
                );
              },
              child: Text(
                S.of(context).subscription,
                style: TextStyle(color: Colors.white),
              ),
            ));
          }
          break;
        default:
      }
    }

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text(S.of(context).enhancements),
      ),
      body: FutureBuilder<ProductDetailsResponse>(
        future: _productsF,
        builder: (BuildContext context, AsyncSnapshot<ProductDetailsResponse> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              var _cards = <Card>[];
              if (snapshot.hasError) {
                _cards.add(
                  Card(
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        snapshot.error is PlatformException ? (snapshot.error as PlatformException).message : snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
                );
              } else {
                _cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: FlatButton(
                      onPressed: () async {
                        final QueryPurchaseDetailsResponse purchaseResponse = await _connection.queryPastPurchases();
                        if (purchaseResponse.error != null) {
                          var purchases = await Prefs.getStringListF(keyPurchases, []);
                          Purchases.purchases = purchases.map((productId) => Purchases.offlineProducts[productId]).toList();
                        } else {
                          Purchases.purchases = [];
                          for (PurchaseDetails purchase in purchaseResponse.pastPurchases) {
                            if (await verifyPurchase(purchase)) {
                              if (Platform.isIOS) {
                                _connection.completePurchase(purchase);
                              }
                              Purchases.purchases.add(purchase);
                            }
                          }
                          Prefs.setStringList(keyPurchases, Purchases.purchases.map((item) => item.productID).toList());
                        }

                        if (mounted) {
                          setState(() {});
                        }
                      },
                      child: Text(
                        S.of(context).product_restore_purchases,
                        style: TextStyle(color: Theme.of(context).accentColor, fontSize: 18.0),
                      ),
                    ),
                  ),
                ));
                _cards.addAll(snapshot.data.productDetails.map((ProductDetails product) {
                  bool isPurchased = Purchases.isPurchased(product.id);
                  return Card(
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        ListTile(
                          leading: getProductIcon(context, product.id),
                          title: Text(
                            getProductTitle(context, product.id, product.title),
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          trailing: Text(
                            product.price,
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.0),
                        Text(
                          getProductDescription(context, product.id, product.description),
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10.0),
                        _getVideoLink(context, product),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _getButtons(product, isPurchased, key)),
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
