import { ChangeDetectionStrategy, Component, computed, effect, inject, input, output, signal, untracked, viewChild } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../../core/api/api.config';
import { MeApi } from '../../../core/api/me.api';
import { AccountConfirmation, ExternalCredential, ExternalProvider } from '../../../core/api/models';
import { AuthConfigService } from '../../../core/auth/auth-config.service';
import { AuthService } from '../../../core/auth/auth.service';
import { ExternalResult } from '../../../core/auth/external-identity.service';
import { SessionStore } from '../../../core/auth/session.store';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { BottomSheet } from '../../../shared/ui/bottom-sheet';
import { ExternalButtons } from '../../../shared/ui/external/external-buttons';
import { PasswordField } from '../../../shared/ui/password/password-field';
import { passwordViolations } from '../../../shared/ui/password/password-rules';
import { ConfirmPhoneDialog } from '../../../shared/ui/phone/confirm-phone-dialog';
import { rememberCountry } from '../../../shared/ui/phone/countries';
import { PhoneField } from '../../../shared/ui/phone/phone-field';
import { PinInput } from '../../../shared/ui/pin/pin-input';
import { normalizePin, pinViolations } from '../../../shared/ui/pin/pin-rules';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { SubmitButton, fieldErrors } from '../../auth/auth-shared';

export const PROVIDER_NAMES: Record<ExternalProvider, string> = { google: 'Google', apple: 'Apple' };

/** Only what the API needs from a provider result (Apple's one-time name isn't sent here). */
function credentialOf(result: ExternalResult): ExternalCredential {
  return { provider: result.provider, idToken: result.idToken, ...(result.nonce ? { nonce: result.nonce } : {}) };
}

/**
 * Settings → Linked accounts → "اربط" (F18, ADR 0012): pick the Google/Apple account, then confirm it's you with the
 * password, or (accounts without one) with an already linked provider.
 */
