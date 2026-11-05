import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { ArticleDraftDocument, FieldDto, TopicDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { Switch } from '../../shared/ui/switch';
import { CategoryPicker } from './category-picker';
import { CoverPicker } from './cover-picker';
import { SourcesEditor } from './sources-editor';
import { TagError, TagInput } from './tag-input';

export const VERSION_BADGE_MAX = 30;

export type DocumentPatch = Partial<Omit<ArticleDraftDocument, 'translations' | 'sourceLanguage'>>;

/**
 * Article settings (F05): field (required to publish), topic, your category (F31: applied at once, not part of the
 * draft), tags, cover, sources, version badge, AI label. A stack of cards: the details (field, topic, category, tags),
 * the cover, the sources, then what readers see next to the title (version badge, AI label).
 */
@Component({
  selector: 'rd-metadata-panel',
  imports: [TranslocoPipe, Switch, CategoryPicker, CoverPicker, SourcesEditor, TagInput],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col gap-2' },
  template: `
    <section class="rd-card flex flex-col gap-4 p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-labelledby="ed-details-title" data-details-card>
      <h2 id="ed-details-title" class="m-0 text-sm font-semibold">{{ 'editor.meta.title' | transloco }}</h2>
      <div>
        <label class="rd-label" for="ed-field">{{ 'editor.meta.field' | transloco }} *</label>
        <select id="ed-field" class="rd-input" data-field [value]="document().fieldId ?? ''" (change)="selectField(valueOf($event))">
          <option value="" [selected]="!document().fieldId">{{ 'editor.meta.fieldPlaceholder' | transloco }}</option>
          @for (field of fields(); track field.id) {
            <option [value]="field.id" [selected]="field.id === document().fieldId">{{ lang() === 'ar' ? field.nameAr : field.nameEn }}</option>
          }
        </select>
        @if (fieldsFailed()) {
          <p class="m-0 mt-1 text-xs text-error" role="alert">
            {{ 'editor.fieldsError' | transloco }}
            <button type="button" class="font-semibold underline" (click)="retryFields.emit()">{{ 'common.retry' | transloco }}</button>
          </p>
        }
      </div>
      <div>
        <label class="rd-label" for="ed-topic">{{ 'editor.meta.topic' | transloco }}</label>
        <select id="ed-topic" class="rd-input" data-topic [disabled]="!topics().length" (change)="patch.emit({ topicId: valueOf($event) || null })">
          <option value="" [selected]="!document().topicId">{{ 'editor.meta.topicNone' | transloco }}</option>
          @for (topic of topics(); track topic.id) {
            <option [value]="topic.id" [selected]="topic.id === document().topicId">{{ lang() === 'ar' ? topic.nameAr : topic.nameEn }}</option>
          }
        </select>
      </div>
      <rd-category-picker [value]="categoryId()" [busy]="categorySaving()" [error]="categoryError()" (changed)="categoryChange.emit($event)" />
      <rd-tag-input id="ed-tags" [tags]="document().tags" [flagged]="tagFlags()" [errors]="tagErrors()" (tagsChange)="patch.emit({ tags: $event })" />
    </section>

    <div class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" data-cover-card>
      <rd-cover-picker [url]="document().coverUrl" (urlChange)="patch.emit({ coverUrl: $event })" (uploadingChange)="coverUploading.emit($event)" />
    </div>

    <div id="ed-sources" class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" tabindex="-1">
      <rd-sources-editor [sources]="document().sources" [required]="sourcesRequired()" (sourcesChange)="patch.emit({ sources: $event })" />
    </div>

    <div class="rd-card flex flex-col gap-4 p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" data-labels-card>
      <div>
        <label class="rd-label" for="ed-version">{{ 'editor.meta.versionBadge' | transloco }}</label>
        <input
          id="ed-version"
          class="rd-input"
          dir="ltr"
          [maxLength]="versionMax"
          [value]="document().versionBadge ?? ''"
          [placeholder]="'editor.meta.versionBadgePlaceholder' | transloco"
          data-version-badge
          (input)="patch.emit({ versionBadge: valueOf($event).trim() ? valueOf($event) : null })"
        />
        <p class="rd-field-hint">{{ 'editor.meta.versionBadgeHint' | transloco }}</p>
      </div>
      <rd-switch
        [checked]="document().isAiAssisted"
        [label]="'editor.aiAssisted' | transloco"
        [hint]="'editor.aiAssistedHint' | transloco"
        data-ai-assisted
        (changed)="patch.emit({ isAiAssisted: $event })"
      />
    </div>
  `,
})
export class MetadataPanel {
  protected readonly lang = inject(LanguageService).lang;

  readonly document = input.required<ArticleDraftDocument>();
  readonly fields = input<FieldDto[]>([]);
  readonly topics = input<TopicDto[]>([]);
  readonly fieldsFailed = input(false);
  /** Tags with a problem in the last checks or save (F32): their chips are marked. */
  readonly tagFlags = input<readonly string[]>([]);
  /** Why the last save was refused because of the tags. */
  readonly tagErrors = input<readonly TagError[]>([]);
  /** The writer's category (F31) and its change on the way, kept outside the document. */
  readonly categoryId = input<string | null>(null);
  readonly categorySaving = input(false);
  readonly categoryError = input<string | null>(null);
  readonly patch = output<DocumentPatch>();
  readonly categoryChange = output<string | null>();
  readonly retryFields = output<void>();
  readonly coverUploading = output<boolean>();

  protected readonly versionMax = VERSION_BADGE_MAX;
  protected readonly sourcesRequired = computed(() => !!this.fields().find((f) => f.id === this.document().fieldId)?.requiresSources);

  protected selectField(id: string): void {
    // A topic belongs to its field.
    this.patch.emit({ fieldId: id || null, topicId: null });
  }

  protected valueOf(event: Event): string {
    return (event.target as HTMLInputElement | HTMLSelectElement).value;
  }
}
