// Firebase configuration for the `prod` flavor: the single real project
// `readin-cca78` (ADR 0005), used only for Cloud Messaging and the Realtime
// Database (SPEC §21). Values come from the Android and iOS apps registered in
// that project (docs/setup/firebase.md step 5). They are public client
// identifiers, not secrets; google-services.json / GoogleService-Info.plist
// stay git-ignored because the options are passed explicitly.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => ios,
        _ => android,
      };

  static const databaseUrl = 'https://readin-cca78-default-rtdb.europe-west1.firebasedatabase.app';

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBJzmmopWlCa2SJITB8b2KTtaTBP_TIalg',
    appId: '1:56680910112:android:85d359b8d330b586ba9b45',
    messagingSenderId: '56680910112',
    projectId: 'readin-cca78',
    databaseURL: databaseUrl,
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyDqC2Wum9ZI6eZ-M1fLt4mUYkryyA5xPmA',
    appId: '1:56680910112:ios:cc6670df9cf083f2ba9b45',
    messagingSenderId: '56680910112',
    projectId: 'readin-cca78',
    databaseURL: databaseUrl,
    iosBundleId: 'app.readin.readin',
  );
}
