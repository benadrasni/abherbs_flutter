import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    GuideAppearanceController.instance.resetForTest();
  });

  test('dark colors match the field-guide mockup', () {
    const dark = GuideColors.dark;
    expect(dark.paper, const Color(0xFF15120E));
    expect(dark.paper2, const Color(0xFF211C16));
    expect(dark.ink, const Color(0xFFEEE6D6));
    expect(dark.ink2, const Color(0xFFC2B7A3));
    expect(dark.ink3, const Color(0xFF9C9180));
    expect(dark.rule, const Color(0xFF3A332A));
    expect(dark.madder, const Color(0xFFE08A70));
    expect(dark.moss, const Color(0xFF9FBEA5));
    expect(dark.gold, const Color(0xFFD0A57A));
    expect(dark.cream, const Color(0xFF1F1A15));
    expect(dark.mossFill, const Color(0xFF4A6652));
    expect(dark.madderFill, const Color(0xFFA4493A));
    expect(dark.onInk, const Color(0xFF15120E));
    expect(dark.body, const Color(0xFFDED5C4));
    expect(dark.photoWell, const Color(0xFF332D25));
    expect(GuideColors.light.mossFill, GuidePalette.moss);
    expect(GuideColors.light.madderFill, GuidePalette.madder);
    expect(GuideColors.light.onMoss, GuidePalette.paper);
    expect(GuideColors.dark.plateWell, GuideColors.light.plateWell);
  });

  testWidgets('the field guide follows the phone appearance', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      const MaterialApp(
        home: GuideTheme(child: _Probe()),
      ),
    );

    expect(
      tester
          .widget<ColoredBox>(find.byKey(const Key('guide-theme-probe')))
          .color,
      GuideColors.dark.paper,
    );
    expect(
      tester.widget<Text>(find.text('Find')).style!.color,
      GuideColors.dark.ink,
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(
      const MaterialApp(
        home: GuideTheme(child: _Probe()),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Find')).style!.color,
      GuidePalette.ink,
    );
  });

  testWidgets('a saved Dark choice overrides a light phone', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    GuideAppearanceController.instance.apply(GuideAppearance.dark);

    await tester.pumpWidget(
      const MaterialApp(
        home: GuideTheme(child: _Probe()),
      ),
    );

    expect(
      tester
          .widget<ColoredBox>(find.byKey(const Key('guide-theme-probe')))
          .color,
      GuideColors.dark.paper,
    );
  });
}

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return ColoredBox(
      key: const Key('guide-theme-probe'),
      color: colors.paper,
      child: Text('Find', style: GuideType.wordmark(colors)),
    );
  }
}
