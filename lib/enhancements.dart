import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class EnhancementsMerged {
  final List<IAPItem> products;
  final List<PurchasedItem> purchases;

  EnhancementsMerged({this.products, this.purchases});
}

class EnhacementsScreen extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final void Function() onBuyProduct;
  EnhacementsScreen(this.onChangeLanguage, this.onBuyProduct);

  @override
  _EnhacementsScreenState createState() => new _EnhacementsScreenState();
}

class _EnhacementsScreenState extends State<EnhacementsScreen> {
  final List<String> _productLists = Platform.isAndroid
      ? [
          productNoAdsAndroid,
        ]
      : [
          productNoAdsIOS,
        ];
  Future<List<IAPItem>> _productsF;
  Future<List<PurchasedItem>> _purchasesF;

  @override
  void initState() {
    super.initState();
    _productsF = FlutterInappPurchase.getProducts(_productLists);
    _purchasesF = FlutterInappPurchase.getAvailablePurchases();
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
          return EnhancementsMerged(products: response[0], purchases: response[1]);
        }),
        builder: (BuildContext context, AsyncSnapshot<EnhancementsMerged> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10.0),
                children: snapshot.data.products.map((IAPItem product) {
                  return Card(
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              getProductTitle(context, product.productId, product.title),
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
                          getProductDescription(context, product.productId, product.description),
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        SizedBox(height: 10.0),
                        RaisedButton(
                          color: Theme.of(context).accentColor,
                          onPressed: () {
                            FlutterInappPurchase.buyProduct(product.productId).then((PurchasedItem purchased) {
                              widget.onBuyProduct();
                            });
                          },
                          child: Text(
                            S.of(context).product_purchase,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
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
