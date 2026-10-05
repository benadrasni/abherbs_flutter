import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/shell/app_version.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/version_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

VersionFacts facts({
  int build = 900,
  int? fetchedFloor = 0,
  int cachedFloor = 0,
  int rememberedFloor = 0,
  int? storeBuild,
  int dismissedStore = 0,
}) {
  return VersionFacts(
    build: build,
    fetchedFloor: fetchedFloor,
    cachedFloor: cachedFloor,
    rememberedFloor: rememberedFloor,
    storeBuild: storeBuild,
    dismissedStore: dismissedStore,
  );
}

void main() {
  test('the gate controller notifies once when the prompt changes', () {
    final controller = VersionGateController.instance;
    var notices = 0;
    void listener() => notices++;
    controller.addListener(listener);
    addTearDown(() {
      controller.removeListener(listener);
      controller.resetForTest();
    });

    controller.apply(VersionPrompt.block);
    controller.apply(VersionPrompt.block);
    expect(controller.prompt, VersionPrompt.block);
    expect(notices, 1);

    controller.apply(VersionPrompt.none);
    expect(notices, 2);
  });

  test('a floor of zero leaves the current build open', () {
    final decision = decideVersion(facts());
    expect(decision.prompt, VersionPrompt.none);
    expect(decision.persistFloor, isNull);
    expect(decision.clearFloor, isFalse);
  });

  test('a build below the fetched floor is blocked and remembered', () {
    final decision = decideVersion(facts(build: 830, fetchedFloor: 900));
    expect(decision.prompt, VersionPrompt.block);
    expect(decision.persistFloor, 900);
    expect(decision.clearFloor, isFalse);
  });

  test('a finished fetch below the build clears a remembered floor', () {
    final decision = decideVersion(facts(
      build: 900,
      fetchedFloor: 0,
      rememberedFloor: 900,
    ));
    expect(decision.prompt, VersionPrompt.none);
    expect(decision.clearFloor, isTrue);
    expect(decision.persistFloor, isNull);
  });

  test('a failed fetch keeps a build closed when a floor was remembered', () {
    final decision = decideVersion(facts(
      build: 830,
      fetchedFloor: null,
      rememberedFloor: 900,
    ));
    expect(decision.prompt, VersionPrompt.block);
    expect(decision.persistFloor, 900);
    expect(decision.clearFloor, isFalse);
  });

  test('a failed fetch with no cache and no memory stays open', () {
    final decision = decideVersion(facts(
      build: 830,
      fetchedFloor: null,
    ));
    expect(decision.prompt, VersionPrompt.none);
    expect(decision.clearFloor, isFalse);
    expect(decision.persistFloor, isNull);
  });

  test('a cached floor closes the build when the fresh fetch fails', () {
    final decision = decideVersion(facts(
      build: 830,
      fetchedFloor: null,
      cachedFloor: 900,
    ));
    expect(decision.prompt, VersionPrompt.block);
    expect(decision.persistFloor, 900);
  });

  test('an updated build stays open offline without clearing the memory', () {
    final decision = decideVersion(facts(
      build: 900,
      fetchedFloor: null,
      rememberedFloor: 900,
    ));
    expect(decision.prompt, VersionPrompt.none);
    expect(decision.clearFloor, isFalse);
  });

  test('a newer store build shows a banner until that build is dismissed', () {
    expect(
      decideVersion(facts(build: 830, storeBuild: 900)).prompt,
      VersionPrompt.banner,
    );
    expect(
      decideVersion(facts(build: 830, storeBuild: 900, dismissedStore: 830))
          .prompt,
      VersionPrompt.banner,
    );
    expect(
      decideVersion(facts(build: 830, storeBuild: 900, dismissedStore: 900))
          .prompt,
      VersionPrompt.none,
    );
    expect(
      decideVersion(facts(build: 900, storeBuild: 900)).prompt,
      VersionPrompt.none,
    );
  });

  test('the floor wins over the store banner', () {
    final decision = decideVersion(facts(
      build: 830,
      fetchedFloor: 900,
      storeBuild: 950,
    ));
    expect(decision.prompt, VersionPrompt.block);
  });

  test('an unreadable build number does not lock the guide', () {
    final decision = decideVersion(facts(
      build: 0,
      fetchedFloor: 900,
      storeBuild: 900,
    ));
    expect(decision.prompt, VersionPrompt.none);
  });

  testWidgets('the required page has no way past the update button',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: VersionRequiredPage(onUpdate: () async => taps++),
    ));

    expect(
        find.text(
            'This version no longer works. Update to keep using the guide.'),
        findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

    await tester.tap(find.byKey(const Key('version-required-update')));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('the banner updates or goes away', (tester) async {
    var updates = 0;
    var dismisses = 0;
    await tester.pumpWidget(MaterialApp(
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
          body: VersionBanner(
            onUpdate: () => updates++,
            onDismiss: () => dismisses++,
          ),
        ),
      ),
    ));

    expect(
        find.text('New version is available, please update.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('version-banner-update')));
    await tester.tap(find.byKey(const Key('version-banner-dismiss')));
    await tester.pump();
    expect(updates, 1);
    expect(dismisses, 1);
  });
}
