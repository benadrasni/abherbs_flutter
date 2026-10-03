import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_camera.dart';
import 'package:abherbs_flutter/guide/guide_seen.dart';
import 'package:abherbs_flutter/guide/outside_page.dart';
import 'package:abherbs_flutter/guide/seen_page.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a catalog species keeps the leading probability', () {
    final outcome = guideCameraOutcome([
      const GuideCameraHit(
        latin: 'Bellis perennis',
        path: 'Bellis perennis',
        probability: 0.82,
      ),
      const GuideCameraHit(
        latin: 'Leucanthemum vulgare',
        path: 'Leucanthemum vulgare',
        probability: 0.2,
      ),
    ]);
    expect(outcome.speciesName, 'Bellis perennis');
    expect(outcome.leadProbability, 0.82);
    expect(outcome.candidates.single.path, 'Leucanthemum vulgare');
  });

  test('reads a private find and keeps older rows confirmed', () {
    final row = readGuideSeenRow('key-1', {
      observationId: 'uid_1',
      observationPlant: 'Bellis perennis',
      observationDate: {observationTime: DateTime(2026, 9, 27, 14, 31).millisecondsSinceEpoch},
      observationLatitude: 48.1,
      observationLongitude: 17.1,
      observationPhotoPaths: ['observations/uid/bellis.jpg'],
      observationStatus: 'public',
      observationCandidates: [
        {'latin': 'Bellis perennis', 'probability': 0.82, 'path': 'Bellis perennis'},
        {
          'latin': 'Leucanthemum vulgare',
          'vernacular': 'oxeye daisy',
          'probability': 0.2,
          'path': 'Leucanthemum vulgare',
        },
        {'latin': 'Asteraceae', 'path': 'Asterales/Asteraceae'},
      ],
    });
    expect(row, isNotNull);
    expect(row!.id, 'uid_1');
    expect(row.confirmed, isTrue);
    expect(row.share, GuideSeenShare.shared);
    expect(row.ownPhoto, isTrue);
    expect(row.probability, 0.82);
    expect(row.others.map((hit) => hit.latin), ['Leucanthemum vulgare']);
    expect(row.latitude, 48.1);

    final older = readGuideSeenRow('uid_2', {
      observationPlant: '  Rosa canina  ',
      observationStatus: 'review',
      observationConfirmed: false,
    });
    expect(older!.name, 'Rosa canina');
    expect(older.id, 'uid_2');
    expect(older.confirmed, isFalse);
    expect(older.share, GuideSeenShare.review);
    expect(older.ownPhoto, isFalse);

    expect(
      readGuideSeenRow('x', {observationPlant: 'Taraxacum officinale'})!.share,
      GuideSeenShare.none,
    );
    expect(
      readGuideSeenRow('x', {
        observationPlant: 'Taraxacum officinale',
        observationStatus: 'rejected',
      })!.share,
      GuideSeenShare.rejected,
    );
    expect(readGuideSeenRow('x', {'note': 'no plant'}), isNull);
  });

  test('counts unconfirmed rows and skips a row with no plant', () {
    expect(
      countGuideUnconfirmedRows({
        'a': {
          observationPlant: 'Bellis perennis',
          observationConfirmed: false,
        },
        'b': {observationPlant: 'Taraxacum officinale'},
        'c': {
          observationPlant: 'Rosa canina',
          observationConfirmed: true,
        },
        'd': {observationConfirmed: false},
        'e': 'nope',
      }),
      1,
    );
    expect(
      guideUnconfirmedTotal([
        _find(id: 'a', confirmed: false),
        _find(id: 'b'),
      ]),
      1,
    );
  });

  test('puts unconfirmed finds first and groups the rest by month', () {
    final september = DateTime(2026, 9, 27, 14);
    final earlier = DateTime(2026, 9, 2, 9);
    final august = DateTime(2026, 8, 18);
    final notebook = arrangeGuideSeen([
      _find(id: 'a', when: earlier),
      _find(id: 'b', when: august),
      _find(id: 'c', when: september, confirmed: false),
      _find(id: 'd', when: september),
    ]);
    expect(notebook.unconfirmed.map((find) => find.id), ['c']);
    expect(notebook.months.map((month) => month.month), [
      DateTime(2026, 9),
      DateTime(2026, 8),
    ]);
    expect(notebook.months.first.finds.map((find) => find.id), ['d', 'a']);
    expect(notebook.months.last.finds.single.id, 'b');
  });

  test('hiding shared skips only confirmed public finds', () {
    final shared = _find(id: 's', share: GuideSeenShare.shared);
    final review = _find(id: 'r', share: GuideSeenShare.review);
    final rejected = _find(id: 'n', share: GuideSeenShare.rejected);
    final open = _find(id: 'o');
    final pending = _find(
      id: 'u',
      confirmed: false,
      share: GuideSeenShare.shared,
    );
    final all = [shared, review, rejected, open, pending];
    expect(guideSeenSharedCount(all), 1);
    expect(
      guideSeenHidingShared(all).map((find) => find.id),
      ['r', 'n', 'o', 'u'],
    );
    final notebook = arrangeGuideSeen(guideSeenHidingShared(all));
    expect(notebook.unconfirmed.map((find) => find.id), ['u']);
    expect(
      notebook.months.single.finds.map((find) => find.id),
      isNot(contains('s')),
    );
  });

  test('share is only for a confirmed catalog species with a photo', () {
    expect(guideSeenChip(_find(id: '1', confirmed: false, ownPhoto: true, inBook: true)), isNull);
    expect(
      guideSeenChip(_find(id: '1', ownPhoto: true, inBook: true)),
      GuideSeenChip.share,
    );
    expect(
      guideSeenChip(_find(id: '1', inBook: true)),
      isNull,
    );
    expect(
      guideSeenChip(_find(id: '1', ownPhoto: true)),
      GuideSeenChip.outside,
    );
    expect(
      guideSeenChip(_find(id: '1', share: GuideSeenShare.review, inBook: true)),
      GuideSeenChip.review,
    );
    expect(
      guideSeenChip(_find(id: '1', share: GuideSeenShare.shared)),
      GuideSeenChip.shared,
    );
    expect(
      guideSeenChip(_find(id: '1', share: GuideSeenShare.rejected, inBook: true)),
      GuideSeenChip.rejected,
    );
    expect(guideSeenDetail('Sep 27', 'Middle Europe'), 'Sep 27 · Middle Europe');
    expect(guideSeenDetail('Sep 27', '  '), 'Sep 27');
  });

  testWidgets('groups finds and offers share, review, and the upsell',
      (tester) async {
    final opened = <String>[];
    final confirmed = <String>[];
    final removed = <String>[];
    var fieldGuide = 0;
    await _pump(
      tester,
      _page(
        finds: [
          _find(
            id: 'new',
            name: 'Bellis perennis',
            label: 'daisy',
            when: DateTime(2026, 9, 27, 14, 31),
            confirmed: false,
            probability: 0.82,
            place: 'Middle Europe',
          ),
          _find(
            id: 'kept',
            name: 'Rosa canina',
            label: 'dog rose',
            when: DateTime(2026, 9, 2),
            ownPhoto: true,
            inBook: true,
          ),
          _find(
            id: 'wait',
            name: 'Achillea millefolium',
            when: DateTime(2026, 8, 4),
            share: GuideSeenShare.review,
            inBook: true,
          ),
          _find(
            id: 'out',
            name: 'Tanacetum corymbosum',
            when: DateTime(2026, 8, 1),
          ),
        ],
        onOpen: (_, find) => opened.add(find.id),
        onConfirm: (find) async => confirmed.add(find.id),
        onDelete: (find) async => removed.add(find.id),
        onFieldGuide: (_) => fieldGuide++,
      ),
    );

    expect(find.text('Seen'), findsOneWidget);
    expect(find.text('4 finds · on this phone until you sign in'), findsOneWidget);
    expect(find.text('TO CONFIRM · 1'), findsOneWidget);
    expect(find.text('LIKELY'), findsOneWidget);
    expect(find.text('daisy'), findsOneWidget);
    expect(find.text('Bellis perennis'), findsOneWidget);
    expect(find.text('Sep 27 · Middle Europe'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Another'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    final confirm = tester.getSize(find.byKey(const Key('guide-seen-confirm-new')));
    final another = tester.getSize(find.byKey(const Key('guide-seen-another-new')));
    final delete = tester.getSize(find.byKey(const Key('guide-seen-delete-new')));
    expect(confirm.width, closeTo(another.width, 0.5));
    expect(another.width, closeTo(delete.width, 0.5));
    expect(find.text('SEPTEMBER 2026'), findsOneWidget);
    expect(find.text('dog rose'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('AUGUST 2026'), findsOneWidget);
    expect(find.text('Achillea millefolium'), findsOneWidget);
    expect(find.text('In review'), findsOneWidget);
    expect(find.text('Tanacetum corymbosum'), findsOneWidget);
    expect(find.text('Not in the book'), findsOneWidget);
    expect(find.text('Keep your photos on every phone'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(confirmed, ['new']);
    expect(find.text('Confirmed.'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(removed, ['new']);

    await tester.tap(find.text('dog rose'));
    expect(opened, ['kept']);

    await tester.ensureVisible(find.byKey(const Key('guide-seen-upsell')));
    await tester.tap(find.byKey(const Key('guide-seen-upsell')));
    expect(fieldGuide, 1);
  });

  testWidgets('a signed-in Field Guide hides the upsell', (tester) async {
    await _pump(
      tester,
      _page(
        finds: [_find(id: '1', name: 'Rosa canina', ownPhoto: true, inBook: true)],
        signedIn: true,
        fieldGuide: true,
      ),
    );
    expect(find.text('1 find · photos on all your devices'), findsOneWidget);
    expect(find.text('Keep your photos on every phone'), findsNothing);
    expect(find.text('Finds you save will show up here.'), findsNothing);
  });

  testWidgets('an empty notebook says so and still offers Field Guide',
      (tester) async {
    await _pump(tester, _page(finds: const []));
    expect(find.text('0 finds · saved to your account'), findsNothing);
    expect(find.text('0 finds · on this phone until you sign in'), findsOneWidget);
    expect(find.text('Finds you save will show up here.'), findsOneWidget);
    expect(find.text('See Field Guide'), findsOneWidget);
    expect(find.text('To confirm · 0'), findsNothing);
    expect(find.byKey(const Key('guide-seen-hide-shared')), findsNothing);
  });

  testWidgets('shows a spinner until the notebook arrives', (tester) async {
    await _pump(tester, _page(finds: null));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Finds you save will show up here.'), findsNothing);
  });

  testWidgets('sharing asks for CC0, and a guest is sent to sign in',
      (tester) async {
    var signed = 0;
    final shared = <String>[];
    await _pump(
      tester,
      _page(
        finds: [
          _find(
            id: 'kept',
            name: 'Rosa canina',
            label: 'dog rose',
            ownPhoto: true,
            inBook: true,
          ),
        ],
        onSignIn: (_) async => signed++,
      ),
    );
    await tester.tap(find.text('Share'));
    await tester.pump();
    expect(signed, 1);
    expect(find.text('Send for review'), findsNothing);

    await _pump(
      tester,
      _page(
        finds: [
          _find(
            id: 'kept',
            name: 'Rosa canina',
            label: 'dog rose',
            ownPhoto: true,
            inBook: true,
          ),
        ],
        signedIn: true,
        onShare: (find) async {
          shared.add(find.id);
          return true;
        },
      ),
    );
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('Share dog rose'), findsOneWidget);
    expect(find.text('Your note stays private.'), findsOneWidget);
    final send = tester.widget<FilledButton>(find.byKey(const Key('guide-seen-send')));
    expect(send.onPressed, isNull);

    await tester.tap(find.byKey(const Key('guide-seen-consent')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('guide-seen-send')));
    await tester.pumpAndSettle();
    expect(shared, ['kept']);
    expect(find.text('Sent for review.'), findsOneWidget);
  });

  testWidgets('a shared find can be withdrawn', (tester) async {
    final withdrawn = <String>[];
    await _pump(
      tester,
      _page(
        finds: [
          _find(
            id: 'pub',
            name: 'Rosa canina',
            label: 'dog rose',
            share: GuideSeenShare.shared,
            inBook: true,
          ),
        ],
        signedIn: true,
        onWithdraw: (find) async {
          withdrawn.add(find.id);
          return true;
        },
      ),
    );
    await tester.tap(find.text('Shared'));
    await tester.pumpAndSettle();
    expect(find.text('dog rose is a Sighting'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guide-seen-withdraw')));
    await tester.pumpAndSettle();
    expect(withdrawn, ['pub']);
    expect(find.text('Withdrawn from Sightings.'), findsOneWidget);
  });

  testWidgets('another name retargets the find', (tester) async {
    String? next;
    await _pump(
      tester,
      _page(
        finds: [
          _find(
            id: 'new',
            name: 'Bellis perennis',
            confirmed: false,
            others: const [
              GuideSeenCandidate(
                latin: 'Leucanthemum vulgare',
                vernacular: 'oxeye daisy',
                path: 'Leucanthemum vulgare',
              ),
            ],
          ),
        ],
        onRetarget: (find, plant) async => next = '$plant from ${find.id}',
        onSearch: (_) {},
      ),
    );
    await tester.tap(find.text('Another'));
    await tester.pumpAndSettle();
    expect(find.text('Which one is it?'), findsOneWidget);
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(next, 'Leucanthemum vulgare from new');
    expect(find.text('Changed and confirmed.'), findsOneWidget);
  });

  testWidgets('hide shared sits under to confirm and drops public finds',
      (tester) async {
    await _pump(
      tester,
      _page(
        finds: [
          _find(
            id: 'new',
            name: 'Tanacetum corymbosum',
            when: DateTime(2026, 9, 27, 14),
            confirmed: false,
          ),
          _find(
            id: 'review',
            name: 'Achillea millefolium',
            label: 'yarrow',
            when: DateTime(2026, 9, 12),
            share: GuideSeenShare.review,
            inBook: true,
          ),
          _find(
            id: 'open',
            name: 'Matricaria chamomilla',
            label: 'chamomile',
            when: DateTime(2026, 9, 3),
            ownPhoto: true,
            inBook: true,
          ),
          _find(
            id: 'no',
            name: 'Anemone nemorosa',
            label: 'wood anemone',
            when: DateTime(2026, 4, 14),
            share: GuideSeenShare.rejected,
            inBook: true,
          ),
          _find(
            id: 'pub',
            name: 'Galanthus nivalis',
            label: 'snowdrop',
            when: DateTime(2026, 3, 2),
            share: GuideSeenShare.shared,
            inBook: true,
          ),
        ],
      ),
    );

    expect(find.text('5 finds · on this phone until you sign in'), findsOneWidget);
    expect(find.text('TO CONFIRM · 1'), findsOneWidget);
    expect(find.text('Hide shared · 1'), findsOneWidget);
    expect(find.text('snowdrop'), findsOneWidget);
    expect(find.text('MARCH 2026'), findsOneWidget);
    expect(find.text('yarrow'), findsOneWidget);
    expect(find.text('In review'), findsOneWidget);
    expect(find.text('Not accepted'), findsOneWidget);

    final chip = find.byKey(const Key('guide-seen-hide-shared'));
    final chipRect = tester.getRect(chip);
    final listRect = tester.getRect(find.byType(ListView));
    final confirm = tester.getRect(
      find.byKey(const Key('guide-seen-confirm-new')),
    );
    expect(chipRect.right, closeTo(listRect.right - 20, 1));
    expect(chipRect.left, greaterThan(listRect.center.dx));
    expect(chipRect.top, greaterThan(confirm.bottom));

    await tester.tap(chip);
    await tester.pump();
    expect(find.text('Shared hidden · 1'), findsOneWidget);
    expect(
      find.text('4 finds · 1 shared hidden · on this phone until you sign in'),
      findsOneWidget,
    );
    expect(find.text('snowdrop'), findsNothing);
    expect(find.text('MARCH 2026'), findsNothing);
    expect(find.text('yarrow'), findsOneWidget);
    expect(find.text('chamomile'), findsOneWidget);
    expect(find.text('wood anemone'), findsOneWidget);
    expect(find.text('Tanacetum corymbosum'), findsOneWidget);
    final hiddenChip = tester.getRect(find.byKey(const Key('guide-seen-hide-shared')));
    final hiddenConfirm = tester.getRect(
      find.byKey(const Key('guide-seen-confirm-new')),
    );
    expect(hiddenChip.right, closeTo(listRect.right - 20, 1));
    expect(hiddenChip.top, greaterThan(hiddenConfirm.bottom));

    await tester.tap(find.byKey(const Key('guide-seen-hide-shared')));
    await tester.pump();
    expect(find.text('Hide shared · 1'), findsOneWidget);
    expect(find.text('snowdrop'), findsOneWidget);
    expect(find.text('5 finds · on this phone until you sign in'), findsOneWidget);
  });

  testWidgets('hiding every confirmed find leaves the chip and a note',
      (tester) async {
    await _pump(
      tester,
      _page(
        finds: [
          _find(
            id: 'pub',
            name: 'Galanthus nivalis',
            label: 'snowdrop',
            share: GuideSeenShare.shared,
          ),
        ],
        hideShared: true,
      ),
    );
    expect(find.text('Shared hidden · 1'), findsOneWidget);
    expect(
      find.text('0 finds · 1 shared hidden · on this phone until you sign in'),
      findsOneWidget,
    );
    expect(find.text('snowdrop'), findsNothing);
    expect(
      find.text(
        'Nothing else in the notebook. Shared finds are still on the species pages.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an unconfirmed name outside the book opens its page',
      (tester) async {
    final opened = <String>[];
    await _pump(
      tester,
      _page(
        finds: [
          _find(
            id: 'out',
            name: 'Tanacetum corymbosum',
            when: DateTime(2026, 9, 27, 14, 31),
            confirmed: false,
            probability: 0.8,
            place: 'Middle Europe',
            others: const [
              GuideSeenCandidate(
                latin: 'Leucanthemum vulgare',
                vernacular: 'oxeye daisy',
                probability: 0.4,
                path: 'Leucanthemum vulgare',
              ),
            ],
          ),
          _find(
            id: 'book',
            name: 'Bellis perennis',
            label: 'daisy',
            confirmed: false,
            inBook: true,
          ),
        ],
        onOpen: (_, find) => opened.add(find.id),
      ),
    );

    await tester.tap(find.text('daisy'));
    await tester.pump();
    expect(opened, ['book']);
    expect(find.byKey(const Key('guide-outside-page')), findsNothing);

    await tester.tap(find.text('Tanacetum corymbosum'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guide-outside-page')), findsOneWidget);
    expect(find.text('Saved to Seen · unconfirmed'), findsOneWidget);
    expect(find.text('oxeye daisy'), findsOneWidget);
    expect(find.byKey(const Key('guide-outside-keep')), findsOneWidget);
    final page = tester.widget<GuideOutsidePage>(find.byType(GuideOutsidePage));
    expect(page.observationId, 'out');
    expect(page.confirmed, isFalse);
    expect(page.onSave, isNull);

    await tester.tap(find.byKey(const Key('guide-outside-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guide-outside-page')), findsNothing);
    expect(find.text('TO CONFIRM · 2'), findsOneWidget);
  });

  testWidgets('Not in the book opens Outside the book', (tester) async {
    final opened = <String>[];
    await _pump(
      tester,
      _page(
        finds: [
          _find(
            id: 'kept',
            name: 'Tanacetum corymbosum',
            when: DateTime(2026, 8, 1, 14, 31),
            place: 'Middle Europe',
          ),
          _find(
            id: 'rose',
            name: 'Rosa canina',
            label: 'dog rose',
            inBook: true,
          ),
        ],
        onOpen: (_, find) => opened.add(find.id),
      ),
    );

    await tester.tap(find.byKey(const Key('guide-seen-outside')));
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    expect(find.byKey(const Key('guide-outside-page')), findsOneWidget);
    expect(find.text('Tanacetum corymbosum'), findsWidgets);
    expect(find.text('Saved to Seen · unconfirmed'), findsNothing);
    expect(find.textContaining('Confirmed ·'), findsOneWidget);
    expect(find.byKey(const Key('guide-outside-keep')), findsNothing);
    expect(find.byKey(const Key('guide-outside-delete')), findsOneWidget);
    final page = tester.widget<GuideOutsidePage>(find.byType(GuideOutsidePage));
    expect(page.observationId, 'kept');
    expect(page.confirmed, isTrue);

    await tester.tap(find.byKey(const Key('guide-outside-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guide-outside-page')), findsNothing);

    await tester.tap(find.text('Tanacetum corymbosum'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guide-outside-page')), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('hide shared is remembered on the phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
    addTearDown(() => Prefs.remove(keyGuideSeenHideShared));
    final finds = [
      _find(
        id: 'pub',
        name: 'Galanthus nivalis',
        label: 'snowdrop',
        share: GuideSeenShare.shared,
      ),
    ];
    await _pump(tester, _page(finds: finds));
    await tester.tap(find.byKey(const Key('guide-seen-hide-shared')));
    await tester.pumpAndSettle();
    expect(Prefs.getBool(keyGuideSeenHideShared, false), isTrue);

    await _pump(tester, _page(finds: finds));
    expect(find.text('Shared hidden · 1'), findsOneWidget);
    expect(find.text('snowdrop'), findsNothing);
  });
}

GuideSeenFind _find({
  required String id,
  String name = 'Bellis perennis',
  String? label,
  DateTime? when,
  bool confirmed = true,
  bool ownPhoto = false,
  bool inBook = false,
  GuideSeenShare share = GuideSeenShare.none,
  double? probability,
  String? place,
  List<GuideSeenCandidate> others = const [],
}) {
  return GuideSeenFind(
    id: id,
    name: name,
    label: label,
    when: when ?? DateTime(2026, 9, 27),
    photoPath: ownPhoto ? 'observations/uid/$id.jpg' : null,
    ownPhoto: ownPhoto,
    confirmed: confirmed,
    share: share,
    inBook: inBook,
    probability: probability,
    place: place,
    others: others,
  );
}

Widget _page({
  required List<GuideSeenFind>? finds,
  bool signedIn = false,
  bool fieldGuide = false,
  void Function(BuildContext context, GuideSeenFind find)? onOpen,
  Future<void> Function(GuideSeenFind find)? onConfirm,
  Future<void> Function(GuideSeenFind find)? onDelete,
  Future<void> Function(GuideSeenFind find, String plant)? onRetarget,
  Future<bool> Function(GuideSeenFind find)? onShare,
  Future<bool> Function(GuideSeenFind find)? onWithdraw,
  void Function(BuildContext context)? onFieldGuide,
  void Function(BuildContext context)? onSearch,
  Future<void> Function(BuildContext context)? onSignIn,
  bool? hideShared,
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
      body: SeenPage(
        finds: finds,
        signedIn: signedIn,
        fieldGuide: fieldGuide,
        onOpen: onOpen,
        onConfirm: onConfirm,
        onDelete: onDelete,
        onRetarget: onRetarget,
        onShare: onShare,
        onWithdraw: onWithdraw,
        onFieldGuide: onFieldGuide,
        onSearch: onSearch,
        onSignIn: onSignIn,
        hideShared: hideShared,
        onCamera: (_) {},
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(page);
  await tester.pump();
}
