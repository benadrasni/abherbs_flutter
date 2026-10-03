import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/book/book_page.dart';
import 'package:abherbs_flutter/data/guide_data.dart';
import 'package:abherbs_flutter/data/guide_results.dart';
import 'package:abherbs_flutter/search/guide_search.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:abherbs_flutter/shell/app_banner_ad.dart';
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

  setUp(() {
    Purchases.hasOldVersion = true;
    Purchases.purchases = {};
  });

  tearDown(() {
    Purchases.hasOldVersion = false;
    Purchases.purchases = {};
  });

  final index = GuideSearchIndex.parse(
    vernacular: const {},
    latin: const {},
    apg: {
      firebaseRootTaxon: {
        firebaseAPGType: 'Regnum',
        'Asterales': {
          firebaseAPGType: 'Ordo',
          'Asteraceae': {
            firebaseAPGType: 'Familia',
            firebaseAttributeCount: 93,
            'Bellis': {
              firebaseAPGType: 'Genus',
              firebaseAttributeCount: 2,
            },
            'Rosa': {
              firebaseAPGType: 'Genus',
              firebaseAttributeCount: 1,
            },
          },
        },
        'Rosales': {
          firebaseAPGType: 'Ordo',
          'Rosaceae': {
            firebaseAPGType: 'Familia',
            firebaseAttributeCount: 12,
          },
          'Emptyaceae': {
            firebaseAPGType: 'Familia',
            firebaseAttributeCount: 0,
          },
        },
      },
    },
    taxonomyNames: const {
      'Asteraceae': ['daisy family'],
      'Rosaceae': ['rose family'],
      'Bellis': ['english daisy'],
      'Rosa': ['rosa'],
    },
  );

  test('families and genera sort by the name on the row', () {
    final book = guideBookTaxa(index.families, index.genera);
    expect(
      book.families.map((taxon) => taxon.latinName),
      ['Asteraceae', 'Rosaceae'],
    );
    expect(book.plants, 105);
    expect(book.genera.map((taxon) => taxon.latinName), ['Bellis', 'Rosa']);
    expect(guideFamilyIllustration('Asteraceae'), 'families/Asteraceae.webp');
    expect(guideFamilyIllustration(''), isNull);

    final listed = GuideSearchIndex.parse(
      vernacular: const {},
      latin: const {},
      apg: {
        firebaseRootTaxon: {
          firebaseAPGType: 'Regnum',
          'Asterales': {
            firebaseAPGType: 'Ordo',
            'Asteraceae': {
              firebaseAPGType: 'Familia',
              firebaseAttributeCount: 2,
              firebaseAttributeList: {'1': 1, '2': 1},
              'Bellis': {
                firebaseAPGType: 'Genus',
                firebaseAttributeCount: 2,
                firebaseAttributeList: {'70': 1, '69': 1},
              },
            },
          },
        },
      },
      taxonomyNames: const {},
    );
    expect(
      listed.genera.single.plantIds,
      ['69', '70'],
    );
    expect(listed.families.single.plantIds, isEmpty);

    final accented = guideBookTaxa(const [], [
      GuideSearchTaxon(
        latinName: 'Viola',
        vernaculars: const ['violet'],
        count: 2,
        listPath: 'v',
        illustrationFamily: 'Violaceae',
      ),
      GuideSearchTaxon(
        latinName: 'Äconitum',
        vernaculars: const [],
        count: 1,
        listPath: 'a',
        illustrationFamily: 'Ranunculaceae',
      ),
    ]);
    expect(
      accented.genera.map((taxon) => taxon.latinName),
      ['Äconitum', 'Viola'],
    );
  });

  testWidgets('opens on families, then genera and lists', (tester) async {
    final latest = DateTime(2026, 9, 1);
    String? opened;
    GuideListCover? openedList;
    final lists = [
      GuideListCover(
        title: '',
        photoPath: 'photos/new.webp',
        thumbs: const ['photos/new.webp', 'photos/older.webp'],
        path: FirebaseDatabase.instance.ref('lists/new'),
        isNew: true,
        count: 2,
        latest: latest,
      ),
      GuideListCover(
        title: 'Alpine flowers',
        photoPath: 'photos/alpine.webp',
        thumbs: const [
          'photos/a.webp',
          'photos/b.webp',
          'photos/c.webp',
          'photos/d.webp',
        ],
        path: FirebaseDatabase.instance.ref('lists/alpine'),
        isNew: false,
        count: 6,
        year: 2024,
        yearFrom: 2019,
      ),
    ];

    await _pump(
      tester,
      _Host(
        loadTaxa: (_) async => guideBookTaxa(index.families, index.genera),
        lists: lists,
        onOpenTaxon: (_, path) => opened = path,
        onOpenList: (_, cover) => openedList = cover,
      ),
    );

    expect(find.text('Book'), findsOneWidget);
    expect(find.text('105 plants · 2 families'), findsOneWidget);
    expect(find.text('daisy family'), findsOneWidget);
    expect(find.text('Asteraceae'), findsOneWidget);
    expect(find.text('93'), findsOneWidget);
    expect(find.text('rose family'), findsOneWidget);
    expect(find.text('english daisy'), findsNothing);
    expect(find.byType(AppBannerAd), findsNothing);

    final families = tester.widget<Material>(find.byKey(guideBookFamiliesKey));
    expect(families.color, GuideColors.light.ink);

    await tester.tap(find.text('daisy family'));
    await tester.pump();
    expect(opened, 'APG IV_v3/Eukaryota/Asterales/Asteraceae/list');

    await tester.tap(find.byKey(guideBookGeneraKey));
    await tester.pump();
    expect(find.text('english daisy'), findsOneWidget);
    expect(find.text('Bellis'), findsOneWidget);
    expect(find.text('Rosa'), findsOneWidget);
    expect(find.text('rosa'), findsNothing);
    expect(find.text('daisy family'), findsNothing);

    await tester.tap(find.byKey(guideBookListsKey));
    await tester.pump();
    expect(find.text('New in the book'), findsOneWidget);
    final context = tester.element(find.text('New in the book'));
    final date = MaterialLocalizations.of(context).formatMediumDate(latest);
    expect(find.text('2 plants · latest $date'), findsOneWidget);
    expect(find.text('6 years · 2019–2024'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Material) return false;
        final shape = widget.shape;
        if (shape is! RoundedRectangleBorder) return false;
        return shape.side.color == GuidePalette.gold && shape.side.width == 1.5;
      }),
      findsOneWidget,
    );
    expect(find.byType(GuidePhoto), findsNWidgets(6));

    await tester.tap(find.text('Alpine flowers'));
    await tester.pump();
    expect(openedList?.title, 'Alpine flowers');
  });

  testWidgets('genera show what is in flower and what you have seen',
      (tester) async {
    await _pump(
      tester,
      _Host(
        loadTaxa: (_) async => guideBookTaxa(index.families, index.genera),
        loadGenusNotes: (_) async => {
          'Bellis': const GuideGenusNote(inFlower: 2, seen: 1),
          'Rosa': const GuideGenusNote(inFlower: 0, seen: 0),
        },
        lists: const [],
      ),
    );

    expect(find.text('In flower now · 2 · you’ve seen 1'), findsNothing);

    await tester.tap(find.byKey(guideBookGeneraKey));
    await tester.pump();
    await tester.pump();

    expect(find.text('english daisy'), findsOneWidget);
    expect(
      find.text('In flower now · 2 · you’ve seen 1'),
      findsOneWidget,
    );
    expect(find.text('Rosa'), findsOneWidget);
    expect(find.text('you’ve seen 0'), findsNothing);
    expect(find.text('In flower now · 0'), findsNothing);
  });

  testWidgets('a failed family load can be tried again', (tester) async {
    var fails = true;
    await _pump(
      tester,
      _Host(
        loadTaxa: (_) async {
          if (fails) throw StateError('offline');
          return guideBookTaxa(index.families, index.genera);
        },
        lists: const [],
      ),
    );

    expect(
      find.text("This feature doesn't work without Internet connection."),
      findsOneWidget,
    );
    expect(find.text('105 plants · 2 families'), findsNothing);

    fails = false;
    await tester.tap(
      find.text("This feature doesn't work without Internet connection."),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('daisy family'), findsOneWidget);
  });

  testWidgets('All lists opens on the lists segment', (tester) async {
    await _pump(
      tester,
      _Host(
        start: GuideBookSegment.lists,
        loadTaxa: (_) async => guideBookTaxa(index.families, index.genera),
        lists: [
          GuideListCover(
            title: 'Meadows',
            photoPath: null,
            path: FirebaseDatabase.instance.ref('lists/meadows'),
            isNew: false,
            count: 11,
          ),
        ],
      ),
    );

    expect(find.text('Meadows'), findsOneWidget);
    expect(find.text('11 plants'), findsOneWidget);
    expect(find.text('daisy family'), findsNothing);
    final lists = tester.widget<Material>(find.byKey(guideBookListsKey));
    expect(lists.color, GuideColors.light.ink);
  });

  testWidgets('New in the book shows four thumbnails', (tester) async {
    await _pump(
      tester,
      _Host(
        start: GuideBookSegment.lists,
        loadTaxa: (_) async => guideBookTaxa(index.families, index.genera),
        lists: [
          GuideListCover(
            title: '',
            photoPath: 'photos/a.webp',
            thumbs: const [
              'photos/a.webp',
              'photos/b.webp',
              'photos/c.webp',
              'photos/d.webp',
            ],
            path: FirebaseDatabase.instance.ref('lists/new'),
            isNew: true,
            count: 24,
            latest: DateTime(2026, 9, 27),
          ),
        ],
      ),
    );

    expect(find.text('New in the book'), findsOneWidget);
    expect(find.byType(GuidePhoto), findsNWidgets(4));
  });
}

