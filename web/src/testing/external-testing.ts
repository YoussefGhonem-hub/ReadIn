import { AppleIdAuth, GoogleAccountsId, GoogleCodeResponse, GoogleOAuth2 } from '../app/core/auth/external-identity.service';

type TestWindow = Window & { google?: { accounts: { id: GoogleAccountsId; oauth2: GoogleOAuth2 } }; AppleID?: { auth: AppleIdAuth } };

/**
 * Stand-ins for Google Identity Services and Sign in with Apple JS, installed on `window` so the real
 * ExternalIdentityService finds them instead of loading the scripts.
 */
export class FakeGoogle implements GoogleAccountsId {
  callback: ((response: { credential?: string }) => void) | null = null;
  readonly initialize = vi.fn((config: Parameters<GoogleAccountsId['initialize']>[0]) => {
    this.callback = config.callback;
  });
  readonly renderButton = vi.fn((parent: HTMLElement) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = 'Continue with Google';
    button.setAttribute('data-fake-gis', '');
    parent.appendChild(button);
  });

  /** What GIS does after the person picks an account in the popup. */
  pick(credential = 'google-id-token'): void {
    this.callback?.({ credential });
  }
}

/** Google's code flow (`google.accounts.oauth2`): records the client it was given and how often the popup opened. */
export class FakeGoogleOAuth2 implements GoogleOAuth2 {
  config: Parameters<GoogleOAuth2['initCodeClient']>[0] | null = null;
  readonly requestCode = vi.fn();
  readonly initCodeClient = vi.fn((config: Parameters<GoogleOAuth2['initCodeClient']>[0]) => {
    this.config = config;
    return { requestCode: this.requestCode };
  });

  /** What GIS does after the person picks an account (or says no) in the popup. */
  answer(response: GoogleCodeResponse = { code: 'google-auth-code' }): void {
    this.config?.callback(response);
  }

  /** The person closed the popup. */
  close(): void {
    this.config?.error_callback?.({ type: 'popup_closed' });
  }
}

export class FakeApple implements AppleIdAuth {
  config: Parameters<AppleIdAuth['init']>[0] | null = null;
  next: Awaited<ReturnType<AppleIdAuth['signIn']>> | 'cancel' = {
    authorization: { id_token: 'apple-id-token', code: 'apple-auth-code' },
    user: { name: { firstName: 'Mona', lastName: 'Adel' } },
  };
  readonly init = vi.fn((config: Parameters<AppleIdAuth['init']>[0]) => {
    this.config = config;
  });
  readonly signIn = vi.fn(async () => {
    if (this.next === 'cancel') throw { error: 'popup_closed_by_user' };
    return this.next;
  });
}

export function installProviderSdks(): { google: FakeGoogle; googleCode: FakeGoogleOAuth2; apple: FakeApple; uninstall: () => void } {
  const google = new FakeGoogle();
  const googleCode = new FakeGoogleOAuth2();
  const apple = new FakeApple();
  const target = window as TestWindow;
  target.google = { accounts: { id: google, oauth2: googleCode } };
  target.AppleID = { auth: apple };
  return {
    google,
    googleCode,
    apple,
    uninstall: () => {
      delete target.google;
      delete target.AppleID;
    },
  };
}
