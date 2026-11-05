import { ChangeDetectionStrategy, Component, DOCUMENT, ElementRef, Injector, afterNextRender, effect, inject, input, signal, untracked, viewChild } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleStatus, MyArticleDto } from '../../core/api/models';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { CompactNumberPipe, LocalizedDatePipe, PluralPipe, ReadingTimePipe, RelativeTimePipe } from '../../shared/pipes/format.pipes';
import { articleLink } from '../../shared/ui/article-link';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ArticleCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { pdfLanguages } from '../pdf/article-pdf.service';
import { PdfDownload } from '../pdf/pdf-download';
import { loadMoreNearEnd } from '../profile/infinite-scroll';
import { provideEditorIcons } from './editor-icons';
import { MyArticlesStore } from './my-articles.store';

const TABS: readonly ArticleStatus[] = ['draft', 'published'];

/**
 * My articles (F05), `/write`: Drafts and Published, each row with Edit and Delete (confirmed in a sheet), published
 * rows also with Download PDF (F33), and the New article button. Signed-in writers only; rendered in the browser.
 */
@Component({
  selector: 'rd-my-articles-page',
  imports: [
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    BdiText,
    ReadingTimePipe,
    RelativeTimePipe,
    LocalizedDatePipe,
    CompactNumberPipe,
    PluralPipe,
    ArticleCardSkeleton,
    EmptyState,
    ErrorState,
    BottomSheet,
    PdfDownload,
  ],
  providers: [MyArticlesStore, provideEditorIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pb-16 pt-5 lg:pt-8' },
  template: `
    <!-- One card: the header (title, New article), the Drafts / Published tabs and the list. -->
    <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0">
      <header class="flex flex-wrap items-start justify-between gap-3 px-4 pt-4 lg:px-5 lg:pt-5">
        <div class="min-w-0">
          <h1 class="m-0 text-xl font-bold lg:text-2xl">{{ 'editor.myArticles.title' | transloco }}</h1>
          <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'editor.myArticles.subtitle' | transloco }}</p>
        </div>
        <a routerLink="/write/new" class="rd-btn rd-btn-primary" data-new-article>
          <svg lucideIcon="Plus" [size]="18" aria-hidden="true"></svg>
          {{ 'editor.myArticles.new' | transloco }}
        </a>
      </header>

      <div class="mt-3 flex gap-5 border-b border-border px-4 lg:px-5" role="tablist" [attr.aria-label]="'editor.myArticles.title' | transloco">
        @for (t of tabs; track t) {
          <button
            type="button"
            role="tab"
            [id]="'my-tab-' + t"
            [attr.aria-controls]="'my-panel'"
            [attr.aria-selected]="store.tab() === t"
            [attr.tabindex]="store.tab() === t ? 0 : -1"
            [attr.data-my-tab]="t"
            class="-mb-px min-h-11 shrink-0 border-b-2 px-1 text-sm"
            [class]="store.tab() === t ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary'"
            (click)="select(t)"
            (keydown)="onTabKey($event)"
          >
            {{ 'editor.myArticles.tabs.' + t | transloco }}
          </button>
        }
      </div>

      <section id="my-panel" role="tabpanel" [attr.aria-labelledby]="'my-tab-' + store.tab()" tabindex="-1" aria-live="polite" data-my-articles>
        @switch (store.status()) {
          @case ('error') {
            <rd-error-state [message]="'editor.myArticles.loadError' | transloco" (retry)="store.load()" />
          }
          @case ('loaded') {
            <ul class="m-0 list-none divide-y divide-border p-0">
              @for (article of store.items(); track article.id) {
                <li class="flex gap-3 px-4 py-4 lg:px-5" [attr.data-my-article]="article.id">
                  <div class="h-16 w-16 shrink-0 overflow-hidden rounded-md bg-primary-container" aria-hidden="true">
                    @if (article.coverUrl) {
                      <img [src]="article.coverUrl" alt="" class="h-full w-full object-cover" loading="lazy" />
                    } @else {
                      <div class="grid h-full w-full place-items-center text-on-primary-container">
                        <svg lucideIcon="FileText" [size]="22"></svg>
                      </div>
                    }
                  </div>
                  <div class="min-w-0 flex-1">
                    <div class="mb-1 flex flex-wrap items-center gap-1.5 text-xs">
                      @if (article.field; as field) {
                        <span class="rd-tag"><rd-bdi-text [text]="lang() === 'ar' ? field.nameAr : field.nameEn" /></span>
                      } @else {
                        <span class="rd-tag rd-tag-neutral">{{ 'editor.myArticles.noField' | transloco }}</span>
                      }
                      @if (article.hasUnpublishedChanges) {
                        <span class="rd-tag rd-tag-accent" data-unpublished-chip>{{ 'editor.myArticles.unpublishedChanges' | transloco }}</span>
                      }
                    </div>
                    <h2 class="m-0 line-clamp-2 text-[15px] font-semibold leading-snug" [attr.dir]="titleDir(article)" [attr.lang]="article.title ? article.language : null" data-my-title>
                      @if (article.title) {
                        <rd-bdi-text [text]="article.title" />
                      } @else {
                        <span class="text-text-secondary">{{ 'editor.myArticles.untitled' | transloco }}</span>
                      }
                    </h2>
                    <p class="m-0 mt-1 flex flex-wrap gap-x-2 text-xs text-text-secondary">
                      <span>{{ article.readingTimeMinutes | rdReadingTime: lang() }}</span>
                      <span aria-hidden="true">·</span>
                      @if (article.publishedAt) {
                        <span>{{ 'editor.myArticles.publishedOn' | transloco: { date: (article.publishedAt | rdDate: lang()) } }}</span>
                        <span aria-hidden="true">·</span>
                      }
                      <span>{{ 'editor.myArticles.editedAt' | transloco: { time: (article.savedAt | rdRelativeTime: lang()) } }}</span>
                    </p>
                    @if (article.status === 'published') {
                      <p class="m-0 mt-1 flex gap-3 text-xs text-text-secondary">
                        <span class="inline-flex items-center gap-1" [attr.aria-label]="article.reactionCount | rdPlural: 'editor.myArticles.reactions' : lang()">
                          <svg lucideIcon="Lightbulb" [size]="13" aria-hidden="true"></svg>{{ article.reactionCount | rdCompactNumber: lang() }}
                        </span>
                        <span class="inline-flex items-center gap-1" [attr.aria-label]="article.commentCount | rdPlural: 'editor.myArticles.comments' : lang()">
                          <svg lucideIcon="MessageCircle" [size]="13" aria-hidden="true"></svg>{{ article.commentCount | rdCompactNumber: lang() }}
                        </span>
                        <span class="inline-flex items-center gap-1" [attr.aria-label]="article.readCount | rdPlural: 'editor.myArticles.reads' : lang()">
                          <svg lucideIcon="Eye" [size]="13" aria-hidden="true"></svg>{{ article.readCount | rdCompactNumber: lang() }}
                        </span>
                      </p>
                    }
                    <div class="mt-2 flex flex-wrap gap-2">
                      <a [routerLink]="['/write', article.id]" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" data-edit-article>
                        <svg lucideIcon="Pencil" [size]="15" aria-hidden="true"></svg>
                        {{ 'editor.myArticles.edit' | transloco }}
                      </a>
                      @if (article.slug && article.status === 'published') {
                        <a [routerLink]="link(article)" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm" data-view-article>{{ 'editor.myArticles.view' | transloco }}</a>
                      }
                      @if (article.status === 'published') {
                        <!-- F33: the published version as a PDF; two language versions ask which first. -->
                        <rd-pdf-download [articleId]="article.id" [languages]="pdfLanguages(article)" />
                      }
                      <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm text-error" data-delete-article (click)="confirming.set(article)">
                        <svg lucideIcon="Trash2" [size]="15" aria-hidden="true"></svg>
                        {{ 'editor.myArticles.delete' | transloco }}
                      </button>
                    </div>
                  </div>
                </li>
              } @empty {
                <li>
                  @if (store.tab() === 'draft') {
                    <rd-empty-state [title]="'editor.myArticles.emptyDrafts.title' | transloco" [message]="'editor.myArticles.emptyDrafts.body' | transloco" data-my-empty>
                      <a routerLink="/write/new" class="rd-btn rd-btn-primary mt-3">{{ 'editor.myArticles.new' | transloco }}</a>
                    </rd-empty-state>
                  } @else {
                    <rd-empty-state [title]="'editor.myArticles.emptyPublished.title' | transloco" [message]="'editor.myArticles.emptyPublished.body' | transloco" data-my-empty />
                  }
                </li>
              }
            </ul>
            @if (store.current().loadingMore) {
              <rd-article-card-skeleton class="px-4 lg:px-5" />
            }
            @if (store.current().loadMoreFailed) {
              <div class="border-t border-border py-4 text-center">
                <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
              </div>
            }
          }
          @default {
            @for (i of [1, 2, 3]; track i) {
              <rd-article-card-skeleton class="px-4 lg:px-5" />
            }
          }
        }
        <div #sentinel class="h-px" aria-hidden="true"></div>
      </section>
    </div>

    <rd-bottom-sheet
      [open]="!!confirming()"
      role="alertdialog"
      labelledBy="delete-article-title"
      describedBy="delete-article-body"
      [dismissible]="!store.deleting()"
      (closed)="confirming.set(null)"
    >
      @if (confirming(); as article) {
        <div class="flex flex-col gap-3 pt-1" data-delete-sheet>
          <h2 id="delete-article-title" class="m-0 pe-10 text-xl font-semibold">{{ 'editor.myArticles.deleteTitle' | transloco }}</h2>
          <p id="delete-article-body" class="m-0 text-sm text-text-secondary">
            {{ (article.status === 'published' ? 'editor.myArticles.deletePublishedBody' : 'editor.myArticles.deleteDraftBody') | transloco }}
          </p>
          <div class="mt-2 flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" (click)="confirming.set(null)">{{ 'common.cancel' | transloco }}</button>
            <button type="button" class="rd-btn flex-1 bg-error text-on-error" data-confirm-delete (click)="delete(article)">
              {{ 'editor.myArticles.deleteConfirm' | transloco }}
            </button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class MyArticlesPage {
  protected readonly store = inject(MyArticlesStore);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);
  private readonly toasts = inject(ToastService);
  private readonly router = inject(Router);
  private readonly document = inject(DOCUMENT);
  private readonly injector = inject(Injector);
  private readonly language = inject(LanguageService);
  protected readonly lang = this.language.lang;
  protected readonly tabs = TABS;
  protected readonly pdfLanguages = pdfLanguages;

  /** `?tab=published` (query param binding) opens the Published tab. */
  readonly tab = input<string | undefined>(undefined);
  protected readonly confirming = signal<MyArticleDto | null>(null);
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('editor.myArticles.title')} — ReadIn`);
    effect(() => {
      const tab: ArticleStatus = this.tab() === 'published' ? 'published' : 'draft';
      untracked(() => this.store.select(tab));
    });
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.store.loadMore(),
    );
  }

  protected select(tab: ArticleStatus): void {
    this.store.select(tab);
    void this.router.navigate([], { queryParams: { tab: tab === 'published' ? 'published' : null }, replaceUrl: true });
  }

  protected onTabKey(event: KeyboardEvent): void {
    const index = TABS.indexOf(this.store.tab());
    const rtl = this.language.dir() === 'rtl';
    const step = { ArrowRight: rtl ? -1 : 1, ArrowLeft: rtl ? 1 : -1 }[event.key];
    let next: number | null = null;
    if (step) next = (index + step + TABS.length) % TABS.length;
    else if (event.key === 'Home') next = 0;
    else if (event.key === 'End') next = TABS.length - 1;
    if (next === null) return;
    event.preventDefault();
    const tab = TABS[next];
    this.select(tab);
    afterNextRender(() => this.document.getElementById(`my-tab-${tab}`)?.focus(), { injector: this.injector });
  }

  protected titleDir(article: MyArticleDto): string | null {
    return article.title ? (detectDir(article.title) ?? 'auto') : null;
  }

  protected link(article: MyArticleDto): string[] {
    return articleLink({ slug: article.slug!, language: article.language });
  }

  protected async delete(article: MyArticleDto): Promise<void> {
    this.confirming.set(null);
    const error = await this.store.delete(article);
    if (error) this.toasts.error(this.errors.forCode(error));
    else this.toasts.success(this.transloco.translate('editor.myArticles.deleted'));
  }
}
