import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class Subscription extends StatefulWidget {
  final void Function(PurchasedItem) onBuyProduct;
  Subscription(this.onBuyProduct);

  @override
  _SubscriptionState createState() => new _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  FirebaseAnalytics _firebaseAnalytics;
  final List<String> _subscriptionLists = Platform.isAndroid
      ? [
          subscriptionMonthly,
          subscriptionYearly,
        ]
      : [
          subscriptionMonthly,
          subscriptionYearly,
        ];
  Future<List<IAPItem>> _subscriptionsF;

  Future<void> _logCanceledSubscriptionEvent(String subscriptionId) async {
    await _firebaseAnalytics.logEvent(name: 'subscription_canceled', parameters: {'subscriptionId': subscriptionId});
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
    _firebaseAnalytics = FirebaseAnalytics();
    _subscriptionsF = FlutterInappPurchase.getSubscriptions(_subscriptionLists);

    Ads.hideBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();

    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text(S.of(context).subscription),
      ),
      body: FutureBuilder<List<IAPItem>>(
        future: _subscriptionsF,
        builder: (BuildContext context, AsyncSnapshot<List<IAPItem>> snapshot) {
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
                  onPressed: () {
                    FlutterInappPurchase.getAvailablePurchases().then((purchases) {
                      Purchases.purchases = purchases;
                      Prefs.setStringList(keyPurchases, Purchases.purchases.map((item) => item.productId).toList());
                      if (mounted) {
                        setState(() {});
                      }
                    });
                  },
                  child: Text(
                    S.of(context).product_restore_purchases,
                    style: TextStyle(color: Theme.of(context).accentColor, fontSize: 18.0),
                  ),
                )));

                _cards.add(Card(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: texts),
                ));
                _cards.addAll(snapshot.data.map((IAPItem subscription) {
                  bool isPurchased = Purchases.isPurchased(subscription.productId);
                  String oldSubscription = _getOldSubscription(subscription.productId);
                  return Card(
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        ListTile(
                          leading: getProductIcon(context, subscription.productId),
                          title: Text(
                            getProductTitle(context, subscription.productId, subscription.title),
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          trailing: Text(
                            subscription.localizedPrice +
                                '/' +
                                getProductPeriod(
                                    context, Platform.isIOS ? subscription.subscriptionPeriodUnitIOS : subscription.subscriptionPeriodAndroid),
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.0),
                        Text(
                          getProductDescription(context, subscription.productId, subscription.description),
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
                              FlutterInappPurchase.buySubscription(subscription.productId, oldSku: oldSubscription).then((PurchasedItem purchased) {
                                widget.onBuyProduct(purchased);
                              }).catchError((error) {
                                _logCanceledSubscriptionEvent(subscription.productId);
                                if (key.currentState != null && key.currentState.mounted) {
                                  key.currentState.showSnackBar(new SnackBar(
                                    content: new Text(S.of(context).product_subscribe_failed),
                                  ));
                                }
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
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                        ]),
                      ],
                    ),
                  ),
                ));

                return ListView(shrinkWrap: true, padding: const EdgeInsets.all(10.0), children: _cards);
              }
              break;

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
