import 'package:abherbs_flutter/data/guide_data.dart';
import 'package:abherbs_flutter/seen/guide_seen.dart';
import 'package:abherbs_flutter/seen/observation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(resetGuideSeenCatalogCache);
  tearDown(resetGuideSeenCatalogCache);

  test('a failed in-book lookup stays unknown and the next pass retries',
      () async {
    var calls = 0;
    guideSeenLabelRead = (name, code) async => 'daisy';
    guideSeenPhotoRead = (name) async => 'bellis.jpg';
    guideSeenInBookRead = (name) async {
      calls++;
      if (calls == 1) throw StateError('offline');
      return true;
    };

    final row = _row('Bellis perennis');
    final first = await decorateGuideSeen([row], 'en', clouds: {});
    expect(first.single.catalogKnown, isFalse);
    expect(first.single.inBook, isFalse);
    expect(first.single.label, isNull);
    expect(first.single.photoPath, isNull);
    expect(guideSeenChip(first.single), isNull);
    expect(guideSeenDecorateSettled(first), isFalse);

    final second = await decorateGuideSeen([row], 'en', clouds: {});
    expect(calls, 2);
    expect(second.single.catalogKnown, isTrue);
    expect(second.single.inBook, isTrue);
    expect(second.single.label, 'daisy');
    expect(second.single.photoPath, 'photos/bellis.jpg');
    expect(guideSeenDecorateSettled(second), isTrue);

    await decorateGuideSeen([row], 'en', clouds: {});
    expect(calls, 2);
  });

  test('a failed catalog photo stays unknown and the next pass retries',
      () async {
    var calls = 0;
    guideSeenLabelRead = (name, code) async => null;
    guideSeenInBookRead = (name) async => true;
    guideSeenPhotoRead = (name) async {
      calls++;
      if (calls == 1) throw StateError('offline');
      return 'rosa.jpg';
    };

    final row = _row('Rosa canina');
    final first = await decorateGuideSeen([row], 'en', clouds: {});
    expect(first.single.catalogKnown, isFalse);
    expect(first.single.photoPath, isNull);
    expect(first.single.inBook, isFalse);
    expect(guideSeenChip(first.single), isNull);
    expect(guideSeenDecorateSettled(first), isFalse);

    final second = await decorateGuideSeen([row], 'en', clouds: {});
    expect(calls, 2);
    expect(second.single.catalogKnown, isTrue);
    expect(second.single.inBook, isTrue);
    expect(second.single.photoPath, 'photos/rosa.jpg');
    expect(guideSeenDecorateSettled(second), isTrue);

    await decorateGuideSeen([row], 'en', clouds: {});
    expect(calls, 2);
  });

  test('a real absence from the book is remembered', () async {
    var bookCalls = 0;
    var photoCalls = 0;
    guideSeenLabelRead = (name, code) async => null;
    guideSeenInBookRead = (name) async {
      bookCalls++;
      return false;
    };
    guideSeenPhotoRead = (name) async {
      photoCalls++;
      return null;
    };

    final row = _row('Tanacetum corymbosum');
    final first = await decorateGuideSeen([row], 'en', clouds: {});
    expect(first.single.catalogKnown, isTrue);
    expect(first.single.inBook, isFalse);
    expect(first.single.photoPath, isNull);
    expect(guideSeenChip(first.single), GuideSeenChip.outside);
    expect(guideSeenDecorateSettled(first), isTrue);

    final second = await decorateGuideSeen([row], 'en', clouds: {});
    expect(bookCalls, 1);
    expect(photoCalls, 1);
    expect(second.single.catalogKnown, isTrue);
    expect(second.single.inBook, isFalse);
    expect(guideSeenDecorateSettled(const []), isTrue);
  });
}

GuideSeenFind _row(String name) {
  return readGuideSeenRow(name, {
    observationId: name,
    observationPlant: name,
  })!;
}
