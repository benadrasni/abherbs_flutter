import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_search.dart';
import 'package:abherbs_flutter/guide/search_page.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final index = GuideSearchIndex.parse(
    vernacular: {
      'oxeye daisy': {
        firebaseAttributeIsLabel: true,
        firebaseAttributeList: {'1': 1},
      },
      'moon daisy': {
        firebaseAttributeList: {'1': 1},
      },
      'gänseblümchen': {
        firebaseAttributeIsLabel: true,
        firebaseAttributeList: [null, null, 1],
      },
      'daisy': {
        firebaseAttributeIsLabel: true,
        firebaseAttributeList: {'4': 1},
      },
      'orphan': {
        firebaseAttributeIsLabel: true,
        firebaseAttributeList: {'9': 1},
      },
    },
    latin: {
      'leucanthemum vulgare': {
        firebaseAttributeIsLabel: true,
        firebaseAttributeList: {'1': 1},
      },
      'bellis perennis': {
        firebaseAttributeIsLabel: true,
        firebaseAttributeList: {'2': 1},
      },
      'chrysanthemum leucanthemum': {
        firebaseAttributeList: {'1': 1},
      },
      'leucanthemum ircutianum': {
        firebaseAttributeIsLabel: true,
        firebaseAttributeList: {'4': 1},
      },
    },
    apg: {
      firebaseRootTaxon: {
        firebaseAPGType: 'Regnum',
        'Asterales': {
          firebaseAPGType: 'Ordo',
          'Asteraceae': {
            firebaseAPGType: 'Familia',
            firebaseAttributeCount: 93,
            firebaseAttributeList: {'1': 1},
            'Asteroideae': {
              firebaseAPGType: 'Subfamilia',
              firebaseAttributeCount: 40,
              'Bellis': {
                firebaseAPGType: 'Genus',
                firebaseAttributeCount: 2,
                firebaseAttributeList: {'2': 1},
              },
            },
          },
        },
        'Rosales': {
          firebaseAPGType: 'Ordo',
          'Rosaceae': {
            firebaseAPGType: 'Familia',
            firebaseAttributeCount: 12,
          },
        },
      },
    },
    taxonomyNames: {
      'Asteraceae': ['daisy family', 'composite'],
      'Bellis': ['english daisy'],
      'Rosaceae': ['rose family'],
    },
  );

  test('blank query and a name outside the book return nothing', () {
    expect(queryGuideSearch(index, '  ').isEmpty, isTrue);
    expect(queryGuideSearch(index, 'orchid').isEmpty, isTrue);
    expect(displayLatin('leucanthemum vulgare'), 'Leucanthemum vulgare');
    expect(displayLatin('Leucanthemum vulgare'), 'Leucanthemum vulgare');
  });

  test('vernacular, synonym, and diacritics find the plant', () {
    final byDaisy = queryGuideSearch(index, 'dais');
    expect(byDaisy.plants.map((plant) => plant.id), [4, 1]);
    expect(byDaisy.plants.first.labelKey, 'daisy');
    expect(byDaisy.genera.map((taxon) => taxon.latinName), ['Bellis']);
    expect(byDaisy.families.map((taxon) => taxon.latinName), ['Asteraceae']);

    expect(queryGuideSearch(index, 'ganse').plants.single.id, 2);
    expect(queryGuideSearch(index, 'chrys').plants.single.id, 1);
    expect(queryGuideSearch(index, 'orphan').plants, isEmpty);
  });

  test('a closer name stays ahead of a later one', () {
    final ranked = GuideSearchIndex.parse(
      vernacular: {
        'beet': _name('10', label: true),
        'beetroot': _name('20', label: true),
        'sugar beet': _name('30', label: true),
        'beets': _name('50'),
        'wild beet': _name('60'),
      },
      latin: {
        'zzzz ten': _name('10', label: true),
        'zzzz twenty': _name('20', label: true),
        'zzzz thirty': _name('30', label: true),
        'beet alba': _name('40', label: true),
        'zzzz fifty': _name('50', label: true),
        'zzzz sixty': _name('60', label: true),
        'xx beet': _name('70', label: true),
        'zzzz eighty': _name('80', label: true),
        'beetonia minor': _name('80'),
        'zzzz ninety': _name('90', label: true),
        'xx beetonia': _name('90'),
      },
      apg: const {},
      taxonomyNames: const {},
    );
    expect(
      queryGuideSearch(ranked, 'beet').plants.map((plant) => plant.id),
      [10, 20, 40, 30, 70, 50, 80, 60],
    );
  });

  test('families stop at four and skip an empty family', () {
    final taxa = GuideSearchIndex.parse(
      vernacular: const {},
      latin: const {},
      apg: {
        firebaseRootTaxon: {
          firebaseAPGType: 'Regnum',
          'Rosales': {
            firebaseAPGType: 'Ordo',
            'Rosaceae': _family(4),
            'Roridulaceae': _family(1),
            'Rogueaceae': _family(0),
          },
          'Other': {
            firebaseAPGType: 'Ordo',
            'Bromeliaceae': _family(2),
            'Droseraceae': _family(2),
            'Proteaceae': _family(2),
            'Scrophulariaceae': _family(2),
          },
        },
      },
      taxonomyNames: const {'Rosaceae': 'ro'},
    );
    expect(
      queryGuideSearch(taxa, 'ro').families.map((taxon) => taxon.latinName),
      ['Rosaceae', 'Roridulaceae', 'Bromeliaceae', 'Droseraceae'],
    );
  });

  test('family and genus names come from a string, list, or map', () {
    final named = GuideSearchIndex.parse(
      vernacular: const {},
      latin: const {},
      apg: {
        firebaseRootTaxon: {
          firebaseAPGType: 'Regnum',
          'Rosales': {
            firebaseAPGType: 'Ordo',
            'Rosaceae': _family(4),
          },
          'Asterales': {
            firebaseAPGType: 'Ordo',
            'Asteraceae': {
              ..._family(9),
              'Bellis': {
                firebaseAPGType: 'Genus',
                firebaseAttributeCount: 2,
              },
            },
          },
        },
      },
      taxonomyNames: const {
        'Rosaceae': 'rose family',
        'Bellis': {'en': 'english daisy', 'skip': ''},
        'Asteraceae': ['daisy family', '', 3],
      },
    );
    expect(
      queryGuideSearch(named, 'rose family').families.single.latinName,
      'Rosaceae',
    );
    expect(
      queryGuideSearch(named, 'english daisy').genera.single.vernaculars,
      ['english daisy'],
    );
    expect(
      queryGuideSearch(named, 'daisy family').families.single.latinName,
      'Asteraceae',
    );
    expect(queryGuideSearch(named, 'skip').isEmpty, isTrue);
  });

  test('search folds diacritics and capitalizes the genus', () {
    expect(foldSearch('  Gänseblümchen '), 'ganseblumchen');
    expect(displayLatin(''), '');
    expect(displayLatin('  bellis perennis'), 'Bellis perennis');
    expect(displayLatin('Bellis'), 'Bellis');
  });

  test('families and genera stay on their ranks', () {
    final family = queryGuideSearch(index, 'aster').families.single;
    expect(family.latinName, 'Asteraceae');
    expect(family.count, 93);
    expect(
      family.listPath,
      '$firebaseAPGIV/$firebaseRootTaxon/Asterales/Asteraceae/$firebaseAttributeList',
    );
    expect(queryGuideSearch(index, 'aster').genera, isEmpty);
    expect(queryGuideSearch(index, 'subfamilia').isEmpty, isTrue);

    final genus = queryGuideSearch(index, 'bellis').genera.single;
    expect(genus.illustrationFamily, 'Asteraceae');
    expect(genus.vernaculars, ['english daisy']);
    expect(
      genus.listPath,
      '$firebaseAPGIV/$firebaseRootTaxon/Asterales/Asteraceae/Asteroideae/Bellis/$firebaseAttributeList',
    );
  });

  test('plant results stop at eight', () {
    final names = <String, dynamic>{};
    final latin = <String, dynamic>{};
    for (var id = 0; id < 9; id++) {
      final key = id.toString().padLeft(2, '0');
      names['daisy $key'] = {
        firebaseAttributeIsLabel: true,
        firebaseAttributeList: {key: 1},
      };
      latin['genus $key'] = {
        firebaseAttributeIsLabel: true,
        firebaseAttributeList: {'$id': 1},
      };
    }
    final many = GuideSearchIndex.parse(
      vernacular: names,
      latin: latin,
      apg: const {},
      taxonomyNames: const {},
    );
    final plants = queryGuideSearch(many, 'daisy').plants;
    expect(plants, hasLength(guideSearchPlantLimit));
    expect(plants.map((plant) => plant.id), [0, 1, 2, 3, 4, 5, 6, 7]);
  });

  testWidgets('search lists plants, then genera, then families',
      (tester) async {
    await tester.pumpWidget(_app(index: index));
    await tester.pump();
    await tester.pump();

    expect(find.text('Find'), findsOneWidget);
    expect(find.text('PLANTS'), findsNothing);
    expect(find.text('Name, Latin, family, genus'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'dais');
    await tester.pump();
    await tester.pump();

    expect(find.text('Oxeye daisy'), findsOneWidget);
    expect(find.text('Leucanthemum vulgare'), findsOneWidget);
    expect(find.text('daisy'), findsOneWidget);
    expect(find.text('english daisy'), findsOneWidget);
    expect(find.text('Bellis'), findsOneWidget);
    expect(find.text('daisy family'), findsOneWidget);
    expect(find.text('Asteraceae'), findsOneWidget);
    expect(find.text('93'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('PLANTS')).dy,
      lessThan(tester.getTopLeft(find.text('GENERA')).dy),
    );
    expect(
      tester.getTopLeft(find.text('GENERA')).dy,
      lessThan(tester.getTopLeft(find.text('FAMILIES')).dy),
    );

    String? opened;
    String? taxonPath;
    var camera = false;
    await tester.pumpWidget(
      _app(
        index: index,
        onOpenPlant: (_, name) => opened = name,
        onOpenTaxon: (_, path) => taxonPath = path,
        onOpenCamera: (_) => camera = true,
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'dais');
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Oxeye daisy'));
    await tester.pump();
    expect(opened, 'Leucanthemum vulgare');

    await tester.tap(find.text('Asteraceae'));
    await tester.pump();
    expect(
      taxonPath,
      '$firebaseAPGIV/$firebaseRootTaxon/Asterales/Asteraceae/$firebaseAttributeList',
    );

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.textContaining('Nothing in the book'), findsOneWidget);

    await tester.tap(find.text('Try a photo'));
    await tester.pump();
    expect(camera, isTrue);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.textContaining('Nothing in the book'), findsNothing);
    expect(find.text('PLANTS'), findsNothing);
  });

  testWidgets('a loaded card replaces the indexed label', (tester) async {
    final card = Completer<GuidePlantCard>();
    String? opened;
    await tester.pumpWidget(
      _app(
        index: index,
        loadCard: (languageCode, id) => card.future,
        onOpenPlant: (context, name) => opened = name,
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'leucanthemum vulgare');
    await tester.pump();
    expect(find.text('oxeye daisy'), findsOneWidget);
    expect(find.text('Leucanthemum vulgare'), findsOneWidget);

    card.complete(const GuidePlantCard(label: 'moon daisy', latinName: ''));
    await tester.pump();
    expect(find.text('moon daisy'), findsOneWidget);
    expect(find.text('oxeye daisy'), findsNothing);

    await tester.tap(find.text('moon daisy'));
    await tester.pump();
    expect(opened, 'Leucanthemum vulgare');
  });

  testWidgets('the index can fail and then load', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _app(
        index: index,
        loadIndex: (languageCode) async {
          attempts++;
          if (attempts == 1) throw StateError('offline');
          return index;
        },
      ),
    );
    await tester.pump();
    expect(find.textContaining('without Internet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'daisy');
    await tester.tap(find.textContaining('without Internet'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('PLANTS'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('daisy')),
      findsOneWidget,
    );
  });

  testWidgets('search waits for the index', (tester) async {
    final ready = Completer<GuideSearchIndex>();
    await tester.pumpWidget(
      _app(index: index, loadIndex: (languageCode) => ready.future),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Name, Latin, family, genus'), findsOneWidget);

    ready.complete(index);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a genus hides a repeated Latin line', (tester) async {
    final genus = GuideSearchIndex.parse(
      vernacular: const {},
      latin: const {},
      apg: {
        firebaseRootTaxon: {
          firebaseAPGType: 'Regnum',
          'Asterales': {
            firebaseAPGType: 'Ordo',
            'Asteraceae': {
              firebaseAPGType: 'Familia',
              firebaseAttributeCount: 1,
              'Bellis': {
                firebaseAPGType: 'Genus',
                firebaseAttributeCount: 2,
              },
            },
          },
        },
      },
      taxonomyNames: const {'Bellis': 'bellis'},
    );
    await tester.pumpWidget(_app(index: genus));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'bell');
    await tester.pump();
    expect(find.text('GENERA'), findsOneWidget);
    expect(find.text('Bellis'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('FAMILIES'), findsNothing);
  });

  testWidgets('key it out returns to Find', (tester) async {
    var showedFind = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder<void>(
                  pageBuilder: (context, animation, secondary) =>
                      GuideSearchPage(
                    fromBook: true,
                    onShowFind: () => showedFind = true,
                    loadIndex: (languageCode) async => index,
                    loadCard: (languageCode, id) async =>
                        const GuidePlantCard(),
                    onOpenPlant: (context, name) {},
                    onOpenTaxon: (context, path) {},
                    onOpenCamera: (context) {},
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Book'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    await tester.tap(find.text('key it out'));
    await tester.pump();
    await tester.pump();

    expect(showedFind, isTrue);
    expect(find.text('Open'), findsOneWidget);
  });
}

Map<String, dynamic> _name(String id, {bool label = false}) {
  return {
    if (label) firebaseAttributeIsLabel: true,
    firebaseAttributeList: {id: 1},
  };
}

Map<String, dynamic> _family(int count) {
  return {
    firebaseAPGType: 'Familia',
    firebaseAttributeCount: count,
  };
}

Widget _app({
  required GuideSearchIndex index,
  Future<GuideSearchIndex> Function(String languageCode)? loadIndex,
  Future<GuidePlantCard> Function(String languageCode, int id)? loadCard,
  void Function(BuildContext context, String latinName)? onOpenPlant,
  void Function(BuildContext context, String listPath)? onOpenTaxon,
  void Function(BuildContext context)? onOpenCamera,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: GuideSearchPage(
      loadIndex: loadIndex ?? (_) async => index,
      loadCard: loadCard ??
          (languageCode, id) async {
            if (id == 1) {
              return const GuidePlantCard(
                latinName: 'Leucanthemum vulgare',
                label: 'Oxeye daisy',
                photoPath: 'photos/leucanthemum.jpg',
              );
            }
            return GuidePlantCard(
              latinName: displayLatin(index.latinKeys[id] ?? ''),
            );
          },
      onOpenPlant: onOpenPlant ?? (context, name) {},
      onOpenTaxon: onOpenTaxon ?? (context, path) {},
      onOpenCamera: onOpenCamera ?? (context) {},
    ),
  );
}
