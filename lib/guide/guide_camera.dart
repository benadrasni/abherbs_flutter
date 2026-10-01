import 'dart:io';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_person.dart';
import 'package:abherbs_flutter/guide/guide_results.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum GuideCameraSource { camera, gallery }

enum GuideCameraPlace { ask, allowed, declined }

/// Asked once. A refusal or an earlier allow, including the region chip,
/// hides the question.
GuideCameraPlace guideCameraPlace({
  required bool locationRefused,
  required bool fromLocation,
  required bool locationAllowed,
}) {
  if (locationRefused) return GuideCameraPlace.declined;
  if (fromLocation || locationAllowed) return GuideCameraPlace.allowed;
  return GuideCameraPlace.ask;
}

Future<GuideCameraPlace> loadGuideCameraPlace() async {
  final prefs = await loadGuideResultPrefs();
  final allowed = await Prefs.getBoolF(keyGuideLocationAllowed, false);
  return guideCameraPlace(
    locationRefused: prefs.locationRefused,
    fromLocation: prefs.fromLocation,
    locationAllowed: allowed,
  );
}

Future<GuideCameraPlace> allowGuideCameraLocation({
  required Future<String?> Function() locate,
  required Future<GuideResultPrefs> Function() loadPrefs,
  required Future<void> Function(GuideResultPrefs prefs) savePrefs,
  required Future<void> Function(bool allowed) saveAllowed,
}) async {
  try {
    final regionId = await locate();
    final prefs = await loadPrefs();
    if (regionId != null && regionId.isNotEmpty) {
      await savePrefs(prefs.copyWith(
        regionId: regionId,
        fromLocation: true,
        locationRefused: false,
      ));
    } else {
      await savePrefs(prefs.copyWith(locationRefused: false));
    }
    await saveAllowed(true);
    return GuideCameraPlace.allowed;
  } on GuideLocationRefused {
    final prefs = await loadPrefs();
    await savePrefs(prefs.copyWith(locationRefused: true));
    await saveAllowed(false);
    return GuideCameraPlace.declined;
  }
}

Future<GuideCameraPlace> declineGuideCameraLocation({
  required Future<GuideResultPrefs> Function() loadPrefs,
  required Future<void> Function(GuideResultPrefs prefs) savePrefs,
  required Future<void> Function(bool allowed) saveAllowed,
}) async {
  final prefs = await loadPrefs();
  await savePrefs(prefs.copyWith(locationRefused: true));
  await saveAllowed(false);
  return GuideCameraPlace.declined;
}

enum GuideCameraMeterKind { fieldGuide, unlimited, signIn, namesLeft }

class GuideCameraMeter {
  final int dotCount;
  final int filledDots;
  final GuideCameraMeterKind kind;
  final int namesLeft;

  const GuideCameraMeter({
    required this.dotCount,
    required this.filledDots,
    required this.kind,
    this.namesLeft = 0,
  });
}

GuideCameraMeter guideCameraMeter(GuideAllowance allowance) {
  switch (allowance.kind) {
    case GuideAllowanceKind.unlimited:
      return GuideCameraMeter(
        dotCount: 0,
        filledDots: 0,
        kind: allowance.fieldGuide
            ? GuideCameraMeterKind.fieldGuide
            : GuideCameraMeterKind.unlimited,
      );
    case GuideAllowanceKind.guest:
      if (allowance.namesLeft > 0) {
        return GuideCameraMeter(
          dotCount: 1,
          filledDots: 1,
          kind: GuideCameraMeterKind.namesLeft,
          namesLeft: allowance.namesLeft,
        );
      }
      return const GuideCameraMeter(
        dotCount: 0,
        filledDots: 0,
        kind: GuideCameraMeterKind.signIn,
      );
    case GuideAllowanceKind.credits:
      final left = allowance.namesLeft;
      return GuideCameraMeter(
        dotCount: 5,
        filledDots: left > 5 ? 5 : left,
        kind: GuideCameraMeterKind.namesLeft,
        namesLeft: left,
      );
    case GuideAllowanceKind.month:
      final left = 5 - allowance.includedUsed;
      return GuideCameraMeter(
        dotCount: 5,
        filledDots: left,
        kind: GuideCameraMeterKind.namesLeft,
        namesLeft: left,
      );
  }
}

