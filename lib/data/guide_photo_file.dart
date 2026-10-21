import 'dart:io';
import 'dart:typed_data';

/// Bytes with location metadata removed, or null when it could not be removed.
///
/// Plant.id, the public sighting, and the private photo upload must not
/// receive the original bytes on null. JPEG EXIF GPS (including a nested
/// thumbnail), XMP, and the same metadata in PNG, WebP, and HEIF is removed.
/// A photo that already has no location is returned unchanged.
Uint8List? photoWithoutLocation(Uint8List bytes) {
  try {
    if (_isJpeg(bytes)) return _jpegWithoutLocation(bytes);
    if (_isPng(bytes)) return _pngWithoutLocation(bytes);
    if (_isWebp(bytes)) return _webpWithoutLocation(bytes);
    if (_isHeif(bytes)) return _heifWithoutLocation(bytes);
  } catch (_) {
    return null;
  }
  return null;
}

/// The photo-picker cache. Other camera files stay where they are.
bool guidePickCachePath(String path) {
  final parts = path.replaceAll('\\', '/').split('/');
  return parts.length >= 2 && parts[parts.length - 2] == 'guide-pick';
}

/// A file this app wrote for a shot and can delete. The camera roll and a
/// stored find are not here.
bool guideTemporaryShotPath(String path) {
  if (guidePickCachePath(path)) return true;
  final parts = path.replaceAll('\\', '/').split('/');
  if (parts.length < 2) return false;
  final parent = parts[parts.length - 2];
  return parent == 'cache' || parent == 'tmp';
}

/// Writes [from] to [to] without location metadata, then deletes a
/// photo-picker cache file. Throws when the location could not be removed,
/// and does not write the original bytes.
Future<void> copyGuidePhotoWithoutGps(String from, String to) async {
  final stripped = photoWithoutLocation(await File(from).readAsBytes());
  if (stripped == null) {
    await deleteGuidePickCache(from);
    throw StateError('photo location could not be removed');
  }
  await File(to).writeAsBytes(stripped);
  await deleteGuidePickCache(from);
}

/// Drops a file left in `cacheDir/guide-pick` after it has been copied.
Future<void> deleteGuidePickCache(String path) async {
  if (!guidePickCachePath(path)) return;
  final file = File(path);
  if (await file.exists()) await file.delete();
}

/// Drops a shot the person discarded or cancelled. The cache file still has
/// the original GPS until a find is saved. Unlink happens before this
/// returns, so the next frame cannot open the file.
Future<void> deleteDiscardedShot(String path) {
  if (guideTemporaryShotPath(path)) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }
  return Future<void>.value();
}

class _Scrub {
  bool changed = false;
}

class _Range {
  final int start;
  final int end;
  const _Range(this.start, this.end);
}

bool _isJpeg(Uint8List bytes) {
  return bytes.length >= 4 && bytes[0] == 0xFF && bytes[1] == 0xD8;
}

Uint8List? _jpegWithoutLocation(Uint8List bytes) {
  final copy = Uint8List.fromList(bytes);
  final scrub = _Scrub();
  if (!_scrubJpeg(copy, 0, copy.length, 0, scrub)) return null;
  return scrub.changed ? copy : bytes;
}

bool _scrubJpeg(
  Uint8List bytes,
  int start,
  int end,
  int depth,
  _Scrub scrub,
) {
  if (depth > 4) return false;
  if (end - start < 4 || bytes[start] != 0xFF || bytes[start + 1] != 0xD8) {
    return false;
  }
  var i = start + 2;
  var sawEoi = false;
  while (i < end) {
    if (bytes[i] != 0xFF) {
      if (!sawEoi) return false;
      _blank(bytes, i, end, scrub);
      return true;
    }
    while (i < end && bytes[i] == 0xFF) {
      i++;
    }
    if (i >= end) return false;
    final marker = bytes[i];
    i++;
    if (marker == 0xD9) {
      sawEoi = true;
      continue;
    }
    if (marker == 0x00) return false;
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) continue;
    if (i + 2 > end) return false;
    final length = (bytes[i] << 8) | bytes[i + 1];
    if (length < 2 || i + length > end) return false;
    if (marker == 0xDA) {
      i += length;
      final next = _skipEntropy(bytes, i, end);
      if (next < 0) return false;
      i = next;
      continue;
    }
    final payload = i + 2;
    final segEnd = i + length;
    if (marker == 0xE1 && _isExifHeader(bytes, payload, segEnd)) {
      if (!_scrubTiff(bytes, payload + 6, segEnd, depth, scrub)) return false;
    } else if (marker == 0xE1 && _isXmpHeader(bytes, payload, segEnd)) {
      _blankXmp(bytes, payload, segEnd, scrub);
    }
    i = segEnd;
  }
  return sawEoi;
}

