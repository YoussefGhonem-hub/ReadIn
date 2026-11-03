import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { AuthService, authErrorKey } from '../../core/auth/auth.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { AuthCard, postSignInUrl, safeReturnUrl } from './auth-shared';
import { GoogleIcon } from './google-icon';

@Component({
  selector: 'rd-sign-in-page',
  imports: [ReactiveFormsModule, RouterLink, TranslocoPipe, AuthCard, GoogleIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-auth-card [title]="'auth.signIn.title' | transloco" [subtitle]="'auth.signIn.subtitle' | transloco">
      <button type="button" class="rd-btn rd-btn-outline w-full text-text-primary" [disabled]="busy()" (click)="google()">
        <rd-google-icon /> {{ 'auth.google' | transloco }}
      </button>
      <div class="my-5 flex items-center gap-3 text-xs text-text-secondary" aria-hidden="true">
        <span class="h-px flex-1 bg-border"></span>{{ 'common.or' | transloco }}<span class="h-px flex-1 bg-border"></span>
      </div>
      <form [formGroup]="form" (ngSubmit)="submit()" class="flex flex-col gap-4" novalidate>
        <div>
          <label class="rd-label" for="email">{{ 'auth.email' | transloco }}</label>
          <input id="email" class="rd-input" type="email" formControlName="email" autocomplete="email" dir="ltr" inputmode="email"
            [attr.aria-invalid]="invalid('email')" />
          @if (invalid('email')) {
            <p class="mt-1 text-xs text-error">{{ 'auth.validation.email' | transloco }}</p>
          }
        </div>
        <div>
          <div class="flex items-center justify-between">
            <label class="rd-label" for="password">{{ 'auth.password' | transloco }}</label>
            <a routerLink="/auth/forgot-password" class="mb-2 text-xs text-primary">{{ 'auth.signIn.forgot' | transloco }}</a>
          </div>
          <input id="password" class="rd-input" type="password" formControlName="password" autocomplete="current-password" dir="ltr"
            [attr.aria-invalid]="invalid('password')" />
          @if (invalid('password')) {
            <p class="mt-1 text-xs text-error">{{ 'auth.validation.required' | transloco }}</p>
          }
        </div>
        @if (errorKey()) {
          <p class="m-0 rounded-md bg-callout-danger p-3 text-sm" role="alert">{{ errorKey()! | transloco }}</p>
        }
        <button type="submit" class="rd-btn rd-btn-primary w-full" [disabled]="busy()">
          {{ (busy() ? 'common.loading' : 'auth.signIn.submit') | transloco }}
        </button>
      </form>
      <p class="mt-6 text-center text-sm text-text-secondary">
        {{ 'auth.signIn.noAccount' | transloco }}
        <a routerLink="/auth/sign-up" [queryParams]="{ returnUrl: returnUrl() }" class="font-semibold text-primary">{{ 'auth.signIn.createAccount' | transloco }}</a>
      </p>
      <p class="mt-2 text-center text-sm">
        <a [routerLink]="safeReturn()" class="text-text-secondary">{{ 'auth.continueAsGuest' | transloco }}</a>
      </p>
    </rd-auth-card>
  `,
})
export class SignInPage {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);

  readonly returnUrl = input<string | null>(null);

  protected readonly form = inject(FormBuilder).nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', Validators.required],
  });
  protected readonly busy = signal(false);
  protected readonly errorKey = signal<string | null>(null);
  private readonly submitted = signal(false);

  protected invalid(name: 'email' | 'password'): boolean {
    const control = this.form.controls[name];
    return control.invalid && (control.touched || this.submitted());
  }

  protected safeReturn(): string {
    return safeReturnUrl(this.returnUrl());
  }

  protected async submit(): Promise<void> {
    this.submitted.set(true);
    if (this.form.invalid) return;
    const { email, password } = this.form.getRawValue();
    await this.run(() => this.auth.signInWithEmail(email, password));
  }

  protected google(): Promise<void> {
    return this.run(() => this.auth.signInWithGoogle());
  }

  private async run(action: () => ReturnType<AuthService['signInWithEmail']>): Promise<void> {
    this.busy.set(true);
    this.errorKey.set(null);
    try {
      const me = await action();
      if (!me) this.toasts.error(this.transloco.translate('errors.syncFailed'));
      await this.router.navigateByUrl(postSignInUrl(me, this.returnUrl()));
    } catch (error) {
      this.errorKey.set(authErrorKey(error));
    } finally {
      this.busy.set(false);
    }
  }
}
