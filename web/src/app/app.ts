import { ChangeDetectionStrategy, Component, Type, ViewContainerRef, effect, inject, signal, untracked, viewChild } from '@angular/core';
import { NgComponentOutlet } from '@angular/common';
import { RouterOutlet } from '@angular/router';
import { ModerationNotices } from './core/moderation/moderation-notices';
import { ThemeService } from './core/theme/theme.service';
import { TermSheetService } from './shared/rdoc/rdoc-context';
import { SignInPrompt } from './shared/ui/sign-in-prompt';
import { ToastHost } from './shared/ui/toast/toast-host';
import { TooltipHost } from './shared/ui/tooltip/tooltip-host';

@Component({
  selector: 'rd-root',
  imports: [RouterOutlet, ToastHost, TooltipHost, SignInPrompt, NgComponentOutlet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <router-outlet />
    <rd-toast-host />
    <!-- Every title on the site shows as this tooltip instead of the browser's -->
    <rd-tooltip-host />
    <rd-sign-in-prompt />
    @if (termSheet(); as sheet) {
      <ng-container *ngComponentOutlet="sheet" />
    }
    <!-- Moderation notices (F22): their dialog's code loads only when there are some -->
    <ng-container #notices />
  `,
})
export class App {
  /** The glossary sheet (F21): its own chunk, loaded on the first tapped term (a `@defer` block would add its runtime to the initial bundle). */
  protected readonly termSheet = signal<Type<unknown> | null>(null);
  private readonly noticeHost = viewChild.required('notices', { read: ViewContainerRef });

  constructor() {
    // Resolve the theme from the cookie up front so SSR renders <html data-theme>.
    inject(ThemeService);

    const terms = inject(TermSheetService);
    let loading = false;
    effect(() => {
      if (!terms.openTerm() || loading) return;
      loading = true;
      import('./shared/rdoc/term-sheet').then(
        ({ TermSheet }) => this.termSheet.set(TermSheet),
        () => (loading = false), // offline: the next tap tries again
      );
    });

    // The notice dialog is created once its lazy chunk has loaded (ModerationNotices loads it only when there are some).
    const notices = inject(ModerationNotices);
    effect(() => {
      const dialog = notices.dialog();
      const host = this.noticeHost();
      untracked(() => {
        if (dialog && host.length === 0) host.createComponent(dialog);
      });
    });
  }
}