@Component({
  selector: 'rd-link-provider-sheet',
  imports: [ReactiveFormsModule, TranslocoPipe, BottomSheet, ExternalButtons, PasswordField, SubmitButton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="!!provider()" labelledBy="link-provider-title" [dismissible]="!busy()" (closed)="close()">
      <div class="flex flex-col gap-4 pt-1" data-link-provider>
        <h2 id="link-provider-title" class="m-0 pe-10 text-xl font-semibold">{{ 'account.linked.linkTitle' | transloco: { provider: name() } }}</h2>
        @if (!credential()) {
          <p class="m-0 text-sm text-text-secondary">{{ 'account.linked.pick' | transloco: { provider: name() } }}</p>
          <rd-external-buttons [only]="provider() ? [provider()!] : []" [busy]="busy()" (credential)="picked($event)" />
        } @else if (hasPassword()) {
          <form [formGroup]="form" (ngSubmit)="save({ password: form.controls.password.value })" class="flex flex-col gap-4" novalidate>
            <p class="m-0 text-sm text-text-secondary">{{ 'account.linked.confirmPassword' | transloco }}</p>
            <div>
              <label class="rd-label" for="link-provider-password">{{ 'auth.currentPassword' | transloco }}</label>
              <rd-password-field inputId="link-provider-password" autocomplete="current-password" formControlName="password" [invalid]="wrongPassword()" />
              @if (wrongPassword()) {
                <p class="rd-field-error">{{ 'errors.auth.wrong_password' | transloco }}</p>
              }
            </div>
            <rd-submit-button [busy]="busy()" [disabled]="!form.controls.password.value">{{ 'account.linked.link' | transloco }}</rd-submit-button>
          </form>
        } @else {
          <p class="m-0 text-sm text-text-secondary">{{ 'account.linked.confirmProvider' | transloco }}</p>
          <rd-external-buttons [only]="linked()" [busy]="busy()" (credential)="save({ external: credentialOf($event) })" />
        }
        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert" data-sheet-error>{{ error() }}</p>
        }
      </div>
    </rd-bottom-sheet>
  `,
})
export class LinkProviderSheet {
  /** The provider to link; null closes the sheet. */
  readonly provider = input<ExternalProvider | null>(null);
  readonly closed = output<void>();

  private readonly meApi = inject(MeApi);
  private readonly auth = inject(AuthService);
  private readonly session = inject(SessionStore);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);

  protected readonly form = inject(FormBuilder).nonNullable.group({ password: [''] });
  protected readonly credential = signal<ExternalCredential | null>(null);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly wrongPassword = signal(false);
  protected readonly name = computed(() => PROVIDER_NAMES[this.provider() ?? 'google']);
  protected readonly hasPassword = computed(() => this.session.me()?.hasPassword ?? true);
  protected readonly linked = computed(() => (this.session.me()?.externalLogins ?? []).map((l) => l.provider));
  protected readonly credentialOf = credentialOf;

  constructor() {
    effect(() => {
      this.provider();
      untracked(() => {
        this.credential.set(null);
        this.error.set(null);
        this.wrongPassword.set(false);
        this.form.reset();
      });
    });
    this.form.valueChanges.subscribe(() => this.wrongPassword.set(false));
  }

  protected picked(result: ExternalResult): void {
    this.error.set(null);
    this.credential.set(credentialOf(result));
  }

  protected async save(confirmation: AccountConfirmation): Promise<void> {
    const credential = this.credential();
    if (!credential || this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      const me = await firstValueFrom(this.meApi.linkExternal(credential, confirmation));
      this.auth.updateMe(me);
      this.toasts.success(this.transloco.translate('account.linked.done', { provider: this.name() }));
      this.busy.set(false);
      this.closed.emit();
    } catch (error) {
      if (isApiError(error) && error.code === 'auth.wrong_password') {
        this.wrongPassword.set(true);
      } else {
        // Anything else means starting again with the provider (in use, conflict, expired token…).
        if (isApiError(error) && error.code !== 'auth.locked_out') this.credential.set(null);
        this.error.set(isApiError(error) ? this.errors.forCode(error.code) : this.errors.forError(error));
      }
    } finally {
      this.busy.set(false);
    }
  }

  protected close(): void {
    if (!this.busy()) this.closed.emit();
  }
}

/** Settings → Linked accounts → "فك الربط". The API refuses to remove the only way to sign in. */
@Component({
  selector: 'rd-unlink-provider-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="!!provider()" role="alertdialog" labelledBy="unlink-title" describedBy="unlink-body" [dismissible]="!busy()" (closed)="close()">
      <div class="flex flex-col gap-4 pt-1" data-unlink-provider>
        <h2 id="unlink-title" class="m-0 pe-10 text-xl font-semibold">{{ 'account.linked.unlinkTitle' | transloco: { provider: name() } }}</h2>
        <p id="unlink-body" class="m-0 text-sm text-text-secondary">{{ 'account.linked.unlinkBody' | transloco: { provider: name() } }}</p>
        @if (lastMethod()) {
          <div class="rd-alert rd-alert-info flex items-start gap-2" role="alert" data-last-method>
            <svg lucideIcon="Info" [size]="18" class="mt-0.5 shrink-0 text-primary" aria-hidden="true"></svg>
            <div>
              <p class="m-0 font-semibold">{{ 'errors.auth.last_sign_in_method' | transloco }}</p>
              <p class="m-0 mt-1">{{ 'account.linked.lastMethodHint' | transloco }}</p>
            </div>
          </div>
        } @else if (error()) {
          <p class="rd-alert rd-alert-error" role="alert">{{ error() }}</p>
        }
        <div class="flex flex-col gap-2 sm:flex-row-reverse">
          @if (!lastMethod()) {
            <button type="button" class="rd-btn rd-btn-primary flex-1" [disabled]="busy()" [attr.aria-busy]="busy()" (click)="confirm()" data-unlink-confirm>
              @if (busy()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ 'account.linked.unlink' | transloco }}
            </button>
          }
          <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="close()">
            {{ (lastMethod() ? 'auth.support.done' : 'common.cancel') | transloco }}
          </button>
        </div>
      </div>
    </rd-bottom-sheet>
  `,
})
export class UnlinkProviderSheet {
  readonly provider = input<ExternalProvider | null>(null);
  readonly closed = output<void>();