int _skipEntropy(Uint8List bytes, int i, int end) {
  while (i < end) {
    if (bytes[i] != 0xFF) {
      i++;
      continue;
    }
    final marker = i;
    var j = i;
    while (j < end && bytes[j] == 0xFF) {
      j++;
    }
    if (j >= end) return -1;
    if (bytes[j] == 0x00) {
      i = j + 1;
      continue;
    }
    return marker;
  }
  return -1;
}

bool _isExifHeader(Uint8List bytes, int start, int end) {
  const header = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
  return _startsWith(bytes, start, end, header);
}

bool _isXmpHeader(Uint8List bytes, int start, int end) {
  return _startsWith(bytes, start, end, _xmpStandard) ||
      _startsWith(bytes, start, end, _xmpExtended);
}

const _xmpStandard = [
  0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F, 0x6E, 0x73, 0x2E, 0x61, 0x64, //
  0x6F, 0x62, 0x65, 0x2E, 0x63, 0x6F, 0x6D, 0x2F, 0x78, 0x61, 0x70, 0x2F, //
  0x31, 0x2E, 0x30, 0x2F, 0x00,
];

const _xmpExtended = [
  0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F, 0x6E, 0x73, 0x2E, 0x61, 0x64, //
  0x6F, 0x62, 0x65, 0x2E, 0x63, 0x6F, 0x6D, 0x2F, 0x78, 0x6D, 0x70, 0x2F, //
  0x65, 0x78, 0x74, 0x65, 0x6E, 0x73, 0x69, 0x6F, 0x6E, 0x2F, 0x00,
];

bool _startsWith(Uint8List bytes, int start, int end, List<int> header) {
  if (start + header.length > end) return false;
  for (var i = 0; i < header.length; i++) {
    if (bytes[start + i] != header[i]) return false;
  }
  return true;
}

void _blankXmp(Uint8List bytes, int payload, int segEnd, _Scrub scrub) {
  final header = _startsWith(bytes, payload, segEnd, _xmpStandard)
      ? _xmpStandard.length
      : _xmpExtended.length;
  _blank(bytes, payload + header, segEnd, scrub);
}

void _blank(Uint8List bytes, int start, int end, _Scrub scrub) {
  for (var i = start; i < end; i++) {
    if (bytes[i] != 0x20) {
      bytes[i] = 0x20;
      scrub.changed = true;
    }
  }
}

