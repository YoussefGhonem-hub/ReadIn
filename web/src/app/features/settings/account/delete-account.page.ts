import { ChangeDetectionStrategy, Component, ElementRef, Injector, afterNextRender, computed, inject, signal, viewChild } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { Title } from '@angular/platform-browser';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { environment } from '../../../../environments/environment';
import { isApiError } from '../../../core/api/api.config';
import { AccountConfirmation, ExternalProvider } from '../../../core/api/models';
import { AuthFlowState } from '../../../core/auth/auth-flow';
import { AuthService } from '../../../core/auth/auth.service';
import { ExternalIdentityService, ExternalResult, PROVIDER_NAMES, credentialOf } from '../../../core/auth/external-identity.service';
import { SessionStore } from '../../../core/auth/session.store';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { BottomSheet } from '../../../shared/ui/bottom-sheet';
import { ExternalButtons } from '../../../shared/ui/external/external-buttons';
import { PasswordField } from '../../../shared/ui/password/password-field';
import { forgetCountry } from '../../../shared/ui/phone/countries';

export const DELETE_ACCOUNT_PATH = '/settings/delete-account';

const DELETED = ['profile', 'contact', 'signIn', 'articles', 'activity', 'devices', 'security'] as const;
const KEPT = ['published', 'record', 'backups', 'reviews'] as const;

/** Codes that mean the Google/Apple sign in can't confirm this account: pick (another) one again. */
const CREDENTIAL_REFUSED = new Set(['auth.external_invalid', 'auth.external_mismatch']);

type Stage = 'about' | 'confirm';

/**
 * Delete account (SPEC F01): immediate and for good, no grace period. Store rules require it in the app, so it is a
 * page of its own, two taps from Settings:
 *
 * 1. What happens: what is deleted at once, what is kept (and why, and for how long), and that it can't be undone.
 * 2. Confirm it's you: the password, or a fresh sign in with a linked Google/Apple account (Apple is offered too when
 *    it's linked and the web has it). A stale session never deletes anything.
 * 3. "I understand, delete my account" enables the red button, which asks once more ("Delete forever", Cancel first).
 * 4. `DELETE /me`: the form is disabled and the button shows progress. Every failure stays on the page with its message
 *    (and Retry where that can help: offline, Apple unreachable, server errors); nothing is ever queued for later.
 *    `auth.apple_confirmation_required` runs Apple sign in when the web has it, or points to the iPhone app and email.
 * 5. `204`: AuthService forgets the session and the push token, the remembered phone country goes too, and Sign in
 *    opens with "Your account was deleted."
 */