bool guideCameraCanCapture(GuideAllowance allowance) {
  switch (allowance.kind) {
    case GuideAllowanceKind.unlimited:
      return true;
    case GuideAllowanceKind.guest:
    case GuideAllowanceKind.credits:
      return allowance.namesLeft > 0;
    case GuideAllowanceKind.month:
      return allowance.includedUsed < 5;
  }
}

/// A rewarded ad is offered when the included names are gone and the month
/// still has room for one. Credits offer an ad at zero.
bool guideCameraOffersAd(GuideAllowance allowance) {
  switch (allowance.kind) {
    case GuideAllowanceKind.credits:
      return allowance.namesLeft <= 0;
    case GuideAllowanceKind.month:
      return allowance.includedUsed >= 5 && allowance.extraUsed < 5;
    case GuideAllowanceKind.guest:
    case GuideAllowanceKind.unlimited:
      return false;
  }
}

bool guideCameraNamesExhausted(GuideAllowance allowance) {
  return allowance.kind == GuideAllowanceKind.month &&
      allowance.includedUsed >= 5 &&
      allowance.extraUsed >= 5;
}

GuideAllowance guideCameraLiveAllowance({bool guestFree = false}) {
  return guideLiveAllowance(
    signedIn: Auth.appUser != null,
    subscribed: Purchases.isSubscribed(),
    unlimitedNames: Purchases.isPhotoSearch(),
    noAds: Purchases.isNoAds(),
    seenSynced: Purchases.isSubscribed(),
    credits: Auth.credits,
    guestFree: guestFree,
    now: DateTime.now(),
  );
}

/// Whether the guest account still has its one free identification. The
/// `identifyPlant` function keeps that flag in `photo_quota/{uid}`; the
/// install also remembers it, since there is one guest account per install.
Future<bool> guideGuestHasFreeName() async {
  if (Auth.appUser != null) return false;
  if (Prefs.getBool(keyGuestFreeUsed, false)) return false;
  if (Auth.firebaseAuth.currentUser == null) await Auth.startGuest();
  final guest = Auth.guestUser;
  if (guest == null) return false;
  try {
    final event = await rootReference
        .child(firebasePhotoQuota)
        .child(guest.uid)
        .child(firebaseAttributeAnonymousFreeUsed)
        .get();
    return event.value != true;
  } catch (_) {
    return true;
  }
}

/// Plain words for a Plant.id probability.
enum GuideCameraConfidence { likely, possible, uncertain }

GuideCameraConfidence guideCameraConfidence(double? probability) {
  final value = probability ?? 0;
  if (value >= 0.5) return GuideCameraConfidence.likely;
  if (value >= 0.2) return GuideCameraConfidence.possible;
  return GuideCameraConfidence.uncertain;
}

class GuideCameraHit {
  final String latin;
  final String? vernacular;
  final double? probability;
  final String? path;
  final String? familyLatin;
  final String? familyLabel;
  final String? photoPath;

  const GuideCameraHit({
    required this.latin,
    this.vernacular,
    this.probability,
    this.path,
    this.familyLatin,
    this.familyLabel,
    this.photoPath,
  });
}

