import { ChangeDetectionStrategy, Component, computed, inject, input, signal, viewChild } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { isApiError } from '../../core/api/api.config';
import { postAuthUrl } from '../../core/auth/account-setup';
import { AuthConfigService } from '../../core/auth/auth-config.service';
import { AuthService } from '../../core/auth/auth.service';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { PasswordField } from '../../shared/ui/password/password-field';
import { passwordViolations } from '../../shared/ui/password/password-rules';
import { AuthCard, SubmitButton, fieldErrors } from './auth-shared';

/**
 * Mandatory "change password" (SPEC §9.2): shown while `mustChangePassword` (after an Admin reset, or the production
 * SuperAdmin's first sign in). The temporary password is the current one. Can't be skipped, only signed out of.
 */
@Component({
  selector: 'rd-change-password-page',
  imports: [ReactiveFormsModule, TranslocoPipe, AuthCard, SubmitButton, PasswordField],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-auth-card [title]="'auth.mustChangePassword.title' | transloco" [subtitle]="'auth.mustChangePassword.subtitle' | transloco">
      <form [formGroup]="form" (ngSubmit)="save()" class="flex flex-col gap-4" novalidate data-change-password>
        <div>
          <label class="rd-label" for="must-current">{{ 'auth.temporaryPassword' | transloco }}</label>
          <rd-password-field
            inputId="must-current"
            autocomplete="current-password"
            formControlName="current"
            [invalid]="!!currentError()"
            [describedBy]="currentError() ? 'must-current-error' : null"
          />
          @if (currentError()) {
            <p id="must-current-error" class="rd-field-error">{{ currentError()! | transloco }}</p>
          }
        </div>
        <div>
          <label class="rd-label" for="must-new">{{ 'auth.newPassword' | transloco }}</label>
          <rd-password-field
            inputId="must-new"
            autocomplete="new-password"
            formControlName="password"
            [showStrength]="true"
            [policy]="policy()"
            [phone]="phone()"
            [invalid]="passwordErrors().length > 0"
            [describedBy]="passwordErrors().length ? 'must-new-error' : null"
          />
          @if (passwordErrors().length) {
            <ul id="must-new-error" class="m-0 list-none p-0">
              @for (code of passwordErrors(); track code) {
                <li class="rd-field-error">{{ 'errors.' + code | transloco: { min: policy().minLength, max: policy().maxLength } }}</li>
              }
            </ul>
          }
        </div>
        <div>
          <label class="rd-label" for="must-confirm">{{ 'auth.confirmPassword' | transloco }}</label>
          <rd-password-field
            inputId="must-confirm"
            autocomplete="new-password"
            formControlName="confirm"
            [invalid]="!!confirmError()"
            [describedBy]="confirmError() ? 'must-confirm-error' : null"
          />
          @if (confirmError()) {
            <p id="must-confirm-error" class="rd-field-error">{{ confirmError()! | transloco }}</p>
          }
        </div>
        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert" data-error>{{ error() }}</p>
        }
        <rd-submit-button [busy]="busy()">{{ 'common.save' | transloco }}</rd-submit-button>
      </form>
      <p class="mt-6 text-center text-sm">
        <button type="button" class="border-0 bg-transparent p-0 text-text-secondary underline-offset-2 hover:underline" [disabled]="busy()" (click)="signOut()">
          {{ 'auth.signOut' | transloco }}
        </button>
      </p>
    </rd-auth-card>
  `,
})
export class ChangePasswordPage {
  private readonly auth = inject(AuthService);
  private readonly session = inject(SessionStore);
  private readonly router = inject(Router);
  private readonly errors = inject(ErrorMessages);
  private readonly config = inject(AuthConfigService);
  // The first password field is the current one.
  private readonly currentField = viewChild.required(PasswordField);

  readonly returnUrl = input<string | null>(null);

  protected readonly form = inject(FormBuilder).nonNullable.group({ current: [''], password: [''], confirm: [''] });
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  private readonly submitted = signal(false);
  private readonly server = signal<{ current: string | null; password: string[] }>({ current: null, password: [] });
  private readonly value = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });

  protected readonly policy = computed(() => this.config.config().password);
  protected readonly phone = this.session.phoneNumber;

  protected readonly currentError = computed(() => {
    if (this.server().current) return this.server().current;
    return this.submitted() && !this.value().current ? 'auth.validation.required' : null;
  });
  protected readonly passwordErrors = computed(() => {
    const { password } = this.value();
    if (this.server().password.length) return this.server().password;
    const codes = passwordViolations(password ?? '', this.policy(), this.phone());
    if (this.submitted()) return codes;
    return password ? codes.filter((c) => c === 'password.too_common' || c === 'password.contains_phone' || c === 'password.too_long') : [];
  });
  protected readonly confirmError = computed(() => {
    const { password, confirm } = this.value();
    if (!confirm) return this.submitted() ? 'auth.validation.confirmPassword' : null;
    return confirm !== password ? 'auth.validation.passwordMismatch' : null;
  });

  constructor() {
    void this.config.load();
    this.form.valueChanges.subscribe(() => {
      this.error.set(null);
      this.server.set({ current: null, password: [] });
    });
  }

  protected async save(): Promise<void> {
    if (this.busy()) return;
    this.submitted.set(true);
    if (this.currentError() || this.passwordErrors().length || this.confirmError()) return;

    const { current, password } = this.form.getRawValue();
    this.busy.set(true);
    try {
      const me = await this.auth.changePassword(current, password);
      await this.router.navigateByUrl(postAuthUrl(me, this.returnUrl()));
    } catch (error) {
      if (isApiError(error) && error.code === 'auth.wrong_password') {
        this.server.set({ current: 'errors.auth.wrong_password', password: [] });
        this.currentField().focus();
        return;
      }
      const codes = fieldErrors(error, 'newPassword');
      if (codes.length) this.server.set({ current: null, password: codes });
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
