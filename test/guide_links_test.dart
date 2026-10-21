import 'dart:io';

import 'package:abherbs_flutter/data/utils.dart';
import 'package:abherbs_flutter/shell/guide_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const name = 'Bellis perennis';

  test('a shared species url round-trips to the Latin name', () {
    final languages = <String>['en', 'nb', ...webPathLanguages];
    for (final lang in languages) {
      final uri = Uri.parse(webPlantUrl(name, lang));
      expect(plantNameFromSharedUrl(uri), name, reason: lang);
    }
  });

  test('a hybrid name keeps its multiplication sign', () {
    const hybrid = 'Citrus × aurantium';
    expect(
      plantNameFromSharedUrl(Uri.parse(webPlantUrl(hybrid, 'en'))),
      hybrid,
    );
  });

  test('the firebase host and a query language still open the species', () {
    expect(
      plantNameFromSharedUrl(Uri.parse(
        'https://abherbs-backend.web.app/plant/Bellis%20perennis/?lang=de',
      )),
      name,
    );
    expect(
      plantNameFromSharedUrl(Uri.parse(
        'https://whatsthatflower.com/en/plant/Bellis%20perennis/',
      )),
      name,
    );
  });

  test('other pages and hosts stay in the browser', () {
    expect(
      plantNameFromSharedUrl(
        Uri.parse('https://whatsthatflower.com/family/Rosaceae/'),
      ),
      isNull,
    );
    expect(
      plantNameFromSharedUrl(Uri.parse('https://whatsthatflower.com/de/')),
      isNull,
    );
    expect(
      plantNameFromSharedUrl(Uri.parse('https://whatsthatflower.com/plant/')),
      isNull,
    );
    expect(
      plantNameFromSharedUrl(
        Uri.parse('https://www.whatsthatflower.com/plant/Bellis%20perennis/'),
      ),
      isNull,
    );
    expect(
      plantNameFromSharedUrl(
        Uri.parse('https://example.com/plant/Bellis%20perennis/'),
      ),
      isNull,
    );
    expect(
      plantNameFromSharedUrl(
        Uri.parse('http://whatsthatflower.com/plant/Bellis%20perennis/'),
      ),
      isNull,
    );
  });

  test('android claims every indexed species path', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest.contains('android:pathPrefix="/plant/"'), isTrue);
    expect(manifest.contains('android:pathPrefix="/en/plant/"'), isTrue);
    for (final lang in webPathLanguages) {
      expect(
        manifest.contains('android:pathPrefix="/$lang/plant/"'),
        isTrue,
        reason: lang,
      );
    }
  });
}
