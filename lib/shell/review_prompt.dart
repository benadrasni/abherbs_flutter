import 'dart:io';

import 'package:abherbs_flutter/data/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Successes recorded before the first system review sheet.
const int reviewSuccessGoal = 4;

/// Pause on the finished screen before the sheet, so it does not cover the
/// tap that completed the work.
const Duration reviewPromptPause = Duration(seconds: 2);

/// Gap after an attempt. The stores also cap how often the sheet appears.
const Duration reviewPromptGap = Duration(days: 14);

const String _countKey = 'review_success_count';
const String _versionKey = 'review_prompted_version';
const String _atKey = 'review_prompted_at';

const String appStoreWriteReview =
    'https://apps.apple.com/app/id1449982118?action=write-review';

const String _playListing =
    'https://play.google.com/store/apps/details?id=sk.ab.herbs';

class ReviewLedger {
  final int count;
  final String promptedVersion;
  final int promptedAtMillis;

  const ReviewLedger({
    this.count = 0,
    this.promptedVersion = '',
    this.promptedAtMillis = 0,
  });
}

class ReviewPromptPlan {
  final ReviewLedger ledger;

  /// True when this success should try the system sheet.
  final bool ask;

  const ReviewPromptPlan({required this.ledger, required this.ask});
}

/// Counts one finished success. Asks once per app version, and only after
/// [reviewSuccessGoal] successes. A later version waits out [gap].
ReviewPromptPlan planReviewPrompt({
  required ReviewLedger ledger,
  required String version,
  required DateTime now,
  int goal = reviewSuccessGoal,
  Duration gap = reviewPromptGap,
}) {
  final count = ledger.count + 1;
  final current = version.trim();
  final elapsed = ledger.promptedAtMillis <= 0
      ? gap
      : Duration(
          milliseconds: now.millisecondsSinceEpoch - ledger.promptedAtMillis,
        );
  final ask = current.isNotEmpty &&
      count >= goal &&
      ledger.promptedVersion != current &&
      elapsed >= gap;
  return ReviewPromptPlan(
    ledger: ReviewLedger(
      count: count,
      promptedVersion: ledger.promptedVersion,
      promptedAtMillis: ledger.promptedAtMillis,
    ),
    ask: ask,
  );
}

class ReviewPromptGate {
  final Future<ReviewLedger> Function() read;
  final Future<void> Function(ReviewLedger ledger) write;
  final Future<String> Function() version;
  final Future<bool> Function() isAvailable;
  final Future<void> Function() requestReview;
  final Future<void> Function(Duration pause) delay;
  final DateTime Function() now;
  final Duration pause;
  final int goal;
  final Duration gap;

  ReviewPromptGate({
    required this.read,
    required this.write,
    required this.version,
    required this.isAvailable,
    required this.requestReview,
    required this.delay,
    required this.now,
    this.pause = reviewPromptPause,
    this.goal = reviewSuccessGoal,
    this.gap = reviewPromptGap,
  });

  Future<void> _tail = Future<void>.value();

  Future<void> note({required bool Function() stillHere}) {
    final run = _tail.then((_) => _step(stillHere));
    _tail = run.catchError((Object _) {});
    return run;
  }

  Future<void> _step(bool Function() stillHere) async {
    final ledger = await read();
    final current = (await version()).trim();
    final plan = planReviewPrompt(
      ledger: ledger,
      version: current,
      now: now(),
      goal: goal,
      gap: gap,
    );
    await write(plan.ledger);
    if (!plan.ask) return;
    await delay(pause);
    if (!stillHere()) return;
    if (!await isAvailable()) return;
    await write(ReviewLedger(
      count: plan.ledger.count,
      promptedVersion: current,
      promptedAtMillis: now().millisecondsSinceEpoch,
    ));
    await requestReview();
  }
}

/// System review sheet after a finished identification, and the store page
/// for the Person row. The row never calls the sheet: the stores may hide
/// it, and a button would then look broken.
class ReviewPrompt {
  static ReviewPromptGate? _gate;

  static ReviewPromptGate get gate {
    return _gate ??= ReviewPromptGate(
      read: readReviewLedger,
      write: writeReviewLedger,
      version: readReviewVersion,
      isAvailable: () => InAppReview.instance.isAvailable(),
      requestReview: () => InAppReview.instance.requestReview(),
      delay: Future<void>.delayed,
      now: DateTime.now,
    );
  }

  static Future<void> note({required bool Function() stillHere}) async {
    try {
      await gate.note(stillHere: stillHere);
    } catch (error) {
      debugPrint('review prompt: $error');
    }
  }
}

Future<ReviewLedger> readReviewLedger() async {
  final prefs = await SharedPreferences.getInstance();
  return ReviewLedger(
    count: prefs.getInt(_countKey) ?? 0,
    promptedVersion: prefs.getString(_versionKey) ?? '',
    promptedAtMillis: prefs.getInt(_atKey) ?? 0,
  );
}

Future<void> writeReviewLedger(ReviewLedger ledger) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_countKey, ledger.count);
  await prefs.setString(_versionKey, ledger.promptedVersion);
  await prefs.setInt(_atKey, ledger.promptedAtMillis);
}

Future<String> readReviewVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

/// Opens the store write-review page. iOS uses Apple's `action=write-review`
/// link. Android opens the Play listing.
Future<bool> openWriteReview() async {
  try {
    if (Platform.isIOS || Platform.isMacOS) {
      return await _launch(appStoreWriteReview);
    }
    if (await _launch(playStore)) return true;
    return await _launch(_playListing);
  } catch (error) {
    debugPrint('write review: $error');
    return false;
  }
}

Future<bool> _launch(String path) {
  return launchUrl(Uri.parse(path), mode: LaunchMode.externalApplication);
}
