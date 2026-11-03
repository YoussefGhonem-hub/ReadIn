import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart' as emulator;
import '../../firebase_options_prod.dart' as prod;
import '../config/app_config.dart';

/// Whether Firebase initialized. The app must still launch without it (no pushes or live updates), e.g. when the
/// emulator isn't running or config is missing.
class FirebaseStatus {
  const FirebaseStatus({required this.available});

  final bool available;
}

abstract final class FirebaseBootstrap {
  /// The Auth emulator, only for the live connection's custom-token sign in.
  static const authEmulatorPort = 9099;

  /// `dev` never touches the real project; only `prod` uses its options.
  static FirebaseOptions optionsFor(Flavor flavor) => switch (flavor) {
        Flavor.dev => emulator.DefaultFirebaseOptions.currentPlatform,
        Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
      };

  static Future<FirebaseStatus> init(AppConfig config) async {
    try {
      // Cloud Messaging and the Realtime Database only (ADR 0008). Nobody signs in to Firebase on this app; the live
      // connection signs its own app in with a custom token (FirebaseLiveConnector).
      await Firebase.initializeApp(options: optionsFor(config.flavor));
      return const FirebaseStatus(available: true);
    } catch (error, stack) {
      debugPrint('Firebase unavailable, continuing without push and live updates: $error');
      debugPrintStack(stackTrace: stack, maxFrames: 5);
      return const FirebaseStatus(available: false);
    }
  }
}
