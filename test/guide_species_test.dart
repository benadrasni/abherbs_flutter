import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_camera.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_species.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/guide/species_page.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/app_banner_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  test('height uses centimetres under a metre and metres above', () {
    expect(guideHeightText(20, 80), '20–80 cm');
    expect(guideHeightText(300, 2000), '3–20 m');
    expect(guideHeightText(150, 180), '1.5–1.8 m');
    expect(guideHeightText(0, 0), isEmpty);
  });

  test('toxicity class is poisonous, slight, or none recorded', () {
    expect(guideToxicityClass(1), 1);
    expect(guideToxicityClass(2.0), 2);
    expect(guideToxicityClass(null), 0);
    expect(guideToxicityClass('1'), 0);
    expect(
      guideToxicityClassLabel(
        toxicityClass: 1,
        poisonous: 'poisonous plant',
        slight: 'slightly poisonous plant',
        none: 'None recorded',
      ),
      'poisonous plant',
    );
    expect(
      guideToxicityClassLabel(
        toxicityClass: 2,
        poisonous: 'poisonous plant',
        slight: 'slightly poisonous plant',
        none: 'None recorded',
      ),
      'slightly poisonous plant',
    );
    expect(
      guideToxicityClassLabel(
        toxicityClass: 0,
        poisonous: 'poisonous plant',
        slight: 'slightly poisonous plant',
        none: 'None recorded',
      ),
      'None recorded',
    );
    final species = assembleGuideSpecies(
      name: 'Anemone nemorosa',
      plant: {
        'id': 1,
        'name': 'Anemone nemorosa',
        'toxicityClass': 1,
      },
      translation: PlantTranslation(),
      vernaculars: const {},
      sightings: const [],
    );
    expect(species!.toxicityClass, 1);
  });

  test('body sections skip empty text and None', () {
    final translation = PlantTranslation()
      ..flower = 'White rays.'
      ..fruit = 'None'
      ..leaf = '   '
      ..stem = 'none.'
      ..toxicity = 'Skin irritant';
    expect(
      guideSpeciesSections(translation).map((section) => section.id),
      ['flower', 'toxicity'],
    );
  });

  test('ranks are the seven nearest and skip kingdom', () {
    final ranks = guideSpeciesRanks({
      '00_Sectio': 'Globiflorae',
      '01_Genus': 'Digitalis',
      '02_Tribus': 'Digitalideae',
      '03_Familia': 'Plantaginaceae',
      '04_Ordo': 'Lamiales',
      '05_Cladus': 'Lamiids',
      '06_Cladus': 'Asterids',
      '07_Cladus': 'Campanulids',
      '11_Regnum': 'Plantae',
      '12_Superregnum': 'Eukaryota',
    }, const {});
    expect(ranks.map((rank) => '${rank.rank} ${rank.latin}'), [
      'Sectio Globiflorae',
      'Genus Digitalis',
      'Tribus Digitalideae',
      'Familia Plantaginaceae',
      'Ordo Lamiales',
      'Cladus Lamiids',
      'Cladus Asterids',
    ]);

    final short = guideSpeciesRanks({
      '00_Genus': 'Bellis',
      '11_Regnum': 'Plantae',
      '12_Superregnum': 'Eukaryota',
    }, const {});
    expect(short.map((rank) => rank.latin), ['Bellis']);
  });

  test('family is the Familia rank, not a subfamily', () {
    expect(
      guideFamilyLatin({
        '02_Subfamilia': 'Asteroideae',
        '03_Familia': 'Asteraceae',
      }),
      'Asteraceae',
    );
    expect(guideFamilyLatin({'03_Subfamilia': 'Asteroideae'}), isNull);
    expect(
      guideOrderLatin({
        '04_Subordo': 'Asteranae',
        '05_Ordo': 'Asterales',
      }),
      'Asterales',
    );
    expect(guideOrderLatin({'05_Subordo': 'Asteranae'}), isNull);
  });

  test('order and family sit above the name, in the language', () {
    expect(
      guideOrderFamilyLine(
        orderLabel: 'aster order',
        orderLatin: 'Asterales',
        familyLabel: 'daisy family',
        familyLatin: 'Asteraceae',
      ),
      'aster order · daisy family',
    );
    expect(
      guideOrderFamilyLine(
        orderLatin: 'Asterales',
        familyLatin: 'Asteraceae',
      ),
      'Asterales · Asteraceae',
    );
    expect(
      guideOrderFamilyLine(familyLabel: 'daisy family'),
      'daisy family',
    );
    expect(guideOrderFamilyLine(), isEmpty);

    final apg = {
      '00_Sectio': 'A',
      '01_Subgenus': 'B',
      '02_Genus': 'C',
      '03_Subtribus': 'D',
      '04_Tribus': 'E',
      '05_Subfamilia': 'F',
      '06_Familia': 'Asteraceae',
      '07_Ordo': 'Asterales',
    };
    expect(
      guideSpeciesRanks(apg, const {}).map((rank) => rank.latin),
      isNot(contains('Asterales')),
    );
    expect(
      guideSpeciesTaxonLatins(apg),
      containsAll(['Asteraceae', 'Asterales']),
    );
  });

  test('a one-plant notification opens the guide species page', () {
    final route = guideNotificationPlantRoute(' Bellis perennis ');
    expect(route?.settings.name, guideSpeciesRouteName);
    expect(guideNotificationPlantRoute(''), isNull);
    expect(guideNotificationPlantRoute('   '), isNull);
    expect(guideNotificationPlantRoute(null), isNull);
  });

  test('a plant id of zero is still a catalog row', () {
    expect(guidePlantRecord({'id': 0, 'name': 'Acer campestre'}), isTrue);
    expect(guidePlantRecord({'name': 'Missing'}), isFalse);
    expect(guidePlantRecord(null), isFalse);
    final species = assembleGuideSpecies(
      name: 'Acer campestre',
      plant: {'id': 0, 'name': 'Acer campestre'},
      translation: PlantTranslation(),
      vernaculars: const {},
      sightings: const [],
    );
    expect(species, isNotNull);
    expect(species!.name, 'Acer campestre');
  });

  test('public sightings need a photo and a date after the epoch', () {
    final sightings = guideSightings({
      'old': {
        'status': 'public',
        'id': 'old',
        'photoPaths': ['old.jpg'],
        'date': {'time': 1000},
      },
      'review': {
        'status': 'review',
        'photoPaths': ['review.jpg'],
        'date': {'time': 9000},
      },
      'blank': {
        'status': 'public',
        'photoPaths': <String>[],
        'date': {'time': 8000},
      },
      'private': {
        'photoPaths': ['hidden.jpg'],
        'date': {'time': 7000},
      },
      'epoch': {
        'status': 'public',
        'id': 'epoch',
        'photoPaths': ['epoch.jpg'],
        'date': {'time': 0},
      },
      'new': {
        'status': 'public',
        'id': 'new',
        'photoPaths': ['new.jpg'],
        'date': {'time': 5000},
      },
    });
    expect(sightings.map((sighting) => sighting.id), ['new', 'old', 'epoch']);
    expect(sightings.last.when, isNull);
    expect(sightings.first.photoPath, '${storagePhotos}new.jpg');
  });

  test('seen summary uses the latest real date', () {
    final seen = guideSpeciesSeen([
      {
        'photoPaths': ['old.jpg'],
        'date': {'time': 1000},
      },
      {
        'photoPaths': ['new.jpg'],
        'date': {'time': 5000},
      },
      {
        'photoPaths': ['epoch.jpg'],
        'date': {'time': 0},
      },
    ]);
    expect(seen, isNotNull);
    expect(seen!.count, 3);
    expect(seen.last, DateTime.fromMillisecondsSinceEpoch(5000));
    expect(seen.photoPath, '${storagePhotos}new.jpg');
  });

  test('an older photo does not replace the latest find', () {
    final current = GuideSpeciesSeen(
      count: 1,
      last: DateTime(2026, 8, 1),
      photoPath: 'photos/current.jpg',
    );
    final older = guideSeenAfterAdd(
      current,
      GuideSeenDraft(
        plant: 'Bellis perennis',
        when: DateTime(2026, 1, 1),
        photoPath: 'photos/old.jpg',
        fromPhoto: true,
      ),
    );
    expect(older.count, 2);
    expect(older.last, DateTime(2026, 8, 1));
    expect(older.photoPath, 'photos/current.jpg');

    final newer = guideSeenAfterAdd(
      current,
      GuideSeenDraft(
        plant: 'Bellis perennis',
        when: DateTime(2026, 9, 1),
      ),
    );
    expect(newer.last, DateTime(2026, 9, 1));
    expect(newer.photoPath, 'photos/current.jpg');
  });

  test('source hosts drop a repeated www prefix', () {
    final links = guideSourceLinks([
      'https://www.wikipedia.org/wiki/A',
      'https://wikipedia.org/wiki/B',
      'https://en.wikipedia.org/wiki/C',
    ]);
    expect(
        links.map((link) => link.label), ['wikipedia.org', 'en.wikipedia.org']);
  });

  test('the distribution image sits beside the plate name', () {
    expect(
      guideDistributionPath('illustrations/Leucanthemum_vulgare.webp'),
      '${storagePhotos}illustrations/Leucanthemum_vulgare_distribution.webp',
    );
    expect(guideDistributionPath('plates/leucanthemum'), isNull);
  });

  test('bold plant text keeps the space after the closing tag', () {
    final runs = guideTextRuns('The <b>ray</b> florets');
    expect(
      runs.map((run) => '${run.bold}:${run.text}'),
      ['false:The ', 'true:ray', 'false: florets'],
    );
  });

  testWidgets('the species page shows the oxeye daisy entry', (tester) async {
    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Leucanthemum vulgare',
        initial: _daisy(),
        load: (_) => Future<GuideSpecies?>.error(StateError('unused')),
        imageBuilder: _swatch,
        month: 7,
      )),
      size: const Size(390, 4200),
    );

    expect(find.text('aster order · daisy family'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('aster order · daisy family')).dy,
      lessThan(tester.getTopLeft(find.text('oxeye daisy')).dy),
    );
    expect(find.text('oxeye daisy'), findsOneWidget);
    expect(find.textContaining('Leucanthemum vulgare'), findsWidgets);
    expect(find.textContaining('Lam.'), findsOneWidget);
    expect(find.text('Also moon daisy, bruisewort'), findsOneWidget);
    expect(find.text('20–80 cm'), findsOneWidget);
    expect(find.text('Flowers May–October'), findsOneWidget);
    expect(find.text('A daisy of lawns.'), findsOneWidget);
    expect(find.text('Skin irritant'), findsOneWidget);
    expect(find.text('Fruit'), findsNothing);
    expect(find.text('None'), findsNothing);
    expect(find.text('Trivia'), findsNothing);
    expect(find.text('None recorded'), findsOneWidget);
    expect(find.text('NOTES'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('USES'), findsOneWidget);
    expect(
      find.text('Traditional or culinary notes, not medical advice.'),
      findsOneWidget,
    );
    final toxicity =
        tester.widget<Text>(find.byKey(const Key('guide-toxicity-value')));
    expect(toxicity.data, 'None recorded');
    expect(toxicity.style!.color, GuidePalette.ink);
    final notesBorder = _asideBorder(tester, const Key('guide-aside-trivia'));
    expect(notesBorder.color, GuidePalette.gold);
    expect(notesBorder.width, 3);
    final usesBorder = _asideBorder(tester, const Key('guide-aside-herbalism'));
    expect(usesBorder.color, GuidePalette.moss);
    expect(usesBorder.width, 3);
    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(
      (y('None recorded') - y('20–80 cm')).abs(),
      lessThan(8),
    );
    expect(y('None recorded'), lessThan(y('Flowers May–October')));
    expect(y('None recorded'), lessThan(y('A daisy of lawns.')));
    expect(y('Notes'), lessThan(y('A daisy of lawns.')));
    expect(y('A daisy of lawns.'), lessThan(y('NOTES')));
    expect(y('NOTES'), lessThan(y('White rays around a yellow disc.')));
    expect(y('Skin irritant'), lessThan(y('USES')));
    expect(y('USES'), lessThan(y('A bitter tea.')));
    expect(find.text('3 photos'), findsOneWidget);
    expect(find.text('Plate'), findsOneWidget);
    expect(
      find.text(DateFormat.yMMMM('en').format(DateTime(2026, 9, 12))),
      findsOneWidget,
    );
    expect(find.textContaining('1 shared by app users'), findsOneWidget);
    expect(find.text('wikipedia.org'), findsOneWidget);
    expect(find.byType(AppBannerAd), findsNothing);

    final july = _monthDecoration(tester, 7);
    final january = _monthDecoration(tester, 1);
    expect(july.color, GuidePalette.moss);
    expect((july.border! as Border).top.color, GuidePalette.madder);
    expect(january.color, GuidePalette.paper2);
    expect((january.border! as Border).top.color, Colors.transparent);
  });

  testWidgets('a poisonous plant warns, and missing notes are left out',
      (tester) async {
    final translation = PlantTranslation()
      ..description = 'A woodland anemone.'
      ..flower = 'Six white tepals.'
      ..toxicity = 'None'
      ..herbalism = 'None'
      ..trivia = '';
    final species = assembleGuideSpecies(
      name: 'Anemone nemorosa',
      plant: {
        'id': 1,
        'name': 'Anemone nemorosa',
        'toxicityClass': 1,
        'heightFrom': 10,
        'heightTo': 25,
      },
      translation: translation,
      vernaculars: const {},
      sightings: const [],
    )!;
    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Anemone nemorosa',
        initial: species,
        load: (_) async => null,
        imageBuilder: _swatch,
        month: 4,
      )),
    );

    final value =
        tester.widget<Text>(find.byKey(const Key('guide-toxicity-value')));
    expect(value.data, 'Poisonous');
    expect(value.style!.color, GuidePalette.madder);
    expect(find.text('NOTES'), findsNothing);
    expect(find.text('USES'), findsNothing);
    expect(
      find.text('Traditional or culinary notes, not medical advice.'),
      findsNothing,
    );
    expect(find.text('None'), findsNothing);
    expect(find.text('Toxicity'), findsOneWidget);
    expect(find.text('Six white tepals.'), findsOneWidget);
  });

  testWidgets('a taxonomy chip scrolls the entry', (tester) async {
    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Leucanthemum vulgare',
        initial: _daisy(),
        load: (_) async => null,
        imageBuilder: _swatch,
        month: 7,
      )),
      size: const Size(390, 1100),
    );

    final position = tester
        .state<ScrollableState>(find
            .descendant(
              of: find.byKey(const Key('guide-species-scroll')),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              ),
            )
            .first)
        .position;
    expect(position.maxScrollExtent, greaterThan(0));
    final chips = tester.state<ScrollableState>(find.descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      matching: find.byType(Scrollable),
    ));
    final chipLeft = tester.getTopLeft(find.text('Taxonomy')).dx;
    chips.position.jumpTo(
      (chips.position.pixels + chipLeft - 24).clamp(
        0.0,
        chips.position.maxScrollExtent,
      ),
    );
    await tester.pump();
    expect(
        tester.getTopLeft(find.text('Taxonomy')).dx, inInclusiveRange(0, 300));
    final before = position.pixels;
    await tester.tap(find.text('Taxonomy'));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(before));
  });

  testWidgets('cancelling the photo picker saves nothing', (tester) async {
    final saved = <GuideSeenDraft>[];
    var refreshed = 0;
    GuideTabs.refreshSeen = () => refreshed++;
    addTearDown(() => GuideTabs.refreshSeen = null);

    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Leucanthemum vulgare',
        initial: _daisy(),
        load: (_) async => null,
        imageBuilder: _swatch,
        month: 7,
        isSignedIn: () => true,
        pickPhoto: (_) async => null,
        saveSeen: (draft) async => saved.add(draft),
      )),
    );

    await tester.tap(find.text('+ Add to Seen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(saved, isEmpty);
    expect(refreshed, 0);
    expect(find.text('Without a photo'), findsNothing);
    expect(find.text('From your photos'), findsNothing);
    expect(find.text('Added to Seen.'), findsNothing);
    expect(find.textContaining('Seen by you'), findsNothing);
  });

  testWidgets('a guest adds a photo without signing in', (tester) async {
    final saved = <GuideSeenDraft>[];
    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Leucanthemum vulgare',
        initial: _daisy(),
        load: (_) async => null,
        imageBuilder: _swatch,
        month: 7,
        isSignedIn: () => true,
        onSignIn: (_) async => fail('guest was sent to sign in'),
        pickPhoto: (_) async => GuideSeenPhoto(
          relativePath: 'observations/guest/lv_1.jpg',
          when: DateTime(2026, 7, 4),
          latitude: 48.1,
          longitude: 17.1,
          fromPhoto: true,
        ),
        saveSeen: (draft) async => saved.add(draft),
      )),
    );

    await tester.tap(find.text('+ Add to Seen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(saved, hasLength(1));
    expect(saved.single.photoPath, 'observations/guest/lv_1.jpg');
    expect(find.textContaining('Seen by you'), findsOneWidget);
    await _clearSnackBar(tester);
  });

  testWidgets('a photo supplies the date and place', (tester) async {
    final saved = <GuideSeenDraft>[];
    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Leucanthemum vulgare',
        initial: _daisy(),
        load: (_) async => null,
        imageBuilder: _swatch,
        month: 7,
        isSignedIn: () => true,
        pickPhoto: (_) async => GuideSeenPhoto(
          relativePath: 'observations/uid/lv_1.jpg',
          when: DateTime(2026, 7, 4),
          latitude: 48.1,
          longitude: 17.1,
          fromPhoto: true,
        ),
        saveSeen: (draft) async => saved.add(draft),
      )),
    );

    await tester.tap(find.text('+ Add to Seen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(saved, hasLength(1));
    expect(saved.single.fromPhoto, isTrue);
    expect(saved.single.photoPath, 'observations/uid/lv_1.jpg');
    expect(saved.single.when, DateTime(2026, 7, 4));
    expect(saved.single.latitude, 48.1);
    expect(
      find.text('Added to Seen. Date and place from the photo.'),
      findsOneWidget,
    );
    await _clearSnackBar(tester);
  });

  testWidgets('a signed-out add asks for sign-in first', (tester) async {
    var prompted = 0;
    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Leucanthemum vulgare',
        initial: _daisy(),
        load: (_) async => null,
        imageBuilder: _swatch,
        month: 7,
        isSignedIn: () => false,
        onSignIn: (_) async => prompted++,
        saveSeen: (_) async => fail('saved while signed out'),
        pickPhoto: (_) async => fail('picked while signed out'),
      )),
    );

    await tester.tap(find.text('+ Add to Seen'));
    await tester.pump();
    expect(prompted, 1);
    expect(find.text('Without a photo'), findsNothing);
    expect(find.text('From your photos'), findsNothing);
  });

  testWidgets('a missing plant is an empty page', (tester) async {
    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Nomen nudum',
        load: (_) async => null,
        imageBuilder: _swatch,
      )),
    );
    await tester.pump();
    expect(find.text('This plant isn’t in the book.'), findsOneWidget);
  });

  testWidgets('a failed load can be tried again', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Leucanthemum vulgare',
        imageBuilder: _swatch,
        month: 7,
        load: (_) async {
          calls++;
          if (calls == 1) throw Exception('offline');
          return _daisy();
        },
      )),
    );
    await tester.pump();
    expect(find.text('Couldn’t load this plant'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(find.text('oxeye daisy'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('back leaves the species page', (tester) async {
    await _pump(
      tester,
      _app(Builder(
        builder: (context) {
          return TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => GuideSpeciesPage(
                    name: 'Leucanthemum vulgare',
                    initial: _daisy(),
                    load: (_) async => null,
                    imageBuilder: _swatch,
                    month: 7,
                  ),
                ),
              );
            },
            child: const Text('open'),
          );
        },
      )),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('oxeye daisy'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('oxeye daisy'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a camera find stays unconfirmed until it is kept',
      (tester) async {
    var confirmed = 0;
    var undone = 0;
    await _pump(
      tester,
      _app(GuideSpeciesPage(
        name: 'Leucanthemum vulgare',
        initial: _daisy(),
        load: (_) async => null,
        imageBuilder: _swatch,
        month: 7,
        pending: GuideCameraPending(
          plant: 'Leucanthemum vulgare',
          when: DateTime(2026, 9, 30, 14, 31),
          place: 'Middle Europe',
          others: const [
            GuideCameraHit(
              latin: 'Bellis perennis',
              vernacular: 'daisy',
              probability: 0.3,
              path: 'Bellis perennis',
            ),
          ],
        ),
        onConfirmPending: () async => confirmed += 1,
        onUndoPending: () async => undone += 1,
      )),
    );

    expect(find.text('Your photo · unconfirmed'), findsOneWidget);
    expect(find.textContaining('Middle Europe'), findsOneWidget);
    expect(find.text('+ Add to Seen'), findsNothing);
    expect(find.textContaining('Seen by you'), findsNothing);
    expect(find.byTooltip('Share'), findsNothing);

    await tester.tap(find.text('It’s this'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(confirmed, 1);
    expect(find.text('In Seen as oxeye daisy'), findsOneWidget);
    expect(find.text('Confirmed.'), findsOneWidget);
    expect(find.text('Your photo · unconfirmed'), findsNothing);
    expect(find.byTooltip('Share'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(GuideSpeciesPage)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('Your photo · unconfirmed'), findsOneWidget);
    expect(find.byTooltip('Share'), findsNothing);

    await tester.tap(find.text('Not it'));
    await tester.pumpAndSettle();
    expect(find.text('Which one is it?'), findsOneWidget);
    expect(
      find.text('Plant.id’s other candidates for this photo.'),
      findsOneWidget,
    );
    expect(find.text('Choose'), findsOneWidget);
  });
}

GuideSpecies _daisy() {
  final translation = PlantTranslation()
    ..label = 'oxeye daisy'
    ..names = [
      'oxeye daisy',
      'moon daisy',
      'bruisewort',
      'Leucanthemum vulgare',
    ]
    ..description = 'A daisy of <b>lawns</b>.'
    ..flower = 'White rays around a yellow disc.'
    ..inflorescence = 'A single head.'
    ..fruit = 'None'
    ..leaf = 'Basal leaves.'
    ..stem = 'Upright.'
    ..habitat = 'Lawns and meadows.'
    ..toxicity = 'Skin irritant'
    ..herbalism = 'A bitter tea.'
    ..trivia = 'A common daisy of grazed grass.'
    ..wikipedia = 'https://www.wikipedia.org/wiki/Leucanthemum_vulgare'
    ..sourceUrls = ['https://en.wikipedia.org/wiki/Leucanthemum_vulgare'];
  return assembleGuideSpecies(
    name: 'Leucanthemum vulgare',
    plant: {
      'id': 0,
      'name': 'Leucanthemum vulgare',
      'author': 'Lam.',
      'heightFrom': 20,
      'heightTo': 80,
      'floweringFrom': 5,
      'floweringTo': 10,
      'APGIV': {
        '00_Genus': 'Leucanthemum',
        '01_Familia': 'Asteraceae',
        '02_Ordo': 'Asterales',
        '11_Regnum': 'Plantae',
      },
      'photoUrls': ['a.jpg', 'b.jpg', 'c.jpg'],
      'illustrationUrl': 'plates/leucanthemum_vulgare',
    },
    translation: translation,
    vernaculars: const {
      'Asteraceae': 'daisy family',
      'Asterales': 'aster order',
    },
    sightings: [
      GuideSighting(
        id: 's1',
        photoPath: 'photos/sight.jpg',
        when: DateTime(2026, 9, 12),
      ),
    ],
  )!;
}

Widget _swatch(String path, BoxFit fit, double width, double height) {
  return const ColoredBox(color: Color(0xFF88AA77));
}

BorderSide _asideBorder(WidgetTester tester, Key key) {
  final decoration =
      tester.widget<DecoratedBox>(find.byKey(key)).decoration as BoxDecoration;
  return (decoration.border! as BorderDirectional).start;
}

BoxDecoration _monthDecoration(WidgetTester tester, int month) {
  final box =
      tester.widget<Container>(find.byKey(ValueKey('guide-month-$month')));
  return box.decoration! as BoxDecoration;
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
  Size size = const Size(390, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(page);
  await tester.pump();
}

Future<void> _clearSnackBar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
}
