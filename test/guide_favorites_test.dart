import 'package:abherbs_flutter/data/guide_favorites.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a favorites map is the plant ids', () {
    expect(
      guideFavoriteIdsFrom({'12': 1, '3': 1, 'gone': null}),
      {'3', '12'},
    );
    expect(guideFavoriteIdsFrom(null), isEmpty);
    expect(guideFavoriteIdsFrom({'0': 1}), {'0'});
  });
}
