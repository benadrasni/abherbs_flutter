import 'package:abherbs_flutter/seen/guide_seen.dart';
import 'package:abherbs_flutter/seen/observation.dart';

/// One plant row on the statistics page.
class GuideStatPlant {
  final String name;
  final String? label;
  final String? photoPath;
  final bool inBook;
  final DateTime when;
  final int count;

  const GuideStatPlant({
    required this.name,
    required this.when,
    this.label,
    this.photoPath,
    this.inBook = false,
    this.count = 1,
  });
}

class GuideYearCount {
  final int year;
  final int count;

  const GuideYearCount(this.year, this.count);
}

class GuideCountryTally {
  final String code;
  final int count;

  const GuideCountryTally(this.code, this.count);
}

/// Outdoor finds in one Seen notebook.
class GuideNotebookStats {
  final int finds;
  final int plants;
  final int shared;
  final int unconfirmed;
  final GuideStatPlant? first;
  final GuideStatPlant? last;

  /// Plants tied for the highest count, when that count is greater than one.
  final List<GuideStatPlant> most;
  final List<GuideYearCount> years;
  final List<GuideCountryTally> countries;
  final int unplaced;

  const GuideNotebookStats({
    required this.finds,
    required this.plants,
    required this.shared,
    required this.unconfirmed,
    required this.first,
    required this.last,
    required this.most,
    required this.years,
    required this.countries,
    required this.unplaced,
  });
}

/// Stored public aggregate. Years come from the sighting list.
class GuideSightingHeadline {
  final int count;
  final int plants;
  final int people;
  final String firstName;
  final DateTime? firstWhen;
  final String lastName;
  final DateTime? lastWhen;
  final String mostName;
  final int mostCount;
  final List<GuideCountryTally> countries;

  const GuideSightingHeadline({
    required this.count,
    required this.plants,
    required this.people,
    required this.firstName,
    required this.firstWhen,
    required this.lastName,
    required this.lastWhen,
    required this.mostName,
    required this.mostCount,
    required this.countries,
  });
}

class GuideSightingsLoad {
  final GuideSightingHeadline? headline;
  final List<GuideYearCount> years;

  const GuideSightingsLoad({required this.headline, required this.years});
}

class GuideStatFace {
  final String? label;
  final String? photoPath;
  final bool inBook;

  const GuideStatFace({
    this.label,
    this.photoPath,
    required this.inBook,
  });
}

/// Indoor finds are left out. A missing country is [GuideNotebookStats.unplaced].
GuideNotebookStats guideNotebookStats(Iterable<GuideSeenFind> finds) {
  final rows = [for (final find in finds) if (!find.indoors) find]..sort(_byWhen);
  final byPlant = <String, List<GuideSeenFind>>{};
  final years = <int, int>{};
  final countries = <String, int>{};
  var shared = 0;
  var unconfirmed = 0;
  var unplaced = 0;
  for (final find in rows) {
    byPlant.putIfAbsent(find.name, () => []).add(find);
    years[find.when.year] = (years[find.when.year] ?? 0) + 1;
    final country = find.country;
    if (country == null) {
      unplaced++;
    } else {
      countries[country] = (countries[country] ?? 0) + 1;
    }
    if (guideSeenIsShared(find)) shared++;
    if (!find.confirmed) unconfirmed++;
  }
  var top = 0;
  for (final group in byPlant.values) {
    if (group.length > top) top = group.length;
  }
  final most = <GuideStatPlant>[];
  if (top > 1) {
    final names = byPlant.keys.where((name) => byPlant[name]!.length == top).toList()
      ..sort();
    for (final name in names) {
      final group = byPlant[name]!;
      most.add(_plant(group.last, count: top));
    }
  }
  final yearRows = [
    for (final entry in years.entries) GuideYearCount(entry.key, entry.value),
  ]..sort((a, b) => a.year.compareTo(b.year));
  return GuideNotebookStats(
    finds: rows.length,
    plants: byPlant.length,
    shared: shared,
    unconfirmed: unconfirmed,
    first: rows.isEmpty ? null : _plant(rows.first),
    last: rows.isEmpty ? null : _plant(rows.last),
    most: most,
    years: yearRows,
    countries: _countryRows(countries),
    unplaced: unplaced,
  );
}

GuideStatPlant _plant(GuideSeenFind find, {int count = 1}) {
  return GuideStatPlant(
    name: find.name,
    label: find.label,
    photoPath: find.photoPath,
    inBook: find.inBook,
    when: find.when,
    count: count,
  );
}

int _byWhen(GuideSeenFind a, GuideSeenFind b) {
  final byWhen = a.when.compareTo(b.when);
  if (byWhen != 0) return byWhen;
  return a.id.compareTo(b.id);
}

