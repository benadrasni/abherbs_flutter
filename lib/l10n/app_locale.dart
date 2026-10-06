import 'package:flutter/widgets.dart';

const _english = 'en';

/// Picks the UI locale for [saved].
///
/// A British phone reports `en_GB`. Older builds stored `en_UK`, which never
/// matched that, so those devices received `en_US`. `en_US` stays the English
/// locale when the country is anything else.
Locale resolveAppLocale(Locale saved, Iterable<Locale> supportedLocales) {
  final wanted = saved.languageCode == _english && saved.countryCode == 'UK'
      ? const Locale(_english, 'GB')
      : saved;

  Locale? resultLocale;
  final defaultLocale = <String, Locale>{};
  for (final locale in supportedLocales) {
    if (locale.languageCode == wanted.languageCode &&
        locale.countryCode == wanted.countryCode) {
      resultLocale = locale;
      break;
    }

    if (locale.languageCode != _english || locale.countryCode == 'US') {
      defaultLocale[locale.languageCode] = locale;
    }
  }

  if (resultLocale == null) {
    for (final locale in supportedLocales) {
      if (locale.languageCode == wanted.languageCode) {
        resultLocale = defaultLocale[locale.languageCode];
        break;
      }
    }
  }

  resultLocale ??= defaultLocale[_english];
  return resultLocale!;
}
