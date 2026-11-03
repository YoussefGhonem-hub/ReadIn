import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { StreakDto } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { ReadingSheetsService } from '../../features/reading/reading-sheets.service';
import { translatePlural } from '../pipes/intl';

/**
 * 🔥 streak badge (F03/F08). Shows "—" until the streak is known, a quieter (dashed) look while the user hasn't read
 * today, and ❄ when reading today would use a freeze. Signed in, it opens the reading stats sheet.
 */
@Component({
  selector: 'rd-streak-badge',
  imports: [LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'inline-flex' },
  template: `
    @if (session.isAuthenticated()) {
      <button type="button" [class]="chipClass()" [attr.aria-label]="label()" [attr.title]="label()" aria-haspopup="dialog" (click)="sheets.openStats()">
        <svg lucideIcon="Flame" [size]="14" [class]="streak()?.current === 0 ? 'text-text-secondary' : 'text-accent'" aria-hidden="true"></svg>
        <span aria-hidden="true">{{ days() ?? '—' }}</span>
        @if (streak()?.freezePending) {
          <span class="text-callout-info-accent" aria-hidden="true">❄</span>
        }
      </button>
    } @else {
      <span class="inline-flex items-center gap-1 rounded-chip bg-accent-container px-3 py-1.5 text-xs font-bold text-text-primary">
        <svg lucideIcon="Flame" [size]="14" class="text-accent" aria-hidden="true"></svg>
        <span aria-hidden="true">—</span><span class="rd-visually-hidden">{{ label() }}</span>
      </span>
    }
  `,
})
export class StreakBadge {
  readonly streak = input<StreakDto | null>(null);

  protected readonly session = inject(SessionStore);
  protected readonly sheets = inject(ReadingSheetsService);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;

  protected readonly days = computed(() => {
    const streak = this.streak();
    return streak ? translatePlural(this.transloco, 'reading.days', streak.current, this.lang()) : null;
  });
  /** A streak not extended today yet looks quieter (dashed); none at all is muted. */
  protected readonly chipClass = computed(() => {
    const streak = this.streak();
    const base = 'inline-flex items-center gap-1 rounded-chip border px-3 py-1.5 text-xs font-bold';
    if (streak?.current === 0) return `${base} border-transparent bg-surface-variant text-text-secondary`;
    if (streak && !streak.readToday) return `${base} border-dashed border-accent bg-transparent text-text-primary`;
    return `${base} border-transparent bg-accent-container text-text-primary`;
  });
  protected readonly label = computed(() => {
    const streak = this.streak();
    const lang = this.lang();
    const days = this.days();
    if (!streak || !days) return this.transloco.translate('reading.badge.unknown', {}, lang);
    const parts = [this.transloco.translate('reading.badge.label', { days }, lang)];
    if (streak.current > 0 && !streak.readToday) parts.push(this.transloco.translate('reading.badge.notReadToday', {}, lang));
    if (streak.freezePending) parts.push(this.transloco.translate('reading.badge.freezePending', {}, lang));
    return parts.join('. ');
  });
}
