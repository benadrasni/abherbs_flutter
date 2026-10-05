import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/data/prefs.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:abherbs_flutter/shell/app_version.dart';
import 'package:abherbs_flutter/shell/settings_remote.dart';
import 'package:abherbs_flutter/shell/version_gate.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

const Duration versionCheckTimeout = Duration(seconds: 5);

/// Closes the guide before the first frame when this install was already
/// below the floor. A first launch, or a failed read, leaves it open.
Future<void> applyRememberedVersionBlock() async {
  try {
    final build = await readAppBuildNumber();
    final local = decideVersion(await readLocalVersionFacts(build));
    if (local.prompt == VersionPrompt.block) {
      VersionGateController.instance.apply(VersionPrompt.block);
    }
  } catch (error) {
    debugPrint('version check: $error');
  }
}

Future<int> readAppBuildNumber() async {
  try {
    final info = await PackageInfo.fromPlatform().timeout(versionCheckTimeout);
    return int.tryParse(info.buildNumber) ?? 0;
  } catch (error) {
    debugPrint('app build: $error');
    return 0;
  }
}

Future<VersionFacts> readLocalVersionFacts(int build) async {
  final remembered = await Prefs.getIntF(keyVersionBlockFloor, 0);
  final dismissed = await Prefs.getIntF(keyVersionBannerDismissed, 0);
  return VersionFacts(
    build: build,
    fetchedFloor: null,
    cachedFloor: 0,
    rememberedFloor: remembered,
    storeBuild: null,
    dismissedStore: dismissed,
  );
}

Future<VersionFacts> readFreshVersionFacts(int build) async {
  final android = Platform.isAndroid;
  final fetched = RemoteConfiguration.fetchMinBuild(android: android);
  final store = _readStoreBuild(android: android);
  final remembered = Prefs.getIntF(keyVersionBlockFloor, 0);
  final dismissed = Prefs.getIntF(keyVersionBannerDismissed, 0);
  final results = await Future.wait<Object?>([
    fetched,
    store,
    remembered,
    dismissed,
  ]);
  return VersionFacts(
    build: build,
    fetchedFloor: results[0] as int?,
    cachedFloor: RemoteConfiguration.cachedMinBuild(android: android),
    rememberedFloor: results[2] as int,
    storeBuild: results[1] as int?,
    dismissedStore: results[3] as int,
  );
}

Future<void> persistVersionDecision(VersionDecision decision) async {
  if (decision.clearFloor) {
    await Prefs.remove(keyVersionBlockFloor);
    return;
  }
  final floor = decision.persistFloor;
  if (floor != null) {
    await Prefs.setInt(keyVersionBlockFloor, floor);
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

Future<int?> _readStoreBuild({required bool android}) async {
  try {
    final event = await rootReference
        .child(firebaseVersions)
        .child(android ? firebaseAttributeAndroid : firebaseAttributeIOS)
        .once()
        .timeout(versionCheckTimeout);
    return _asInt(event.snapshot.value);
  } catch (error) {
    debugPrint('store version: $error');
    return null;
  }
}
