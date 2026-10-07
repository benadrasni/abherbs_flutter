import 'package:abherbs_flutter/camera/plant_id_search.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supported locales cover the photo-search keys', () {
    final keys = photoSearchLanguageKeys(S.delegate.supportedLocales);
    final languages = S.delegate.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();

    expect(keys, containsAll(['en-GB', 'en-US', 'tr-TR', 'zh-TW']));
    expect(keys, containsAll(languages));
    expect(keys.where((key) => key.contains('_')), isEmpty);
    expect(keys.length, keys.toSet().length);
    expect(keys, [...keys]..sort());

    const uid = 'user';
    expect(
      [
        for (final key in keys) 'users_photo_search/$key/$uid',
      ],
      containsAll([
        'users_photo_search/en-GB/user',
        'users_photo_search/en-US/user',
        'users_photo_search/tr-TR/user',
        'users_photo_search/zh-TW/user',
        'users_photo_search/en/user',
        'users_photo_search/tr/user',
        'users_photo_search/zh/user',
      ]),
    );
  });
}
