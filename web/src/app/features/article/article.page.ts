import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  RESPONSE_INIT,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  signal,
  viewChild,
} from '@angular/core';
import { HttpContext, httpResource } from '@angular/common/http';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SILENT_ERRORS, isApiError } from '../../core/api/api.config';
import { ContentApi } from '../../core/api/content.api';
import { ArticleDetailsDto, ArticleLanguage } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { injectLiveCounts } from '../../core/realtime/live-signals';
import { ARTICLE_FONT_SIZES, ArticleFontSize, ReaderPrefsService } from '../../core/theme/reader-prefs.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { ArticleAttachments } from '../../shared/media/article-attachments';
import { LocalizedDatePipe, ReadingTimePipe } from '../../shared/pipes/format.pipes';
import { RDocRenderer } from '../../shared/rdoc/rdoc-renderer';
import { hasBlock, safeHttpUrl, tableOfContents } from '../../shared/rdoc/rdoc.utils';
import { articleLanguageForUrl, urlLangFor } from '../../shared/ui/article-link';
import { Avatar } from '../../shared/ui/avatar';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { LinesSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ArticleActionBar } from './article-action-bar';
import { ArticleSeoService } from './article-seo.service';
import { ArticleToc } from './article-toc';
import { injectReadingTracker } from './reading-tracker';

/** Show the TOC once an article has this many headings ("long articles", F04). */
const TOC_MIN_HEADINGS = 3;

