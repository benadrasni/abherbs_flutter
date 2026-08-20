import 'dart:io';

import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Failed host lookup is a transient network error', () {
    expect(
      isTransientNetworkError(const SocketException(
        "Failed host lookup: 'storage.googleapis.com'",
        osError: OSError('No address associated with hostname', 7),
      )),
      isTrue,
    );
    expect(
      isTransientNetworkError(
        'ClientException with SocketException: Failed host lookup: \'storage.googleapis.com\' (OS Error: No address associated with hostname, errno = 7), uri=https://storage.googleapis.com/abherbs-resources/photos/x.webp',
      ),
      isTrue,
    );
  });

  test('image resource service FlutterErrors are ignored', () {
    expect(
      isIgnorableFlutterError(FlutterErrorDetails(
        exception: const SocketException("Failed host lookup: 'storage.googleapis.com'"),
        library: 'image resource service',
      )),
      isTrue,
    );
  });

  test('unrelated errors are not ignored', () {
    expect(isTransientNetworkError(StateError('bad state')), isFalse);
    expect(
      isIgnorableFlutterError(FlutterErrorDetails(
        exception: StateError('bad state'),
        library: 'widgets library',
      )),
      isFalse,
    );
  });

  test('MissingPluginException on EventChannel cancel is teardown', () {
    final error = MissingPluginException(
      'No implementation found for method cancel on channel lists_4_v2/1_1_1_11-[DEFAULT]-null-DatabaseEventType.value-[]#10',
    );
    expect(isIgnorablePluginTeardown(error), isTrue);
    expect(isIgnorableNonFatalError(error), isTrue);
    expect(
      isIgnorableFlutterError(FlutterErrorDetails(exception: error)),
      isTrue,
    );
  });

  test('other MissingPluginExceptions are not ignored', () {
    final error = MissingPluginException(
      'No implementation found for method getBatteryLevel on channel samples.flutter.dev/battery',
    );
    expect(isIgnorablePluginTeardown(error), isFalse);
    expect(isIgnorableNonFatalError(error), isFalse);
  });
}
