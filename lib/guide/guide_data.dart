import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class GuideListCover {
  final String title;
  final String? photoPath;
  final DatabaseReference path;
  final bool isNew;
  final int count;
  final int? year;
  final DateTime? latest;

  GuideListCover({
    required this.title,
    required this.photoPath,
    required this.path,
    required this.isNew,
    required this.count,
    this.year,
    this.latest,
  });
}

class GuideFind {
  final String name;
  final String? label;
  final DateTime when;
  final String? photoPath;

  GuideFind({
    required this.name,
    required this.label,
    required this.when,
    required this.photoPath,
  });
}

const guideHabitatRouteName = 'GuideHabitat';
const guidePetalRouteName = 'GuidePetal';

/// v3 habitat codes, in the order the key shows them.
const guideHabitatIds = ['4', '1', '7', '8', '3', '9', '5', '10'];
const guidePetalIds = ['1', '2', '3', '4'];

Future<Map<String, int>> loadColorCounts() async {
  const ids = ['1', '2', '3', '4', '5'];
  final entries = await Future.wait(ids.map((id) async {
    final event = await countsReference.child('${id}___').once();
    return MapEntry(id, _asInt(event.snapshot.value));
  }));
  return Map.fromEntries(entries);
}

String guideFilterKey({
  String? colorId,
  String? habitatId,
  String? petalId,
  String? regionId,
}) {
  return getFilterKey({
    if (colorId != null && colorId.isNotEmpty) filterColor: colorId,
    if (habitatId != null && habitatId.isNotEmpty) filterHabitat: habitatId,
    if (petalId != null && petalId.isNotEmpty) filterPetal: petalId,
    if (regionId != null && regionId.isNotEmpty) filterDistribution: regionId,
  });
}

class GuideHabitatCounts {
  final int total;
  final Map<String, int> byHabitat;

  const GuideHabitatCounts({required this.total, required this.byHabitat});
}

Future<GuideHabitatCounts> loadHabitatCounts(String colorId) async {
  final keys = [
    guideFilterKey(colorId: colorId),
    for (final id in guideHabitatIds)
      guideFilterKey(colorId: colorId, habitatId: id),
  ];
  final counts = await _loadV3Counts(keys);
  return GuideHabitatCounts(
    total: counts[guideFilterKey(colorId: colorId)] ?? 0,
    byHabitat: {
      for (final id in guideHabitatIds)
        id: counts[guideFilterKey(colorId: colorId, habitatId: id)] ?? 0,
    },
  );
}

Future<Map<String, int>> loadPetalCounts(
  String colorId,
  String? habitatId,
) async {
  final keys = [
    for (final id in guidePetalIds)
      guideFilterKey(colorId: colorId, habitatId: habitatId, petalId: id),
  ];
  final counts = await _loadV3Counts(keys);
  return {
    for (final id in guidePetalIds)
      id: counts[guideFilterKey(
            colorId: colorId,
            habitatId: habitatId,
            petalId: id,
          )] ??
          0,
  };
}

Future<Map<String, int>> _loadV3Counts(List<String> keys) async {
  final entries = await Future.wait(keys.map((key) async {
    final event = await countsV3Reference.child(key).once();
    return MapEntry(key, _asInt(event.snapshot.value));
  }));
  return Map.fromEntries(entries);
}

