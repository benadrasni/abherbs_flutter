import 'package:abherbs_flutter/shell/guide_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a phone stays on the phone layout', () {
    final phone = GuideWindow.fromSize(const Size(390, 844));
    expect(phone.tablet, isFalse);
    expect(phone.wide, isFalse);

    final landscape = GuideWindow.fromSize(const Size(844, 390));
    expect(landscape.tablet, isFalse);

    final tests = GuideWindow.fromSize(const Size(800, 600));
    expect(tests.tablet, isFalse);
    expect(tests.wide, isFalse);
  });

  test('iPad portrait is a tablet and landscape is wide', () {
    final portrait = GuideWindow.fromSize(const Size(834, 1194));
    expect(portrait.tablet, isTrue);
    expect(portrait.wide, isFalse);
    expect(portrait.columns(phone: 2, tablet: 3, wide: 4), 3);

    final landscape = GuideWindow.fromSize(const Size(1194, 834));
    expect(landscape.tablet, isTrue);
    expect(landscape.wide, isTrue);
    expect(landscape.columns(phone: 2, tablet: 3, wide: 4), 4);

    final miniPortrait = GuideWindow.fromSize(const Size(744, 1133));
    expect(miniPortrait.tablet, isTrue);
    expect(miniPortrait.wide, isFalse);

    final miniLandscape = GuideWindow.fromSize(const Size(1133, 744));
    expect(miniLandscape.wide, isTrue);

    final proPortrait = GuideWindow.fromSize(const Size(1024, 1366));
    expect(proPortrait.tablet, isTrue);
    expect(proPortrait.wide, isTrue);
  });
}
