import 'package:abherbs_flutter/detail/plant_detail_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uniqueSourceUrls drops empty values and duplicate hosts', () {
    expect(
      uniqueSourceUrls([
        'https://en.wikipedia.org/wiki/Buddleja_davidii',
        'https://www.efloras.org/florataxon.aspx?flora_id=2&taxon_id=200018861',
        'http://www.efloras.org/other',
        null,
        '',
        'https://powo.science.kew.org/taxon/123',
      ]),
      [
        'https://en.wikipedia.org/wiki/Buddleja_davidii',
        'https://www.efloras.org/florataxon.aspx?flora_id=2&taxon_id=200018861',
        'https://powo.science.kew.org/taxon/123',
      ],
    );
  });

  test('sourceHost strips www', () {
    expect(sourceHost('https://www.infoflora.ch/de/flora/123.html'), 'infoflora.ch');
    expect(sourceHost('https://botany.cz/cs/foo/'), 'botany.cz');
  });
}
