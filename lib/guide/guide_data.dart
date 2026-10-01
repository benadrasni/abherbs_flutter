import 'dart:async';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/guide/guide_results.dart';
import 'package:abherbs_flutter/guide/guide_seen.dart';
import 'package:abherbs_flutter/guide/guide_species.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

/// Families opens first. All lists on Find switches to [lists].
enum GuideBookSegment { families, genera, lists }

class GuideListCover {
  final String title;
  final String? photoPath;
  final List<String> thumbs;
  final DatabaseReference path;
  final bool isNew;
  final int count;
  final int? year;
  final int? yearFrom;
  final DateTime? latest;

  GuideListCover({
    required this.title,
    required this.photoPath,
    required this.path,
    required this.isNew,
    required this.count,
    this.thumbs = const [],
    this.year,
    this.yearFrom,
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
const guideResultsRouteName = 'GuideResults';
const guideListRouteName = 'GuideList';
const guideSpeciesRouteName = 'GuideSpecies';
const guidePersonRouteName = 'GuidePerson';
const guideSearchRouteName = 'GuideSearch';
const guideCameraRouteName = 'GuideCamera';
const guideOutsideRouteName = 'GuideOutside';
const guideCustomRouteName = 'GuideCustom';

/// How a custom list opens. Year values use the timeline. New in the book
/// groups recent additions by date. Everything else uses the result grid.
enum GuideCustomLayout { fresh, grid, years }

GuideCustomLayout guideCustomLayout(GuideListCover cover) {
  if (cover.isNew) return GuideCustomLayout.fresh;
  if (cover.year != null) return GuideCustomLayout.years;
  return GuideCustomLayout.grid;
}

/// Newest days of `lists_custom/new`, kept whole while the plant count
/// stays inside this band. A day is shortened only when leaving it whole
/// would pass the maximum before the minimum is met.
const guideNewPlantMin = 15;
const guideNewPlantMax = 25;

/// Tab actions for the field-guide shell. A pushed page cannot see the
/// shell's inherited widgets, so it calls these.
class GuideTabs {
  static void Function(int index)? show;
  static VoidCallback? showSeen;
  static VoidCallback? refreshSeen;

  /// Unconfirmed finds waiting on Seen. The shell writes this. Every bottom
  /// bar reads it, including bars on pages pushed over the shell.
  static final ValueNotifier<int> unconfirmed = ValueNotifier(0);
}

/// Leaves the key and opens a shell tab. Find stays selected while the key
/// is open; tapping Find, Book, or Seen returns to that tab.
void leaveGuideKeyForTab(BuildContext context, int index) {
  GuideTabs.show?.call(index);
  popGuideKeyToFind(context);
}

bool guideIsKeyRoute(String? name) {
  return name == guideHabitatRouteName ||
      name == guidePetalRouteName ||
      name == guideResultsRouteName;
}

void popGuideKeyToFind(BuildContext context) {
  Navigator.popUntil(context, (route) => !guideIsKeyRoute(route.settings.name));
}

/// The key on the camera returns to Find, including when search or the key
/// is still underneath.
void leaveGuideCameraForFind(BuildContext context) {
  GuideTabs.show?.call(0);
  Navigator.popUntil(context, (route) {
    final name = route.settings.name;
    return name != guideCameraRouteName &&
        name != guideOutsideRouteName &&
        name != guideSearchRouteName &&
        !guideIsKeyRoute(name);
  });
}

void popGuideKeyToHabitat(BuildContext context) {
  Navigator.popUntil(context, (route) {
    final name = route.settings.name;
    return name != guidePetalRouteName && name != guideResultsRouteName;
  });
}

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

Future<List<GuideResultPlant>> loadGuideResults({
  required String colorId,
  String? habitatId,
  required String petalId,
  String? regionId,
  required String languageCode,
}) async {
  final key = guideFilterKey(
    colorId: colorId,
    habitatId: habitatId,
    petalId: petalId,
    regionId: regionId,
  );
  final event = await listsV3Reference.child(key).once();
  final ids = guideResultIds(event.snapshot.value);
  if (ids.isEmpty) return [];
  final lang = getLanguageCode(languageCode);
  final plants = await Future.wait(
    ids.map((id) => _guideResultPlant(id, lang)),
  );
  return plants.whereType<GuideResultPlant>().toList();
}

/// Plants on a family or genus list. Same headers as the key's result list.
Future<List<GuideResultPlant>> loadGuideListedPlants(
  DatabaseReference path,
  String languageCode,
) async {
  final event = await path.once();
  final ids = guideResultIds(event.snapshot.value);
  if (ids.isEmpty) return const [];
  final lang = getLanguageCode(languageCode);
  final plants = await Future.wait(ids.map((id) async {
    return await _guideResultPlant(id, lang) ??
        await _guideHeaderPlant(id, lang);
  }));
  return plants.whereType<GuideResultPlant>().toList();
}

Future<String?> loadGuideTaxonTitle(String latin, String languageCode) async {
  if (latin.isEmpty) return null;
  final lang = getLanguageCode(languageCode);
  try {
    final event =
        await translationsTaxonomyReference.child(lang).child(latin).once();
    return guideTaxonVernacular(event.snapshot.value, latin);
  } catch (error) {
    debugPrint('guide list title $latin: $error');
    return null;
  }
}

Future<GuideResultPlant?> _guideResultPlant(String id, String language) async {
  try {
    final event = await headersV3Reference.child(id).once();
    final value = event.snapshot.value;
    if (value is! Map) return null;
    final name = value[firebaseAttributeName];
    if (name is! String || name.isEmpty) return null;
    final label = await _resultLabel(language, name);
    final plate = await _resultPlate(name);
    return readGuideResultHeader(id, value, label: label, platePath: plate);
  } catch (error) {
    debugPrint('guide result $id: $error');
    return null;
  }
}

Future<GuideResultPlant?> _guideHeaderPlant(String id, String language) async {
  try {
    final event = await listsReference.child(id).once();
    final value = event.snapshot.value;
    if (value is! Map) return null;
    final name = value[firebaseAttributeName];
    if (name is! String || name.isEmpty) return null;
    final label = await _resultLabel(language, name);
    final plate = await _resultPlate(name);
    return readGuideResultHeader(id, value, label: label, platePath: plate);
  } catch (error) {
    debugPrint('guide list header $id: $error');
    return null;
  }
}

Future<String?> _resultLabel(String language, String name) async {
  final cached = translationCache[name];
  if (cached != null && cached.isNotEmpty) return cached;
  try {
    final event = await translationsReference
        .child(language)
        .child(name)
        .child(firebaseAttributeLabel)
        .once();
    final value = event.snapshot.value;
    if (value is String && value.isNotEmpty) {
      translationCache[name] = value;
      return value;
    }
  } catch (error) {
    debugPrint('guide result label $name: $error');
  }
  return null;
}

Future<String?> _resultPlate(String name) async {
  try {
    final event =
        await plantsReference.child(name).child('illustrationUrl').once();
    final value = event.snapshot.value;
    if (value is String && value.isNotEmpty) return value;
  } catch (error) {
    debugPrint('guide result plate $name: $error');
  }
  return null;
}

Future<Set<String>> loadGuideSeenNames() async {
  final user = Auth.appUser;
  if (user == null) return {};
  try {
    final event = await privateObservationsReference
        .child(user.uid)
        .child(firebaseObservationsByPlant)
        .once();
    final value = event.snapshot.value;
    if (value is! Map) return {};
    return value.keys.map((key) => key.toString()).toSet();
  } catch (error) {
    debugPrint('guide seen names: $error');
    return {};
  }
}

Future<Map<String, int>> loadGuideRegionCounts({
  required String colorId,
  String? habitatId,
  required String petalId,
}) async {
  final ids = ['', ...guideAllRegionIds];
  final entries = await Future.wait(ids.map((id) async {
    final key = guideFilterKey(
      colorId: colorId,
      habitatId: habitatId,
      petalId: petalId,
      regionId: id.isEmpty ? null : id,
    );
    try {
      final event = await countsV3Reference.child(key).once();
      return MapEntry(id, guideResultInt(event.snapshot.value));
    } catch (error) {
      debugPrint('guide region count $key: $error');
      return MapEntry(id, 0);
    }
  }));
  return Map.fromEntries(entries);
}

Future<GuideResultPrefs> loadGuideResultPrefs() async {
  final region = await Prefs.getStringF(keyGuideRegion, '');
  final fromLocation = await Prefs.getBoolF(keyGuideRegionFromLocation, false);
  final wildOnly = await Prefs.getBoolF(keyGuideWildOnly, false);
  final refused = await Prefs.getBoolF(keyGuideLocationRefused, false);
  final regionId = region.isEmpty ? null : region;
  return GuideResultPrefs(
    regionId: regionId,
    fromLocation: fromLocation && regionId != null,
    wildOnly: wildOnly,
    locationRefused: refused,
  );
}

Future<void> saveGuideResultPrefs(GuideResultPrefs prefs) async {
  final regionId = prefs.regionId;
  if (regionId == null || regionId.isEmpty) {
    await Prefs.remove(keyGuideRegion);
  } else {
    await Prefs.setString(keyGuideRegion, regionId);
  }
  await Prefs.setBool(keyGuideRegionFromLocation, prefs.fromLocation);
  await Prefs.setBool(keyGuideWildOnly, prefs.wildOnly);
  await Prefs.setBool(keyGuideLocationRefused, prefs.locationRefused);
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
      thumbIds: body.thumbIds,
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
        yearFrom: body.yearFrom,
      ),
    ));
  });

  final newest = await _newestAddition();
  if (newest != null) {
    pending.add(_PendingCover(
      coverId: newest.coverId,
      thumbIds: newest.thumbIds,
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

  final photoIds = <String>{
    for (final item in pending) ...item.thumbIds,
    for (final item in pending)
      if (item.coverId != null) item.coverId!,
  };
  final photos = await _headerPhotos(photoIds);
  final covers = pending.map((item) {
    final cover = item.cover;
    final photo = item.coverId == null ? null : photos[item.coverId];
    final thumbs = [
      for (final id in item.thumbIds)
        if (photos[id] != null) photos[id]!,
    ];
    return GuideListCover(
      title: cover.title,
      photoPath: photo,
      thumbs: thumbs,
      path: cover.path,
      isNew: cover.isNew,
      count: cover.count,
      year: cover.year,
      yearFrom: cover.yearFrom,
      latest: cover.latest,
    );
  }).toList();

  covers.sort(compareGuideLists);
  return covers;
}

class _PendingCover {
  final String? coverId;
  final List<String> thumbIds;
  final GuideListCover cover;

  _PendingCover({
    required this.coverId,
    required this.thumbIds,
    required this.cover,
  });
}

/// The signed-in account, or the anonymous guest while that is the only
/// account. A missing Firebase app yields null.
User? guideNotebookUser() {
  final signedIn = Auth.appUser;
  if (signedIn != null) return signedIn;
  try {
    return Auth.guestUser;
  } catch (_) {
    return null;
  }
}

Future<List<GuideFind>> loadRecentFinds(String languageCode,
    {int limit = 5}) async {
  final user = guideNotebookUser();
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

/// Every private find for the Seen notebook, newest first.
Future<List<GuideSeenFind>> loadGuideSeen(String languageCode) async {
  final user = guideNotebookUser();
  if (user == null) return [];
  final event = await privateObservationsReference
      .child(user.uid)
      .child(firebaseObservationsByDate)
      .child(firebaseAttributeList)
      .once();
  final value = event.snapshot.value;
  if (value is! Map) return [];
  final rows = <GuideSeenFind>[];
  value.forEach((key, raw) {
    final row = readGuideSeenRow(key, raw);
    if (row != null) rows.add(row);
  });
  final lang = getLanguageCode(languageCode);
  final faces = <String, _SeenFace>{};
  await Future.wait(rows.map((row) => row.name).toSet().map((name) async {
    final needsPhoto = rows.any((row) => row.name == name && !row.ownPhoto);
    faces[name] = await _seenFace(name, lang, needsPhoto: needsPhoto);
  }));
  final decorated = [
    for (final row in rows)
      row.withCatalog(
        label: faces[row.name]?.label,
        catalogPhoto: faces[row.name]?.photo,
        inBook: faces[row.name]?.inBook ?? false,
      ),
  ];
  decorated.sort((a, b) {
    final byWhen = b.when.compareTo(a.when);
    if (byWhen != 0) return byWhen;
    return a.id.compareTo(b.id);
  });
  return decorated;
}

/// How many private finds are still unconfirmed. Used for the Seen tab badge
/// before the notebook itself is loaded.
Future<int> loadGuideUnconfirmedCount() async {
  final user = guideNotebookUser();
  if (user == null) return 0;
  final event = await privateObservationsReference
      .child(user.uid)
      .child(firebaseObservationsByDate)
      .child(firebaseAttributeList)
      .once();
  final value = event.snapshot.value;
  if (value is! Map) return 0;
  return countGuideUnconfirmedRows(value);
}

class _SeenFace {
  final String? label;
  final String? photo;
  final bool inBook;

  _SeenFace(this.label, this.photo, this.inBook);
}

Future<_SeenFace> _seenFace(
  String name,
  String languageCode, {
  required bool needsPhoto,
}) async {
  final label = await _seenLabel(name, languageCode);
  final photo = needsPhoto ? await _catalogPhoto(name) : null;
  final inBook = await _plantInBook(name);
  return _SeenFace(label, photo, inBook);
}

Future<String?> _seenLabel(String name, String languageCode) async {
  final cached = translationCache[name];
  if (cached != null && cached.isNotEmpty) return cached;
  try {
    final event = await translationsReference
        .child(languageCode)
        .child(name)
        .child(firebaseAttributeLabel)
        .once();
    final value = event.snapshot.value;
    if (value is String && value.isNotEmpty) {
      translationCache[name] = value;
      return value;
    }
  } catch (error) {
    debugPrint('guide seen label $name: $error');
  }
  return null;
}

Future<String?> _catalogPhoto(String name) async {
  try {
    final event = await plantsReference.child(name).child('photoUrls').once();
    final url = guideFirstText(event.snapshot.value);
    if (url == null) return null;
    return storagePhotos + url;
  } catch (error) {
    debugPrint('guide seen photo $name: $error');
    return null;
  }
}

Future<bool> _plantInBook(String name) async {
  try {
    final event = await plantsReference.child(name).child('id').once();
    final value = event.snapshot.value;
    return value != null && value.toString().isNotEmpty;
  } catch (error) {
    debugPrint('guide seen plant $name: $error');
    return false;
  }
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
  final int? yearFrom;
  final List<String> thumbIds;

  GuideListBody(
    this.count,
    this.coverId,
    this.year, {
    this.yearFrom,
    this.thumbIds = const [],
  });
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
  int? oldestYear;
  final dated = <MapEntry<String, int>>[];
  for (final entry in entries) {
    coverId ??= entry.key;
    final year = customListYear(entry.value);
    if (year == null) continue;
    dated.add(MapEntry(entry.key, year));
    if (latestYear == null || year > latestYear) {
      latestYear = year;
      coverId = entry.key;
    }
    if (oldestYear == null || year < oldestYear) oldestYear = year;
  }
  final order = <String, int>{
    for (var i = 0; i < entries.length; i++) entries[i].key: i,
  };
  dated.sort((a, b) {
    final byYear = b.value.compareTo(a.value);
    if (byYear != 0) return byYear;
    return order[a.key]!.compareTo(order[b.key]!);
  });
  final source = dated.isEmpty
      ? entries.map((entry) => entry.key)
      : dated.map((entry) => entry.key);
  return GuideListBody(
    entries.length,
    coverId,
    latestYear,
    yearFrom: oldestYear,
    thumbIds: source.take(4).toList(),
  );
}

class _Newest {
  final String dateKey;
  final DateTime? date;
  final int count;
  final String? coverId;
  final List<String> thumbIds;

  _Newest(
    this.dateKey,
    this.date,
    this.count,
    this.coverId,
    this.thumbIds,
  );
}

/// One dated drop under `lists_custom/new`, before the plants are loaded.
class GuideNewDrop {
  final String dateKey;
  final DateTime? date;
  final List<String> ids;

  const GuideNewDrop(this.dateKey, this.date, this.ids);
}

/// Plants added on one day, newest day first on the New in the book page.
class GuideNewDay {
  final String dateKey;
  final DateTime? date;
  final List<GuideResultPlant> plants;

  const GuideNewDay({
    required this.dateKey,
    required this.date,
    required this.plants,
  });
}

/// A year-list row. One plant keeps the later year when the list names it once.
class GuideYearEntry {
  final int year;
  final GuideResultPlant plant;

  const GuideYearEntry({required this.year, required this.plant});
}

class GuideYearList {
  final List<GuideYearEntry> entries;
  final String? sourceUrl;

  const GuideYearList({required this.entries, required this.sourceUrl});
}

class GuideYearId {
  final String id;
  final int year;

  const GuideYearId(this.id, this.year);
}

@visibleForTesting
List<GuideNewDrop> readGuideNewDrops(dynamic value) {
  if (value is! Map) return const [];
  final drops = <GuideNewDrop>[];
  value.forEach((key, raw) {
    if (raw is! Map) return;
    final dateKey = key.toString();
    DateTime? date;
    try {
      date = DateTime.parse(dateKey);
    } catch (_) {
      return;
    }
    final ids = guideResultIds(raw[firebaseAttributeList]);
    if (ids.isEmpty) return;
    drops.add(GuideNewDrop(dateKey, date, ids));
  });
  drops.sort((a, b) => b.dateKey.compareTo(a.dateKey));
  return drops;
}

@visibleForTesting
List<GuideNewDrop> selectGuideNewDrops(List<GuideNewDrop> newestFirst) {
  final chosen = <GuideNewDrop>[];
  var count = 0;
  for (final drop in newestFirst) {
    final next = count + drop.ids.length;
    if (count >= guideNewPlantMin && next > guideNewPlantMax) break;
    if (next <= guideNewPlantMax) {
      chosen.add(drop);
      count = next;
      continue;
    }
    final room = guideNewPlantMax - count;
    final ids = drop.ids.length <= room
        ? drop.ids
        : drop.ids.sublist(drop.ids.length - room);
    chosen.add(GuideNewDrop(drop.dateKey, drop.date, ids));
    break;
  }
  return chosen;
}

@visibleForTesting
List<GuideYearId> readGuideYearIds(dynamic list) {
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
  final dated = <GuideYearId>[];
  for (final entry in entries) {
    final year = customListYear(entry.value);
    if (year == null) continue;
    dated.add(GuideYearId(entry.key, year));
  }
  final order = {for (var i = 0; i < dated.length; i++) dated[i].id: i};
  dated.sort((a, b) {
    final byYear = b.year.compareTo(a.year);
    if (byYear != 0) return byYear;
    return order[a.id]!.compareTo(order[b.id]!);
  });
  return dated;
}

/// Host shown next to a year list, without the scheme.
String guideSourceHost(String url) {
  final uri = Uri.tryParse(url.trim());
  var host = (uri == null || uri.host.isEmpty) ? url.trim() : uri.host;
  if (host.startsWith('www.')) host = host.substring(4);
  return host;
}

Future<_Newest?> _newestAddition() async {
  final event = await listsCustomReference
      .child('new')
      .orderByKey()
      .limitToLast(guideNewPlantMax)
      .once();
  final drops = selectGuideNewDrops(readGuideNewDrops(event.snapshot.value));
  if (drops.isEmpty) return null;
  final ids = [for (final drop in drops) ...drop.ids];
  final newest = drops.first;
  return _Newest(
    newest.dateKey,
    newest.date,
    ids.length,
    ids.isEmpty ? null : ids.first,
    ids.take(4).toList(),
  );
}

Future<List<GuideNewDay>> loadGuideNewDays(String languageCode) async {
  final event = await listsCustomReference
      .child('new')
      .orderByKey()
      .limitToLast(guideNewPlantMax)
      .once();
  final drops = selectGuideNewDrops(readGuideNewDrops(event.snapshot.value));
  if (drops.isEmpty) return const [];
  final lang = getLanguageCode(languageCode);
  final days = <GuideNewDay>[];
  for (final drop in drops) {
    final plants = await Future.wait(drop.ids.map((id) async {
      return await _guideResultPlant(id, lang) ??
          await _guideHeaderPlant(id, lang);
    }));
    days.add(GuideNewDay(
      dateKey: drop.dateKey,
      date: drop.date,
      plants: plants.whereType<GuideResultPlant>().toList(),
    ));
  }
  return days;
}

Future<GuideYearList> loadGuideYearList(
  DatabaseReference path,
  String languageCode,
) async {
  final event = await path.once();
  final rows = readGuideYearIds(event.snapshot.value);
  String? sourceUrl;
  final parent = path.parent;
  if (parent != null) {
    try {
      final source = await parent.child(firebaseAttributeSourceUrl).once();
      final value = source.snapshot.value;
      if (value is String && value.isNotEmpty) sourceUrl = value;
    } catch (error) {
      debugPrint('guide year source: $error');
    }
  }
  if (rows.isEmpty) {
    return GuideYearList(entries: const [], sourceUrl: sourceUrl);
  }
  final lang = getLanguageCode(languageCode);
  final entries = await Future.wait(rows.map((row) async {
    final plant = await _guideResultPlant(row.id, lang) ??
        await _guideHeaderPlant(row.id, lang);
    if (plant == null) return null;
    return GuideYearEntry(year: row.year, plant: plant);
  }));
  return GuideYearList(
    entries: entries.whereType<GuideYearEntry>().toList(),
    sourceUrl: sourceUrl,
  );
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

Future<GuideSpecies?> loadGuideSpecies(String name, String languageCode) async {
  final lang = getLanguageCode(languageCode);
  final event = await plantsReference.child(name).once();
  final raw = event.snapshot.value;
  if (!guidePlantRecord(raw)) {
    _keepSpeciesSynced(name, lang);
    return null;
  }
  final plant = Map<dynamic, dynamic>.from(raw as Map);
  final translation = await _guideTranslation(lang, name);
  final family = guideFamilyLatin(plant['APGIV']);
  final latins = <String>{
    if (family != null) family,
    for (final rank in guideSpeciesRanks(plant['APGIV'], const {})) rank.latin,
  };
  final vernaculars = await _guideVernaculars(lang, latins);
  final sightings = await _guideSightings(name);
  final seen = await _guideSpeciesSeen(name);
  return assembleGuideSpecies(
    name: name,
    plant: plant,
    translation: translation,
    vernaculars: vernaculars,
    sightings: sightings,
    seen: seen,
  );
}

Future<void> saveGuideSeen(GuideSeenDraft draft) async {
  final user = Auth.appUser;
  if (user == null) {
    throw StateError('sign in to save a find');
  }
  final millis = DateTime.now().millisecondsSinceEpoch;
  final observation = Observation(draft.plant);
  observation.id = '${user.uid}_$millis';
  observation.date = draft.when;
  observation.latitude = draft.latitude;
  observation.longitude = draft.longitude;
  observation.note = '';
  observation.photoPaths = [
    if (draft.photoPath != null && draft.photoPath!.isNotEmpty)
      draft.photoPath!,
  ];
  observation.status = observationStatusPrivate;
  observation.order = -draft.when.millisecondsSinceEpoch;
  observation.confirmed = true;
  observation.source = observationSourceManual;
  final json = observation.toJson();
  final root = privateObservationsReference.child(user.uid);
  await root
      .child(firebaseObservationsByDate)
      .child(firebaseAttributeList)
      .child(observation.id)
      .set(json);
  await root
      .child(firebaseObservationsByPlant)
      .child(draft.plant)
      .child(firebaseAttributeList)
      .child(observation.id)
      .set(json);
}

Future<PlantTranslation> _guideTranslation(String lang, String name) async {
  final event = await translationsReference.child(lang).child(name).once();
  final raw = event.snapshot.value;
  final local = raw is Map
      ? PlantTranslation.fromJson(Map<dynamic, dynamic>.from(raw))
      : PlantTranslation();
  if (lang == languageEnglish || local.isTranslated()) return local;
  try {
    final english =
        await translationsReference.child(languageEnglish).child(name).once();
    final fallback = english.snapshot.value;
    if (fallback is Map) {
      local.fillMissingFrom(
        PlantTranslation.fromJson(Map<dynamic, dynamic>.from(fallback)),
      );
    }
  } catch (error) {
    debugPrint('guide species english $name: $error');
  }
  return local;
}

Future<Map<String, String>> _guideVernaculars(
  String lang,
  Set<String> latins,
) async {
  final vernaculars = <String, String>{};
  await Future.wait(latins.map((latin) async {
    try {
      final event =
          await translationsTaxonomyReference.child(lang).child(latin).once();
      final name = guideTaxonVernacular(event.snapshot.value, latin);
      if (name != null) vernaculars[latin] = name;
    } catch (error) {
      debugPrint('guide species taxon $latin: $error');
    }
  }));
  return vernaculars;
}

Future<List<GuideSighting>> _guideSightings(String name) async {
  try {
    final event = await publicObservationsReference
        .child(firebaseObservationsByPlant)
        .child(name)
        .child(firebaseAttributeList)
        .once();
    return guideSightings(event.snapshot.value);
  } catch (error) {
    debugPrint('guide species sightings $name: $error');
    return const [];
  }
}

Future<GuideSpeciesSeen?> _guideSpeciesSeen(String name) async {
  final user = guideNotebookUser();
  if (user == null) return null;
  try {
    final event = await privateObservationsReference
        .child(user.uid)
        .child(firebaseObservationsByPlant)
        .child(name)
        .child(firebaseAttributeList)
        .once();
    final value = event.snapshot.value;
    final Iterable<dynamic> rows;
    if (value is List) {
      rows = value;
    } else if (value is Map) {
      rows = value.values;
    } else {
      rows = const [];
    }
    return guideSpeciesSeen(rows);
  } catch (error) {
    debugPrint('guide species seen $name: $error');
    return null;
  }
}

void _keepSpeciesSynced(String name, String lang) {
  unawaited(plantsReference.child(name).keepSynced(true));
  unawaited(translationsReference.child(lang).child(name).keepSynced(true));
  if (lang != languageEnglish) {
    unawaited(
      translationsReference.child(languageEnglish).child(name).keepSynced(true),
    );
  }
}
