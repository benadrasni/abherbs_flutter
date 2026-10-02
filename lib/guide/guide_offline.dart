import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';

/// Pictures per species: photos, the large plate, the small plate, and the
/// range map. Measured on a 36-species sample.
const guideOfflineMbPerPlant = 0.73;

/// A whole book of this many species is the "about 1.0 GB" line.
const guideOfflineBookPlants = 1433;

class GuideOfflineGroup {
  final String id;
  final List<String> codes;

  const GuideOfflineGroup(this.id, this.codes);
}

/// Floristic packs. Antarctic is left out: no species lives only there.
const guideOfflineGroups = <GuideOfflineGroup>[
  GuideOfflineGroup('1', ['10', '11', '12', '13', '14']),
  GuideOfflineGroup(
      '2', ['20', '21', '22', '23', '24', '25', '26', '27', '28', '29']),
  GuideOfflineGroup(
      '3', ['30', '31', '32', '33', '34', '35', '36', '37', '38']),
  GuideOfflineGroup('4', ['40', '41', '42', '43']),
  GuideOfflineGroup('5', ['50', '51']),
  GuideOfflineGroup('6', ['60', '61', '62', '63']),
  GuideOfflineGroup(
      '7', ['70', '71', '72', '73', '74', '75', '76', '77', '78', '79']),
  GuideOfflineGroup('8', ['80', '81', '82', '83', '84', '85']),
];

final Set<String> guideOfflinePackCodes = {
  for (final group in guideOfflineGroups) ...group.codes,
};

/// One entry per catalog plant: the level-2 codes where it occurs.
class GuideOfflineCatalog {
  final List<Set<String>> plants;

  const GuideOfflineCatalog(this.plants);

  int get total => plants.length;

  static const empty = GuideOfflineCatalog([]);
}

GuideOfflineCatalog readGuideOfflineCatalog(dynamic raw) {
  final plants = <Set<String>>[];
  void add(dynamic value) {
    if (value is! Map) return;
    final name = value[firebaseAttributeName];
    if (name is! String || name.isEmpty) return;
    plants.add(_codes(value['filterDistribution']));
  }

  if (raw is List) {
    for (final value in raw) {
      add(value);
    }
  } else if (raw is Map) {
    raw.forEach((_, value) => add(value));
  }
  return GuideOfflineCatalog(plants);
}

Set<String> _codes(dynamic raw) {
  final codes = <String>{};
  void add(dynamic value) {
    final code = _code(value);
    if (code != null) codes.add(code);
  }

  if (raw is List) {
    for (final value in raw) {
      add(value);
    }
  } else if (raw is Map) {
    raw.forEach((_, value) => add(value));
  }
  return codes;
}

String? _code(dynamic value) {
  if (value is int) return '$value';
  if (value is num && value == value.roundToDouble()) return '${value.toInt()}';
  if (value is String && value.isNotEmpty) return value;
  return null;
}

/// Null means the whole book. An empty set matches nothing.
int guideOfflineMatch(GuideOfflineCatalog catalog, Set<String>? codes) {
  if (codes == null) return catalog.total;
  if (codes.isEmpty) return 0;
  var count = 0;
  for (final plant in catalog.plants) {
    for (final code in plant) {
      if (codes.contains(code)) {
        count++;
        break;
      }
    }
  }
  return count;
}

Set<String>? guideOfflineUnion(Set<String>? a, Set<String>? b) {
  if (a == null || b == null) return null;
  return {...a, ...b};
}

/// Rounded picture size. At 1,000 MB and above the text is gigabytes.
class GuideOfflineSize {
  final bool gigabytes;
  final String amount;

  const GuideOfflineSize._(this.gigabytes, this.amount);

  static GuideOfflineSize of(int plants) {
    final mb = plants * guideOfflineMbPerPlant;
    if (mb >= 1000) {
      final tenths = (mb / 100).round();
      return GuideOfflineSize._(true, (tenths / 10).toStringAsFixed(1));
    }
    final rounded = (mb / 10).round() * 10;
    return GuideOfflineSize._(false, '$rounded');
  }

  /// Megabytes shown on a download bar. A gigabyte size stays in megabytes
  /// here so the bar can move in the same unit as the bytes already fetched.
  int get barMb {
    if (!gigabytes) return int.parse(amount);
    return (double.parse(amount) * 1000).round();
  }
}

class GuideOfflineLabel {
  final bool everything;
  final String? regionId;
  final String? groupId;
  final int count;

  const GuideOfflineLabel._({
    required this.everything,
    required this.regionId,
    required this.groupId,
    required this.count,
  });

