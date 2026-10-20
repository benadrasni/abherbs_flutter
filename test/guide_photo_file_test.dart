import 'dart:io';
import 'dart:typed_data';

import 'package:abherbs_flutter/camera/guide_camera.dart';
import 'package:abherbs_flutter/data/guide_photo_file.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:exif/exif.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gps leaves a jpeg and the date stays', () async {
    final latitude = [0x30, 0, 0, 0, 1, 0, 0, 0, 9, 0, 0, 0, 1, 0, 0, 0, 0x24, 0, 0, 0, 1, 0, 0, 0];
    final original = _jpeg(little: true);
    expect(_contains(original, latitude), isTrue);

    final stripped = jpegWithoutGps(original);
    expect(identical(stripped, original), isFalse);
    expect(_contains(stripped, latitude), isFalse);
    expect(_contains(stripped, '2024:01:02 03:04:05'.codeUnits), isTrue);

    final tags = await readExifFromBytes(stripped);
    expect(tags['GPS GPSLatitude'], isNull);
    expect(tags['GPS GPSLongitude'], isNull);
    expect(tags['Image DateTime'].toString(), '2024:01:02 03:04:05');
    expect(
      getLatitudeFromExif(tags['GPS GPSLatitudeRef'], tags['GPS GPSLatitude']),
      0,
    );
    expect(
      guidePhotoPosition(
        getLatitudeFromExif(tags['GPS GPSLatitudeRef'], tags['GPS GPSLatitude']),
        getLongitudeFromExif(
          tags['GPS GPSLongitudeRef'],
          tags['GPS GPSLongitude'],
        ),
      ),
      isNull,
    );

    final before = await readExifFromBytes(original);
    expect(
      getLatitudeFromExif(
        before['GPS GPSLatitudeRef'],
        before['GPS GPSLatitude'],
      ),
      closeTo(48.16, 0.001),
    );
  });

  test('a big-endian gps directory is removed too', () async {
    final original = _jpeg(little: false);
    final tags = await readExifFromBytes(original);
    expect(tags['GPS GPSLatitude'], isNotNull);
    final stripped = jpegWithoutGps(original);
    final after = await readExifFromBytes(stripped);
    expect(after['GPS GPSLatitude'], isNull);
    expect(after['Image DateTime'].toString(), '2024:01:02 03:04:05');
  });

  test('a jpeg without gps is left byte for byte', () {
    final plain = _jpeg(little: true, gps: false);
    expect(identical(jpegWithoutGps(plain), plain), isTrue);
    final other = Uint8List.fromList([1, 2, 3]);
    expect(identical(jpegWithoutGps(other), other), isTrue);
  });

  test('only the photo-picker cache is deleted after the copy', () async {
    final root = await Directory.systemTemp.createTemp('guide-pick-test');
    addTearDown(() => root.delete(recursive: true));
    final cache = Directory('${root.path}/guide-pick')..createSync();
    final shot = File('${cache.path}/shot.jpg')
      ..writeAsBytesSync(_jpeg(little: true));
    final kept = File('${root.path}/kept.jpg');
    await copyGuidePhotoWithoutGps(shot.path, kept.path);
    expect(shot.existsSync(), isFalse);
    expect(kept.existsSync(), isTrue);
    final tags = await readExifFromBytes(await kept.readAsBytes());
    expect(tags['GPS GPSLatitude'], isNull);
    expect(tags['Image DateTime'].toString(), '2024:01:02 03:04:05');

    final camera = File('${root.path}/camera.jpg')
      ..writeAsBytesSync(_jpeg(little: true));
    final stored = File('${root.path}/stored.jpg');
    await copyGuidePhotoWithoutGps(camera.path, stored.path);
    expect(camera.existsSync(), isTrue);
    expect(guidePickCachePath(shot.path), isTrue);
    expect(guidePickCachePath(camera.path), isFalse);
    expect(guidePickCachePath('${root.path}/guide-pick'), isFalse);
  });
}

bool _contains(List<int> bytes, List<int> needle) {
  if (needle.isEmpty || needle.length > bytes.length) return false;
  for (var i = 0; i <= bytes.length - needle.length; i++) {
    var found = true;
    for (var j = 0; j < needle.length; j++) {
      if (bytes[i + j] != needle[j]) {
        found = false;
        break;
      }
    }
    if (found) return true;
  }
  return false;
}

Uint8List _jpeg({required bool little, bool gps = true}) {
  final tiff = _tiff(little: little, gps: gps);
  final payload = <int>[
    0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // Exif\0\0
    ...tiff,
  ];
  final length = payload.length + 2;
  return Uint8List.fromList([
    0xFF, 0xD8,
    0xFF, 0xE0, 0x00, 0x10,
    0x4A, 0x46, 0x49, 0x46, 0x00,
    0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
    0xFF, 0xE1,
    (length >> 8) & 0xFF,
    length & 0xFF,
    ...payload,
    0xFF, 0xD9,
  ]);
}

Uint8List _tiff({required bool little, required bool gps}) {
  final bytes = BytesBuilder();
  void u16(int value) {
    if (little) {
      bytes.addByte(value & 0xFF);
      bytes.addByte((value >> 8) & 0xFF);
    } else {
      bytes.addByte((value >> 8) & 0xFF);
      bytes.addByte(value & 0xFF);
    }
  }

  void u32(int value) {
    if (little) {
      bytes.addByte(value & 0xFF);
      bytes.addByte((value >> 8) & 0xFF);
      bytes.addByte((value >> 16) & 0xFF);
      bytes.addByte((value >> 24) & 0xFF);
    } else {
      bytes.addByte((value >> 24) & 0xFF);
      bytes.addByte((value >> 16) & 0xFF);
      bytes.addByte((value >> 8) & 0xFF);
      bytes.addByte(value & 0xFF);
    }
  }

  bytes.addByte(little ? 0x49 : 0x4D);
  bytes.addByte(little ? 0x49 : 0x4D);
  u16(42);
  u32(8);

  final dateAt = gps ? 38 : 26;
  u16(gps ? 2 : 1);
  u16(0x0132);
  u16(2);
  u32(20);
  u32(dateAt);
  if (gps) {
    u16(0x8825);
    u16(4);
    u32(1);
    u32(58);
  }
  u32(0);

  if (!gps) {
    expect(bytes.length, dateAt);
  }
  bytes.add('2024:01:02 03:04:05'.codeUnits);
  bytes.addByte(0);
  if (!gps) return bytes.toBytes();

  expect(bytes.length, 58);
  final latAt = 112;
  final lonAt = 136;
  u16(4);
  u16(1);
  u16(2);
  u32(2);
  bytes.add('N'.codeUnits);
  bytes.add([0, 0, 0]);
  u16(2);
  u16(5);
  u32(3);
  u32(latAt);
  u16(3);
  u16(2);
  u32(2);
  bytes.add('E'.codeUnits);
  bytes.add([0, 0, 0]);
  u16(4);
  u16(5);
  u32(3);
  u32(lonAt);
  u32(0);
  expect(bytes.length, latAt);
  for (final part in [48, 1, 9, 1, 36, 1, 17, 1, 6, 1, 18, 1]) {
    u32(part);
  }
  return bytes.toBytes();
}
