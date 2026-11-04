import { ChangeDetectionStrategy, Component, ViewContainerRef, effect, inject, untracked, viewChild } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ModerationNotices } from './core/moderation/moderation-notices';
import { ThemeService } from './core/theme/theme.service';
import { TermSheet } from './shared/rdoc/term-sheet';
import { SignInPrompt } from './shared/ui/sign-in-prompt';
import { ToastHost } from './shared/ui/toast/toast-host';

@Component({
  selector: 'rd-root',
  imports: [RouterOutlet, ToastHost, SignInPrompt, TermSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <router-outlet />
    <rd-toast-host />
    <rd-sign-in-prompt />
    <rd-term-sheet />
    <!-- Moderation notices (F22): their dialog's code loads only when there are some -->
    <ng-container #notices />
  `,
})
export class App {
  private readonly noticeHost = viewChild.required('notices', { read: ViewContainerRef });

  constructor() {
    // Resolve the theme from the cookie up front so SSR renders <html data-theme>.
    inject(ThemeService);

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
