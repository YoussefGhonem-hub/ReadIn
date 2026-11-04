import { ChangeDetectionStrategy, Component, computed, effect, inject, signal, untracked } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { VerificationApi } from '../../core/api/verification.api';
import { SessionStore } from '../../core/auth/session.store';
import { VerificationView, verificationView } from '../verification/verification-status';

/**
 * Settings → "Writer verification" (F19): opens `/verification`, with where your request stands (verified, under
 * review, not approved, or "request it"). A verified account needs no call; otherwise `GET /me/verification` once, and
 * the status is left out when it can't be read.
 */
@Component({
  selector: 'rd-verification-row',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <a routerLink="/verification" class="flex min-h-14 items-center gap-3 text-sm text-text-primary no-underline" data-settings-verification [attr.data-status]="state()">
      <svg lucideIcon="BadgeCheck" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
      <span class="min-w-0 flex-1">
        <span class="block">{{ 'settings.verification.label' | transloco }}</span>
        <span class="block text-xs text-text-secondary">{{ 'settings.verification.hint' | transloco }}</span>
      </span>
      @if (state(); as s) {
        <span class="shrink-0 text-xs font-semibold" [class]="tone()" data-verification-state>{{ 'settings.verification.status.' + s | transloco }}</span>
      }
      <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
    </a>
  `,
})
export class VerificationRow {
  private readonly session = inject(SessionStore);
  private readonly api = inject(VerificationApi);

  private readonly loaded = signal<VerificationView | null>(null);
  private readonly verified = computed(() => !!this.session.me()?.isVerified);
  protected readonly state = computed<Exclude<VerificationView, 'unavailable'> | null>(() => {
    if (this.verified()) return 'verified';
    const view = this.loaded();
    return view === 'unavailable' ? null : view;
  });
  protected readonly tone = computed(() => {
    switch (this.state()) {
      case 'verified':
        return 'text-primary';
      case 'rejected':
        return 'text-error';
      case 'pending':
        return 'text-text-primary';
      default:
        return 'text-link';
    }
  });

  constructor() {
    let asked = false;
    effect(() => {
      const ask = this.session.isAuthenticated() && !this.verified() && !asked;
      if (!ask) return;
      asked = true;
      untracked(() => void this.load());
    });
  }

  private async load(): Promise<void> {
    try {
      this.loaded.set(verificationView(await firstValueFrom(this.api.status())));
    } catch {
      this.loaded.set(null); // no status shown; the page says what went wrong
    }
  }
}
