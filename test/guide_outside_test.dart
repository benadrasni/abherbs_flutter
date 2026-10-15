import 'package:abherbs_flutter/camera/guide_camera.dart';
import 'package:abherbs_flutter/camera/outside_page.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const inset = 48.0;

  testWidgets(
    'a wide Outside the book photo keeps the date and place above the system bar',
    (tester) async {
      const size = Size(1194, 834);
      await _pump(tester, size: size, bottom: inset);

      expect(_pillOffset(tester), 10 + inset);
      expect(_pillGap(tester, size), closeTo(10 + inset, 0.1));
      expect(_photoBottom(tester), size.height);
      expect(
        tester.widget<ListView>(find.byType(ListView)).padding,
        const EdgeInsets.only(bottom: inset),
      );
    },
  );

  testWidgets(
    'a phone Outside the book photo keeps the date and place on the photo',
    (tester) async {
      const size = Size(390, 844);
      await _pump(tester, size: size, bottom: inset);

      expect(_pillOffset(tester), 10);
      expect(_pillGap(tester, size), greaterThan(10 + inset));
      expect(_photoBottom(tester), 300);
      expect(
        tester.widget<ListView>(find.byType(ListView)).padding,
        const EdgeInsets.only(bottom: inset),
      );
    },
  );
}

const _date = 'Sep 30, 2026';

double _pillOffset(WidgetTester tester) {
  return tester
      .widget<Positioned>(
        find.ancestor(
          of: find.text(_date),
          matching: find.byType(Positioned),
        ),
      )
      .bottom!;
}

double _pillGap(WidgetTester tester, Size size) {
  final positioned = find.ancestor(
    of: find.text(_date),
    matching: find.byType(Positioned),
  );
  final row = find
      .descendant(
        of: positioned,
        matching: find.byType(Row),
      )
      .first;
  return size.height - tester.getRect(row).bottom;
}

double _photoBottom(WidgetTester tester) {
  return tester
      .getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox && widget.color == const Color(0xFF333333),
        ),
      )
      .bottom;
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required double bottom,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: bottom);
  tester.view.viewPadding = FakeViewPadding(bottom: bottom);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: GuideOutsidePage(
        outcome: const GuideCameraOutcome.outside(
          GuideCameraHit(latin: 'Tanacetum corymbosum', probability: 0.8),
          [],
        ),
        when: DateTime(2026, 9, 30, 14, 31),
        place: 'Middle Europe',
      ),
    ),
  );
  await tester.pumpAndSettle();
}
