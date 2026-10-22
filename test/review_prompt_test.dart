import 'dart:async';

import 'package:abherbs_flutter/shell/review_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the first three successes stay quiet', () {
    final now = DateTime(2026, 10, 1);
    var ledger = const ReviewLedger();
    for (var i = 0; i < 3; i++) {
      final plan = planReviewPrompt(
        ledger: ledger,
        version: '9.1.0',
        now: now,
      );
      expect(plan.ask, isFalse);
      ledger = plan.ledger;
    }
    expect(ledger.count, 3);
    expect(ledger.promptedVersion, isEmpty);
  });

  test('the fourth success on a version may ask', () {
    final plan = planReviewPrompt(
      ledger: const ReviewLedger(count: 3),
      version: '9.1.0',
      now: DateTime(2026, 10, 1),
    );
    expect(plan.ask, isTrue);
    expect(plan.ledger.count, 4);
    expect(plan.ledger.promptedVersion, isEmpty);
  });

  test('the same version does not ask again', () {
    final plan = planReviewPrompt(
      ledger: const ReviewLedger(
        count: 4,
        promptedVersion: '9.1.0',
        promptedAtMillis: 0,
      ),
      version: ' 9.1.0 ',
      now: DateTime(2026, 10, 20),
    );
    expect(plan.ask, isFalse);
  });

  test('a new version waits two weeks', () {
    final asked = DateTime(2026, 10, 1);
    final ledger = ReviewLedger(
      count: 4,
      promptedVersion: '9.1.0',
      promptedAtMillis: asked.millisecondsSinceEpoch,
    );
    expect(
      planReviewPrompt(
        ledger: ledger,
        version: '9.2.0',
        now: asked.add(const Duration(days: 13)),
      ).ask,
      isFalse,
    );
    expect(
      planReviewPrompt(
        ledger: ledger,
        version: '9.2.0',
        now: asked.add(reviewPromptGap),
      ).ask,
      isTrue,
    );
  });

  test('an empty version does not ask', () {
    const ledger = ReviewLedger(count: 8);
    final now = DateTime(2026, 10, 1);
    expect(
      planReviewPrompt(ledger: ledger, version: ' ', now: now).ask,
      isFalse,
    );
  });

  test('a pause that the person leaves does not open the sheet', () async {
    final gate = _gate();
    final pending = gate.note(stillHere: () => false);
    await pumpEventQueue();
    expect(_Harness.pauses, 1);
    expect(_Harness.ledger.count, reviewSuccessGoal);
    _Harness.release();
    await pending;
    expect(_Harness.requests, 0);
    expect(_Harness.ledger.promptedVersion, isEmpty);
  });

  test('a settled success opens the sheet once for that version', () async {
    final gate = _gate();
    final first = gate.note(stillHere: () => true);
    final second = gate.note(stillHere: () => true);
    await pumpEventQueue();
    expect(_Harness.pauses, 1);
    _Harness.release();
    await first;
    await second;
    expect(_Harness.requests, 1);
    expect(_Harness.ledger.promptedVersion, '9.1.0');
    expect(_Harness.ledger.count, reviewSuccessGoal + 1);
    expect(
      _Harness.ledger.promptedAtMillis,
      _Harness.clock.millisecondsSinceEpoch,
    );
  });

  test('a hidden sheet keeps the version free for a later success', () async {
    final gate = _gate(available: false);
    final first = gate.note(stillHere: () => true);
    await pumpEventQueue();
    _Harness.release();
    await first;
    expect(_Harness.requests, 0);
    expect(_Harness.ledger.promptedVersion, isEmpty);
    expect(_Harness.ledger.count, reviewSuccessGoal);

    _Harness.available = true;
    final second = gate.note(stillHere: () => true);
    await pumpEventQueue();
    _Harness.release();
    await second;
    expect(_Harness.requests, 1);
    expect(_Harness.ledger.promptedVersion, '9.1.0');
  });
}

class _Harness extends ReviewPromptGate {
  _Harness()
      : super(
          read: () async => ledger,
          write: (next) async => ledger = next,
          version: () async => '9.1.0',
          isAvailable: () async => available,
          requestReview: () async => requests++,
          delay: (pause) {
            expect(pause, reviewPromptPause);
            pauses++;
            final done = Completer<void>();
            hold = done;
            return done.future;
          },
          now: () => clock,
        );

  static ReviewLedger ledger = const ReviewLedger(count: 3);
  static bool available = true;
  static int requests = 0;
  static int pauses = 0;
  static Completer<void>? hold;
  static final DateTime clock = DateTime(2026, 10, 21);

  static void release() {
    final done = hold;
    if (done != null && !done.isCompleted) done.complete();
  }
}

ReviewPromptGate _gate({bool available = true}) {
  _Harness.ledger = const ReviewLedger(count: reviewSuccessGoal - 1);
  _Harness.available = available;
  _Harness.requests = 0;
  _Harness.pauses = 0;
  _Harness.hold = null;
  return _Harness();
}