/** Article reader (F04). Route: `/:lang/a/:slug` where `lang` (ar|en) selects the article version (SPEC §23). */
@Component({
  selector: 'rd-article-page',
  imports: [RouterLink, TranslocoPipe, BdiText, Avatar, RDocRenderer, Segmented, LinesSkeleton, EmptyState, ErrorState, ArticleToc, ArticleActionBar, ArticleAttachments, ReadingTimePipe, LocalizedDatePipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <!-- Reading progress (mirrors in RTL: fills from the inline start) -->
    <div class="fixed inset-x-0 top-0 z-40 h-[3px] bg-transparent" aria-hidden="true">
      <div class="absolute start-0 top-0 h-full bg-accent transition-[width] duration-100" [style.width.%]="progress() * 100"></div>
    </div>

    <article class="mx-auto max-w-[720px] px-4 pb-28 pt-4" #articleEl>
      <!-- Reader toolbar -->
      <div class="mb-4 flex items-center justify-between gap-2">
        <a routerLink="/" class="rd-icon-btn" [attr.aria-label]="'common.back' | transloco">
          <svg lucideIcon="ArrowRight" [size]="18" class="ltr:rotate-180"></svg>
        </a>
        <div class="flex items-center gap-2">
          @if (article(); as a) {
            @if (languageOptions().length > 1) {
              <rd-segmented
                class="min-w-36"
                [options]="languageOptions()"
                [value]="a.language"
                (valueChange)="switchLanguage($event)"
                [label]="'article.languageToggle' | transloco"
              />
            }
          }
          <button type="button" class="rd-icon-btn" [attr.aria-label]="'article.fontSize' | transloco" (click)="fontPanel.set(!fontPanel())" [attr.aria-expanded]="fontPanel()">
            <svg lucideIcon="TextCursorInput" [size]="18"></svg>
          </button>
          <button type="button" class="rd-icon-btn hidden sm:inline-grid" [attr.aria-label]="'article.save' | transloco" (click)="prompt.requireAuth()">
            <svg lucideIcon="Bookmark" [size]="18"></svg>
          </button>
        </div>
      </div>

      @if (fontPanel()) {
        <div class="mb-4 rd-card p-3 shadow-none">
          <span class="rd-label">{{ 'article.fontSize' | transloco }}</span>
          <rd-segmented [options]="fontOptions()" [value]="prefs.fontSize()" (valueChange)="prefs.setFontSize($event)" [label]="'article.fontSize' | transloco" />
        </div>
      }

      @if (article(); as a) {
        @if (a.language !== requestedLanguage()) {
          <p class="mb-4 rounded-md bg-callout-info p-3 text-sm" role="status">{{ 'article.fallbackNotice' | transloco }}</p>
        }

        <div class="mb-2 flex flex-wrap items-center gap-2 text-xs">
          <span class="rd-tag"><rd-bdi-text [text]="uiLang() === 'ar' ? a.field.nameAr : a.field.nameEn" /></span>
          @if (a.topic; as topic) {
            <span class="text-text-secondary"><rd-bdi-text [text]="uiLang() === 'ar' ? topic.nameAr : topic.nameEn" /></span>
          }
          <span class="text-text-secondary">· {{ a.readingTimeMinutes | rdReadingTime: uiLang() }}</span>
        </div>

        <h1 class="m-0 text-[28px] font-semibold leading-snug tracking-tight lg:text-[32px]" [attr.dir]="titleDir()" [attr.lang]="a.language">
          <rd-bdi-text [text]="a.title" />
        </h1>
        @if (a.subtitle) {
          <p class="mt-2 text-lg text-text-secondary" [attr.dir]="subtitleDir()" [attr.lang]="a.language"><rd-bdi-text [text]="a.subtitle" /></p>
        }

        <!-- Byline -->
        <div class="mt-5 flex items-center gap-3">
          <rd-avatar [name]="a.author.displayName" [src]="a.author.avatarUrl" [size]="40" />
          <div class="min-w-0">
            <a [routerLink]="'/@' + a.author.username" class="inline-flex items-center gap-1 font-semibold text-text-primary no-underline">
              {{ a.author.displayName }}
              @if (a.author.isVerified) {
                <svg lucideIcon="BadgeCheck" [size]="16" class="text-primary" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
              }
            </a>
            <div class="text-xs text-text-secondary">{{ a.publishedAt | rdDate: uiLang() : 'long' }}</div>
          </div>
          <button type="button" class="rd-btn rd-btn-outline ms-auto min-h-9 px-3 text-sm" (click)="prompt.requireAuth()">
            + {{ 'article.follow' | transloco }}
          </button>
        </div>

        <!-- Trust row (SPEC §20) -->
        <ul class="my-5 flex list-none flex-wrap items-center gap-x-3 gap-y-2 border-y border-border p-0 py-3 text-xs text-text-secondary">
          @if (a.author.isVerified) {
            <li class="inline-flex items-center gap-1 font-semibold text-success">
              <svg lucideIcon="BadgeCheck" [size]="14" aria-hidden="true"></svg>{{ 'article.verifiedWriter' | transloco }}
            </li>
          }
          @if (a.isReviewed) {
            <li class="inline-flex items-center gap-1 font-semibold text-success">
              <svg lucideIcon="ShieldCheck" [size]="14" aria-hidden="true"></svg>
              @if (a.reviewedBy; as reviewer) {
                {{ 'article.reviewedBy' | transloco: { name: reviewer.displayName } }}
              } @else {
                {{ 'article.reviewed' | transloco }}
              }
            </li>
          }
          @if (a.lastReviewedAt) {
            <li>{{ 'article.lastReviewed' | transloco: { date: (a.lastReviewedAt | rdDate: uiLang() : 'monthYear') } }}</li>
          }
          @if (a.versionBadge) {
            <li><span class="rd-tag rd-tag-neutral" dir="ltr">{{ a.versionBadge }}</span></li>
          }
          @if (a.isAiAssisted) {
            <li class="inline-flex items-center gap-1"><svg lucideIcon="Bot" [size]="14" aria-hidden="true"></svg>{{ 'article.aiAssisted' | transloco }}</li>
          }
        </ul>

        @if (a.summary && !hasSummaryBlock()) {
          <aside class="rd-summary mb-6" role="note" [attr.dir]="summaryDir()" [attr.lang]="a.language">
            <span class="rd-summary-label">{{ 'rdoc.summary' | transloco }}</span>
            <rd-bdi-text [text]="a.summary" />
          </aside>
        }

        @if (toc().length >= tocMinHeadings) {
          <rd-article-toc class="mb-6 block" [entries]="toc()" />
        }

        <rd-rdoc [doc]="a.content" [style.--rd-article-size]="prefs.cssSize()" />

        <!-- Post attachments (F26): after the content, before the sources -->
        @if (a.attachments; as attachments) {
          <rd-article-attachments class="mt-8" [attachments]="attachments" [article]="a" />
        }

        @if (a.tags.length) {
          <ul class="mt-8 flex list-none flex-wrap gap-2 p-0">
            @for (tag of a.tags; track tag) {
              <li class="rd-tag rd-tag-neutral" dir="auto">#{{ tag }}</li>
            }
          </ul>
        }

        <!-- Sources (mandatory for technical content, SPEC §20) -->
        <section class="mt-10" aria-labelledby="sources-title">
          <h2 id="sources-title" class="mb-3 text-lg font-semibold">📚 {{ 'article.sources' | transloco }}</h2>
          @if (sources().length) {
            <ol class="m-0 flex flex-col gap-2 ps-5 text-sm">
              @for (source of sources(); track source.url) {
                <li>
                  <a [href]="source.url" target="_blank" rel="nofollow noopener noreferrer" class="inline-flex items-center gap-1 text-link underline underline-offset-2" dir="auto">
                    <rd-bdi-text [text]="source.title" />
                    <svg lucideIcon="ExternalLink" [size]="13" class="rd-flip-rtl shrink-0" aria-hidden="true"></svg>
                  </a>
                </li>
              }
            </ol>
          } @else {
            <p class="text-sm text-text-secondary">{{ 'article.noSources' | transloco }}</p>
          }
        </section>
      } @else {
        @if (notFound()) {
          <rd-empty-state [title]="'errors.article.not_found' | transloco" [message]="'article.notFoundBody' | transloco">
            <a routerLink="/" class="rd-btn rd-btn-primary mt-3">{{ 'comingSoon.backHome' | transloco }}</a>
          </rd-empty-state>
        } @else if (resource.status() === 'error') {
          <rd-error-state [message]="'article.loadError' | transloco" (retry)="resource.reload()" />
        } @else {
          <div class="flex flex-col gap-4" aria-busy="true">
            <div class="rd-skeleton h-8 w-4/5"></div>
            <div class="rd-skeleton h-5 w-1/2"></div>
            <rd-lines-skeleton class="mt-6" [count]="9" />
          </div>
        }
      }
    </article>

    @if (article(); as a) {
      <rd-article-action-bar
        [title]="a.title"
        [url]="shareUrl()"
        [reactionCount]="live()?.reactionCount ?? a.reactionCount"
        [commentCount]="live()?.commentCount ?? a.commentCount"
      />
    }
  `,
})
export class ArticlePage {
  private readonly content = inject(ContentApi);
  private readonly seo = inject(ArticleSeoService);
  private readonly router = inject(Router);
  private readonly transloco = inject(TranslocoService);
  private readonly responseInit = inject(RESPONSE_INIT, { optional: true });
  protected readonly prefs = inject(ReaderPrefsService);
  protected readonly prompt = inject(AuthPromptService);
  protected readonly uiLang = inject(LanguageService).lang;
  protected readonly tocMinHeadings = TOC_MIN_HEADINGS;

  /** Route params (component input binding). */
  readonly lang = input<string>('ar');
  readonly slug = input.required<string>();

  protected readonly requestedLanguage = computed<ArticleLanguage>(() => articleLanguageForUrl(this.lang()));
  protected readonly resource = httpResource<ArticleDetailsDto>(() => ({
    url: this.content.articleUrl(this.slug(), this.requestedLanguage()),
    context: new HttpContext().set(SILENT_ERRORS, true),
  }));

  protected readonly article = computed(() => (this.resource.hasValue() ? this.resource.value() : null));
  /** Reaction and comment counts update live while the article is open (F27). */
  protected readonly live = injectLiveCounts(() => this.article()?.id);
  protected readonly notFound = computed(() => {
    const error = this.resource.error();
    return isApiError(error) ? error.status === 404 : false;
  });

  protected readonly titleDir = computed(() => detectDir(this.article()?.title) ?? 'auto');
  protected readonly subtitleDir = computed(() => detectDir(this.article()?.subtitle) ?? 'auto');
  protected readonly summaryDir = computed(() => detectDir(this.article()?.summary) ?? 'auto');
  protected readonly toc = computed(() => tableOfContents(this.article()?.content));
  protected readonly hasSummaryBlock = computed(() => hasBlock(this.article()?.content, 'summary'));
  protected readonly sources = computed(() =>
    (this.article()?.sources ?? []).flatMap((s) => {
      const url = safeHttpUrl(s.url);
      return url ? [{ title: s.title || url, url }] : [];
    }),
  );
  protected readonly shareUrl = computed(() => {
    const a = this.article();
    return a ? this.seo.articleUrl(a.slug, a.language) : '';
  });

  protected readonly languageOptions = computed<SegmentOption<ArticleLanguage>[]>(() => {
    const available = this.article()?.availableLanguages ?? [];
    const options: SegmentOption<ArticleLanguage>[] = [
      { value: 'ar-EG', label: this.transloco.translate('article.languages.arEG') },
      { value: 'en', label: this.transloco.translate('article.languages.en'), ltr: true },
    ];
    return options.filter((o) => available.includes(o.value));
  });

  protected readonly fontOptions = computed<SegmentOption<ArticleFontSize>[]>(() => {
    this.uiLang(); // re-translate on UI language change
    return ARTICLE_FONT_SIZES.map((size) => ({ value: size, label: this.transloco.translate(`article.fontSizes.${size}`) }));
  });

  protected readonly fontPanel = signal(false);
  protected readonly progress = signal(0);
  private readonly articleEl = viewChild<ElementRef<HTMLElement>>('articleEl');

  constructor() {
    // Reading progress and active time for the "read" rule and streaks (F04, F08).
    injectReadingTracker(this.article, this.progress, () => this.articleEl()?.nativeElement);
    effect(() => {
      const article = this.article();
      if (article) this.seo.apply(article);
    });
    effect(() => {
      // Real 404 status for crawlers when rendered on the server.
      if (this.notFound() && this.responseInit) this.responseInit.status = 404;
    });

    const destroyRef = inject(DestroyRef);
    destroyRef.onDestroy(() => this.seo.clear());
    afterNextRender(() => {
      let frame = 0;
      const update = () => {
        frame = 0;
        const el = this.articleEl()?.nativeElement;
        if (!el) return;
        const rect = el.getBoundingClientRect();
        const total = rect.height - window.innerHeight;
        this.progress.set(total <= 0 ? 1 : Math.min(1, Math.max(0, -rect.top / total)));
      };
      const onScroll = () => {
        if (!frame) frame = requestAnimationFrame(update);
      };
      window.addEventListener('scroll', onScroll, { passive: true });
      window.addEventListener('resize', onScroll, { passive: true });
      destroyRef.onDestroy(() => {
        window.removeEventListener('scroll', onScroll);
        window.removeEventListener('resize', onScroll);
        cancelAnimationFrame(frame);
      });
      update();
    });
  }

  protected switchLanguage(language: ArticleLanguage): void {
    const article = this.article();
    if (!article || language === article.language) return;
    void this.router.navigate(['/', urlLangFor(language), 'a', article.slug]);
  }

}
