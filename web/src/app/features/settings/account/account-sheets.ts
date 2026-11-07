import { ChangeDetectionStrategy, Component, Directive, computed, effect, inject, input, output, signal, untracked, viewChild } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../../core/api/api.config';
import { MeApi } from '../../../core/api/me.api';
import { AuthConfigService } from '../../../core/auth/auth-config.service';
import { AuthService } from '../../../core/auth/auth.service';
import { SessionStore } from '../../../core/auth/session.store';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { BottomSheet } from '../../../shared/ui/bottom-sheet';
import { PasswordField } from '../../../shared/ui/password/password-field';
import { passwordViolations } from '../../../shared/ui/password/password-rules';
import { ConfirmPhoneDialog } from '../../../shared/ui/phone/confirm-phone-dialog';
import { rememberCountry } from '../../../shared/ui/phone/countries';
import { PhoneField } from '../../../shared/ui/phone/phone-field';
import { PinInput } from '../../../shared/ui/pin/pin-input';
import { normalizePin, pinViolations } from '../../../shared/ui/pin/pin-rules';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { SubmitButton, fieldErrors } from '../../auth/auth-shared';

/** Errors every account form shares: a wrong current password goes under that field, the rest in an alert. */
@Directive()
abstract class AccountSheet {
  readonly open = input(false);
  readonly closed = output<void>();

  protected readonly auth = inject(AuthService);
  protected readonly toasts = inject(ToastService);
  protected readonly errors = inject(ErrorMessages);
  protected readonly transloco = inject(TranslocoService);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly wrongPassword = signal(false);
  protected readonly submitted = signal(false);

  constructor() {
    // Every time the sheet opens it starts empty.
    effect(() => {
      if (!this.open()) return;
      untracked(() => {
        this.reset();
        this.error.set(null);
        this.wrongPassword.set(false);
        this.submitted.set(false);
      });
    });
  }

  /** Clears the sheet's own form state when it opens. */
  protected abstract reset(): void;

  protected close(): void {
    if (!this.busy()) this.closed.emit();
  }

  /** True when the error was handled as "wrong current password". */
  protected showError(error: unknown): boolean {
    if (isApiError(error) && error.code === 'auth.wrong_password') {
      this.wrongPassword.set(true);
      return true;
    }
    this.error.set(isApiError(error) ? this.errors.forCode(error.code) : this.errors.forError(error));
    return false;
  }
}

const PASSWORD_LIVE_CODES = new Set(['password.too_common', 'password.contains_phone', 'password.too_long']);

