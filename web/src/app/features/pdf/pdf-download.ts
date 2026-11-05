import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleLanguage } from '../../core/api/models';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ArticlePdfService } from './article-pdf.service';

let nextId = 0;

/**
 * "تحميل PDF" / "Download PDF" (F33) for one of your own published articles. One language: downloads it at once. Two
 * (My articles, source language first): asks "أنهي نسخة؟" in a sheet, then downloads the one picked. While the file is
 * built the button says "بنجهز الـ PDF…" with a spinner and is disabled (`aria-disabled`, so it keeps focus); another
 * press does nothing. Errors are toasts from {@link ArticlePdfService}.
 */
@Component({
  selector: 'rd-pdf-download',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents' },
  template: `
    <button
      type="button"
      [class]="buttonClass()"
      class="aria-disabled:cursor-not-allowed aria-disabled:opacity-55"
      [attr.aria-disabled]="building() || null"
      [attr.data-state]="building() ? 'building' : 'idle'"
      data-pdf-download
      (click)="start()"
    >
      @if (building()) {
        <svg lucideIcon="LoaderCircle" [size]="15" class="animate-spin" aria-hidden="true"></svg>
        {{ 'pdf.building' | transloco }}
      } @else {
        <svg lucideIcon="Download" [size]="15" aria-hidden="true"></svg>
        {{ 'pdf.download' | transloco }}
      }
    </button>
    <span class="sr-only" role="status">{{ building() ? ('pdf.building' | transloco) : '' }}</span>

    <rd-bottom-sheet [open]="asking()" [labelledBy]="titleId" [describedBy]="bodyId" (closed)="asking.set(false)">
      @if (asking()) {
        <div class="flex flex-col gap-3 pt-1" data-pdf-languages>
          <h2 [id]="titleId" class="m-0 pe-10 text-xl font-semibold">{{ 'pdf.chooseTitle' | transloco }}</h2>
          <p [id]="bodyId" class="m-0 text-sm text-text-secondary">{{ 'pdf.chooseBody' | transloco }}</p>
          <div class="mt-1 flex flex-col gap-2">
            @for (lang of languages(); track lang; let first = $first) {
              <button
                type="button"
                class="rd-btn rd-btn-outline w-full justify-start"
                [attr.data-pdf-language]="lang"
                [attr.data-initial-focus]="first ? '' : null"
                (click)="choose(lang)"
              >
                <svg lucideIcon="FileText" [size]="18" aria-hidden="true"></svg>
                {{ 'pdf.languages.' + (lang === 'ar-EG' ? 'arEG' : 'en') | transloco }}
              </button>
            }
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class PdfDownload {
  private readonly pdf = inject(ArticlePdfService);

  readonly articleId = input.required<string>();
  /** The published versions to offer, source language first (one → no question). */
  readonly languages = input.required<readonly ArticleLanguage[]>();
  readonly buttonClass = input('rd-btn rd-btn-ghost min-h-9 px-3 text-sm');

  protected readonly building = computed(() => this.pdf.isBuilding(this.articleId()));
  protected readonly asking = signal(false);
  private readonly uid = nextId++;
  protected readonly titleId = `pdf-language-title-${this.uid}`;
  protected readonly bodyId = `pdf-language-body-${this.uid}`;

  protected start(): void {
    if (this.building()) return;
    const languages = this.languages();
    if (languages.length > 1) this.asking.set(true);
    else if (languages.length === 1) void this.pdf.download(this.articleId(), languages[0]);
  }

  protected choose(lang: ArticleLanguage): void {
    this.asking.set(false);
    void this.pdf.download(this.articleId(), lang);
  }
}
