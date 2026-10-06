import 'package:abherbs_flutter/l10n/app_locale.dart';
import 'package:abherbs_flutter/person/setting_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = <Locale>[
    Locale('en'),
    Locale('en', 'GB'),
    Locale('en', 'US'),
    Locale('de', 'DE'),
    Locale('sk', 'SK'),
  ];

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

  test('a saved en_UK tag is British English on the English row', () {
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
  });
}
