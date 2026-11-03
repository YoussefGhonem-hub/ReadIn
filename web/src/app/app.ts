import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
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
  `,
})
export class App {
  constructor() {
    // Resolve the theme from the cookie up front so SSR renders <html data-theme>.
    inject(ThemeService);
  }
}
