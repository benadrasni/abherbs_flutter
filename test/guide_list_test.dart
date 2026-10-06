import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/data/guide_data.dart';
import 'package:abherbs_flutter/data/guide_results.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:abherbs_flutter/book/list_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  test('a new-plants notification opens New in the book', () {
    expect(notificationPathOpensNewInBook('lists_custom/new/2026-10-01/list'),
        isTrue);
    expect(notificationPathOpensNewInBook('/lists_custom/new'), isTrue);
    expect(
        notificationPathOpensNewInBook('lists_custom/2026-10-01/list'), isTrue);
    expect(notificationPathOpensNewInBook('/lists_custom/2026-10-01'), isTrue);
    expect(notificationPathOpensNewInBook('lists_custom/2026-10-01/time'),
        isFalse);
    expect(
        notificationPathOpensNewInBook(
            'lists_custom/by language/en/Spices/list'),
        isFalse);
    expect(notificationPathOpensNewInBook(''), isFalse);
  });

  test('new in the book says today and yesterday', () {
    final now = DateTime(2026, 10, 1, 23, 30);
    expect(
      guideNewDayLabel('en', DateTime.parse('2026-10-01'), now: now),
      'Today',
    );
    expect(
      guideNewDayLabel('en', DateTime.parse('2026-09-30'), now: now),
      'Yesterday',
    );
    expect(
      guideNewDayLabel('en_US', DateTime.parse('2026-09-27'), now: now),
      'September 27, 2026',
    );
    final newYear = DateTime(2026, 1, 1, 0, 30);
    expect(
      guideNewDayLabel('en', DateTime.parse('2025-12-31'), now: newYear),
      'Yesterday',
    );
  });

  test('new in the book keeps whole days inside 15 to 25', () {
    final window = selectGuideNewDrops([
      _drop('2026-09-27', 6, start: 100),
      _drop('2026-09-20', 6, start: 90),
      _drop('2026-09-13', 6, start: 80),
      _drop('2026-09-06', 6, start: 70),
      _drop('2026-08-30', 6, start: 60),
    ]);
    expect(window.map((drop) => drop.dateKey), [
      '2026-09-27',
      '2026-09-20',
      '2026-09-13',
      '2026-09-06',
    ]);
    final ids = [for (final drop in window) ...drop.ids];
    expect(ids, hasLength(24));
    expect(ids.take(4), ['100', '101', '102', '103']);

    expect(
      selectGuideNewDrops([
        _drop('2026-09-01', 10),
        _drop('2026-08-01', 10),
        _drop('2026-07-01', 10),
      ]).fold<int>(0, (count, drop) => count + drop.ids.length),
      20,
    );

    final packed = selectGuideNewDrops([_drop('2026-09-01', 40)]);
    expect(packed.single.ids, hasLength(25));
    expect(packed.single.ids.first, '15');
    expect(packed.single.ids.last, '39');

    final short = selectGuideNewDrops([
      _drop('2026-09-02', 14, start: 0),
      _drop('2026-09-01', 20, start: 100),
    ]);
    expect(short.first.ids, hasLength(14));
    expect(short.last.ids, hasLength(11));
    expect(short.last.ids.first, '109');

    expect(
      selectGuideNewDrops([
        _drop('2026-09-02', 16),
        _drop('2026-09-01', 10),
      ]).fold<int>(0, (count, drop) => count + drop.ids.length),
      16,
    );

    expect(
      selectGuideNewDrops([_drop('2026-09-01', 8)])
          .fold<int>(0, (count, drop) => count + drop.ids.length),
      8,
    );
    expect(selectGuideNewDrops(const []), isEmpty);
  });

  test('new drops are the newest dated lists', () {
    final drops = readGuideNewDrops({
      '2026-08-01': {
        'list': {'1': 1, '2': 1},
      },
      'notes': {
        'list': {'9': 1}
      },
      '2026-09-01': {
        'list': {'4': 1},
      },
      '2026-09-02': {'time': 1},
    });
    expect(drops.map((drop) => drop.dateKey), ['2026-09-01', '2026-08-01']);
    expect(drops.first.ids, ['4']);
    expect(drops.last.ids, ['1', '2']);
  });

  test('year lists run newest first and ignore membership values', () {
    final years = readGuideYearIds({
      '5': 1,
      '9': 2024,
      '3': 2019,
      '1': 2024,
      '8': 2026,
    });
    expect(
      years.map((row) => '${row.year}:${row.id}'),
      ['2026:8', '2024:1', '2024:9', '2019:3'],
    );
    expect(readGuideYearIds({'1': 1, '2': 1}), isEmpty);
  });

  test('a list opens on the layout its values imply', () {
    final fresh = GuideListCover(
      title: '',
      photoPath: null,
      path: FirebaseDatabase.instance.ref('lists/new'),
      isNew: true,
      count: 20,
    );
    final years = GuideListCover(
      title: 'Baum des Jahres',
      photoPath: null,
      path: FirebaseDatabase.instance.ref('lists/baum'),
      isNew: false,
      count: 12,
      year: 2026,
    );
    final spices = GuideListCover(
      title: 'Spices',
      photoPath: null,
      path: FirebaseDatabase.instance.ref('lists/spices'),
      isNew: false,
      count: 8,
    );
    expect(guideCustomLayout(fresh), GuideCustomLayout.fresh);
    expect(guideCustomLayout(years), GuideCustomLayout.years);
    expect(guideCustomLayout(spices), GuideCustomLayout.grid);
    expect(guideSourceHost('https://www.baum-des-jahres.de/'),
        'baum-des-jahres.de');
    expect(guideSourceHost('baum-des-jahres.de'), 'baum-des-jahres.de');
  });

  testWidgets('New in the book groups the latest plants by date',
      (tester) async {
    String? opened;
    final newer = DateTime(2026, 9, 27);
    final older = DateTime(2026, 8, 14);
    await _pump(
      tester,
      GuideNewPage(
        backLabel: 'Book',
        initialDays: [
          GuideNewDay(
            dateKey: '2026-09-27',
            date: newer,
            plants: [_plant('1', 'Bellis perennis', label: 'daisy')],
          ),
          GuideNewDay(
            dateKey: '2026-08-14',
            date: older,
            plants: [_plant('2', 'Galanthus nivalis', label: 'snowdrop')],
          ),
        ],
        initialSeen: const {'Bellis perennis'},
        loadDays: () async => const [],
        loadSeen: () async => const {},
        onOpenPlant: (_, name) => opened = name,
      ),
    );

    expect(find.text('LISTS OF FLOWERS'), findsOneWidget);
    expect(find.text('New in the book'), findsOneWidget);
    expect(find.text('Book'), findsOneWidget);
    expect(
      find.text(
        'The last 2 plants added to the book · you’ve seen 1',
        findRichText: true,
      ),
      findsOneWidget,
    );
    final context = tester.element(find.text('New in the book'));
    final locale = Localizations.localeOf(context).toString();
    final newerLabel = guideNewDayLabel(locale, newer).toUpperCase();
    final olderLabel = guideNewDayLabel(locale, older).toUpperCase();
    expect(
      tester.getTopLeft(find.text(newerLabel)).dy,
      lessThan(tester.getTopLeft(find.text(olderLabel)).dy),
    );
    expect(
      tester.getTopLeft(find.text('daisy')).dy,
      lessThan(tester.getTopLeft(find.text('snowdrop')).dy),
    );
    expect(find.text('✓ Seen'), findsOneWidget);
    expect(find.text('In flower now · 2'), findsNothing);

    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio).first).aspectRatio,
      1,
    );
    await tester.tap(find.text('Plates'));
    await tester.pump();
    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio).first).aspectRatio,
      closeTo(2 / 3, 0.01),
    );

    await tester.tap(find.text('daisy'));
    expect(opened, 'Bellis perennis');
  });

  testWidgets('New in the book labels today and yesterday', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    await _pump(
      tester,
      GuideNewPage(
        backLabel: 'Book',
        initialDays: [
          GuideNewDay(
            dateKey: 'today',
            date: today,
            plants: [_plant('1', 'Bellis perennis', label: 'daisy')],
          ),
          GuideNewDay(
            dateKey: 'yesterday',
            date: yesterday,
            plants: [_plant('2', 'Galanthus nivalis', label: 'snowdrop')],
          ),
        ],
        initialSeen: const {},
        loadDays: () async => const [],
        loadSeen: () async => const {},
        onOpenPlant: (_, __) {},
      ),
    );

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('TODAY')).dy,
      lessThan(tester.getTopLeft(find.text('YESTERDAY')).dy),
    );
  });

  testWidgets('a year list is a timeline, newest first', (tester) async {
    String? opened;
    await _pump(
      tester,
      GuideYearPage(
        title: 'Baum des Jahres',
        backLabel: 'Find',
        sourceUrl: 'https://baum-des-jahres.de/',
        now: () => DateTime(2026, 9, 30),
        initialEntries: [
          GuideYearEntry(
            year: 2026,
            plant: _plant('8', 'Acer campestre', label: 'field maple'),
          ),
          GuideYearEntry(
            year: 2021,
            plant: _plant('3', 'Ilex aquifolium', label: 'holly'),
          ),
        ],
        initialSeen: const {'Ilex aquifolium'},
        loadList: () async => const GuideYearList(entries: [], sourceUrl: null),
        loadSeen: () async => const {},
        onOpenPlant: (_, name) => opened = name,
      ),
    );

    expect(find.text('Baum des Jahres'), findsOneWidget);
    expect(find.text('Find'), findsOneWidget);
    expect(
      find.textContaining('2 years, newest first', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('baum-des-jahres.de ↗'), findsOneWidget);
    expect(
      find.textContaining('you’ve seen 1', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('THIS YEAR'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('2026')).dy,
      lessThan(tester.getTopLeft(find.text('2021')).dy),
    );
    expect(tester.getSize(find.byType(GuidePhoto).first).height, 64);

    await tester.tap(find.text('Plates'));
    await tester.pump();
    expect(tester.getSize(find.byType(GuidePhoto).first).height, 96);

    await tester.tap(find.text('field maple'));
    expect(opened, 'Acer campestre');
    expect(find.text('In flower now · 2'), findsNothing);
    expect(find.text('Any region'), findsNothing);
  });
}

GuideNewDrop _drop(String date, int count, {int start = 0}) {
  return GuideNewDrop(
    date,
    DateTime.parse(date),
    [for (var i = 0; i < count; i++) '${start + i}'],
  );
}

GuideResultPlant _plant(String id, String name, {String? label}) {
  return GuideResultPlant(
    id: id,
    name: name,
    label: label,
    photoPath: 'photos/$id.webp',
    platePath: 'plates/$id.webp',
    floweringFrom: 6,
    floweringTo: 8,
    cultivated: false,
  );
}

Future<void> _pump(WidgetTester tester, Widget page) {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: GuideTheme(child: page),
    ),
  );
}
