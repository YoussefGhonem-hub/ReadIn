import { InjectionToken } from '@angular/core';
import { environment } from '../../../environments/environment';
import { liveFirebaseApp } from '../firebase/live-app';

/** Stops a listener. */
export type Unsubscribe = () => void;

/** The few Realtime Database operations ReadIn needs; tests replace it with a fake. */
export interface LiveConnection {
  /** Calls `next` with the value at `path` now and on every change (`null` when missing or not readable). */
  onValue(path: string, next: (value: unknown) => void): Unsubscribe;
  /** Calls `next` for each child of `path` whose `orderBy` field is at least `since` (server time, ms). */
  onChildAddedSince(path: string, orderBy: string, since: number, next: (key: string, value: unknown) => void): Unsubscribe;
  /** The server's clock in ms, so clients with a wrong clock still ask for the right events. */
  serverTime(): Promise<number>;
  /** Uses a Firebase custom token from `POST /realtime/token` to read `/live/users/{id}`. Not a ReadIn sign-in. */
  signIn(customToken: string): Promise<void>;
  signOut(): Promise<void>;
  /** Calls `next` with `true` while the socket to the Realtime Database is open. */
  onConnectedChange(next: (connected: boolean) => void): Unsubscribe;
}

/** Opens the connection. Only called in the browser; the Firebase SDK is loaded lazily. */
export const LIVE_CONNECTOR = new InjectionToken<() => Promise<LiveConnection>>('LIVE_CONNECTOR', {
  providedIn: 'root',
  factory: () => connectToFirebase,
});

async function connectToFirebase(): Promise<LiveConnection> {
  const [app, db, authSdk] = await Promise.all([liveFirebaseApp(), import('firebase/database'), import('firebase/auth')]);
  const database = db.getDatabase(app);
  if (environment.databaseEmulatorHost) {
    const [host, port] = environment.databaseEmulatorHost.split(':');
    db.connectDatabaseEmulator(database, host, Number(port));
  }
  // In memory: the token is fetched again on each page load, so a session never outlives the ReadIn one.
  const auth = authSdk.initializeAuth(app, { persistence: authSdk.inMemoryPersistence });
  if (environment.authEmulatorUrl) authSdk.connectAuthEmulator(auth, environment.authEmulatorUrl, { disableWarnings: true });

  const ignoreCancel = () => undefined; // permission denied or the listener was revoked: keep the REST values
  return {
    onValue: (path, next) => db.onValue(db.ref(database, path), (snapshot) => next(snapshot.val()), ignoreCancel),
    onChildAddedSince: (path, orderBy, since, next) =>
      db.onChildAdded(
        db.query(db.ref(database, path), db.orderByChild(orderBy), db.startAt(since)),
        (snapshot) => next(snapshot.key ?? '', snapshot.val()),
        ignoreCancel,
      ),
    serverTime: () =>
      new Promise<number>((resolve) =>
        db.onValue(
          db.ref(database, '.info/serverTimeOffset'),
          (snapshot) => resolve(Date.now() + (Number(snapshot.val()) || 0)),
          { onlyOnce: true },
        ),
      ),
    signIn: async (customToken) => {
      await authSdk.signInWithCustomToken(auth, customToken);
    },
    signOut: () => authSdk.signOut(auth),
    onConnectedChange: (next) => db.onValue(db.ref(database, '.info/connected'), (snapshot) => next(snapshot.val() === true)),
  };
}
