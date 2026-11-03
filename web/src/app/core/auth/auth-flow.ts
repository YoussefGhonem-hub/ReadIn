import { Injectable, signal } from '@angular/core';

export type AuthBanner = 'passwordReset' | 'accountDeleted';

/**
 * Hand-offs between auth screens that must not go in the URL: the phone number typed on Sign in pre-fills Forgot
 * password and the other way round, and the banner Sign in shows once after a password reset or an account deletion.
 * Memory only.
 */
@Injectable({ providedIn: 'root' })
export class AuthFlowState {
  /** Last E.164 number typed on an auth screen. */
  readonly phone = signal<string | null>(null);
  readonly banner = signal<AuthBanner | null>(null);

  /** Reads and clears the banner, so it shows once. */
  takeBanner(): AuthBanner | null {
    const banner = this.banner();
    this.banner.set(null);
    return banner;
  }
}
