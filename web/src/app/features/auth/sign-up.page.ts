import { ChangeDetectionStrategy, Component, computed, inject, input, signal, viewChild } from '@angular/core';
import { TermsCheckbox } from '../../shared/legal/terms-checkbox';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, TouchedChangeEvent, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { filter, map } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { postAuthUrl } from '../../core/auth/account-setup';
import { AuthConfigService } from '../../core/auth/auth-config.service';
import { AuthFlowState } from '../../core/auth/auth-flow';
import { AuthService } from '../../core/auth/auth.service';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { PasswordField } from '../../shared/ui/password/password-field';
import { passwordViolations } from '../../shared/ui/password/password-rules';
import { rememberCountry } from '../../shared/ui/phone/countries';
import { ConfirmPhoneDialog } from '../../shared/ui/phone/confirm-phone-dialog';
import { PhoneField } from '../../shared/ui/phone/phone-field';
import { PinInput } from '../../shared/ui/pin/pin-input';
import { normalizePin, pinViolations } from '../../shared/ui/pin/pin-rules';
import { AuthCard, AuthSteps, SubmitButton, fieldErrors } from './auth-shared';

type Step = 1 | 2;

/**
 * Create account (SPEC §9.2), a 3-step stepper: (1) phone + password with strength meter, live rules and confirm;
 * (2) the recovery PIN + confirm; (3) "confirm your number" dialog, after which the account is created and the user
 * goes on to Complete profile.
 */
