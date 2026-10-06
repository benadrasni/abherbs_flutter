import 'dart:io';

/// Removes the offline family and photo folders.
///
/// Callers await this before clearing the prefs that record those folders.
Future<void> deleteOfflineDirectories({
  required Directory families,
  required Directory photos,
}) async {
  if (await families.exists()) {
    await families.delete(recursive: true);
  }
  if (await photos.exists()) {
    await photos.delete(recursive: true);
  }
}