bool _scrubTiff(
  Uint8List bytes,
  int tiff,
  int limit,
  int depth,
  _Scrub scrub,
) {
  if (tiff + 8 > limit) return false;
  final little = bytes[tiff] == 0x49 && bytes[tiff + 1] == 0x49;
  final big = bytes[tiff] == 0x4D && bytes[tiff + 1] == 0x4D;
  if (!little && !big) return false;

  int u16(int offset) {
    final b0 = bytes[offset];
    final b1 = bytes[offset + 1];
    return little ? (b1 << 8) | b0 : (b0 << 8) | b1;
  }

  int u32(int offset) {
    final b0 = bytes[offset];
    final b1 = bytes[offset + 1];
    final b2 = bytes[offset + 2];
    final b3 = bytes[offset + 3];
    return little
        ? (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
        : (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
  }

  if (u16(tiff + 2) != 42) return false;
  final thumbs = <_Range>[];
  final seen = <int>{};

  bool walk(int ifd, int hops) {
    if (hops > 16 || ifd < tiff || ifd + 2 > limit || !seen.add(ifd)) {
      return false;
    }
    final count = u16(ifd);
    final entries = ifd + 2;
    final nextAt = entries + count * 12;
    if (count > 256 || nextAt + 4 > limit) return false;
    int? jpegOff;
    int? jpegLen;
    final subs = <int>[];
    for (var n = 0; n < count; n++) {
      final entry = entries + n * 12;
      final tag = u16(entry);
      if (tag == 0x8825) {
        final gps = tiff + u32(entry + 8);
        _wipeIfd(bytes, tiff, gps, limit, u16, u32);
        for (var b = 0; b < 12; b++) {
          bytes[entry + b] = 0;
        }
        scrub.changed = true;
      } else if (tag == 0x02BC) {
        final zeroed = _zeroValue(bytes, tiff, entry, limit, u16, u32);
        if (zeroed == null) return false;
        if (zeroed) scrub.changed = true;
      } else if (tag == 0x014A) {
        final offsets = _entryLongs(bytes, tiff, entry, limit, u16, u32);
        if (offsets == null) return false;
        subs.addAll(offsets);
      } else if (tag == 0x0201) {
        jpegOff = _singleLong(entry, u16, u32);
      } else if (tag == 0x0202) {
        jpegLen = _singleLong(entry, u16, u32);
      }
    }
    if (jpegOff != null && jpegLen != null && jpegLen > 0) {
      final thumbStart = tiff + jpegOff;
      final thumbEnd = thumbStart + jpegLen;
      if (thumbStart < tiff || thumbEnd > bytes.length) return false;
      thumbs.add(_Range(thumbStart, thumbEnd));
    }
    final next = u32(nextAt);
    if (next != 0 && !walk(tiff + next, hops + 1)) return false;
    for (final sub in subs) {
      if (sub != 0 && !walk(tiff + sub, hops + 1)) return false;
    }
    return true;
  }

  if (!walk(tiff + u32(tiff + 4), 0)) return false;
  for (final thumb in thumbs) {
    if (thumb.end - thumb.start < 2) continue;
    if (bytes[thumb.start] != 0xFF || bytes[thumb.start + 1] != 0xD8) continue;
    if (!_scrubJpeg(bytes, thumb.start, thumb.end, depth + 1, scrub)) {
      return false;
    }
  }
  return true;
}

int? _singleLong(
  int entry,
  int Function(int offset) u16,
  int Function(int offset) u32,
) {
  final type = u16(entry + 2);
  final count = u32(entry + 4);
  if (count != 1 || (type != 3 && type != 4)) return null;
  return type == 3 ? u16(entry + 8) : u32(entry + 8);
}

List<int>? _entryLongs(
  Uint8List bytes,
  int tiff,
  int entry,
  int limit,
  int Function(int offset) u16,
  int Function(int offset) u32,
) {
  final type = u16(entry + 2);
  final count = u32(entry + 4);
  if (count == 0 || count > 8 || (type != 3 && type != 4)) return null;
  if (count == 1) {
    final value = _singleLong(entry, u16, u32);
    return value == null ? null : [value];
  }
  final width = type == 3 ? 2 : 4;
  final size = width * count;
  if (size <= 4) {
    if (type == 3 && count == 2) {
      return [u16(entry + 8), u16(entry + 10)];
    }
    return null;
  }
  final at = tiff + u32(entry + 8);
  if (at < tiff || at + size > limit) return null;
  return [
    for (var n = 0; n < count; n++)
      type == 3 ? u16(at + n * 2) : u32(at + n * 4),
  ];
}

/// Null when the value sits outside the TIFF and could not be cleared.
bool? _zeroValue(
  Uint8List bytes,
  int tiff,
  int entry,
  int limit,
  int Function(int offset) u16,
  int Function(int offset) u32,
) {
  final size = _typeSize(u16(entry + 2)) * u32(entry + 4);
  if (size <= 0 || size > limit) return null;
  if (size <= 4) {
    var changed = false;
    for (var b = 0; b < 4; b++) {
      if (bytes[entry + 8 + b] != 0) {
        bytes[entry + 8 + b] = 0;
        changed = true;
      }
    }
    return changed;
  }
  final value = tiff + u32(entry + 8);
  if (value < tiff || value + size > limit) return null;
  var changed = false;
  for (var b = 0; b < size; b++) {
    if (bytes[value + b] != 0) {
      bytes[value + b] = 0;
      changed = true;
    }
  }
  return changed;
}

void _wipeIfd(
  Uint8List bytes,
  int tiff,
  int ifd,
  int limit,
  int Function(int offset) u16,
  int Function(int offset) u32,
) {
  if (ifd < tiff || ifd + 2 > limit) return;
  final count = u16(ifd);
  final entries = ifd + 2;
  final nextAt = entries + count * 12;
  if (count > 256 || nextAt + 4 > limit) return;
  for (var n = 0; n < count; n++) {
    final entry = entries + n * 12;
    final size = _typeSize(u16(entry + 2)) * u32(entry + 4);
    if (size <= 4 || size > limit) continue;
    final value = tiff + u32(entry + 8);
    if (value < tiff || value + size > limit) continue;
    for (var b = 0; b < size; b++) {
      bytes[value + b] = 0;
    }
  }
  for (var b = ifd; b < nextAt + 4; b++) {
    bytes[b] = 0;
  }
}

int _typeSize(int type) {
  switch (type) {
    case 1:
    case 2:
    case 6:
    case 7:
      return 1;
    case 3:
    case 8:
      return 2;
    case 4:
    case 9:
    case 11:
      return 4;
    case 5:
    case 10:
    case 12:
      return 8;
    default:
      return 0;
  }
}

bool _isPng(Uint8List bytes) {
  const sig = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < sig.length) return false;
  for (var i = 0; i < sig.length; i++) {
    if (bytes[i] != sig[i]) return false;
  }
  return true;
}

Uint8List? _pngWithoutLocation(Uint8List bytes) {
  final out = BytesBuilder(copy: false);
  out.add(bytes.sublist(0, 8));
  var i = 8;
  var changed = false;
  var sawIend = false;
  while (i + 12 <= bytes.length) {
    final length = _be32(bytes, i);
    if (length < 0 || i + 12 + length > bytes.length) return null;
    final type = String.fromCharCodes(bytes.sublist(i + 4, i + 8));
    final next = i + 12 + length;
    if (type == 'IEND') {
      out.add(bytes.sublist(i, next));
      sawIend = true;
      i = next;
      break;
    }
    if (_pngDropsLocation(type, bytes, i + 8, i + 8 + length)) {
      changed = true;
    } else {
      out.add(bytes.sublist(i, next));
    }
    i = next;
  }
  if (!sawIend || i != bytes.length) return null;
  return changed ? out.toBytes() : bytes;
}

bool _pngDropsLocation(String type, Uint8List bytes, int start, int end) {
  if (type == 'eXIf') return true;
  if (type != 'tEXt' && type != 'zTXt' && type != 'iTXt') return false;
  final keyword = _pngKeyword(bytes, start, end);
  if (keyword == null) return true;
  final lower = keyword.toLowerCase();
  return lower.contains('xmp') ||
      lower.contains('exif') ||
      lower.contains('gps') ||
      lower.startsWith('raw profile');
}

String? _pngKeyword(Uint8List bytes, int start, int end) {
  final chars = <int>[];
  for (var i = start; i < end; i++) {
    if (bytes[i] == 0) return String.fromCharCodes(chars);
    chars.add(bytes[i]);
    if (chars.length > 80) return null;
  }
  return null;
}

bool _isWebp(Uint8List bytes) {
  return bytes.length >= 12 &&
      _fourcc(bytes, 0) == 'RIFF' &&
      _fourcc(bytes, 8) == 'WEBP';
}

Uint8List? _webpWithoutLocation(Uint8List bytes) {
  final declared = _le32(bytes, 4);
  final riffEnd = 8 + declared;
  if (declared < 4 || riffEnd > bytes.length || riffEnd != bytes.length) {
    return null;
  }
  final chunks = BytesBuilder(copy: false);
  var i = 12;
  var changed = false;
  while (i + 8 <= riffEnd) {
    final type = _fourcc(bytes, i);
    final size = _le32(bytes, i + 4);
    if (size < 0) return null;
    final data = i + 8;
    final padded = size + (size & 1);
    if (data + padded > riffEnd) return null;
    if (type == 'EXIF' || type == 'XMP ') {
      changed = true;
    } else if (type == 'VP8X' && size >= 1) {
      final flags = bytes[data] & ~0x0C;
      if (flags != bytes[data]) changed = true;
      final chunk = Uint8List.fromList(bytes.sublist(i, data + padded));
      chunk[8] = flags;
      chunks.add(chunk);
    } else {
      chunks.add(bytes.sublist(i, data + padded));
    }
    i = data + padded;
  }
  if (i != riffEnd) return null;
  if (!changed) return bytes;
  final body = chunks.toBytes();
  final out = BytesBuilder(copy: false);
  out.add(const [0x52, 0x49, 0x46, 0x46]);
  out.add(_leBytes(body.length + 4));
  out.add(const [0x57, 0x45, 0x42, 0x50]);
  out.add(body);
  return out.toBytes();
}

bool _isHeif(Uint8List bytes) {
  if (bytes.length < 12 || _fourcc(bytes, 4) != 'ftyp') return false;
  const brands = {
    'heic',
    'heix',
    'hevc',
    'hevx',
    'heim',
    'heis',
    'hevm',
    'hevs',
    'mif1',
    'msf1',
    'avif',
    'avis',
  };
  if (brands.contains(_fourcc(bytes, 8))) return true;
  final size = _be32(bytes, 0);
  final end = size > 16 && size <= bytes.length ? size : bytes.length;
  for (var i = 16; i + 4 <= end; i += 4) {
    if (brands.contains(_fourcc(bytes, i))) return true;
  }
  return false;
}

Uint8List? _heifWithoutLocation(Uint8List bytes) {
  final copy = Uint8List.fromList(bytes);
  final scrub = _Scrub();
  if (!_scrubHeif(copy, scrub)) return null;
  return scrub.changed ? copy : bytes;
}

class _HeifBoxes {
  int? iinfStart;
  int? iinfEnd;
  int? ilocStart;
  int? ilocEnd;
  int? idatStart;
  int? idatEnd;
}

class _HeifItem {
  final int id;
  final String type;
  final String? mime;
  const _HeifItem(this.id, this.type, this.mime);
}

class _HeifExtent {
  final int method;
  final int offset;
  final int length;
  const _HeifExtent(this.method, this.offset, this.length);
}

bool _scrubHeif(Uint8List bytes, _Scrub scrub) {
  final boxes = _HeifBoxes();
  if (!_walkBoxes(bytes, 0, bytes.length, boxes, scrub)) return false;
  final iinfStart = boxes.iinfStart;
  final iinfEnd = boxes.iinfEnd;
  final ilocStart = boxes.ilocStart;
  final ilocEnd = boxes.ilocEnd;
  if (iinfStart == null ||
      iinfEnd == null ||
      ilocStart == null ||
      ilocEnd == null) {
    return false;
  }
  final items = _readHeifItems(bytes, iinfStart, iinfEnd);
  final locations = _readHeifLocations(bytes, ilocStart, ilocEnd);
  if (items == null || locations == null) return false;
  for (final entry in locations.entries) {
    final item = items[entry.key];
    if (item == null) return false;
    final extents = entry.value;
    if (_heifExif(item) && extents.length != 1) return false;
    for (final extent in extents) {
      if (!_scrubHeifExtent(bytes, item, extent, boxes, scrub)) return false;
    }
  }
  return true;
}

bool _walkBoxes(
  Uint8List bytes,
  int start,
  int end,
  _HeifBoxes boxes,
  _Scrub scrub, {
  bool fullBox = false,
}) {
  var i = start + (fullBox ? 4 : 0);
  if (i > end) return false;
  while (i + 8 <= end) {
    final size = _boxSize(bytes, i, end);
    if (size < 8) return false;
    final header = _be32(bytes, i) == 1 ? 16 : 8;
    if (size < header) return false;
    final type = _fourcc(bytes, i + 4);
    final content = i + header;
    final boxEnd = i + size;
    if (type == 'uuid' &&
        content + 16 <= boxEnd &&
        _isXmpUuid(bytes, content)) {
      _blank(bytes, content + 16, boxEnd, scrub);
    } else if (type == 'iinf') {
      boxes.iinfStart = content;
      boxes.iinfEnd = boxEnd;
    } else if (type == 'iloc') {
      boxes.ilocStart = content;
      boxes.ilocEnd = boxEnd;
    } else if (type == 'idat') {
      boxes.idatStart = content;
      boxes.idatEnd = boxEnd;
    } else if (type == 'meta') {
      if (!_walkBoxes(bytes, content, boxEnd, boxes, scrub, fullBox: true)) {
        return false;
      }
    } else if (type == 'moov' || type == 'iprp' || type == 'dinf') {
      if (!_walkBoxes(bytes, content, boxEnd, boxes, scrub)) return false;
    }
    i = boxEnd;
  }
  return i == end;
}

bool _isXmpUuid(Uint8List bytes, int start) {
  const uuid = [
    0xBE, 0x7A, 0xCF, 0xCB, 0x97, 0xA9, 0x42, 0xE8, //
    0x9C, 0x71, 0x99, 0x94, 0x91, 0xE3, 0xAF, 0xAC,
  ];
  for (var i = 0; i < uuid.length; i++) {
    if (bytes[start + i] != uuid[i]) return false;
  }
  return true;
}

Map<int, _HeifItem>? _readHeifItems(Uint8List bytes, int start, int end) {
  if (start + 4 > end) return null;
  final version = bytes[start];
  final countSize = version == 0 ? 2 : 4;
  var i = start + 4 + countSize;
  if (i > end) return null;
  final items = <int, _HeifItem>{};
  while (i + 8 <= end) {
    final size = _boxSize(bytes, i, end);
    if (size < 8) return null;
    final header = _be32(bytes, i) == 1 ? 16 : 8;
    if (_fourcc(bytes, i + 4) != 'infe') return null;
    final item = _readInfe(bytes, i + header, i + size);
    if (item == null) return null;
    items[item.id] = item;
    i += size;
  }
  if (i != end) return null;
  return items;
}

_HeifItem? _readInfe(Uint8List bytes, int start, int end) {
  if (start + 4 > end) return null;
  final version = bytes[start];
  var p = start + 4;
  if (version >= 2) {
    final idSize = version == 2 ? 2 : 4;
    if (version > 3 || p + idSize + 6 > end) return null;
    final id = idSize == 2 ? _be16(bytes, p) : _be32(bytes, p);
    p += idSize + 2;
    final type = _fourcc(bytes, p);
    p += 4;
    final name = _cString(bytes, p, end);
    if (name == null) return null;
    p = name.end;
    String? mime;
    if (type == 'mime') {
      final read = _cString(bytes, p, end);
      if (read == null) return null;
      mime = read.text;
    }
    return _HeifItem(id, type, mime);
  }
  if (p + 4 > end) return null;
  final id = _be16(bytes, p);
  p += 4;
  final name = _cString(bytes, p, end);
  if (name == null) return null;
  final mime = _cString(bytes, name.end, end);
  if (mime == null) return null;
  return _HeifItem(id, 'mime', mime.text);
}

class _CString {
  final String text;
  final int end;
  const _CString(this.text, this.end);
}

_CString? _cString(Uint8List bytes, int start, int end) {
  final chars = <int>[];
  for (var i = start; i < end; i++) {
    if (bytes[i] == 0) return _CString(String.fromCharCodes(chars), i + 1);
    chars.add(bytes[i]);
    if (chars.length > 256) return null;
  }
  return null;
}

Map<int, List<_HeifExtent>>? _readHeifLocations(
  Uint8List bytes,
  int start,
  int end,
) {
  if (start + 6 > end) return null;
  final version = bytes[start];
  if (version > 2) return null;
  var p = start + 4;
  final sizes = bytes[p++];
  final sizes2 = bytes[p++];
  final offsetSize = sizes >> 4;
  final lengthSize = sizes & 0x0F;
  final baseSize = sizes2 >> 4;
  final indexSize = version == 0 ? 0 : sizes2 & 0x0F;
  if (offsetSize > 4 || lengthSize > 4 || baseSize > 4 || indexSize > 4) {
    return null;
  }
  final count = version < 2 ? _be16(bytes, p) : _be32(bytes, p);
  p += version < 2 ? 2 : 4;
  if (count < 0 || count > 64) return null;
  final locations = <int, List<_HeifExtent>>{};
  for (var n = 0; n < count; n++) {
    final idSize = version < 2 ? 2 : 4;
    if (p + idSize + 4 > end) return null;
    final id = idSize == 2 ? _be16(bytes, p) : _be32(bytes, p);
    p += idSize;
    var method = 0;
    if (version == 1 || version == 2) {
      method = _be16(bytes, p) & 0x0F;
      p += 2;
    }
    p += 2;
    final base = _readBe(bytes, p, end, baseSize);
    if (base == null) return null;
    p += baseSize;
    if (p + 2 > end) return null;
    final extents = _be16(bytes, p);
    p += 2;
    if (extents < 0 || extents > 8) return null;
    final list = <_HeifExtent>[];
    for (var e = 0; e < extents; e++) {
      if ((version == 1 || version == 2) && indexSize > 0) {
        if (_readBe(bytes, p, end, indexSize) == null) return null;
        p += indexSize;
      }
      final offset = _readBe(bytes, p, end, offsetSize);
      if (offset == null) return null;
      p += offsetSize;
      final length = _readBe(bytes, p, end, lengthSize);
      if (length == null) return null;
      p += lengthSize;
      list.add(_HeifExtent(method, base + offset, length));
    }
    locations[id] = list;
  }
  if (p != end) return null;
  return locations;
}

bool _scrubHeifExtent(
  Uint8List bytes,
  _HeifItem item,
  _HeifExtent extent,
  _HeifBoxes boxes,
  _Scrub scrub,
) {
  if (extent.length < 0) return false;
  var start = extent.offset;
  if (extent.method == 1) {
    final idat = boxes.idatStart;
    if (idat == null) return false;
    start = idat + extent.offset;
  } else if (extent.method != 0) {
    return !_heifLocation(item);
  }
  final end = start + extent.length;
  if (start < 0 || end > bytes.length) return false;
  if (_heifExif(item)) {
    if (extent.length < 4) return false;
    final header = _be32(bytes, start);
    final tiff = start + 4 + header;
    if (header < 0 || tiff < start || tiff >= end) return false;
    return _scrubTiff(bytes, tiff, end, 0, scrub);
  }
  if (_heifXmp(item)) {
    _blank(bytes, start, end, scrub);
    return true;
  }
  if (_heifJpeg(item)) {
    return _scrubJpeg(bytes, start, end, 0, scrub);
  }
  return true;
}

bool _heifExif(_HeifItem item) => item.type == 'Exif';

bool _heifXmp(_HeifItem item) {
  final mime = (item.mime ?? '').toLowerCase();
  if (item.type == 'mime') {
    return mime.contains('xmp') || mime.contains('rdf+xml');
  }
  return item.type == 'xml ';
}

bool _heifJpeg(_HeifItem item) {
  return item.type == 'mime' &&
      (item.mime ?? '').toLowerCase().contains('jpeg');
}

bool _heifLocation(_HeifItem item) {
  return _heifExif(item) || _heifXmp(item) || _heifJpeg(item);
}

int _boxSize(Uint8List bytes, int i, int end) {
  final size = _be32(bytes, i);
  if (size == 0) return end - i;
  if (size == 1) {
    if (i + 16 > end) return -1;
    final large = _be64(bytes, i + 8);
    if (large < 16 || large > end - i) return -1;
    return large;
  }
  if (size < 8 || i + size > end) return -1;
  return size;
}

int _be16(Uint8List bytes, int offset) {
  return (bytes[offset] << 8) | bytes[offset + 1];
}

int _be32(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

int _be64(Uint8List bytes, int offset) {
  var value = 0;
  for (var i = 0; i < 8; i++) {
    value = (value << 8) | bytes[offset + i];
  }
  return value;
}

int? _readBe(Uint8List bytes, int offset, int end, int size) {
  if (size == 0) return 0;
  if (offset + size > end) return null;
  var value = 0;
  for (var i = 0; i < size; i++) {
    value = (value << 8) | bytes[offset + i];
  }
  return value;
}

int _le32(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

List<int> _leBytes(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}

String _fourcc(Uint8List bytes, int offset) {
  return String.fromCharCodes(bytes.sublist(offset, offset + 4));
}
