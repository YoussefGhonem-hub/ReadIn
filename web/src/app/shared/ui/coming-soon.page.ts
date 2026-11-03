import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';

/**
 * Placeholder for features scheduled in later phases (SPEC §12). Route data provides `titleKey` and `phase`.
 * Bound via `withComponentInputBinding()`.
 */
@Component({
  selector: 'rd-coming-soon-page',
  imports: [TranslocoPipe, RouterLink, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col items-center gap-3 px-6 py-20 text-center' },
  template: `
    <span class="grid h-16 w-16 place-items-center rounded-card bg-accent-container text-text-primary" aria-hidden="true">
      <svg lucideIcon="Sparkles" [size]="28"></svg>
    </span>
    <h1 class="m-0 text-2xl font-semibold">{{ titleKey() | transloco }}</h1>
    <p class="m-0 max-w-md text-text-secondary">{{ 'comingSoon.body' | transloco }}</p>
    @if (username()) {
      <p class="m-0 text-sm text-text-secondary" dir="ltr">&#64;{{ username() }}</p>
    }
    @if (phase()) {
      <span class="rd-tag rd-tag-accent">{{ 'comingSoon.phase' | transloco: { phase: phase() } }}</span>
    }
    <a routerLink="/" class="rd-btn rd-btn-outline mt-4">{{ 'comingSoon.backHome' | transloco }}</a>
  `,
})
export class ComingSoonPage {
  readonly titleKey = input('comingSoon.title');
  readonly phase = input<number | null>(null);
  /** Present on the profile route (`/@username`). */
  readonly username = input<string | null>(null);
}