  private readonly meApi = inject(MeApi);
  private readonly auth = inject(AuthService);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);

  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly lastMethod = signal(false);
  protected readonly name = computed(() => PROVIDER_NAMES[this.provider() ?? 'google']);

  constructor() {
    effect(() => {
      this.provider();
      untracked(() => {
        this.error.set(null);
        this.lastMethod.set(false);
      });
    });
  }

  protected async confirm(): Promise<void> {
    const provider = this.provider();
    if (!provider || this.busy()) return;
    this.busy.set(true);
    try {
      const me = await firstValueFrom(this.meApi.unlinkExternal(provider));
      this.auth.updateMe(me);
      this.toasts.success(this.transloco.translate('account.linked.unlinked', { provider: this.name() }));
      this.busy.set(false);
      this.closed.emit();
    } catch (error) {
      if (isApiError(error) && error.code === 'auth.last_sign_in_method') this.lastMethod.set(true);
      else this.error.set(isApiError(error) ? this.errors.forCode(error.code) : this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }

  protected close(): void {
    if (!this.busy()) this.closed.emit();
  }
}

type AddStage = 'form' | 'confirm' | 'reauth';

/**
 * "ضيف رقم تليفون وكلمة سر" (F18): Google/Apple-only accounts add phone + password + recovery PIN. The number is
 * confirmed in the confirm-number dialog, then the person proves it's them with a linked provider.
 */
@Component({
  selector: 'rd-add-phone-sign-in-sheet',
  imports: [ReactiveFormsModule, TranslocoPipe, BottomSheet, ExternalButtons, PhoneField, PasswordField, PinInput, SubmitButton, ConfirmPhoneDialog],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open() && stage() === 'form'" labelledBy="add-phone-title" [dismissible]="!busy()" (closed)="close()">
      <form [formGroup]="form" (ngSubmit)="review()" class="flex flex-col gap-4 pt-1" novalidate data-add-phone>
        <h2 id="add-phone-title" class="m-0 pe-10 text-xl font-semibold">{{ 'account.addPhone.title' | transloco }}</h2>
        <p class="m-0 text-sm text-text-secondary">{{ 'account.addPhone.body' | transloco }}</p>
        <div>
          <label class="rd-label" for="add-phone-number">{{ 'auth.phone' | transloco }}</label>
          <rd-phone-field inputId="add-phone-number" formControlName="phone" [invalid]="!!phoneError()" [describedBy]="phoneError() ? 'add-phone-number-error' : null" />
          @if (phoneError()) {
            <p id="add-phone-number-error" class="rd-field-error">{{ phoneError()! | transloco }}</p>
          }
        </div>
        <div>
          <label class="rd-label" for="add-phone-password">{{ 'auth.password' | transloco }}</label>
          <rd-password-field
            inputId="add-phone-password"
            autocomplete="new-password"
            formControlName="password"
            [showStrength]="true"
            [policy]="policy()"
            [phone]="value().phone || null"
            [invalid]="passwordErrors().length > 0"
          />
          @for (code of passwordErrors(); track code) {
            <p class="rd-field-error">{{ 'errors.' + code | transloco }}</p>
          }
        </div>
        <div>
          <label class="rd-label" for="add-phone-confirm">{{ 'auth.confirmPassword' | transloco }}</label>
          <rd-password-field inputId="add-phone-confirm" autocomplete="new-password" formControlName="confirm" [invalid]="!!confirmError()" />
          @if (confirmError()) {
            <p class="rd-field-error">{{ confirmError()! | transloco }}</p>
          }
        </div>
        <div>
          <label id="add-phone-pin-label" class="rd-label" for="add-phone-pin-0">{{ 'auth.pin' | transloco }}</label>
          <rd-pin-input idPrefix="add-phone-pin" labelledBy="add-phone-pin-label" formControlName="pin" [length]="pinLength()" [invalid]="!!pinError()" />
          @if (pinError()) {
            <p class="rd-field-error">{{ pinError()! | transloco }}</p>
          }
        </div>
        <div>
          <label id="add-phone-pin-confirm-label" class="rd-label" for="add-phone-pin-confirm-0">{{ 'auth.confirmPin' | transloco }}</label>
          <rd-pin-input idPrefix="add-phone-pin-confirm" labelledBy="add-phone-pin-confirm-label" formControlName="confirmPin" [length]="pinLength()" [invalid]="!!confirmPinError()" />
          @if (confirmPinError()) {
            <p class="rd-field-error">{{ confirmPinError()! | transloco }}</p>
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
      [confirmLabel]="'account.addPhone.confirm' | transloco"
      (confirm)="stage.set('reauth')"
      (edit)="stage.set('form')"
    />

    <rd-bottom-sheet [open]="open() && stage() === 'reauth'" labelledBy="add-phone-reauth-title" [dismissible]="!busy()" (closed)="stage.set('form')">
      <div class="flex flex-col gap-4 pt-1" data-add-phone-reauth>
        <h2 id="add-phone-reauth-title" class="m-0 pe-10 text-xl font-semibold">{{ 'account.addPhone.reauthTitle' | transloco }}</h2>
        <p class="m-0 text-sm text-text-secondary">{{ 'account.addPhone.reauthBody' | transloco }}</p>
        <rd-external-buttons [only]="linked()" [busy]="busy()" (credential)="save($event)" />
        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert">{{ error() }}</p>
        }
      </div>
    </rd-bottom-sheet>
  `,
})
export class AddPhoneSignInSheet {
  readonly open = input(false);
  readonly closed = output<void>();

  private readonly auth = inject(AuthService);
  private readonly session = inject(SessionStore);
  private readonly config = inject(AuthConfigService);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly phoneField = viewChild(PhoneField);

  protected readonly form = inject(FormBuilder).nonNullable.group({
    phone: ['', Validators.required],
    password: [''],
    confirm: [''],
    pin: [''],
    confirmPin: [''],
  });
  protected readonly value = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });
  protected readonly stage = signal<AddStage>('form');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  private readonly submitted = signal(false);
  private readonly server = signal<{ phone: string | null; password: string[]; pin: string | null }>({ phone: null, password: [], pin: null });

  protected readonly policy = computed(() => this.config.config().password);
  protected readonly pinLength = computed(() => this.config.config().pinLength);
  protected readonly linked = computed(() => (this.session.me()?.externalLogins ?? []).map((l) => l.provider));

  protected readonly phoneError = computed(() => {
    const { phone } = this.value();
    if (this.server().phone) return this.server().phone;
    if (!this.submitted()) return null;
    if (!phone) return 'auth.validation.phoneRequired';
    return this.form.controls.phone.hasError('phoneInvalid') ? 'errors.phone.invalid' : null;
  });
  protected readonly passwordErrors = computed(() => {
    const { password, phone } = this.value();
    if (this.server().password.length) return this.server().password;
    const codes = passwordViolations(password ?? '', this.policy(), phone || null);
    if (this.submitted()) return codes;
    return password ? codes.filter((c) => c === 'password.too_common' || c === 'password.contains_phone' || c === 'password.too_long') : [];
  });
  protected readonly confirmError = computed(() => {
    const { password, confirm } = this.value();
    if (!confirm) return this.submitted() ? 'auth.validation.confirmPassword' : null;
    return confirm !== password ? 'auth.validation.passwordMismatch' : null;
  });
  protected readonly pinError = computed(() => {
    if (this.server().pin) return this.server().pin;
    const { pin, phone, password } = this.value();
    const normalized = normalizePin(pin);
    if (normalized.length !== this.pinLength() && !this.submitted()) return null;
    const [code] = pinViolations(normalized, this.pinLength(), { phoneE164: phone || null, password });
    return code ? `errors.${code}` : null;
  });
  protected readonly confirmPinError = computed(() => {
    const { pin, confirmPin } = this.value();
    const confirmed = normalizePin(confirmPin);
    if (!confirmed) return this.submitted() ? 'auth.validation.confirmPin' : null;
    if (confirmed.length < this.pinLength() && !this.submitted()) return null;
    return confirmed !== normalizePin(pin) ? 'auth.validation.pinMismatch' : null;
  });

  constructor() {
    effect(() => {
      if (!this.open()) return;
      untracked(() => {
        this.form.reset();
        this.stage.set('form');
        this.submitted.set(false);
        this.error.set(null);
        this.server.set({ phone: null, password: [], pin: null });
        void this.config.load();
      });
    });
    this.form.valueChanges.subscribe(() => {
      this.error.set(null);
      this.server.set({ phone: null, password: [], pin: null });
    });
  }

  protected review(): void {
    this.submitted.set(true);
    if (this.phoneError() || this.passwordErrors().length || this.confirmError() || this.pinError() || this.confirmPinError()) return;
    this.stage.set('confirm');
  }

  protected async save(result: ExternalResult): Promise<void> {
    if (this.busy()) return;
    const { phone, password, pin } = this.form.getRawValue();
    this.busy.set(true);
    this.error.set(null);
    try {
      await this.auth.addPhoneSignIn({ phoneNumber: phone, password, recoveryPin: normalizePin(pin), external: credentialOf(result) });
      const country = this.phoneField()?.selectedCountry;
      if (country) rememberCountry(country);
      this.toasts.success(this.transloco.translate('account.addPhone.done'));
      this.busy.set(false);
      this.closed.emit();
    } catch (error) {
      const phoneCodes = fieldErrors(error, 'phoneNumber');
      const passwordCodes = fieldErrors(error, 'password');
      const pinCodes = fieldErrors(error, 'recoveryPin');
      if (isApiError(error) && error.code === 'auth.phone_taken') {
        this.server.set({ phone: 'errors.auth.phone_taken', password: [], pin: null });
        this.stage.set('form');
      } else if (phoneCodes.length || passwordCodes.length || pinCodes.length) {
        this.server.set({
          phone: phoneCodes.length ? `errors.${phoneCodes[0]}` : null,
          password: passwordCodes,
          pin: pinCodes.length ? `errors.${pinCodes[0]}` : null,
        });
        this.stage.set('form');
      } else {
        this.error.set(isApiError(error) ? this.errors.forCode(error.code) : this.errors.forError(error));
      }
    } finally {
      this.busy.set(false);
    }
  }

  protected close(): void {
    if (!this.busy()) this.closed.emit();
  }
}
