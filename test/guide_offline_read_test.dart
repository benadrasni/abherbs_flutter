import 'dart:async';

import 'package:abherbs_flutter/data/guide_data.dart';
import 'package:abherbs_flutter/search/guide_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a dead read uses the pack, and a pack that fails is the error',
      () async {
    var online = 0;
    var pack = 0;
    final value = await guideReadOrPack(
      () async {
        online++;
        return 'server';
      },
      () async {
        pack++;
        return 'pack';
      },
      wait: const Duration(milliseconds: 200),
    );
    expect(value, 'server');
    expect(online, 1);
    expect(pack, 0);

    final fellBack = await guideReadOrPack(
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return 'server';
      },
      () async => 'pack',
      wait: const Duration(milliseconds: 10),
      label: 'guide test',
    );
    expect(fellBack, 'pack');

    await expectLater(
      guideReadOrPack<String>(
        () async => throw StateError('down'),
        () async => throw StateError('no pack'),
        wait: const Duration(milliseconds: 20),
        label: 'guide test',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('a label load is only returned for its language', () async {
    debugResetPhoneLabels();
    addTearDown(debugResetPhoneLabels);
    var reads = 0;
    final pending = <String, Completer<Map<String, String>>>{};
    debugReadPhoneLabels = (language) {
      reads++;
      final gate = Completer<Map<String, String>>();
      pending[language] = gate;
      return gate.future;
    };

    final german = debugPhoneLabelsFor('de');
    final english = debugPhoneLabelsFor('en');
    final again = debugPhoneLabelsFor('en');
    expect(reads, 2);

    pending['en']!.complete({'Bellis perennis': 'en-name'});
    expect(await english, {'Bellis perennis': 'en-name'});
    expect(await again, {'Bellis perennis': 'en-name'});

    pending['de']!.complete({'Bellis perennis': 'de-name'});
    expect(await german, {'Bellis perennis': 'de-name'});

    expect(await debugPhoneLabelsFor('en'), {'Bellis perennis': 'en-name'});
    expect(reads, 2);
  });
}
