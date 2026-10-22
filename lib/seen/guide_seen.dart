import 'package:abherbs_flutter/seen/observation.dart';
import 'package:abherbs_flutter/data/utils.dart';

/// How a confirmed find sits with Sightings.
enum GuideSeenShare { none, review, shared, rejected }

/// The control at the end of a confirmed row.
enum GuideSeenChip { share, review, shared, rejected, outside }

/// One other name Plant.id offered for an unconfirmed photo.
class GuideSeenCandidate {
  final String latin;
  final String? vernacular;
  final double? probability;
  final String? path;

  const GuideSeenCandidate({
    required this.latin,
    this.vernacular,
    this.probability,
    this.path,
  });
}

/// One private find. [ownPhoto] is a photo the person took. [photoPath] may
/// fall back to the catalog photo when they did not.
class GuideSeenFind {
  final String id;
  final String name;
  final String? label;
  final DateTime when;
  final String? photoPath;

  /// Book photo. The row shows it when [photoPath] is not on this phone.
  final String? coverPath;
  final bool ownPhoto;
  final bool confirmed;
  final GuideSeenShare share;
  final bool inBook;
  final double? probability;
  final List<GuideSeenCandidate> others;
  final String? place;
  final double latitude;
  final double longitude;

  /// Indoor finds stay in Seen and are left out of statistics.
  final bool indoors;

  /// Lowercase ISO country code, when the row has one.
  final String? country;

  /// The person's photo can be published. A path stored on the row is not
  /// enough: a new phone keeps the path and loses a file that was never
  /// copied to Storage. Hand-built rows default to attached.
  final bool photoAttached;

  /// Vernacular, catalog photo, and [inBook] have been read. A fresh
  /// observation row is false, so the list can draw before those lookups.
  /// A failed lookup stays false so a later decorate pass can retry.
  /// Hand-built rows default to known.
  final bool catalogKnown;

  const GuideSeenFind({
    required this.id,
    required this.name,
    required this.when,
    this.label,
    this.photoPath,
    this.coverPath,
    this.ownPhoto = false,
    this.confirmed = true,
    this.share = GuideSeenShare.none,
    this.inBook = false,
    this.probability,
    this.others = const [],
    this.place,
    this.latitude = 0,
    this.longitude = 0,
    this.indoors = false,
    this.country,
    this.photoAttached = true,
    this.catalogKnown = true,
  });

  GuideSeenFind withCatalog({
    String? label,
    String? catalogPhoto,
    required bool inBook,
    bool? photoAttached,
  }) {
    return GuideSeenFind(
      id: id,
      name: name,
      label: label,
      when: when,
      photoPath: photoPath ?? catalogPhoto,
      coverPath: catalogPhoto ?? coverPath,
      ownPhoto: ownPhoto,
      confirmed: confirmed,
      share: share,
      inBook: inBook,
      probability: probability,
      others: others,
      place: place,
      latitude: latitude,
      longitude: longitude,
      indoors: indoors,
      country: country,
      photoAttached: photoAttached ?? this.photoAttached,
      catalogKnown: true,
    );
  }

  /// Same find, with a book photo for the thumbnail. Lookups stay as they are,
  /// so a vernacular that has not loaded yet is tried again.
  GuideSeenFind withCover(String coverPath) {
    return GuideSeenFind(
      id: id,
      name: name,
      label: label,
      when: when,
      photoPath: photoPath,
      coverPath: coverPath,
      ownPhoto: ownPhoto,
      confirmed: confirmed,
      share: share,
      inBook: inBook,
      probability: probability,
      others: others,
      place: place,
      latitude: latitude,
      longitude: longitude,
      indoors: indoors,
      country: country,
      photoAttached: photoAttached,
      catalogKnown: catalogKnown,
    );
  }
}

/// Applies catalog reads when every required one is known. A failed read
/// leaves [row] unknown. A find with its own photo does not wait on the
/// catalog photo. A book photo that did load is kept for the thumbnail
/// even while the vernacular or the in-book read is still unknown.
/// [inBook] is null when that read failed.
GuideSeenFind guideSeenApplyCatalog(
  GuideSeenFind row, {
  required String? label,
  required bool labelKnown,
  required String? catalogPhoto,
  required bool photoKnown,
  required bool? inBook,
  bool? photoAttached,
}) {
  final held = _holdBookCover(row, catalogPhoto, photoKnown);
  if (!labelKnown || inBook == null) return held;
  if (!row.ownPhoto && !photoKnown) return held;
  return held.withCatalog(
    label: label,
    catalogPhoto: catalogPhoto,
    inBook: inBook,
    photoAttached: photoAttached,
  );
}

