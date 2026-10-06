import 'dart:io';

import 'package:abherbs_flutter/offline/offline_dirs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline folders are gone before the delete future finishes', () async {
    final root = await Directory.systemTemp.createTemp('offline-dirs');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final families = Directory('${root.path}/families')..createSync();
    final photos = Directory('${root.path}/photos')..createSync();
    File('${families.path}/family.txt').writeAsStringSync('family');
    File('${photos.path}/photo.txt').writeAsStringSync('photo');

    await deleteOfflineDirectories(families: families, photos: photos);

    expect(families.existsSync(), isFalse);
    expect(photos.existsSync(), isFalse);
    expect(root.existsSync(), isTrue);
  });
}
