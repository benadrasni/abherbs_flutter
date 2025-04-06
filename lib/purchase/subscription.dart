import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

class Subscription extends StatefulWidget {
  @override
  _SubscriptionState createState() => new _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final _key = GlobalKey<ScaffoldState>();
  final List<String> _subscriptionLists = Platform.isAndroid
      ? [
          subscriptionMonthly,
          subscriptionYearly,
        ]
      : [
          subscriptionMonthly,
          subscriptionYearly,
        ];
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  late Future<ProductDetailsResponse> _subscriptionsF;

  Future<void> _logCancelledSubscriptionEvent(key, String productId) async {
    if (key.currentState != null && key.currentState.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: new Text(S.of(context).product_subscribe_failed),
      ));
    }
    await _firebaseAnalytics.logEvent(name: 'subscription_canceled', parameters: {'productId': productId});
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _logCancelledSubscriptionEvent(_key, purchaseDetails.productID);
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          bool valid = await verifyPurchase(purchaseDetails);
          if (valid) {
            Purchases.purchases[purchaseDetails.productID] = purchaseDetails;
          } else {
            _logCancelledSubscriptionEvent(_key, purchaseDetails.productID);
            return;
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  GooglePlayPurchaseDetails? _getOldSubscription(ProductDetails productDetails, Map<String, PurchaseDetails> purchases) {
    GooglePlayPurchaseDetails? oldSubscription;
    if (productDetails.id == subscriptionMonthly &&  purchases[subscriptionYearly] != null) {
      oldSubscription = purchases[subscriptionYearly] as GooglePlayPurchaseDetails;
    } else if (productDetails.id == subscriptionYearly && purchases[subscriptionMonthly] != null) {
      oldSubscription = purchases[subscriptionMonthly] as GooglePlayPurchaseDetails;
    }
    return oldSubscription;
  }

  String _getProductPeriod(BuildContext context, ProductDetails subscription) {
    if (subscription.id == subscriptionMonthly) {
      return S.of(context).subscription_period_month;
    } else if (subscription.id == subscriptionYearly) {
      return S.of(context).subscription_period_year;
    } else {
      return '';
    }
 }

  @override
  void initState() {
    super.initState();
    _subscriptionsF = _inAppPurchase.queryProductDetails(_subscriptionLists.toSet());
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
    });
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
                      (snapshot.error is PlatformException ? (snapshot.error as PlatformException).message : snapshot.error?.toString()) ?? "",
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
                    child: TextButton(
                  onPressed: () async {
                    Purchases.purchases = {};
                    _inAppPurchase.restorePurchases();
                  },
                  child: Text(
                    S.of(context).product_restore_purchases,
                    style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 18.0),
                  ),
                )));

                _cards.add(Card(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: texts),
                ));
                _cards.addAll(snapshot.data?.productDetails.map((ProductDetails subscription) {
                  bool isPurchased = Purchases.isPurchased(subscription.id);
                  PurchaseDetails? oldSubscription = _getOldSubscription(subscription, Purchases.purchases);
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
                                _getProductPeriod(context, subscription),
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
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPurchased ? Theme.of(context).secondaryHeaderColor : Theme.of(context).primaryColor, // background
                          ),
                          onPressed: () {
                            if (!isPurchased) {
                              PurchaseParam purchaseParam;
                              if (Platform.isAndroid) {
                                final oldSubscription = _getOldSubscription(subscription, Purchases.purchases);

                                purchaseParam = GooglePlayPurchaseParam(
                                    productDetails: subscription,
                                    applicationUserName: null,
                                    changeSubscriptionParam: (oldSubscription != null)
                                        ? ChangeSubscriptionParam(
                                      oldPurchaseDetails: oldSubscription,
                                      replacementMode: ReplacementMode.withTimeProration,
                                    )
                                        : null);
                              } else {
                                purchaseParam = PurchaseParam(
                                  productDetails: subscription,
                                  applicationUserName: null,
                                );
                              }

                              _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam).then((value) {
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
                }) as Iterable<Card>);

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
                        TextButton(
                          onPressed: () {
                            launchURL(termsOfUseUrl);
                          },
                          child: Text(
                            S.of(context).terms_of_use,
                            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14.0),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            launchURL(privacyPolicyUrl);
                          },
                          child: Text(
                            S.of(context).privacy_policy,
                            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14.0),
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
