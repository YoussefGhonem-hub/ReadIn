import { ChangeDetectionStrategy, Component, Injector, Type, WritableSignal, afterNextRender, effect, inject, signal } from '@angular/core';
import { NgComponentOutlet } from '@angular/common';
import { RouterOutlet } from '@angular/router';
import { AuthPromptService } from './core/auth/auth-prompt.service';
import { ThemeService } from './core/theme/theme.service';
import { TermSheetService } from './shared/rdoc/term-sheet.service';
import { appIconsReady } from './shared/ui/app-icons';

@Component({
  selector: 'rd-root',
  imports: [RouterOutlet, NgComponentOutlet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <router-outlet />
    <!-- Each a chunk of its own, created in the browser: the toast host and the site's tooltip (every title shows as it
         instead of the browser's) right after the first render, the sign-in prompt when it first opens. -->
    @if (toastHost(); as host) {
      <ng-container *ngComponentOutlet="host" />
    }
    @if (tooltipHost(); as host) {
      <ng-container *ngComponentOutlet="host" />
    }
    @if (signInPrompt(); as prompt) {
      <ng-container *ngComponentOutlet="prompt" />
    }
    @if (termSheet(); as sheet) {
      <ng-container *ngComponentOutlet="sheet" />
    }
    <!-- Moderation notices (F22): their dialog's code loads only when there are some -->
    @if (noticeDialog(); as dialog) {
      <ng-container *ngComponentOutlet="dialog" />
    }
  `,
})
export class App {
  protected readonly toastHost = signal<Type<unknown> | null>(null);
  protected readonly tooltipHost = signal<Type<unknown> | null>(null);
  protected readonly signInPrompt = signal<Type<unknown> | null>(null);
  /** The glossary sheet (F21): its own chunk, loaded on the first tapped term (a `@defer` block would add its runtime to the initial bundle). */
  protected readonly termSheet = signal<Type<unknown> | null>(null);
  /** The moderation notice dialog, once ModerationNotices has loaded its chunk (only when there are notices). */
  protected readonly noticeDialog = signal<Type<unknown> | null>(null);

  constructor() {
    // Resolve the theme from the cookie up front so SSR renders <html data-theme>.
    inject(ThemeService);

    afterNextRender(() => {
      show(this.toastHost, () => import('./shared/ui/toast/toast-host').then((m) => m.ToastHost));
      show(this.tooltipHost, () => import('./shared/ui/tooltip/tooltip-host').then((m) => m.TooltipHost));
    });

    // The soft sign-in prompt (F01) loads the first time a guest tries to interact; it shows once it is there.
    const prompt = inject(AuthPromptService);
    let promptLoading = false;
    effect(() => {
      if (!prompt.isOpen() || promptLoading) return;
      promptLoading = true;
      show(this.signInPrompt, () => import('./shared/ui/sign-in-prompt').then((m) => m.SignInPrompt), () => (promptLoading = false));
    });

    const terms = inject(TermSheetService);
    let loading = false;
    effect(() => {
      if (!terms.openTerm() || loading) return;
      loading = true;
      show(this.termSheet, () => import('./shared/rdoc/term-sheet').then((m) => m.TermSheet), () => (loading = false)); // offline: the next tap tries again
    });

    // Moderation notices (F22) are a signed-in member's, in the browser: ModerationNotices comes in a chunk of its own
    // after the first render and loads the dialog's chunk only when there are some; it is shown once (one dialog for all).
    const injector = inject(Injector);
    afterNextRender(() => {
      import('./core/moderation/moderation-notices').then(
        ({ ModerationNotices }) => {
          const notices = injector.get(ModerationNotices);
          effect(
            () => {
              const dialog = notices.dialog();
              if (dialog && !this.noticeDialog()) this.noticeDialog.set(dialog);
            },
            { injector },
          );
        },
        () => undefined, // offline: the notices wait for the next page load
      );
    });
  }
}

/** Shows a lazily loaded component in its slot once its chunk and the app's icons are there. */
function show(slot: WritableSignal<Type<unknown> | null>, load: () => Promise<Type<unknown>>, failed?: () => void): void {
  Promise.all([load(), appIconsReady()]).then(
    ([component]) => slot.set(component),
    () => failed?.(), // offline: the toasts wait for the next page load; the prompt and the sheet try again when reopened
  );
}
