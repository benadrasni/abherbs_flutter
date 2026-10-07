import 'package:abherbs_flutter/data/utils.dart';
import 'package:abherbs_flutter/purchase/account_entitlements.dart';
import 'package:abherbs_flutter/purchase/owned_purchases.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    Purchases.purchases.clear();
    Purchases.clearAccountProducts();
  });

  test('a checked Field Guide plan unlocks this phone and sign-out clears it', () {
    Purchases.purchases.clear();
    Purchases.clearAccountProducts();
    final snapshot = accountEntitlementsOf({
      'entitlements': {
        'products': {
          'field_guide_yearly': {'active': true, 'store': 'app_store'},
          'field_guide_monthly': {'active': false, 'store': 'app_store'},
        },
      },
    });
    expect(snapshot.present, isTrue);
    expect(revokedEntitlementIds(snapshot), ['field_guide_monthly']);
    applyAccountEntitlements(snapshot);
    expect(Purchases.hasFieldGuide(), isTrue);
    expect(Purchases.fieldGuideFromAccountOnly, isTrue);
    expect(Purchases.owns(fieldGuideYearly), isTrue);
    expect(Purchases.purchases.containsKey(fieldGuideMonthly), isFalse);

    Purchases.clearAccountProducts();
    expect(Purchases.hasFieldGuide(), isFalse);
  });

  test('an inactive checked plan drops the copy this phone bought', () {
    Purchases.purchases.clear();
    Purchases.clearAccountProducts();
    keepRememberedPurchases([fieldGuideYearly]);
    applyCheckedProducts({fieldGuideYearly: false, productNoAdsAndroid: true});
    expect(Purchases.purchases.containsKey(fieldGuideYearly), isFalse);
    expect(Purchases.isNoAds(), isTrue);
  });

  test('a server entitlements row replaces a cache that has none', () {
    final merged = userWithFreshEntitlements(
      {'credits': 1},
      {
        'products': {
          'field_guide_monthly': {'active': true, 'store': 'play'},
        },
      },
    );
    final snapshot = accountEntitlementsOf(merged);
    applyAccountEntitlements(snapshot);
    expect(Purchases.hasFieldGuide(), isTrue);
    expect(Purchases.owns(fieldGuideMonthly), isTrue);
  });

  test('a cached entitlements event does not clear a plan already applied', () {
    applyAccountEntitlements(accountEntitlementsOf({
      'entitlements': {
        'products': {
          'field_guide_monthly': {'active': true},
        },
      },
    }));
    final watch = EntitlementWatch();
    final cached = accountEntitlementsOf(<String, Object?>{});
    expect(watch.shouldApply(cached), isFalse);
    expect(Purchases.hasFieldGuide(), isTrue);

    final live = accountEntitlementsOf({
      'entitlements': {
        'products': {
          'field_guide_monthly': {'active': false},
        },
      },
    });
    expect(watch.shouldApply(live), isTrue);
    expect(watch.shouldApply(cached), isTrue);
    applyAccountEntitlements(cached);
    expect(Purchases.hasFieldGuide(), isFalse);
  });

  test('an account with no entitlement record leaves store purchases alone', () {
    Purchases.purchases.clear();
    Purchases.clearAccountProducts();
    final snapshot = accountEntitlementsOf({'credits': 1});
    expect(snapshot.present, isFalse);
    applyAccountEntitlements(snapshot);
    expect(Purchases.accountProducts, isEmpty);
  });
}
