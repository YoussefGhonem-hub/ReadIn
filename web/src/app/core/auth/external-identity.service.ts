import { DOCUMENT, Injectable, InjectionToken, PLATFORM_ID, computed, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { environment } from '../../../environments/environment';
import { ExternalCredential, ExternalProvider } from '../api/models';
import { AuthConfigService } from './auth-config.service';

/** Public client ids for Google Identity Services and Sign in with Apple JS (ADR 0012). Empty = not on the web. */
export interface ExternalClientIds {
  google: string;
  apple: string;
}

export const EXTERNAL_CLIENT_IDS = new InjectionToken<ExternalClientIds>('EXTERNAL_CLIENT_IDS', {
  providedIn: 'root',
  factory: () => ({ google: environment.googleWebClientId, apple: environment.appleServicesId }),
});

export const GOOGLE_GSI_SRC = 'https://accounts.google.com/gsi/client';
export const APPLE_JS_SRC = 'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js';

/** The parts of Google Identity Services ReadIn uses (`google.accounts.id`). */
export interface GoogleAccountsId {
  initialize(config: {
    client_id: string;
    callback: (response: { credential?: string }) => void;
    ux_mode?: 'popup' | 'redirect';
    auto_select?: boolean;
    itp_support?: boolean;
  }): void;
  renderButton(
    parent: HTMLElement,
    options: {
      type?: 'standard' | 'icon';
      theme?: 'outline' | 'filled_blue' | 'filled_black';
      size?: 'large' | 'medium' | 'small';
      text?: 'signin_with' | 'signup_with' | 'continue_with' | 'signin';
      shape?: 'rectangular' | 'pill' | 'circle' | 'square';
      logo_alignment?: 'left' | 'center';
      width?: number;
      locale?: string;
    },
  ): void;
  disableAutoSelect?(): void;
}

/** What Google's code flow answers: the one-time code, or an OAuth error (e.g. `access_denied`). */
export interface GoogleCodeResponse {
  code?: string;
  error?: string;
}

/** The part of Google Identity Services' OAuth 2.0 library ReadIn uses (`google.accounts.oauth2`): the popup code flow. */
export interface GoogleOAuth2 {
  initCodeClient(config: {
    client_id: string;
    scope: string;
    ux_mode: 'popup';
    callback: (response: GoogleCodeResponse) => void;
    /** The popup failed to open or the person closed it (`popup_failed_to_open`, `popup_closed`, `unknown`). */
    error_callback?: (error: { type: string }) => void;
  }): { requestCode(): void };
}

/** The parts of Sign in with Apple JS ReadIn uses (`AppleID.auth`). */
export interface AppleIdAuth {
  init(config: { clientId: string; scope: string; redirectURI: string; usePopup: boolean; nonce?: string; state?: string }): void;
  signIn(): Promise<{
    authorization: { id_token: string; code?: string; state?: string };
    user?: { email?: string; name?: { firstName?: string; lastName?: string } };
  }>;
}

type ExternalWindow = Window & {
  google?: { accounts?: { id?: GoogleAccountsId; oauth2?: GoogleOAuth2 } };
  AppleID?: { auth?: AppleIdAuth };
};

/** Brand names, the same in every UI language. */
export const PROVIDER_NAMES: Record<ExternalProvider, string> = { google: 'Google', apple: 'Apple' };

/** What a provider returned: the credential for the API, plus Apple's one-time name. */
export interface ExternalResult extends ExternalCredential {
  displayName?: string;
}

/** Only what the API needs to confirm an identity (Apple's one-time name isn't part of it); Apple keeps its code. */
export function credentialOf(result: ExternalResult): ExternalCredential {
  return {
    provider: result.provider,
    ...(result.idToken ? { idToken: result.idToken } : {}),
    ...(result.nonce ? { nonce: result.nonce } : {}),
    ...(result.authorizationCode ? { authorizationCode: result.authorizationCode } : {}),
  };
}

/** A random raw nonce and its SHA-256 (hex), which Apple puts in the token (ADR 0012). */
export async function createNonce(): Promise<{ raw: string; hashed: string }> {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  const raw = btoa(String.fromCharCode(...bytes)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(raw));
  const hashed = [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
  return { raw, hashed };
}

/** "Mona Adel" from Apple's `user.name`, sent only on the first authorization. */
export function appleDisplayName(name: { firstName?: string; lastName?: string } | undefined): string | undefined {
  const full = [name?.firstName, name?.lastName].map((part) => part?.trim()).filter(Boolean).join(' ');
  return full || undefined;
}

/**
 * Google and Apple sign in on the web (SPEC §9.1, ADR 0012). The provider SDKs are loaded lazily in the browser only
 * (never during SSR). They give an ID token (or, from our own Google button, Google's one-time code) that goes straight
 * to the API; nothing is stored here. A provider is offered only when the API lists it in `GET /auth/config` and this
 * build has a client id for it.
 */
@Injectable({ providedIn: 'root' })
export class ExternalIdentityService {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly document = inject(DOCUMENT);
  private readonly config = inject(AuthConfigService);
  private readonly clientIds = inject(EXTERNAL_CLIENT_IDS);

  private google: Promise<GoogleAccountsId> | null = null;
  private apple: Promise<AppleIdAuth> | null = null;
  /** GIS has one global callback; it goes to the most recently rendered button that is still on the page. */
  private googleTargets: { host: HTMLElement; onCredential: (result: ExternalResult) => void }[] = [];
  /** Google's code client, once its script is in. Kept so a click can open the popup without waiting (popup blockers). */
  private googleCodeClient: { requestCode(): void } | null = null;
  private googleCodeLoading: Promise<{ requestCode(): void }> | null = null;
  /** The code flow has one callback; it answers the request that opened the popup. */
  private googleCodePending: ((result: ExternalResult | null) => void) | null = null;

  /** Providers to show, in the order Google, Apple. */
  readonly providers = computed<ExternalProvider[]>(() => {
    const listed = new Set(this.config.config().externalProviders ?? []);
    return (['google', 'apple'] as const).filter((p) => listed.has(p) && !!this.clientIds[p]);
  });

  /** Our own "Continue with Google" button (Google's code flow) instead of Google's: the API can trade the code. */
  readonly googleCodeSignIn = computed(() => !!this.config.config().googleCodeSignIn);

  /** Loads `GET /auth/config` (the providers come with it). */
  load(): Promise<void> {
    return this.config.load();
  }

  /**
   * Loads Google's script and makes the code client ahead of the click, so {@link signInWithGoogle} opens the popup
   * inside the click itself (browsers block popups opened later). Safe to call again.
   */
  prepareGoogleCode(): Promise<void> {
    if (!this.isBrowser || !this.clientIds.google) return Promise.resolve();
    return this.loadGoogleCodeClient().then(() => undefined);
  }

  /**
   * Our own Google button (ADR 0012): opens Google's account picker in a popup and resolves with Google's one-time code,
   * which the API trades for the ID token. Resolves null when the person closes the popup or says no.
   */
  async signInWithGoogle(): Promise<ExternalResult | null> {
    if (!this.isBrowser || !this.clientIds.google) return null;
    // No await before requestCode() when the client is ready, so the popup opens within the click.
    const client = this.googleCodeClient ?? (await this.loadGoogleCodeClient());
    return new Promise<ExternalResult | null>((resolve) => {
      this.googleCodePending?.(null); // an earlier popup that never answered
      this.googleCodePending = resolve;
      client.requestCode();
    });
  }

  /**
   * Renders Google's official button into `host`, for when the API can't trade a code (no web client secret): Google
   * hands over the ID token only through its own button. The credential goes to `onCredential`; closing the popup does
   * nothing.
   */
  async renderGoogleButton(
    host: HTMLElement,
    options: { theme: 'light' | 'dark'; locale: string; width: number; text?: 'continue_with' | 'signin_with' },
    onCredential: (result: ExternalResult) => void,
  ): Promise<void> {
    if (!this.isBrowser || !this.clientIds.google) return;
    const id = await this.loadGoogle();
    this.googleTargets = [...this.googleTargets.filter((t) => t.host !== host && t.host.isConnected), { host, onCredential }];
    host.replaceChildren();
    id.renderButton(host, {
      type: 'standard',
      theme: options.theme === 'dark' ? 'filled_black' : 'outline',
      size: 'large',
      text: options.text ?? 'continue_with',
      shape: 'rectangular',
      logo_alignment: 'center',
      width: Math.round(Math.min(400, Math.max(200, options.width))),
      locale: options.locale,
    });
  }

  /**
   * Sign in with Apple in a popup, with a fresh nonce. Resolves null when the person closes it. The raw nonce goes to
   * the API, which checks that the token carries its SHA-256, and so does Apple's one-time authorization code, which
   * the API turns into a token it can revoke when the account is deleted.
   */
  async signInWithApple(): Promise<ExternalResult | null> {
    if (!this.isBrowser || !this.clientIds.apple) return null;
    const auth = await this.loadApple();
    const nonce = await createNonce();
    auth.init({
      clientId: this.clientIds.apple,
      scope: 'name email',
      redirectURI: this.document.location.origin,
      usePopup: true,
      nonce: nonce.hashed,
    });
    try {
      const response = await auth.signIn();
      const idToken = response?.authorization?.id_token;
      if (!idToken) return null;
      const code = response.authorization.code;
      return {
        provider: 'apple',
        idToken,
        nonce: nonce.raw,
        ...(code ? { authorizationCode: code } : {}),
        displayName: appleDisplayName(response.user?.name),
      };
    } catch {
      return null; // popup_closed_by_user / user_cancelled_authorize
    }
  }

  private loadGoogle(): Promise<GoogleAccountsId> {
    this.google ??= this.loadScript(GOOGLE_GSI_SRC, () => (this.window().google?.accounts?.id ?? null))
      .then((id) => {
        id.initialize({
          client_id: this.clientIds.google,
          callback: (response) => this.onGoogleCredential(response.credential),
          ux_mode: 'popup',
          auto_select: false,
          itp_support: true,
        });
        return id;
      })
      .catch((error: unknown) => {
        this.google = null; // blocked or offline: try again next time
        throw error;
      });
    return this.google;
  }

  private loadGoogleCodeClient(): Promise<{ requestCode(): void }> {
    this.googleCodeLoading ??= this.loadScript(GOOGLE_GSI_SRC, () => this.window().google?.accounts?.oauth2 ?? null)
      .then((oauth2) => {
        this.googleCodeClient = oauth2.initCodeClient({
          client_id: this.clientIds.google,
          scope: 'openid email profile',
          ux_mode: 'popup',
          callback: (response) => this.settleGoogleCode(response.code ? { provider: 'google', authorizationCode: response.code } : null),
          error_callback: () => this.settleGoogleCode(null),
        });
        return this.googleCodeClient;
      })
      .catch((error: unknown) => {
        this.googleCodeLoading = null; // blocked or offline: try again next time
        throw error;
      });
    return this.googleCodeLoading;
  }

  private settleGoogleCode(result: ExternalResult | null): void {
    const pending = this.googleCodePending;
    this.googleCodePending = null;
    pending?.(result);
  }

  private loadApple(): Promise<AppleIdAuth> {
    this.apple ??= this.loadScript(APPLE_JS_SRC, () => this.window().AppleID?.auth ?? null).catch((error: unknown) => {
      this.apple = null;
      throw error;
    });
    return this.apple;
  }

  private onGoogleCredential(credential: string | undefined): void {
    if (!credential) return;
    this.googleTargets = this.googleTargets.filter((t) => t.host.isConnected);
    this.googleTargets.at(-1)?.onCredential({ provider: 'google', idToken: credential });
  }

  /** Adds the script once; resolves with the SDK object as soon as it exists (also when a test put it there). */
  private loadScript<T>(src: string, sdk: () => T | null): Promise<T> {
    const ready = sdk();
    if (ready) return Promise.resolve(ready);
    return new Promise<T>((resolve, reject) => {
      const existing = this.document.querySelector<HTMLScriptElement>(`script[src="${src}"]`);
      const script = existing ?? this.document.createElement('script');
      const done = () => {
        const loaded = sdk();
        if (loaded) resolve(loaded);
        else reject(new Error(`${src} loaded without its SDK`));
      };
      script.addEventListener('load', done, { once: true });
      script.addEventListener('error', () => reject(new Error(`${src} failed to load`)), { once: true });
      if (!existing) {
        script.src = src;
        script.async = true;
        script.defer = true;
        this.document.head.appendChild(script);
      }
    });
  }

  private window(): ExternalWindow {
    return this.document.defaultView as ExternalWindow;
  }
}
