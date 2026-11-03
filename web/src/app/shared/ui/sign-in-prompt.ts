import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { BottomSheet } from './bottom-sheet';
import { Wordmark } from './wordmark';

/** Soft sign-in prompt shown when a guest tries to interact (F01). */
@Component({
  selector: 'rd-sign-in-prompt',
  imports: [BottomSheet, Wordmark, TranslocoPipe, RouterLink],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="prompt.isOpen()" [label]="'auth.prompt.title' | transloco" (closed)="prompt.close()">
      <div class="flex flex-col items-center gap-3 pt-2 text-center">
        <rd-wordmark [size]="26" />
        <h2 class="m-0 text-xl font-semibold">{{ 'auth.prompt.title' | transloco }}</h2>
        <p class="m-0 max-w-sm text-sm text-text-secondary">{{ 'auth.prompt.body' | transloco }}</p>
        <div class="mt-2 flex w-full flex-col gap-2">
          <a class="rd-btn rd-btn-primary" routerLink="/auth/sign-in" [queryParams]="{ returnUrl: returnUrl() }" (click)="prompt.close()">
            {{ 'auth.prompt.signIn' | transloco }}
          </a>
          <a class="rd-btn rd-btn-outline" routerLink="/auth/sign-up" [queryParams]="{ returnUrl: returnUrl() }" (click)="prompt.close()">
            {{ 'auth.prompt.signUp' | transloco }}
          </a>
          <button type="button" class="rd-btn rd-btn-ghost" (click)="prompt.close()">{{ 'auth.prompt.later' | transloco }}</button>
        </div>
      </div>
    </rd-bottom-sheet>
  `,
})
export class SignInPrompt {
  protected readonly prompt = inject(AuthPromptService);
  private readonly router = inject(Router);

  protected returnUrl(): string {
    return this.router.url;
  }
}