Future<List<GuideListCover>> loadGuideLists(String languageCode) async {
  final chosen = await _languageLists(languageCode);
  final pending = <_PendingCover>[];

  chosen.lists.forEach((key, raw) {
    if (raw is! Map) return;
    final body = readGuideList(raw[firebaseAttributeList]);
    if (body.count == 0) return;
    pending.add(_PendingCover(
      coverId: body.coverId,
      cover: GuideListCover(
        title: key.toString(),
        photoPath: null,
        path: listsCustomReference
            .child('by language')
            .child(chosen.code)
            .child(key.toString())
            .child(firebaseAttributeList),
        isNew: false,
        count: body.count,
        year: body.year,
      ),
    ));
  });

  final newest = await _newestAddition();
  if (newest != null) {
    pending.add(_PendingCover(
      coverId: newest.coverId,
      cover: GuideListCover(
        title: '',
        photoPath: null,
        path: listsCustomReference
            .child('new')
            .child(newest.dateKey)
            .child(firebaseAttributeList),
        isNew: true,
        count: newest.count,
        latest: newest.date,
      ),
    ));
  }

  final photos = await _headerPhotos(
    pending.map((item) => item.coverId).whereType<String>().toSet(),
  );
  final covers = pending.map((item) {
    final cover = item.cover;
    final photo = item.coverId == null ? null : photos[item.coverId];
    return GuideListCover(
      title: cover.title,
      photoPath: photo,
      path: cover.path,
      isNew: cover.isNew,
      count: cover.count,
      year: cover.year,
      latest: cover.latest,
    );
  }).toList();

  covers.sort(compareGuideLists);
  return covers;
}

class _PendingCover {
  final String? coverId;
  final GuideListCover cover;

  _PendingCover({required this.coverId, required this.cover});
}

Future<List<GuideFind>> loadRecentFinds(String languageCode,
    {int limit = 5}) async {
  final user = Auth.appUser;
  if (user == null) return [];
  final event = await privateObservationsReference
      .child(user.uid)
      .child(firebaseObservationsByDate)
      .child(firebaseAttributeList)
      .orderByChild(firebaseAttributeOrder)
      .limitToLast(limit)
      .once();
  final value = event.snapshot.value;
  if (value is! Map) return [];

  final rawFinds = <_RawFind>[];
  value.forEach((key, raw) {
    if (raw is! Map) return;
    final name = raw[observationPlant];
    if (name is! String || name.isEmpty) return;
    rawFinds.add(_RawFind(name, guideFindWhen(raw), _ownPhoto(raw)));
  });
  rawFinds.sort((a, b) => b.when.compareTo(a.when));

  final lang = getLanguageCode(languageCode);
  return Future.wait(rawFinds.map((raw) => _decorateFind(raw, lang)));
}

@visibleForTesting
int guideListRank(GuideListCover cover) {
  if (cover.isNew) return 0;
  if (cover.year != null) return 1;
  return 2;
}

