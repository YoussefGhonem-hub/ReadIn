import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:injectable/injectable.dart';

import '../config/app_config.dart';
import '../firebase/firebase_bootstrap.dart';

/// The few Realtime Database operations ReadIn needs (SPEC §21.2); tests use a fake.
abstract interface class LiveConnection {
  /// The value at [path] now and on every change; null when missing. Errors
  /// (e.g. permission denied) end the stream quietly: callers keep REST values.
  Stream<Object?> onValue(String path);

  /// Children of [path] whose [orderBy] field is at least [since] (server time, ms).
  Stream<(String, Object?)> onChildAddedSince(String path, String orderBy, int since);

  /// The server's clock in ms, so a device with a wrong clock still asks for the right events.
  Future<int> serverTime();

  /// Reads `/live/users/{id}` with a custom token from `POST /realtime/token`. Not a ReadIn sign-in.
  Future<void> signIn(String customToken);

  Future<void> signOut();

  /// Closes the socket while the app is in the background and reopens it on resume.
  void setOnline(bool online);
}

/// Opens the [LiveConnection]. Fails when Firebase is unavailable; callers then stay on REST.
abstract interface class LiveConnector {
  Future<LiveConnection> open();
}

@LazySingleton(as: LiveConnector)
class FirebaseLiveConnector implements LiveConnector {
  FirebaseLiveConnector(this._config, this._firebase);

  final AppConfig _config;
  final FirebaseStatus _firebase;

  /// A separate Firebase app, so the database's custom-token session never
  /// replaces the default app's session.
  static const appName = 'readin-live';
  static const databaseEmulatorPort = 9000;

  @override
  Future<LiveConnection> open() async {
    if (!_firebase.available) throw StateError('Firebase is unavailable');
    final options = FirebaseBootstrap.optionsFor(_config.flavor);
    final existing = Firebase.apps.where((app) => app.name == appName);
    final app = existing.isNotEmpty ? existing.first : await Firebase.initializeApp(name: appName, options: options);
    final database = FirebaseDatabase.instanceFor(app: app, databaseURL: options.databaseURL);
    final auth = FirebaseAuth.instanceFor(app: app);
    if (_config.useFirebaseEmulator) {
      database.useDatabaseEmulator(_config.emulatorHost, databaseEmulatorPort);
      await auth.useAuthEmulator(_config.emulatorHost, FirebaseBootstrap.authEmulatorPort);
    }
    return _FirebaseLiveConnection(database, auth);
  }
}

class _FirebaseLiveConnection implements LiveConnection {
  _FirebaseLiveConnection(this._database, this._auth);

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  @override
  Stream<Object?> onValue(String path) =>
      _database.ref(path).onValue.map((event) => event.snapshot.value).handleError((Object _) {});

  @override
  Stream<(String, Object?)> onChildAddedSince(String path, String orderBy, int since) => _database
      .ref(path)
      .orderByChild(orderBy)
      .startAt(since)
      .onChildAdded
      .map((event) => (event.snapshot.key ?? '', event.snapshot.value))
      .handleError((Object _) {});

  @override
  Future<int> serverTime() async {
    final offset = (await _database.ref('.info/serverTimeOffset').get()).value;
    return DateTime.now().millisecondsSinceEpoch + (offset is num ? offset.toInt() : 0);
  }

  @override
  Future<void> signIn(String customToken) => _auth.signInWithCustomToken(customToken);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  void setOnline(bool online) => online ? _database.goOnline() : _database.goOffline();
}
