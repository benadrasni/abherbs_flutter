import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/utils/utils.dart';

const guideSpeciesRankLimit = 7;

const guideSpeciesSectionIds = [
  'flower',
  'inflorescence',
  'fruit',
  'leaf',
  'stem',
  'habitat',
  'toxicity',
  'herbalism',
  'trivia',
];

class GuideTextRun {
  final String text;
  final bool bold;

  const GuideTextRun(this.text, this.bold);
}

class GuideSpeciesSection {
  final String id;
  final String text;

  const GuideSpeciesSection({required this.id, required this.text});
}

class GuideSpeciesRank {
  final String rank;
  final String latin;
  final String? vernacular;

  const GuideSpeciesRank({
    required this.rank,
    required this.latin,
    this.vernacular,
  });
}

class GuideSighting {
  final String id;
  final String photoPath;
  final DateTime? when;

  const GuideSighting({
    required this.id,
    required this.photoPath,
    required this.when,
  });
}

class GuideSpeciesSeen {
  final int count;
  final DateTime? last;
  final String? photoPath;

  const GuideSpeciesSeen({
    required this.count,
    required this.last,
    required this.photoPath,
  });
}

class GuideSourceLink {
  final String label;
  final String url;

  const GuideSourceLink({required this.label, required this.url});
}

class GuideSeenPhoto {
  final String relativePath;
  final DateTime when;
  final double latitude;
  final double longitude;
  final bool fromPhoto;

  const GuideSeenPhoto({
    required this.relativePath,
    required this.when,
    required this.latitude,
    required this.longitude,
    required this.fromPhoto,
  });
}

class GuideSeenDraft {
  final String plant;
  final DateTime when;
  final double latitude;
  final double longitude;
  final String? photoPath;
  final bool fromPhoto;

  const GuideSeenDraft({
    required this.plant,
    required this.when,
    this.latitude = 0,
    this.longitude = 0,
    this.photoPath,
    this.fromPhoto = false,
  });
}

class GuideSpecies {
  final String name;
  final String? author;
  final String? label;
  final List<String> names;
  final String? description;
  final List<GuideSpeciesSection> sections;
  final int heightFrom;
  final int heightTo;
  final int floweringFrom;
  final int floweringTo;
  final String? familyLatin;
  final String? familyLabel;
  final List<GuideSpeciesRank> ranks;
  final List<String> photoPaths;
  final String? platePath;
  final String? mapPath;
  final List<GuideSourceLink> sources;
  final List<GuideSighting> sightings;
  final GuideSpeciesSeen? seen;

  const GuideSpecies({
    required this.name,
    required this.author,
    required this.label,
    required this.names,
    required this.description,
    required this.sections,
    required this.heightFrom,
    required this.heightTo,
    required this.floweringFrom,
    required this.floweringTo,
    required this.familyLatin,
    required this.familyLabel,
    required this.ranks,
    required this.photoPaths,
    required this.platePath,
    required this.mapPath,
    required this.sources,
    required this.sightings,
    required this.seen,
  });

  bool get hasVernacular {
    final value = label?.trim();
    if (value == null || value.isEmpty) return false;
    return value.toLowerCase() != name.toLowerCase();
  }
}

GuideSpecies? assembleGuideSpecies({
  required String name,
  required Map plant,
  required PlantTranslation translation,
  required Map<String, String> vernaculars,
  required List<GuideSighting> sightings,
  GuideSpeciesSeen? seen,
}) {
  final latin = _text(plant['name']) ?? name;
  if (latin.isEmpty) return null;
  final family = guideFamilyLatin(plant['APGIV']);
  return GuideSpecies(
    name: latin,
    author: _text(plant['author']),
    label: _text(translation.label),
    names: guideAlsoNames(translation, latin),
    description: guideBodyText(translation.description),
    sections: guideSpeciesSections(translation),
    heightFrom: _int(plant['heightFrom']),
    heightTo: _int(plant['heightTo']),
    floweringFrom: _int(plant['floweringFrom']),
    floweringTo: _int(plant['floweringTo']),
    familyLatin: family,
    familyLabel: family == null ? null : vernaculars[family],
    ranks: guideSpeciesRanks(plant['APGIV'], vernaculars),
    photoPaths: guidePhotoPaths(plant['photoUrls']),
    platePath: guideStoragePhoto(plant['illustrationUrl']),
    mapPath: guideDistributionPath(_text(plant['illustrationUrl'])),
    sources: guideSourceLinks(_sourceUrls(translation, plant)),
    sightings: sightings,
    seen: seen,
  );
}

List<GuideSpeciesSection> guideSpeciesSections(PlantTranslation translation) {
  final values = {
    'flower': translation.flower,
    'inflorescence': translation.inflorescence,
    'fruit': translation.fruit,
    'leaf': translation.leaf,
    'stem': translation.stem,
    'habitat': translation.habitat,
    'toxicity': translation.toxicity,
    'herbalism': translation.herbalism,
    'trivia': translation.trivia,
  };
  return [
    for (final id in guideSpeciesSectionIds)
      if (guideBodyText(values[id]) != null)
        GuideSpeciesSection(id: id, text: guideBodyText(values[id])!),
  ];
}

