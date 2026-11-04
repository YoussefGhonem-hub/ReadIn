import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { isApiError } from '../../core/api/api.config';
import { ExternalSignInRequest } from '../../core/api/models';
import { postAuthUrl } from '../../core/auth/account-setup';
import { AuthService } from '../../core/auth/auth.service';
import { ExternalIdentityService, ExternalResult, credentialOf } from '../../core/auth/external-identity.service';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ExternalButtons } from '../../shared/ui/external/external-buttons';
import { PasswordField } from '../../shared/ui/password/password-field';
import { PhoneField } from '../../shared/ui/phone/phone-field';
import { SubmitButton } from './auth-shared';

type Stage = 'choose' | 'link';

/**
 * Continue with Google / Apple on Welcome and Sign in (SPEC §9.2, ADR 0012). A linked identity (or a verified email
 * that matches an account) signs in and the usual guards apply. Otherwise the "not linked" sheet offers "create a new
 * account" or "I already have an account" (phone + password links it). The provider's ID token is kept in memory only
 * for that second request.
 */
@Component({
  selector: 'rd-external-sign-in',
  imports: [ReactiveFormsModule, TranslocoPipe, BottomSheet, ExternalButtons, PhoneField, PasswordField, SubmitButton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  // No providers: not even a flex item, so Welcome's spacing stays the same.
  host: { class: 'block', '[class.hidden]': '!available() && !pending()' },
  template: `
    @if (available()) {
      @if (divider()) {
        <div class="my-5 flex items-center gap-3 text-xs text-text-secondary" aria-hidden="true">
          <span class="h-px flex-1 bg-border"></span>{{ 'common.or' | transloco }}<span class="h-px flex-1 bg-border"></span>
        </div>
      }
      <rd-external-buttons [busy]="busy()" (credential)="start($event)" />
      @if (error()) {
        <p class="rd-alert rd-alert-error mt-3" role="alert" data-external-error>{{ error() }}</p>
      }
    }

    <rd-bottom-sheet [open]="!!pending()" labelledBy="not-linked-title" describedBy="not-linked-body" [dismissible]="!busy()" (closed)="cancel()">
      <div class="flex flex-col gap-4 pt-1" data-not-linked>
        <h2 id="not-linked-title" class="m-0 pe-10 text-xl font-semibold">{{ 'auth.external.notLinked.title' | transloco }}</h2>
        <p id="not-linked-body" class="m-0 text-sm text-text-secondary">
          {{ 'auth.external.notLinked.body' | transloco: { provider: providerName() } }}
        </p>
        @if (stage() === 'choose') {
          <div class="flex flex-col gap-2">
            <button type="button" class="rd-btn rd-btn-primary w-full" [disabled]="busy()" [attr.aria-busy]="busy()" (click)="create()" data-create>
              {{ 'auth.external.notLinked.create' | transloco }}
            </button>
            <button type="button" class="rd-btn rd-btn-outline w-full" [disabled]="busy()" (click)="stage.set('link')" data-have-account>
              {{ 'auth.external.notLinked.haveAccount' | transloco }}
            </button>
          </div>
        } @else {
          <form [formGroup]="linkForm" (ngSubmit)="link()" class="flex flex-col gap-4" novalidate data-link-form>
            <p class="m-0 text-sm">{{ 'auth.external.notLinked.linkHint' | transloco: { provider: providerName() } }}</p>
            <div>
              <label class="rd-label" for="link-phone">{{ 'auth.phone' | transloco }}</label>
              <rd-phone-field inputId="link-phone" autocomplete="username" formControlName="phone" [invalid]="linkSubmitted() && linkForm.controls.phone.invalid" />
            </div>
            <div>
              <label class="rd-label" for="link-password">{{ 'auth.password' | transloco }}</label>
              <rd-password-field inputId="link-password" autocomplete="current-password" formControlName="password" [invalid]="linkSubmitted() && linkForm.controls.password.invalid" />
            </div>
            <div class="flex gap-2">
              <button type="button" class="rd-btn rd-btn-ghost" [disabled]="busy()" (click)="stage.set('choose')">{{ 'common.back' | transloco }}</button>
              <rd-submit-button class="flex-1" [busy]="busy()">{{ 'auth.external.notLinked.linkSubmit' | transloco }}</rd-submit-button>
            </div>
          </form>
        }
        @if (sheetError()) {
          <p class="rd-alert rd-alert-error" role="alert" data-sheet-error>{{ sheetError() }}</p>
        }
      </div>
    </rd-bottom-sheet>
  `,
})
export class ExternalSignIn {
  readonly returnUrl = input<string | null>(null);
  /** The "or" line above the buttons (Sign in). */
  readonly divider = input(false);

  private readonly auth = inject(AuthService);
  private readonly external = inject(ExternalIdentityService);
  private readonly router = inject(Router);
  private readonly errors = inject(ErrorMessages);

  protected readonly available = computed(() => this.external.providers().length > 0);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly sheetError = signal<string | null>(null);
  protected readonly stage = signal<Stage>('choose');
  protected readonly linkSubmitted = signal(false);
  /** The credential waiting for "create" or "link". Memory only, dropped when the sheet closes. */
  protected readonly pending = signal<ExternalResult | null>(null);
  protected readonly providerName = computed(() => (this.pending()?.provider === 'apple' ? 'Apple' : 'Google'));

  protected readonly linkForm = inject(FormBuilder).nonNullable.group({
    phone: ['', Validators.required],
    password: ['', Validators.required],
  });

  constructor() {
    void this.external.load(); // GET /auth/config lists the providers
  }

  protected async start(result: ExternalResult): Promise<void> {
    if (this.busy()) return;
    this.error.set(null);
    this.busy.set(true);
    try {
      await this.finish(this.request(result));
    } catch (error) {
      if (isApiError(error) && error.code === 'auth.external_not_linked') {
        this.stage.set('choose');
        this.sheetError.set(null);
        this.linkForm.reset();
        this.linkSubmitted.set(false);
        this.pending.set(result);
      } else {
        this.error.set(this.message(error));
      }
    } finally {
      this.busy.set(false);
    }
  }

  protected create(): Promise<void> {
    return this.retry({ createAccount: true });
  }

  protected link(): Promise<void> {
    this.linkSubmitted.set(true);
    if (this.linkForm.invalid) return Promise.resolve();
    const { phone, password } = this.linkForm.getRawValue();
    return this.retry({ link: { phoneNumber: phone, password } });
  }

  protected cancel(): void {
    if (this.busy()) return;
    this.pending.set(null);
    this.linkForm.reset();
  }

  private async retry(extra: Pick<ExternalSignInRequest, 'createAccount' | 'link'>): Promise<void> {
    const result = this.pending();
    if (!result || this.busy()) return;
    this.busy.set(true);
    this.sheetError.set(null);
    try {
      await this.finish({ ...this.request(result), ...extra });
      this.pending.set(null);
    } catch (error) {
      if (isApiError(error) && error.code === 'auth.external_invalid') {
        // The token expired while the sheet was open: start again with the provider.
        this.pending.set(null);
        this.error.set(this.message(error));
      } else {
        this.sheetError.set(this.message(error));
      }
    } finally {
      this.busy.set(false);
    }
  }

  private request(result: ExternalResult): ExternalSignInRequest {
    return { ...credentialOf(result), ...(result.displayName ? { displayName: result.displayName } : {}) };
  }

  private async finish(request: ExternalSignInRequest): Promise<void> {
    const me = await this.auth.signInExternal(request);
    await this.router.navigateByUrl(postAuthUrl(me, this.returnUrl()));
  }

  private message(error: unknown): string {
    return this.errors.forError(error);
  }
}
