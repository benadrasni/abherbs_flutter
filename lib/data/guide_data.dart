import 'dart:async';

import 'package:abherbs_flutter/seen/observation.dart';
import 'package:abherbs_flutter/data/plant_translation.dart';
import 'package:abherbs_flutter/key/filter_utils.dart';
import 'package:abherbs_flutter/seen/guide_private_photos.dart';
import 'package:abherbs_flutter/data/guide_results.dart';
import 'package:abherbs_flutter/search/guide_search.dart';
import 'package:abherbs_flutter/seen/guide_seen.dart';
import 'package:abherbs_flutter/seen/guide_stats.dart';
import 'package:abherbs_flutter/species/guide_species.dart';
import 'package:abherbs_flutter/offline/offline.dart';
import 'package:abherbs_flutter/person/authentication.dart';
import 'package:abherbs_flutter/data/prefs.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
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

  /// True when the list has a campaign `sourceUrl`.
  final bool hasSource;

  /// Extra classifier, such as a country epithet. Year values count too.
  final String parameter;

  /// True when plant values are state names rather than years.
  final bool labeled;

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
    this.hasSource = false,
    this.parameter = '',
    this.labeled = false,
  });
}

class GuideFind {
  final String name;
  final String? label;
  final DateTime when;
  final String? photoPath;

  /// False while a photo name is still waiting on Seen. A missing flag on
  /// an older row counts as confirmed.
  final bool confirmed;

  GuideFind({
    required this.name,
    required this.label,
    required this.when,
    required this.photoPath,
    this.confirmed = true,
  });
}

const guideHabitatRouteName = 'GuideHabitat';
const guidePetalRouteName = 'GuidePetal';
const guideResultsRouteName = 'GuideResults';
const guideListRouteName = 'GuideList';
const guideSpeciesRouteName = 'GuideSpecies';
const guidePersonRouteName = 'GuidePerson';
const guideLanguageRouteName = 'GuideLanguage';
const guideFieldGuideRouteName = 'GuideFieldGuide';
const guideOfflineRouteName = 'GuideOffline';
const guideStatsRouteName = 'GuideStats';
const guideSearchRouteName = 'GuideSearch';
const guideCameraRouteName = 'GuideCamera';
const guideOutsideRouteName = 'GuideOutside';
const guideCustomRouteName = 'GuideCustom';

/// How a custom list opens. Year values use the timeline. State names use
/// that same list, labeled and ordered by state. New in the book groups
/// recent additions by date. Everything else uses the result grid.
enum GuideCustomLayout { fresh, grid, years }

