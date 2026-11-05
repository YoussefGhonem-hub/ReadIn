import {
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
  DestroyRef,
  ElementRef,
  Injector,
  PLATFORM_ID,
  Signal,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  linkedSignal,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { NgTemplateOutlet, isPlatformBrowser } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ContentApi } from '../../core/api/content.api';
import { ArticleCardDto, ArticlePreviewDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { injectInViewport } from '../../core/realtime/live-signals';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { FollowStore } from '../../core/social/follow.store';
import { bindLiveCounters } from '../../core/social/live-article';
import { MUTE_SCOPE, MuteStore } from '../../core/social/mute.store';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { ArticleAttachments } from '../../shared/media/article-attachments';
import { MediaViewerService } from '../../shared/media/media-viewer.service';
import { CompactNumberPipe, PluralPipe, ReadingTimePipe, RelativeTimePipe, LocalizedDatePipe, translatePlural } from '../../shared/pipes/format.pipes';
import { FollowButton } from '../../shared/social/follow-button';
import { ShareService, articleShareUrl } from '../../shared/social/share.service';
import { articleLink } from '../../shared/ui/article-link';
import { tagLink } from '../../shared/ui/tag-link';
import { Avatar } from '../../shared/ui/avatar';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { LinesSkeleton } from '../../shared/ui/skeletons';
import { ArticleMenu } from '../article/article-menu';
import { ReactionButton } from '../article/reaction-button';
import { REACTION_EMOJI, topReactions } from '../article/reactions';
import { ReactorsSheet } from '../article/reactors-sheet';
import { CommentsSection } from '../comments/comments-section';
import { CardPreview } from './card-preview';
import type { PreviewStatus } from './card-preview';
import { FeedMemory } from './feed-memory';
import { injectCardReading } from './card-reading';

/** Comments open in place under the card from this width; narrower screens get a bottom sheet (F34). */
const WIDE_QUERY = '(min-width: 768px)';
/** The sticky top bar: a card whose top is above this line is brought back into view when it collapses. */
const TOP_BAR_PX = 72;
/** A muted card folds away (and back on Undo) in this long (F28). */
const MUTE_FOLD_MS = 220;

let nextCardId = 0;

/** True while `query` matches; false during SSR. Must run in an injection context. */
function injectMediaQuery(query: string): Signal<boolean> {
  const matches = signal(false);
  if (!isPlatformBrowser(inject(PLATFORM_ID)) || typeof matchMedia !== 'function') return matches;
  const list = matchMedia(query);
  matches.set(list.matches);
  const onChange = (event: MediaQueryListEvent) => matches.set(event.matches);
  list.addEventListener('change', onChange);
  inject(DestroyRef).onDestroy(() => list.removeEventListener('change', onChange));
  return matches.asReadonly();
}

/**
 * An article as a social post (F34), in Home's feeds, profile Articles and Related articles. Top to bottom: an optional
 * label ("مقال النهارده"), the writer (avatar, name, verified badge; field · time since publishing · reading time),
 * Follow / Save / "⋯", the title (≤ 3 lines, opens the reader), the excerpt cut at 4 lines with "… اقرأ المزيد" at
 * the end of its last line, the attachments (F26) or else the cover (16:9), up to 3 tags + "+N", the counts (who
 * reacted; the comments) and the action bar: React, Comment, Share. The card is no longer one big link: the title
 * opens the reader, the text expands, an image opens the viewer, the writer opens the profile, a tag its tag page (F32).
 *
 * "Read more" grows the card in place, downwards: the first time it loads the preview (the first ~300 words as RDoc)
 * and renders it with the reader's renderer, in a lazy chunk; "Show less" folds it back and brings the card's top
 * into view if it scrolled off. Comments open under the card on wide screens and in a bottom sheet on phones, both
 * lazy. Guests get the sign-in prompt and, once signed in, come back to this card (FeedMemory). Counters are live
 * while the card is on screen (F27).
 *
 * F28: after Mute author, Show less or a field / topic mute from any "⋯" menu, the cards they concern fold away from
 * the list (MuteStore), and unfold in place on Undo; the writer's own pages keep them (MUTE_SCOPE).
 */
@Component({
  selector: 'rd-post-card',
  imports: [
    NgTemplateOutlet,
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    BdiText,
    Avatar,
    FollowButton,
    ArticleMenu,
    ArticleAttachments,
    ReactionButton,
    ReactorsSheet,
    BottomSheet,
    LinesSkeleton,
    CardPreview,
    CommentsSection,
    CompactNumberPipe,
    PluralPipe,
    ReadingTimePipe,
    RelativeTimePipe,
    LocalizedDatePipe,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'rd-card block max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0',
    style: 'scroll-margin-top: 5rem',
    '[attr.data-post-card]': 'article().id',
    '[style.display]': "away() ? 'none' : null",
    '(click)': 'onCardClick($event)',
  },
  styles: `
    /* The excerpt is cut at 4 lines. "… Read more" floats at the end of the last line, beside the text instead of over
       it: the flex parent makes the text box's height definite, so the 0-wide spacer can fill all but its last line. */
    .excerpt-box {
      display: flex;
    }
    .excerpt {
      max-height: calc(4 * 1.7em);
      overflow: hidden;
    }
    .excerpt.is-expandable {
      cursor: pointer;
    }
    .excerpt::before {
      content: '';
      float: inline-end;
      height: calc(100% - 1.7em);
    }
    .read-more {
      float: inline-end;
      clear: both;
      margin-inline-start: 0.25em;
    }
  `,
  template: `
    <article [attr.aria-labelledby]="titleId">
      @if (label(); as labelKey) {
        <div class="flex items-center gap-1.5 border-b border-border px-4 py-2 text-xs font-bold text-primary" data-card-label>
          <svg lucideIcon="Sparkles" [size]="14" aria-hidden="true"></svg>
          {{ labelKey | transloco }}
        </div>
      }

      <!-- Header: the writer, then Follow, Save and "⋯"; the meta line runs under them, so it rarely wraps -->
      <header class="grid grid-cols-[auto_minmax(0,1fr)_auto] gap-x-3 ps-4 pe-2 pt-3">
        @if (article().author; as author) {
          <!-- The name is the link for keyboards and screen readers; the photo is the same link for taps. -->
          <a [routerLink]="'/@' + author.username" class="row-span-2 mt-0.5 flex self-start rounded-full" tabindex="-1" aria-hidden="true" data-card-avatar>
            <rd-avatar [name]="author.displayName" [src]="author.avatarUrl" [size]="44" />
          </a>
          <a
            [routerLink]="'/@' + author.username"
            class="inline-flex min-w-0 max-w-full items-center gap-1 self-center justify-self-start pt-0.5 font-semibold leading-snug text-text-primary no-underline hover:underline"
            data-card-author
          >
            <span class="truncate" dir="auto">{{ author.displayName }}</span>
            @if (author.isVerified) {
              <svg lucideIcon="BadgeCheck" [size]="15" class="shrink-0 text-primary" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
            }
          </a>
        } @else {
          <!-- The author deleted their account (SPEC §9.6): no profile link and no follow. -->
          <rd-avatar class="row-span-2 mt-0.5 self-start" [generic]="true" [size]="44" />
          <span class="self-center pt-0.5 font-semibold text-text-secondary" data-deleted-author>{{ 'common.deletedUser' | transloco }}</span>
        }
        <!-- 44 px targets that don't make the name's row taller -->
        <div class="-my-2.5 flex items-center self-center">
          @if (showFollow() && article().author; as author) {
            <span data-card-follow class="contents"><rd-follow-button [user]="author" [initial]="article().isFollowingAuthor" [compact]="true" /></span>
          }
          <button
            type="button"
            class="grid h-11 w-11 place-items-center rounded-md hover:bg-surface-variant hover:text-primary"
            [class]="state().isSaved ? 'text-primary' : 'text-text-secondary'"
            data-card-save
            [attr.aria-pressed]="state().isSaved"
            [attr.aria-label]="'article.save' | transloco"
            (click)="save()"
          >
            <svg lucideIcon="Bookmark" [size]="19" [class.fill-current]="state().isSaved" aria-hidden="true"></svg>
          </button>
          <rd-article-menu [article]="article()" (topicsSheetOpen)="sheetOpen.set($event)" />
        </div>
        <p class="col-span-2 col-start-2 m-0 mt-0.5 flex flex-wrap items-center gap-x-1.5 pe-2 text-xs text-text-secondary" data-card-meta>
          <span><rd-bdi-text [text]="fieldName()" /></span>
          <span aria-hidden="true">·</span>
          <time [attr.datetime]="article().publishedAt" [attr.title]="article().publishedAt | rdDate: lang() : 'long'">{{
            article().publishedAt | rdRelativeTime: lang()
          }}</time>
          <span aria-hidden="true">·</span>
          <span>{{ article().readingTimeMinutes | rdReadingTime: lang() }}</span>
        </p>
      </header>

      <!-- Title (opens the reader) and text (expands in place) -->
      <h3 class="m-0 px-4 pt-3 text-[17px] font-semibold leading-snug" [id]="titleId" [attr.dir]="titleDir()">
        <a [routerLink]="link()" class="line-clamp-3 text-text-primary no-underline hover:underline" data-card-title>
          <rd-bdi-text [text]="article().title" />
        </a>
      </h3>

      <div #textRegion [id]="textId" class="px-4 pt-1.5 outline-none" [attr.tabindex]="expanded() ? -1 : null" data-card-text>
        @if (!expanded()) {
          @if (article().excerpt; as excerpt) {
            <div class="excerpt-box">
              <div
                #excerptEl
                class="excerpt rd-card-text"
                [class.is-expandable]="canExpand()"
                [attr.dir]="excerptDir()"
                [attr.lang]="article().language"
                data-card-excerpt
              >
                @if (canExpand()) {
                  <ng-container *ngTemplateOutlet="readMore" />
                }
                <rd-bdi-text [text]="excerpt" />
              </div>
            </div>
          } @else if (canExpand()) {
            <!-- Not backfilled yet: no text, but the article has some. -->
            <div class="rd-card-text">
              <ng-container *ngTemplateOutlet="readMore" />
            </div>
          }
        }
        <!-- The preview and the reader's renderer are their own chunk, fetched when the browser is idle. -->
        @defer (when expanded(); prefetch on idle) {
          @if (expanded()) {
            <rd-card-preview [article]="article()" [preview]="preview()" [status]="previewView()" (retry)="loadPreview()" />
          }
        } @loading {
          @if (expanded() && article().excerpt; as excerpt) {
            <p class="rd-card-text m-0" [attr.dir]="excerptDir()" [attr.lang]="article().language"><rd-bdi-text [text]="excerpt" /></p>
          }
        }
        @if (expanded()) {
          <button
            type="button"
            class="mt-1 inline-flex min-h-11 items-center gap-1 rounded-md px-1 text-sm font-semibold text-text-secondary hover:text-primary"
            [attr.aria-expanded]="true"
            [attr.aria-controls]="textId"
            data-card-show-less
            (click)="collapse()"
          >
            {{ 'feedCard.showLess' | transloco }}
            <svg lucideIcon="ChevronUp" [size]="16" aria-hidden="true"></svg>
          </button>
        }
      </div>

      <ng-template #readMore>
        <button
          type="button"
          class="read-more min-h-6 font-semibold text-text-secondary hover:text-primary hover:underline"
          [attr.aria-expanded]="false"
          [attr.aria-controls]="textId"
          [attr.aria-label]="'feedCard.readMoreLabel' | transloco: { title: article().title }"
          data-card-read-more
          (click)="expand()"
        >
          <bdi [attr.dir]="uiDir()">… {{ 'feedCard.readMore' | transloco }}</bdi>
        </button>
      </ng-template>

      <!-- Media: the attachments (F26), else the cover at full width; nothing without either -->
      @if (article().attachments; as attachments) {
        <rd-article-attachments class="mt-3 px-4" [attachments]="attachments" [article]="article()" [priority]="priorityMedia()" />
      } @else if (article().coverUrl; as cover) {
        <div class="mt-3 px-4">
          <button
            type="button"
            class="block w-full cursor-zoom-in overflow-hidden rounded-md border border-border bg-surface-variant p-0"
            [attr.aria-label]="'feedCard.openCover' | transloco: { title: article().title }"
            data-card-cover
            (click)="openCover(cover)"
          >
            <img
              [src]="cover"
              alt=""
              class="block aspect-video w-full object-cover"
              [attr.loading]="priorityMedia() ? null : 'lazy'"
              [attr.fetchpriority]="priorityMedia() ? 'high' : null"
              decoding="async"
            />
          </button>
        </div>
      }

      <!-- Tags: each opens its tag page (F32); "+N" stays plain -->
      @if (tags().length) {
        <ul class="m-0 mt-3 flex list-none flex-wrap gap-1.5 px-4" [attr.aria-label]="'feedCard.tags' | transloco" data-card-tags>
          @for (tag of tags(); track tag.slug) {
            <li class="flex">
              <a [routerLink]="tagLink(tag)" class="rd-tag rd-tag-neutral no-underline hover:text-primary hover:underline" dir="auto" [attr.data-card-tag]="tag.slug">#{{ tag.name }}</a>
            </li>
          }
          @if (moreTags() > 0) {
            <li class="rd-tag rd-tag-neutral" data-card-more-tags>
              <span aria-hidden="true">+{{ moreTags() }}</span>
              <span class="sr-only">{{ moreTags() | rdPlural: 'feedCard.moreTags' : lang() }}</span>
            </li>
          }
        </ul>
      }

      <!-- Counts: who reacted, and the comments -->
      @if (state().reactionCount > 0 || state().commentCount > 0) {
        <div class="mt-2 flex items-center justify-between gap-2 px-3 text-sm text-text-secondary" data-card-counts>
          @if (state().reactionCount > 0) {
            <button
              type="button"
              class="flex min-h-11 items-center gap-1.5 rounded-md px-1 hover:text-primary hover:underline"
              data-reactions-summary
              [attr.aria-label]="summaryLabel()"
              (click)="whoOpen.set(true)"
            >
              <span class="flex items-center" aria-hidden="true">
                @for (type of topTypes(); track type) {
                  <span class="-ms-1 text-base leading-none first:ms-0">{{ emoji[type] }}</span>
                }
              </span>
              <span aria-hidden="true" data-reaction-total>{{ state().reactionCount | rdCompactNumber: lang() }}</span>
            </button>
          } @else {
            <span></span>
          }
          @if (state().commentCount > 0) {
            <button
              type="button"
              class="min-h-11 rounded-md px-1 hover:text-primary hover:underline"
              data-card-comment-count
              [attr.aria-expanded]="commentsOpen()"
              [attr.aria-controls]="commentsId"
              (click)="toggleComments()"
            >
              {{ state().commentCount | rdPlural: 'feedCard.commentCount' : lang() : { count: (state().commentCount | rdCompactNumber: lang()) } }}
            </button>
          }
        </div>
      }

      <!-- Action bar: always visible, never leaves the feed -->
      <div
        class="relative mx-2 flex items-stretch gap-1 border-t border-border py-1"
        [class.mt-2]="state().reactionCount === 0 && state().commentCount === 0"
        role="group"
        [attr.aria-label]="'feedCard.actions' | transloco: { title: article().title }"
        data-card-actions
      >
        <rd-reaction-button [article]="article()" variant="card" />
        <button
          type="button"
          class="flex min-h-11 flex-1 items-center justify-center gap-1.5 rounded-md px-2 text-sm font-semibold text-text-secondary hover:bg-surface-variant"
          [class.text-primary]="commentsOpen()"
          data-card-comment
          [attr.aria-expanded]="commentsOpen()"
          [attr.aria-controls]="commentsId"
          (click)="comment()"
        >
          <svg lucideIcon="MessageCircle" [size]="18" aria-hidden="true"></svg>
          {{ 'feedCard.comment' | transloco }}
        </button>
        <button
          type="button"
          class="flex min-h-11 flex-1 items-center justify-center gap-1.5 rounded-md px-2 text-sm font-semibold text-text-secondary hover:bg-surface-variant"
          data-card-share
          (click)="share()"
        >
          <svg lucideIcon="Share2" [size]="18" aria-hidden="true"></svg>
          {{ 'common.share' | transloco }}
        </button>
      </div>

      <!-- Comments: in place on wide screens (F34), lazy -->
      @if (commentsOpen() && wide()) {
        <section [id]="commentsId" class="border-t border-border px-4 pb-4 pt-3" [attr.aria-labelledby]="commentsTitleId" data-card-comments>
          @defer (on immediate) {
            <rd-comments-section [article]="article()" variant="card" [titleId]="commentsTitleId" (guestSignIn)="rememberReturn(true)" />
          } @loading {
            <rd-lines-skeleton [count]="2" />
          }
        </section>
      }
    </article>

    <!-- Comments on phones: a bottom sheet, with the feed where it was behind it -->
    <rd-bottom-sheet [open]="commentsOpen() && !wide()" [labelledBy]="commentsTitleId" (closed)="commentsOpen.set(false)">
      @if (commentsOpen() && !wide()) {
        <div [id]="commentsId" data-card-comments-sheet>
          @defer (on immediate) {
            <rd-comments-section [article]="article()" variant="sheet" [titleId]="commentsTitleId" (guestSignIn)="rememberReturn(true)" />
          } @loading {
            <rd-lines-skeleton [count]="4" />
          }
        </div>
      }
    </rd-bottom-sheet>

    <rd-reactors-sheet
      [open]="whoOpen()"
      [articleId]="article().id"
      [counts]="state().reactions"
      [total]="state().reactionCount"
      (closed)="whoOpen.set(false)"
    />
  `,
})
export class PostCard {
  private readonly language = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);
  private readonly prompt = inject(AuthPromptService);
  private readonly session = inject(SessionStore);
  private readonly social = inject(ArticleSocialStore);
  private readonly follows = inject(FollowStore);
  private readonly content = inject(ContentApi);
  private readonly viewer = inject(MediaViewerService);
  private readonly sharing = inject(ShareService);
  private readonly memory = inject(FeedMemory);
  private readonly mutes = inject(MuteStore);
  private readonly muteScope = inject(MUTE_SCOPE);
  private readonly injector = inject(Injector);
  private readonly document = inject(DOCUMENT);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  protected readonly lang = this.language.lang;
  protected readonly uiDir = this.language.dir;
  protected readonly emoji = REACTION_EMOJI;
  protected readonly tagLink = tagLink;

  readonly article = input.required<ArticleCardDto>();
  /** An i18n key for the label above the card, e.g. `feedCard.todayLabel` on Home's daily article. */
  readonly label = input<string | null>(null);
  /** Loads the first attachment image (or the cover) eagerly: the first card with media in the feed. */
  readonly priorityMedia = input(false);

  private readonly uid = nextCardId++;
  protected readonly titleId = `card-title-${this.uid}`;
  protected readonly textId = `card-text-${this.uid}`;
  protected readonly commentsId = `card-comments-${this.uid}`;
  protected readonly commentsTitleId = `card-comments-title-${this.uid}`;

  protected readonly link = computed(() => articleLink(this.article()));
  protected readonly titleDir = computed(() => detectDir(this.article().title) ?? 'auto');
  protected readonly excerptDir = computed(() => detectDir(this.article().excerpt) ?? 'auto');
  protected readonly fieldName = computed(() => (this.lang() === 'ar' ? this.article().field.nameAr : this.article().field.nameEn));
  /** Defaults keep a card from an older API (without the F34 fields) working: title only, with "Read more". */
  protected readonly tags = computed(() => this.article().tags ?? []);
  protected readonly moreTags = computed(() => Math.max(0, (this.article().tagCount ?? 0) - this.tags().length));

  /** The feed values with your actions and the live counters on top. */
  protected readonly state = computed(() => this.social.state(this.article()));
  protected readonly topTypes = computed(() => topReactions(this.state().reactions));
  protected readonly summaryLabel = computed(() => {
    const lang = this.lang();
    const count = translatePlural(this.transloco, 'article.reactions.count', this.state().reactionCount, lang);
    return this.transloco.translate('article.reactions.summary', { count });
  });

  /**
   * Follow shows when you don't follow the writer and it isn't your article (guests get the sign-in prompt). Decided
   * when the card (or a fresh copy of it) arrives, so the button stays to show "Following" after a tap, and to undo.
   */
  protected readonly showFollow = linkedSignal({
    source: () => ({ article: this.article(), viewer: this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null }),
    computation: ({ article, viewer }) => {
      const author = article.author;
      if (!author || author.id === viewer) return false;
      return !viewer || !untracked(() => this.follows.isFollowing(author.id, article.isFollowingAuthor));
    },
  });

  /** The excerpt is longer than 4 lines (measured in the browser). */
  private readonly overflows = signal(false);
  /** "Read more" shows when the article has more than the excerpt, or the excerpt itself is cut. */
  protected readonly canExpand = computed(() => !this.article().excerpt || this.article().hasMore !== false || this.overflows());

  protected readonly expanded = signal(false);
  protected readonly preview = signal<ArticlePreviewDto | null>(null);
  private readonly previewStatus = signal<'idle' | PreviewStatus>('idle');
  protected readonly previewView = computed<PreviewStatus>(() => {
    const status = this.previewStatus();
    return status === 'idle' ? 'loading' : status;
  });

  protected readonly commentsOpen = signal(false);
  protected readonly whoOpen = signal(false);
  protected readonly wide = injectMediaQuery(WIDE_QUERY);

  /**
   * This card's own "كتم المواضيع" sheet is open. The sheet is drawn inside the card, so the card waits for it to close
   * before it folds away: a toggle can mute the card itself, and toggling back must stay possible (F28).
   */
  protected readonly sheetOpen = signal(false);
  /** You muted its writer, field or topic, or pressed Show less on it, in a list that applies mutes (F28). */
  private readonly muted = computed(() => !this.sheetOpen() && this.mutes.hides(this.article(), this.muteScope));
  /** Out of the list, once it folded away. */
  protected readonly away = signal(false);

  private readonly textRegion = viewChild.required<ElementRef<HTMLElement>>('textRegion');
  private readonly excerptEl = viewChild<ElementRef<HTMLElement>>('excerptEl');
  /** Set by the Comment action just before the sign-in prompt opens, read by the card's click handler. */
  private commentIntent = false;

  constructor() {
    const inView = injectInViewport();
    // Live counters only while the card is on screen (F27).
    bindLiveCounters(() => this.article(), inView);
    // An article shown whole in the card counts as read under the F04 rule (C7).
    injectCardReading(
      computed(() => {
        const preview = this.preview();
        return this.expanded() && this.previewStatus() === 'loaded' && preview?.isComplete ? { id: this.article().id, language: preview.language } : null;
      }),
      () => this.textRegion().nativeElement,
      inView,
    );

    this.measureExcerpt();
    this.foldWhenMuted();

    // A guest who signed in from this card comes back to it (with its comments open, if that's what they pressed).
    effect(() => {
      if (!this.session.isAuthenticated()) return;
      const pending = this.memory.pendingReturn();
      const id = this.article().id;
      if (pending?.articleId !== id) return;
      untracked(() => {
        const taken = this.memory.takeReturn(id);
        if (!taken) return;
        afterNextRender(
          () => {
            this.host.nativeElement.scrollIntoView?.({ block: 'center', behavior: 'auto' });
            if (taken.comments) this.commentsOpen.set(true);
          },
          { injector: this.injector },
        );
      });
    });
  }

  /** Bookmark toggle (F13); guests get the sign-in prompt. */
  protected save(): void {
    if (this.prompt.requireAuth()) void this.social.toggleSave(this.article());
  }

  /** The action bar's Comment: opens (or closes) the comments; guests get the sign-in prompt first. */
  protected comment(): void {
    this.commentIntent = true;
    if (!this.prompt.requireAuth()) return;
    this.toggleComments();
  }

  /** The count opens the comments for everyone: guests can read them, and the section offers to sign in. */
  protected toggleComments(): void {
    this.commentsOpen.update((open) => !open);
  }

  protected share(): Promise<void> {
    const article = this.article();
    return this.sharing.share({ title: article.title, url: articleShareUrl(article) });
  }

  /**
   * Taps anywhere in the card: the excerpt expands (its "Read more" button is the control for keyboards and screen
   * readers), and a tap that opened the sign-in prompt brings a guest back here after signing in.
   */
  protected onCardClick(event: Event): void {
    const target = event.target instanceof Element ? event.target : null;
    if (target?.closest('[data-card-excerpt]') && !target.closest('button, a')) this.onTextClick();
    const comments = this.commentIntent;
    this.commentIntent = false;
    if (this.session.isGuest() && this.prompt.isOpen()) this.rememberReturn(comments);
  }

  protected rememberReturn(comments: boolean): void {
    this.memory.rememberReturn(this.article().id, comments);
  }

  /** The text expands too, unless you were selecting some of it. */
  private onTextClick(): void {
    if (!this.canExpand()) return;
    const selection = this.document.defaultView?.getSelection?.();
    if (selection && !selection.isCollapsed && selection.toString().trim()) return;
    this.expand();
  }

  /** "… Read more": grows the card in place, downwards, and keeps focus in the card's text. */
  protected expand(): void {
    if (this.expanded()) return;
    this.keepInPlace(() => this.expanded.set(true), () => this.textRegion().nativeElement.focus({ preventScroll: true }));
    if (this.previewStatus() === 'idle' || this.previewStatus() === 'error') void this.loadPreview();
  }

  /** "Show less": folds the text back, brings the card's top into view if it scrolled off, focuses "Read more". */
  protected collapse(): void {
    this.expanded.set(false);
    afterNextRender(
      () => {
        const host = this.host.nativeElement;
        if (host.getBoundingClientRect().top < TOP_BAR_PX) host.scrollIntoView?.({ block: 'start', behavior: this.reducedMotion() ? 'auto' : 'smooth' });
        host.querySelector<HTMLElement>('[data-card-read-more]')?.focus({ preventScroll: true });
      },
      { injector: this.injector },
    );
  }

  /** The preview, once per card (again after a failure). The text stays where it is when it arrives. */
  async loadPreview(): Promise<void> {
    if (this.previewStatus() === 'loading') return;
    this.previewStatus.set('loading');
    const { id, language } = this.article();
    try {
      const preview = await firstValueFrom(this.content.preview(id, language));
      this.keepInPlace(() => {
        this.preview.set(preview);
        this.previewStatus.set('loaded');
      });
    } catch {
      this.previewStatus.set('error');
    }
  }

  protected openCover(url: string): void {
    const article = this.article();
    this.viewer.open({
      kind: 'images',
      title: article.title,
      items: signal([
        { key: 'cover', kind: 'image', variants: [{ width: 1200, url }], viewVariants: [{ width: 1200, url }], blurHash: null, alt: article.title, caption: null, ratio: 16 / 9 },
      ]),
      total: 1,
      startIndex: 0,
      document: null,
      share: { title: article.title, url: articleShareUrl(article) },
    });
  }

  /**
   * Runs `change`, then scrolls back by however far the card's text moved on screen, so expanding (or the preview
   * replacing the excerpt) only ever grows the card downwards and nothing above it moves.
   */
  private keepInPlace(change: () => void, after?: () => void): void {
    const region = this.textRegion().nativeElement;
    const before = region.getBoundingClientRect().top;
    change();
    afterNextRender(
      () => {
        const moved = region.getBoundingClientRect().top - before;
        if (Math.abs(moved) >= 1) this.document.defaultView?.scrollBy({ top: moved, behavior: 'instant' });
        after?.();
      },
      { injector: this.injector },
    );
  }

  /** Whether the excerpt is cut at 4 lines, kept up to date as the card resizes (fonts, width). Browser only. */
  private measureExcerpt(): void {
    if (!isPlatformBrowser(inject(PLATFORM_ID)) || typeof ResizeObserver === 'undefined') return;
    const observer = new ResizeObserver(() => {
      const el = this.excerptEl()?.nativeElement;
      if (el) this.overflows.set(el.scrollHeight > el.clientHeight + 1);
    });
    let observed: HTMLElement | null = null;
    effect(() => {
      const el = this.excerptEl()?.nativeElement ?? null;
      if (el === observed) return;
      if (observed) observer.unobserve(observed);
      observed = el;
      if (el) observer.observe(el);
    });
    inject(DestroyRef).onDestroy(() => observer.disconnect());
  }

  private reducedMotion(): boolean {
    return !!this.document.defaultView?.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  }

  /**
   * F28: the card folds away (height and opacity to 0) when it becomes muted, and unfolds in place when that is undone;
   * with reduce motion (or no Web Animations) it just goes and comes back. A card muted when it arrives is never shown.
   * Keyboard focus inside a card that leaves moves to the next card still in the list (or the one before).
   */
  private foldWhenMuted(): void {
    const host = this.host.nativeElement;
    let animation: Animation | null = null;
    let first = true;
    const stop = () => {
      animation?.cancel();
      animation = null;
      host.style.overflow = '';
    };
    const fold = (keyframes: Keyframe[], easing: string, done: () => void) => {
      host.style.overflow = 'hidden';
      const running = host.animate(keyframes, { duration: MUTE_FOLD_MS, easing });
      animation = running;
      running.onfinish = () => {
        if (animation !== running) return;
        animation = null;
        host.style.overflow = '';
        done();
      };
    };
    effect(() => {
      const muted = this.muted();
      untracked(() => {
        stop();
        const animate = !first && typeof host.animate === 'function' && !this.reducedMotion();
        first = false;
        if (muted) {
          if (this.away()) return;
          if (!animate || !host.offsetHeight) return this.leave();
          fold([{ height: `${host.offsetHeight}px`, opacity: 1 }, { height: '0px', opacity: 0 }], 'ease-in', () => this.leave());
        } else if (this.away()) {
          this.away.set(false);
          if (!animate) return;
          afterNextRender(() => fold([{ height: '0px', opacity: 0 }, { height: `${host.offsetHeight}px`, opacity: 1 }], 'ease-out', () => undefined), {
            injector: this.injector,
          });
        }
      });
    });
    inject(DestroyRef).onDestroy(stop);
  }

  /** Takes the card out of the list; focus inside it goes to the next card still shown, else the one before. */
  private leave(): void {
    const host = this.host.nativeElement;
    const hadFocus = host.contains(this.document.activeElement);
    this.away.set(true);
    if (!hadFocus) return;
    const cards = [...this.document.querySelectorAll<HTMLElement>('rd-post-card')];
    const at = cards.indexOf(host);
    const shown = (card: HTMLElement) => card !== host && card.style.display !== 'none';
    const next = cards.slice(at + 1).find(shown) ?? cards.slice(0, at).reverse().find(shown);
    next?.querySelector<HTMLElement>('[data-card-title]')?.focus();
  }
}