  const GuideOfflineLabel.everything()
      : this._(everything: true, regionId: null, groupId: null, count: 0);

  const GuideOfflineLabel.region(String id)
      : this._(everything: false, regionId: id, groupId: null, count: 1);

  const GuideOfflineLabel.group(String id)
      : this._(everything: false, regionId: null, groupId: id, count: 0);

  const GuideOfflineLabel.count(int count)
      : this._(
          everything: false,
          regionId: null,
          groupId: null,
          count: count,
        );
}

GuideOfflineLabel guideOfflineLabel(Set<String>? codes) {
  if (codes == null) return const GuideOfflineLabel.everything();
  if (codes.length == 1) return GuideOfflineLabel.region(codes.first);
  for (final group in guideOfflineGroups) {
    if (group.codes.length == codes.length &&
        group.codes.every(codes.contains)) {
      return GuideOfflineLabel.group(group.id);
    }
  }
  return GuideOfflineLabel.count(codes.length);
}

/// The level-2 code that holds most of a continent, when it is more than
/// three fifths of that continent's plants.
String? guideOfflineOverlap(GuideOfflineCatalog catalog, List<String> codes) {
  final all = guideOfflineMatch(catalog, codes.toSet());
  if (all <= 0) return null;
  String? best;
  var bestCount = 0;
  for (final code in codes) {
    final count = guideOfflineMatch(catalog, {code});
    if (count > bestCount) {
      bestCount = count;
      best = code;
    }
  }
  if (best != null && bestCount > all * 0.6) return best;
  return null;
}

class GuideOfflinePick {
  final bool everything;
  final Set<String> regions;

  const GuideOfflinePick({
    this.everything = false,
    this.regions = const {},
  });

  bool get chosen => everything || regions.isNotEmpty;

  Set<String>? get asCodes => everything ? null : regions;

  GuideOfflinePick toggleEverything() {
    return GuideOfflinePick(everything: !everything);
  }

  GuideOfflinePick toggleGroup(List<String> codes) {
    if (everything) return GuideOfflinePick(regions: codes.toSet());
    final next = {...regions};
    if (codes.every(next.contains)) {
      next.removeAll(codes);
    } else {
      next.addAll(codes);
    }
    return GuideOfflinePick(regions: next);
  }

  GuideOfflinePick toggleRegion(String code) {
    if (everything) return GuideOfflinePick(regions: {code});
    final next = {...regions};
    if (!next.add(code)) next.remove(code);
    return GuideOfflinePick(regions: next);
  }

  bool groupOn(List<String> codes) {
    return everything || (codes.isNotEmpty && codes.every(regions.contains));
  }

  bool groupMid(List<String> codes) {
    if (everything || groupOn(codes)) return false;
    return codes.any(regions.contains);
  }

  bool regionOn(String code) => everything || regions.contains(code);
}

class GuideOfflineStored {
  final bool everything;
  final Set<String> regions;

  const GuideOfflineStored({
    this.everything = false,
    this.regions = const {},
  });

  const GuideOfflineStored.everything() : this(everything: true);

  bool get isEmpty => !everything && regions.isEmpty;

  Set<String>? get asCodes =>
      everything ? null : (regions.isEmpty ? {} : regions);

  bool covers(String code) => everything || regions.contains(code);
}

GuideOfflineStored guideOfflineStoredFrom(
  String packs, {
  required bool classic,
}) {
  if (classic || packs == 'all') return const GuideOfflineStored.everything();
  final regions = <String>{
    for (final part in packs.split(','))
      if (guideOfflinePackCodes.contains(part)) part,
  };
  return GuideOfflineStored(regions: regions);
}

String guideOfflinePacksValue(GuideOfflineStored stored) {
  if (stored.everything) return 'all';
  final codes = stored.regions.toList()..sort();
  return codes.join(',');
}

class GuideOfflineRequest {
  final bool everything;
  final Set<String> regions;
  final int added;
  final String title;

  const GuideOfflineRequest({
    required this.everything,
    required this.regions,
    required this.added,
    required this.title,
  });
}

class GuideOfflineJob {
  final String title;
  final int plants;
  final int doneMb;
  final int totalMb;

  const GuideOfflineJob({
    required this.title,
    required this.plants,
    required this.doneMb,
    required this.totalMb,
  });

  double get fraction {
    if (totalMb <= 0) return 0;
    return (doneMb / totalMb).clamp(0, 1).toDouble();
  }
}

enum GuideOfflineMenuKind { legacy, upsell, empty, book, stored }

class GuideOfflineHold {
  final bool canDownload;
  final bool everything;
  final int storedPlants;
  final int totalPlants;
  final List<String> regionIds;

