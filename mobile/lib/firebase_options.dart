// Firebase configuration for the `dev` flavor: the Firebase Emulator Suite
// (project `demo-readin`, see /firebase.json). Never point this at the real
// project; the `prod` flavor uses lib/firebase_options_prod.dart (ADR 0005).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => ios,
        _ => android,
      };

  /// Namespace `demo-readin`, the same one the API writes to (`?ns=demo-readin`);
  /// the emulator host replaces this URL's host at runtime.
  static const databaseUrl = 'https://demo-readin.firebaseio.com';

  static const android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-readin',
    databaseURL: databaseUrl,
  );

  static const ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-readin',
    databaseURL: databaseUrl,
    iosBundleId: 'app.readin.readin',
  );
}