/// The observation path stays. The book photo is only a stand-in thumbnail.
GuideSeenFind _holdBookCover(
  GuideSeenFind row,
  String? catalogPhoto,
  bool photoKnown,
) {
  if (!row.ownPhoto || !photoKnown) return row;
  if (catalogPhoto == null || catalogPhoto.isEmpty) return row;
  if (row.coverPath == catalogPhoto) return row;
  return row.withCover(catalogPhoto);
}

class GuideSeenMonth {
  final DateTime month;
  final List<GuideSeenFind> finds;

  const GuideSeenMonth({required this.month, required this.finds});
}

class GuideSeenNotebook {
  final List<GuideSeenFind> unconfirmed;
  final List<GuideSeenMonth> months;

  const GuideSeenNotebook({
    required this.unconfirmed,
    required this.months,
  });
}

GuideSeenShare guideSeenShare(String? status) {
  switch (status) {
    case firebaseValueReview:
      return GuideSeenShare.review;
    case firebaseValuePublic:
      return GuideSeenShare.shared;
    case firebaseValueRejection:
      return GuideSeenShare.rejected;
    default:
      return GuideSeenShare.none;
  }
}

/// Share needs a confirmed catalog species and a photo that can be published.
/// A name outside the book, or one already sent, shows its state instead.
GuideSeenChip? guideSeenChip(GuideSeenFind find) {
  if (!find.confirmed) return null;
  switch (find.share) {
    case GuideSeenShare.review:
      return GuideSeenChip.review;
    case GuideSeenShare.shared:
      return GuideSeenChip.shared;
    case GuideSeenShare.rejected:
      return GuideSeenChip.rejected;
    case GuideSeenShare.none:
      if (!find.catalogKnown) return null;
      if (!find.inBook) return GuideSeenChip.outside;
      if (!find.ownPhoto || !find.photoAttached) return null;
      return GuideSeenChip.share;
  }
}

/// The file is on this phone, in private Storage, or already published.
/// Any one of those can be sent. A bare path cannot.
bool guideSeenPhotoAttached({
  required bool local,
  required bool cloud,
  required bool published,
}) {
  return local || cloud || published;
}

/// The leading name's probability, when the saved candidates include it.
double? guideSeenLeadProbability(
  String plant,
  List<GuideSeenCandidate> hits,
) {
  for (final hit in hits) {
    if (hit.latin == plant) return hit.probability;
  }
  return null;
}

/// Up to two other catalog species from the same photo.
List<GuideSeenCandidate> guideSeenOthers(
  String plant,
  List<GuideSeenCandidate> hits,
) {
  final others = <GuideSeenCandidate>[];
  for (final hit in hits) {
    if (hit.latin == plant) continue;
    final path = hit.path;
    if (path == null || path.isEmpty || path.contains('/')) continue;
    others.add(hit);
    if (others.length == 2) break;
  }
  return others;
}

String guideSeenDetail(String when, String? place) {
  final where = place?.trim() ?? '';
  if (where.isEmpty) return when;
  return '$when · $where';
}

/// A confirmed find already published as a Sighting.
bool guideSeenIsShared(GuideSeenFind find) {
  return find.confirmed && find.share == GuideSeenShare.shared;
}

int guideSeenSharedCount(Iterable<GuideSeenFind> finds) {
  var count = 0;
  for (final find in finds) {
    if (guideSeenIsShared(find)) count++;
  }
  return count;
}

/// Drops confirmed public finds. To confirm, in review, and not accepted stay.
Iterable<GuideSeenFind> guideSeenHidingShared(Iterable<GuideSeenFind> finds) {
  return finds.where((find) => !guideSeenIsShared(find));
}

/// Unconfirmed finds stay at the top. Confirmed finds group by month,
/// newest month first.
GuideSeenNotebook arrangeGuideSeen(Iterable<GuideSeenFind> finds) {
  final unconfirmed = <GuideSeenFind>[];
  final grouped = <DateTime, List<GuideSeenFind>>{};
  for (final find in finds) {
    if (!find.confirmed) {
      unconfirmed.add(find);
      continue;
    }
    final month = DateTime(find.when.year, find.when.month);
    grouped.putIfAbsent(month, () => []).add(find);
  }
  unconfirmed.sort(_newestFirst);
  final months = grouped.entries.map((entry) {
    final rows = [...entry.value]..sort(_newestFirst);
    return GuideSeenMonth(month: entry.key, finds: rows);
  }).toList();
  months.sort((a, b) => b.month.compareTo(a.month));
  return GuideSeenNotebook(unconfirmed: unconfirmed, months: months);
}

int _newestFirst(GuideSeenFind a, GuideSeenFind b) {
  final byWhen = b.when.compareTo(a.when);
  if (byWhen != 0) return byWhen;
  return a.id.compareTo(b.id);
}