/// The `observations/public/stats` node. Null when the node is missing.
GuideSightingHeadline? guideSightingHeadline(dynamic raw) {
  if (raw is! Map) return null;
  final countries = <String, int>{};
  final stored = raw['countries'];
  if (stored is Map) {
    stored.forEach((key, value) {
      final code = guideRowCountry(key);
      final count = _asInt(value);
      if (code == null || count <= 0) return;
      countries[code] = (countries[code] ?? 0) + count;
    });
  }
  final first = _asInt(raw['firstDate']);
  final last = _asInt(raw['lastDate']);
  return GuideSightingHeadline(
    count: _asInt(raw['count']),
    plants: _asInt(raw['distinctFlowers']),
    people: _asInt(raw['observers']),
    firstName: _text(raw['firstFlower']),
    firstWhen: first > 0 ? DateTime.fromMillisecondsSinceEpoch(first) : null,
    lastName: _text(raw['lastFlower']),
    lastWhen: last > 0 ? DateTime.fromMillisecondsSinceEpoch(last) : null,
    mostName: _text(raw['mostObserved']),
    mostCount: _asInt(raw['mostObservedCount']),
    countries: _countryRows(countries),
  );
}

/// Outdoor rows of a public by-date list, used when the stats node is absent.
GuideSightingHeadline? guideSightingHeadlineFromRows(dynamic raw) {
  if (raw is! Map) return null;
  final rows = <_PublicRow>[];
  raw.forEach((key, value) {
    final row = _publicRow(value);
    if (row != null) rows.add(row);
  });
  if (rows.isEmpty) return null;
  rows.sort((a, b) {
    final byWhen = a.when.compareTo(b.when);
    if (byWhen != 0) return byWhen;
    return a.name.compareTo(b.name);
  });
  final plants = <String, int>{};
  final countries = <String, int>{};
  final people = <String>{};
  for (final row in rows) {
    plants[row.name] = (plants[row.name] ?? 0) + 1;
    final country = row.country;
    if (country != null) countries[country] = (countries[country] ?? 0) + 1;
    final observer = row.observer;
    if (observer != null) people.add(observer);
  }
  var top = 0;
  var mostName = '';
  final names = plants.keys.toList()..sort();
  for (final name in names) {
    final count = plants[name]!;
    if (count > top) {
      top = count;
      mostName = name;
    }
  }
  final first = rows.first;
  final last = rows.last;
  return GuideSightingHeadline(
    count: rows.length,
    plants: plants.length,
    people: people.length,
    firstName: first.name,
    firstWhen: first.when,
    lastName: last.name,
    lastWhen: last.when,
    mostName: mostName,
    mostCount: top,
    countries: _countryRows(countries),
  );
}

/// Local calendar year of each outdoor sighting. `date.time`, otherwise `-order`.
List<GuideYearCount> guideSightingYears(dynamic raw) {
  if (raw is! Map) return const [];
  final counts = <int, int>{};
  raw.forEach((key, value) {
    if (value is! Map) return;
    if (guideRowIndoors(value[observationIndoors])) return;
    final when = guideObservationWhen(value);
    if (when == null) return;
    counts[when.year] = (counts[when.year] ?? 0) + 1;
  });
  final years = [
    for (final entry in counts.entries) GuideYearCount(entry.key, entry.value),
  ]..sort((a, b) => a.year.compareTo(b.year));
  return years;
}

/// The instant on the row. Prefers `date.time`, then `-order`.
DateTime? guideObservationWhen(Map raw) {
  final date = raw[observationDate];
  final time = date is Map ? date[observationTime] : null;
  final millis = _millis(time) ?? _millisFromOrder(raw[observationOrder]);
  if (millis == null || millis <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}

int? _millis(dynamic value) {
  if (value is int && value > 0) return value;
  if (value is num && value > 0) return value.toInt();
  return null;
}

int? _millisFromOrder(dynamic order) {
  if (order is! num) return null;
  final millis = -order.toInt();
  if (millis <= 0) return null;
  return millis;
}

class _PublicRow {
  final String name;
  final DateTime when;
  final String? country;
  final String? observer;

  const _PublicRow(this.name, this.when, this.country, this.observer);
}

_PublicRow? _publicRow(dynamic raw) {
  if (raw is! Map) return null;
  if (guideRowIndoors(raw[observationIndoors])) return null;
  final name = _text(raw[observationPlant]);
  if (name.isEmpty) return null;
  final when = guideObservationWhen(raw);
  if (when == null) return null;
  return _PublicRow(
    name,
    when,
    guideRowCountry(raw[observationCountry]),
    _observer(raw[observationId]),
  );
}

String? _observer(dynamic id) {
  if (id is! String) return null;
  final split = id.indexOf('_');
  if (split <= 0) return null;
  return id.substring(0, split);
}

List<GuideCountryTally> _countryRows(Map<String, int> counts) {
  final rows = [
    for (final entry in counts.entries)
      if (entry.value > 0) GuideCountryTally(entry.key, entry.value),
  ];
  rows.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    return a.code.compareTo(b.code);
  });
  return rows;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

String _text(dynamic value) {
  if (value is! String) return '';
  return value.trim();
}
