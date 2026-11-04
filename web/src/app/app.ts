import { ChangeDetectionStrategy, Component, Type, effect, inject, signal } from '@angular/core';
import { NgComponentOutlet } from '@angular/common';
import { RouterOutlet } from '@angular/router';
import { ThemeService } from './core/theme/theme.service';
import { TermSheetService } from './shared/rdoc/rdoc-context';
import { SignInPrompt } from './shared/ui/sign-in-prompt';
import { ToastHost } from './shared/ui/toast/toast-host';

@Component({
  selector: 'rd-root',
  imports: [RouterOutlet, ToastHost, SignInPrompt, NgComponentOutlet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <router-outlet />
    <rd-toast-host />
    <rd-sign-in-prompt />
    @if (termSheet(); as sheet) {
      <ng-container *ngComponentOutlet="sheet" />
    }
  `,
})
export class App {
  /** The glossary sheet (F21): its own chunk, loaded on the first tapped term (a `@defer` block would add its runtime to the initial bundle). */
  protected readonly termSheet = signal<Type<unknown> | null>(null);

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
  }
}
