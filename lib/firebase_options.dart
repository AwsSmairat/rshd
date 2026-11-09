// Firebase app options for the existing "rshd-academy" project.
//
// Written from android/app/google-services.json and
// ios/Runner/GoogleService-Info.plist (the same values `flutterfire
// configure` would generate), so no new Firebase apps were registered.
// These are client identifiers, not secrets.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  /// The options for this platform, or null where push isn't set up.
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqU-zNF3_BLx-84ralFa-yde8rGuyu4QI',
    appId: '1:353270987285:android:eb2fd9896b19ea9b4cec1c',
    messagingSenderId: '353270987285',
    projectId: 'rshd-academy',
    storageBucket: 'rshd-academy.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB9ruK79bdWaENVPGN79ZpYkA1DoftZQ5Q',
    appId: '1:353270987285:ios:c4655153b153056e4cec1c',
    messagingSenderId: '353270987285',
    projectId: 'rshd-academy',
    storageBucket: 'rshd-academy.firebasestorage.app',
    iosBundleId: 'com.rshdacademy.rshd',
  );
}
