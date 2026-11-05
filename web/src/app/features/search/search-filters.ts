import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { catchError, of } from 'rxjs';
import { ArticleLanguage } from '../../core/api/models';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { LanguageService } from '../../core/i18n/language.service';
import { ARTICLE_LANGUAGES, READING_TIMES, ReadingTime, SearchRequest } from './search-query';

export type SearchFilterPatch = Partial<Pick<SearchRequest, 'field' | 'lang' | 'time'>>;

interface FilterOption {
  value: string;
  label: string;
}

/** A filter as a chip that is a native select: the chosen value shows on it, and it fills in while a value is set. */
@Component({
  selector: 'rd-search-filter',
  imports: [LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'relative inline-flex shrink-0' },
  template: `
    <label class="contents">
      <span class="sr-only">{{ label() }}</span>
      <select class="rd-chip appearance-none pe-8" [class.is-active]="!!value()" [attr.data-filter]="name()" (change)="onChange($event)">
        <option value="" class="bg-surface text-text-primary">{{ anyLabel() }}</option>
        @for (option of options(); track option.value) {
          <option class="bg-surface text-text-primary" [value]="option.value" [selected]="option.value === value()">{{ option.label }}</option>
        }
      </select>
    </label>
    <svg
      lucideIcon="ChevronDown"
      [size]="14"
      class="pointer-events-none absolute end-3 top-1/2 -translate-y-1/2"
      [class]="value() ? 'text-on-primary' : 'text-text-secondary'"
      aria-hidden="true"
    ></svg>
  `,
})
export class SearchFilter {
  readonly name = input.required<string>();
  readonly label = input.required<string>();
  readonly anyLabel = input.required<string>();
  readonly options = input.required<readonly FilterOption[]>();
  /** '' for "any". */
  readonly value = input('');
  readonly valueChange = output<string | null>();

  protected onChange(event: Event): void {
    this.valueChange.emit((event.target as HTMLSelectElement).value || null);
  }
}

/**
 * The Articles tab's filters (F16): field, article language and reading time (`≤ 5`, `5–10`, `> 10` minutes), plus
 * "Clear filters" while any is set. The fields come from `GET /fields`; a field slug that isn't one of them (an old
 * link) still shows as chosen. Not hydrated: the browser renders it again once the fields are in, so the server's
 * copy can't mismatch. A row of the search page's header card, padded like the card.
 */
@Component({
  selector: 'rd-search-filters',
  imports: [TranslocoPipe, LucideDynamicIcon, SearchFilter],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    ngSkipHydration: 'true',
    class: 'flex gap-2 overflow-x-auto px-4 py-3 lg:px-5',
    role: 'group',
    '[attr.aria-label]': 'label()',
    'data-search-filters': '',
  },
  template: `
    <rd-search-filter
      name="field"
      [label]="'search.filters.field' | transloco"
      [anyLabel]="'search.filters.anyField' | transloco"
      [options]="fieldOptions()"
      [value]="request().field ?? ''"
      (valueChange)="changed.emit({ field: $event })"
    />
    <rd-search-filter
      name="lang"
      [label]="'search.filters.language' | transloco"
      [anyLabel]="'search.filters.anyLanguage' | transloco"
      [options]="languageOptions()"
      [value]="request().lang ?? ''"
      (valueChange)="changed.emit({ lang: $any($event) })"
    />
    <rd-search-filter
      name="time"
      [label]="'search.filters.time' | transloco"
      [anyLabel]="'search.filters.anyTime' | transloco"
      [options]="timeOptions()"
      [value]="request().time ?? ''"
      (valueChange)="changed.emit({ time: $any($event) })"
    />
    @if (request().field || request().lang || request().time) {
      <button type="button" class="rd-chip" data-clear-filters (click)="changed.emit({ field: null, lang: null, time: null })">
        <svg lucideIcon="X" [size]="14" aria-hidden="true"></svg>
        {{ 'search.filters.clear' | transloco }}
      </button>
    }
  `,
})
export class SearchFilterBar {
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;
  private readonly fields = toSignal(
    inject(TaxonomyApi)
      .fields()
      .pipe(catchError(() => of([]))),
    { initialValue: [] },
  );

  readonly request = input.required<SearchRequest>();
  readonly changed = output<SearchFilterPatch>();

  protected readonly label = computed(() => {
    this.lang();
    return this.transloco.translate('search.filters.label');
  });

  protected readonly fieldOptions = computed<FilterOption[]>(() => {
    const ar = this.lang() === 'ar';
    const options = this.fields().map((f) => ({ value: f.slug, label: ar ? f.nameAr : f.nameEn }));
    const chosen = this.request().field;
    return chosen && !options.some((o) => o.value === chosen) ? [...options, { value: chosen, label: chosen }] : options;
  });
  protected readonly languageOptions = computed<FilterOption[]>(() => {
    this.lang();
    const label: Record<ArticleLanguage, string> = { 'ar-EG': 'search.filters.arabic', en: 'search.filters.english' };
    return ARTICLE_LANGUAGES.map((value) => ({ value, label: this.transloco.translate(label[value]) }));
  });
  protected readonly timeOptions = computed<FilterOption[]>(() => {
    this.lang();
    return READING_TIMES.map((value: ReadingTime) => ({ value, label: this.transloco.translate(`search.filters.${value}`) }));
  });
}
