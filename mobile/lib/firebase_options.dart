// PLACEHOLDER Firebase configuration for local development against the
// Firebase Emulator Suite (project `demo-readin`, see /firebase.json).
//
// TODO(readin): for staging/production run `flutterfire configure` with the
// real projects (readin-staging / readin-prod). It overwrites this file and adds
// google-services.json / GoogleService-Info.plist (both git-ignored).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => ios,
        _ => android,
      };

  static const android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-readin',
    storageBucket: 'demo-readin.appspot.com',
  );

  static const ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-readin',
    storageBucket: 'demo-readin.appspot.com',
    iosBundleId: 'app.readin.readin',
  );
}
