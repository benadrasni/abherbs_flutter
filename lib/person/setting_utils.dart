import 'package:abherbs_flutter/data/prefs.dart';
import 'package:abherbs_flutter/data/utils.dart';

/// `en_UK` was the old British ARB tag. Phones and `intl_en_GB.arb` use `en_GB`.
String canonicalLanguageTag(String language) {
  if (language == 'en_UK') return 'en_GB';
  return language;
}

/// Reads the saved language, stores `en_GB` in place of `en_UK`, and returns it.
Future<String> preferredLanguageTag() async {
  final stored = await Prefs.getStringF(keyPreferredLanguage);
  final canonical = canonicalLanguageTag(stored);
  if (canonical != stored) {
    await Prefs.setString(keyPreferredLanguage, canonical);
  }
  return canonical;
}

/// Row in [names] for a saved tag or a `language_COUNTRY` locale tag.
/// British English uses the English row when the list has no `en_GB` entry.
String? languageListKey(Map<String, String> names, String tag) {
  final canonical = canonicalLanguageTag(tag);
  if (names.containsKey(canonical)) return canonical;
  if (canonical == 'en_GB' && names.containsKey('en_US')) return 'en_US';
  return null;
}

const languages = {
  "ar_EG": "العربية",
  "bg_BG": "Български",
  "cs_CZ": "Čeština",
  "da_DK": "Dansk",
  "de_DE": "Deutsch",
  "en_US": "English",
  "es_ES": "Español",
  "et_EE": "Eesti",
  "fa_IR": "فارسی",
  "fr_FR": "Français",
  "hi_IN": "हिन्दी",
  "ko_KR": "한국어",
  "hr_HR": "Hrvatski",
  "id_ID": "Bahasa Indonesia",
  "it_IT": "Italiano",
  "he_IL": "עברית",
  "lv_LV": "Latviešu",
  "lt_LT": "Lietuvių",
  "hu_HU": "Magyar",
  "nl_NL": "Nederlands",
  "ja_JP": "日本語",
  "nb_NO": "Norsk",
  "pl_PL": "Polski",
  "pt_PT": "Português",
  "ro_RO": "Română",
  "ru_RU": "Русский",
  "sk_SK": "Slovenčina",
  "sl_SI": "Slovenščina",
  "sr_RS": "Српски",
  "sv_SE": "Svenska",
  "tr_TR": "Türkçe",
  "fi_FI": "Suomi",
  "uk_UA": "Українська",
  "zh_TW": "中文"
};