/// Finds still waiting to be confirmed.
int guideUnconfirmedTotal(Iterable<GuideSeenFind> finds) {
  var count = 0;
  for (final find in finds) {
    if (!find.confirmed) count++;
  }
  return count;
}

/// Unconfirmed rows in a private notebook snapshot. A row with no plant name
/// is skipped. A missing `confirmed` flag counts as confirmed.
int countGuideUnconfirmedRows(Map rows) {
  var count = 0;
  rows.forEach((key, raw) {
    final row = readGuideSeenRow(key, raw);
    if (row != null && !row.confirmed) count++;
  });
  return count;
}

/// One private observation row. Missing `confirmed` counts as confirmed,
/// matching older records. Returns null when the plant name is missing.
GuideSeenFind? readGuideSeenRow(Object? key, dynamic raw) {
  if (raw is! Map) return null;
  final nameValue = raw[observationPlant];
  if (nameValue is! String || nameValue.trim().isEmpty) return null;
  final name = nameValue.trim();
  final idValue = raw[observationId];
  final id = idValue is String && idValue.isNotEmpty
      ? idValue
      : (key?.toString() ?? '');
  if (id.isEmpty) return null;
  final confirmedValue = raw[observationConfirmed];
  final confirmed = confirmedValue is bool ? confirmedValue : true;
  final status = raw[observationStatus];
  final photo = _firstText(raw[observationPhotoPaths]);
  final hits = _candidates(raw[observationCandidates]);
  return GuideSeenFind(
    id: id,
    name: name,
    when: _when(raw),
    photoPath: photo,
    ownPhoto: photo != null,
    photoAttached: false,
    confirmed: confirmed,
    share: guideSeenShare(status is String ? status : null),
    probability: guideSeenLeadProbability(name, hits),
    others: guideSeenOthers(name, hits),
    latitude: _asDouble(raw[observationLatitude]),
    longitude: _asDouble(raw[observationLongitude]),
    indoors: guideRowIndoors(raw[observationIndoors]),
    country: guideRowCountry(raw[observationCountry]),
    catalogKnown: false,
  );
}

/// Every private row in a notebook snapshot, newest first. Skips a row
/// with no plant name. This is the list the Seen page can draw immediately.
List<GuideSeenFind> guideSeenRows(dynamic value) {
  if (value is! Map) return [];
  final rows = <GuideSeenFind>[];
  value.forEach((key, raw) {
    final row = readGuideSeenRow(key, raw);
    if (row != null) rows.add(row);
  });
  rows.sort((a, b) {
    final byWhen = b.when.compareTo(a.when);
    if (byWhen != 0) return byWhen;
    return a.id.compareTo(b.id);
  });
  return rows;
}

/// `photoCloud` on each row. True means the file is already in private Storage.
Map<String, bool> guideSeenCloudFlags(dynamic value) {
  if (value is! Map) return {};
  final clouds = <String, bool>{};
  value.forEach((key, raw) {
    if (raw is! Map || raw[observationPhotoCloud] != true) return;
    final row = readGuideSeenRow(key, raw);
    if (row == null) return;
    clouds[row.id] = true;
  });
  return clouds;
}

/// Keeps a vernacular and a Share answer across a fresh snapshot of the
/// same find. A changed plant name or photo is looked up again. Status
/// always comes from [raw].
GuideSeenFind guideSeenCarryFace(
  GuideSeenFind raw,
  GuideSeenFind? previous,
) {
  if (previous == null || previous.name != raw.name) return raw;
  if (!previous.catalogKnown) {
    final cover = previous.coverPath;
    if (cover == null || cover.isEmpty) return raw;
    return raw.withCover(cover);
  }
  final samePhoto = raw.ownPhoto
      ? previous.ownPhoto && previous.photoPath == raw.photoPath
      : !previous.ownPhoto;
  final catalogPhoto = previous.coverPath ??
      (!raw.ownPhoto && !previous.ownPhoto ? previous.photoPath : null);
  return raw.withCatalog(
    label: previous.label,
    catalogPhoto: catalogPhoto,
    inBook: previous.inBook,
    photoAttached: samePhoto && previous.photoAttached,
  );
}

/// A known new read, otherwise a remembered known face, otherwise [raw].
/// An unknown read is not remembered over a face already known.
GuideSeenFind guideSeenChooseFace(
  GuideSeenFind raw,
  GuideSeenFind? read,
  GuideSeenFind? remembered,
) {
  final fresh = guideSeenCarryFace(raw, read);
  if (fresh.catalogKnown) return fresh;
  final kept = guideSeenCarryFace(raw, remembered);
  if (kept.catalogKnown) return kept;
  final freshCover = fresh.coverPath;
  if (freshCover != null && freshCover.isNotEmpty) return fresh;
  final keptCover = kept.coverPath;
  if (keptCover != null && keptCover.isNotEmpty) return kept;
  return raw;
}

