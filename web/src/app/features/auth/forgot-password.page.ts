import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { AuthService, authErrorKey } from '../../core/auth/auth.service';
import { AuthCard } from './auth-shared';

@Component({
  selector: 'rd-forgot-password-page',
  imports: [ReactiveFormsModule, RouterLink, TranslocoPipe, AuthCard, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-auth-card [title]="'auth.forgot.title' | transloco" [subtitle]="'auth.forgot.subtitle' | transloco">
      @if (sent()) {
        <div class="flex flex-col items-center gap-3 text-center" role="status">
          <span class="grid h-14 w-14 place-items-center rounded-card bg-primary-container text-on-primary-container">
            <svg lucideIcon="MailCheck" [size]="26" aria-hidden="true"></svg>
          </span>
          <p class="m-0">{{ 'auth.forgot.sent' | transloco }}</p>
          <a routerLink="/auth/sign-in" class="rd-btn rd-btn-primary mt-2 w-full">{{ 'auth.signIn.submit' | transloco }}</a>
        </div>
      } @else {
        <form [formGroup]="form" (ngSubmit)="submit()" class="flex flex-col gap-4" novalidate>
          <div>
            <label class="rd-label" for="email">{{ 'auth.email' | transloco }}</label>
            <input id="email" class="rd-input" type="email" formControlName="email" autocomplete="email" dir="ltr"
              [attr.aria-invalid]="form.controls.email.invalid && submitted()" />
            @if (form.controls.email.invalid && submitted()) {
              <p class="mt-1 text-xs text-error">{{ 'auth.validation.email' | transloco }}</p>
            }
          </div>
          @if (errorKey()) {
            <p class="m-0 rounded-md bg-callout-danger p-3 text-sm" role="alert">{{ errorKey()! | transloco }}</p>
          }
          <button type="submit" class="rd-btn rd-btn-primary w-full" [disabled]="busy()">
            {{ (busy() ? 'common.loading' : 'auth.forgot.submit') | transloco }}
          </button>
          <a routerLink="/auth/sign-in" class="text-center text-sm text-text-secondary">{{ 'common.back' | transloco }}</a>
        </form>
      }
    </rd-auth-card>
  `,
})
export class ForgotPasswordPage {
  private readonly auth = inject(AuthService);
  protected readonly form = inject(FormBuilder).nonNullable.group({ email: ['', [Validators.required, Validators.email]] });
  protected readonly busy = signal(false);
  protected readonly sent = signal(false);
  protected readonly submitted = signal(false);
  protected readonly errorKey = signal<string | null>(null);

  protected async submit(): Promise<void> {
    this.submitted.set(true);
    if (this.form.invalid) return;
    this.busy.set(true);
    this.errorKey.set(null);
    try {
      await this.auth.sendPasswordReset(this.form.getRawValue().email);
      this.sent.set(true);
    } catch (error) {
      // Don't reveal whether an account exists: unknown emails show the same success state.
      if ((error as { code?: string })?.code === 'auth/user-not-found') this.sent.set(true);
      else this.errorKey.set(authErrorKey(error));
    } finally {
      this.busy.set(false);
    }
  }
}