@Component({
  selector: 'rd-delete-account-page',
  imports: [ReactiveFormsModule, RouterLink, TranslocoPipe, LucideDynamicIcon, BottomSheet, ExternalButtons, PasswordField],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[640px] px-4 pt-6' },
  template: `
    <a routerLink="/settings" class="mb-4 inline-flex min-h-11 items-center gap-1 text-sm font-semibold text-text-secondary no-underline hover:text-text-primary" data-back-to-settings>
      <svg lucideIcon="ArrowLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>{{ 'nav.settings' | transloco }}
    </a>

    @if (stage() === 'about') {
      <section class="rd-card p-5 shadow-none sm:p-6" aria-labelledby="delete-about-title" data-delete-about>
        <span class="grid h-12 w-12 place-items-center rounded-card bg-callout-danger text-error" aria-hidden="true">
          <svg lucideIcon="Trash2" [size]="22"></svg>
        </span>
        <h1 #heading id="delete-about-title" tabindex="-1" class="m-0 mt-4 text-2xl font-bold outline-none">{{ 'account.delete.title' | transloco }}</h1>
        <p class="m-0 mt-2" data-lead>{{ 'account.delete.lead' | transloco }}</p>

        <h2 class="m-0 mt-6 text-base font-semibold">{{ 'account.delete.deletedTitle' | transloco }}</h2>
        <ul class="m-0 mt-2 flex list-none flex-col gap-2 p-0 text-sm" data-deleted>
          @for (key of deleted; track key) {
            <li class="flex items-start gap-2">
              <svg lucideIcon="CircleX" [size]="16" class="mt-0.5 shrink-0 text-error" aria-hidden="true"></svg>
              <span>{{ 'account.delete.deleted.' + key | transloco }}</span>
            </li>
          }
        </ul>

        <h2 class="m-0 mt-6 text-base font-semibold">{{ 'account.delete.keptTitle' | transloco }}</h2>
        <ul class="m-0 mt-2 flex list-none flex-col gap-2 p-0 text-sm" data-kept>
          @for (key of kept; track key) {
            <li class="flex items-start gap-2">
              <svg lucideIcon="Info" [size]="16" class="mt-0.5 shrink-0 text-text-secondary" aria-hidden="true"></svg>
              <span>{{ 'account.delete.kept.' + key | transloco }}</span>
            </li>
          }
        </ul>

        <p class="m-0 mt-6 rounded-md bg-surface-variant p-3 text-sm" data-after>{{ 'account.delete.after' | transloco }}</p>

        <div class="mt-6 flex flex-col gap-2 sm:flex-row-reverse">
          <button type="button" class="rd-btn rd-btn-primary flex-1" (click)="toConfirm()" data-continue>{{ 'common.continue' | transloco }}</button>
          <a routerLink="/settings" class="rd-btn rd-btn-outline flex-1 no-underline">{{ 'common.cancel' | transloco }}</a>
        </div>
      </section>
    } @else {
      <section class="rd-card p-5 shadow-none sm:p-6" aria-labelledby="delete-confirm-title" data-delete-confirm>
        <h1 #heading id="delete-confirm-title" tabindex="-1" class="m-0 text-2xl font-bold outline-none">{{ 'account.delete.confirmTitle' | transloco }}</h1>

        <form [formGroup]="form" (ngSubmit)="review()" class="mt-4 flex flex-col gap-4" novalidate data-delete-form>
          <fieldset [disabled]="busy()" class="m-0 flex min-w-0 flex-col gap-4 border-0 p-0">
            @if (held(); as credential) {
              <div class="rd-alert rd-alert-success flex flex-wrap items-center gap-2" data-confirmed>
                <svg lucideIcon="CircleCheck" [size]="18" class="shrink-0 text-success" aria-hidden="true"></svg>
                <span class="flex-1">{{ 'account.delete.confirmedWith' | transloco: { provider: providerName(credential.provider) } }}</span>
                <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-sm" (click)="confirmAgain()" data-confirm-again>
                  {{ 'account.delete.confirmAgain' | transloco }}
                </button>
              </div>
            } @else {
              @if (hasPassword()) {
                <div>
                  <label class="rd-label" for="delete-account-password">{{ 'auth.password' | transloco }}</label>
                  <rd-password-field
                    inputId="delete-account-password"
                    autocomplete="current-password"
                    formControlName="password"
                    [invalid]="!!passwordError()"
                    [describedBy]="passwordError() ? 'delete-account-password-error' : null"
                  />
                  @if (passwordError()) {
                    <p id="delete-account-password-error" class="rd-field-error">{{ passwordError()! | transloco }}</p>
                  }
                </div>
              }
              @if (providers().length) {
                @if (hasPassword()) {
                  <p class="m-0 text-center text-xs text-text-secondary">{{ 'common.or' | transloco }}</p>
                } @else {
                  <p class="m-0 text-sm text-text-secondary">{{ 'account.delete.confirmProvider' | transloco }}</p>
                }
                <rd-external-buttons
                  [only]="providers()"
                  [busy]="busy()"
                  text="signin_with"
                  [appleLabel]="'account.delete.confirmApple' | transloco"
                  (credential)="picked($event)"
                  data-delete-external
                />
              } @else if (!hasPassword() && providersLoaded() && !appleNeeded()) {
                <!-- Nothing this browser can confirm with (e.g. Apple only, and the web has no Apple sign in yet). -->
                <div class="rd-alert rd-alert-info" data-no-confirm-here>
                  <p class="m-0">{{ (appleLinked() ? 'account.delete.appleUnavailable' : 'errors.auth.provider_disabled') | transloco }}</p>
                  <a [href]="mailto" class="mt-1 inline-block font-semibold text-link">{{ 'account.delete.emailUs' | transloco }}: <span class="font-latin" dir="ltr">{{ email }}</span></a>
                </div>
              }
              @if (confirmMissing()) {
                <p class="rd-field-error m-0" data-confirm-first>{{ 'account.delete.confirmFirst' | transloco }}</p>
              }
            }

            <label class="flex items-start gap-2 text-sm">
              <input type="checkbox" formControlName="understood" class="mt-0.5 h-5 w-5 shrink-0 accent-error" data-understood />
              <span class="font-semibold">{{ 'account.delete.understand' | transloco }}</span>
            </label>
          </fieldset>

          @if (appleNeeded() && !appleHere()) {
            <div class="rd-alert rd-alert-error" role="alert" data-apple-unavailable>
              <p class="m-0">{{ 'account.delete.appleUnavailable' | transloco }}</p>
              <a [href]="mailto" class="mt-1 inline-block font-semibold text-link">{{ 'account.delete.emailUs' | transloco }}: <span class="font-latin" dir="ltr">{{ email }}</span></a>
            </div>
          } @else if (error()) {
            <div class="rd-alert rd-alert-error flex flex-wrap items-center gap-2" role="alert" data-delete-error>
              <span class="min-w-0 flex-1">{{ error() }}</span>
              @if (canRetry()) {
                <button #retryButton type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" [disabled]="busy()" (click)="retry()" data-retry>
                  <svg lucideIcon="RotateCw" [size]="16" aria-hidden="true"></svg>{{ 'common.retry' | transloco }}
                </button>
              }
            </div>
          }

          <button
            #submitButton
            type="submit"
            class="rd-btn w-full bg-error text-on-error"
            [disabled]="busy() || !value().understood"
            [attr.aria-busy]="busy()"
            data-delete-submit
          >
            @if (busy()) {
              <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              {{ 'account.delete.deleting' | transloco }}
            } @else {
              <svg lucideIcon="Trash2" [size]="18" aria-hidden="true"></svg>
              {{ 'account.delete.submit' | transloco }}
            }
          </button>
          <button type="button" class="rd-btn rd-btn-outline w-full" [disabled]="busy()" (click)="toAbout()" data-back>{{ 'common.back' | transloco }}</button>
        </form>
      </section>
    }

    <p class="m-0 mt-4 text-center text-sm">
      <a [href]="deletionPageUrl" target="_blank" rel="noopener" class="text-text-secondary underline underline-offset-2" data-delete-by-email>
        {{ 'account.delete.byEmail' | transloco }}
      </a>
    </p>

    <!-- Screen readers hear the progress; errors are announced by their role="alert". -->
    <p class="rd-visually-hidden" role="status" data-delete-status>{{ busy() ? ('account.delete.deleting' | transloco) : '' }}</p>

    <rd-bottom-sheet [open]="dialogOpen()" role="alertdialog" labelledBy="delete-forever-title" describedBy="delete-forever-body" (closed)="dialogOpen.set(false)">
      <div class="flex flex-col gap-4 pt-1" data-delete-dialog>
        <span class="grid h-12 w-12 place-items-center rounded-card bg-callout-danger text-error" aria-hidden="true">
          <svg lucideIcon="TriangleAlert" [size]="22"></svg>
        </span>
        <h2 id="delete-forever-title" class="m-0 pe-10 text-xl font-semibold">{{ 'account.delete.dialogTitle' | transloco }}</h2>
        <p id="delete-forever-body" class="m-0 text-sm text-text-secondary">{{ 'account.delete.dialogBody' | transloco }}</p>
        <div class="flex flex-col gap-2 sm:flex-row-reverse">
          <button type="button" class="rd-btn flex-1 bg-error text-on-error" (click)="deleteForever()" data-delete-forever>
            {{ 'account.delete.dialogConfirm' | transloco }}
          </button>
          <button type="button" class="rd-btn rd-btn-outline flex-1" (click)="dialogOpen.set(false)" data-initial-focus data-delete-cancel>
            {{ 'common.cancel' | transloco }}
          </button>
        </div>
      </div>
    </rd-bottom-sheet>
  `,
})
export class DeleteAccountPage {
  private readonly auth = inject(AuthService);
  private readonly session = inject(SessionStore);
  private readonly external = inject(ExternalIdentityService);
  private readonly flow = inject(AuthFlowState);
  private readonly router = inject(Router);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly injector = inject(Injector);
  private readonly heading = viewChild<ElementRef<HTMLElement>>('heading');
  private readonly submitButton = viewChild<ElementRef<HTMLButtonElement>>('submitButton');
  private readonly retryButton = viewChild<ElementRef<HTMLButtonElement>>('retryButton');
  private readonly passwordField = viewChild(PasswordField);