String? guideBodyText(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final plain = trimmed.toLowerCase();
  if (plain == 'none' || plain == 'none.') return null;
  return trimmed;
}

List<String> guideAlsoNames(PlantTranslation translation, String latin) {
  final skip = {
    latin.trim().toLowerCase(),
    if (translation.label != null) translation.label!.trim().toLowerCase(),
  };
  final seen = <String>{};
  final names = <String>[];
  for (final raw in translation.names) {
    final name = raw.toString().trim();
    if (name.isEmpty) continue;
    final key = name.toLowerCase();
    if (skip.contains(key) || !seen.add(key)) continue;
    names.add(name);
  }
  return names;
}

List<GuideSpeciesRank> guideSpeciesRanks(
  dynamic apg,
  Map<String, String> vernaculars,
) {
  if (apg is! Map) return const [];
  final keys = apg.keys.map((key) => key.toString()).where((key) {
    return !key.toLowerCase().contains('regnum');
  }).toList()
    ..sort();
  final ranks = <GuideSpeciesRank>[];
  for (final key in keys) {
    final latin = _text(apg[key]);
    if (latin == null) continue;
    final rank = key.contains('_') ? key.substring(key.indexOf('_') + 1) : key;
    if (rank.isEmpty) continue;
    ranks.add(GuideSpeciesRank(
      rank: rank,
      latin: latin,
      vernacular: vernaculars[latin],
    ));
    if (ranks.length == guideSpeciesRankLimit) break;
  }
  return ranks;
}

/// A `plants_v2` row. Id 0 is a real catalog plant.
bool guidePlantRecord(dynamic raw) {
  return raw is Map && raw['id'] != null;
}

String? guideFamilyLatin(dynamic apg) {
  if (apg is! Map) return null;
  for (final entry in apg.entries) {
    final key = entry.key.toString();
    final rank = key.contains('_') ? key.substring(key.indexOf('_') + 1) : key;
    if (rank == 'Familia') return _text(entry.value);
  }
  return null;
}

String? guideTaxonVernacular(dynamic raw, String latin) {
  final names = <String>[];
  if (raw is String) {
    names.add(raw.trim());
  } else if (raw is List) {
    for (final item in raw) {
      if (item is String && item.trim().isNotEmpty) names.add(item.trim());
    }
  } else if (raw is Map) {
    final keys = raw.keys.map((key) => key.toString()).toList()..sort();
    for (final key in keys) {
      final item = raw[key];
      if (item is String && item.trim().isNotEmpty) names.add(item.trim());
    }
  }
  final latinKey = latin.trim().toLowerCase();
  for (final name in names) {
    if (name.isNotEmpty && name.toLowerCase() != latinKey) return name;
  }
  return null;
}

String guideHeightText(int from, int to) {
  if (from <= 0 && to <= 0) return '';
  final lo = from <= to ? from : to;
  final hi = from <= to ? to : from;
  final low = lo < 0 ? 0 : lo;
  final high = hi < 0 ? 0 : hi;
  if (high >= 100) {
    return '${_meters(low)}–${_meters(high)} m';
  }
  return '$low–$high cm';
}

String guideFloweringRange(
  int from,
  int to,
  String Function(int month) monthName,
) {
  if (from < 1 || from > 12 || to < 1 || to > 12) return '';
  final start = monthName(from);
  final end = monthName(to);
  if (start.isEmpty) return '';
  if (from == to || start == end) return start;
  return '$start–$end';
}

List<GuideSighting> guideSightings(dynamic raw) {
  final rows = <MapEntry<String, Map>>[];
  if (raw is List) {
    for (var i = 0; i < raw.length; i++) {
      final row = raw[i];
      if (row is Map) rows.add(MapEntry(i.toString(), row));
    }
  } else if (raw is Map) {
    raw.forEach((key, value) {
      if (value is Map) rows.add(MapEntry(key.toString(), value));
    });
  }
  final sightings = <GuideSighting>[];
  for (final entry in rows) {
    final row = entry.value;
    final status = row['status'];
    if (status != null && status != 'public') continue;
    if (status == null) continue;
    final photo = guideStoragePhoto(_firstPhoto(row));
    if (photo == null) continue;
    final id = _text(row['id']) ?? entry.key;
    sightings.add(GuideSighting(
      id: id,
      photoPath: photo,
      when: guideObservationWhen(row),
    ));
  }
  sightings.sort((a, b) {
    final aw = a.when?.millisecondsSinceEpoch ?? 0;
    final bw = b.when?.millisecondsSinceEpoch ?? 0;
    return bw.compareTo(aw);
  });
  return sightings;
}

