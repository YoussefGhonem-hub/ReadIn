import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { FieldDto, TopicDto, UiLanguage } from '../../core/api/models';
import { BdiText } from '../../shared/directives/bdi-text';
import { FieldIcon } from '../../shared/ui/field-icon';

/** Key of a chip in `busy`: `field:{id}` or `topic:{id}`. */
export const interestKey = (kind: 'field' | 'topic', id: string): string => `${kind}:${id}`;

/**
 * The interest chips of onboarding (F02) and Settings → Your interests (F12): one per field, then the topics of every
 * field you follow (or follow a topic of, so a followed topic never hides). The host owns the state and toggles it;
 * chips in `busy` are being saved (`aria-busy`; they stay focusable).
 */
@Component({
  selector: 'rd-interest-chips',
  imports: [TranslocoPipe, LucideDynamicIcon, BdiText, FieldIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <div class="mt-5 grid grid-cols-2 gap-2 sm:grid-cols-3">
      @for (field of fields(); track field.id) {
        <button
          type="button"
          class="flex min-h-12 items-center gap-2 rounded-md border px-3 text-start text-sm transition-colors"
          [class]="fieldIds().has(field.id) ? 'border-primary bg-primary-container font-semibold text-on-primary-container' : 'border-border bg-surface'"
          [attr.aria-pressed]="fieldIds().has(field.id)"
          [attr.aria-busy]="busy().has(fieldKey(field)) ? true : null"
          [attr.data-interest-field]="field.id"
          (click)="fieldToggle.emit(field)"
        >
          <rd-field-icon [name]="field.icon" class="text-primary" />
          <span class="min-w-0 flex-1 truncate"><rd-bdi-text [text]="fieldName(field)" /></span>
          @if (fieldIds().has(field.id)) {
            <svg lucideIcon="Check" [size]="16" aria-hidden="true"></svg>
          }
        </button>
      }
    </div>

    @for (field of topicFields(); track field.id) {
      @if (topics()[field.slug]?.length) {
        <div class="mt-5">
          <h2 class="mb-2 text-sm font-semibold">{{ 'onboarding.interests.topicsOf' | transloco: { field: fieldName(field) } }}</h2>
          <div class="flex flex-wrap gap-2">
            @for (topic of topics()[field.slug]; track topic.id) {
              <button
                type="button"
                class="rd-chip"
                [attr.aria-pressed]="topicIds().has(topic.id)"
                [attr.aria-busy]="busy().has(topicKey(topic)) ? true : null"
                [attr.data-interest-topic]="topic.id"
                (click)="topicToggle.emit(topic)"
              >
                <rd-bdi-text [text]="lang() === 'ar' ? topic.nameAr : topic.nameEn" />
              </button>
            }
          </div>
        </div>
      }
    }
  `,
})
export class InterestChips {
  readonly fields = input.required<readonly FieldDto[]>();
  /** Topics by field slug, as far as they are loaded. */
  readonly topics = input.required<Readonly<Record<string, readonly TopicDto[]>>>();
  readonly fieldIds = input.required<ReadonlySet<string>>();
  readonly topicIds = input.required<ReadonlySet<string>>();
  readonly lang = input.required<UiLanguage>();
  /** Chips being saved, by {@link interestKey}. */
  readonly busy = input<ReadonlySet<string>>(new Set());

  readonly fieldToggle = output<FieldDto>();
  readonly topicToggle = output<TopicDto>();

  /** The fields whose topics are listed: the ones you follow, and the ones you follow a topic of. */
  protected readonly topicFields = computed(() =>
    this.fields().filter((f) => this.fieldIds().has(f.id) || (this.topics()[f.slug] ?? []).some((t) => this.topicIds().has(t.id))),
  );

  protected fieldName(field: FieldDto): string {
    return this.lang() === 'ar' ? field.nameAr : field.nameEn;
  }

  protected fieldKey(field: FieldDto): string {
    return interestKey('field', field.id);
  }

  protected topicKey(topic: TopicDto): string {
    return interestKey('topic', topic.id);
  }
}
