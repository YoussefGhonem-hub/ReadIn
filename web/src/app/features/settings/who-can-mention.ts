import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { MentionPolicy } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { PrivacyService } from '../profile/privacy.service';

const POLICIES: readonly MentionPolicy[] = ['everyone', 'following', 'nobody'];

/**
 * Settings → Privacy: "Who can mention me" (F18): everyone, the people you follow, or nobody, in comments and articles.
 * Saved at once and put back, with the reason, when the API refuses it (PrivacyService).
 */
@Component({
  selector: 'rd-who-can-mention',
  imports: [TranslocoPipe, Segmented],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'flex flex-wrap items-center gap-x-4 gap-y-2',
    'data-who-can-mention': '',
    '[attr.data-value]': 'privacy.whoCanMention()',
    '[attr.aria-busy]': 'privacy.saving() || null',
  },
  template: `
    <div class="min-w-48 flex-1">
      <div class="text-sm font-semibold">{{ 'settings.privacy.whoCanMention.label' | transloco }}</div>
      <div id="who-can-mention-hint" class="mt-1 text-xs text-text-secondary">{{ 'settings.privacy.whoCanMention.hint' | transloco }}</div>
    </div>
    <rd-segmented
      class="w-full sm:w-80"
      [options]="options()"
      [value]="privacy.whoCanMention()"
      (valueChange)="privacy.setWhoCanMention($event)"
      [disabled]="privacy.saving()"
      [label]="'settings.privacy.whoCanMention.label' | transloco"
      aria-describedby="who-can-mention-hint"
    />
  `,
})
export class WhoCanMention {
  protected readonly privacy = inject(PrivacyService);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;

  protected readonly options = computed<SegmentOption<MentionPolicy>[]>(() => {
    this.lang();
    return POLICIES.map((value) => ({ value, label: this.transloco.translate(`settings.privacy.whoCanMention.options.${value}`) }));
  });
}
