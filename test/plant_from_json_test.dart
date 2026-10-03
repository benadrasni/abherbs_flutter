import 'package:abherbs_flutter/data/plant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Plant.fromJson uses an empty map when wikilinks is missing', () {
    final plant = Plant.fromJson('Acer campestre', <dynamic, dynamic>{
      'id': 0,
      'name': 'Acer campestre',
      'author': 'L.',
      'floweringFrom': 5,
      'floweringTo': 6,
      'APGIV': <dynamic, dynamic>{
        '00_Genus': 'Acer',
        '02_Familia': 'Sapindaceae',
      },
    });

    expect(plant.name, 'Acer campestre');
    expect(plant.floweringFrom, 5);
    expect(plant.floweringTo, 6);
    expect(plant.wikiLinks, isEmpty);
    expect(plant.wikiLinks.values, isEmpty);
  });

  test('Plant.fromJson keeps a missing floweringTo as 0', () {
    final plant = Plant.fromJson('Acer campestre', <dynamic, dynamic>{
      'id': 0,
      'name': 'Acer campestre',
      'floweringFrom': 5,
      'wikilinks': <dynamic, dynamic>{
        'data': 'https://www.wikidata.org/wiki/Q157810',
      },
      'APGIV': <dynamic, dynamic>{
        '00_Genus': 'Acer',
      },
    });

    expect(plant.floweringTo, 0);
    expect(plant.wikiLinks['data'], 'https://www.wikidata.org/wiki/Q157810');
  });
}
