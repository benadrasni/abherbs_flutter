import 'package:abherbs_flutter/camera/plant_id_search.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = <Locale>[
    Locale('en'),
    Locale('en', 'GB'),
    Locale('en', 'US'),
    Locale('de', 'DE'),
    Locale('nb', 'NO'),
    Locale('tr', 'TR'),
    Locale('zh', 'TW'),
  ];

  test('deletion paths use the full tag photo search writes', () {
    expect(
      photoSearchDeletionPaths('uid-1', supportedLocales: supported),
      [
        'users_photo_search/de/uid-1',
        'users_photo_search/de-DE/uid-1',
        'users_photo_search/en/uid-1',
        'users_photo_search/en-GB/uid-1',
        'users_photo_search/en-US/uid-1',
        'users_photo_search/nb/uid-1',
        'users_photo_search/nb-NO/uid-1',
        'users_photo_search/tr/uid-1',
        'users_photo_search/tr-TR/uid-1',
        'users_photo_search/zh/uid-1',
        'users_photo_search/zh-TW/uid-1',
      ],
    );
  });

  test('a saved en_UK tag is deleted as en-GB', () {
    final paths = photoSearchDeletionPaths(
      'uid-1',
      supportedLocales: const [Locale('en', 'US')],
      preferredLanguageTag: 'en_UK',
    );
    expect(paths, contains('users_photo_search/en-GB/uid-1'));
    expect(paths, contains('users_photo_search/en/uid-1'));
    expect(paths, contains('users_photo_search/en-US/uid-1'));
    expect(paths, isNot(contains('users_photo_search/en_GB/uid-1')));
    expect(paths, isNot(contains('users_photo_search/en_UK/uid-1')));
    expect(paths, isNot(contains('users_photo_search/en-UK/uid-1')));
  });

  test('an empty saved language adds no extra path', () {
    expect(
      photoSearchDeletionPaths(
        'uid-1',
        supportedLocales: const [Locale('sk', 'SK')],
        preferredLanguageTag: '',
      ),
      [
        'users_photo_search/sk/uid-1',
        'users_photo_search/sk-SK/uid-1',
      ],
    );
  });

  test('the app locales cover en-GB and tr-TR', () {
    final paths = photoSearchDeletionPaths(
      'user',
      supportedLocales: S.delegate.supportedLocales,
      preferredLanguageTag: 'tr_TR',
    );
    expect(paths, contains('users_photo_search/en-GB/user'));
    expect(paths, contains('users_photo_search/en-US/user'));
    expect(paths, contains('users_photo_search/en/user'));
    expect(paths, contains('users_photo_search/tr-TR/user'));
    expect(paths, contains('users_photo_search/tr/user'));
    expect(paths, contains('users_photo_search/zh-TW/user'));
    final tags = paths.map((path) => path.split('/')[1]);
    expect(tags.where((tag) => tag.contains('_')), isEmpty);
    expect(paths.toSet().length, paths.length);
  });
}
