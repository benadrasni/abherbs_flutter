import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/find_page.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_person.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/guide/guide_widgets.dart';
import 'package:abherbs_flutter/guide/species_page.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/app_banner_ad.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() {
    Purchases.hasOldVersion = false;
    Purchases.purchases = {};
    GuideTabs.unconfirmed.value = 0;
  });

  tearDown(() {
    Purchases.hasOldVersion = false;
    Purchases.purchases = {};
  });

  test('the cover is the newest year in the list', () {
    expect(readGuideList(null).count, 0);
    expect(readGuideList('meadow').count, 0);

    final plain = readGuideList([null, '69', null]);
    expect(plain.count, 1);
    expect(plain.coverId, '1');
    expect(plain.year, isNull);

    final ordered = readGuideList({'10': 1, '2': 1});
    expect(ordered.coverId, '2');
    expect(ordered.year, isNull);

    final years = readGuideList({'5': 1, '9': 2024, '3': 2019});
    expect(years.count, 3);
    expect(years.coverId, '9');
    expect(years.year, 2024);

    final tied = readGuideList({'1': 2020, '2': 2020});
    expect(tied.coverId, '1');
    expect(tied.year, 2020);

    final edge = readGuideList({'1': 1899, '2': 2100, '4': 2101, '8': '2024'});
    expect(edge.count, 4);
    expect(edge.coverId, '2');
    expect(edge.year, 2100);

    final words = readGuideList({'b': 1, 'a': 2020.0, 'm': null});
    expect(words.count, 2);
    expect(words.coverId, 'a');
    expect(words.year, 2020);

    expect(plain.thumbIds, ['1']);
    expect(plain.yearFrom, isNull);
    expect(ordered.thumbIds, ['2', '10']);
    expect(years.thumbIds, ['9', '3']);
    expect(years.yearFrom, 2019);
    expect(tied.thumbIds, ['1', '2']);
    expect(tied.yearFrom, 2020);
    expect(edge.thumbIds, ['2']);
    expect(edge.yearFrom, 2100);
    expect(words.thumbIds, ['a']);
    expect(words.yearFrom, 2020);

    final span = readGuideList({
      '1': 2018,
      '2': 2020,
      '3': 2019,
      '4': 2022,
      '5': 2021,
      '6': 2017,
    });
    expect(span.coverId, '4');
    expect(span.year, 2022);
    expect(span.yearFrom, 2017);
    expect(span.thumbIds, ['4', '5', '2', '3']);
  });

  test('new lists come first, then year lists, then titles', () {
    final covers = [
      _cover(title: 'meadows', count: 3),
      _cover(title: 'Alpine', count: 6, year: 2024),
      _cover(title: 'zzzz', count: 2, isNew: true),
      _cover(title: 'beeches', count: 2, year: 2020),
    ];
    covers.sort(compareGuideLists);
    expect(
      covers.map((cover) => cover.title),
      ['zzzz', 'Alpine', 'beeches', 'meadows'],
    );
    expect(guideListRank(covers.first), 0);
    expect(guideListRank(covers[1]), 1);
    expect(guideListRank(covers.last), 2);
  });

  test('a find keeps its own time and first photo', () {
    final when = guideFindWhen({
      observationDate: {observationTime: 1500.9},
    });
    expect(when, DateTime.fromMillisecondsSinceEpoch(1500));
    expect(guideFindWhen({}), DateTime.fromMillisecondsSinceEpoch(0));
    expect(
      guideFindWhen({
        observationDate: {observationTime: 'soon'}
      }),
      DateTime.fromMillisecondsSinceEpoch(0),
    );

    expect(guideFirstText([null, '', 'a.jpg', 'b.jpg']), 'a.jpg');
    expect(guideFirstText({'2': 'b.jpg', '10': 'c.jpg', '1': ''}), 'c.jpg');
    expect(guideFirstText(null), isNull);
  });

  test('a missing confirmed flag counts as confirmed', () {
    expect(guideFindConfirmed({}), isTrue);
    expect(guideFindConfirmed({observationConfirmed: true}), isTrue);
    expect(guideFindConfirmed({observationConfirmed: false}), isFalse);
    expect(guideFindConfirmed({observationConfirmed: 'false'}), isTrue);
  });

  testWidgets('pins the banner above Find and leaves Book clear',
      (tester) async {
    Purchases.hasOldVersion = true;
    var index = 0;
    Widget bar() {
      return MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: GuideBottomBar(
            index: index,
            showAd: index == 0,
            onSelect: (next) => index = next,
          ),
        ),
      );
    }

    await tester.pumpWidget(bar());
    expect(find.byType(AppBannerAd), findsOneWidget);
    expect(find.text('Find'), findsOneWidget);

    index = 1;
    await tester.pumpWidget(bar());
    expect(find.byType(AppBannerAd), findsNothing);
    expect(find.text('Book'), findsOneWidget);
  });

  testWidgets('shows the key, the first five finds, and the list covers',
      (tester) async {
    Purchases.hasOldVersion = true;
    var seen = 0;
    var book = 0;
    final when = DateTime(2026, 9, 29, 15, 4);
    final latest = DateTime(2026, 9, 1);
    final finds = [
      GuideFind(
        name: 'Bellis perennis',
        label: 'oxeye',
        when: when,
        photoPath: null,
      ),
      for (var n = 2; n <= 6; n++)
        GuideFind(
          name: 'Find $n',
          label: null,
          when: when,
          photoPath: null,
        ),
    ];

    await _pump(
      tester,
      _page(
        colorCounts: const {'1': 12, '2': 0, '4': 7},
        finds: finds,
        allowance: const GuideAllowance.unlimited(
          fieldGuide: false,
          unlimitedNames: true,
          noAds: true,
          seenSynced: false,
        ),
        lists: [
          _cover(title: '', count: 2, isNew: true, latest: latest),
          _cover(title: 'Alpine flowers', count: 6, year: 2024),
          _cover(title: 'Meadows', count: 11),
        ],
        onOpenSeen: () => seen++,
        onOpenBook: () => book++,
      ),
    );

    expect(find.byType(AppBannerAd), findsNothing);
    expect(find.text('What’s that flower'), findsOneWidget);
    expect(find.text('Search plants, families, genera'), findsOneWidget);
    expect(find.text('Name it from a photo'), findsOneWidget);
    expect(find.text('Unlimited'), findsOneWidget);
    expect(find.text('KEY IT OUT · 1 OF 3'), findsOneWidget);
    expect(find.text('ALWAYS FREE'), findsOneWidget);
    expect(find.text('What color is the flower?'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.text('Red, pink'), findsOneWidget);
    expect(find.text('Blue, purple'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('12')).dy,
      lessThan(tester.getTopLeft(find.text('White')).dy),
    );
    expect(
      tester.getTopRight(find.text('12')).dx,
      greaterThan(tester.getTopRight(find.text('White')).dx),
    );
    expect(find.text('null'), findsNothing);

    expect(find.text('Oxeye'), findsOneWidget);
    expect(find.text('To confirm'), findsNothing);
    expect(find.text('Bellis perennis'), findsNothing);
    expect(find.text('Find 5'), findsOneWidget);
    expect(find.text('Find 6'), findsNothing);
    final context = tester.element(find.text('Seen lately'));
    expect(find.text(guideWhen(context, when)), findsNWidgets(5));

    expect(find.text('New in the book'), findsOneWidget);
    final date = MaterialLocalizations.of(context).formatMediumDate(latest);
    expect(find.text('Latest $date'), findsOneWidget);
    expect(find.text('6 years · 2024'), findsOneWidget);
    expect(find.text('11 plants'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox) return false;
        final decoration = widget.decoration;
        if (decoration is! BoxDecoration) return false;
        final border = decoration.border;
        return border is Border &&
            border.top.color == GuidePalette.gold &&
            border.top.width == 2;
      }),
      findsOneWidget,
    );

    await tester.tap(find.text('All finds'));
    await tester.tap(find.text('All lists'));
    await tester.pump();
    expect(seen, 1);
    expect(book, 1);
  });

  testWidgets('hides finds and covers that are not ready', (tester) async {
    Purchases.hasOldVersion = true;
    await _pump(tester, _page(finds: null, lists: null));
    expect(find.text('Seen lately'), findsNothing);
    expect(find.text('Lists of flowers'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await _pump(tester, _page(finds: const [], lists: const []));
    expect(find.text('Seen lately'), findsNothing);
    expect(find.text('All lists'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  test('Remove ads and Field Guide hide banners', () {
    Purchases.hasOldVersion = false;
    Purchases.hasLifetimeSubscription = false;
    Purchases.purchases = {};
    expect(Purchases.showsAds(), isTrue);

    Purchases.purchases = {_noAds().productID: _noAds()};
    expect(Purchases.showsAds(), isFalse);

    Purchases.purchases = {};
    Purchases.hasOldVersion = true;
    expect(Purchases.showsAds(), isFalse);

    Purchases.hasOldVersion = false;
    Purchases.hasLifetimeSubscription = true;
    expect(Purchases.showsAds(), isFalse);
    Purchases.hasLifetimeSubscription = false;
  });

  testWidgets('a no-ads purchase leaves Find without a banner', (tester) async {
    Purchases.hasOldVersion = false;
    Purchases.hasLifetimeSubscription = false;
    Purchases.purchases = {_noAds().productID: _noAds()};
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: const SizedBox.shrink(),
        bottomNavigationBar: GuideBottomBar(
          index: 0,
          showAd: Purchases.showsAds(),
          onSelect: (_) {},
        ),
      ),
    ));
    expect(find.byType(AppBannerAd), findsNothing);
    expect(find.text('Find'), findsOneWidget);
    Purchases.hasLifetimeSubscription = false;
  });

  testWidgets('shows the unconfirmed count on the Seen icon', (tester) async {
    GuideTabs.unconfirmed.value = 3;
    await tester.pumpWidget(_tabs());
    expect(find.text('3'), findsOneWidget);
    expect(find.byKey(guideUnconfirmedBadgeKey), findsOneWidget);

    final icon = tester.getRect(find.byIcon(Icons.article_outlined));
    final badge = tester.getRect(find.byKey(guideUnconfirmedBadgeKey));
    final bar = tester.getRect(find.byType(GuideTabBar));
    expect(badge.top, closeTo(icon.top + 1, 0.5));
    expect(badge.center.dy, lessThan(icon.center.dy));
    expect(badge.center.dx, greaterThan(icon.center.dx));
    expect(badge.top, greaterThanOrEqualTo(bar.top));
    expect(badge.right, lessThanOrEqualTo(bar.right));

    final paint = tester.widget<DecoratedBox>(
      find.byKey(guideUnconfirmedBadgeKey),
    );
    expect(
      (paint.decoration as BoxDecoration).color,
      GuideColors.light.madderFill,
    );

    GuideTabs.unconfirmed.value = 120;
    await tester.pump();
    expect(find.text('99+'), findsOneWidget);

    GuideTabs.unconfirmed.value = 0;
    await tester.pump();
    expect(find.byKey(guideUnconfirmedBadgeKey), findsNothing);
    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
  });

  testWidgets('an unconfirmed find wears To confirm and opens Seen',
      (tester) async {
    Purchases.hasOldVersion = true;
    var seen = 0;
    final when = DateTime(2026, 9, 29, 15, 4);
    await _pump(
      tester,
      _page(
        finds: [
          GuideFind(
            name: 'Bellis perennis',
            label: 'oxeye',
            when: when,
            photoPath: null,
            confirmed: false,
          ),
          GuideFind(
            name: 'Leucanthemum vulgare',
            label: 'daisy',
            when: when,
            photoPath: null,
          ),
        ],
        lists: const [],
        onOpenSeen: () => seen++,
      ),
    );

    expect(find.text('To confirm'), findsOneWidget);
    final photo = tester.getRect(find.byType(GuidePhoto).first);
    final badge = tester.getRect(find.byKey(guideFindToConfirmKey));
    expect(badge.top, closeTo(photo.top + 6, 0.5));
    expect(badge.left, closeTo(photo.left + 6, 0.5));
    final paint = tester.widget<DecoratedBox>(
      find.byKey(guideFindToConfirmKey),
    );
    expect(
      (paint.decoration as BoxDecoration).color,
      GuideColors.light.madderFill,
    );

    await tester.tap(find.text('To confirm'));
    await tester.pump();
    expect(seen, 1);
    expect(find.byType(GuideSpeciesPage), findsNothing);

    await tester.tap(find.text('Daisy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(seen, 1);
    expect(
      tester
          .widget<GuideSpeciesPage>(
            find.byType(GuideSpeciesPage, skipOffstage: false),
          )
          .name,
      'Leucanthemum vulgare',
    );
  });

  testWidgets('asks a signed-out reader to sign in', (tester) async {
    Purchases.purchases = {_noAds().productID: _noAds()};
    await _pump(tester, _page(finds: const [], lists: const []));
    expect(find.text('Sign in to name a photo'), findsOneWidget);
    expect(find.text('Unlimited'), findsNothing);
  });

  testWidgets('a first open has one free photo name', (tester) async {
    await _pump(
      tester,
      _page(
        finds: const [],
        lists: const [],
        allowance: const GuideAllowance.guest(free: true),
      ),
    );
    expect(find.text('1 name left'), findsOneWidget);
    expect(find.text('Sign in to name a photo'), findsNothing);
  });

  testWidgets('a signed-in month shows the names still left', (tester) async {
    await _pump(
      tester,
      _page(
        finds: const [],
        lists: const [],
        allowance: GuideAllowance.month(
          used: 2,
          fromAds: 0,
          now: DateTime(2026, 9, 30),
        ),
      ),
    );
    expect(find.text('3 names left'), findsOneWidget);
    expect(find.text('Sign in to name a photo'), findsNothing);
  });
}

Widget _tabs() {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(
      body: const SizedBox.shrink(),
      bottomNavigationBar: GuideBottomBar(index: 0, onSelect: (_) {}),
    ),
  );
}

GuideListCover _cover({
  required String title,
  required int count,
  bool isNew = false,
  int? year,
  DateTime? latest,
}) {
  return GuideListCover(
    title: title,
    photoPath: null,
    path: FirebaseDatabase.instance.ref('lists'),
    isNew: isNew,
    count: count,
    year: year,
    latest: latest,
  );
}

PurchaseDetails _noAds() {
  return PurchaseDetails(
    productID: productNoAdsIOS,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
    transactionDate: '0',
    status: PurchaseStatus.purchased,
  );
}

Widget _page({
  Map<String, int>? colorCounts = const {},
  List<GuideFind>? finds = const [],
  List<GuideListCover>? lists = const [],
  GuideAllowance allowance = const GuideAllowance.guest(),
  VoidCallback? onOpenBook,
  VoidCallback? onOpenSeen,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(
      body: FindPage(
        colorCounts: colorCounts,
        lists: lists,
        finds: finds,
        allowance: allowance,
        onOpenBook: onOpenBook ?? () {},
        onOpenSeen: onOpenSeen ?? () {},
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(page);
  await tester.pump();
}
