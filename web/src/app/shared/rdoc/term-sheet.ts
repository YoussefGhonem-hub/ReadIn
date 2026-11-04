import { ChangeDetectionStrategy, Component, computed, inject, resource } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationStart, Router, RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { filter } from 'rxjs';
import { GlossaryArticleDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../directives/bdi-text';
import { TextDir } from '../directives/bidi';
import { ReadingTimePipe } from '../pipes/format.pipes';
import { articleLink } from '../ui/article-link';
import { BottomSheet } from '../ui/bottom-sheet';
import { LinesSkeleton } from '../ui/skeletons';
import { ErrorState } from '../ui/states';
import { GlossaryStore } from './glossary.store';
import { TermSheetService } from './rdoc-context';
import { languageDir } from './rdoc.utils';

/** "Articles that use this term": at most this many (the API sends ≤ 6, one of them may be the open article). */
const MAX_ARTICLES = 5;

type SheetState = 'loading' | 'ready' | 'missing' | 'error';

/**
 * Glossary term sheet (F21): tap a term → the English term, its Egyptian Arabic explanation and English definition
 * (the article version's language first), and other articles that use it. A bottom sheet on narrow screens, a dialog
 * on wide ones (role="dialog", labelled by the term, focus trapped, Esc and the scrim close it, focus returns to the
 * term). Lazy: app.ts loads it on the first tap.
 */
@Component({
  selector: 'rd-term-sheet',
  imports: [BottomSheet, TranslocoPipe, LucideDynamicIcon, RouterLink, BdiText, ReadingTimePipe, LinesSkeleton, ErrorState],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="!!terms.openTerm()" labelledBy="term-sheet-title" (closed)="terms.close()">
      @if (terms.openTerm(); as open) {
        <div class="flex flex-col gap-4" data-term-sheet [attr.data-state]="state()">
          <header class="flex flex-col gap-1 pe-10">
            <span class="inline-flex items-center gap-2 text-xs font-semibold text-primary">
              <svg lucideIcon="BookOpen" [size]="16" aria-hidden="true"></svg>
              {{ 'rdoc.term.title' | transloco }}
            </span>
            <h2 id="term-sheet-title" class="m-0 text-xl font-semibold leading-snug" data-term-title>
              @if (entry(); as term) {
                <bdi dir="ltr" lang="en">{{ term.term }}</bdi>
              } @else {
                <bdi>{{ open.text }}</bdi>
              }
            </h2>
          </header>

          @switch (state()) {
            @case ('loading') {
              <div class="flex flex-col gap-3" aria-busy="true" data-term-loading>
                <rd-lines-skeleton [count]="3" />
                <div class="rd-skeleton h-3 w-24"></div>
                <rd-lines-skeleton [count]="2" />
              </div>
            }
            @case ('missing') {
              <p class="m-0 text-sm text-text-secondary" data-term-missing>{{ 'rdoc.term.missing' | transloco }}</p>
            }
            @case ('error') {
              <rd-error-state [message]="'rdoc.term.loadError' | transloco" (retry)="lookup.reload()" />
            }
            @case ('ready') {
              @if (entry(); as term) {
                @if (open.language === 'ar-EG') {
                  <p class="m-0 leading-relaxed" dir="rtl" lang="ar-EG" data-term-explanation>
                    <rd-bdi-text [text]="term.explanationAr" baseDir="rtl" />
                  </p>
                  <div>
                    <span class="rd-label mb-1 text-text-secondary">{{ 'rdoc.term.inEnglish' | transloco }}</span>
                    <p class="m-0 text-sm leading-relaxed text-text-secondary" dir="ltr" lang="en" data-term-definition>
                      <rd-bdi-text [text]="term.definitionEn" baseDir="ltr" />
                    </p>
                  </div>
                } @else {
                  <p class="m-0 leading-relaxed" dir="ltr" lang="en" data-term-definition>
                    <rd-bdi-text [text]="term.definitionEn" baseDir="ltr" />
                  </p>
                  @if (uiLang() === 'ar' && term.explanationAr) {
                    <div>
                      <span class="rd-label mb-1 text-text-secondary">{{ 'rdoc.term.inArabic' | transloco }}</span>
                      <p class="m-0 text-sm leading-relaxed text-text-secondary" dir="rtl" lang="ar-EG" data-term-explanation>
                        <rd-bdi-text [text]="term.explanationAr" baseDir="rtl" />
                      </p>
                    </div>
                  }
                }

                @if (articles().length) {
                  <section class="border-t border-border pt-3" aria-labelledby="term-sheet-articles" data-term-articles>
                    <h3 id="term-sheet-articles" class="m-0 text-sm font-semibold">{{ 'rdoc.term.articles' | transloco }}</h3>
                    <ul class="m-0 flex list-none flex-col p-0">
                      @for (article of articles(); track article.id) {
                        <li class="border-t border-border first:border-t-0">
                          <a
                            [routerLink]="link(article)"
                            class="flex flex-col gap-1 py-3 text-text-primary no-underline hover:text-primary"
                            data-term-article
                            (click)="terms.close()"
                          >
                            <span class="line-clamp-2 font-semibold leading-snug" [attr.dir]="dir(article)" [attr.lang]="article.language">
                              <rd-bdi-text [text]="article.title" [baseDir]="dir(article)" />
                            </span>
                            <span class="text-xs text-text-secondary">
                              <rd-bdi-text [text]="uiLang() === 'ar' ? article.field.nameAr : article.field.nameEn" />
                              · {{ article.readingTimeMinutes | rdReadingTime: uiLang() }}
                            </span>
                          </a>
                        </li>
                      }
                    </ul>
                  </section>
                }
              }
            }
          }
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class TermSheet {
  protected readonly terms = inject(TermSheetService);
  private readonly glossary = inject(GlossaryStore);
  protected readonly uiLang = inject(LanguageService).lang;

  /** The open term, looked up in the version's language (answered from memory after the first time). */
  protected readonly lookup = resource({
    params: () => {
      const open = this.terms.openTerm();
      return open ? { slug: open.termId, lang: open.language } : undefined;
    },
    loader: ({ params }) => this.glossary.term(params.slug, params.lang),
  });

  protected readonly state = computed<SheetState>(() => {
    if (this.lookup.status() === 'error') return 'error';
    if (!this.lookup.hasValue()) return 'loading';
    return this.lookup.value() ? 'ready' : 'missing';
  });
  protected readonly entry = computed(() => (this.state() === 'ready' ? this.lookup.value() : null));
  /** Other articles that use the term: the one being read is left out. */
  protected readonly articles = computed(() => {
    const openId = this.terms.openTerm()?.articleId;
    return (this.entry()?.articles ?? []).filter((a) => a.id !== openId).slice(0, MAX_ARTICLES);
  });

  constructor() {
    // Leaving the page (back button, a link) closes the sheet.
    inject(Router)
      .events.pipe(
        filter((e) => e instanceof NavigationStart),
        takeUntilDestroyed(),
      )
      .subscribe(() => this.terms.close());
  }

  protected link(article: GlossaryArticleDto): string[] {
    return articleLink(article);
  }

  protected dir(article: GlossaryArticleDto): TextDir {
    return languageDir(article.language);
  }
}