@visibleForTesting
int compareGuideLists(GuideListCover a, GuideListCover b) {
  final byRank = guideListRank(a).compareTo(guideListRank(b));
  if (byRank != 0) return byRank;
  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

@visibleForTesting
class GuideListBody {
  final int count;
  final String? coverId;
  final int? year;

  GuideListBody(this.count, this.coverId, this.year);
}

@visibleForTesting
GuideListBody readGuideList(dynamic list) {
  final entries = <MapEntry<String, dynamic>>[];
  if (list is List) {
    for (var i = 0; i < list.length; i++) {
      if (list[i] != null) entries.add(MapEntry(i.toString(), list[i]));
    }
  } else if (list is Map) {
    list.forEach((key, value) {
      if (value != null) entries.add(MapEntry(key.toString(), value));
    });
  }
  entries.sort((a, b) {
    final na = int.tryParse(a.key);
    final nb = int.tryParse(b.key);
    if (na != null && nb != null) return na.compareTo(nb);
    return a.key.compareTo(b.key);
  });

  String? coverId;
  int? latestYear;
  for (final entry in entries) {
    coverId ??= entry.key;
    final year = customListYear(entry.value);
    if (year != null && (latestYear == null || year > latestYear)) {
      latestYear = year;
      coverId = entry.key;
    }
  }
  return GuideListBody(entries.length, coverId, latestYear);
}

class _Newest {
  final String dateKey;
  final DateTime? date;
  final int count;
  final String? coverId;

  _Newest(this.dateKey, this.date, this.count, this.coverId);
}

Future<_Newest?> _newestAddition() async {
  final event = await listsCustomReference
      .child('new')
      .orderByKey()
      .limitToLast(1)
      .once();
  final value = event.snapshot.value;
  if (value is! Map || value.isEmpty) return null;
  final dateKey = value.keys.first.toString();
  final node = value.values.first;
  if (node is! Map) return null;
  final body = readGuideList(node[firebaseAttributeList]);
  DateTime? date;
  try {
    date = DateTime.parse(dateKey);
  } catch (_) {
    date = null;
  }
  return _Newest(dateKey, date, body.count, body.coverId);
}

class _LanguageLists {
  final String code;
  final Map<dynamic, dynamic> lists;

  _LanguageLists(this.code, this.lists);
}

Future<_LanguageLists> _languageLists(String languageCode) async {
  var code = getLanguageCode(languageCode);
  var event =
      await listsCustomReference.child('by language').child(code).once();
  if (_isEmptyMap(event.snapshot.value) && code != 'en') {
    code = 'en';
    event = await listsCustomReference.child('by language').child(code).once();
  }
  final value = event.snapshot.value;
  if (value is Map) return _LanguageLists(code, value);
  return _LanguageLists(code, {});
}

bool _isEmptyMap(dynamic value) {
  return value is! Map || value.isEmpty;
}

Future<Map<String, String>> _headerPhotos(Set<String> ids) async {
  final photos = <String, String>{};
  await Future.wait(ids.map((id) async {
    try {
      final event =
          await listsReference.child(id).child(firebaseAttributeUrl).once();
      final url = event.snapshot.value;
      if (url is String && url.isNotEmpty) {
        photos[id] = storagePhotos + url;
      }
    } catch (error) {
      debugPrint('guide photo $id: $error');
    }
  }));
  return photos;
}

class _RawFind {
  final String name;
  final DateTime when;
  final String? photoPath;

  _RawFind(this.name, this.when, this.photoPath);
}

Future<GuideFind> _decorateFind(_RawFind raw, String languageCode) async {
  var photo = raw.photoPath;
  if (photo == null) {
    try {
      final event =
          await plantsReference.child(raw.name).child('photoUrls').once();
      final url = guideFirstText(event.snapshot.value);
      if (url != null) photo = storagePhotos + url;
    } catch (error) {
      debugPrint('guide find photo ${raw.name}: $error');
    }
  }

  String? label = translationCache[raw.name];
  if (label == null || label.isEmpty) {
    try {
      final event = await translationsReference
          .child(languageCode)
          .child(raw.name)
          .child(firebaseAttributeLabel)
          .once();
      final value = event.snapshot.value;
      if (value is String && value.isNotEmpty) {
        label = value;
        translationCache[raw.name] = value;
      } else {
        label = null;
      }
    } catch (error) {
      debugPrint('guide find label ${raw.name}: $error');
      label = null;
    }
  }

  return GuideFind(
    name: raw.name,
    label: label,
    when: raw.when,
    photoPath: photo,
  );
}

String? _ownPhoto(Map raw) {
  return guideFirstText(raw[observationPhotoPaths]);
}

@visibleForTesting
String? guideFirstText(dynamic raw) {
  if (raw is List) {
    for (final item in raw) {
      if (item != null && item.toString().isNotEmpty) return item.toString();
    }
  } else if (raw is Map) {
    final keys = raw.keys.map((key) => key.toString()).toList()..sort();
    for (final key in keys) {
      final item = raw[key];
      if (item != null && item.toString().isNotEmpty) return item.toString();
    }
  }
  return null;
}

@visibleForTesting
DateTime guideFindWhen(Map raw) {
  final date = raw[observationDate];
  if (date is Map) {
    final time = date[observationTime];
    if (time is int) return DateTime.fromMillisecondsSinceEpoch(time);
    if (time is num) return DateTime.fromMillisecondsSinceEpoch(time.toInt());
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}
