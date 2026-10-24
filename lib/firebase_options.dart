import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions: unsupported platform $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA0d6rW2vyE2jesmFfIywGawIwAM984cEM',
    appId: '1:1028964662835:android:e3a7e8621a1c139604ad46',
    messagingSenderId: '1028964662835',
    projectId: 'efeler-running-club',
    storageBucket: 'efeler-running-club.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBOfi4l4gWcLEytxmcfGfpZGObXkhJU1sg',
    appId: '1:1028964662835:ios:85340b01a9ae82d604ad46',
    messagingSenderId: '1028964662835',
    projectId: 'efeler-running-club',
    storageBucket: 'efeler-running-club.firebasestorage.app',
    iosBundleId: 'com.efelerrunningclub.app',
  );
}