/// The list Seen paints and stores after one decorate pass, plus the stamp
/// to keep. [stamp] is null when a read failed or the snapshot moved, so
/// the next pass runs.
class GuideSeenPass {
  final List<GuideSeenFind> rows;
  final String? stamp;

  const GuideSeenPass(this.rows, this.stamp);
}

GuideSeenPass guideSeenPass({
  required List<GuideSeenFind> latest,
  required List<GuideSeenFind> read,
  required Map<String, GuideSeenFind> remembered,
  required String stamp,
  required String doneStamp,
}) {
  final byId = {for (final row in read) row.id: row};
  final rows = [
    for (final row in latest)
      guideSeenChooseFace(row, byId[row.id], remembered[row.id]),
  ];
  final settled = doneStamp == stamp &&
      latest.every((row) {
        final next = byId[row.id];
        return next != null && next.catalogKnown && next.name == row.name;
      });
  return GuideSeenPass(rows, settled ? doneStamp : null);
}

/// Identity of the lookups Seen has to repeat: plant, photo path, and
/// whether the photo is already in private Storage. Status and date are
/// already on the row, so a review update does not belong here.
String guideSeenDecorateStamp(dynamic value) {
  final rows = guideSeenRows(value);
  final clouds = guideSeenCloudFlags(value);
  final buffer = StringBuffer()
    ..write(rows.length)
    ..write('\n');
  for (final row in rows) {
    buffer
      ..write(row.id)
      ..write('\u0001')
      ..write(row.name)
      ..write('\u0001')
      ..write(row.photoPath ?? '')
      ..write('\u0001')
      ..write(clouds[row.id] == true ? '1' : '0')
      ..write('\n');
  }
  return buffer.toString();
}

/// Missing or unrecognised means outdoor. Matches the statistics recount.
bool guideRowIndoors(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
        return true;
    }
  }
  return false;
}

/// A private row that has a place and no country yet.
class GuideSeenCountryGap {
  final String id;
  final String plant;
  final double latitude;
  final double longitude;

  const GuideSeenCountryGap({
    required this.id,
    required this.plant,
    required this.latitude,
    required this.longitude,
  });
}

/// Rows the notebook can give a country. A stored code, or 0, 0, is skipped.
List<GuideSeenCountryGap> guideSeenCountryGaps(dynamic value) {
  if (value is! Map) return const [];
  final gaps = <GuideSeenCountryGap>[];
  value.forEach((key, raw) {
    if (raw is! Map) return;
    if (guideRowCountry(raw[observationCountry]) != null) return;
    final nameValue = raw[observationPlant];
    if (nameValue is! String || nameValue.trim().isEmpty) return;
    final latitude = _asDouble(raw[observationLatitude]);
    final longitude = _asDouble(raw[observationLongitude]);
    if (!_hasPlace(latitude, longitude)) return;
    final idValue = raw[observationId];
    final id = idValue is String && idValue.isNotEmpty
        ? idValue
        : (key?.toString() ?? '');
    if (id.isEmpty) return;
    gaps.add(GuideSeenCountryGap(
      id: id,
      plant: nameValue.trim(),
      latitude: latitude,
      longitude: longitude,
    ));
  });
  return gaps;
}

/// 0, 0 is no place. Same bound as a photo position.
bool _hasPlace(double latitude, double longitude) {
  if (!latitude.isFinite || !longitude.isFinite) return false;
  if (latitude == 0 && longitude == 0) return false;
  if (latitude.abs() > 90 || longitude.abs() > 180) return false;
  return true;
}

List<GuideSeenCandidate> _candidates(dynamic raw) {
  if (raw is! List) return const [];
  final hits = <GuideSeenCandidate>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final latin = item['latin'];
    if (latin is! String || latin.trim().isEmpty) continue;
    final vernacular = item['vernacular'];
    final probability = item['probability'];
    final path = item['path'];
    hits.add(GuideSeenCandidate(
      latin: latin.trim(),
      vernacular: vernacular is String && vernacular.trim().isNotEmpty
          ? vernacular.trim()
          : null,
      probability: probability is num ? probability.toDouble() : null,
      path: path is String && path.isNotEmpty ? path : null,
    ));
  }
  return hits;
}

String? _firstText(dynamic raw) {
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

DateTime _when(Map raw) {
  final date = raw[observationDate];
  final time = date is Map ? date[observationTime] : null;
  if (time is int) return DateTime.fromMillisecondsSinceEpoch(time);
  if (time is num) return DateTime.fromMillisecondsSinceEpoch(time.toInt());
  return DateTime.fromMillisecondsSinceEpoch(0);
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return 0;
}
