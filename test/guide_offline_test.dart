import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_offline.dart';
import 'package:abherbs_flutter/guide/offline_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const europe = ['10', '11', '12', '13', '14'];

  GuideOfflineCatalog catalog() {
    return const GuideOfflineCatalog([
      {'11'},
      {'11', '75'},
      {'75'},
      {'90'},
    ]);
  }

  test('a plant counts once, and Antarctic is not a pack', () {
    final plants = catalog();
    expect(plants.total, 4);
    expect(guideOfflineMatch(plants, null), 4);
    expect(guideOfflineMatch(plants, {'11'}), 2);
    expect(guideOfflineMatch(plants, {'75'}), 2);
    expect(guideOfflineMatch(plants, {'11', '75'}), 3);
    expect(guideOfflineMatch(plants, {'90'}), 1);
    expect(guideOfflineMatch(plants, guideOfflinePackCodes), 3);
    expect(guideOfflinePackCodes.contains('90'), isFalse);
    expect(guideOfflinePackCodes.contains('91'), isFalse);
    expect(
      guideOfflineGroups.any((group) => group.codes.contains('90')),
      isFalse,
    );
    expect(guideOfflineUnion(null, {'11'}), isNull);
    expect(guideOfflineUnion({'11'}, null), isNull);
    expect(guideOfflineUnion({'11'}, {'75'}), {'11', '75'});
  });

  test('picture sizes round the way the page prints them', () {
    final middle = GuideOfflineSize.of(1105);
    expect(middle.gigabytes, isFalse);
    expect(middle.amount, '810');
    final book = GuideOfflineSize.of(1433);
    expect(book.gigabytes, isTrue);
    expect(book.amount, '1.0');
    expect(book.barMb, 1000);
  });

  test('overlap names the region that holds most of a continent', () {
    const heavy = GuideOfflineCatalog([
      {'11'},
      {'11'},
      {'11'},
      {'11'},
      {'12'},
    ]);
    expect(guideOfflineOverlap(heavy, europe), '11');
    const split = GuideOfflineCatalog([
      {'11'},
      {'11'},
      {'12'},
      {'12'},
    ]);
    expect(guideOfflineOverlap(split, europe), isNull);
  });

  test('choosing while everything is on drops to that group or region', () {
    const pick = GuideOfflinePick();
    final all = pick.toggleEverything();
    expect(all.everything, isTrue);
    final group = all.toggleGroup(europe);
    expect(group.everything, isFalse);
    expect(group.regions, europe.toSet());
    final region = all.toggleRegion('11');
    expect(region.everything, isFalse);
    expect(region.regions, {'11'});
    expect(guideOfflineLabel(null).everything, isTrue);
    expect(guideOfflineLabel({'11'}).regionId, '11');
    expect(guideOfflineLabel(europe.toSet()).groupId, '1');
  });

  test('a region does not start the whole-book download', () async {
    final result = await startGuideOfflineDownload(
      request: const GuideOfflineRequest(
        everything: false,
        regions: {'11'},
        added: 2,
        title: 'Middle Europe',
      ),
      onProgress: (_, __) {},
      onFinished: () {},
      onFailed: () {},
      connectivity: () async => throw StateError('no wifi check'),
    );
    expect(result, GuideOfflineStart.skipped);
  });

  testWidgets('the page lists Everything and Europe', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(GuideOfflinePage(
      view: _view(),
      onDownload: (_) async {},
    )));

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Everything'), findsWidgets);
    expect(find.text('Europe'), findsOneWidget);
    expect(find.text('4 plants'), findsOneWidget);
    expect(find.text('2 plants'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a group checkbox downloads that continent', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    GuideOfflineRequest? request;
    await tester.pumpWidget(_app(GuideOfflinePage(
      view: _view(),
      onDownload: (value) async => request = value,
    )));

    await tester.tap(find.byKey(guideOfflineGroupKey('1')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(guideOfflineDownloadKey));
    await tester.tap(find.byKey(guideOfflineDownloadKey));
    await tester.pump();

    expect(request, isNotNull);
    expect(request!.everything, isFalse);
    expect(request!.regions, europe.toSet());
    expect(request!.added, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without Field Guide the button opens Field Guide',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var opened = 0;
    GuideOfflineRequest? request;
    await tester.pumpWidget(_app(GuideOfflinePage(
      view: _view(canDownload: false),
      onFieldGuide: () async => opened++,
      onDownload: (value) async => request = value,
    )));

    await tester.tap(find.byKey(guideOfflineEverythingKey));
    await tester.pump();
    await tester.ensureVisible(find.byKey(guideOfflineDownloadKey));
    expect(
      find.descendant(
        of: find.byKey(guideOfflineDownloadKey),
        matching: find.text('Field Guide'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(guideOfflineDownloadKey));
    await tester.pump();
    expect(opened, 1);
    expect(request, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a running job shows pause and hides Download', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var paused = 0;
    await tester.pumpWidget(_app(GuideOfflinePage(
      view: _view(),
      job: const GuideOfflineJob(
        title: 'Europe',
        plants: 2,
        doneMb: 12,
        totalMb: 40,
      ),
      onPause: () async => paused++,
    )));

    expect(find.text('Downloading Europe'), findsOneWidget);
    expect(find.text('12 MB of about 40 MB · 2 plants'), findsOneWidget);
    expect(find.byKey(guideOfflineDownloadKey), findsNothing);
    await tester.tap(find.byKey(guideOfflinePauseKey));
    await tester.pump();
    expect(paused, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the phone region is offered when it is not stored yet',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    GuideOfflineRequest? request;
    await tester.pumpWidget(_app(GuideOfflinePage(
      view: _view(phoneRegionId: '11'),
      onDownload: (value) async => request = value,
    )));

    expect(find.text('WHERE THIS PHONE IS'), findsOneWidget);
    expect(find.byKey(guideOfflinePhoneKey), findsOneWidget);
    await tester.tap(find.byKey(guideOfflinePhoneKey));
    await tester.pump();
    await tester.ensureVisible(find.byKey(guideOfflineDownloadKey));
    await tester.tap(find.byKey(guideOfflineDownloadKey));
    await tester.pump();

    expect(request, isNotNull);
    expect(request!.everything, isFalse);
    expect(request!.regions, {'11'});
    expect(request!.added, 2);
    expect(tester.takeException(), isNull);
  });
}

GuideOfflineView _view({
  bool canDownload = true,
  String? phoneRegionId,
}) {
  return GuideOfflineView(
    catalog: const GuideOfflineCatalog([
      {'11'},
      {'11', '75'},
      {'75'},
      {'90'},
    ]),
    canDownload: canDownload,
    stored: const GuideOfflineStored(),
    phoneRegionId: phoneRegionId,
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
