import 'dart:io';
import 'dart:typed_data';

/// JPEG bytes with the GPS EXIF directory removed.
///
/// The observation reads the coordinates first. Plant.id and the public
/// photo must not receive them. A file that is not a JPEG, or a JPEG with
/// no GPS directory, is returned unchanged.
Uint8List jpegWithoutGps(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return bytes;
  final out = Uint8List.fromList(bytes);
  var changed = false;
  var i = 2;
  while (i + 1 < out.length) {
    if (out[i] != 0xFF) break;
    while (i < out.length && out[i] == 0xFF) {
      i++;
    }
    if (i >= out.length) break;
    final marker = out[i];
    i++;
    if (marker == 0xD9 || marker == 0xDA) break;
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) continue;
    if (i + 2 > out.length) break;
    final length = (out[i] << 8) | out[i + 1];
    if (length < 2 || i + length > out.length) break;
    final start = i + 2;
    final end = i + length;
    if (marker == 0xE1 && _isExif(out, start, end)) {
      if (_stripGps(out, start + 6, end)) changed = true;
    }
    i = end;
  }
  return changed ? out : bytes;
}

/// The photo-picker cache. Other camera files stay where they are.
bool guidePickCachePath(String path) {
  final parts = path.replaceAll('\\', '/').split('/');
  return parts.length >= 2 && parts[parts.length - 2] == 'guide-pick';
}

/// Writes [from] to [to] without GPS, then deletes a photo-picker cache file.
Future<void> copyGuidePhotoWithoutGps(String from, String to) async {
  final bytes = jpegWithoutGps(await File(from).readAsBytes());
  await File(to).writeAsBytes(bytes);
  await deleteGuidePickCache(from);
}

/// Drops a file left in `cacheDir/guide-pick` after it has been copied.
Future<void> deleteGuidePickCache(String path) async {
  if (!guidePickCachePath(path)) return;
  final file = File(path);
  if (await file.exists()) await file.delete();
}

bool _isExif(Uint8List bytes, int start, int end) {
  const header = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
  if (start + header.length > end) return false;
  for (var i = 0; i < header.length; i++) {
    if (bytes[start + i] != header[i]) return false;
  }
  return true;
}

bool _stripGps(Uint8List bytes, int tiff, int limit) {
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
  var ifd = tiff + u32(tiff + 4);
  var changed = false;
  for (var hop = 0; hop < 2; hop++) {
    if (ifd < tiff || ifd + 2 > limit) break;
    final count = u16(ifd);
    final entries = ifd + 2;
    final nextAt = entries + count * 12;
    if (count > 256 || nextAt + 4 > limit) break;
    for (var n = 0; n < count; n++) {
      final entry = entries + n * 12;
      if (u16(entry) != 0x8825) continue;
      final gps = tiff + u32(entry + 8);
      _wipeIfd(bytes, tiff, gps, limit, u16, u32);
      for (var b = 0; b < 12; b++) {
        bytes[entry + b] = 0;
      }
      changed = true;
    }
    final next = u32(nextAt);
    if (next == 0) break;
    ifd = tiff + next;
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
