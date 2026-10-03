import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/utils/utils.dart';

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
  final bool ownPhoto;
  final bool confirmed;
  final GuideSeenShare share;
  final bool inBook;
  final double? probability;
  final List<GuideSeenCandidate> others;
  final String? place;
  final double latitude;
  final double longitude;

  const GuideSeenFind({
    required this.id,
    required this.name,
    required this.when,
    this.label,
    this.photoPath,
    this.ownPhoto = false,
    this.confirmed = true,
    this.share = GuideSeenShare.none,
    this.inBook = false,
    this.probability,
    this.others = const [],
    this.place,
    this.latitude = 0,
    this.longitude = 0,
  });

  GuideSeenFind withCatalog({
    String? label,
    String? catalogPhoto,
    required bool inBook,
  }) {
    return GuideSeenFind(
      id: id,
      name: name,
      label: label,
      when: when,
      photoPath: photoPath ?? catalogPhoto,
      ownPhoto: ownPhoto,
      confirmed: confirmed,
      share: share,
      inBook: inBook,
      probability: probability,
      others: others,
      place: place,
      latitude: latitude,
      longitude: longitude,
    );
  }
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

/// Share needs a confirmed catalog species and the person's own photo.
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
      if (!find.inBook) return GuideSeenChip.outside;
      if (!find.ownPhoto) return null;
      return GuideSeenChip.share;
  }
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
    confirmed: confirmed,
    share: guideSeenShare(status is String ? status : null),
    probability: guideSeenLeadProbability(name, hits),
    others: guideSeenOthers(name, hits),
    latitude: _asDouble(raw[observationLatitude]),
    longitude: _asDouble(raw[observationLongitude]),
  );
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