  protected readonly deleted = DELETED;
  protected readonly kept = KEPT;
  protected readonly email = environment.supportEmail;
  protected readonly mailto = `mailto:${environment.supportEmail}?subject=${encodeURIComponent('ReadIn: delete my account')}`;
  protected readonly deletionPageUrl = environment.accountDeletionUrl;

  protected readonly form = inject(FormBuilder).nonNullable.group({ password: [''], understood: [false] });
  protected readonly value = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });

  protected readonly stage = signal<Stage>('about');
  /** A fresh Google/Apple sign in that confirms it's you (instead of the password). Memory only. */
  protected readonly held = signal<ExternalResult | null>(null);
  protected readonly submitted = signal(false);
  protected readonly dialogOpen = signal(false);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly canRetry = signal(false);
  protected readonly wrongPassword = signal(false);
  /** The API asked for an Apple confirmation (it has no Apple token to revoke otherwise). */
  protected readonly appleNeeded = signal(false);
  protected readonly providersLoaded = signal(false);

  protected readonly hasPassword = computed(() => this.session.me()?.hasPassword ?? true);
  private readonly linked = computed<ExternalProvider[]>(() => (this.session.me()?.externalLogins ?? []).map((l) => l.provider));
  protected readonly appleLinked = computed(() => this.linked().includes('apple'));
  protected readonly appleHere = computed(() => this.external.providers().includes('apple'));
  /**
   * Sign ins offered to confirm: the linked providers this browser has (accounts without a password), and Apple when
   * it's linked (also next to the password, so its token can be revoked).
   */
  protected readonly providers = computed(() => {
    const offered = this.hasPassword() ? this.linked().filter((p) => p === 'apple') : this.linked();
    return offered.filter((p) => this.external.providers().includes(p));
  });

  protected readonly passwordError = computed(() => {
    if (this.wrongPassword()) return 'errors.auth.wrong_password';
    return this.submitted() && this.hasPassword() && !this.held() && !this.value().password ? 'auth.validation.required' : null;
  });
  protected readonly confirmMissing = computed(() => this.submitted() && !this.hasPassword() && !this.held());

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('account.delete.title')} — ReadIn`);
    void this.external.load().finally(() => this.providersLoaded.set(true));
    this.form.controls.password.valueChanges.subscribe(() => this.wrongPassword.set(false));
  }

  protected providerName(provider: ExternalProvider): string {
    return PROVIDER_NAMES[provider];
  }

  protected toConfirm(): void {
    this.stage.set('confirm');
    this.focusLater(() => this.heading()?.nativeElement);
  }

  protected toAbout(): void {
    if (this.busy()) return;
    this.stage.set('about');
    this.focusLater(() => this.heading()?.nativeElement);
  }

  /** A fresh provider sign in. After the API asked for Apple, Apple's answer goes straight on with the deletion. */
  protected picked(result: ExternalResult): void {
    this.held.set(result);
    this.error.set(null);
    this.canRetry.set(false);
    if (this.appleNeeded() && result.provider === 'apple' && this.form.controls.understood.value) void this.send();
  }

  protected confirmAgain(): void {
    this.held.set(null);
    this.focusLater(() => (this.hasPassword() ? this.passwordField() : this.heading()?.nativeElement));
  }

  /** The red button: once it's confirmed and understood, ask one last time. */
  protected review(): void {
    if (this.busy() || !this.form.controls.understood.value) return;
    this.submitted.set(true);
    if (this.passwordError()) {
      this.passwordField()?.focus();
      return;
    }
    if (!this.confirmation()) return;
    this.dialogOpen.set(true);
  }

  protected deleteForever(): void {
    this.dialogOpen.set(false);
    void this.send();
  }

  /** After a failure that may pass on its own (offline, Apple unreachable, a server error): the same request again. */
  protected retry(): void {
    if (this.busy() || !this.form.controls.understood.value) return;
    this.submitted.set(true);
    if (this.passwordError() || this.confirmMissing()) return;
    void this.send();
  }

  /** Exactly one confirmation, made now: the held provider sign in, or the password typed on this page. */
  private confirmation(): AccountConfirmation | null {
    const held = this.held();
    if (held) return { external: credentialOf(held) };
    const password = this.form.controls.password.value;
    return this.hasPassword() && password ? { password } : null;
  }

  private async send(): Promise<void> {
    const confirmation = this.confirmation();
    if (!confirmation || this.busy()) return;
    this.error.set(null);
    this.canRetry.set(false);
    this.wrongPassword.set(false);
    this.appleNeeded.set(false);
    if (typeof navigator !== 'undefined' && navigator.onLine === false) {
      // Never queued: the person tries again once they're back online.
      this.fail(this.offlineMessage(), true);
      return;
    }

    this.busy.set(true);
    try {
      await this.auth.deleteAccount(confirmation);
    } catch (error) {
      this.busy.set(false);
      await this.handle(error);
      return;
    }
    forgetCountry();
    this.flow.banner.set('accountDeleted');
    await this.router.navigateByUrl('/auth/sign-in');
  }

  private async handle(error: unknown): Promise<void> {
    if (!isApiError(error)) return this.fail(this.errors.forError(error), true);
    const { code, status } = error;
    if (code === 'auth.wrong_password') {
      this.wrongPassword.set(true);
      this.focusLater(() => this.passwordField());
    } else if (code === 'auth.apple_confirmation_required') {
      await this.confirmWithApple(error.problem?.title ?? null);
    } else if (CREDENTIAL_REFUSED.has(code)) {
      this.held.set(null); // sign in again, with the account that is linked
      this.fail(this.errors.forCode(code, error.problem?.title), false);
    } else if (status === 401) {
      // The session already ended (the interceptor could not renew it): sign in again, then come back here.
      this.auth.endLocalSession();
      await this.router.navigate(['/auth/sign-in'], { queryParams: { returnUrl: DELETE_ACCOUNT_PATH } });
    } else if (status === 0) {
      this.fail(this.offlineMessage(), true);
    } else {
      // 503 account.deletion_unavailable (nothing was deleted) and other server errors can pass; 429 and 400s can't.
      this.fail(this.errors.forCode(code, error.problem?.title), status >= 500);
    }
  }

  /**
   * The API has no Apple token to revoke, so Apple has to confirm. With Apple sign in on this browser it runs at once
   * (and the deletion goes on); if the popup is closed the "Confirm with Apple" button stays. Without it, the page
   * points to the iPhone app and the email route.
   */
  private async confirmWithApple(title: string | null): Promise<void> {
    this.held.set(null);
    this.appleNeeded.set(true);
    if (!this.appleHere()) return;
    this.fail(this.errors.forCode('auth.apple_confirmation_required', title), false);
    const apple = await this.external.signInWithApple().catch(() => null);
    if (apple && this.appleNeeded() && !this.held()) this.picked(apple);
  }

  private fail(message: string, retry: boolean): void {
    this.error.set(message);
    this.canRetry.set(retry);
    this.focusLater(() => this.retryButton()?.nativeElement ?? this.submitButton()?.nativeElement);
  }

  private offlineMessage(): string {
    return this.transloco.translate('account.delete.offline');
  }

  /** Moves focus once the view shows the new state (a disabled or removed control would lose it). */
  private focusLater(target: () => { focus(): void } | null | undefined): void {
    afterNextRender({ write: () => target()?.focus() }, { injector: this.injector });
  }
}
