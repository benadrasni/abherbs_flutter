import 'package:abherbs_flutter/data/plant_translation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/species/guide_species.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:abherbs_flutter/species/schema_page.dart';
import 'package:abherbs_flutter/species/species_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    GuideAppearanceController.instance.resetForTest();
  });

  test('inflorescence types keep the stored order and drop unknown keys', () {
    expect(
      guideInflorescenceTypes(['head', 'catkin', 'corymb', 'head']),
      ['head', 'corymb'],
    );
    expect(
      guideInflorescenceTypes({'1': 'corymb', '0': 'capitulum', '2': 'nope'}),
      ['capitulum', 'corymb'],
    );
    expect(guideInflorescenceTypes(null), isEmpty);
    expect(guideInflorescenceTypes('head'), isEmpty);
    final species = assembleGuideSpecies(
      name: 'Leucanthemum vulgare',
      plant: {
        'id': 69,
        'name': 'Leucanthemum vulgare',
        'inflorescenceType': ['head'],
      },
      translation: PlantTranslation(),
      vernaculars: const {},
      sightings: const [],
    );
    expect(species!.inflorescenceTypes, ['head']);
    expect(species.id, '69');
  });

  testWidgets('flower parts run down the left column, then the right',
      (tester) async {
    await _pump(
      tester,
      _app(const GuideFlowerSchemaPage(backLabel: 'Oxeye daisy')),
      size: const Size(390, 1200),
    );

    expect(find.text('FLOWER'), findsOneWidget);
    expect(find.text('Parts of a flower'), findsOneWidget);
    expect(
      find.text('A typical complete flower. The numbers match the list.'),
      findsOneWidget,
    );

    final first = tester.getTopLeft(find.byKey(guideFlowerPartKey(1)));
    final second = tester.getTopLeft(find.byKey(guideFlowerPartKey(2)));
    final eighth = tester.getTopLeft(find.byKey(guideFlowerPartKey(8)));
    final ninth = tester.getTopLeft(find.byKey(guideFlowerPartKey(9)));
    final tenth = tester.getTopLeft(find.byKey(guideFlowerPartKey(10)));
    final last = tester.getTopLeft(find.byKey(guideFlowerPartKey(17)));

    expect(second.dy, greaterThan(first.dy));
    expect(ninth.dy, greaterThan(eighth.dy));
    expect(tenth.dx, greaterThan(first.dx + 80));
    expect(tenth.dy, closeTo(first.dy, 1));
    expect(last.dy, closeTo(eighth.dy, 1));
    expect(last.dx, greaterThan(eighth.dx + 80));

    final well = tester.widget<DecoratedBox>(find.byKey(guideFlowerWellKey));
    final plate = well.decoration as BoxDecoration;
    expect(plate.color, GuidePalette.paper);
    expect(plate.borderRadius, BorderRadius.circular(16));
    expect(
      (tester.widget<Image>(find.byKey(guideFlowerPlateKey)).image
              as AssetImage)
          .assetName,
      guideFlowerSchemaAsset,
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(guideFlowerPartKey(1)),
              matching: find.text('1'),
            ),
          )
          .style!
          .color,
      GuidePalette.gold,
    );
  });

  testWidgets('a dark flower plate is the light-line drawing on no ground',
      (tester) async {
    GuideAppearanceController.instance.apply(GuideAppearance.dark);
    await _pump(
      tester,
      _app(const GuideFlowerSchemaPage(backLabel: 'Oxeye daisy')),
    );

    final well = tester.widget<DecoratedBox>(find.byKey(guideFlowerWellKey));
    expect((well.decoration as BoxDecoration).color, Colors.transparent);
    expect(
      (tester.widget<Image>(find.byKey(guideFlowerPlateKey)).image
              as AssetImage)
          .assetName,
      guideFlowerSchemaDarkAsset,
    );
    expect(
      tester.widget<Text>(find.text('Parts of a flower')).style!.color,
      GuideColors.dark.ink,
    );
  });

  testWidgets('the stored type is marked, and the first one is heavier',
      (tester) async {
    await _pump(
      tester,
      _app(const GuideInflorescencePage(
        backLabel: 'Feverfew',
        types: ['capitulum', 'corymb'],
      )),
      size: const Size(390, 1400),
    );

    expect(find.text('INFLORESCENCE'), findsOneWidget);
    expect(find.text('Types of inflorescence'), findsOneWidget);
    expect(
      find.text('Feverfew · capitulum, also corymb'),
      findsOneWidget,
    );
    expect(_cell(tester, 'capitulum').color, const Color(0xFFFFFFFF));
    expect(_cell(tester, 'corymb').color, const Color(0xFFFFFFFF));
    expect(_cell(tester, 'raceme').color, const Color(0xFFFFFFFF));
    expect(_border(_cell(tester, 'capitulum')).width, 3);
    expect(_border(_cell(tester, 'corymb')).width, 2);
    expect(_border(_cell(tester, 'raceme')).width, 1);
    expect(_border(_cell(tester, 'capitulum')).color, const Color(0xFF3E5344));
    expect(_name(tester, 'capitulum').fontWeight, FontWeight.w600);
    expect(_name(tester, 'capitulum').color, const Color(0xFF3E5344));
    expect(_name(tester, 'raceme').fontWeight, FontWeight.w400);
    expect(_name(tester, 'raceme').color, const Color(0xFF1A1612));

    GuideAppearanceController.instance.apply(GuideAppearance.dark);
    await tester.pump();
    expect(_cell(tester, 'capitulum').color, const Color(0xFFFFFFFF));
    expect(_border(_cell(tester, 'capitulum')).color, const Color(0xFF3E5344));
  });

  testWidgets('a solitary flower marks nothing', (tester) async {
    await _pump(
      tester,
      _app(const GuideInflorescencePage(
        backLabel: 'Wood anemone',
        types: [],
      )),
      size: const Size(390, 1400),
    );

    expect(
      find.text('Wood anemone · a solitary flower, so nothing here is marked'),
      findsOneWidget,
    );
    for (final key in guideInflorescenceKeys) {
      expect(_border(_cell(tester, key)).width, 1);
      expect(_border(_cell(tester, key)).color, const Color(0xFFE6E0D4));
    }
  });

  testWidgets('flower and inflorescence headings open the diagrams',
      (tester) async {
    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Leucanthemum vulgare',
        initial: _daisy(),
        load: (_) async => null,
        imageBuilder: _swatch,
        month: 7,
      )),
      size: const Size(390, 2400),
    );

    expect(find.byType(GuideSchemaLink), findsNWidgets(2));
    expect(find.byKey(guideSchemaFlowerKey), findsOneWidget);
    expect(find.byKey(guideSchemaInflorescenceKey), findsOneWidget);

    final flower = find.descendant(
      of: find.byKey(guideSchemaFlowerKey),
      matching: find.text('Flower'),
    );
    await tester.ensureVisible(flower);
    await tester.pumpAndSettle();
    await tester.tap(flower);
    await tester.pumpAndSettle();
    expect(find.text('Parts of a flower'), findsOneWidget);
    expect(find.widgetWithText(GuideBackButton, 'oxeye daisy'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(GuideBackButton),
      matching: find.text('oxeye daisy'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Parts of a flower'), findsNothing);
    expect(find.byKey(guideSchemaFlowerKey), findsOneWidget);

    final inflorescence = find.descendant(
      of: find.byKey(guideSchemaInflorescenceKey),
      matching: find.text('Inflorescence'),
    );
    await tester.ensureVisible(inflorescence);
    await tester.pumpAndSettle();
    await tester.tap(inflorescence);
    await tester.pumpAndSettle();
    expect(find.text('oxeye daisy · head'), findsOneWidget);
    expect(_border(_cell(tester, 'head')).width, 3);
    expect(_border(_cell(tester, 'capitulum')).width, 1);
  });
}

BoxDecoration _cell(WidgetTester tester, String type) {
  return tester
      .widget<DecoratedBox>(find.byKey(guideInflorescenceCellKey(type)))
      .decoration as BoxDecoration;
}

BorderSide _border(BoxDecoration decoration) {
  return (decoration.border! as Border).top;
}

TextStyle _name(WidgetTester tester, String label) {
  return tester
      .widget<Text>(find.descendant(
        of: find.byKey(guideInflorescenceCellKey(label)),
        matching: find.text(label),
      ))
      .style!;
}

GuideSpecies _daisy() {
  return assembleGuideSpecies(
    name: 'Leucanthemum vulgare',
    plant: {
      'id': 69,
      'name': 'Leucanthemum vulgare',
      'inflorescenceType': ['head'],
    },
    translation: PlantTranslation()
      ..label = 'oxeye daisy'
      ..flower = 'White rays around a yellow disc.'
      ..inflorescence = 'A single head.',
    vernaculars: const {},
    sightings: const [],
  )!;
}

Widget _swatch(String path, BoxFit fit, double width, double height) {
  return const ColoredBox(color: Color(0xFF88AA77));
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

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(page);
  await tester.pump();
}
