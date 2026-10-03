import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:abherbs_flutter/person/guide_person.dart';
import 'package:abherbs_flutter/person/authentication.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class SearchResult {
  double? confidence;
  int? count;
  String? entityId;
  String? labelInLanguage;
  String? labelLatin;
  String? path;
  Map<String, dynamic>? plantDetails;
  List<dynamic>? similarImages;
  String? commonName;
}

/// Why `identifyPlant` did not call Plant.id.
enum PhotoRefusal {
  signIn,
  noCredits,
  noNames,
  dailyCeiling,
  cooldown,
  repeatPhoto
}

PhotoRefusal? _refusal(String? reason) {
  switch (reason) {
    case 'sign-in':
      return PhotoRefusal.signIn;
    case 'no-credits':
      return PhotoRefusal.noCredits;
    case 'no-names':
      return PhotoRefusal.noNames;
    case 'daily-ceiling':
      return PhotoRefusal.dailyCeiling;
    case 'cooldown':
      return PhotoRefusal.cooldown;
    case 'repeat-photo':
      return PhotoRefusal.repeatPhoto;
  }
  return null;
}

class PhotoIdentification {
  final List<SearchResult> results;
  final PhotoRefusal? refusal;
  final bool failed;

  /// A monthly name was used. A photo that is not a plant is free only for
  /// the first few each month.
  final bool charged;

  /// Names charged this UTC month, when the server sent the meter.
  final int? namesUsed;

  /// Ad grants earned this UTC month.
  final int? adGrants;

  /// The guest account spent its one free identification on this photo.
  final bool guestFreeUsed;

  const PhotoIdentification(
    this.results, {
    this.refusal,
    this.failed = false,
    this.charged = false,
    this.guestFreeUsed = false,
    this.namesUsed,
    this.adGrants,
  });
}

/// `language` for `identifyPlant`. The region stays on the tag so Traditional
/// Chinese (`zh-TW`) and Portuguese can be mapped to Plant.id's codes.
String plantIdLanguageTag(Locale locale) {
  final country = locale.countryCode;
  if (country == null || country.isEmpty) return locale.languageCode;
  return '${locale.languageCode}-$country';
}

/// Names a photo through the `identifyPlant` Cloud Function, which holds the
/// Plant.id key and counts the allowance. No results with no refusal means
/// Plant.id found no plant.
Future<PhotoIdentification> identifyPlantPhoto({
  required File image,
  required String languageCode,
  void Function()? onCreditsChanged,
}) async {
  if (Auth.firebaseAuth.currentUser == null) await Auth.startGuest();
  if (Auth.firebaseAuth.currentUser == null) {
    return const PhotoIdentification([], refusal: PhotoRefusal.signIn);
  }
  try {
    final bytes = await image.readAsBytes();
    final response = await FirebaseFunctions.instance
        .httpsCallable(
      'identifyPlant',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    )
        .call({'image': base64Encode(bytes), 'language': languageCode});
    final data = jsonDecode(jsonEncode(response.data)) as Map<String, dynamic>;
    _applyMeter(data);
    onCreditsChanged?.call();
    final results = <SearchResult>[];
    final suggestions = data['suggestions'];
    if (suggestions is List) {
      for (final suggestion in suggestions) {
        if (suggestion == null) continue;
        results.add(await _readSuggestion(suggestion, languageCode));
      }
    }
    if (results.isNotEmpty) {
      _saveLabels(results, languageCode);
    }
    return PhotoIdentification(
      results,
      charged: data['charged'] == true,
      guestFreeUsed: data['anonymousFreeUsed'] == true,
      namesUsed: _meterInt(data['namesUsed']),
      adGrants: _meterInt(data['adGrants']),
    );
  } on FirebaseFunctionsException catch (error, stackTrace) {
    final details = error.details;
    final refusal =
        _refusal(details is Map ? details['reason'] : error.message);
    if (error.code == 'resource-exhausted' && refusal != null) {
      if (refusal == PhotoRefusal.noNames) {
        final count = await loadGuideMonthCount();
        guideMonthCount.value = count;
        onCreditsChanged?.call();
      }
      return PhotoIdentification(const [], refusal: refusal);
    }
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
    return const PhotoIdentification([], failed: true);
  } catch (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
    return const PhotoIdentification([], failed: true);
  }
}