class _Host extends StatefulWidget {
  final GuideBookSegment start;
  final Future<GuideBookTaxa> Function(String languageCode) loadTaxa;
  final Future<Map<String, GuideGenusNote>> Function(
      List<GuideSearchTaxon> genera) loadGenusNotes;
  final List<GuideListCover>? lists;
  final void Function(BuildContext context, String listPath)? onOpenTaxon;
  final void Function(BuildContext context, GuideListCover cover)? onOpenList;

  const _Host({
    this.start = GuideBookSegment.families,
    required this.loadTaxa,
    this.loadGenusNotes = _noGenusNotes,
    required this.lists,
    this.onOpenTaxon,
    this.onOpenList,
  });

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late GuideBookSegment _segment = widget.start;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: GuideTheme(
        appearance: GuideAppearance.light,
        child: Scaffold(
          body: BookPage(
            lists: widget.lists,
            segment: _segment,
            onSegment: (segment) => setState(() => _segment = segment),
            onOpenFind: () {},
            loadTaxa: widget.loadTaxa,
            loadGenusNotes: widget.loadGenusNotes,
            onOpenTaxon: widget.onOpenTaxon,
            onOpenList: widget.onOpenList,
            onSearch: () {},
          ),
        ),
      ),
    );
  }
}

Future<Map<String, GuideGenusNote>> _noGenusNotes(
  List<GuideSearchTaxon> genera,
) async {
  return {};
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(page);
  await tester.pump();
}