/// Plant.id `plant_details.taxonomy.family`, when the reply includes one.
String? guideCameraFamilyLatin(dynamic details) {
  if (details is! Map) return null;
  final taxonomy = details['taxonomy'];
  if (taxonomy is! Map) return null;
  final family = taxonomy['family'];
  if (family is! String) return null;
  final trimmed = family.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

/// Firebase path key for a Latin name. Spaces stay; the forbidden characters
/// do not.
String guideObservationPlantKey(String name) {
  final cleaned = name.trim().replaceAll(RegExp(r'[.#$\[\]/]'), '_');
  if (cleaned.isEmpty) return '_';
  return cleaned;
}

List<Map<String, dynamic>> guideCameraCandidateMaps(List<GuideCameraHit> hits) {
  return [
    for (final hit in hits)
      {
        'latin': hit.latin,
        if (hit.vernacular != null && hit.vernacular!.trim().isNotEmpty)
          'vernacular': hit.vernacular,
        if (hit.probability != null) 'probability': hit.probability,
        if (hit.path != null && hit.path!.isNotEmpty) 'path': hit.path,
      },
  ];
}

/// A photo name saved to Seen before the person keeps it.
class GuideCameraDraft {
  final String plant;
  final DateTime when;
  final String? shotPath;
  final List<Map<String, dynamic>> candidates;

  const GuideCameraDraft({
    required this.plant,
    required this.when,
    required this.candidates,
    this.shotPath,
  });
}

/// What the Outside the book page asks the camera to do next.
class GuideOutsideResult {
  final String? openSpecies;
  final bool seen;
  final bool find;
  final String? message;

  const GuideOutsideResult.seen(this.message)
      : openSpecies = null,
        seen = true,
        find = false;

  const GuideOutsideResult.find()
      : openSpecies = null,
        seen = false,
        find = true,
        message = null;

  const GuideOutsideResult.species(this.openSpecies, this.message)
      : seen = false,
        find = false;
}

/// The unconfirmed bar on a species page opened from the camera.
class GuideCameraPending {
  final String plant;
  final DateTime when;
  final String place;
  final String? photoPath;
  final String? observationId;
  final List<GuideCameraHit> others;

  const GuideCameraPending({
    required this.plant,
    required this.when,
    required this.place,
    this.photoPath,
    this.observationId,
    this.others = const [],
  });
}

/// The floristic region kept after the camera's one location question.
/// Anything else is [noPlace].
Future<String> guideCameraPlaceName({
  required Future<GuideResultPrefs> Function() loadPrefs,
  required Future<bool> Function() loadAllowed,
  required String Function(String id) regionName,
  required String noPlace,
}) async {
  final prefs = await loadPrefs();
  final allowed = await loadAllowed();
  if (!allowed && !prefs.fromLocation) return noPlace;
  final id = prefs.regionId;
  if (id == null || id.isEmpty) return noPlace;
  final name = regionName(id).trim();
  if (name.isEmpty) return noPlace;
  return name;
}

/// The last four are the server declining to call Plant.id: sign in, no names
/// left, a second photo too soon or the same photo again, and the silent daily
/// ceiling.
enum GuideCameraOutcomeKind {
  species,
  list,
  outside,
  notPlant,
  signIn,
  limit,
  tooSoon,
  samePhoto,
  pausedToday,
}

class GuideCameraOutcome {
  final GuideCameraOutcomeKind kind;
  final String? speciesName;
  final String? listPath;
  final GuideCameraHit? leading;
  final List<GuideCameraHit> candidates;

  /// A not-a-plant photo that still spent a name.
  final bool counted;

  /// Plant.id's probability for a catalog species, kept for the Seen card.
  final double? leadProbability;

  const GuideCameraOutcome.species(
    String name, {
    this.candidates = const [],
    this.leadProbability,
  })  : kind = GuideCameraOutcomeKind.species,
        speciesName = name,
        listPath = null,
        leading = null,
        counted = false;

  const GuideCameraOutcome.list(String path)
      : kind = GuideCameraOutcomeKind.list,
        speciesName = null,
        listPath = path,
        leading = null,
        candidates = const [],
        counted = false,
        leadProbability = null;

  const GuideCameraOutcome.outside(
    this.leading,
    this.candidates,
  )   : kind = GuideCameraOutcomeKind.outside,
        speciesName = null,
        listPath = null,
        counted = false,
        leadProbability = null;

  const GuideCameraOutcome.notPlant({this.counted = false})
      : kind = GuideCameraOutcomeKind.notPlant,
        speciesName = null,
        listPath = null,
        leading = null,
        candidates = const [],
        leadProbability = null;

  const GuideCameraOutcome.refused(this.kind)
      : speciesName = null,
        listPath = null,
        leading = null,
        candidates = const [],
        counted = false,
        leadProbability = null;
}

String? guideCameraSpeciesName(GuideCameraHit hit) {
  final path = hit.path;
  if (path == null || path.isEmpty || path.contains('/')) return null;
  return path;
}

String? guideCameraListPath(GuideCameraHit hit) {
  final path = hit.path;
  if (path == null || !path.contains('/')) return null;
  return path;
}

bool _named(GuideCameraHit hit) {
  if (hit.latin.trim().isNotEmpty) return true;
  final path = hit.path;
  return path != null && path.isNotEmpty;
}

/// A leading catalog species opens its page. A leading list opens that list.
/// Anything else opens Outside the book. Up to two catalog species from the
/// rest of the reply go with either result. The `identifyPlant` function
/// drops every suggestion for a photo that is not a plant.
GuideCameraOutcome guideCameraOutcome(
  List<GuideCameraHit> hits, {
  bool isPlant = true,
}) {
  if (!isPlant) return const GuideCameraOutcome.notPlant();
  final named = hits.where(_named).toList();
  if (named.isEmpty) return const GuideCameraOutcome.notPlant();
  final lead = named.first;
  final candidates = <GuideCameraHit>[];
  for (final hit in named.skip(1)) {
    if (guideCameraSpeciesName(hit) == null) continue;
    candidates.add(hit);
    if (candidates.length == 2) break;
  }
  final species = guideCameraSpeciesName(lead);
  if (species != null) {
    return GuideCameraOutcome.species(
      species,
      candidates: candidates,
      leadProbability: lead.probability,
    );
  }
  final list = guideCameraListPath(lead);
  if (list != null) return GuideCameraOutcome.list(list);
  return GuideCameraOutcome.outside(lead, candidates);
}

/// When this photo was taken, from its EXIF date. Null when the file has
/// no date, or the date cannot be read. A shutter photo does not use this.
Future<DateTime?> guideCameraPhotoTakenAt(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    final tags = await readExifFromBytes(await file.readAsBytes());
    final tag = tags['EXIF DateTimeOriginal'] ?? tags['Image DateTime'];
    if (tag == null) return null;
    return guideCameraExifDate(tag.toString());
  } catch (error) {
    debugPrint('guide camera photo date: $error');
    return null;
  }
}

