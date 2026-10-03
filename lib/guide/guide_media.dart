import 'dart:convert';

import 'package:crypto/crypto.dart';

/// md5 hex of the file bytes. The catalog stamp uses the same digest.
String guideMediaHash(List<int> bytes) => md5.convert(bytes).toString();

/// One picture file. [url] is the path under `photos/`, as in `photoUrls`.
class GuideMediaFile {
  final String url;
  final int bytes;
  final String hash;

  const GuideMediaFile({
    required this.url,
    required this.bytes,
    required this.hash,
  });

  Map<String, Object> toJson() => {'u': url, 'b': bytes, 'h': hash};
}

/// Photos, the unsuffixed plate, and the range map for one plant.
class GuideMediaStamp {
  final List<GuideMediaFile> photos;
  final GuideMediaFile? plate;
  final GuideMediaFile? map;

  const GuideMediaStamp({
    this.photos = const [],
    this.plate,
    this.map,
  });

  static const empty = GuideMediaStamp();

  List<GuideMediaFile> get files => [
        ...photos,
        if (plate != null) plate!,
        if (map != null) map!,
      ];

  int get bytes {
    var total = 0;
    for (final file in files) {
      total += file.bytes;
    }
    return total;
  }

  Map<String, Object> toJson() {
    return {
      if (photos.isNotEmpty) 'photos': [for (final file in photos) file.toJson()],
      if (plate != null) 'plate': plate!.toJson(),
      if (map != null) 'map': map!.toJson(),
    };
  }
}

GuideMediaFile? _file(dynamic raw) {
  if (raw is! Map) return null;
  final url = raw['u'];
  if (url is! String || url.isEmpty) return null;
  final bytes = _int(raw['b']);
  final hash = raw['h'];
  if (bytes == null || bytes < 0 || hash is! String || hash.isEmpty) {
    return null;
  }
  return GuideMediaFile(url: url, bytes: bytes, hash: hash);
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

List<GuideMediaFile> _files(dynamic raw) {
  final files = <GuideMediaFile>[];
  if (raw is List) {
    for (final value in raw) {
      final file = _file(value);
      if (file != null) files.add(file);
    }
  } else if (raw is Map) {
    final entries = <MapEntry<int, dynamic>>[];
    raw.forEach((key, value) {
      final index = int.tryParse(key.toString());
      if (index == null) return;
      entries.add(MapEntry(index, value));
    });
    entries.sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      final file = _file(entry.value);
      if (file != null) files.add(file);
    }
  }
  return files;
}

GuideMediaStamp readGuideMediaStamp(dynamic raw) {
  if (raw is! Map) return GuideMediaStamp.empty;
  final photos = _files(raw['photos'])
    ..sort((a, b) => a.url.compareTo(b.url));
  return GuideMediaStamp(
    photos: photos,
    plate: _file(raw['plate']),
    map: _file(raw['map']),
  );
}

/// Split saved files into photos, the plate, and the map.
GuideMediaStamp guideMediaStampFromFiles(
  List<GuideMediaFile> files, {
  String? plateUrl,
}) {
  GuideMediaFile? plate;
  GuideMediaFile? map;
  final photos = <GuideMediaFile>[];
  for (final file in files) {
    final name = file.url.split('/').last;
    if (name.contains('_distribution.')) {
      map = file;
    } else if (plateUrl != null && file.url == plateUrl) {
      plate = file;
    } else if (name.contains('@400') || name.contains('@1600')) {
      continue;
    } else {
      photos.add(file);
    }
  }
  photos.sort((a, b) => a.url.compareTo(b.url));
  return GuideMediaStamp(photos: photos, plate: plate, map: map);
}

class GuideMediaDiff {
  final List<GuideMediaFile> download;
  final List<String> remove;

  const GuideMediaDiff({
    required this.download,
    required this.remove,
  });

  bool get isEmpty => download.isEmpty && remove.isEmpty;
}

/// Files whose path or hash changed, and paths that left the stamp.
GuideMediaDiff guideMediaDiff(GuideMediaStamp? oldStamp, GuideMediaStamp next) {
  final previous = <String, GuideMediaFile>{
    for (final file in oldStamp?.files ?? const <GuideMediaFile>[]) file.url: file,
  };
  final current = <String, GuideMediaFile>{
    for (final file in next.files) file.url: file,
  };
  final download = <GuideMediaFile>[];
  for (final file in next.files) {
    final had = previous[file.url];
    if (had == null || had.hash != file.hash) download.add(file);
  }
  final remove = <String>[
    for (final url in previous.keys)
      if (!current.containsKey(url)) url,
  ]..sort();
  return GuideMediaDiff(download: download, remove: remove);
}

/// One catalog change. [index] is the position in the change list.
class GuideCatalogChange {
  final int index;
  final int plantId;
  final String kind;
  final GuideMediaStamp stamp;

  const GuideCatalogChange({
    required this.index,
    required this.plantId,
    required this.kind,
    required this.stamp,
  });

  bool get added => kind == 'added';
}

class GuideChangeLog {
  final int count;
  final List<GuideCatalogChange> changes;

  const GuideChangeLog({required this.count, required this.changes});

  static const empty = GuideChangeLog(count: 0, changes: []);
}

GuideChangeLog readGuideChangeLog(dynamic raw) {
  if (raw is! Map) return GuideChangeLog.empty;
  final count = _int(raw['count']) ?? 0;
  final changes = <GuideCatalogChange>[];
  void add(int index, dynamic value) {
    if (value is! Map) return;
    final id = _int(value['id']);
    final kind = value['kind'];
    if (id == null || (kind != 'added' && kind != 'pictures')) return;
    changes.add(
      GuideCatalogChange(
        index: index,
        plantId: id,
        kind: kind,
        stamp: readGuideMediaStamp(value['stamp']),
      ),
    );
  }

  final list = raw['list'];
  if (list is List) {
    for (var index = 0; index < list.length; index++) {
      add(index, list[index]);
    }
  } else if (list is Map) {
    list.forEach((key, value) {
      final index = int.tryParse(key.toString());
      if (index == null) return;
      add(index, value);
    });
  }
  changes.sort((a, b) => a.index.compareTo(b.index));
  return GuideChangeLog(count: count, changes: changes);
}

/// What one plant still needs from the phone's stamp to the latest stamp.
class GuideMediaJob {
  final int id;
  final bool added;
  final GuideMediaStamp stamp;
  final List<GuideMediaFile> download;
  final List<String> remove;

  const GuideMediaJob({
    required this.id,
    required this.added,
    required this.stamp,
    required this.download,
    required this.remove,
  });

  int get bytes {
    var total = 0;
    for (final file in download) {
      total += file.bytes;
    }
    return total;
  }
}

String encodeGuideStamps(Map<int, GuideMediaStamp> stamps) {
  final json = <String, Object>{};
  final ids = stamps.keys.toList()..sort();
  for (final id in ids) {
    json['$id'] = stamps[id]!.toJson();
  }
  return jsonEncode(json);
}

Map<int, GuideMediaStamp> decodeGuideStamps(String raw) {
  if (raw.isEmpty) return {};
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return {};
  final stamps = <int, GuideMediaStamp>{};
  decoded.forEach((key, value) {
    final id = int.tryParse(key.toString());
    if (id == null) return;
    stamps[id] = readGuideMediaStamp(value);
  });
  return stamps;
}
