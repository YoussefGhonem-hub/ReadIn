import { Injectable, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { MyVerificationRequestDto, VerificationStatusDto, VerificationSubmission } from '../../core/api/models';
import { VerificationApi } from '../../core/api/verification.api';
import { AuthService } from '../../core/auth/auth.service';
import { SessionStore } from '../../core/auth/session.store';
import { VerificationView, verificationView } from './verification-status';

/**
 * Your writer verification (F19), for the `/verification` page that provides it: `GET /me/verification`, sending a
 * request, and withdrawing it (at once on screen, put back when the API refuses). Once you are verified and the
 * session doesn't know it yet, `me` is read again so the badge shows everywhere.
 */
@Injectable()
export class VerificationStore {
  private readonly api = inject(VerificationApi);
  private readonly auth = inject(AuthService);
  private readonly session = inject(SessionStore);

  readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  readonly data = signal<VerificationStatusDto | null>(null);
  readonly withdrawing = signal(false);
  readonly request = computed(() => this.data()?.request ?? null);
  readonly view = computed<VerificationView | null>(() => {
    const data = this.data();
    return data ? verificationView(data) : null;
  });
  private generation = 0;

  async load(options: { quiet?: boolean } = {}): Promise<void> {
    const generation = ++this.generation;
    if (!options.quiet) this.status.set('loading');
    try {
      const data = await firstValueFrom(this.api.status());
      if (generation !== this.generation) return;
      this.data.set(data);
      this.status.set('loaded');
      if (data.isVerified && this.session.me()?.isVerified === false) void this.auth.refreshMe();
    } catch {
      if (generation === this.generation && !options.quiet) this.status.set('error');
    }
  }

  /** Sends the request; on `201` the page shows it as under review. Errors are the caller's to show. */
  async submit(request: VerificationSubmission): Promise<MyVerificationRequestDto> {
    const created = await firstValueFrom(this.api.submit(request));
    this.generation++;
    this.data.set({ isVerified: false, canRequest: false, request: created });
    this.status.set('loaded');
    return created;
  }

  /**
   * Withdraws the pending request: the form shows at once; a refusal puts the request back and is rethrown. When it
   * was already gone (`404 verification.not_found`, e.g. decided meanwhile), the status is read again instead.
   */
  async withdraw(): Promise<void> {
    const before = this.data();
    if (!before || this.withdrawing()) return;
    this.withdrawing.set(true);
    this.generation++;
    this.data.set({ ...before, canRequest: true, request: null });
    try {
      await firstValueFrom(this.api.withdraw());
    } catch (error) {
      if (isApiError(error) && error.code === 'verification.not_found') {
        void this.load({ quiet: true });
        return;
      }
      this.data.set(before);
      throw error;
    } finally {
      this.withdrawing.set(false);
    }
  }
}
