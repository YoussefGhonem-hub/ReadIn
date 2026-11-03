import { ChangeDetectionStrategy, Component, computed, inject, input, signal, viewChild } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { AuthApi } from '../../core/api/auth.api';
import { AuthConfigService } from '../../core/auth/auth-config.service';
import { AuthFlowState } from '../../core/auth/auth-flow';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { PasswordField } from '../../shared/ui/password/password-field';
import { passwordViolations } from '../../shared/ui/password/password-rules';
import { PhoneField } from '../../shared/ui/phone/phone-field';
import { PinInput } from '../../shared/ui/pin/pin-input';
import { normalizePin } from '../../shared/ui/pin/pin-rules';
import { AuthCard, SubmitButton, fieldErrors } from './auth-shared';
import { ContactSupportSheet } from './contact-support-sheet';

type Step = 'verify' | 'reset';

/**
 * Forgot password (SPEC §9.2, ADR 0009): (1) phone + recovery PIN → a 10-minute reset token; (2) new password +
 * confirm → Sign in with the number pre-filled and a banner. "Forgot the PIN too?" opens the contact-support sheet.
 */
@Component({
  selector: 'rd-forgot-password-page',
  imports: [ReactiveFormsModule, RouterLink, TranslocoPipe, LucideDynamicIcon, AuthCard, SubmitButton, PhoneField, PasswordField, PinInput, ContactSupportSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-auth-card
      [title]="(step() === 'verify' ? 'auth.forgot.title' : 'auth.forgot.newTitle') | transloco"
      [subtitle]="(step() === 'verify' ? 'auth.forgot.subtitle' : 'auth.forgot.newSubtitle') | transloco"
    >
      @if (step() === 'verify') {
        <form [formGroup]="verifyForm" (ngSubmit)="verify()" class="flex flex-col gap-4" novalidate data-step-verify>
          @if (expired()) {
            <p class="rd-alert rd-alert-error" role="alert" data-expired>{{ 'errors.auth.reset_token_invalid' | transloco }}</p>
          }
          <div>
            <label class="rd-label" for="forgot-phone">{{ 'auth.phone' | transloco }}</label>
            <rd-phone-field
              inputId="forgot-phone"
              autocomplete="username"
              formControlName="phone"
              [invalid]="!!phoneError()"
              [describedBy]="phoneError() ? 'forgot-phone-error' : null"
            />
            @if (phoneError()) {
              <p id="forgot-phone-error" class="rd-field-error">{{ phoneError()! | transloco }}</p>
            }
          </div>
          <div>
            <label id="forgot-pin-label" class="rd-label" for="forgot-pin-0">{{ 'auth.pin' | transloco }}</label>
            <rd-pin-input
              idPrefix="forgot-pin"
              labelledBy="forgot-pin-label"
              formControlName="pin"
              [length]="pinLength()"
              [invalid]="pinIncomplete()"
              [describedBy]="pinIncomplete() ? 'forgot-pin-error' : null"
            />
            @if (pinIncomplete()) {
              <p id="forgot-pin-error" class="rd-field-error">{{ 'errors.pin.length' | transloco: { length: pinLength() } }}</p>
            }
            <button type="button" class="mt-3 border-0 bg-transparent p-0 text-sm font-semibold text-primary underline-offset-2 hover:underline" (click)="supportOpen.set(true)" data-forgot-pin>
              {{ 'auth.forgot.forgotPin' | transloco }}
            </button>
          </div>
          @if (error()) {
            <div class="rd-alert rd-alert-error" role="alert" data-error>
              {{ error() }}
              @if (recoveryDisabled()) {
                <button type="button" class="rd-btn rd-btn-outline mt-2 min-h-9 w-full text-sm" (click)="supportOpen.set(true)">{{ 'auth.support.contact' | transloco }}</button>
              }
            </div>
          }
          <rd-submit-button [busy]="busy()">{{ 'common.continue' | transloco }}</rd-submit-button>
        </form>
      } @else {
        <form [formGroup]="resetForm" (ngSubmit)="save()" class="flex flex-col gap-4" novalidate data-step-reset>
          <div>
            <label class="rd-label" for="forgot-new-password">{{ 'auth.newPassword' | transloco }}</label>
            <rd-password-field
              inputId="forgot-new-password"
              autocomplete="new-password"
              formControlName="password"
              [showStrength]="true"
              [policy]="policy()"
              [phone]="verifiedPhone()"
              [invalid]="passwordErrors().length > 0"
              [describedBy]="passwordErrors().length ? 'forgot-new-password-error' : null"
            />
            @if (passwordErrors().length) {
              <ul id="forgot-new-password-error" class="m-0 list-none p-0">
                @for (code of passwordErrors(); track code) {
                  <li class="rd-field-error">{{ 'errors.' + code | transloco: { min: policy().minLength, max: policy().maxLength } }}</li>
                }
              </ul>
            }
          </div>
          <div>
            <label class="rd-label" for="forgot-confirm">{{ 'auth.confirmPassword' | transloco }}</label>
            <rd-password-field
              inputId="forgot-confirm"
              autocomplete="new-password"
              formControlName="confirm"
              [invalid]="!!confirmError()"
              [describedBy]="confirmError() ? 'forgot-confirm-error' : null"
            />
            @if (confirmError()) {
              <p id="forgot-confirm-error" class="rd-field-error">{{ confirmError()! | transloco }}</p>
            }
          </div>
          @if (error()) {
            <p class="rd-alert rd-alert-error" role="alert" data-error>{{ error() }}</p>
          }
          <rd-submit-button [busy]="busy()">{{ 'auth.forgot.save' | transloco }}</rd-submit-button>
        </form>
      }
      <p class="mt-6 text-center text-sm">
        <a routerLink="/auth/sign-in" class="font-semibold text-primary" (click)="handOverPhone()">
          <svg lucideIcon="ArrowRight" [size]="14" class="ltr:rotate-180 me-1 inline align-[-2px]" aria-hidden="true"></svg>{{ 'auth.forgot.backToSignIn' | transloco }}
        </a>
      </p>
    </rd-auth-card>
    <rd-contact-support-sheet [open]="supportOpen()" (closed)="supportOpen.set(false)" />
  `,
})
export class ForgotPasswordPage {
  private readonly api = inject(AuthApi);
  private readonly router = inject(Router);
  private readonly flow = inject(AuthFlowState);
  private readonly errors = inject(ErrorMessages);
  private readonly config = inject(AuthConfigService);
  private readonly fb = inject(FormBuilder).nonNullable;
  private readonly phoneField = viewChild(PhoneField);
  private readonly pinInput = viewChild(PinInput);
  private readonly newPasswordField = viewChild(PasswordField);

  /** Kept for the way back to Sign in. */
  readonly returnUrl = input<string | null>(null);

  protected readonly verifyForm = this.fb.group({ phone: [this.flow.phone() ?? '', Validators.required], pin: [''] });
  protected readonly resetForm = this.fb.group({ password: [''], confirm: [''] });

  protected readonly step = signal<Step>('verify');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly expired = signal(false);
  protected readonly recoveryDisabled = signal(false);
  protected readonly supportOpen = signal(false);
  protected readonly verifiedPhone = signal<string | null>(null);
  private readonly verifySubmitted = signal(false);
  private readonly resetSubmitted = signal(false);
  private readonly serverPasswordErrors = signal<string[]>([]);
  private resetToken: string | null = null;

  private readonly verifyValue = toSignal(this.verifyForm.valueChanges, { initialValue: this.verifyForm.getRawValue() });
  private readonly resetValue = toSignal(this.resetForm.valueChanges, { initialValue: this.resetForm.getRawValue() });

  protected readonly policy = computed(() => this.config.config().password);
  protected readonly pinLength = computed(() => this.config.config().pinLength);

  protected readonly phoneError = computed(() => {
    const { phone } = this.verifyValue();
    if (!this.verifySubmitted()) return null;
    if (!phone) return 'auth.validation.phoneRequired';
    return this.verifyForm.controls.phone.hasError('phoneInvalid') ? 'errors.phone.invalid' : null;
  });
  protected readonly pinIncomplete = computed(
    () => this.verifySubmitted() && normalizePin(this.verifyValue().pin).length !== this.pinLength(),
  );
  protected readonly passwordErrors = computed(() => {
    const { password } = this.resetValue();
    if (this.serverPasswordErrors().length) return this.serverPasswordErrors();
    const codes = passwordViolations(password ?? '', this.policy(), this.verifiedPhone());
    if (this.resetSubmitted()) return codes;
    return password ? codes.filter((c) => c === 'password.too_common' || c === 'password.contains_phone' || c === 'password.too_long') : [];
  });
  protected readonly confirmError = computed(() => {
    const { password, confirm } = this.resetValue();
    if (!confirm) return this.resetSubmitted() ? 'auth.validation.confirmPassword' : null;
    return confirm !== password ? 'auth.validation.passwordMismatch' : null;
  });

  constructor() {
    void this.config.load();
    this.verifyForm.valueChanges.subscribe(() => {
      this.error.set(null);
      this.recoveryDisabled.set(false);
    });
    this.resetForm.controls.password.valueChanges.subscribe(() => this.serverPasswordErrors.set([]));
  }

  protected handOverPhone(): void {
    const phone = this.verifiedPhone() ?? this.verifyForm.controls.phone.value;
    if (phone) this.flow.phone.set(phone);
  }

  protected async verify(): Promise<void> {
    if (this.busy()) return;
    this.verifySubmitted.set(true);
    this.expired.set(false);
    if (this.phoneError()) return this.phoneField()?.focus();
    if (this.pinIncomplete()) return this.pinInput()?.focus();

    const { phone, pin } = this.verifyForm.getRawValue();
    this.busy.set(true);
    this.error.set(null);
    try {
      const { resetToken } = await firstValueFrom(this.api.verifyPin({ phoneNumber: phone, pin: normalizePin(pin) }));
      this.resetToken = resetToken;
      this.verifiedPhone.set(phone);
      this.step.set('reset');
      queueMicrotask(() => this.newPasswordField()?.focus());
    } catch (error) {
      this.recoveryDisabled.set(isApiError(error) && error.code === 'auth.recovery_disabled');
      this.error.set(isApiError(error) ? this.errors.forCode(error.code) : this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }

  protected async save(): Promise<void> {
    if (this.busy()) return;
    this.resetSubmitted.set(true);
    if (this.passwordErrors().length || this.confirmError()) return this.newPasswordField()?.focus();

    this.busy.set(true);
    this.error.set(null);
    try {
      await firstValueFrom(this.api.resetPassword({ resetToken: this.resetToken ?? '', newPassword: this.resetForm.getRawValue().password }));
      this.flow.phone.set(this.verifiedPhone());
      this.flow.banner.set('passwordReset');
      await this.router.navigate(['/auth/sign-in'], { queryParams: this.returnUrl() ? { returnUrl: this.returnUrl() } : {} });
    } catch (error) {
      if (isApiError(error) && error.code === 'auth.reset_token_invalid') return this.startOver();
      const codes = fieldErrors(error, 'newPassword');
      if (codes.length) this.serverPasswordErrors.set(codes);
      else this.error.set(isApiError(error) ? this.errors.forCode(error.code) : this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }

  /** The reset token expired (10 minutes) or was used: back to step 1, number kept, PIN cleared. */
  private startOver(): void {
    this.resetToken = null;
    this.verifyForm.controls.pin.setValue('');
    this.resetForm.reset();
    this.resetSubmitted.set(false);
    this.verifySubmitted.set(false);
    this.step.set('verify');
    this.expired.set(true);
    queueMicrotask(() => this.pinInput()?.focus());
  }
}
