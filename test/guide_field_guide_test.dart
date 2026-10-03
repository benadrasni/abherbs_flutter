import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/field_guide_page.dart';
import 'package:abherbs_flutter/guide/guide_field_guide.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  tearDown(() {
    Purchases.purchases = {};
    Purchases.hasLifetimeSubscription = false;
    Purchases.hasOldVersion = false;
  });

  test('yearly is the offer to show, and a free phase is the one to buy', () {
    final choice = guideFieldGuideOfferChoice(const [
      (price: r'$0.00', rawPrice: 0),
      (price: r'$19.99', rawPrice: 19.99),
    ]);
    expect(choice?.buyIndex, 0);
    expect(choice?.displayPrice, r'$19.99');

    final paidOnly = guideFieldGuideOfferChoice(const [
      (price: r'$2.99', rawPrice: 2.99),
    ]);
    expect(paidOnly?.buyIndex, 0);
    expect(paidOnly?.displayPrice, r'$2.99');
    expect(guideFieldGuideOfferChoice(const []), isNull);
  });

  test('a photo-storage plan counts, and the other period is the replacement',
      () {
    final catalog = guideFieldGuideCatalog(
      storeAvailable: true,
      yearlyPrice: r'$19.99',
      monthlyPrice: r'$2.99',
      owned: {subscriptionYearly},
    );
    expect(catalog.photoStorage, isTrue);
    expect(catalog.coveredByOlderPlan, isTrue);
    expect(catalog.initialPlan, GuideFieldGuidePlan.yearly);

    final monthly = guideFieldGuideCatalog(
      storeAvailable: true,
      yearlyPrice: null,
      monthlyPrice: r'$2.99',
      owned: {fieldGuideMonthly},
    );
    expect(monthly.monthly.owned, isTrue);
    expect(monthly.initialPlan, GuideFieldGuidePlan.monthly);
    expect(
      guideFieldGuideReplaces(
        GuideFieldGuidePlan.yearly,
        {fieldGuideMonthly, subscriptionYearly},
      ),
      fieldGuideMonthly,
    );
    expect(
      guideFieldGuideReplaces(GuideFieldGuidePlan.yearly, {subscriptionYearly}),
      isNull,
    );
  });

  test('the paid price stays on the row when a trial phase is present', () {
    final loaded = guideFieldGuideFromStore(
      storeAvailable: true,
      owned: const {},
      products: [
        _product(fieldGuideYearly, r'$0.00', 0),
        _product(fieldGuideYearly, r'$19.99', 19.99),
        _product(fieldGuideMonthly, r'$2.99', 2.99),
      ],
    );
    expect(loaded.catalog.yearly.price, r'$19.99');
    expect(loaded.catalog.monthly.price, r'$2.99');
    expect(loaded.products[fieldGuideYearly]?.rawPrice, 0);
    expect(loaded.products[fieldGuideMonthly]?.rawPrice, 2.99);
  });

  test('Field Guide plans hide ads and are not the lifetime purchase', () {
    Purchases.hasLifetimeSubscription = true;
    expect(Purchases.isSubscribed(), isTrue);
    expect(Purchases.hasFieldGuide(), isFalse);
    expect(Purchases.showsAds(), isFalse);

    Purchases.hasLifetimeSubscription = false;
    Purchases.purchases = {fieldGuideMonthly: _purchase(fieldGuideMonthly)};
    expect(Purchases.hasFieldGuide(), isTrue);
    expect(Purchases.showsAds(), isFalse);

    Purchases.purchases = {
      subscriptionMonthly: _purchase(subscriptionMonthly),
    };
    expect(Purchases.hasFieldGuide(), isTrue);

    Purchases.purchases = {};
    expect(Purchases.showsAds(), isTrue);
  });

  testWidgets('yearly is selected and the store price starts that plan',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    GuideFieldGuidePlan? bought;
    var restored = 0;
    await tester.pumpWidget(_app(_page(
      catalog: _priced(),
      onBuy: (plan) async {
        bought = plan;
        return true;
      },
      onRestore: () async => restored++,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Field Guide'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Unlimited names from photos'), findsOneWidget);
    expect(find.text(r'$19.99'), findsOneWidget);
    expect(find.text(r'$2.99'), findsOneWidget);
    expect(find.text('Start 7 days free'), findsOneWidget);

    await tester.tap(find.byKey(guideFieldGuideStartKey));
    await tester.pump();
    expect(bought, GuideFieldGuidePlan.yearly);

    await tester.tap(find.text('Monthly'));
    await tester.pump();
    await tester.tap(find.byKey(guideFieldGuideStartKey));
    await tester.pump();
    expect(bought, GuideFieldGuidePlan.monthly);

    await tester.tap(find.byKey(guideFieldGuideRestoreKey));
    await tester.pump();
    expect(restored, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an owned yearly plan is already subscribed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var bought = 0;
    await tester.pumpWidget(_app(_page(
      catalog: guideFieldGuideCatalog(
        storeAvailable: true,
        yearlyPrice: r'$19.99',
        monthlyPrice: r'$2.99',
        owned: {fieldGuideYearly},
      ),
      onBuy: (_) async {
        bought++;
        return true;
      },
    )));
    await tester.pumpAndSettle();

    expect(find.text('Subscribed'), findsOneWidget);
    expect(find.text('Start 7 days free'), findsNothing);
    await tester.tap(find.byKey(guideFieldGuideStartKey));
    await tester.pump();
    expect(bought, 0);

    await tester.tap(find.text('Monthly'));
    await tester.pump();
    expect(find.text('Change'), findsOneWidget);
    await tester.tap(find.byKey(guideFieldGuideStartKey));
    await tester.pump();
    expect(bought, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a photo-storage plan is Field Guide already', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(_page(
      catalog: guideFieldGuideCatalog(
        storeAvailable: true,
        yearlyPrice: r'$19.99',
        monthlyPrice: r'$2.99',
        owned: {subscriptionMonthly},
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('You already have Field Guide.'), findsOneWidget);
    expect(
      find.text('Your photo-storage plan counts as Field Guide.'),
      findsOneWidget,
    );
    expect(find.byKey(guideFieldGuideStartKey), findsNothing);
    expect(find.text('Yearly'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a missing store price does not start a purchase',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var bought = 0;
    await tester.pumpWidget(_app(_page(
      catalog: guideFieldGuideCatalog(
        storeAvailable: false,
        yearlyPrice: null,
        monthlyPrice: null,
        owned: const {},
      ),
      onBuy: (_) async {
        bought++;
        return true;
      },
    )));
    await tester.pumpAndSettle();

    expect(find.text('Store price'), findsNWidgets(2));
    expect(
      find.text('The store doesn’t have these plans yet.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(guideFieldGuideStartKey));
    await tester.pump();
    expect(bought, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode keeps the page on the dark paper', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(_page(
      catalog: _priced(),
      appearance: GuideAppearance.dark,
    )));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Field Guide')))
          .scaffoldBackgroundColor,
      GuideColors.dark.paper,
    );
    expect(tester.takeException(), isNull);
  });
}

GuideFieldGuideCatalog _priced() {
  return guideFieldGuideCatalog(
    storeAvailable: true,
    yearlyPrice: r'$19.99',
    monthlyPrice: r'$2.99',
    owned: const {},
  );
}

Widget _page({
  required GuideFieldGuideCatalog catalog,
  Future<bool> Function(GuideFieldGuidePlan plan)? onBuy,
  Future<void> Function()? onRestore,
  GuideAppearance? appearance,
}) {
  return GuideFieldGuidePage(
    appearance: appearance,
    load: () async => GuideFieldGuideLoaded(catalog: catalog),
    buy: onBuy ?? (_) async => false,
    restore: onRestore ?? () async {},
    plate: (_) => const ColoredBox(color: Color(0xFFEFE6D3)),
  );
}

Widget _app(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: home,
  );
}

ProductDetails _product(String id, String price, double raw) {
  return ProductDetails(
    id: id,
    title: id,
    description: '',
    price: price,
    rawPrice: raw,
    currencyCode: 'USD',
  );
}

PurchaseDetails _purchase(String id) {
  return PurchaseDetails(
    productID: id,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
    transactionDate: '0',
    status: PurchaseStatus.purchased,
  );
}
