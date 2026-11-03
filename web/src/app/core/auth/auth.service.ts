import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import type { Auth, User } from 'firebase/auth';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../../environments/environment';
import { MeDto } from '../api/models';
import { MeApi } from '../api/me.api';
import { LanguageService } from '../i18n/language.service';
import { ThemeService } from '../theme/theme.service';
import { FirebaseUserSummary, SessionStore } from './session.store';

type FirebaseAuthModule = typeof import('firebase/auth');
interface FirebaseHandle {
  auth: Auth;
  sdk: FirebaseAuthModule;
}

/** If Firebase never reports a session (offline, blocked SDK), browse as a guest after this delay. */
const RESOLVE_TIMEOUT_MS = 5000;

export function localTimeZone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || 'Africa/Cairo';
  } catch {
    return 'Africa/Cairo';
  }
}

/**
 * Firebase Authentication (SPEC §9) — browser only. The Firebase SDK is lazy-loaded so it never runs during SSR
 * and stays out of the initial bundle. After each sign-in the user is synced with `POST /auth/sync`; SQL Server
 * stays the source of truth for roles and permissions (returned in `MeDto`).
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly session = inject(SessionStore);
  private readonly meApi = inject(MeApi);
  private readonly language = inject(LanguageService);
  private readonly theme = inject(ThemeService);

  private firebasePromise: Promise<FirebaseHandle> | null = null;
  private syncState: { uid: string; promise: Promise<MeDto | null> } | null = null;
  /** Suppresses the token listener's sync while sign-up sets the display name first. */
  private signingUp = false;
  private resolveAuth!: () => void;
  /** Resolves once Firebase has reported the initial session (never resolves on the server). */
  readonly resolved = new Promise<void>((resolve) => (this.resolveAuth = resolve));

  /** Starts listening to Firebase. Non-blocking; called once from an app initializer. */
  init(): void {
    if (!this.isBrowser) return;
    const timeout = setTimeout(() => this.markGuestIfUnresolved(), RESOLVE_TIMEOUT_MS);
    this.firebase()
      .then(({ auth, sdk }) =>
        sdk.onIdTokenChanged(auth, (user) => {
          clearTimeout(timeout);
          this.onUser(user);
        }),
      )
      .catch(() => {
        clearTimeout(timeout);
        this.markGuestIfUnresolved();
      });
  }

  /** Waits for the initial session and, when signed in, for the `/auth/sync` round-trip. */
  async whenReady(): Promise<MeDto | null> {
    await this.resolved;
    return this.syncState?.promise ?? this.session.me();
  }

  async getIdToken(): Promise<string | null> {
    if (!this.isBrowser || this.session.isGuest()) return null;
    try {
      const { auth } = await this.firebase();
      await auth.authStateReady(); // currentUser is null until the persisted session is restored
      return (await auth.currentUser?.getIdToken()) ?? null;
    } catch {
      return null;
    }
  }

  async signInWithEmail(email: string, password: string): Promise<MeDto | null> {
    const { auth, sdk } = await this.firebase();
    const credential = await sdk.signInWithEmailAndPassword(auth, email.trim(), password);
    return this.ensureSynced(credential.user.uid);
  }

  async signInWithGoogle(): Promise<MeDto | null> {
    const { auth, sdk } = await this.firebase();
    const credential = await sdk.signInWithPopup(auth, new sdk.GoogleAuthProvider());
    return this.ensureSynced(credential.user.uid);
  }

  async signUp(displayName: string, email: string, password: string): Promise<MeDto | null> {
    const { auth, sdk } = await this.firebase();
    this.signingUp = true;
    try {
      const credential = await sdk.createUserWithEmailAndPassword(auth, email.trim(), password);
      await sdk.updateProfile(credential.user, { displayName: displayName.trim() });
      // Refresh so the ID token carries the `name` claim that /auth/sync reads.
      await credential.user.getIdToken(true);
      sdk.sendEmailVerification(credential.user).catch(() => undefined);
      this.session.setUser(summarize(credential.user));
      return await this.ensureSynced(credential.user.uid);
    } finally {
      this.signingUp = false;
    }
  }

  async sendPasswordReset(email: string): Promise<void> {
    const { auth, sdk } = await this.firebase();
    await sdk.sendPasswordResetEmail(auth, email.trim());
  }

  async signOut(): Promise<void> {
    const { auth, sdk } = await this.firebase();
    await sdk.signOut(auth);
    this.syncState = null;
    this.session.setGuest();
  }

  /** Re-reads `/me` (e.g. after onboarding) and updates the session. */
  async refreshMe(): Promise<MeDto | null> {
    try {
      const me = await firstValueFrom(this.meApi.get({ silent: true }));
      this.session.setMe(me);
      return me;
    } catch {
      return this.session.me();
    }
  }

  private onUser(user: User | null): void {
    if (!user) {
      this.syncState = null;
      this.session.setGuest();
    } else {
      this.session.setUser(summarize(user));
      if (!this.signingUp) void this.ensureSynced(user.uid);
    }
    this.resolveAuth();
  }

  private ensureSynced(uid: string): Promise<MeDto | null> {
    if (this.syncState?.uid === uid) return this.syncState.promise;
    const promise = this.sync().then((me) => {
      if (!me && this.syncState?.uid === uid) this.syncState = null; // allow a retry
      return me;
    });
    this.syncState = { uid, promise };
    return promise;
  }

  private async sync(): Promise<MeDto | null> {
    this.session.setSyncing(true);
    try {
      const me = await firstValueFrom(this.meApi.sync({ uiLanguage: this.language.lang(), timeZone: localTimeZone() }));
      this.session.setMe(me);
      // The profile is the cross-device source of truth for theme and UI language (SPEC §15.5, F18).
      this.theme.setPreference(me.theme);
      await this.language.setLanguage(me.uiLanguage);
      return me;
    } catch {
      this.session.setSyncFailed();
      return null;
    }
  }

  private markGuestIfUnresolved(): void {
    if (!this.session.isResolved()) this.session.setGuest();
    this.resolveAuth();
  }

  private firebase(): Promise<FirebaseHandle> {
    if (!this.isBrowser) return Promise.reject(new Error('Firebase Auth is browser-only'));
    this.firebasePromise ??= (async () => {
      const [{ initializeApp, getApps }, sdk] = await Promise.all([import('firebase/app'), import('firebase/auth')]);
      const app = getApps()[0] ?? initializeApp(environment.firebase);
      const auth = sdk.getAuth(app);
      if (environment.authEmulatorUrl) sdk.connectAuthEmulator(auth, environment.authEmulatorUrl, { disableWarnings: true });
      auth.languageCode = this.language.lang();
      return { auth, sdk };
    })();
    return this.firebasePromise;
  }
}

function summarize(user: User): FirebaseUserSummary {
  return {
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    emailVerified: user.emailVerified,
  };
}

/** Maps Firebase Auth error codes to translation keys under `auth.errors`. */
export function authErrorKey(error: unknown): string {
  const code = (error as { code?: string } | null)?.code ?? '';
  switch (code) {
    case 'auth/invalid-credential':
    case 'auth/wrong-password':
    case 'auth/user-not-found':
    case 'auth/invalid-login-credentials':
      return 'auth.errors.invalidCredential';
    case 'auth/email-already-in-use':
      return 'auth.errors.emailInUse';
    case 'auth/weak-password':
      return 'auth.errors.weakPassword';
    case 'auth/invalid-email':
      return 'auth.errors.invalidEmail';
    case 'auth/too-many-requests':
      return 'auth.errors.tooMany';
    case 'auth/network-request-failed':
      return 'auth.errors.network';
    case 'auth/popup-closed-by-user':
    case 'auth/cancelled-popup-request':
      return 'auth.errors.popupClosed';
    case 'auth/popup-blocked':
      return 'auth.errors.popupBlocked';
    default:
      return 'auth.errors.generic';
  }
}
