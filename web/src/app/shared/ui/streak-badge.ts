import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';

/** 🔥 streak badge (F03/F08). Shows "—" until streak stats ship in Phase 2. */
@Component({
  selector: 'rd-streak-badge',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'inline-flex items-center gap-1 rounded-chip bg-accent-container px-3 py-1.5 text-xs font-bold text-text-primary',
  },
  template: `
    <svg lucideIcon="Flame" [size]="14" class="text-accent" aria-hidden="true"></svg>
    @if (days() !== null) {
      {{ 'topbar.streakDays' | transloco: { count: days() } }}
    } @else {
      <span aria-hidden="true">—</span><span class="rd-visually-hidden">{{ 'topbar.streakLabel' | transloco }}</span>
    }
  `,
})
export class StreakBadge {
  readonly days = input<number | null>(null);
}
