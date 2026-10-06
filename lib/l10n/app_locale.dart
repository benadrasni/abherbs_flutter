import 'package:abherbs_flutter/person/setting_utils.dart';
import 'package:flutter/widgets.dart';

/// Picks the UI locale for [saved].
///
/// `en_UK` is read as `en_GB`. An exact language and country match wins.
/// Otherwise the last supported locale of that language is used. English
/// without an exact match uses the `en_US` entry, not the last English
/// locale. A country-less `en` matches the `en` arb and stays country-less.
/// Any other language with no supported locale falls back to `en_US`.
Locale resolveAppLocale(Locale saved, Iterable<Locale> supportedLocales) {
  final country = saved.countryCode;
  final tag = country == null || country.isEmpty
      ? saved.languageCode
      : canonicalLanguageTag('${saved.languageCode}_$country');
  final parts = tag.split('_');
  final wanted =
      parts.length < 2 ? Locale(parts[0]) : Locale(parts[0], parts[1]);

  Locale? exact;
  Locale? lastOfLanguage;
  Locale? englishUs;
  for (final locale in supportedLocales) {
    if (locale.languageCode == wanted.languageCode &&
        locale.countryCode == wanted.countryCode) {
      exact ??= locale;
    }
    if (locale.languageCode == wanted.languageCode) {
      lastOfLanguage = locale;
    }
    if (locale.languageCode == 'en' && locale.countryCode == 'US') {
      englishUs = locale;
    }
  }
  if (exact != null) return exact;
  if (wanted.languageCode == 'en') {
    return englishUs ?? const Locale('en', 'US');
  }
  return lastOfLanguage ?? englishUs ?? const Locale('en', 'US');
}
