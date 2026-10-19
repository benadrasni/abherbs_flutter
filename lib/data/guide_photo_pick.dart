import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const _photoChannel = MethodChannel('sk.ab.herbs/photo');

/// A photo chosen from the device. Android asks the system photo picker to
/// keep the picture's location. The picker still lets the person leave it
/// out. Anywhere else, the image picker is used.
Future<String?> pickGuideDevicePhoto({
  required double maxWidth,
  bool? android,
  Future<String?> Function(double maxWidth)? imagePicker,
}) async {
  final useAndroid = android ?? Platform.isAndroid;
  if (useAndroid) {
    try {
      final path = await _photoChannel.invokeMethod<String>('pick', {
        'maxWidth': maxWidth,
      });
      if (path == null || path.isEmpty) return null;
      return path;
    } on PlatformException catch (error) {
      if (error.code != 'unavailable') rethrow;
    }
  }
  final pick = imagePicker ?? _imagePickerPath;
  return pick(maxWidth);
}

Future<String?> _imagePickerPath(double maxWidth) async {
  final image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: maxWidth,
  );
  return image?.path;
}

@visibleForTesting
const MethodChannel guidePhotoChannel = _photoChannel;
