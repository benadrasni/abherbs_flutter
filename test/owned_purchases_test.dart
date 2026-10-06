import 'package:abherbs_flutter/data/utils.dart';
import 'package:abherbs_flutter/purchase/owned_purchases.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  test('a purchase id merges with the list and the database map', () {
    expect(
      mergePurchaseIds(
        ['search_by_photo'],
        ['field_guide_yearly'],
      ),
      ['field_guide_yearly', 'search_by_photo'],
    );
    expect(
      mergePurchaseIds(
        {'0': 'store_photos_monthly'},
        ['field_guide_yearly', 'store_photos_monthly', ''],
      ),
      ['field_guide_yearly', 'store_photos_monthly'],
    );
    expect(purchaseIdsOf(null), isEmpty);
    expect(purchaseIdsOf({'kept': true, '0': 'no_ads'}), ['no_ads']);
  });

  test('the same ids are one set', () {
    expect(
      samePurchaseIds(
        ['field_guide_monthly', 'no_ads'],
        ['no_ads', 'field_guide_monthly'],
      ),
      isTrue,
    );
    expect(
      samePurchaseIds(['field_guide_yearly'], ['field_guide_monthly']),
      isFalse,
    );
  });

  test('remembered ids fill the map and leave a store row in place', () {
    Purchases.purchases.clear();
    final store = PurchaseDetails(
      productID: productNoAdsAndroid,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'test',
      ),
      transactionDate: '0',
      status: PurchaseStatus.purchased,
    );
    Purchases.purchases[productNoAdsAndroid] = store;
    keepRememberedPurchases([
      productNoAdsAndroid,
      fieldGuideYearly,
      '',
    ]);
    expect(Purchases.purchases[productNoAdsAndroid], same(store));
    expect(Purchases.purchases.containsKey(fieldGuideYearly), isTrue);
    expect(Purchases.purchases.containsKey(''), isFalse);
    expect(
      Purchases.purchases[fieldGuideYearly]?.status,
      PurchaseStatus.restored,
    );
    Purchases.purchases.clear();
  });
}
