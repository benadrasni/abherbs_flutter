import 'package:abherbs_flutter/data/guide_photo_pick.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(guidePhotoChannel, null);
  });

  void mock(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(guidePhotoChannel, handler);
  }

  test('Android returns the picker file and skips the image picker', () async {
    mock((call) async {
      expect(call.method, 'pick');
      expect(call.arguments, {'maxWidth': 2048.0});
      return '/cache/flower.jpg';
    });
    final path = await pickGuideDevicePhoto(
      maxWidth: 2048,
      android: true,
      imagePicker: (_) async => fail('image picker'),
    );
    expect(path, '/cache/flower.jpg');
  });

  test('a cancelled picker returns null', () async {
    mock((_) async => null);
    final path = await pickGuideDevicePhoto(
      maxWidth: 800,
      android: true,
      imagePicker: (_) async => fail('image picker'),
    );
    expect(path, isNull);
  });

  test('an empty path is a cancel', () async {
    mock((_) async => '');
    final path = await pickGuideDevicePhoto(
      maxWidth: 800,
      android: true,
      imagePicker: (_) async => fail('image picker'),
    );
    expect(path, isNull);
  });

  test('a missing picker falls back to the image picker', () async {
    mock((_) async => throw PlatformException(code: 'unavailable'));
    final path = await pickGuideDevicePhoto(
      maxWidth: 1200,
      android: true,
      imagePicker: (width) async {
        expect(width, 1200);
        return '/gallery.jpg';
      },
    );
    expect(path, '/gallery.jpg');
  });

  test('other picker errors are not swallowed', () async {
    mock((_) async => throw PlatformException(code: 'busy'));
    expect(
      () => pickGuideDevicePhoto(
        maxWidth: 100,
        android: true,
        imagePicker: (_) async => '/nope.jpg',
      ),
      throwsA(isA<PlatformException>()),
    );
  });

  test('other platforms use the image picker', () async {
    var called = false;
    mock((_) async {
      called = true;
      return '/native.jpg';
    });
    final path = await pickGuideDevicePhoto(
      maxWidth: 640,
      android: false,
      imagePicker: (width) async {
        expect(width, 640);
        return '/ios.jpg';
      },
    );
    expect(path, '/ios.jpg');
    expect(called, isFalse);
  });
}
