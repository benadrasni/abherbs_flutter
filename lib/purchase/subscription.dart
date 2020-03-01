import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class Subscription extends StatefulWidget {
  @override
  _SubscriptionState createState() => new _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics();
  final InAppPurchaseConnection _connection = InAppPurchaseConnection.instance;
  final List<String> _subscriptionLists = Platform.isAndroid
      ? [
          subscriptionMonthly,
          subscriptionYearly,
        ]
      : [
          subscriptionMonthly,
          subscriptionYearly,
        ];
  Future<ProductDetailsResponse> _subscriptionsF;

  Future<void> _logCancelledSubscriptionEvent(key, String productId) async {
    if (key.currentState != null && key.currentState.mounted) {
      key.currentState.showSnackBar(new SnackBar(
        content: new Text(S.of(context).product_subscribe_failed),
      ));
    }
    await _firebaseAnalytics.logEvent(name: 'subscription_canceled', parameters: {'productId': productId});
  }

  String _getOldSubscription(String productId) {
    switch (productId) {
      case subscriptionMonthly:
        return Purchases.isPurchased(subscriptionYearly) ? subscriptionYearly : null;
      case subscriptionYearly:
        return Purchases.isPurchased(subscriptionMonthly) ? subscriptionMonthly : null;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _subscriptionsF = _connection.queryProductDetails(_subscriptionLists.toSet());
  }

  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();

    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text(S.of(context).subscription),
      ),
      body: FutureBuilder<ProductDetailsResponse>(
        future: _subscriptionsF,
        builder: (BuildContext context, AsyncSnapshot<ProductDetailsResponse> snapshot) {
          var _cards = <Card>[];
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasError) {
                _cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      snapshot.error is PlatformException ? (snapshot.error as PlatformException).message : snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ));
              } else {
                List<Widget> texts =
                    [S.of(context).subscription_intro1, S.of(context).subscription_intro2, S.of(context).subscription_intro3].map((item) {
                  return Container(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 16.0,
                        ),
                        textAlign: TextAlign.justify,
                      ));
                }).toList();
                texts.add(Container(
                    child: FlatButton(
                  onPressed: () async {
                    final QueryPurchaseDetailsResponse purchaseResponse = await _connection.queryPastPurchases();
                    if (purchaseResponse.error != null) {
                      var purchases = await Prefs.getStringListF(keyPurchases, []);
                      Purchases.purchases = purchases.map((productId) => Purchases.offlineProducts[productId]).toList();
                    } else {
                      for (PurchaseDetails purchase in purchaseResponse.pastPurchases) {
                        if (await verifyPurchase(purchase)) {
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
                )));

                _cards.add(Card(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: texts),
                ));
                _cards.addAll(snapshot.data.productDetails.map((ProductDetails subscription) {
                  bool isPurchased = Purchases.isPurchased(subscription.id);
                  String oldSubscription = _getOldSubscription(subscription.id);
                  return Card(
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        ListTile(
                          leading: getProductIcon(context, subscription.id),
                          title: Text(
                            getProductTitle(context, subscription.id, subscription.title),
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          trailing: Text(
                            subscription.price +
                                '/' +
                                getProductPeriod(
                                    context, subscription.skuDetail.subscriptionPeriod),
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.0),
                        Text(
                          getProductDescription(context, subscription.id, subscription.description),
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10.0),
                        RaisedButton(
                          color: isPurchased ? Theme.of(context).buttonColor : Theme.of(context).accentColor,
                          onPressed: () {
                            if (!isPurchased) {
                              _connection.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: subscription)).then((value) {
                                if (!value) {
                                  _logCancelledSubscriptionEvent(key, subscription.id);
                                }
                              }).catchError((error) {
                                _logCancelledSubscriptionEvent(key, subscription.id);
                              });
                            }
                          },
                          child: Text(
                            isPurchased
                                ? S.of(context).product_subscribed
                                : oldSubscription != null ? S.of(context).product_change : S.of(context).product_subscribe,
                            style: TextStyle(color: isPurchased ? Colors.black : Colors.white),
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList());

                _cards.add(Card(
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        Text(
                          Platform.isIOS ? S.of(context).subscription_disclaimer_ios : S.of(context).subscription_disclaimer_android,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 16.0),
                        ),
                        FlatButton(
                          onPressed: () {
                            launchURL(termsOfUseUrl);
                          },
                          child: Text(
                            S.of(context).terms_of_use,
                            style: TextStyle(color: Theme.of(context).accentColor, fontSize: 14.0),
                          ),
                        ),
                        FlatButton(
                          onPressed: () {
                            launchURL(privacyPolicyUrl);
                          },
                          child: Text(
                            S.of(context).privacy_policy,
                            style: TextStyle(color: Theme.of(context).accentColor, fontSize: 14.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ));
              }
              return ListView(shrinkWrap: true, padding: const EdgeInsets.all(10.0), children: _cards);

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
