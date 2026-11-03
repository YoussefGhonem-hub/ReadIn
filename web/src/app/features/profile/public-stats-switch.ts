import { ChangeDetectionStrategy, Component, inject, input } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { Switch } from '../../shared/ui/switch';
import { PrivacyService } from './privacy.service';

/** "Show on my public profile" for your reading stats (F14, F18): on your own profile and in Settings → Privacy. */
@Component({
  selector: 'rd-public-stats-switch',
  imports: [TranslocoPipe, Switch],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-public-stats': '' },
  template: `
    <rd-switch
      [checked]="privacy.publicReadingStats()"
      [label]="labelKey() | transloco"
      [hint]="hintKey() | transloco"
      [disabled]="privacy.saving()"
      [busy]="privacy.saving()"
      (changed)="privacy.setPublicReadingStats($event)"
    />
  `,
})
export class PublicStatsSwitch {
  protected readonly privacy = inject(PrivacyService);
  /** The profile says "Show on my public profile"; Settings spells out what is shown. */
  readonly labelKey = input('profile.readingStats.publicSwitch');
  readonly hintKey = input('profile.readingStats.publicHint');
}
