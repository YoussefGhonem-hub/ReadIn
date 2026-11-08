import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { LegalApi } from '../../core/api/legal.api';
import { LegalDto } from '../../core/api/models';
import { postAuthUrl } from '../../core/auth/account-setup';
import { AuthService } from '../../core/auth/auth.service';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { LocalizedDatePipe } from '../../shared/pipes/format.pipes';
import { AuthCard } from './auth-shared';

/**
 * New terms (F37), `/auth/terms`: a blocking step after the password and the PIN when a newer version of the Terms of Use
 * and Community Guidelines took effect (`MeDto.mustAcceptTerms`). What changed (`GET /legal`, or a general line), links
 * to both texts, «موافق» (`POST /me/terms/accept`, then the next step), or sign out or delete the account instead.
 */
@Component({
  selector: 'rd-accept-terms-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, LocalizedDatePipe, AuthCard],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-auth-card [title]="'legal.accept.title' | transloco" [subtitle]="'legal.accept.subtitle' | transloco">
      <div class="flex flex-col gap-4" data-accept-terms-page>
        <div class="rd-alert rd-alert-info m-0" data-terms-summary>
          @if (summary(); as text) {
            <p class="m-0 whitespace-pre-line" dir="auto">{{ text }}</p>
          } @else {
            <p class="m-0">{{ 'legal.accept.generic' | transloco }}</p>
          }
          @if (legal()?.effectiveAt; as at) {
            <p class="m-0 mt-1 text-xs text-text-secondary">{{ 'legal.accept.effective' | transloco: { date: (at | rdDate: lang() : 'long') } }}</p>
          }
        </div>
        <ul class="m-0 flex list-none flex-col gap-1 p-0 text-sm">
          <li>
            <a href="/terms" target="_blank" rel="noopener" class="inline-flex min-h-11 items-center gap-1.5 font-semibold text-link" data-terms-link>
              {{ 'legal.terms.title' | transloco }}
              <svg lucideIcon="ExternalLink" [size]="14" aria-hidden="true"></svg>
            </a>
          </li>
          <li>
            <a href="/community-guidelines" target="_blank" rel="noopener" class="inline-flex min-h-11 items-center gap-1.5 font-semibold text-link" data-guidelines-link>
              {{ 'legal.guidelines.title' | transloco }}
              <svg lucideIcon="ExternalLink" [size]="14" aria-hidden="true"></svg>
            </a>
          </li>
        </ul>
        <p class="m-0 text-sm">{{ 'legal.accept.zeroTolerance' | transloco }}</p>
        @if (error()) {
          <p class="rd-alert rd-alert-error m-0" role="alert" data-accept-error>{{ error() }}</p>
        }
        <button type="button" class="rd-btn rd-btn-primary w-full" [disabled]="busy()" [attr.aria-busy]="busy()" (click)="accept()" data-accept>
          @if (busy()) {
            <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
          }
          {{ 'legal.accept.agree' | transloco }}
        </button>
        <div class="flex flex-wrap justify-center gap-x-4 gap-y-1 text-sm">
          <button type="button" class="min-h-11 text-text-secondary hover:text-text-primary hover:underline" [disabled]="busy()" (click)="signOut()" data-terms-sign-out>
            {{ 'auth.signOut' | transloco }}
          </button>
          <a routerLink="/settings/delete-account" class="inline-flex min-h-11 items-center text-error no-underline hover:underline" data-terms-delete>{{ 'legal.accept.delete' | transloco }}</a>
        </div>
      </div>
    </rd-auth-card>
  `,
})
export class AcceptTermsPage {
  private readonly api = inject(LegalApi);
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly errors = inject(ErrorMessages);
  protected readonly lang = inject(LanguageService).lang;

  readonly returnUrl = input<string | null>(null);

  protected readonly legal = signal<LegalDto | null>(null);
  protected readonly summary = computed(() => {
    const summary = this.legal()?.summary;
    return (this.lang() === 'ar' ? summary?.ar : summary?.en)?.trim() || null;
  });
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);

  constructor() {
    void firstValueFrom(this.api.legal()).then(
      (legal) => this.legal.set(legal),
      () => undefined,
    );
  }

  protected async accept(): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      const me = await firstValueFrom(this.api.accept());
      this.auth.updateMe(me);
      await this.router.navigateByUrl(postAuthUrl(me, this.returnUrl()));
    } catch (error) {
      this.error.set(this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }

  protected async signOut(): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    try {
      await this.auth.signOut();
      await this.router.navigateByUrl('/');
    } finally {
      this.busy.set(false);
    }
  }
}
