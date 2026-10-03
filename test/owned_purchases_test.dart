import 'package:abherbs_flutter/purchase/owned_purchases.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
