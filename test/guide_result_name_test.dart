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

  test('a label that repeats the Latin name is not a vernacular', () {
    expect(distinctVernacular('Daisy', 'Bellis perennis'), 'Daisy');
    expect(distinctVernacular('  Daisy ', 'Bellis perennis'), 'Daisy');
    expect(distinctVernacular('Bellis perennis', 'Bellis perennis'), isNull);
    expect(distinctVernacular('  bellis perennis ', 'Bellis perennis'), isNull);
    expect(distinctVernacular(null, 'Bellis perennis'), isNull);
    expect(distinctVernacular('  ', 'Bellis perennis'), isNull);

    expect(plant('Bellis perennis', label: 'Daisy').shownName, 'Daisy');
    expect(
      plant('Bellis perennis', label: 'Bellis perennis').shownName,
      'Bellis perennis',
    );
    expect(plant('Bellis perennis').shownName, 'Bellis perennis');
  });
}
