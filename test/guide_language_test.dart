import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/person/language_page.dart';
import 'package:abherbs_flutter/person/setting_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every catalog language has an English name and sorts by it', () {
    expect(guideLanguageEnglish.keys.toSet(), languages.keys.toSet());
    final options = guideLanguageOptions(languages);
    expect(options.map((option) => option.key).toSet(), languages.keys.toSet());
    expect(options.first.english, 'Arabic');
    expect(options.last.english, 'Ukrainian');
    final folded =
        options.map((option) => option.english.toLowerCase()).toList();
    expect(folded, orderedEquals([...folded]..sort()));
    expect(
      guideLanguageShowsEnglish(
        options.firstWhere((option) => option.key == 'en_US'),
      ),
      isFalse,
    );
    expect(
      guideLanguageShowsEnglish(
        options.firstWhere((option) => option.key == 'de_DE'),
      ),
      isTrue,
    );
  });

  test('search matches native names, English names, and aliases', () {
    final options = guideLanguageOptions(languages);
    expect(
      guideLanguageMatches(options, '  Türk ').map((option) => option.key),
      ['tr_TR'],
    );
    expect(
      guideLanguageMatches(options, 'arab').map((option) => option.key),
      ['ar_EG'],
    );
    expect(
      guideLanguageMatches(options, 'ces').map((option) => option.key),
      ['cs_CZ'],
    );
    expect(
      guideLanguageMatches(options, 'farsi').map((option) => option.key),
      ['fa_IR'],
    );
    expect(
      guideLanguageMatches(options, 'bokmal').map((option) => option.key),
      ['nb_NO'],
    );
    expect(
      guideLanguageMatches(options, 'traditional').map((option) => option.key),
      ['zh_TW'],
    );
    expect(guideLanguageMatches(options, 'zzzz'), isEmpty);
    expect(guideLanguageMatches(options, '   ').length, options.length);
    expect(
      guideLanguagePhoneMatches('deutsch', 'Same as this phone', 'English'),
      isFalse,
    );
    expect(
      guideLanguagePhoneMatches('phone', 'Same as this phone', 'English'),
      isTrue,
    );
    expect(guideLanguagePhoneMatches('norsk', 'Same as this phone', 'Norsk'),
        isTrue);
  });

  testWidgets('English is not labeled twice, and a saved language is checked',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(GuideLanguagePage(
      selectedKey: 'de_DE',
      phoneName: 'English',
      options: const [
        GuideLanguageOption(key: 'en_US', name: 'English', english: 'English'),
        GuideLanguageOption(key: 'de_DE', name: 'Deutsch', english: 'German'),
      ],
      onChoose: (_) async {},
    )));

    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('German'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('de_DE')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(guideLanguagePhoneKey),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the phone choice is separate from an explicit language',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? chosen;
    await tester.pumpWidget(_app(_page(
      selectedKey: '',
      phoneName: 'Norsk',
      onChoose: (key) async => chosen = key,
    )));

    expect(find.text('Same as this phone'), findsOneWidget);
    expect(find.text('The app follows this language.'), findsOneWidget);
    expect(find.text('Norsk'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(guideLanguagePhoneKey),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('en_US')),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField), 'deutsch');
    await tester.pump();
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Same as this phone'), findsNothing);
    expect(find.text('English'), findsNothing);

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(chosen, 'de_DE');
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing the phone language returns to the previous page',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? chosen;
    await tester.pumpWidget(_app(Builder(
      builder: (context) {
        return TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => _page(
                  selectedKey: 'ar_EG',
                  phoneName: 'English',
                  onChoose: (key) async => chosen = key,
                ),
              ),
            );
          },
          child: const Text('Open'),
        );
      },
    )));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ar_EG')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Same as this phone'));
    await tester.pumpAndSettle();
    expect(chosen, '');
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Same as this phone'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow phone lays the list out without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(_page(
      selectedKey: 'id_ID',
      phoneName: 'Bahasa Indonesia',
      onChoose: (_) async {},
    )));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check).hitTestable(), findsOneWidget);
    await tester.fling(find.byType(ListView), const Offset(0, -600), 1200);
    await tester.pumpAndSettle();
    expect(find.text('No language by that name.'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.text('No language by that name.'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(find.text('Bahasa Indonesia'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

GuideLanguagePage _page({
  required String selectedKey,
  required String phoneName,
  required Future<void> Function(String key) onChoose,
}) {
  return GuideLanguagePage(
    selectedKey: selectedKey,
    phoneName: phoneName,
    options: guideLanguageOptions(languages),
    onChoose: onChoose,
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
