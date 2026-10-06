import 'package:abherbs_flutter/data/prefs.dart';
import 'package:abherbs_flutter/l10n/app_locale.dart';
import 'package:abherbs_flutter/person/setting_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const supported = <Locale>[
    Locale('en'),
    Locale('en', 'GB'),
    Locale('en', 'US'),
    Locale('de', 'DE'),
    Locale('sk', 'SK'),
  ];

  String pickerKey(String saved) {
    return saved.isEmpty ? '' : (languageListKey(languages, saved) ?? saved);
  }

  tearDown(Prefs.dispose);

  test('a GB phone uses British English and other English stays en_US', () {
    expect(
      resolveAppLocale(const Locale('en', 'GB'), supported).countryCode,
      'GB',
    );
    expect(
      resolveAppLocale(const Locale('en', 'UK'), supported).countryCode,
      'GB',
    );
    expect(
      resolveAppLocale(const Locale('en', 'US'), supported).countryCode,
      'US',
    );
    expect(
      resolveAppLocale(const Locale('en', 'AU'), supported).countryCode,
      'US',
    );
    expect(
      resolveAppLocale(const Locale('de', 'AT'), supported).countryCode,
      'DE',
    );
    expect(
      resolveAppLocale(const Locale('fr', 'FR'), supported).countryCode,
      'US',
    );
    expect(
      resolveAppLocale(const Locale('en'), supported).countryCode,
      isNull,
    );
  });

  test('English falls back to en_US even when en_GB is last', () {
    const ordered = <Locale>[
      Locale('en', 'US'),
      Locale('en'),
      Locale('en', 'GB'),
    ];
    expect(
      resolveAppLocale(const Locale('en', 'AU'), ordered).countryCode,
      'US',
    );
  });

  test('another language uses the last supported locale of that language', () {
    const ordered = <Locale>[
      Locale('de', 'AT'),
      Locale('de', 'DE'),
      Locale('en', 'US'),
    ];
    expect(
      resolveAppLocale(const Locale('de', 'CH'), ordered).countryCode,
      'DE',
    );
  });

  test('a saved en_UK tag is British English on the English row', () async {
    expect(canonicalLanguageTag('en_UK'), 'en_GB');
    expect(canonicalLanguageTag('en_GB'), 'en_GB');
    expect(canonicalLanguageTag('en_US'), 'en_US');
    expect(canonicalLanguageTag(''), '');
    expect(languageListKey(languages, 'en_UK'), 'en_US');
    expect(languageListKey(languages, 'en_GB'), 'en_US');
    expect(languageListKey(languages, 'en_US'), 'en_US');
    expect(languageListKey(languages, 'de_DE'), 'de_DE');
    expect(
      languageListKey(const {'en_GB': 'English'}, 'en_UK'),
      'en_GB',
    );
    expect(pickerKey(''), '');
    expect(pickerKey('en_UK'), 'en_US');
    expect(pickerKey('en_GB'), 'en_US');
    expect(pickerKey('de_DE'), 'de_DE');

    SharedPreferences.setMockInitialValues({'pref_language': 'en_UK'});
    expect(await preferredLanguageTag(), 'en_GB');
    expect(
      (await SharedPreferences.getInstance()).getString('pref_language'),
      'en_GB',
    );
  });
}