void _applyMeter(Map<String, dynamic> data) {
  if (Auth.appUser == null) return;
  final used = _meterInt(data['namesUsed']);
  final grants = _meterInt(data['adGrants']);
  if (used == null || grants == null) return;
  guideMonthCount.value = GuideMonthCount(namesUsed: used, adGrants: grants);
}

int? _meterInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

Future<SearchResult> _readSuggestion(
  dynamic suggestion,
  String languageCode,
) async {
  final plantName = suggestion['plant_details']['scientific_name'] as String;
  final event = await rootReference
      .child(
        '$firebaseSearchPhoto/${plantName.toLowerCase().replaceAll('.', '')}',
      )
      .once();
  final result = SearchResult();
  result.labelLatin = plantName;
  result.entityId = suggestion['id'].toString();
  result.confidence = suggestion['probability'];
  result.plantDetails = suggestion['plant_details'];
  result.similarImages = suggestion['similar_images'];
  final names = suggestion['plant_details']['common_names'];
  result.commonName = names != null ? names[0] : "";
  if (event.snapshot.exists && event.snapshot.value != null) {
    final value = event.snapshot.value as Map;
    result.count = value['count'];
    result.path = value['path'];
    result.labelInLanguage = '';
    if (result.path!.contains('/')) {
      final path = result.path!.substring(0, result.path!.length - 5);
      result.labelLatin = path.substring(path.lastIndexOf('/') + 1);
    } else {
      result.labelLatin = result.path;
      final code = getLanguageCode(languageCode);
      translationsReference
          .child(code)
          .child(result.labelLatin!)
          .keepSynced(true);
      final labelEvent = await translationsReference
          .child(code)
          .child(result.labelLatin!)
          .child(firebaseAttributeLabel)
          .once();
      if (labelEvent.snapshot.value != null) {
        result.labelInLanguage = labelEvent.snapshot.value as String;
      }
      return result;
    }
    if (translationCache.containsKey(result.labelLatin)) {
      result.labelInLanguage = translationCache[result.labelLatin];
      return result;
    }
    translationsTaxonomyReference
        .child(languageCode)
        .child(result.labelLatin!)
        .keepSynced(true);
    final taxonEvent = await translationsTaxonomyReference
        .child(languageCode)
        .child(result.labelLatin!)
        .once();
    final taxon = taxonEvent.snapshot.value;
    if (taxon != null && (taxon as List).isNotEmpty) {
      translationCache[result.labelLatin!] = taxon[0];
      result.labelInLanguage = taxon[0];
    }
  }
  return result;
}

void _saveLabels(List<SearchResult> results, String languageCode) {
  final userId =
      Auth.firebaseAuth.currentUser?.uid ?? firebaseAttributeAnonymous;
  rootReference
      .child(firebaseUsersPhotoSearch)
      .child(languageCode)
      .child(userId)
      .child(DateTime.now().millisecondsSinceEpoch.toString())
      .set(results.map((searchResult) {
        final labelMap = <String, dynamic>{};
        labelMap['entityId'] = searchResult.entityId;
        labelMap['language'] = languageCode;
        labelMap['confidence'] = searchResult.confidence;
        labelMap['plantDetails'] = searchResult.plantDetails;
        labelMap['similarImages'] = searchResult.similarImages;
        if (searchResult.labelLatin != null) {
          labelMap['label_latin'] = searchResult.labelLatin;
        }
        if (searchResult.labelInLanguage != null) {
          labelMap['label_language'] = searchResult.labelInLanguage;
        }
        return labelMap;
      }).toList());
}