GuideCustomLayout guideCustomLayout(GuideListCover cover) {
  if (cover.isNew) return GuideCustomLayout.fresh;
  if (cover.year != null || cover.labeled) return GuideCustomLayout.years;
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
  /// The shell tab under any pushed page. The landscape rail reads it.
  static int index = 0;
  static void Function(int index)? show;
  static VoidCallback? showSeen;
  static VoidCallback? refreshSeen;

  /// Opens Person. The shell sets this; a rail on a pushed page calls it.
  static void Function(BuildContext context)? openPerson;

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

/// Opens a shell tab and drops every page pushed over it.
void guideRailSelect(BuildContext context, int index) {
  GuideTabs.show?.call(index);
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// Person in the landscape rail. A page already on Person stays there.
void guideRailPerson(BuildContext context) {
  final navigator = Navigator.of(context);
  if (ModalRoute.of(context)?.settings.name == guidePersonRouteName) return;
  var found = false;
  navigator.popUntil((route) {
    if (route.settings.name == guidePersonRouteName) found = true;
    return route.isFirst || found;
  });
  if (!found) GuideTabs.openPerson?.call(navigator.context);
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

/// Header for one catalog id. [Query.get] so a plant added after
/// `plants_headers_v3` was cached on disk is not read back as missing.
Future<GuideResultPlant?> _guideResultPlant(String id, String language) async {
  try {
    final snapshot = await headersV3Reference.child(id).get();
    final value = snapshot.value;
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
    final snapshot = await listsReference.child(id).get();
    final value = snapshot.value;
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

Map<String, GuideHeaderBloom>? _headerBlooms;

/// In flower this month, and seen, for each genus. Flowering months are cached.
/// Seen is read again on every call.
Future<Map<String, GuideGenusNote>> loadGuideGenusNotes(
  List<GuideSearchTaxon> genera, {
  int? month,
}) async {
  if (genera.isEmpty) return {};
  final blooms = _headerBlooms ?? await _loadHeaderBlooms();
  final seen = await loadGuideSeenNames();
  final now = month ?? DateTime.now().month;
  return {
    for (final genus in genera)
      genus.latinName: countGuideGenusNote(
        plantIds: genus.plantIds,
        blooms: blooms,
        seen: seen,
        month: now,
      ),
  };
}

Future<Map<String, GuideHeaderBloom>> _loadHeaderBlooms() async {
  final event = await headersV3Reference.once();
  final blooms = readGuideHeaderBlooms(event.snapshot.value);
  _headerBlooms = blooms;
  return blooms;
}

Future<Set<String>> loadGuideSeenNames() async {
  final user = guideNotebookUser();
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
    final body = readGuideList(
      raw[firebaseAttributeList],
      genera: raw[firebaseAttributeGenera],
    );
    if (body.count == 0) return;
    pending.add(_PendingCover(
      coverId: body.coverId,
      coverGenus: body.coverGenus,
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
        hasSource: _listHasSource(raw),
        parameter: _listParameter(raw),
        labeled: body.labeled,
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
  final genusPhotos = await _genusCoverPhotos(pending, chosen.code);
  final covers = pending.map((item) {
    final cover = item.cover;
    final photo = item.coverId != null
        ? photos[item.coverId]
        : genusPhotos[item.coverGenus];
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
      hasSource: cover.hasSource,
      parameter: cover.parameter,
      labeled: cover.labeled,
    );
  }).toList();

  covers.sort(compareGuideLists);
  return covers;
}

class _PendingCover {
  final String? coverId;
  final String? coverGenus;
  final List<String> thumbIds;
  final GuideListCover cover;

  _PendingCover({
    required this.coverId,
    required this.thumbIds,
    required this.cover,
    this.coverGenus,
  });
}

/// One catalog species stands for a genus on a list card or a genus row.
///
/// The picture is that species’ photo or plate. A genus with no catalog
/// species, such as Yucca, has no picture.
const Map<String, String> _genusSampleIds = {
  'Crataegus': '145',
  'Iris': '757',
  'Lupinus': '643',
  'Magnolia': '664',
  'Malus': '339',
  'Paeonia': '810',
  'Rosa': '996',
  'Viola': '1090',
};

@visibleForTesting
String? guideGenusSampleId(String genus, List<String> plantIds) {
  final wanted = _genusSampleIds[genus];
  if (wanted != null && (plantIds.isEmpty || plantIds.contains(wanted))) {
    return wanted;
  }
  if (plantIds.isNotEmpty) return plantIds.first;
  return null;
}

/// Species photo for a genus cover. A genus the book does not list has none.
Future<Map<String, String>> _genusCoverPhotos(
  List<_PendingCover> pending,
  String languageCode,
) async {
  final wanted = {
    for (final item in pending)
      if (item.coverGenus != null) item.coverGenus!,
  };
  if (wanted.isEmpty) return const {};
  final idsByGenus = <String, List<String>>{};
  try {
    final book = await loadGuideBookTaxa(languageCode);
    for (final taxon in book.genera) {
      if (wanted.contains(taxon.latinName)) {
        idsByGenus[taxon.latinName] = taxon.plantIds;
      }
    }
  } catch (error) {
    debugPrint('guide genus cover: $error');
  }
  final photos = <String, String>{};
  await Future.wait(wanted.map((genus) async {
    final id = guideGenusSampleId(genus, idsByGenus[genus] ?? const []);
    if (id == null) return;
    final plant = await _guideResultPlant(id, languageCode) ??
        await _guideHeaderPlant(id, languageCode);
    final path = plant?.photoPath ?? plant?.platePath;
    if (path != null && path.isNotEmpty) photos[genus] = path;
  }));
  return photos;
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

/// The notebook account, creating the anonymous guest when this install
/// does not have one yet. Signing out does not create another guest.
Future<User?> guideNotebookUserReady() async {
  final current = guideNotebookUser();
  if (current != null) return current;
  await Auth.startGuest();
  return guideNotebookUser();
}

/// Newest private finds for the Seen lately strip.
///
/// `order` is a negative timestamp, so an ascending `orderByChild` lists
/// newest first. [limit] has to read the start of that index.
Future<List<GuideFind>> loadRecentFinds(String languageCode,
    {int limit = 5}) async {
  final user = guideNotebookUser();
  if (user == null) return [];
  final event = await privateObservationsReference
      .child(user.uid)
      .child(firebaseObservationsByDate)
      .child(firebaseAttributeList)
      .orderByChild(firebaseAttributeOrder)
      .limitToFirst(limit)
      .once();
  final value = event.snapshot.value;
  if (value is! Map) return [];

  final rawFinds = <_RawFind>[];
  value.forEach((key, raw) {
    if (raw is! Map) return;
    final name = raw[observationPlant];
    if (name is! String || name.isEmpty) return;
    rawFinds.add(_RawFind(
      name,
      guideFindWhen(raw),
      _ownPhoto(raw),
      confirmed: guideFindConfirmed(raw),
    ));
  });
  rawFinds.sort((a, b) => b.when.compareTo(a.when));

  final lang = getLanguageCode(languageCode);
  return Future.wait(rawFinds.map((raw) => _decorateFind(raw, lang)));
}

/// Every private find for the Seen notebook, newest first.
///
/// Reads with [Query.get] so disk persistence cannot keep a row on
/// "In review" after the server status is `public`. [Query.once] completes
/// from the on-disk copy and then stops listening.
Future<List<GuideSeenFind>> loadGuideSeen(String languageCode) async {
  final user = guideNotebookUser();
  if (user == null) return [];
  final snapshot = await privateObservationsReference
      .child(user.uid)
      .child(firebaseObservationsByDate)
      .child(firebaseAttributeList)
      .get();
  final value = snapshot.value;
  if (value is! Map) return [];
  final rows = <GuideSeenFind>[];
  final clouds = <String, bool>{};
  value.forEach((key, raw) {
    final row = readGuideSeenRow(key, raw);
    if (row == null) return;
    rows.add(row);
    clouds[row.id] = raw is Map && raw[observationPhotoCloud] == true;
  });
  final lang = getLanguageCode(languageCode);
  final faces = <String, _SeenFace>{};
  final attached = <String, bool>{};
  await Future.wait([
    ...rows.map((row) => row.name).toSet().map((name) async {
      final needsPhoto = rows.any((row) => row.name == name && !row.ownPhoto);
      faces[name] = await _seenFace(name, lang, needsPhoto: needsPhoto);
    }),
    ...rows.map((row) async {
      attached[row.id] = await _photoAttached(
        row,
        cloud: clouds[row.id] ?? false,
      );
    }),
  ]);
  final decorated = [
    for (final row in rows)
      row.withCatalog(
        label: faces[row.name]?.label,
        catalogPhoto: faces[row.name]?.photo,
        inBook: faces[row.name]?.inBook ?? false,
        photoAttached: attached[row.id] ?? false,
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

/// Public Sightings: the stored aggregate, and years from the outdoor list.
///
/// The stats node is the headline. When it is missing, the same outdoor rows
/// supply the counts. Indoor rows are left out of the year chart either way.
Future<GuideSightingsLoad> loadGuideSightings() async {
  final stats = publicObservationsReference.child(firebaseObservationsStats).get();
  final list = publicObservationsReference
      .child(firebaseObservationsByDate)
      .child(firebaseAttributeList)
      .get();
  final statsSnap = await stats;
  final listSnap = await list;
  final stored = guideSightingHeadline(statsSnap.value);
  return GuideSightingsLoad(
    headline: stored ?? guideSightingHeadlineFromRows(listSnap.value),
    years: guideSightingYears(listSnap.value),
  );
}

/// Vernacular, catalog photo, and whether the species is in the book.
Future<GuideStatFace> loadGuidePlantCard(
  String name,
  String languageCode,
) async {
  final lang = getLanguageCode(languageCode);
  final face = await _seenFace(name, lang, needsPhoto: true);
  return GuideStatFace(
    label: face.label,
    photoPath: face.photo,
    inBook: face.inBook,
  );
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

bool _listHasSource(Map raw) {
  final source = raw[firebaseAttributeSourceUrl];
  return source is String && source.trim().isNotEmpty;
}

String _listParameter(Map raw) {
  final value = raw['parameter'];
  if (value is! String) return '';
  return value.trim();
}

/// New in the book, then sourced lists, then lists with a year or another
/// parameter, then the title. A parameter sorts ahead of the title inside
/// its group, so two country lists follow the parameter.
@visibleForTesting
int guideListRank(GuideListCover cover) {
  if (cover.isNew) return 0;
  if (cover.hasSource) return 1;
  if (cover.year != null || cover.parameter.isNotEmpty) return 2;
  return 3;
}

String _guideListSortKey(GuideListCover cover) {
  if (cover.parameter.isNotEmpty) return cover.parameter.toLowerCase();
  return cover.title.toLowerCase();
}

@visibleForTesting
int compareGuideLists(GuideListCover a, GuideListCover b) {
  final byRank = guideListRank(a).compareTo(guideListRank(b));
  if (byRank != 0) return byRank;
  final byKey = _guideListSortKey(a).compareTo(_guideListSortKey(b));
  if (byKey != 0) return byKey;
  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

@visibleForTesting
class GuideListBody {
  final int count;
  final String? coverId;
  final int? year;
  final int? yearFrom;
  final List<String> thumbIds;
  final bool labeled;

  /// Set when the alphabetically first state, or the newest year, is a genus.
  final String? coverGenus;

  GuideListBody(
    this.count,
    this.coverId,
    this.year, {
    this.yearFrom,
    this.thumbIds = const [],
    this.labeled = false,
    this.coverGenus,
  });
}

/// One genus designation. [state] and [year] are both null for membership.
class GuideGenusMark {
  final String genus;
  final String? state;
  final int? year;

  const GuideGenusMark(this.genus, {this.state, this.year});
}

/// A genus name. Numeric keys stay out so they can never be plant ids.
bool guideGenusKey(String key) {
  final text = key.trim();
  if (text.isEmpty) return false;
  if (int.tryParse(text) != null) return false;
  return RegExp(r'[A-Za-z]').hasMatch(text);
}

/// Genus designations beside `list`. Same values as a plant: one state, a
/// map of states, a year, or membership.
@visibleForTesting
List<GuideGenusMark> readGuideGenusMarks(dynamic genera) {
  if (genera is! Map) return const [];
  final pending = <MapEntry<String, dynamic>>[];
  genera.forEach((key, value) {
    if (value == null || value == false) return;
    if (value is String && value.trim().isEmpty) return;
    if (value is Map && value.isEmpty) return;
    final name = key.toString().trim();
    if (!guideGenusKey(name)) return;
    pending.add(MapEntry(name, value));
  });
  pending.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
  final marks = <GuideGenusMark>[];
  for (final entry in pending) {
    final states = customListStates(entry.value);
    if (states.isNotEmpty) {
      for (final state in states) {
        marks.add(GuideGenusMark(entry.key, state: state));
      }
      continue;
    }
    final year = customListYear(entry.value);
    if (year != null) {
      marks.add(GuideGenusMark(entry.key, year: year));
      continue;
    }
    marks.add(GuideGenusMark(entry.key));
  }
  return marks;
}

@visibleForTesting
GuideListBody readGuideList(dynamic list, {dynamic genera}) {
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

  final order = <String, int>{
    for (var i = 0; i < entries.length; i++) entries[i].key: i,
  };
  final marks = <MapEntry<String, String>>[];
  for (final entry in entries) {
    for (final state in customListStates(entry.value)) {
      marks.add(MapEntry(entry.key, state));
    }
  }
  final genusMarks = readGuideGenusMarks(genera);
  final genusStates = [
    for (final mark in genusMarks)
      if (mark.state != null) mark,
  ];
  // A membership list stays a grid. Genus states must not hide those plants.
  final stateList = marks.isNotEmpty || (genusStates.isNotEmpty && entries.isEmpty);
  if (stateList) {
    final ranked = <_RankedState>[];
    for (final mark in marks) {
      ranked.add(_RankedState(
        id: mark.key,
        state: mark.value,
        order: order[mark.key] ?? 0,
      ));
    }
    for (var i = 0; i < genusStates.length; i++) {
      final mark = genusStates[i];
      ranked.add(_RankedState(
        genus: mark.genus,
        state: mark.state!,
        order: marks.length + i,
      ));
    }
    ranked.sort((a, b) {
      final byState = a.state.toLowerCase().compareTo(b.state.toLowerCase());
      if (byState != 0) return byState;
      final aGenus = a.genus != null;
      final bGenus = b.genus != null;
      if (aGenus != bGenus) return aGenus ? 1 : -1;
      return a.order.compareTo(b.order);
    });
    final seen = <String>{};
    final thumbs = <String>[];
    for (final mark in ranked) {
      final id = mark.id;
      if (id == null || !seen.add(id)) continue;
      thumbs.add(id);
      if (thumbs.length == 4) break;
    }
    final first = ranked.first;
    return GuideListBody(
      marks.length + genusMarks.length,
      first.id,
      null,
      thumbIds: thumbs,
      labeled: true,
      coverGenus: first.genus,
    );
  }

  String? coverId;
  String? coverGenus;
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
      coverGenus = null;
    }
    if (oldestYear == null || year < oldestYear) oldestYear = year;
  }
  for (final mark in genusMarks) {
    final year = mark.year;
    if (year == null) continue;
    if (latestYear == null || year > latestYear) {
      latestYear = year;
      coverId = null;
      coverGenus = mark.genus;
    }
    if (oldestYear == null || year < oldestYear) oldestYear = year;
  }
  dated.sort((a, b) {
    final byYear = b.value.compareTo(a.value);
    if (byYear != 0) return byYear;
    return order[a.key]!.compareTo(order[b.key]!);
  });
  final source = dated.isEmpty
      ? entries.map((entry) => entry.key)
      : dated.map((entry) => entry.key);
  return GuideListBody(
    entries.length + genusMarks.length,
    coverId,
    latestYear,
    yearFrom: oldestYear,
    thumbIds: source.take(4).toList(),
    coverGenus: coverGenus,
  );
}

class _RankedState {
  final String? id;
  final String? genus;
  final String state;
  final int order;

  _RankedState({
    required this.state,
    required this.order,
    this.id,
    this.genus,
  });
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
///
/// A genus row leaves [plant] null. [genusPath] is empty when the book walk
/// has no species in that genus, and the row does not open.
class GuideYearEntry {
  final int? year;
  final GuideResultPlant? plant;

  /// Set when the list value is a state name. The row shows this instead of [year].
  final String? mark;
  final String? genus;
  final String? genusFamily;
  final String? genusPath;

  /// Photo and plate of the one species that stands for this genus.
  final String? genusPhotoPath;
  final String? genusPlatePath;

  const GuideYearEntry({
    this.year,
    this.plant,
    this.mark,
    this.genus,
    this.genusFamily,
    this.genusPath,
    this.genusPhotoPath,
    this.genusPlatePath,
  });
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

class GuideStateId {
  final String id;
  final String state;

  const GuideStateId(this.id, this.state);
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

/// One timeline row before the plant or the genus plate is loaded.
class GuideTimelineRow {
  final String? id;
  final String? genus;
  final String? state;
  final int? year;

  const GuideTimelineRow({this.id, this.genus, this.state, this.year});
}

class _TimelineRank {
  final GuideTimelineRow row;
  final int index;
  final bool genus;

  const _TimelineRank(this.row, this.index, {this.genus = false});
}

/// State rows, then year rows, then membership genera. A year list keeps
/// its species order and folds genus years into it. Membership species are
/// not rows here: those stay on the result grid.
@visibleForTesting
List<GuideTimelineRow> readGuideTimeline(dynamic list, [dynamic genera]) {
  final speciesYears = readGuideYearIds(list);
  final speciesStates = speciesYears.isEmpty
      ? readGuideStateIds(list)
      : const <GuideStateId>[];
  final genusMarks = readGuideGenusMarks(genera);
  final stateMode = speciesStates.isNotEmpty ||
      (speciesYears.isEmpty && genusMarks.any((mark) => mark.state != null));
  if (stateMode) {
    final ranked = <_TimelineRank>[];
    for (var i = 0; i < speciesStates.length; i++) {
      final row = speciesStates[i];
      ranked.add(_TimelineRank(
        GuideTimelineRow(id: row.id, state: row.state),
        i,
      ));
    }
    var genusIndex = speciesStates.length;
    for (final mark in genusMarks) {
      final state = mark.state;
      if (state == null) continue;
      ranked.add(_TimelineRank(
        GuideTimelineRow(genus: mark.genus, state: state),
        genusIndex++,
      ));
    }
    ranked.sort((a, b) {
      final byState = a.row.state!.toLowerCase().compareTo(b.row.state!.toLowerCase());
      if (byState != 0) return byState;
      return a.index.compareTo(b.index);
    });
    return [
      for (final rank in ranked) rank.row,
      ..._genusTimelineTail(genusMarks, includeYears: true),
    ];
  }
  final ranked = <_TimelineRank>[];
  for (var i = 0; i < speciesYears.length; i++) {
    final row = speciesYears[i];
    ranked.add(_TimelineRank(
      GuideTimelineRow(id: row.id, year: row.year),
      i,
    ));
  }
  var genusIndex = speciesYears.length;
  for (final mark in genusMarks) {
    final year = mark.year;
    if (year == null) continue;
    ranked.add(_TimelineRank(
      GuideTimelineRow(genus: mark.genus, year: year),
      genusIndex++,
      genus: true,
    ));
  }
  ranked.sort((a, b) {
    final byYear = b.row.year!.compareTo(a.row.year!);
    if (byYear != 0) return byYear;
    if (a.genus != b.genus) return a.genus ? 1 : -1;
    return a.index.compareTo(b.index);
  });
  final states = [
    for (final mark in genusMarks)
      if (mark.state != null) mark,
  ]..sort((a, b) {
      final byState = a.state!.toLowerCase().compareTo(b.state!.toLowerCase());
      if (byState != 0) return byState;
      return a.genus.toLowerCase().compareTo(b.genus.toLowerCase());
    });
  return [
    for (final rank in ranked) rank.row,
    for (final mark in states)
      GuideTimelineRow(genus: mark.genus, state: mark.state),
    ..._genusTimelineTail(genusMarks, includeYears: false),
  ];
}

List<GuideTimelineRow> _genusTimelineTail(
  List<GuideGenusMark> marks, {
  required bool includeYears,
}) {
  final tail = <GuideTimelineRow>[];
  if (includeYears) {
    final dated = [
      for (final mark in marks)
        if (mark.year != null) mark,
    ]..sort((a, b) {
        final byYear = b.year!.compareTo(a.year!);
        if (byYear != 0) return byYear;
        return a.genus.toLowerCase().compareTo(b.genus.toLowerCase());
      });
    for (final mark in dated) {
      tail.add(GuideTimelineRow(genus: mark.genus, year: mark.year));
    }
  }
  final plain = [
    for (final mark in marks)
      if (mark.state == null && mark.year == null) mark,
  ]..sort((a, b) => a.genus.toLowerCase().compareTo(b.genus.toLowerCase()));
  for (final mark in plain) {
    tail.add(GuideTimelineRow(genus: mark.genus));
  }
  return tail;
}

/// State names on a list, alphabetical. One species can name more than one state.
@visibleForTesting
List<GuideStateId> readGuideStateIds(dynamic list) {
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
  final order = {for (var i = 0; i < entries.length; i++) entries[i].key: i};
  final marked = <GuideStateId>[];
  for (final entry in entries) {
    for (final state in customListStates(entry.value)) {
      marked.add(GuideStateId(entry.key, state));
    }
  }
  marked.sort((a, b) {
    final byState = a.state.toLowerCase().compareTo(b.state.toLowerCase());
    if (byState != 0) return byState;
    return order[a.id]!.compareTo(order[b.id]!);
  });
  return marked;
}

/// Host shown next to a year list, without the scheme.
String guideSourceHost(String url) {
  final uri = Uri.tryParse(url.trim());
  var host = (uri == null || uri.host.isEmpty) ? url.trim() : uri.host;
  if (host.startsWith('www.')) host = host.substring(4);
  return host;
}

Future<_Newest?> _newestAddition() async {
  final drops = await _selectedNewDrops();
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

/// Newest days of `lists_custom/new` inside the 15 to 25 plant window.
///
/// [Query.get] reads the server while online. [Query.once] finishes from
/// the on-disk copy and then stops, so a plant published after the last
/// open of this list never appears. Disk persistence is on in `main`.
Future<List<GuideNewDrop>> _selectedNewDrops() async {
  final snapshot = await listsCustomReference
      .child('new')
      .orderByKey()
      .limitToLast(guideNewPlantMax)
      .get();
  return selectGuideNewDrops(readGuideNewDrops(snapshot.value));
}

Future<List<GuideNewDay>> loadGuideNewDays(String languageCode) async {
  final drops = await _selectedNewDrops();
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
  String? sourceUrl;
  dynamic genera;
  final parent = path.parent;
  if (parent != null) {
    try {
      final source = await parent.child(firebaseAttributeSourceUrl).once();
      final value = source.snapshot.value;
      if (value is String && value.isNotEmpty) sourceUrl = value;
    } catch (error) {
      debugPrint('guide year source: $error');
    }
    try {
      // get() reads the server. once() can stop at the on-disk copy, which
      // hides a genera node published after the last open of this list.
      final snapshot = await parent.child(firebaseAttributeGenera).get();
      genera = snapshot.value;
    } catch (error) {
      debugPrint('guide genera: $error');
    }
  }
  final rows = readGuideTimeline(event.snapshot.value, genera);
  if (rows.isEmpty) {
    return GuideYearList(entries: const [], sourceUrl: sourceUrl);
  }
  final lang = getLanguageCode(languageCode);
  final generaByName = <String, GuideSearchTaxon>{};
  if (rows.any((row) => row.genus != null)) {
    try {
      final book = await loadGuideBookTaxa(lang);
      for (final taxon in book.genera) {
        generaByName[taxon.latinName] = taxon;
      }
    } catch (error) {
      debugPrint('guide genus rows: $error');
    }
  }
  final sampleLoads = <String, Future<GuideResultPlant?>>{};
  final entries = await Future.wait(rows.map((row) async {
    final genus = row.genus;
    if (genus != null) {
      final taxon = generaByName[genus];
      final sampleId = guideGenusSampleId(genus, taxon?.plantIds ?? const []);
      GuideResultPlant? sample;
      if (sampleId != null) {
        sample = await sampleLoads.putIfAbsent(sampleId, () async {
          return await _guideResultPlant(sampleId, lang) ??
              await _guideHeaderPlant(sampleId, lang);
        });
      }
      return GuideYearEntry(
        year: row.year,
        mark: row.state,
        genus: genus,
        genusFamily: taxon?.illustrationFamily ?? '',
        genusPath: taxon?.listPath ?? '',
        genusPhotoPath: sample?.photoPath,
        genusPlatePath: sample?.platePath,
      );
    }
    final id = row.id;
    if (id == null) return null;
    final plant = await _guideResultPlant(id, lang) ??
        await _guideHeaderPlant(id, lang);
    if (plant == null) return null;
    return GuideYearEntry(
      year: row.year ?? 0,
      mark: row.state,
      plant: plant,
    );
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

/// Lists for this language only. A missing node is an empty set.
/// English lists are not a substitute.
Future<_LanguageLists> _languageLists(String languageCode) async {
  final code = getLanguageCode(languageCode);
  // get() reads the server while online. once() can finish from the on-disk
  // copy, which hides a genera child published after the last open.
  final snapshot =
      await listsCustomReference.child('by language').child(code).get();
  final value = snapshot.value;
  if (value is Map) return _LanguageLists(code, value);
  return _LanguageLists(code, {});
}

Future<Map<String, String>> _headerPhotos(Set<String> ids) async {
  final photos = <String, String>{};
  await Future.wait(ids.map((id) async {
    try {
      final snapshot =
          await listsReference.child(id).child(firebaseAttributeUrl).get();
      final url = snapshot.value;
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
  final bool confirmed;

  _RawFind(this.name, this.when, this.photoPath, {this.confirmed = true});
}

/// Missing [observationConfirmed] counts as confirmed, matching older rows
/// in the Seen notebook.
@visibleForTesting
bool guideFindConfirmed(Map raw) {
  final value = raw[observationConfirmed];
  return value is bool ? value : true;
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
    confirmed: raw.confirmed,
  );
}

String? _ownPhoto(Map raw) {
  return guideFirstText(raw[observationPhotoPaths]);
}

/// A stored path is not a photo on a new phone. The file has to be here,
/// already in private Storage, or already published.
Future<bool> _photoAttached(GuideSeenFind row, {required bool cloud}) async {
  if (!row.ownPhoto) return false;
  final path = row.photoPath;
  if (path == null || path.isEmpty) return false;
  final local = await Offline.getLocalFile(path) != null;
  if (local || cloud) {
    return guideSeenPhotoAttached(local: local, cloud: cloud, published: false);
  }
  return guideSeenPhotoAttached(
    local: false,
    cloud: false,
    published: await _publishedObservationPhoto(path),
  );
}

final Map<String, bool> _publishedPhoto = {};

Future<bool> _publishedObservationPhoto(String path) async {
  if (!path.startsWith(storageObservations)) return false;
  final known = _publishedPhoto[path];
  if (known != null) return known;
  try {
    await firebase_storage.FirebaseStorage.instanceFor(bucket: storageBucket)
        .ref()
        .child(path)
        .getMetadata();
    return _publishedPhoto[path] = true;
  } on firebase_storage.FirebaseException catch (error) {
    if (error.code == 'object-not-found') {
      return _publishedPhoto[path] = false;
    }
    debugPrint('guide seen photo $path: $error');
    return false;
  } catch (error) {
    debugPrint('guide seen photo $path: $error');
    return false;
  }
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
  final latins = guideSpeciesTaxonLatins(plant['APGIV']);
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
  final user = await guideNotebookUserReady();
  if (user == null) {
    throw StateError('sign in to save a find');
  }
  final photoPath = draft.photoPath;
  if (photoPath == null || photoPath.isEmpty) {
    throw StateError('a find needs a photo from this device');
  }
  final millis = DateTime.now().millisecondsSinceEpoch;
  final observation = Observation(draft.plant);
  observation.id = '${user.uid}_$millis';
  observation.date = draft.when;
  observation.latitude = draft.latitude;
  observation.longitude = draft.longitude;
  observation.note = '';
  observation.photoPaths = [photoPath];
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
  unawaited(syncGuidePrivatePhotos(onlyId: observation.id));
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
    final snapshot = await publicObservationsReference
        .child(firebaseObservationsByPlant)
        .child(name)
        .child(firebaseAttributeList)
        .get();
    return guideSightings(snapshot.value);
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