@Component({
  selector: 'rd-sign-up-page',
  imports: [
    ReactiveFormsModule,
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    AuthCard,
    AuthSteps,
    SubmitButton,
    PhoneField,
    PasswordField,
    PinInput,
    ConfirmPhoneDialog, TermsCheckbox],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-auth-card [title]="(step() === 1 ? 'auth.signUp.title' : 'auth.signUp.pinTitle') | transloco" [subtitle]="(step() === 1 ? 'auth.signUp.subtitle' : 'auth.signUp.pinSubtitle') | transloco">
      <rd-auth-steps rdAuthCardTop [current]="step()" />

      @if (step() === 1) {
        <form [formGroup]="account" (ngSubmit)="next()" class="flex flex-col gap-4" novalidate data-step-1>
          <div>
            <label class="rd-label" for="sign-up-phone">{{ 'auth.phone' | transloco }}</label>
            <rd-phone-field
              inputId="sign-up-phone"
              formControlName="phone"
              [invalid]="!!phoneError()"
              [describedBy]="phoneError() ? 'sign-up-phone-error' : 'sign-up-phone-hint'"
            />
            @if (phoneError()) {
              <p id="sign-up-phone-error" class="rd-field-error">{{ phoneError()! | transloco }}</p>
            } @else {
              <p id="sign-up-phone-hint" class="rd-field-hint">{{ 'auth.signUp.phoneHint' | transloco }}</p>
            }
          </div>
          @if (phoneTaken()) {
            <div class="rd-alert rd-alert-error flex flex-wrap items-center justify-between gap-2" role="alert" data-phone-taken>
              <span>{{ 'errors.auth.phone_taken' | transloco }}</span>
              <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" (click)="goToSignIn()">{{ 'auth.signIn.action' | transloco }}</button>
            </div>
          }
          <div>
            <label class="rd-label" for="sign-up-password">{{ 'auth.password' | transloco }}</label>
            <rd-password-field
              inputId="sign-up-password"
              autocomplete="new-password"
              formControlName="password"
              [showStrength]="true"
              [policy]="policy()"
              [phone]="phone()"
              [invalid]="passwordErrors().length > 0"
              [describedBy]="passwordErrors().length ? 'sign-up-password-error' : null"
            />
            @if (passwordErrors().length) {
              <ul id="sign-up-password-error" class="m-0 list-none p-0">
                @for (code of passwordErrors(); track code) {
                  <li class="rd-field-error">{{ 'errors.' + code | transloco: { min: policy().minLength, max: policy().maxLength } }}</li>
                }
              </ul>
            }
          </div>
          <div>
            <label class="rd-label" for="sign-up-confirm">{{ 'auth.confirmPassword' | transloco }}</label>
            <rd-password-field
              inputId="sign-up-confirm"
              autocomplete="new-password"
              formControlName="confirm"
              [invalid]="!!confirmError()"
              [describedBy]="confirmError() ? 'sign-up-confirm-error' : null"
            />
            @if (confirmError()) {
              <p id="sign-up-confirm-error" class="rd-field-error">{{ confirmError()! | transloco }}</p>
            }
          </div>
          <rd-submit-button>{{ 'common.continue' | transloco }}</rd-submit-button>
        </form>
      } @else {
        <form [formGroup]="recovery" (ngSubmit)="review()" class="flex flex-col gap-5" novalidate data-step-2>
          <p class="rd-alert rd-alert-info m-0 flex items-start gap-2">
            <svg lucideIcon="KeyRound" [size]="18" class="mt-0.5 shrink-0 text-primary" aria-hidden="true"></svg>
            <span>{{ 'auth.signUp.pinExplain' | transloco }}</span>
          </p>
          <div>
            <label id="sign-up-pin-label" class="rd-label" for="sign-up-pin-0">{{ 'auth.pin' | transloco }}</label>
            <rd-pin-input
              idPrefix="sign-up-pin"
              labelledBy="sign-up-pin-label"
              formControlName="pin"
              [length]="pinLength()"
              [invalid]="!!pinError()"
              [describedBy]="pinError() ? 'sign-up-pin-error' : 'sign-up-pin-hint'"
            />
            @if (pinError()) {
              <p id="sign-up-pin-error" class="rd-field-error">{{ pinError()! | transloco: { length: pinLength() } }}</p>
            } @else {
              <p id="sign-up-pin-hint" class="rd-field-hint">{{ 'auth.pinHint' | transloco: { length: pinLength() } }}</p>
            }
          </div>
          <div>
            <label id="sign-up-pin-confirm-label" class="rd-label" for="sign-up-pin-confirm-0">{{ 'auth.confirmPin' | transloco }}</label>
            <rd-pin-input
              idPrefix="sign-up-pin-confirm"
              labelledBy="sign-up-pin-confirm-label"
              formControlName="confirmPin"
              [length]="pinLength()"
              [invalid]="!!confirmPinError()"
              [describedBy]="confirmPinError() ? 'sign-up-pin-confirm-error' : null"
            />
            @if (confirmPinError()) {
              <p id="sign-up-pin-confirm-error" class="rd-field-error">{{ confirmPinError()! | transloco }}</p>
            }
          </div>
          <!-- F37: required before the account is created; Continue stays off until it is ticked -->
          <rd-terms-checkbox [(checked)]="acceptTerms" />
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-ghost" (click)="back()">{{ 'common.back' | transloco }}</button>
            <rd-submit-button class="flex-1" [disabled]="!acceptTerms()">{{ 'common.continue' | transloco }}</rd-submit-button>
          </div>
        </form>
      }

      <p class="mt-6 text-center text-sm text-text-secondary">
        {{ 'auth.signUp.haveAccount' | transloco }}
        <a routerLink="/auth/sign-in" [queryParams]="returnParams()" class="font-semibold text-primary">{{ 'auth.signIn.action' | transloco }}</a>
      </p>
    </rd-auth-card>

    <rd-confirm-phone-dialog
      [open]="confirming()"
      [phone]="phone()"
      [stepLabel]="'auth.signUp.step' | transloco: { current: 3, total: 3 }"
      [confirmLabel]="'auth.confirmPhone.create' | transloco"
      [busy]="busy()"
      [error]="dialogError()"
      (confirm)="create()"
      (edit)="edit()"
    />
  `,
})
export class SignUpPage {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly flow = inject(AuthFlowState);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly config = inject(AuthConfigService);
  private readonly fb = inject(FormBuilder).nonNullable;
  private readonly phoneField = viewChild(PhoneField);
  private readonly pinInputs = viewChild(PinInput);

  readonly returnUrl = input<string | null>(null);

  protected readonly account = this.fb.group({
    phone: ['', Validators.required],
    password: [''],
    confirm: [''],
  });
  protected readonly recovery = this.fb.group({ pin: [''], confirmPin: [''] });

  protected readonly step = signal<Step>(1);
  /** F37: the terms checkbox (SPEC §9.2). */
  protected readonly acceptTerms = signal(false);
  protected readonly confirming = signal(false);
  protected readonly busy = signal(false);
  protected readonly dialogError = signal<string | null>(null);
  protected readonly phoneTaken = signal(false);
  private readonly accountSubmitted = signal(false);
  private readonly recoverySubmitted = signal(false);
  /** Codes the API returned for a field, shown until that field changes. */
  private readonly server = signal<{ phone: string[]; password: string[]; pin: string[] }>({ phone: [], password: [], pin: [] });

  private readonly phoneTouched = toSignal(
    this.account.controls.phone.events.pipe(
      filter((event): event is TouchedChangeEvent => event instanceof TouchedChangeEvent),
      map((event) => event.touched),
    ),
    { initialValue: false },
  );
  private readonly accountValue = toSignal(this.account.valueChanges, { initialValue: this.account.getRawValue() });
  private readonly recoveryValue = toSignal(this.recovery.valueChanges, { initialValue: this.recovery.getRawValue() });

  protected readonly policy = computed(() => this.config.config().password);
  protected readonly pinLength = computed(() => this.config.config().pinLength);
  protected readonly phone = computed(() => this.accountValue().phone || null);
  protected readonly returnParams = computed(() => (this.returnUrl() ? { returnUrl: this.returnUrl() } : {}));

  protected readonly phoneError = computed(() => {
    const value = this.accountValue();
    if (this.server().phone.length) return `errors.${this.server().phone[0]}`;
    if (!this.accountSubmitted() && !this.phoneTouched()) return null;
    if (!value.phone) return this.accountSubmitted() ? 'auth.validation.phoneRequired' : null;
    return this.account.controls.phone.hasError('phoneInvalid') ? 'errors.phone.invalid' : null;
  });

  protected readonly passwordErrors = computed(() => {
    const { password, phone } = this.accountValue();
    if (this.server().password.length) return this.server().password;
    // Live once something is typed; "too short" waits for a submit so the checklist does the talking first.
    const codes = passwordViolations(password ?? '', this.policy(), phone || null);
    if (this.accountSubmitted()) return codes;
    return password ? codes.filter((c) => c === 'password.too_common' || c === 'password.contains_phone' || c === 'password.too_long') : [];
  });

  protected readonly confirmError = computed(() => {
    const { password, confirm } = this.accountValue();
    if (!confirm) return this.accountSubmitted() ? 'auth.validation.confirmPassword' : null;
    return confirm !== password ? 'auth.validation.passwordMismatch' : null;
  });

  protected readonly pinError = computed(() => {
    const { pin } = this.recoveryValue();
    if (this.server().pin.length) return `errors.${this.server().pin[0]}`;
    const normalized = normalizePin(pin);
    const complete = normalized.length === this.pinLength();
    if (!complete && !this.recoverySubmitted()) return null;
    const [code] = pinViolations(normalized, this.pinLength());
    return code ? `errors.${code}` : null;
  });

  protected readonly confirmPinError = computed(() => {
    const { pin, confirmPin } = this.recoveryValue();
    const confirm = normalizePin(confirmPin);
    if (!confirm) return this.recoverySubmitted() ? 'auth.validation.confirmPin' : null;
    if (confirm.length < this.pinLength() && !this.recoverySubmitted()) return null;
    return confirm !== normalizePin(pin) ? 'auth.validation.pinMismatch' : null;
  });

  constructor() {
    void this.config.load();
    if (this.flow.phone()) this.account.controls.phone.setValue(this.flow.phone()!);
    this.account.controls.phone.valueChanges.subscribe(() => {
      this.phoneTaken.set(false);
      this.server.update((s) => ({ ...s, phone: [] }));
    });
    this.account.controls.password.valueChanges.subscribe(() => this.server.update((s) => ({ ...s, password: [] })));
    this.recovery.controls.pin.valueChanges.subscribe(() => this.server.update((s) => ({ ...s, pin: [] })));
  }

  /** Step 1 → 2. */
  protected next(): void {
    this.accountSubmitted.set(true);
    if (this.phoneError() || this.passwordErrors().length || this.confirmError() || this.phoneTaken()) {
      if (this.phoneError() || this.phoneTaken()) this.phoneField()?.focus();
      return;
    }
    this.step.set(2);
    queueMicrotask(() => this.pinInputs()?.focus());
  }

  protected back(): void {
    this.step.set(1);
  }

  /** Step 2 → the "confirm your number" dialog (step 3). */
  protected review(): void {
    if (!this.acceptTerms()) return;
    this.recoverySubmitted.set(true);
    if (this.pinError() || this.confirmPinError()) {
      this.pinInputs()?.focus();
      return;
    }
    this.dialogError.set(null);
    this.confirming.set(true);
  }

  /** "Edit": back to the number. */
  protected edit(): void {
    if (this.busy()) return;
    this.confirming.set(false);
    this.step.set(1);
    queueMicrotask(() => this.phoneField()?.focus());
  }

  protected async create(): Promise<void> {
    if (this.busy()) return;
    const { phone, password } = this.account.getRawValue();
    this.busy.set(true);
    this.dialogError.set(null);
    try {
      const me = await this.auth.register({ phoneNumber: phone, password, recoveryPin: normalizePin(this.recovery.getRawValue().pin), acceptTerms: this.acceptTerms() });
      const country = this.phoneField()?.selectedCountry;
      if (country) rememberCountry(country);
      this.flow.phone.set(null);
      this.confirming.set(false);
      await this.router.navigateByUrl(postAuthUrl(me, this.returnUrl()));
    } catch (error) {
      this.handleError(error);
    } finally {
      this.busy.set(false);
    }
  }

  protected goToSignIn(): void {
    this.flow.phone.set(this.account.controls.phone.value || null);
    void this.router.navigate(['/auth/sign-in'], { queryParams: this.returnParams() });
  }

  private handleError(error: unknown): void {
    if (isApiError(error) && error.code === 'auth.phone_taken') {
      this.confirming.set(false);
      this.step.set(1);
      this.phoneTaken.set(true);
      queueMicrotask(() => this.phoneField()?.focus());
      return;
    }
    const phone = fieldErrors(error, 'phoneNumber');
    const password = fieldErrors(error, 'password');
    const pin = fieldErrors(error, 'recoveryPin');
    if (phone.length || password.length || pin.length) {
      this.server.set({ phone, password, pin });
      this.confirming.set(false);
      this.step.set(phone.length || password.length ? 1 : 2);
      return;
    }
    this.dialogError.set(isApiError(error) ? this.errors.forCode(error.code) : this.transloco.translate('errors.unknown'));
  }
}
