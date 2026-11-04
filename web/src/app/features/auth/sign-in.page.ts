import { ChangeDetectionStrategy, Component, computed, inject, input, signal, viewChild } from '@angular/core';
import { NgComponentOutlet } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { postAuthUrl, safeReturnUrl } from '../../core/auth/account-setup';
import { AuthFlowState } from '../../core/auth/auth-flow';
import { AuthService } from '../../core/auth/auth.service';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { PasswordField } from '../../shared/ui/password/password-field';
import { rememberCountry } from '../../shared/ui/phone/countries';
import { PhoneField } from '../../shared/ui/phone/phone-field';
import { AuthCard, SubmitButton, fieldErrors } from './auth-shared';
import { DEV_LOGIN_PANEL } from './dev/dev-login';
import { ExternalSignIn } from './external-sign-in';

/**
 * Sign in (SPEC §9.2): phone + password. One generic error for a wrong number or password (it never says whether
 * the number exists); lockout, suspended (until when, or permanently) and rate-limit messages; after a reset, the number
 * is pre-filled with a banner. A session that ended because the account was suspended (F22) lands here with that
 * message. Then the account-setup guards apply (change password → PIN → profile → onboarding).
 */
@Component({
  selector: 'rd-sign-in-page',
  imports: [ReactiveFormsModule, RouterLink, TranslocoPipe, LucideDynamicIcon, NgComponentOutlet, AuthCard, SubmitButton, PhoneField, PasswordField, ExternalSignIn],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-auth-card [title]="'auth.signIn.title' | transloco" [subtitle]="'auth.signIn.subtitle' | transloco">
      @if (banner()) {
        <p class="rd-alert rd-alert-success mb-5 flex items-start gap-2" role="status" data-banner>
          <svg lucideIcon="CircleCheck" [size]="18" class="mt-0.5 shrink-0 text-success" aria-hidden="true"></svg>
          <span>{{ 'auth.signIn.passwordReset' | transloco }}</span>
        </p>
      }
      <form [formGroup]="form" (ngSubmit)="submit()" class="flex flex-col gap-4" novalidate>
        <div>
          <label class="rd-label" for="sign-in-phone">{{ 'auth.phone' | transloco }}</label>
          <rd-phone-field
            inputId="sign-in-phone"
            autocomplete="username"
            formControlName="phone"
            [invalid]="!!phoneError()"
            [describedBy]="phoneError() ? 'sign-in-phone-error' : null"
          />
          @if (phoneError()) {
            <p id="sign-in-phone-error" class="rd-field-error">{{ phoneError()! | transloco }}</p>
          }
        </div>
        <div>
          <div class="flex items-center justify-between gap-2">
            <label class="rd-label" for="sign-in-password">{{ 'auth.password' | transloco }}</label>
            <a routerLink="/auth/forgot-password" class="mb-2 text-xs font-semibold text-primary" (click)="handOverPhone()" data-forgot>
              {{ 'auth.signIn.forgot' | transloco }}
            </a>
          </div>
          <rd-password-field
            inputId="sign-in-password"
            autocomplete="current-password"
            formControlName="password"
            [invalid]="passwordMissing()"
            [describedBy]="passwordMissing() ? 'sign-in-password-error' : null"
          />
          @if (passwordMissing()) {
            <p id="sign-in-password-error" class="rd-field-error">{{ 'auth.validation.required' | transloco }}</p>
          }
        </div>
        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert" data-error>{{ error() }}</p>
        }
        <rd-submit-button [busy]="busy()">{{ 'auth.signIn.action' | transloco }}</rd-submit-button>
      </form>
      <p class="mt-6 text-center text-sm text-text-secondary">
        {{ 'auth.signIn.noAccount' | transloco }}
        <a routerLink="/auth/sign-up" [queryParams]="returnParams()" class="font-semibold text-primary">{{ 'auth.signIn.createAccount' | transloco }}</a>
      </p>
      <rd-external-sign-in [returnUrl]="returnUrl()" [divider]="true" />
      <p class="mt-2 text-center text-sm">
        <a [routerLink]="guestUrl()" class="text-text-secondary">{{ 'auth.continueAsGuest' | transloco }}</a>
      </p>
      @if (devPanel) {
        <ng-container *ngComponentOutlet="devPanel; inputs: devInputs" />
      }
    </rd-auth-card>
  `,
})
export class SignInPage {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly flow = inject(AuthFlowState);
  private readonly errors = inject(ErrorMessages);
  private readonly phoneField = viewChild.required(PhoneField);
  private readonly passwordField = viewChild.required(PasswordField);

  readonly returnUrl = input<string | null>(null);

  protected readonly form = inject(FormBuilder).nonNullable.group({
    phone: [this.flow.phone() ?? '', Validators.required],
    password: ['', Validators.required],
  });
  protected readonly banner = signal(this.flow.takeBanner() === 'passwordReset');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(this.suspensionMessage());
  private readonly submitted = signal(false);
  private readonly serverPhoneError = signal<string | null>(null);
  /** Re-evaluates the template checks below on every change. */
  private readonly formState = signal(0);

  protected readonly guestUrl = computed(() => safeReturnUrl(this.returnUrl()));
  protected readonly returnParams = computed(() => (this.returnUrl() ? { returnUrl: this.returnUrl() } : {}));

  /** Development builds only (see dev/dev-login.ts). */
  protected readonly devPanel = DEV_LOGIN_PANEL;
  protected readonly devInputs = { pick: (phone: string, password: string | null) => this.useSeedUser(phone, password) };

  constructor() {
    this.form.valueChanges.subscribe(() => {
      this.serverPhoneError.set(null);
      this.formState.update((n) => n + 1);
    });
  }

  protected phoneError(): string | null {
    this.formState();
    const control = this.form.controls.phone;
    if (this.serverPhoneError()) return this.serverPhoneError();
    if (!this.submitted() && !control.touched) return null;
    if (control.hasError('required')) return 'auth.validation.phoneRequired';
    if (control.hasError('phoneInvalid')) return 'errors.phone.invalid';
    return null;
  }

  protected passwordMissing(): boolean {
    this.formState();
    return this.submitted() && this.form.controls.password.hasError('required');
  }

  /** "Forgot password?" takes the number along (SPEC §9.2: Forgot password is pre-filled from Sign in). */
  protected handOverPhone(): void {
    const phone = this.form.controls.phone.value;
    if (phone) this.flow.phone.set(phone);
  }

  protected async submit(): Promise<void> {
    if (this.busy()) return;
    this.submitted.set(true);
    this.formState.update((n) => n + 1);
    this.error.set(null);
    if (this.form.invalid) {
      if (this.form.controls.phone.invalid) this.phoneField().focus();
      else this.passwordField().focus();
      return;
    }

    const { phone, password } = this.form.getRawValue();
    this.busy.set(true);
    try {
      const me = await this.auth.signIn(phone, password);
      rememberCountry(this.phoneField().selectedCountry);
      this.flow.phone.set(null);
      await this.router.navigateByUrl(postAuthUrl(me, this.returnUrl()));
    } catch (error) {
      const phoneCodes = fieldErrors(error, 'phoneNumber');
      if (phoneCodes.length) this.serverPhoneError.set(`errors.${phoneCodes[0]}`);
      else this.error.set(this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }

  /** The suspension that ended your session, if that is how you got here. */
  private suspensionMessage(): string | null {
    const suspension = this.flow.takeSuspension();
    return suspension ? this.errors.suspended(suspension) : null;
  }

  private useSeedUser(phone: string, password: string | null): void {
    this.form.controls.phone.setValue(phone);
    if (password) {
      this.form.controls.password.setValue(password);
      void this.submit();
    } else {
      this.passwordField().focus();
    }
  }
}
