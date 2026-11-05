import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleLanguage, DraftChecksDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { PluralPipe, ReadingTimePipe } from '../../shared/pipes/format.pipes';
import { CheckTarget, checkItems, readingTimeOf } from './checks';

/**
 * Live checks (F05): the problems of the last save (`checks.problems`) in the UI language, each a button that jumps
 * to the field or block to fix, plus the reading time of every language version (`checks.readingTime`).
 */
@Component({
  selector: 'rd-checks-panel',
  imports: [TranslocoPipe, LucideDynamicIcon, ReadingTimePipe, PluralPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <section class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-labelledby="rd-checks-title" data-checks>
      <h2 id="rd-checks-title" class="m-0 mb-2 text-sm font-semibold">{{ 'editor.checks.title' | transloco }}</h2>
      <div aria-live="polite">
        @if (!checks()) {
          <p class="m-0 text-sm text-text-secondary" data-checks-pending>{{ 'editor.checks.pending' | transloco }}</p>
        } @else if (items().length || uploading()) {
          <ul class="m-0 flex list-none flex-col gap-1 p-0" data-problems>
            @if (uploading()) {
              <li class="flex items-start gap-2 px-1 py-1.5 text-sm" data-problem="uploading">
                <svg lucideIcon="LoaderCircle" [size]="16" class="mt-0.5 shrink-0 animate-spin text-primary" aria-hidden="true"></svg>
                {{ 'editor.problems.uploading' | transloco }}
              </li>
            }
            @for (item of items(); track $index) {
              <li>
                <button
                  type="button"
                  class="flex w-full items-start gap-2 rounded-sm px-1 py-1.5 text-start text-sm hover:bg-surface-variant"
                  [attr.data-problem]="item.code"
                  (click)="jump.emit(item.target)"
                >
                  <svg lucideIcon="CircleAlert" [size]="16" class="mt-0.5 shrink-0 text-error" aria-hidden="true"></svg>
                  <span class="min-w-0 flex-1">
                    {{ item.messageKey | transloco }}
                    @if (item.tag) {
                      <span class="rd-tag rd-tag-neutral ms-1" dir="auto" data-problem-tag>#{{ item.tag }}</span>
                    }
                    @if (item.language && multilingual()) {
                      <span class="rd-tag rd-tag-neutral ms-1">{{ 'editor.language.short.' + languageKey(item.language) | transloco }}</span>
                    }
                  </span>
                  <svg lucideIcon="ChevronLeft" [size]="16" class="mt-0.5 shrink-0 text-text-secondary ltr:rotate-180" aria-hidden="true"></svg>
                </button>
              </li>
            }
          </ul>
        } @else {
          <p class="m-0 flex items-center gap-2 text-sm font-semibold text-success" data-checks-ready>
            <svg lucideIcon="CircleCheck" [size]="16" aria-hidden="true"></svg>
            {{ 'editor.checks.ready' | transloco }}
          </p>
        }
      </div>
      @if (readingTimes().length) {
        <ul class="m-0 mt-3 flex list-none flex-col gap-1 border-t border-border p-0 pt-3 text-xs text-text-secondary" data-reading-time>
          @for (entry of readingTimes(); track entry.language) {
            <li>
              @if (multilingual()) {
                <span class="font-semibold">{{ 'editor.language.short.' + languageKey(entry.language) | transloco }}:</span>
              }
              {{ entry.minutes | rdReadingTime: lang() }} · {{ entry.words | rdPlural: 'editor.checks.words' : lang() }}
            </li>
          }
        </ul>
      }
    </section>
  `,
})
export class ChecksPanel {
  protected readonly lang = inject(LanguageService).lang;

  readonly checks = input<DraftChecksDto | null>(null);
  readonly sourceLanguage = input.required<ArticleLanguage>();
  readonly languages = input.required<ArticleLanguage[]>();
  /** Something is uploading or processing (attachments, cover, image blocks). */
  readonly uploading = input(false);
  readonly jump = output<CheckTarget>();

  protected readonly items = computed(() => checkItems(this.checks(), this.sourceLanguage()));
  protected readonly multilingual = computed(() => this.languages().length > 1);
  protected readonly readingTimes = computed(() =>
    this.languages().flatMap((language) => {
      const entry = readingTimeOf(this.checks(), language);
      return entry ? [{ language, ...entry }] : [];
    }),
  );

  protected languageKey(language: ArticleLanguage): string {
    return language === 'en' ? 'en' : 'arEG';
  }
}