/** "تغيير الرقم" (F18): new number + current password, then the same confirm-number dialog as sign up. */
@Component({
  selector: 'rd-change-phone-sheet',
  imports: [ReactiveFormsModule, TranslocoPipe, BottomSheet, PhoneField, PasswordField, SubmitButton, ConfirmPhoneDialog],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open() && stage() === 'form'" labelledBy="change-phone-title" [dismissible]="!busy()" (closed)="close()">
      <form [formGroup]="form" (ngSubmit)="review()" class="flex flex-col gap-4 pt-1" novalidate data-change-phone>
        <h2 id="change-phone-title" class="m-0 pe-10 text-xl font-semibold">{{ 'account.changePhone.title' | transloco }}</h2>
        <p class="m-0 text-sm text-text-secondary">{{ 'account.changePhone.body' | transloco }}</p>
        <div>
          <label class="rd-label" for="change-phone-number">{{ 'account.changePhone.newNumber' | transloco }}</label>
          <rd-phone-field inputId="change-phone-number" formControlName="phone" [invalid]="!!phoneError()" [describedBy]="phoneError() ? 'change-phone-number-error' : null" />
          @if (phoneError()) {
            <p id="change-phone-number-error" class="rd-field-error">{{ phoneError()! | transloco }}</p>
          }
        </div>
        <div>
          <label class="rd-label" for="change-phone-password">{{ 'auth.currentPassword' | transloco }}</label>
          <rd-password-field inputId="change-phone-password" autocomplete="current-password" formControlName="password" [invalid]="!!passwordError()" [describedBy]="passwordError() ? 'change-phone-password-error' : null" />
          @if (passwordError()) {
            <p id="change-phone-password-error" class="rd-field-error">{{ passwordError()! | transloco }}</p>
          }
        </div>
        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert">{{ error() }}</p>
        }
        <rd-submit-button>{{ 'common.continue' | transloco }}</rd-submit-button>
      </form>
    </rd-bottom-sheet>
    <rd-confirm-phone-dialog
      [open]="open() && stage() === 'confirm'"
      [phone]="value().phone ?? null"
      [confirmLabel]="'auth.confirmPhone.change' | transloco"
      [busy]="busy()"
      [error]="dialogError()"
      (confirm)="save()"
      (edit)="stage.set('form')"
    />
  `,
})
export class ChangePhoneSheet extends AccountSheet {
  private readonly session = inject(SessionStore);
  private readonly phoneField = viewChild(PhoneField);
  protected readonly form = inject(FormBuilder).nonNullable.group({ phone: ['', Validators.required], password: [''] });
  protected readonly value = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });
  protected readonly stage = signal<'form' | 'confirm'>('form');
  protected readonly dialogError = signal<string | null>(null);
  private readonly serverPhoneError = signal<string | null>(null);

  protected readonly phoneError = computed(() => {
    const { phone } = this.value();
    if (this.serverPhoneError()) return this.serverPhoneError();
    if (!this.submitted()) return null;
    if (!phone) return 'auth.validation.phoneRequired';
    if (this.form.controls.phone.hasError('phoneInvalid')) return 'errors.phone.invalid';
    return phone === this.session.phoneNumber() ? 'errors.auth.phone_unchanged' : null;
  });
  protected readonly passwordError = computed(() => {
    this.value();
    if (this.wrongPassword()) return 'errors.auth.wrong_password';
    return this.submitted() && !this.value().password ? 'auth.validation.required' : null;
  });

  constructor() {
    super();
    this.form.valueChanges.subscribe(() => {
      this.wrongPassword.set(false);
      this.serverPhoneError.set(null);
      this.error.set(null);
    });
  }

  protected reset(): void {
    this.form.reset();
    this.stage.set('form');
    this.dialogError.set(null);
    this.serverPhoneError.set(null);
  }

  protected review(): void {
    this.submitted.set(true);
    if (this.phoneError() || this.passwordError()) return;
    this.dialogError.set(null);
    this.stage.set('confirm');
  }

  protected async save(): Promise<void> {
    if (this.busy()) return;
    const { phone, password } = this.form.getRawValue();
    this.busy.set(true);
    try {
      await this.auth.changePhone(phone, password);
      const country = this.phoneField()?.selectedCountry;
      if (country) rememberCountry(country);
      this.toasts.success(this.transloco.translate('account.changePhone.done'));
      this.busy.set(false);
      this.closed.emit();
    } catch (error) {
      const phoneCodes = fieldErrors(error, 'newPhoneNumber');
      if (isApiError(error) && (error.code === 'auth.phone_taken' || error.code === 'auth.phone_unchanged')) {
        this.serverPhoneError.set(`errors.${error.code}`);
        this.stage.set('form');
      } else if (phoneCodes.length) {
        this.serverPhoneError.set(`errors.${phoneCodes[0]}`);
        this.stage.set('form');
      } else if (isApiError(error) && error.code === 'auth.wrong_password') {
        this.wrongPassword.set(true);
        this.stage.set('form');
      } else {
        this.dialogError.set(isApiError(error) ? this.errors.forCode(error.code) : this.errors.forError(error));
      }
    } finally {
      this.busy.set(false);
    }
  }
}

/** "تغيير كلمة السر" (F18): current + new + confirm. Other sessions end; this one gets fresh tokens. */
@Component({
  selector: 'rd-change-password-sheet',
  imports: [ReactiveFormsModule, TranslocoPipe, BottomSheet, PasswordField, SubmitButton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" labelledBy="change-password-title" [dismissible]="!busy()" (closed)="close()">
      <form [formGroup]="form" (ngSubmit)="save()" class="flex flex-col gap-4 pt-1" novalidate data-change-password-sheet>
        <h2 id="change-password-title" class="m-0 pe-10 text-xl font-semibold">{{ 'account.changePassword.title' | transloco }}</h2>
        <p class="m-0 text-sm text-text-secondary">{{ 'account.changePassword.body' | transloco }}</p>
        <div>
          <label class="rd-label" for="change-password-current">{{ 'auth.currentPassword' | transloco }}</label>
          <rd-password-field inputId="change-password-current" autocomplete="current-password" formControlName="current" [invalid]="!!currentError()" [describedBy]="currentError() ? 'change-password-current-error' : null" />
          @if (currentError()) {
            <p id="change-password-current-error" class="rd-field-error">{{ currentError()! | transloco }}</p>
          }
        </div>
        <div>
          <label class="rd-label" for="change-password-new">{{ 'auth.newPassword' | transloco }}</label>
          <rd-password-field
            inputId="change-password-new"
            autocomplete="new-password"
            formControlName="password"
            [showStrength]="true"
            [policy]="policy()"
            [phone]="phone()"
            [invalid]="passwordErrors().length > 0"
            [describedBy]="passwordErrors().length ? 'change-password-new-error' : null"
          />
          @if (passwordErrors().length) {
            <ul id="change-password-new-error" class="m-0 list-none p-0">
              @for (code of passwordErrors(); track code) {
                <li class="rd-field-error">{{ 'errors.' + code | transloco: { min: policy().minLength, max: policy().maxLength } }}</li>
              }
            </ul>
          }
        </div>
        <div>
          <label class="rd-label" for="change-password-confirm">{{ 'auth.confirmPassword' | transloco }}</label>
          <rd-password-field inputId="change-password-confirm" autocomplete="new-password" formControlName="confirm" [invalid]="!!confirmError()" [describedBy]="confirmError() ? 'change-password-confirm-error' : null" />
          @if (confirmError()) {
            <p id="change-password-confirm-error" class="rd-field-error">{{ confirmError()! | transloco }}</p>
          }
        </div>
        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert">{{ error() }}</p>
        }
        <rd-submit-button [busy]="busy()">{{ 'common.save' | transloco }}</rd-submit-button>
      </form>
    </rd-bottom-sheet>
  `,
})
export class ChangePasswordSheet extends AccountSheet {
  private readonly config = inject(AuthConfigService);
  protected readonly phone = inject(SessionStore).phoneNumber;
  protected readonly form = inject(FormBuilder).nonNullable.group({ current: [''], password: [''], confirm: [''] });
  private readonly value = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });
  private readonly serverPasswordErrors = signal<string[]>([]);
  protected readonly policy = computed(() => this.config.config().password);

  protected readonly currentError = computed(() => {
    if (this.wrongPassword()) return 'errors.auth.wrong_password';
    return this.submitted() && !this.value().current ? 'auth.validation.required' : null;
  });
  protected readonly passwordErrors = computed(() => {
    const { password } = this.value();
    if (this.serverPasswordErrors().length) return this.serverPasswordErrors();
    const codes = passwordViolations(password ?? '', this.policy(), this.phone());
    if (this.submitted()) return codes;
    return password ? codes.filter((c) => PASSWORD_LIVE_CODES.has(c)) : [];
  });
  protected readonly confirmError = computed(() => {
    const { password, confirm } = this.value();
    if (!confirm) return this.submitted() ? 'auth.validation.confirmPassword' : null;
    return confirm !== password ? 'auth.validation.passwordMismatch' : null;
  });

  constructor() {
    super();
    this.form.valueChanges.subscribe(() => {
      this.wrongPassword.set(false);
      this.serverPasswordErrors.set([]);
      this.error.set(null);
    });
  }

  protected reset(): void {
    this.form.reset();
    this.serverPasswordErrors.set([]);
    void this.config.load();
  }

  protected async save(): Promise<void> {
    if (this.busy()) return;
    this.submitted.set(true);
    if (this.currentError() || this.passwordErrors().length || this.confirmError()) return;
    const { current, password } = this.form.getRawValue();
    this.busy.set(true);
    try {
      await this.auth.changePassword(current, password);
      this.toasts.success(this.transloco.translate('account.changePassword.done'));
      this.busy.set(false);
      this.closed.emit();
    } catch (error) {
      const codes = fieldErrors(error, 'newPassword');
      if (codes.length) this.serverPasswordErrors.set(codes);
      else this.showError(error);
    } finally {
      this.busy.set(false);
    }
  }
}