/// `yyyy:MM:dd HH:mm:ss` as written in EXIF. The clock is the photo's own
/// local time. Null when the text is not that shape.
DateTime? guideCameraExifDate(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll('\u0000', '').trim();
  final parts = cleaned.split(' ');
  if (parts.length < 2) return null;
  final date = parts[0].split(':');
  final clock = parts[1].split(':');
  if (date.length < 3 || clock.length < 3) return null;
  final year = int.tryParse(date[0]);
  final month = int.tryParse(date[1]);
  final day = int.tryParse(date[2]);
  final hour = int.tryParse(clock[0].split('.').first);
  final minute = int.tryParse(clock[1].split('.').first);
  final second = int.tryParse(clock[2].split('.').first);
  if (year == null ||
      month == null ||
      day == null ||
      hour == null ||
      minute == null ||
      second == null) {
    return null;
  }
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (hour > 23 || minute > 59 || second > 59) return null;
  return DateTime(year, month, day, hour, minute, second);
}

/// Writes the camera's leading name to Seen, unconfirmed. Returns the
/// observation id, or null when there is no account or the write fails.
Future<String?> saveGuideCameraFind(GuideCameraDraft draft) async {
  try {
    final user = guideNotebookUser();
    if (user == null) return null;
    final relative =
        await _storeCameraShot(user.uid, draft.plant, draft.shotPath);
    final millis = DateTime.now().millisecondsSinceEpoch;
    final observation = Observation(draft.plant);
    observation.id = '${user.uid}_$millis';
    observation.date = draft.when;
    observation.note = '';
    observation.photoPaths = [
      if (relative != null) relative,
    ];
    observation.status = observationStatusPrivate;
    observation.order = -draft.when.millisecondsSinceEpoch;
    observation.confirmed = false;
    observation.source = observationSourceCamera;
    observation.candidates = draft.candidates;
    final json = observation.toJson();
    final root = privateObservationsReference.child(user.uid);
    final plantKey = guideObservationPlantKey(draft.plant);
    await root
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(observation.id)
        .set(json);
    await root
        .child(firebaseObservationsByPlant)
        .child(plantKey)
        .child(firebaseAttributeList)
        .child(observation.id)
        .set(json);
    return observation.id;
  } catch (error) {
    debugPrint('guide camera save: $error');
    return null;
  }
}

