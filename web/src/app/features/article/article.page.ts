import {
  ApplicationRef,
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  Injector,
  PLATFORM_ID,
  RESPONSE_INIT,
  Type,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { NgComponentOutlet, isPlatformBrowser } from '@angular/common';
import { HttpContext, httpResource } from '@angular/common/http';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SILENT_ERRORS, isApiError } from '../../core/api/api.config';
import { ContentApi } from '../../core/api/content.api';
import { ArticleDetailsDto, ArticleLanguage, ArticleModerationDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { HydrationWindow } from '../../core/http/hydration-window';
import { LanguageService } from '../../core/i18n/language.service';
import { AppHistory } from '../../core/platform/app-history';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { CollectionsStore } from '../../core/social/collections.store';
import { FollowStore } from '../../core/social/follow.store';
import { bindLiveCounters } from '../../core/social/live-article';
import { MuteStore } from '../../core/social/mute.store';
import { ARTICLE_FONT_SIZES, ArticleFontSize, ReaderPrefsService } from '../../core/theme/reader-prefs.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir, isolate } from '../../shared/directives/bidi';
import { ArticleAttachments } from '../../shared/media/article-attachments';
import { LocalizedDatePipe } from '../../shared/pipes/format.pipes';
import { CollectionPickerSheet } from '../../shared/social/collection-sheets';
import { FollowButton } from '../../shared/social/follow-button';
import { MutedBanner } from '../../shared/mutes/muted-banner';
import { RDocRenderer } from '../../shared/rdoc/rdoc-renderer';
import { hasBlock, tableOfContents } from '../../shared/rdoc/rdoc.utils';
import { articleLanguageForUrl, urlLangFor } from '../../shared/ui/article-link';
import { tagLink } from '../../shared/ui/tag-link';
import { Avatar } from '../../shared/ui/avatar';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { LinesSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { categoryLink } from '../categories/category-rules';
import { ArticleActionBar } from './article-action-bar';
import { ArticleCover, ArticleHeadline, ArticleHealthNotice, ArticleSources, ArticleTrustRow } from './article-parts';
import { ArticleSeoService } from './article-seo.service';
import { ArticleToc } from './article-toc';
import { NextInPath } from './next-in-path';
import { injectReadingTracker } from './reading-tracker';
import { RelatedArticles } from './related-articles';
import { injectResumePosition } from './resume-position';

/** Show the TOC once an article has this many headings ("long articles", F04). */
const TOC_MIN_HEADINGS = 3;

/** Article reader (F04). Route: `/:lang/a/:slug` where `lang` (ar|en) selects the article version (SPEC §23). */
@Component({
  selector: 'rd-article-page',
  imports: [
    RouterLink,
    TranslocoPipe,
    BdiText,
    Avatar,
    RDocRenderer,
    Segmented,
    LinesSkeleton,
    EmptyState,
    ErrorState,
    ArticleToc,
    ArticleActionBar,
    ArticleAttachments,
    ArticleCover,
    ArticleHeadline,
    ArticleTrustRow,
    ArticleHealthNotice,
    ArticleSources,
    NextInPath,
    LocalizedDatePipe,
    LucideDynamicIcon,
    FollowButton,
    CollectionPickerSheet,
    NgComponentOutlet,
    RelatedArticles,
    MutedBanner,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <!-- Reading progress (mirrors in RTL: fills from the inline start) -->
    <div class="fixed inset-x-0 top-0 z-40 h-[3px] bg-transparent" aria-hidden="true" data-reading-progress>
      <div class="absolute start-0 top-0 h-full bg-accent transition-[width] duration-100" [style.width.%]="progress() * 100"></div>
    </div>

    <article class="mx-auto max-w-[720px] px-4 pb-28 pt-4" #articleEl>
      <!-- Reader toolbar -->
      <div class="mb-4 flex items-center justify-between gap-2">
        <!-- Back to the page you came from in the app, else Home (a plain link to Home without JavaScript) -->
        <a href="/" class="rd-icon-btn" [attr.aria-label]="'common.back' | transloco" data-reader-back (click)="goBack($event)">
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
          @if (article()) {
            <button type="button" class="rd-icon-btn" data-add-to-collection [attr.aria-label]="'article.addToCollection' | transloco" (click)="openCollections()">
              <svg lucideIcon="FolderPlus" [size]="18"></svg>
            </button>
          }
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

        <!-- Hidden by moderators (F22): only its author and moderators get here -->
        @if (a.moderation; as hidden) {
          <section class="mb-4 flex gap-3 rounded-card bg-callout-warning p-4 text-sm" role="status" aria-labelledby="hidden-banner-title" data-hidden-banner>
            <svg lucideIcon="EyeOff" [size]="20" class="mt-0.5 shrink-0 text-callout-warning-accent" aria-hidden="true"></svg>
            <div class="min-w-0 flex-1">
              <h2 id="hidden-banner-title" class="m-0 text-base font-semibold">{{ 'article.hiddenBanner.title' | transloco }}</h2>
              <p class="m-0 mt-1 text-text-secondary">
                {{ (isAuthor() ? 'article.hiddenBanner.author' : 'article.hiddenBanner.moderator') | transloco }}
                · {{ 'article.hiddenBanner.since' | transloco: { date: (hidden.hiddenAt | rdDate: uiLang() : 'long') } }}
              </p>
              @if (hidden.note) {
                <p class="m-0 mt-2"><span class="font-semibold">{{ 'article.hiddenBanner.note' | transloco }}:</span> <rd-bdi-text [text]="hidden.note" /></p>
              }
            </div>
          </section>
        }

        <!-- A writer you muted (F28): a direct link still opens, with the way to unmute -->
        @if (mutedAuthor(); as author) {
          <rd-muted-banner class="mb-4" [user]="author" />
        }

        @if (a.coverUrl) {
          <rd-article-cover [url]="a.coverUrl" />
        }
        <rd-article-headline
          [field]="uiLang() === 'ar' ? a.field.nameAr : a.field.nameEn"
          [topic]="a.topic ? (uiLang() === 'ar' ? a.topic.nameAr : a.topic.nameEn) : null"
          [minutes]="a.readingTimeMinutes"
          [title]="a.title"
          [subtitle]="a.subtitle"
          [language]="a.language"
          [uiLang]="uiLang()"
        />

        <!-- Byline -->
        <div class="mt-5 flex items-center gap-3" data-byline>
          @if (a.author; as author) {
            <!-- The name below is the link for keyboards and screen readers; the photo is the same link for taps. -->
            <a [routerLink]="'/@' + author.username" class="flex shrink-0 rounded-full" tabindex="-1" aria-hidden="true" data-author-avatar>
              <rd-avatar [name]="author.displayName" [src]="author.avatarUrl" [size]="40" />
            </a>
            <div class="min-w-0">
              <a [routerLink]="'/@' + author.username" class="inline-flex items-center gap-1 font-semibold text-text-primary no-underline">
                {{ author.displayName }}
                @if (author.isVerified) {
                  <svg lucideIcon="BadgeCheck" [size]="16" class="text-primary" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
                }
              </a>
              <!-- The writer's title (F14): one line with "…", on the UI's start side, laid out and cut in its own direction -->
              @if (author.headline?.trim(); as headline) {
                <p class="m-0 flex text-xs leading-snug text-text-secondary" [attr.title]="headline" data-author-headline>
                  <bdi dir="auto" class="min-w-0 truncate">{{ headline }}</bdi>
                </p>
              }
              <div class="text-xs text-text-secondary">
                {{ a.publishedAt | rdDate: uiLang() : 'long' }}
                <!-- The writer's category (F31): "في قسم {name}", the name isolated in its own direction. -->
                @if (a.category; as category) {
                  <span aria-hidden="true">·</span>
                  <a [routerLink]="categoryLink(author.username, category.slug)" class="font-semibold text-link no-underline hover:underline" data-article-category>{{
                    'article.inCategory' | transloco: { name: isolate(category.name) }
                  }}</a>
                }
              </div>
            </div>
            <div class="ms-auto" data-author-follow>
              <rd-follow-button [user]="author" [initial]="a.isFollowingAuthor" />
            </div>
          } @else {
            <!-- The author deleted their account (SPEC §9.6): no name, photo, profile link or follow. -->
            <rd-avatar [generic]="true" [size]="40" />
            <div class="min-w-0">
              <span class="font-semibold text-text-secondary" data-deleted-author>{{ 'common.deletedUser' | transloco }}</span>
              <div class="text-xs text-text-secondary">{{ a.publishedAt | rdDate: uiLang() : 'long' }}</div>
            </div>
          }
        </div>

        <!-- Trust row (SPEC §20) -->
        <rd-article-trust-row [verified]="!!a.author?.isVerified" [versionBadge]="a.versionBadge" [aiAssisted]="a.isAiAssisted" />

        <!-- Medicine and Public Health (SPEC F04, §20) -->
        @if (a.field.isSensitive) {
          <rd-article-health-notice />
        }

        @if (a.summary && !hasSummaryBlock()) {
          <aside class="rd-summary mb-6" role="note" [attr.dir]="summaryDir()" [attr.lang]="a.language">
            <span class="rd-summary-label">{{ 'rdoc.summary' | transloco }}</span>
            <rd-bdi-text [text]="a.summary" />
          </aside>
        }

        @if (toc().length >= tocMinHeadings) {
          <rd-article-toc class="mb-6 block" [entries]="toc()" />
        }

        <rd-rdoc [doc]="a.content" [articleId]="a.id" [style.--rd-article-size]="prefs.cssSize()" />

        <!-- Post attachments (F26): after the content, before the sources -->
        @if (a.attachments; as attachments) {
          <rd-article-attachments class="mt-8" [attachments]="attachments" [article]="a" />
        }

        <!-- Tags (F32): each opens its tag page -->
        @if (a.tags.length) {
          <ul class="mt-8 flex list-none flex-wrap gap-2 p-0" [attr.aria-label]="'feedCard.tags' | transloco" data-article-tags>
            @for (tag of a.tags; track tag.slug) {
              <li class="flex">
                <a [routerLink]="tagLink(tag)" class="rd-tag rd-tag-neutral no-underline hover:text-primary hover:underline" dir="auto" [attr.data-article-tag]="tag.slug">#{{ tag.name }}</a>
              </li>
            }
          </ul>
        }

        <!-- Sources (mandatory for technical content, SPEC §20) -->
        <rd-article-sources [sources]="a.sources" />
        <rd-next-in-path [articleId]="a.id" />

        <rd-related-articles [article]="a" />

        <!-- Comments (F11): their code and data load when they near the viewport or the comment button is pressed -->
        <section #commentsAnchor id="comments" class="mt-10 border-t border-border pt-6" style="scroll-margin-top: 5rem" aria-labelledby="comments-title">
          @if (commentsSection(); as section) {
            <ng-container *ngComponentOutlet="section; inputs: { article: a }" />
          } @else {
            <div class="min-h-56">
              <h2 id="comments-title" class="m-0 text-lg font-semibold" tabindex="-1">{{ 'comments.title' | transloco: { count: commentCount() } }}</h2>
            </div>
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
      <rd-article-action-bar [article]="a" [url]="shareUrl()" (commentsOpen)="openComments()" (moderationChange)="setModeration($event)" />
      <rd-collection-picker-sheet [open]="collectionsOpen()" [article]="a" (closed)="collectionsOpen.set(false)" />
    }
  `,
})
export class ArticlePage {
  private readonly content = inject(ContentApi);
  private readonly seo = inject(ArticleSeoService);
  private readonly router = inject(Router);
  private readonly transloco = inject(TranslocoService);
  private readonly responseInit = inject(RESPONSE_INIT, { optional: true });
  private readonly history = inject(AppHistory);
  protected readonly prefs = inject(ReaderPrefsService);
  protected readonly prompt = inject(AuthPromptService);
  protected readonly uiLang = inject(LanguageService).lang;
  protected readonly tocMinHeadings = TOC_MIN_HEADINGS;
  protected readonly tagLink = tagLink;
  protected readonly categoryLink = categoryLink;
  protected readonly isolate = isolate;

  /** Route params (component input binding). */
  readonly lang = input<string>('ar');
  readonly slug = input.required<string>();

  protected readonly requestedLanguage = computed<ArticleLanguage>(() => articleLanguageForUrl(this.lang()));
  protected readonly resource = httpResource<ArticleDetailsDto>(() => ({
    url: this.content.articleUrl(this.slug(), this.requestedLanguage()),
    context: new HttpContext().set(SILENT_ERRORS, true),
  }));

  protected readonly article = computed(() => (this.resource.hasValue() ? this.resource.value() : null));
  private readonly session = inject(SessionStore);
  /** You wrote it: the "hidden" banner speaks to you (F22). */
  protected readonly isAuthor = computed(() => this.session.isAuthenticated() && this.session.me()?.id === this.article()?.author?.id);
  private readonly mutes = inject(MuteStore);
  /** You muted the writer (F28): the "انت كاتم الكاتب ده" banner, also right after Mute author from the "⋯" menu. */
  protected readonly mutedAuthor = computed(() => {
    const article = this.article();
    const author = article?.author;
    if (!author || !this.session.isAuthenticated() || this.isAuthor()) return null;
    return this.mutes.isAuthorMuted(author.id, article.isAuthorMuted ?? false) ? author : null;
  });
  protected readonly notFound = computed(() => {
    const error = this.resource.error();
    return isApiError(error) ? error.status === 404 : false;
  });

  protected readonly summaryDir = computed(() => detectDir(this.article()?.summary) ?? 'auto');
  protected readonly toc = computed(() => tableOfContents(this.article()?.content));
  protected readonly hasSummaryBlock = computed(() => hasBlock(this.article()?.content, 'summary'));
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
  protected readonly collectionsOpen = signal(false);
  protected readonly progress = signal(0);
  private readonly articleEl = viewChild<ElementRef<HTMLElement>>('articleEl');
  private readonly social = inject(ArticleSocialStore);

  /** The live comment count for the comments heading before the section loads (F11, F27). */
  protected readonly commentCount = computed(() => {
    const a = this.article();
    return a ? this.social.state(a).commentCount : 0;
  });
  /**
   * False while the page shows the anonymous copy rendered by the server and your own (with your reading progress) is
   * still on its way, see `personalizeAfterHydration`.
   */
  private readonly ownCopy = signal(!inject(HydrationWindow).isOpen);
  /** The comments section, once its lazy chunk has loaded (browser only; never during SSR). */
  protected readonly commentsSection = signal<Type<unknown> | null>(null);
  private readonly commentsAnchor = viewChild<ElementRef<HTMLElement>>('commentsAnchor');
  private readonly injector = inject(Injector);
  /** The comments chunk being (or already) loaded, shared by the viewport trigger and the button. */
  private commentsChunk: Promise<void> | null = null;

  constructor() {
    // The comments load when they near the viewport (or on the comment button). Their code is its own lazy chunk.
    const isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
    effect((onCleanup) => {
      const anchor = this.commentsAnchor()?.nativeElement;
      if (!isBrowser || !anchor || this.commentsSection() || typeof IntersectionObserver === 'undefined') return;
      const observer = new IntersectionObserver(
        (entries) => {
          if (entries.some((e) => e.isIntersecting)) void this.loadComments();
        },
        { rootMargin: '600px 0px' },
      );
      observer.observe(anchor);
      onCleanup(() => observer.disconnect());
    });

    // Back to where you left off (F04), then reading progress and active time for the "read" rule and streaks (F04,
    // F08). The tracker starts once you are placed, so its first report doesn't save the top over your position.
    const session = inject(SessionStore);
    const articleEl = () => this.articleEl()?.nativeElement;
    const resume = injectResumePosition(this.article, articleEl, () => this.ownCopy() || session.isGuest());
    injectReadingTracker(this.article, this.progress, articleEl, resume.pending);
    const social = this.social;
    const follows = inject(FollowStore);
    const collections = inject(CollectionsStore);
    const hydration = inject(HydrationWindow);
    effect(() => {
      const article = this.article();
      if (!article) return;
      this.seo.apply(article);
      // A fresh copy from the API is the truth for reactions, saves, following and collections (F10, F12, F13).
      untracked(() => {
        social.absorb([article]);
        // A deleted author (null) can't be followed.
        if (article.author) follows.absorb(article.author.id, article.isFollowingAuthor);
        // The copy served while hydrating is the anonymous SSR one: no collections yet.
        if (!hydration.isOpen) collections.learnArticle(article.id, article.collectionIds);
      });
    });
    // Reaction, save and comment counts update live while the article is open (F27).
    bindLiveCounters(() => this.article());
    this.personalizeAfterHydration();
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

  /** A moderator hid or unhid the article from the "⋯" menu: the banner follows at once. */
  protected setModeration(moderation: ArticleModerationDto | null): void {
    const article = this.article();
    if (article) this.resource.value.set({ ...article, moderation });
  }

  protected openCollections(): void {
    if (this.prompt.requireAuth()) this.collectionsOpen.set(true);
  }

  /** The action bar's comment button: scroll to the comments (loading them if needed) and focus their heading. */
  protected async openComments(): Promise<void> {
    const reduce = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
    this.commentsAnchor()?.nativeElement.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' });
    const focusTitle = () => document.getElementById('comments-title')?.focus({ preventScroll: true });
    if (this.commentsSection()) {
      focusTitle();
      return;
    }
    await this.loadComments();
    // The section replaces the placeholder (and its heading) on the next render.
    if (this.commentsSection()) afterNextRender(focusTitle, { injector: this.injector });
  }

  private loadComments(): Promise<void> {
    this.commentsChunk ??= import('../comments/comments-section').then(
      ({ CommentsSection }) => this.commentsSection.set(CommentsSection),
      () => {
        this.commentsChunk = null; // the chunk didn't load (offline): scrolling back to them or the button tries again
      },
    );
    return this.commentsChunk;
  }

  /**
   * SSR renders the article anonymously and hydration reuses that response, so your reaction, save and follow state
   * and your reading progress are missing on a server-rendered page. Once the app is stable and you are signed in,
   * load it again with your token.
   */
  private personalizeAfterHydration(): void {
    if (!inject(HydrationWindow).isOpen) return;
    const session = inject(SessionStore);
    const injector = inject(Injector);
    void inject(ApplicationRef)
      .whenStable()
      .then(() => {
        const ref = effect(
          () => {
            if (!session.isAuthenticated()) return;
            untracked(() => {
              this.resource.reload();
              // Your copy has arrived once the reload ends (or fails).
              const loaded = effect(
                () => {
                  if (this.resource.isLoading()) return;
                  this.ownCopy.set(true);
                  loaded.destroy();
                },
                { injector },
              );
            });
            ref.destroy();
          },
          { injector },
        );
      });
  }

  /** The other language version replaces this one in history, so Back leaves the article instead of switching back. */
  protected switchLanguage(language: ArticleLanguage): void {
    const article = this.article();
    if (!article || language === article.language) return;
    void this.router.navigate(['/', urlLangFor(language), 'a', article.slug], { replaceUrl: true });
  }

  /** Back in history when you came from another page of the app; Home otherwise (a link, a new tab, a reload). */
  protected goBack(event: MouseEvent): void {
    // A new tab or window (a modifier key, another button) opens Home, like any link.
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    this.history.back('/');
  }

}
