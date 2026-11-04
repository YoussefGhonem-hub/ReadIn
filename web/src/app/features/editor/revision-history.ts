import { ChangeDetectionStrategy, Component, computed, effect, inject, input, output, signal, untracked } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ArticlesApi } from '../../core/api/articles.api';
import { ArticleLanguage, ArticleRevisionDetailsDto, ArticleRevisionDto, FieldDto, MediaAssetDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { LocalizedDatePipe, RelativeTimePipe } from '../../shared/pipes/format.pipes';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { ErrorState } from '../../shared/ui/states';
import { ArticlePreview, PreviewAuthor } from './article-preview';

/**
 * Revision history (F05): one revision per publish or update, newest first. A revision opens as a preview; "Restore"
 * asks the page to copy it into the working copy (readers see it after Update).
 */
@Component({
  selector: 'rd-revision-history',
  imports: [TranslocoPipe, LucideDynamicIcon, BdiText, LocalizedDatePipe, RelativeTimePipe, Segmented, ErrorState, ArticlePreview],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-revisions': '' },
  template: `
    @if (selected(); as revision) {
      <div class="mb-4 flex flex-wrap items-center gap-2">
        <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-sm" data-revisions-back (click)="selected.set(null)">
          <svg lucideIcon="ChevronRight" [size]="16" class="ltr:rotate-180" aria-hidden="true"></svg>
          {{ 'editor.revisions.back' | transloco }}
        </button>
        <h2 class="m-0 flex-1 text-base font-semibold">
          {{ 'editor.revisions.revision' | transloco: { number: revision.number } }}
          <span class="font-normal text-text-secondary">· {{ revision.createdAt | rdDate: lang() : 'long' }}</span>
        </h2>
        @if (languageOptions().length > 1) {
          <rd-segmented class="min-w-36" [options]="languageOptions()" [(value)]="previewLanguage" [label]="'editor.preview.version' | transloco" />
        }
        <button type="button" class="rd-btn rd-btn-primary min-h-10 px-4 text-sm" [disabled]="busy()" data-restore-revision (click)="restore.emit(revision.number)">
          <svg lucideIcon="RotateCcw" [size]="16" aria-hidden="true"></svg>
          {{ 'editor.revisions.restore' | transloco }}
        </button>
      </div>
      <div class="rd-card p-4 shadow-none">
        <rd-article-preview
          [document]="revision.document"
          [language]="previewLanguage()"
          [media]="mediaOf(revision)"
          [field]="fieldOf(revision)"
          [author]="author()"
          [publishedAt]="revision.createdAt"
          [uiLang]="lang()"
        />
      </div>
    } @else {
      <h2 class="m-0 mb-1 text-lg font-semibold">{{ 'editor.revisions.title' | transloco }}</h2>
      <p class="m-0 mb-4 text-sm text-text-secondary">{{ 'editor.revisions.subtitle' | transloco }}</p>
      @switch (status()) {
        @case ('error') {
          <rd-error-state [message]="'editor.revisions.loadError' | transloco" (retry)="load()" />
        }
        @case ('loaded') {
          <ol class="m-0 flex list-none flex-col gap-2 p-0">
            @for (revision of revisions(); track revision.number; let first = $first) {
              <li>
                <button
                  type="button"
                  class="rd-card flex w-full items-center gap-3 p-3 text-start shadow-none"
                  [disabled]="opening() !== null"
                  [attr.data-revision]="revision.number"
                  (click)="open(revision)"
                >
                  <span class="grid h-9 w-9 shrink-0 place-items-center rounded-chip bg-primary-container text-sm font-semibold text-on-primary-container" dir="ltr">{{ revision.number }}</span>
                  <span class="min-w-0 flex-1">
                    <span class="block truncate font-semibold">
                      @if (revision.title) {
                        <rd-bdi-text [text]="revision.title" />
                      } @else {
                        {{ 'editor.myArticles.untitled' | transloco }}
                      }
                    </span>
                    <span class="block text-xs text-text-secondary">
                      {{ revision.createdAt | rdRelativeTime: lang() }}
                      @if (first) {
                        · <span class="font-semibold text-success">{{ 'editor.revisions.live' | transloco }}</span>
                      }
                    </span>
                  </span>
                  @if (opening() === revision.number) {
                    <svg lucideIcon="LoaderCircle" [size]="16" class="animate-spin" aria-hidden="true"></svg>
                  } @else {
                    <svg lucideIcon="ChevronLeft" [size]="16" class="text-text-secondary ltr:rotate-180" aria-hidden="true"></svg>
                  }
                </button>
              </li>
            } @empty {
              <li class="rd-card p-4 text-sm text-text-secondary shadow-none" data-revisions-empty>{{ 'editor.revisions.empty' | transloco }}</li>
            }
          </ol>
          @if (openFailed()) {
            <p class="rd-alert rd-alert-error mt-3" role="alert">{{ 'editor.revisions.openError' | transloco }}</p>
          }
        }
        @default {
          <div class="flex flex-col gap-2" aria-busy="true">
            @for (i of [1, 2, 3]; track i) {
              <div class="rd-skeleton h-16"></div>
            }
          </div>
        }
      }
    }
  `,
})
export class RevisionHistory {
  private readonly api = inject(ArticlesApi);
  private readonly transloco = inject(TranslocoService);
  private readonly language = inject(LanguageService);
  protected readonly lang = this.language.lang;

  readonly articleId = input.required<string>();
  readonly author = input.required<PreviewAuthor>();
  readonly fields = input<FieldDto[]>([]);
  /** Assets the editor knows; a revision brings its own attachments' assets too. */
  readonly media = input<readonly MediaAssetDto[]>([]);
  readonly busy = input(false);
  readonly restore = output<number>();

  protected readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly revisions = signal<ArticleRevisionDto[]>([]);
  protected readonly selected = signal<ArticleRevisionDetailsDto | null>(null);
  protected readonly opening = signal<number | null>(null);
  protected readonly openFailed = signal(false);
  protected readonly previewLanguage = signal<ArticleLanguage>('ar-EG');
  protected readonly languageOptions = computed<SegmentOption<ArticleLanguage>[]>(() => {
    const lang = this.lang();
    const languages = this.selected()?.document.translations.map((t) => t.language) ?? [];
    return languages.map((value) => ({ value, label: this.transloco.translate(`editor.language.short.${value === 'en' ? 'en' : 'arEG'}`, {}, lang) }));
  });

  constructor() {
    effect(() => {
      this.articleId();
      untracked(() => void this.load());
    });
  }

  async load(): Promise<void> {
    this.status.set('loading');
    this.selected.set(null);
    try {
      this.revisions.set(await firstValueFrom(this.api.revisions(this.articleId())));
      this.status.set('loaded');
    } catch {
      this.status.set('error');
    }
  }

  protected async open(revision: ArticleRevisionDto): Promise<void> {
    this.opening.set(revision.number);
    this.openFailed.set(false);
    try {
      const details = await firstValueFrom(this.api.revision(this.articleId(), revision.number));
      this.previewLanguage.set(details.document.sourceLanguage);
      this.selected.set(details);
    } catch {
      this.openFailed.set(true);
    } finally {
      this.opening.set(null);
    }
  }

  /** The revision's attachment assets, then the ones the editor knows (newer status wins for the same id). */
  protected mediaOf(revision: ArticleRevisionDetailsDto): readonly MediaAssetDto[] {
    const known = new Set(this.media().map((m) => m.id));
    return [...this.media(), ...(revision.media ?? []).filter((m) => !known.has(m.id))];
  }

  protected fieldOf(revision: ArticleRevisionDetailsDto): FieldDto | null {
    return this.fields().find((f) => f.id === revision.document.fieldId) ?? null;
  }
}