/** "تغيير الـ PIN" (F18): current password + new PIN + confirm. */
@Component({
  selector: 'rd-change-pin-sheet',
  imports: [ReactiveFormsModule, TranslocoPipe, BottomSheet, PasswordField, PinInput, SubmitButton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" labelledBy="change-pin-title" [dismissible]="!busy()" (closed)="close()">
      <form [formGroup]="form" (ngSubmit)="save()" class="flex flex-col gap-4 pt-1" novalidate data-change-pin>
        <h2 id="change-pin-title" class="m-0 pe-10 text-xl font-semibold">{{ 'account.changePin.title' | transloco }}</h2>
        <p class="m-0 text-sm text-text-secondary">{{ 'account.changePin.body' | transloco }}</p>
        <div>
          <label class="rd-label" for="change-pin-password">{{ 'auth.currentPassword' | transloco }}</label>
          <rd-password-field inputId="change-pin-password" autocomplete="current-password" formControlName="password" [invalid]="!!passwordError()" [describedBy]="passwordError() ? 'change-pin-password-error' : null" />
          @if (passwordError()) {
            <p id="change-pin-password-error" class="rd-field-error">{{ passwordError()! | transloco }}</p>
          }
        </div>
        <div>
          <label id="change-pin-label" class="rd-label" for="change-pin-new-0">{{ 'account.changePin.newPin' | transloco }}</label>
          <rd-pin-input idPrefix="change-pin-new" labelledBy="change-pin-label" formControlName="pin" [length]="pinLength()" [invalid]="!!pinError()" [describedBy]="pinError() ? 'change-pin-new-error' : null" />
          @if (pinError()) {
            <p id="change-pin-new-error" class="rd-field-error">{{ pinError()! | transloco: { length: pinLength() } }}</p>
          }
        </div>
        <div>
          <label id="change-pin-confirm-label" class="rd-label" for="change-pin-confirm-0">{{ 'auth.confirmPin' | transloco }}</label>
          <rd-pin-input idPrefix="change-pin-confirm" labelledBy="change-pin-confirm-label" formControlName="confirm" [length]="pinLength()" [invalid]="!!confirmError()" [describedBy]="confirmError() ? 'change-pin-confirm-error' : null" />
          @if (confirmError()) {
            <p id="change-pin-confirm-error" class="rd-field-error">{{ confirmError()! | transloco }}</p>
          }
        </div>
        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert">{{ error() }}</p>
        }
        <rd-submit-button [busy]="busy()">{{ 'common.save' | transloco }}</rd-submit-button>
      </form>
    </rd-bottom-sheet>
  `,
})
export class ChangePinSheet extends AccountSheet {
  private readonly config = inject(AuthConfigService);
  private readonly meApi = inject(MeApi);
  private readonly session = inject(SessionStore);
  protected readonly form = inject(FormBuilder).nonNullable.group({ password: [''], pin: [''], confirm: [''] });
  private readonly value = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });
  private readonly serverPinError = signal<string | null>(null);
  protected readonly pinLength = computed(() => this.config.config().pinLength);

  protected readonly passwordError = computed(() => {
    if (this.wrongPassword()) return 'errors.auth.wrong_password';
    return this.submitted() && !this.value().password ? 'auth.validation.required' : null;
  });
  protected readonly pinError = computed(() => {
    if (this.serverPinError()) return this.serverPinError();
    const normalized = normalizePin(this.value().pin);
    if (normalized.length !== this.pinLength() && !this.submitted()) return null;
    const [code] = pinViolations(normalized, this.pinLength());
    return code ? `errors.${code}` : null;
  });
  protected readonly confirmError = computed(() => {
    const { pin, confirm } = this.value();
    const confirmed = normalizePin(confirm);
    if (!confirmed) return this.submitted() ? 'auth.validation.confirmPin' : null;
    if (confirmed.length < this.pinLength() && !this.submitted()) return null;
    return confirmed !== normalizePin(pin) ? 'auth.validation.pinMismatch' : null;
  });

  constructor() {
    super();
    this.form.valueChanges.subscribe(() => {
      this.wrongPassword.set(false);
      this.serverPinError.set(null);
      this.error.set(null);
    });
  }

  protected reset(): void {
    this.form.reset();
    this.serverPinError.set(null);
    void this.config.load();
  }

  protected async save(): Promise<void> {
    if (this.busy()) return;
    this.submitted.set(true);
    if (this.passwordError() || this.pinError() || this.confirmError()) return;
    const { password, pin } = this.form.getRawValue();
    this.busy.set(true);
    try {
      await firstValueFrom(this.meApi.changeRecoveryPin(password, normalizePin(pin)));
      this.session.patchMe({ hasRecoveryPin: true, mustSetRecoveryPin: false });
      this.toasts.success(this.transloco.translate('account.changePin.done'));
      this.busy.set(false);
      this.closed.emit();
    } catch (error) {
      const codes = fieldErrors(error, 'newPin');
      if (codes.length) this.serverPinError.set(`errors.${codes[0]}`);
      else this.showError(error);
    } finally {
      this.busy.set(false);
    }
  }
}

/** "Sign out of all devices": every other session ends at once (new security stamp); this browser stays in. */
@Component({
  selector: 'rd-sign-out-everywhere-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" role="alertdialog" labelledBy="sign-out-all-title" describedBy="sign-out-all-body" [dismissible]="!busy()" (closed)="close()">
      <div class="flex flex-col gap-4 pt-1" data-sign-out-everywhere>
        <h2 id="sign-out-all-title" class="m-0 pe-10 text-xl font-semibold">{{ 'account.signOutEverywhere.title' | transloco }}</h2>
        <p id="sign-out-all-body" class="m-0 text-sm text-text-secondary">{{ 'account.signOutEverywhere.body' | transloco }}</p>
        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert">{{ error() }}</p>
        }
        <div class="flex flex-col gap-2 sm:flex-row-reverse">
          <button type="button" class="rd-btn rd-btn-primary flex-1" [disabled]="busy()" [attr.aria-busy]="busy()" (click)="confirm()">
            @if (busy()) {
              <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
            }
            {{ 'account.signOutEverywhere.confirm' | transloco }}
          </button>
          <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="close()">{{ 'common.cancel' | transloco }}</button>
        </div>
      </div>
    </rd-bottom-sheet>
  `,
})
export class SignOutEverywhereSheet extends AccountSheet {
  protected reset(): void {
    /* nothing to clear */
  }

  protected async confirm(): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    try {
      await this.auth.signOutEverywhere();
      this.toasts.success(this.transloco.translate('account.signOutEverywhere.done'));
      this.busy.set(false);
      this.closed.emit();
    } catch (error) {
      this.showError(error);
    } finally {
      this.busy.set(false);
    }
  }
}

