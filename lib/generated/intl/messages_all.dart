// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that looks up messages for specific locales by
// delegating to the appropriate library.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:implementation_imports, file_names, unnecessary_new
// ignore_for_file:unnecessary_brace_in_string_interps, directives_ordering
// ignore_for_file:argument_type_not_assignable, invalid_assignment
// ignore_for_file:prefer_single_quotes, prefer_generic_function_type_aliases
// ignore_for_file:comment_references

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';

import 'messages_ar_EG.dart' as messages_ar_eg;
import 'messages_cs_CZ.dart' as messages_cs_cz;
import 'messages_da_DK.dart' as messages_da_dk;
import 'messages_de_DE.dart' as messages_de_de;
import 'messages_en.dart' as messages_en;
import 'messages_en_UK.dart' as messages_en_uk;
import 'messages_en_US.dart' as messages_en_us;
import 'messages_es_ES.dart' as messages_es_es;
import 'messages_et_EE.dart' as messages_et_ee;
import 'messages_fa_IR.dart' as messages_fa_ir;
import 'messages_fi_FI.dart' as messages_fi_fi;
import 'messages_fr_FR.dart' as messages_fr_fr;
import 'messages_he_IL.dart' as messages_he_il;
import 'messages_hi_IN.dart' as messages_hi_in;
import 'messages_hr_HR.dart' as messages_hr_hr;
import 'messages_hu_HU.dart' as messages_hu_hu;
import 'messages_id_ID.dart' as messages_id_id;
import 'messages_it_IT.dart' as messages_it_it;
import 'messages_ja_JP.dart' as messages_ja_jp;
import 'messages_ko_KR.dart' as messages_ko_kr;
import 'messages_lt_LT.dart' as messages_lt_lt;
import 'messages_lv_LV.dart' as messages_lv_lv;
import 'messages_nb_NO.dart' as messages_nb_no;
import 'messages_nl_NL.dart' as messages_nl_nl;
import 'messages_pl_PL.dart' as messages_pl_pl;
import 'messages_pt_PT.dart' as messages_pt_pt;
import 'messages_ro_RO.dart' as messages_ro_ro;
import 'messages_ru_RU.dart' as messages_ru_ru;
import 'messages_sk_SK.dart' as messages_sk_sk;
import 'messages_sl_SI.dart' as messages_sl_si;
import 'messages_sr_RS.dart' as messages_sr_rs;
import 'messages_sv_SE.dart' as messages_sv_se;
import 'messages_uk_UA.dart' as messages_uk_ua;

typedef Future<dynamic> LibraryLoader();
Map<String, LibraryLoader> _deferredLibraries = {
  'ar_EG': () => new Future.value(null),
  'cs_CZ': () => new Future.value(null),
  'da_DK': () => new Future.value(null),
  'de_DE': () => new Future.value(null),
  'en': () => new Future.value(null),
  'en_UK': () => new Future.value(null),
  'en_US': () => new Future.value(null),
  'es_ES': () => new Future.value(null),
  'et_EE': () => new Future.value(null),
  'fa_IR': () => new Future.value(null),
  'fi_FI': () => new Future.value(null),
  'fr_FR': () => new Future.value(null),
  'he_IL': () => new Future.value(null),
  'hi_IN': () => new Future.value(null),
  'hr_HR': () => new Future.value(null),
  'hu_HU': () => new Future.value(null),
  'id_ID': () => new Future.value(null),
  'it_IT': () => new Future.value(null),
  'ja_JP': () => new Future.value(null),
  'ko_KR': () => new Future.value(null),
  'lt_LT': () => new Future.value(null),
  'lv_LV': () => new Future.value(null),
  'nb_NO': () => new Future.value(null),
  'nl_NL': () => new Future.value(null),
  'pl_PL': () => new Future.value(null),
  'pt_PT': () => new Future.value(null),
  'ro_RO': () => new Future.value(null),
  'ru_RU': () => new Future.value(null),
  'sk_SK': () => new Future.value(null),
  'sl_SI': () => new Future.value(null),
  'sr_RS': () => new Future.value(null),
  'sv_SE': () => new Future.value(null),
  'uk_UA': () => new Future.value(null),
};

MessageLookupByLibrary _findExact(String localeName) {
  switch (localeName) {
    case 'ar_EG':
      return messages_ar_eg.messages;
    case 'cs_CZ':
      return messages_cs_cz.messages;
    case 'da_DK':
      return messages_da_dk.messages;
    case 'de_DE':
      return messages_de_de.messages;
    case 'en':
      return messages_en.messages;
    case 'en_UK':
      return messages_en_uk.messages;
    case 'en_US':
      return messages_en_us.messages;
    case 'es_ES':
      return messages_es_es.messages;
    case 'et_EE':
      return messages_et_ee.messages;
    case 'fa_IR':
      return messages_fa_ir.messages;
    case 'fi_FI':
      return messages_fi_fi.messages;
    case 'fr_FR':
      return messages_fr_fr.messages;
    case 'he_IL':
      return messages_he_il.messages;
    case 'hi_IN':
      return messages_hi_in.messages;
    case 'hr_HR':
      return messages_hr_hr.messages;
    case 'hu_HU':
      return messages_hu_hu.messages;
    case 'id_ID':
      return messages_id_id.messages;
    case 'it_IT':
      return messages_it_it.messages;
    case 'ja_JP':
      return messages_ja_jp.messages;
    case 'ko_KR':
      return messages_ko_kr.messages;
    case 'lt_LT':
      return messages_lt_lt.messages;
    case 'lv_LV':
      return messages_lv_lv.messages;
    case 'nb_NO':
      return messages_nb_no.messages;
    case 'nl_NL':
      return messages_nl_nl.messages;
    case 'pl_PL':
      return messages_pl_pl.messages;
    case 'pt_PT':
      return messages_pt_pt.messages;
    case 'ro_RO':
      return messages_ro_ro.messages;
    case 'ru_RU':
      return messages_ru_ru.messages;
    case 'sk_SK':
      return messages_sk_sk.messages;
    case 'sl_SI':
      return messages_sl_si.messages;
    case 'sr_RS':
      return messages_sr_rs.messages;
    case 'sv_SE':
      return messages_sv_se.messages;
    case 'uk_UA':
      return messages_uk_ua.messages;
    default:
      return null;
  }
}

/// User programs should call this before using [localeName] for messages.
Future<bool> initializeMessages(String localeName) async {
  var availableLocale = Intl.verifiedLocale(
    localeName,
    (locale) => _deferredLibraries[locale] != null,
    onFailure: (_) => null);
  if (availableLocale == null) {
    return new Future.value(false);
  }
  var lib = _deferredLibraries[availableLocale];
  await (lib == null ? new Future.value(false) : lib());
  initializeInternalMessageLookup(() => new CompositeMessageLookup());
  messageLookup.addLocale(availableLocale, _findGeneratedMessagesFor);
  return new Future.value(true);
}

bool _messagesExistFor(String locale) {
  try {
    return _findExact(locale) != null;
  } catch (e) {
    return false;
  }
}

MessageLookupByLibrary _findGeneratedMessagesFor(String locale) {
  var actualLocale = Intl.verifiedLocale(locale, _messagesExistFor,
      onFailure: (_) => null);
  if (actualLocale == null) return null;
  return _findExact(actualLocale);
}