GuideSpeciesSeen? guideSpeciesSeen(Iterable<dynamic> rows) {
  var count = 0;
  DateTime? last;
  String? photo;
  String? fallbackPhoto;
  for (final row in rows) {
    if (row is! Map) continue;
    count++;
    final path = guideStoragePhoto(_firstPhoto(row));
    fallbackPhoto ??= path;
    final when = guideObservationWhen(row);
    if (when == null) continue;
    if (last == null || when.isAfter(last)) {
      last = when;
      if (path != null) photo = path;
    }
  }
  if (count == 0) return null;
  return GuideSpeciesSeen(
    count: count,
    last: last,
    photoPath: photo ?? fallbackPhoto,
  );
}

GuideSpeciesSeen guideSeenAfterAdd(
  GuideSpeciesSeen? current,
  GuideSeenDraft draft,
) {
  final count = (current?.count ?? 0) + 1;
  final currentLast = current?.last;
  final draftWins = currentLast == null || !draft.when.isBefore(currentLast);
  if (draftWins) {
    return GuideSpeciesSeen(
      count: count,
      last: draft.when,
      photoPath: draft.photoPath ?? current?.photoPath,
    );
  }
  return GuideSpeciesSeen(
    count: count,
    last: currentLast,
    photoPath: current?.photoPath,
  );
}

DateTime? guideObservationWhen(Map row) {
  final date = row['date'];
  final raw = date is Map ? date['time'] : row['time'];
  if (raw is! num || raw <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
}

String? guideDistributionPath(String? illustrationUrl) {
  if (illustrationUrl == null || illustrationUrl.isEmpty) return null;
  final slash = illustrationUrl.lastIndexOf('/');
  final file =
      slash >= 0 ? illustrationUrl.substring(slash + 1) : illustrationUrl;
  final dot = file.lastIndexOf('.');
  if (dot <= 0) return null;
  final prefix = slash >= 0 ? illustrationUrl.substring(0, slash + 1) : '';
  return storagePhotos +
      prefix +
      file.substring(0, dot) +
      '_distribution' +
      file.substring(dot);
}

List<String> guidePhotoPaths(dynamic raw) {
  final paths = <String>[];
  void add(dynamic value) {
    final path = guideStoragePhoto(value);
    if (path != null) paths.add(path);
  }

  if (raw is List) {
    for (final item in raw) {
      add(item);
    }
  } else if (raw is Map) {
    final keys = raw.keys.map((key) => key.toString()).toList()..sort();
    for (final key in keys) {
      add(raw[key]);
    }
  }
  return paths;
}

String? guideStoragePhoto(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith(storagePhotos) ||
      trimmed.startsWith(storageObservations)) {
    return trimmed;
  }
  return storagePhotos + trimmed;
}

List<GuideSourceLink> guideSourceLinks(Iterable<String> urls) {
  final seen = <String>{};
  final links = <GuideSourceLink>[];
  for (final url in urls) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) continue;
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    if (!seen.add(host)) continue;
    links.add(GuideSourceLink(label: host, url: url.trim()));
  }
  return links;
}

List<GuideTextRun> guideTextRuns(String text) {
  final runs = <GuideTextRun>[];
  final parts = text.split('<b>');
  for (var i = 0; i < parts.length; i++) {
    final part = parts[i];
    if (part.isEmpty) continue;
    if (i == 0) {
      runs.add(GuideTextRun(part, false));
      continue;
    }
    final close = part.indexOf('</b>');
    if (close < 0) {
      runs.add(GuideTextRun(part, true));
      continue;
    }
    if (close > 0) runs.add(GuideTextRun(part.substring(0, close), true));
    final rest = part.substring(close + 4);
    if (rest.isNotEmpty) runs.add(GuideTextRun(rest, false));
  }
  return runs;
}

String _meters(int centimeters) {
  final meters = centimeters / 100;
  if (meters == meters.roundToDouble()) return meters.toStringAsFixed(0);
  return meters.toStringAsFixed(1);
}

String? _text(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

String? _firstPhoto(Map row) {
  final raw = row['photoPaths'];
  if (raw is List) {
    for (final item in raw) {
      if (item != null && item.toString().trim().isNotEmpty) {
        return item.toString();
      }
    }
  } else if (raw is Map) {
    final keys = raw.keys.map((key) => key.toString()).toList()..sort();
    for (final key in keys) {
      final item = raw[key];
      if (item != null && item.toString().trim().isNotEmpty) {
        return item.toString();
      }
    }
  }
  return null;
}

List<String> _sourceUrls(PlantTranslation translation, Map plant) {
  final urls = <String>[];
  void add(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) urls.add(raw.trim());
    if (raw is List) {
      for (final item in raw) {
        add(item);
      }
    }
  }

  add(translation.sourceUrls);
  add(translation.wikipedia);
  add(plant['sourceUrls']);
  return urls;
}
