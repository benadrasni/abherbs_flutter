import 'package:abherbs_flutter/data/guide_results.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GuideResultPlant plant(String name, {String? label}) {
    return GuideResultPlant(
      id: '1',
      name: name,
      label: label,
      photoPath: null,
      platePath: null,
      floweringFrom: 1,
      floweringTo: 12,
      cultivated: false,
    );
  }

  test('the Latin line is only for a vernacular title', () {
    final daisy = plant('Bellis perennis', label: 'Daisy');
    expect(daisy.hasVernacular, isTrue);
    expect(daisy.shownName, 'Daisy');

    final latin = plant('Bellis perennis');
    expect(latin.hasVernacular, isFalse);
    expect(latin.shownName, 'Bellis perennis');

    final blank = plant('Bellis perennis', label: '');
    expect(blank.hasVernacular, isFalse);
    expect(blank.shownName, 'Bellis perennis');
  });
}
