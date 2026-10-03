import 'package:abherbs_flutter/seen/observation.dart';
import 'package:abherbs_flutter/camera/guide_camera.dart';
import 'package:abherbs_flutter/seen/guide_private_photos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const uid = 'user';
  const bellis = 'observations/user/Bellis_perennis/bp_1.jpg';
  const outside = 'observations/user/Tanacetum_corymbosum/tc_9.jpg';

  test('private object path mirrors the seen file, in the book or not', () {
    expect(
      guidePrivateObjectPath(bellis, uid),
      'private/user/Bellis_perennis/bp_1.jpg',
    );
    expect(
      guidePrivateObjectPath(outside, uid),
      'private/user/Tanacetum_corymbosum/tc_9.jpg',
    );
    expect(
      guidePrivateObjectPath(
          'observations/other/Bellis_perennis/bp_1.jpg', uid),
      isNull,
    );
    expect(guidePrivateObjectPath(bellis, ''), isNull);
    expect(guidePrivateObjectPath('observations/user/', uid), isNull);
    expect(
      guidePrivateObjectPath('observations/user/../secret.jpg', uid),
      isNull,
    );
    expect(guidePrivateObjectPath('photos/user/bp_1.jpg', uid), isNull);
  });

  test('plant keys match the camera observation key', () {
    for (final name in [
      'Bellis perennis',
      'Tanacetum corymbosum',
      'A/B.C#D\$E[F]',
      '   ',
    ]) {
      expect(guidePrivatePlantKey(name), guideObservationPlantKey(name));
    }
  });

  test('content type follows the file', () {
    expect(guidePrivateContentType(bellis), 'image/jpeg');
    expect(guidePrivateContentType('a.PNG'), 'image/png');
    expect(guidePrivateContentType('a.webp'), 'image/webp');
    expect(guidePrivateContentType('a.heic'), 'image/heic');
    expect(guidePrivateContentType('no-dot'), 'image/jpeg');
  });

  test('photo lists keep list and map order', () {
    expect(guidePrivatePhotoList([bellis, outside]), [bellis, outside]);
    expect(
      guidePrivatePhotoList({'1': outside, '0': bellis, '2': ''}),
      [bellis, outside],
    );
    expect(guidePrivatePhotoList(null), isEmpty);
  });

  test('a lapsed plan uploads nothing and does not mark the row', () {
    final work = guidePrivatePhotoWork(
      fieldGuide: false,
      uid: uid,
      photoPaths: [bellis, outside],
      cloud: false,
      local: (_) => true,
      remote: (_) => false,
    );
    expect(work.upload, isEmpty);
    expect(work.markCloud, isFalse);
  });

  test('photos already in the cloud are left alone', () {
    final work = guidePrivatePhotoWork(
      fieldGuide: true,
      uid: uid,
      photoPaths: [bellis],
      cloud: true,
      local: (_) => true,
      remote: (_) => false,
    );
    expect(work.upload, isEmpty);
    expect(work.markCloud, isFalse);
  });

  test('local photos are uploaded, and a missing one holds the flag', () {
    final both = guidePrivatePhotoWork(
      fieldGuide: true,
      uid: uid,
      photoPaths: [bellis, outside],
      cloud: false,
      local: (_) => true,
      remote: (_) => false,
    );
    expect(both.upload, [bellis, outside]);
    expect(both.markCloud, isTrue);

    final one = guidePrivatePhotoWork(
      fieldGuide: true,
      uid: uid,
      photoPaths: [bellis, outside],
      cloud: false,
      local: (path) => path == bellis,
      remote: (_) => false,
    );
    expect(one.upload, [bellis]);
    expect(one.markCloud, isFalse);
  });

  test('a photo put earlier this session is not put again', () {
    final work = guidePrivatePhotoWork(
      fieldGuide: true,
      uid: uid,
      photoPaths: [bellis, outside],
      cloud: false,
      local: (_) => false,
      remote: (path) => path == bellis,
    );
    expect(work.upload, isEmpty);
    expect(work.markCloud, isFalse);

    final done = guidePrivatePhotoWork(
      fieldGuide: true,
      uid: uid,
      photoPaths: [bellis],
      cloud: false,
      local: (_) => false,
      remote: (_) => true,
    );
    expect(done.upload, isEmpty);
    expect(done.markCloud, isTrue);
  });

  test('another account and an empty find are skipped', () {
    final foreign = guidePrivatePhotoWork(
      fieldGuide: true,
      uid: uid,
      photoPaths: ['observations/other/Bellis_perennis/bp_1.jpg'],
      cloud: false,
      local: (_) => true,
      remote: (_) => false,
    );
    expect(foreign.upload, isEmpty);
    expect(foreign.markCloud, isFalse);

    final empty = guidePrivatePhotoWork(
      fieldGuide: true,
      uid: uid,
      photoPaths: const [],
      cloud: false,
      local: (_) => true,
      remote: (_) => false,
    );
    expect(empty.markCloud, isFalse);
  });

  test('photoCloud stays off the shared payload', () {
    final observation = Observation('Tanacetum corymbosum');
    observation.id = 'user_1';
    expect(observation.toJson().containsKey(observationPhotoCloud), isFalse);
  });
}
