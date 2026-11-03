import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';

/// Whether Firebase initialized. The app must still launch without it
/// (guest mode), e.g. when the emulator isn't running or config is missing.
class FirebaseStatus {
  const FirebaseStatus({required this.available});

  final bool available;
}

abstract final class FirebaseBootstrap {
  static const authEmulatorPort = 9099;

  static Future<FirebaseStatus> init(AppConfig config) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (config.useFirebaseEmulator) {
        await FirebaseAuth.instance.useAuthEmulator(config.emulatorHost, authEmulatorPort);
      }
      return const FirebaseStatus(available: true);
    } catch (error, stack) {
      debugPrint('Firebase unavailable, continuing as guest: $error');
      debugPrintStack(stackTrace: stack, maxFrames: 5);
      return const FirebaseStatus(available: false);
    }
  }
}