  const GuideOfflineHold({
    required this.canDownload,
    required this.everything,
    required this.storedPlants,
    required this.totalPlants,
    this.regionIds = const [],
  });
}

GuideOfflineMenuKind guideOfflineMenuKind(GuideOfflineHold? hold) {
  if (hold == null) return GuideOfflineMenuKind.legacy;
  if (hold.everything) return GuideOfflineMenuKind.book;
  if (hold.regionIds.isNotEmpty || hold.storedPlants > 0) {
    return GuideOfflineMenuKind.stored;
  }
  if (!hold.canDownload) return GuideOfflineMenuKind.upsell;
  return GuideOfflineMenuKind.empty;
}

class GuideOfflineView {
  final GuideOfflineCatalog catalog;
  final bool canDownload;
  final GuideOfflineStored stored;
  final String? phoneRegionId;

  const GuideOfflineView({
    required this.catalog,
    required this.canDownload,
    required this.stored,
    required this.phoneRegionId,
  });
}

Future<GuideOfflineView> loadGuideOffline() async {
  final snapshot = await headersV3Reference.get();
  final catalog = readGuideOfflineCatalog(snapshot.value);
  final packs = await Prefs.getStringF(keyGuideOfflinePacks, '');
  final classic = await Prefs.getBoolF(keyOffline, false);
  final stored = guideOfflineStoredFrom(packs, classic: classic);
  final guideRegion = await Prefs.getStringF(keyGuideRegion, '');
  final myRegion = guideRegion.isEmpty
      ? await Prefs.getStringF(keyMyRegion, '')
      : guideRegion;
  final phone = guideOfflinePackCodes.contains(myRegion) ? myRegion : null;
  await Prefs.setString(keyGuideOfflineTotal, '${catalog.total}');
  if (!stored.isEmpty) {
    final plants = guideOfflineMatch(
      catalog,
      stored.everything ? null : stored.regions,
    );
    await Prefs.setString(keyGuideOfflineStoredPlants, '$plants');
  }
  return GuideOfflineView(
    catalog: catalog,
    canDownload: Purchases.hasFieldGuide() || Purchases.isOffline(),
    stored: stored,
    phoneRegionId: phone,
  );
}

Future<GuideOfflineHold> loadGuideOfflineHold() async {
  final packs = await Prefs.getStringF(keyGuideOfflinePacks, '');
  final classic = await Prefs.getBoolF(keyOffline, false);
  final stored = guideOfflineStoredFrom(packs, classic: classic);
  final total =
      int.tryParse(await Prefs.getStringF(keyGuideOfflineTotal, '')) ?? 0;
  final storedPlants =
      int.tryParse(await Prefs.getStringF(keyGuideOfflineStoredPlants, '')) ??
          0;
  final plants = stored.everything
      ? (storedPlants > 0 ? storedPlants : total)
      : storedPlants;
  final regions = stored.regions.toList()..sort();
  return GuideOfflineHold(
    canDownload: Purchases.hasFieldGuide() || Purchases.isOffline(),
    everything: stored.everything,
    storedPlants: plants,
    totalPlants: total,
    regionIds: regions,
  );
}

enum GuideOfflineStart { started, needsWifi, skipped }

/// Starts the whole-book picture download. A floristic region is not started:
/// the downloader stores every plant, so a region tap must not use it.
Future<GuideOfflineStart> startGuideOfflineDownload({
  required GuideOfflineRequest request,
  required void Function(int done, int total) onProgress,
  required void Function() onFinished,
  required void Function() onFailed,
  Future<List<ConnectivityResult>> Function()? connectivity,
}) async {
  if (!request.everything) return GuideOfflineStart.skipped;
  final result = await (connectivity ?? Connectivity().checkConnectivity)();
  if (!result.contains(ConnectivityResult.wifi)) {
    return GuideOfflineStart.needsWifi;
  }
  Offline.downloadPaused = false;
  Offline.onChange(true);
  await Prefs.setBool(keyOffline, true);
  await Prefs.setString(keyGuideOfflinePacks, 'all');
  Offline.download(
    (_, __) {},
    onProgress,
    () {
      Prefs.setString(keyGuideOfflineStoredPlants, '${request.added}');
      onFinished();
    },
    onFailed,
  );
  return GuideOfflineStart.started;
}

Future<void> clearGuideOfflinePack() async {
  await Prefs.remove(keyOffline);
  await Prefs.remove(keyGuideOfflinePacks);
  await Prefs.remove(keyGuideOfflineStoredPlants);
  Offline.onChange(false);
  await Offline.delete();
}
