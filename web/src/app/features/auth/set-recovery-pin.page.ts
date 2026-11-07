import { ChangeDetectionStrategy, Component, computed, inject, input, signal, viewChild } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { MeApi } from '../../core/api/me.api';
import { postAuthUrl } from '../../core/auth/account-setup';
import { AuthConfigService } from '../../core/auth/auth-config.service';
import { AuthService } from '../../core/auth/auth.service';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { PinInput } from '../../shared/ui/pin/pin-input';
import { normalizePin, pinViolations } from '../../shared/ui/pin/pin-rules';
import { AuthCard, SubmitButton, fieldErrors } from './auth-shared';

/**
 * Mandatory "set recovery PIN" (SPEC §9.2, ADR 0009): accounts created before the PIN existed, admin-reset accounts
 * and the production SuperAdmin. It can't be skipped (the account-setup guard keeps sending the user here).
 */
@Component({
  selector: 'rd-set-recovery-pin-page',
  imports: [ReactiveFormsModule, TranslocoPipe, LucideDynamicIcon, AuthCard, SubmitButton, PinInput],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-auth-card [title]="'auth.setPin.title' | transloco" [subtitle]="'auth.setPin.subtitle' | transloco">
      <form [formGroup]="form" (ngSubmit)="save()" class="flex flex-col gap-5" novalidate data-set-pin>
        <p class="rd-alert rd-alert-info m-0 flex items-start gap-2">
          <svg lucideIcon="ShieldCheck" [size]="18" class="mt-0.5 shrink-0 text-primary" aria-hidden="true"></svg>
          <span>{{ 'auth.signUp.pinExplain' | transloco }}</span>
        </p>
        <div>
          <label id="set-pin-label" class="rd-label" for="set-pin-0">{{ 'auth.pin' | transloco }}</label>
          <rd-pin-input
            idPrefix="set-pin"
            labelledBy="set-pin-label"
            formControlName="pin"
            [length]="pinLength()"
            [invalid]="!!pinError()"
            [describedBy]="pinError() ? 'set-pin-error' : 'set-pin-hint'"
          />
          @if (pinError()) {
            <p id="set-pin-error" class="rd-field-error">{{ pinError()! | transloco: { length: pinLength() } }}</p>
          } @else {
            <p id="set-pin-hint" class="rd-field-hint">{{ 'auth.pinHint' | transloco: { length: pinLength() } }}</p>
          }
        </div>
        <div>
          <label id="set-pin-confirm-label" class="rd-label" for="set-pin-confirm-0">{{ 'auth.confirmPin' | transloco }}</label>
          <rd-pin-input
            idPrefix="set-pin-confirm"
            labelledBy="set-pin-confirm-label"
            formControlName="confirm"
            [length]="pinLength()"
            [invalid]="!!confirmError()"
            [describedBy]="confirmError() ? 'set-pin-confirm-error' : null"
          />
          @if (confirmError()) {
            <p id="set-pin-confirm-error" class="rd-field-error">{{ confirmError()! | transloco }}</p>
          }
        </div>
        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert" data-error>{{ error() }}</p>
        }
        <rd-submit-button [busy]="busy()">{{ 'auth.setPin.submit' | transloco }}</rd-submit-button>
      </form>
      <p class="mt-6 text-center text-sm">
        <button type="button" class="border-0 bg-transparent p-0 text-text-secondary underline-offset-2 hover:underline" [disabled]="busy()" (click)="signOut()">
          {{ 'auth.signOut' | transloco }}
        </button>
      </p>
    </rd-auth-card>
  `,
})
export class SetRecoveryPinPage {
  private readonly auth = inject(AuthService);
  private readonly meApi = inject(MeApi);
  private readonly router = inject(Router);
  private readonly errors = inject(ErrorMessages);
  private readonly config = inject(AuthConfigService);
  private readonly pinInput = viewChild.required(PinInput);

  readonly returnUrl = input<string | null>(null);

  protected readonly form = inject(FormBuilder).nonNullable.group({ pin: [''], confirm: [''] });
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  private readonly submitted = signal(false);
  private readonly serverPinError = signal<string | null>(null);
  private readonly value = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });

  protected readonly pinLength = computed(() => this.config.config().pinLength);

  protected readonly pinError = computed(() => {
    if (this.serverPinError()) return this.serverPinError();
    const pin = normalizePin(this.value().pin);
    if (pin.length !== this.pinLength() && !this.submitted()) return null;
    const [code] = pinViolations(pin, this.pinLength());
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
    void this.config.load();
    this.form.valueChanges.subscribe(() => {
      this.error.set(null);
      this.serverPinError.set(null);
    });
  }

  protected async save(): Promise<void> {
    if (this.busy()) return;
    this.submitted.set(true);
    if (this.pinError() || this.confirmError()) return this.pinInput().focus();

    this.busy.set(true);
    try {
      const me = await firstValueFrom(this.meApi.setRecoveryPin(normalizePin(this.form.getRawValue().pin)));
      this.auth.updateMe(me);
      await this.router.navigateByUrl(postAuthUrl(me, this.returnUrl()));
    } catch (error) {
      if (isApiError(error) && error.code === 'auth.pin_already_set') {
        // Set from another device meanwhile: carry on with the next step.
        const me = await this.auth.refreshMe();
        await this.router.navigateByUrl(postAuthUrl(me, this.returnUrl()));
        return;
      }
      const codes = fieldErrors(error, 'pin');
      if (codes.length) this.serverPinError.set(`errors.${codes[0]}`);
      else this.error.set(isApiError(error) ? this.errors.forCode(error.code) : this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }

  protected async signOut(): Promise<void> {
    await this.auth.signOut();
    await this.router.navigateByUrl('/');
  }
}
