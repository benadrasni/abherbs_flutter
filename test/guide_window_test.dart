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

    // 12.9-inch and 13-inch portrait are both past 1000 points, and still
    // stay on the tablet layout so rotation can reach the sidebar.
    final proPortrait = GuideWindow.fromSize(const Size(1024, 1366));
    expect(proPortrait.tablet, isTrue);
    expect(proPortrait.wide, isFalse);

    final pro13Portrait = GuideWindow.fromSize(const Size(1032, 1376));
    expect(pro13Portrait.tablet, isTrue);
    expect(pro13Portrait.wide, isFalse);
    expect(pro13Portrait.columns(phone: 2, tablet: 3, wide: 4), 3);

    final pro13Landscape = GuideWindow.fromSize(const Size(1376, 1032));
    expect(pro13Landscape.tablet, isTrue);
    expect(pro13Landscape.wide, isTrue);
    expect(pro13Landscape.columns(phone: 2, tablet: 3, wide: 4), 4);
  });
}
