/// What the running build should do about a newer store build.
enum VersionPrompt {
  /// This build may keep running.
  none,

  /// A newer build is on the store. The person can dismiss it.
  banner,

  /// This build is below the minimum. The guide stays closed.
  block,
}

class VersionFacts {
  /// `PackageInfo.buildNumber`. Zero when it cannot be read.
  final int build;

  /// Remote Config floor from a fetch that finished. Null when that fetch failed.
  final int? fetchedFloor;

  /// Last activated Remote Config floor, or 0 when nothing has been activated.
  final int cachedFloor;

  /// Floor that already closed this install. Zero when none was saved.
  final int rememberedFloor;

  /// `versions/android` or `versions/ios`. Null when the read failed.
  final int? storeBuild;

  /// Store build whose banner was dismissed. Zero when none was.
  final int dismissedStore;

  const VersionFacts({
    required this.build,
    required this.fetchedFloor,
    required this.cachedFloor,
    required this.rememberedFloor,
    required this.storeBuild,
    required this.dismissedStore,
  });
}

class VersionDecision {
  final VersionPrompt prompt;
  final int? storeBuild;

  /// Floor to save so a later launch with no network stays closed.
  final int? persistFloor;

  /// A finished fetch put this build back on the allowed side.
  final bool clearFloor;

  const VersionDecision({
    required this.prompt,
    this.storeBuild,
    this.persistFloor,
    this.clearFloor = false,
  });
}

/// A failed fetch must not unlock a build that was already below the floor.
/// A finished fetch with a lower floor does.
VersionDecision decideVersion(VersionFacts facts) {
  final build = facts.build;
  final int floor;
  var clearFloor = false;
  int? persistFloor;

  final fetched = facts.fetchedFloor;
  if (fetched != null) {
    floor = fetched;
    if (build > 0 && floor > build) {
      persistFloor = floor;
    } else if (facts.rememberedFloor > 0) {
      clearFloor = true;
    }
  } else {
    final remembered = facts.rememberedFloor;
    final cached = facts.cachedFloor;
    floor = cached > remembered ? cached : remembered;
    if (build > 0 && floor > build) {
      persistFloor = floor;
    }
  }

  if (build > 0 && floor > build) {
    return VersionDecision(
      prompt: VersionPrompt.block,
      storeBuild: facts.storeBuild,
      persistFloor: persistFloor,
    );
  }

  final store = facts.storeBuild;
  final showBanner = build > 0 &&
      store != null &&
      store > build &&
      facts.dismissedStore != store;
  return VersionDecision(
    prompt: showBanner ? VersionPrompt.banner : VersionPrompt.none,
    storeBuild: store,
    persistFloor: persistFloor,
    clearFloor: clearFloor,
  );
}
