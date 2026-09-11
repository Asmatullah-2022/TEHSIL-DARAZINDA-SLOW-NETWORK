// GENERATED PLACEHOLDER — replace by running `flutterfire configure` with
// a real Firebase project before building a release. Never commit real
// API keys from a production Firebase project to a public repository;
// use per-environment CI secrets instead. This file intentionally
// contains no live credentials.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run `flutterfire configure` to generate real values.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    projectId: 'darazinda-connect',
    storageBucket: 'darazinda-connect.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    projectId: 'darazinda-connect',
    storageBucket: 'darazinda-connect.appspot.com',
    iosBundleId: 'pk.darazindaconnect.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    projectId: 'darazinda-connect',
    storageBucket: 'darazinda-connect.appspot.com',
  );
}
