import { Injectable, signal } from '@angular/core';
import type { ProblemDetails } from '../api/models';

export type AuthBanner = 'passwordReset';

/** Why the session ended for a suspended account: the `user.suspended` problem's `suspendedUntil` (F22). */
export type SuspensionNotice = Pick<ProblemDetails, 'suspendedUntil'>;

/**
 * Hand-offs between auth screens that must not go in the URL: the phone number typed on Sign in pre-fills Forgot
 * password and the other way round, the "password changed" banner after a reset, and the suspension that ended the
 * session (Sign in says until when). Memory only.
 */
@Injectable({ providedIn: 'root' })
export class AuthFlowState {
  /** Last E.164 number typed on an auth screen. */
  readonly phone = signal<string | null>(null);
  readonly banner = signal<AuthBanner | null>(null);
  readonly suspension = signal<SuspensionNotice | null>(null);

  /** Reads and clears the banner, so it shows once. */
  takeBanner(): AuthBanner | null {
    const banner = this.banner();
    this.banner.set(null);
    return banner;
  }

  /** Reads and clears the suspension, so Sign in shows it once. */
  takeSuspension(): SuspensionNotice | null {
    const suspension = this.suspension();
    this.suspension.set(null);
    return suspension;
  }
}
