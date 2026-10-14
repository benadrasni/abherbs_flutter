import 'package:abherbs_flutter/seen/guide_seen.dart';
import 'package:abherbs_flutter/seen/observation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a failed read stays unknown and a real absence is applied', () {
    final row = _row('Bellis perennis');

    final failedBook = guideSeenApplyCatalog(
      row,
      label: 'daisy',
      labelKnown: true,
      catalogPhoto: 'photos/bellis.jpg',
      photoKnown: true,
      inBook: null,
    );
    expect(failedBook.catalogKnown, isFalse);
    expect(failedBook.label, isNull);
    expect(failedBook.photoPath, isNull);

    final failedLabel = guideSeenApplyCatalog(
      row,
      label: null,
      labelKnown: false,
      catalogPhoto: 'photos/bellis.jpg',
      photoKnown: true,
      inBook: true,
    );
    expect(failedLabel.catalogKnown, isFalse);
    expect(failedLabel.inBook, isFalse);

    final failedPhoto = guideSeenApplyCatalog(
      row,
      label: 'daisy',
      labelKnown: true,
      catalogPhoto: null,
      photoKnown: false,
      inBook: true,
    );
    expect(failedPhoto.catalogKnown, isFalse);

    final absent = guideSeenApplyCatalog(
      row,
      label: null,
      labelKnown: true,
      catalogPhoto: null,
      photoKnown: true,
      inBook: false,
    );
    expect(absent.catalogKnown, isTrue);
    expect(absent.inBook, isFalse);
    expect(absent.label, isNull);
    expect(absent.photoPath, isNull);
    expect(guideSeenChip(absent), GuideSeenChip.outside);

    final present = guideSeenApplyCatalog(
      row,
      label: 'daisy',
      labelKnown: true,
      catalogPhoto: 'photos/bellis.jpg',
      photoKnown: true,
      inBook: true,
    );
    expect(present.catalogKnown, isTrue);
    expect(present.label, 'daisy');
    expect(present.inBook, isTrue);
    expect(present.photoPath, 'photos/bellis.jpg');
  });

  test('an own photo settles when the shared catalog photo read fails', () {
    final bare = _row('Rosa canina');
    final own = readGuideSeenRow('own', {
      observationId: 'own',
      observationPlant: 'Rosa canina',
      observationPhotoPaths: ['observations/uid/rosa.jpg'],
    })!;
    final rows = [
      guideSeenApplyCatalog(
        bare,
        label: 'dog rose',
        labelKnown: true,
        catalogPhoto: null,
        photoKnown: false,
        inBook: true,
      ),
      guideSeenApplyCatalog(
        own,
        label: 'dog rose',
        labelKnown: true,
        catalogPhoto: null,
        photoKnown: false,
        inBook: true,
        photoAttached: true,
      ),
    ];
    expect(rows[0].catalogKnown, isFalse);
    expect(rows[0].photoPath, isNull);
    expect(rows[1].catalogKnown, isTrue);
    expect(rows[1].inBook, isTrue);
    expect(rows[1].label, 'dog rose');
    expect(rows[1].ownPhoto, isTrue);
    expect(rows[1].photoPath, 'observations/uid/rosa.jpg');
    expect(rows[1].photoAttached, isTrue);
  });

  test('an unknown read keeps the remembered known face', () {
    final raw = _row('Bellis perennis');
    final known = raw.withCatalog(
      label: 'daisy',
      catalogPhoto: 'photos/bellis.jpg',
      inBook: true,
    );
    final kept = guideSeenChooseFace(raw, raw, known);
    expect(kept.catalogKnown, isTrue);
    expect(kept.label, 'daisy');
    expect(kept.photoPath, 'photos/bellis.jpg');

    final fresh = raw.withCatalog(label: 'common daisy', inBook: true);
    expect(guideSeenChooseFace(raw, fresh, known).label, 'common daisy');
    expect(guideSeenChooseFace(raw, raw, null).catalogKnown, isFalse);
  });

  test('a thrown pass keeps the known face and the next pass retries', () {
    final raw = _row('Bellis perennis');
    final known = raw.withCatalog(label: 'daisy', inBook: true);
    const stamp = 'en\u0000notebook';
    final thrown = guideSeenPass(
      latest: [raw],
      read: [raw],
      remembered: {raw.id: known},
      stamp: stamp,
      doneStamp: stamp,
    );
    expect(thrown.rows.single.label, 'daisy');
    expect(thrown.rows.single.catalogKnown, isTrue);
    expect(thrown.stamp, isNull);
    expect(_nonForceRuns(stamp, thrown.stamp), isTrue);

    final stored = {for (final row in thrown.rows) row.id: row};
    final retried = guideSeenPass(
      latest: [raw],
      read: [known],
      remembered: stored,
      stamp: stamp,
      doneStamp: stamp,
    );
    expect(retried.rows.single.label, 'daisy');
    expect(retried.stamp, stamp);
    expect(_nonForceRuns(stamp, retried.stamp), isFalse);

    final moved = guideSeenPass(
      latest: [raw],
      read: [known],
      remembered: stored,
      stamp: stamp,
      doneStamp: 'en\u0000changed',
    );
    expect(moved.stamp, isNull);
    expect(_nonForceRuns('en\u0000changed', moved.stamp), isTrue);
  });
}

/// The shell skips a non-force pass only when this stamp is already recorded.
bool _nonForceRuns(String stamp, String? recorded) => stamp != recorded;

GuideSeenFind _row(String name) {
  return readGuideSeenRow(name, {
    observationId: name,
    observationPlant: name,
  })!;
}
