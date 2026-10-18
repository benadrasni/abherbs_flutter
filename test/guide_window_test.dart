import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a phone stays on the phone layout', () {
    final phone = GuideWindow.fromSize(const Size(390, 844));
    expect(phone.tablet, isFalse);
    expect(phone.wide, isFalse);

    final landscape = GuideWindow.fromSize(const Size(844, 390));
    expect(landscape.tablet, isFalse);

    final tests = GuideWindow.fromSize(const Size(800, 600));
    expect(tests.tablet, isFalse);
    expect(tests.wide, isFalse);
  });

  test('iPad portrait is a tablet and landscape is wide', () {
    final portrait = GuideWindow.fromSize(const Size(834, 1194));
    expect(portrait.tablet, isTrue);
    expect(portrait.wide, isFalse);
    expect(portrait.columns(phone: 2, tablet: 3, wide: 4), 3);

    final landscape = GuideWindow.fromSize(const Size(1194, 834));
    expect(landscape.tablet, isTrue);
    expect(landscape.wide, isTrue);
    expect(landscape.columns(phone: 2, tablet: 3, wide: 4), 4);

    final miniPortrait = GuideWindow.fromSize(const Size(744, 1133));
    expect(miniPortrait.tablet, isTrue);
    expect(miniPortrait.wide, isFalse);

    final miniLandscape = GuideWindow.fromSize(const Size(1133, 744));
    expect(miniLandscape.wide, isTrue);

    // 12.9-inch and 13-inch portrait are both past 1000 points, and still
    // stay on the tablet layout so rotation can reach the sidebar.
    final proPortrait = GuideWindow.fromSize(const Size(1024, 1366));
    expect(proPortrait.tablet, isTrue);
    expect(proPortrait.wide, isFalse);

    final pro13Portrait = GuideWindow.fromSize(const Size(1032, 1376));
    expect(pro13Portrait.tablet, isTrue);
    expect(pro13Portrait.wide, isFalse);
    expect(pro13Portrait.columns(phone: 2, tablet: 3, wide: 4), 3);

    final pro13Landscape = GuideWindow.fromSize(const Size(1376, 1032));
    expect(pro13Landscape.tablet, isTrue);
    expect(pro13Landscape.wide, isTrue);
    expect(pro13Landscape.columns(phone: 2, tablet: 3, wide: 4), 4);
  });

  test('iPhone Duo outer stays a phone and the inner display is a tablet', () {
    final outer = GuideWindow.fromSize(const Size(466, 678));
    expect(outer.tablet, isFalse);
    expect(outer.wide, isFalse);

    final outerLandscape = GuideWindow.fromSize(const Size(678, 466));
    expect(outerLandscape.tablet, isFalse);
    expect(outerLandscape.wide, isFalse);

    final inner = GuideWindow.fromSize(const Size(669, 951));
    expect(inner.tablet, isTrue);
    expect(inner.wide, isFalse);
    expect(inner.columns(phone: 2, tablet: 3, wide: 4), 3);

    final innerLandscape = GuideWindow.fromSize(const Size(951, 669));
    expect(innerLandscape.tablet, isTrue);
    expect(innerLandscape.wide, isFalse);
    expect(innerLandscape.columns(phone: 2, tablet: 3, wide: 4), 3);
  });

  test('a side status column is the vertical tab edge', () {
    expect(
      GuideChrome.fromPadding(const EdgeInsets.only(top: 59)).vertical,
      isFalse,
    );

    final right = GuideChrome.fromPadding(
      const EdgeInsets.only(right: 84, bottom: 34),
    );
    expect(right.vertical, isTrue);
    expect(right.onRight, isTrue);
    expect(right.side, 84);

    final left = GuideChrome.fromPadding(const EdgeInsets.only(left: 84));
    expect(left.vertical, isTrue);
    expect(left.onRight, isFalse);
    expect(left.side, 84);

    expect(
      GuideChrome.fromPadding(const EdgeInsets.only(top: 90, right: 84))
          .vertical,
      isFalse,
    );
  });

  test('a crease is kept only when it crosses the window', () {
    final size = const Size(669, 951);
    final crease = GuideFold.choose(
      [const Rect.fromLTWH(314, 0, 40, 951)],
      size,
    );
    expect(crease, isNotNull);
    expect(crease!.vertical, isTrue);
    expect(crease.leading, 314);
    expect(crease.span, 40);

    expect(
      GuideFold.choose([const Rect.fromLTWH(0, 20, 40, 30)], size),
      isNull,
    );
    expect(
      GuideFold.choose(const [], size),
      isNull,
    );
  });

  test('pages sit on either side of the crease', () {
    const fold = GuideFold(Rect.fromLTWH(314, 0, 40, 951));
    final pages = fold.pagesIn(originX: 0, width: 669);
    expect(pages, isNotNull);
    expect(pages!.leading, 314);
    expect(pages.span, 40);
    expect(pages.trailing, 315);

    final inset = fold.pagesIn(originX: 10, width: 649);
    expect(inset!.leading, 304);
    expect(inset.trailing, 305);
    expect(fold.pagesIn(originX: 0, width: 200), isNull);
  });

  test('fold regions accept a platform list', () {
    final rects = GuideFold.rects([
      {'x': 314, 'y': 0, 'w': 40, 'h': 951},
    ]);
    expect(rects, [const Rect.fromLTWH(314, 0, 40, 951)]);
    expect(GuideFold.rects(null), isEmpty);
    expect(GuideFold.rects('nope'), isEmpty);
  });

  testWidgets('a vertical crease splits the row', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(669, 951)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 669,
            height: 100,
            child: GuideFoldScope(
              fold: GuideFold(Rect.fromLTWH(314, 0, 40, 951)),
              child: GuideFoldSplit(
                unsplit: Text('whole'),
                leading: Text('left'),
                trailing: Text('right'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('left'), findsOneWidget);
    expect(find.text('whole'), findsNothing);
    expect(tester.getTopLeft(find.text('left')).dx, 0);
    expect(tester.getTopLeft(find.text('right')).dx, closeTo(354, 1));
  });

  testWidgets('a folded row keeps every cell off the crease', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(669, 951)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 669,
            height: 80,
            child: GuideFoldScope(
              fold: GuideFold(Rect.fromLTWH(314, 0, 40, 951)),
              child: GuideFoldRow(
                columns: 4,
                gap: 0,
                children: [
                  Text('c0'),
                  Text('c1'),
                  Text('c2'),
                  Text('c3'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('c0')).dx, 0);
    expect(tester.getTopRight(find.text('c1')).dx, lessThan(314));
    expect(tester.getTopLeft(find.text('c2')).dx, greaterThan(354));
  });

  testWidgets('an odd column count becomes even around a crease',
      (tester) async {
    late int folded;
    late int flat;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(669, 951)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GuideFoldScope(
            fold: const GuideFold(Rect.fromLTWH(314, 0, 40, 951)),
            child: Builder(
              builder: (context) {
                folded = GuideFold.across(context, 3);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(834, 1194)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              flat = GuideFold.across(context, 3);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(folded, 4);
    expect(flat, 3);
  });

  test('folded tab centers put Book in the middle', () {
    final centers = GuideFold.tabCenters(width: 669);
    expect(centers, isNotNull);
    expect(centers![1], closeTo(334.5, 0.01));
    expect(centers[1] - centers[0], closeTo(centers[2] - centers[1], 0.01));
    expect(centers[0], closeTo(669 / 6, 0.01));
    expect(centers[2], closeTo(669 * 5 / 6, 0.01));
  });

  testWidgets('folded tabs use that equal gap', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(669, 951)),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: GuideFoldScope(
            fold: const GuideFold(Rect.fromLTWH(314.5, 0, 40, 951)),
            child: Builder(
              builder: (context) => guideChromeFrame(
                context,
                index: 2,
                onSelect: (_) {},
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );

    final findIcon = tester.getCenter(find.byIcon(Icons.center_focus_weak));
    final bookIcon = tester.getCenter(find.byIcon(Icons.menu_book_outlined));
    final seenIcon = tester.getCenter(find.byIcon(Icons.article_outlined));
    expect(bookIcon.dx - findIcon.dx, closeTo(seenIcon.dx - bookIcon.dx, 1));
    expect(bookIcon.dx, closeTo(findIcon.dx * 3, 1));
    expect(seenIcon.dx, closeTo(findIcon.dx * 5, 1));
  });
}
