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

  test('sourceButtonLook uses site icons for the new floras', () {
    expect(
      sourceButtonLook('https://www.infoflora.ch/en/flora/acer-campestre.html').image,
      'res/images/infoflora.png',
    );
    expect(sourceButtonLook('https://pladias.cz/en/taxon/data/Acer%20campestre').image, 'res/images/pladias.png');
    expect(
      sourceButtonLook('https://gobotany.nativeplanttrust.org/species/achillea/millefolium/').image,
      'res/images/gobotany.png',
    );
    expect(sourceButtonLook('https://bsbi.org/taxon/acer-campestre').image, 'res/images/bsbi.png');
    expect(
      sourceButtonLook('https://burkeherbarium.org/imagecollection/taxon.php?Taxon=Acer+platanoides').image,
      'res/images/burke.png',
    );
    expect(
      sourceButtonLook('http://biology.burke.washington.edu/herbarium/imagecollection/taxon.php?Taxon=Penstemon').image,
      'res/images/burke.png',
    );
    expect(sourceButtonLook('https://pfaf.org/user/plant.aspx?latinname=Acer+campestre').image, 'res/images/internet.png');
  });
}
