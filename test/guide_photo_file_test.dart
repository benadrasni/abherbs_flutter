import 'dart:io';
import 'dart:typed_data';

import 'package:abherbs_flutter/camera/guide_camera.dart';
import 'package:abherbs_flutter/data/guide_photo_file.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:exif/exif.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gps leaves a jpeg and the date stays', () async {
    final latitude = [
      0x30,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      9,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0x24,
      0,
      0,
      0,
      1,
      0,
      0,
      0
    ];
    final original = _jpeg(little: true);
    expect(_contains(original, latitude), isTrue);

    final stripped = photoWithoutLocation(original)!;
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
        getLatitudeFromExif(
            tags['GPS GPSLatitudeRef'], tags['GPS GPSLatitude']),
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
    final stripped = photoWithoutLocation(original)!;
    final after = await readExifFromBytes(stripped);
    expect(after['GPS GPSLatitude'], isNull);
    expect(after['Image DateTime'].toString(), '2024:01:02 03:04:05');
  });

  test('a jpeg without gps is left byte for byte', () {
    final plain = _jpeg(little: true, gps: false);
    expect(identical(photoWithoutLocation(plain), plain), isTrue);
    final entropy = Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      0xDA,
      0x00,
      0x08,
      0x01,
      0x01,
      0x00,
      0x00,
      0x3F,
      0x00,
      0x00,
      0x11,
      0xFF,
      0x00,
      0x22,
      0xFF,
      0xD9,
    ]);
    expect(identical(photoWithoutLocation(entropy), entropy), isTrue);
  });

  test('a photo that cannot be cleaned is not returned', () {
    expect(photoWithoutLocation(Uint8List.fromList([1, 2, 3])), isNull);
    expect(
      photoWithoutLocation(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0x00, 0x20])),
      isNull,
    );
    expect(
      photoWithoutLocation(Uint8List.fromList([
        0,
        0,
        0,
        16,
        ...'ftyp'.codeUnits,
        ...'heic'.codeUnits,
        0,
        0,
        0,
        0,
      ])),
      isNull,
    );
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

  test('xmp and a nested thumbnail lose their place', () async {
    const place = 'GPSLatitude>48,9.6000N';
    final xmp = _withSegment(
      _jpeg(little: true, gps: false),
      _xmp(place),
    );
    final fromXmp = photoWithoutLocation(xmp);
    expect(fromXmp, isNotNull);
    expect(_contains(fromXmp!, place.codeUnits), isFalse);
    expect(_contains(fromXmp, '2024:01:02 03:04:05'.codeUnits), isTrue);
    final xmpTags = await readExifFromBytes(fromXmp);
    expect(xmpTags['Image DateTime'].toString(), '2024:01:02 03:04:05');

    final nested = _jpegWithThumbnail(_jpeg(little: true));
    expect(_contains(nested, _latitude), isTrue);
    final fromThumb = photoWithoutLocation(nested);
    expect(fromThumb, isNotNull);
    expect(_contains(fromThumb!, _latitude), isFalse);
    expect(_contains(fromThumb, '2024:01:02 03:04:05'.codeUnits), isTrue);
  });

  test('png and webp lose exif and xmp', () {
    final tiff = _tiff(little: true, gps: true);
    final png = _png([
      _pngChunk('IHDR', List<int>.filled(13, 0)),
      _pngChunk('eXIf', tiff),
      _pngChunk('tEXt', [
        ...'XML:com.adobe.xmp'.codeUnits,
        0,
        ...'GPSLatitude>48,9.6000N'.codeUnits,
      ]),
      _pngChunk('IEND', const []),
    ]);
    expect(_contains(png, _latitude), isTrue);
    final strippedPng = photoWithoutLocation(png)!;
    expect(_contains(strippedPng, _latitude), isFalse);
    expect(_contains(strippedPng, 'GPSLatitude'.codeUnits), isFalse);
    expect(_contains(strippedPng, 'IHDR'.codeUnits), isTrue);

    final plainPng = _png([
      _pngChunk('IHDR', List<int>.filled(13, 0)),
      _pngChunk('IEND', const []),
    ]);
    expect(identical(photoWithoutLocation(plainPng), plainPng), isTrue);

    final webp = _webp([
      _webpChunk('VP8X', [0x08, 0, 0, 0, 0, 0, 1, 0, 0, 1]),
      _webpChunk('EXIF', tiff),
      _webpChunk('XMP ', 'GPSLongitude>17,6.1800E'.codeUnits),
    ]);
    expect(_contains(webp, _latitude), isTrue);
    final strippedWebp = photoWithoutLocation(webp);
    expect(strippedWebp, isNotNull);
    expect(_contains(strippedWebp!, _latitude), isFalse);
    expect(_contains(strippedWebp, 'GPSLongitude'.codeUnits), isFalse);
    expect(strippedWebp[0], 0x52);
    expect(_le32(strippedWebp, 4), strippedWebp.length - 8);
    expect(_vp8xFlags(strippedWebp) & 0x0C, 0);

    final plainWebp = _webp([
      _webpChunk('VP8 ', [1, 2, 3, 4])
    ]);
    expect(identical(photoWithoutLocation(plainWebp), plainWebp), isTrue);
  });

  test('heif exif and xmp lose their place', () {
    final tiff = _tiff(little: true, gps: true);
    final heic = _heic(
      exif: [0, 0, 0, 0, ...tiff],
      xmp: 'GPSLatitude>48,9.6000N'.codeUnits,
    );
    expect(_contains(heic, _latitude), isTrue);
    expect(_contains(heic, 'GPSLatitude'.codeUnits), isTrue);
    final stripped = photoWithoutLocation(heic);
    expect(stripped, isNotNull);
    expect(_contains(stripped!, _latitude), isFalse);
    expect(_contains(stripped, 'GPSLatitude'.codeUnits), isFalse);
    expect(_fourcc(stripped, 4), 'ftyp');

    final clean = _heic(exif: null, xmp: null);
    expect(identical(photoWithoutLocation(clean), clean), isTrue);
  });

  test('a photo whose place cannot be removed is not written', () async {
    final root = await Directory.systemTemp.createTemp('guide-strip-fail');
    addTearDown(() => root.delete(recursive: true));
    final cache = Directory('${root.path}/guide-pick')..createSync();
    final shot = File('${cache.path}/shot.bin')..writeAsBytesSync([1, 2, 3, 4]);
    final dest = File('${root.path}/out.jpg');
    await expectLater(
      copyGuidePhotoWithoutGps(shot.path, dest.path),
      throwsA(isA<StateError>()),
    );
    expect(dest.existsSync(), isFalse);
    expect(shot.existsSync(), isFalse);

    final camera = File('${root.path}/camera.bin')
      ..writeAsBytesSync([1, 2, 3, 4]);
    await expectLater(
      copyGuidePhotoWithoutGps(camera.path, dest.path),
      throwsA(isA<StateError>()),
    );
    expect(camera.existsSync(), isTrue);
    expect(dest.existsSync(), isFalse);
  });

  test('a discarded shot drops its cache file and leaves other files',
      () async {
    final root = await Directory.systemTemp.createTemp('guide-discard');
    addTearDown(() => root.delete(recursive: true));
    final pick = Directory('${root.path}/guide-pick')..createSync();
    final shot = File('${pick.path}/shot.jpg')
      ..writeAsBytesSync(_jpeg(little: true));
    final cache = Directory('${root.path}/cache')..createSync();
    final shutter = File('${cache.path}/CAP1.jpg')..writeAsBytesSync([9, 9]);
    final kept = File('${root.path}/kept.jpg')..writeAsBytesSync([3, 3]);
    await deleteDiscardedShot(shot.path);
    await deleteDiscardedShot(shutter.path);
    await deleteDiscardedShot(kept.path);
    expect(shot.existsSync(), isFalse);
    expect(shutter.existsSync(), isFalse);
    expect(kept.existsSync(), isTrue);
    expect(guideTemporaryShotPath(shot.path), isTrue);
    expect(guideTemporaryShotPath(shutter.path), isTrue);
    expect(guideTemporaryShotPath('${root.path}/tmp/shot.jpg'), isTrue);
    expect(guideTemporaryShotPath(kept.path), isFalse);
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
    0xFF,
    0xD8,
    0xFF,
    0xE0,
    0x00,
    0x10,
    0x4A,
    0x46,
    0x49,
    0x46,
    0x00,
    0x01,
    0x01,
    0x00,
    0x00,
    0x01,
    0x00,
    0x01,
    0x00,
    0x00,
    0xFF,
    0xE1,
    (length >> 8) & 0xFF,
    length & 0xFF,
    ...payload,
    0xFF,
    0xD9,
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

const _latitude = [
  0x30,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  9,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0x24,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
];

Uint8List _xmp(String body) {
  final payload = [
    ...'http://ns.adobe.com/xap/1.0/'.codeUnits,
    0,
    ...body.codeUnits,
  ];
  final length = payload.length + 2;
  return Uint8List.fromList([
    0xFF,
    0xE1,
    (length >> 8) & 0xFF,
    length & 0xFF,
    ...payload,
  ]);
}

Uint8List _withSegment(Uint8List jpeg, Uint8List segment) {
  return Uint8List.fromList([
    ...jpeg.sublist(0, jpeg.length - 2),
    ...segment,
    0xFF,
    0xD9,
  ]);
}

Uint8List _jpegWithThumbnail(Uint8List thumbnail) {
  final bytes = BytesBuilder();
  void u16(int value) {
    bytes.addByte(value & 0xFF);
    bytes.addByte((value >> 8) & 0xFF);
  }

  void u32(int value) {
    bytes.addByte(value & 0xFF);
    bytes.addByte((value >> 8) & 0xFF);
    bytes.addByte((value >> 16) & 0xFF);
    bytes.addByte((value >> 24) & 0xFF);
  }

  bytes.addByte(0x49);
  bytes.addByte(0x49);
  u16(42);
  u32(8);
  u16(1);
  u16(0x0132);
  u16(2);
  u32(20);
  u32(26);
  u32(46);
  bytes.add('2024:01:02 03:04:05'.codeUnits);
  bytes.addByte(0);
  u16(2);
  u16(0x0201);
  u16(4);
  u32(1);
  u32(76);
  u16(0x0202);
  u16(4);
  u32(1);
  u32(thumbnail.length);
  u32(0);
  bytes.add(thumbnail);
  final payload = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00, ...bytes.toBytes()];
  final length = payload.length + 2;
  return Uint8List.fromList([
    0xFF,
    0xD8,
    0xFF,
    0xE1,
    (length >> 8) & 0xFF,
    length & 0xFF,
    ...payload,
    0xFF,
    0xD9,
  ]);
}

Uint8List _png(List<List<int>> chunks) {
  return Uint8List.fromList([
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    for (final chunk in chunks) ...chunk,
  ]);
}

List<int> _pngChunk(String type, List<int> data) {
  final length = data.length;
  return [
    (length >> 24) & 0xFF,
    (length >> 16) & 0xFF,
    (length >> 8) & 0xFF,
    length & 0xFF,
    ...type.codeUnits,
    ...data,
    0,
    0,
    0,
    0,
  ];
}

Uint8List _webp(List<List<int>> chunks) {
  final body = [for (final chunk in chunks) ...chunk];
  final size = 4 + body.length;
  return Uint8List.fromList([
    ...'RIFF'.codeUnits,
    size & 0xFF,
    (size >> 8) & 0xFF,
    (size >> 16) & 0xFF,
    (size >> 24) & 0xFF,
    ...'WEBP'.codeUnits,
    ...body,
  ]);
}

List<int> _webpChunk(String type, List<int> data) {
  return [
    ...type.codeUnits,
    data.length & 0xFF,
    (data.length >> 8) & 0xFF,
    (data.length >> 16) & 0xFF,
    (data.length >> 24) & 0xFF,
    ...data,
    if (data.length.isOdd) 0,
  ];
}

int _le32(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

int _vp8xFlags(Uint8List bytes) {
  for (var i = 12; i + 8 < bytes.length; i++) {
    if (bytes[i] == 0x56 &&
        bytes[i + 1] == 0x50 &&
        bytes[i + 2] == 0x38 &&
        bytes[i + 3] == 0x58) {
      return bytes[i + 8];
    }
  }
  throw StateError('VP8X missing');
}

String _fourcc(Uint8List bytes, int offset) {
  return String.fromCharCodes(bytes.sublist(offset, offset + 4));
}

Uint8List _heic({List<int>? exif, List<int>? xmp}) {
  List<int> u32(int value) => [
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ];
  List<int> box(String type, List<int> content) {
    return [...u32(8 + content.length), ...type.codeUnits, ...content];
  }

  List<int> full(String type, int version, List<int> content) {
    return box(type, [version, 0, 0, 0, ...content]);
  }

  final items = <({int id, String type, String? mime, List<int> data})>[
    if (exif != null) (id: 1, type: 'Exif', mime: null, data: exif),
    if (xmp != null)
      (id: 2, type: 'mime', mime: 'application/rdf+xml', data: xmp),
    if (exif == null && xmp == null)
      (id: 1, type: 'hvc1', mime: null, data: [0, 0, 0, 0]),
  ];
  final infes = <int>[];
  for (final item in items) {
    infes.addAll(full('infe', 2, [
      (item.id >> 8) & 0xFF,
      item.id & 0xFF,
      0,
      0,
      ...item.type.codeUnits,
      0,
      if (item.mime != null) ...item.mime!.codeUnits,
      if (item.mime != null) 0,
    ]));
  }
  final iinf = full('iinf', 0, [
    (items.length >> 8) & 0xFF,
    items.length & 0xFF,
    ...infes,
  ]);
  final hdlr = full('hdlr', 0, [
    0,
    0,
    0,
    0,
    ...'pict'.codeUnits,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ]);
  final ilocBody = <int>[0x44, 0x00, 0x00, items.length];
  final offsetAt = <int>[];
  for (final item in items) {
    ilocBody.addAll([
      (item.id >> 8) & 0xFF,
      item.id & 0xFF,
      0,
      0,
      0,
      1,
    ]);
    offsetAt.add(ilocBody.length);
    ilocBody.addAll([0, 0, 0, 0, ...u32(item.data.length)]);
  }
  final iloc = full('iloc', 0, ilocBody);
  final hdlrBox = hdlr;
  final iinfBox = iinf;
  final meta = box('meta', [0, 0, 0, 0, ...hdlrBox, ...iinfBox, ...iloc]);
  final ftyp = box('ftyp', [
    ...'heic'.codeUnits,
    0,
    0,
    0,
    0,
    ...'heic'.codeUnits,
  ]);
  final payload = [for (final item in items) ...item.data];
  final file = <int>[...ftyp, ...meta, ...box('mdat', payload)];
  final ilocStart = ftyp.length + 12 + hdlrBox.length + iinfBox.length;
  final bodyStart = ilocStart + 12;
  var cursor = ftyp.length + meta.length + 8;
  for (var n = 0; n < items.length; n++) {
    final at = bodyStart + offsetAt[n];
    final off = cursor;
    file[at] = (off >> 24) & 0xFF;
    file[at + 1] = (off >> 16) & 0xFF;
    file[at + 2] = (off >> 8) & 0xFF;
    file[at + 3] = off & 0xFF;
    cursor += items[n].data.length;
  }
  return Uint8List.fromList(file);
}
