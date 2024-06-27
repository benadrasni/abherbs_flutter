// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMSjEX6VXmPXvkT-q4CgUrQI2DfNVE7Kw',
    appId: '1:319603655901:android:768ad9d1a7ed119f',
    messagingSenderId: '319603655901',
    projectId: 'abherbs-backend',
    databaseURL: 'https://abherbs-backend.firebaseio.com',
    storageBucket: 'abherbs-backend.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4tQNf5gkVM8AoyidW-1sqnq3Ds1JyQHY',
    appId: '1:319603655901:ios:768ad9d1a7ed119f',
    messagingSenderId: '319603655901',
    projectId: 'abherbs-backend',
    databaseURL: 'https://abherbs-backend.firebaseio.com',
    storageBucket: 'abherbs-backend.appspot.com',
    androidClientId: '319603655901-654lpnt9ssvm7qpms45bqj7l153751of.apps.googleusercontent.com',
    iosClientId: '319603655901-t1m598jgupm97c74totm6h5g2d8692f5.apps.googleusercontent.com',
    iosBundleId: 'sk.ab.herbs',
  );
}