Future<void> setGuideCameraConfirmed({
  required String id,
  required String plant,
  required bool confirmed,
}) async {
  try {
    final user = guideNotebookUser();
    if (user == null || id.isEmpty) return;
    final patch = {observationConfirmed: confirmed};
    final root = privateObservationsReference.child(user.uid);
    await root
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(id)
        .update(patch);
    await root
        .child(firebaseObservationsByPlant)
        .child(guideObservationPlantKey(plant))
        .child(firebaseAttributeList)
        .child(id)
        .update(patch);
  } catch (error) {
    debugPrint('guide camera confirm: $error');
  }
}

Future<void> deleteGuideCameraFind({
  required String id,
  required String plant,
}) async {
  try {
    final user = guideNotebookUser();
    if (user == null || id.isEmpty) return;
    final root = privateObservationsReference.child(user.uid);
    final dateRef = root
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(id);
    final event = await dateRef.once();
    final raw = event.snapshot.value;
    if (raw is Map) await _deleteObservationPhotos(raw[observationPhotoPaths]);
    await dateRef.remove();
    await root
        .child(firebaseObservationsByPlant)
        .child(guideObservationPlantKey(plant))
        .child(firebaseAttributeList)
        .child(id)
        .remove();
  } catch (error) {
    debugPrint('guide camera delete: $error');
  }
}

/// Moves an unconfirmed camera find onto [to] and marks it confirmed.
Future<void> retargetGuideCameraFind({
  required String id,
  required String from,
  required String to,
}) async {
  try {
    final user = guideNotebookUser();
    if (user == null || id.isEmpty) return;
    final root = privateObservationsReference.child(user.uid);
    final dateRef = root
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(id);
    final event = await dateRef.once();
    final raw = event.snapshot.value;
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    data[observationPlant] = to;
    data[observationConfirmed] = true;
    await dateRef.set(data);
    await root
        .child(firebaseObservationsByPlant)
        .child(guideObservationPlantKey(from))
        .child(firebaseAttributeList)
        .child(id)
        .remove();
    await root
        .child(firebaseObservationsByPlant)
        .child(guideObservationPlantKey(to))
        .child(firebaseAttributeList)
        .child(id)
        .set(data);
  } catch (error) {
    debugPrint('guide camera retarget: $error');
  }
}

Future<String?> _storeCameraShot(
  String uid,
  String plant,
  String? shotPath,
) async {
  if (shotPath == null || shotPath.isEmpty) return null;
  final source = File(shotPath);
  if (!await source.exists()) return null;
  final names = plant.toLowerCase().split(' ');
  var prefix = 'unknown_';
  if (names.length > 1 && names[0].isNotEmpty && names[1].isNotEmpty) {
    prefix = '${names[0][0]}${names[1][0]}_';
  }
  final dot = shotPath.lastIndexOf('.');
  final slash = shotPath.lastIndexOf('/');
  final suffix = dot > slash ? shotPath.substring(dot) : '.jpg';
  final filename = '$prefix${DateTime.now().millisecondsSinceEpoch}$suffix';
  final dir = '$storageObservations$uid/${plant.replaceAll(' ', '_')}';
  final root = (await getApplicationDocumentsDirectory()).path;
  await Directory('$root/$dir').create(recursive: true);
  await source.copy('$root/$dir/$filename');
  return '$dir/$filename';
}

Future<void> _deleteObservationPhotos(dynamic raw) async {
  final root = (await getApplicationDocumentsDirectory()).path;
  final paths = <String>[];
  if (raw is List) {
    for (final item in raw) {
      if (item is String && item.isNotEmpty) paths.add(item);
    }
  } else if (raw is Map) {
    for (final item in raw.values) {
      if (item is String && item.isNotEmpty) paths.add(item);
    }
  }
  for (final path in paths) {
    final file = File('$root/$path');
    if (await file.exists()) await file.delete();
  }
}
