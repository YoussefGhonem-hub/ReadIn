import {
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
  ElementRef,
  PLATFORM_ID,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Dir } from '@angular/cdk/bidi';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleCardDto, CommentSort } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { RealtimeService } from '../../core/realtime/realtime.service';
import { translatePlural } from '../../shared/pipes/format.pipes';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { CommentComposer } from './comment-composer';
import { CommentErrors } from './comment-errors';
import { provideCommentIcons } from './comment-icons';
import { ReportSheet, ReportTarget } from '../../shared/moderation/report-sheet';
import { DeleteCommentSheet } from './comment-sheets';
import { CommentThreadView } from './comment-thread';
import { CommentsStore } from './comments.store';
import { FeedMemory } from '../feed/feed-memory';

/** Where the section is shown: the reader, right under the article, a post card's inline section (F34) or its bottom sheet. */
export type CommentsVariant = 'reader' | 'card' | 'sheet';

/** A post card's inline section shows this many threads until "Show all comments" (F34). */
export const CARD_PREVIEW_THREADS = 2;

/** The list's top counts as "on screen" from this far above the viewport (it may sit under the sticky top bar). */
const NEAR_TOP_SLACK_PX = 160;

/**
 * Comments in the reader, right under the article (F11): "التعليقات (N)" with the live total, Top / Newest, the
 * composer (or a sign-in prompt for guests), the first 5 threads, "Show more comments" (10 more a tap), and empty /
 * loading / error states. Created lazily by the reader (`@defer`, never during SSR); it loads on creation and again
 * when the account changes. Live comment events (F27) are followed from then until the reader closes; new comments
 * that arrive while you are away from the top of the list wait behind the "N تعليقات جديدة" pill.
 *
 * A post card (F34) shows it too, while its comments are open: `card` is the inline section of wide screens (the
 * composer and the top 2 threads, then "Show all comments" lists the rest in place), `sheet` the full section in a
 * bottom sheet on phones. There the unsent text is kept per article and account (FeedMemory), so it survives closing
 * the comments, leaving the page and refreshing the feed.
 */
@Component({
  selector: 'rd-comments-section',
  imports: [
    Dir,
    TranslocoPipe,
    LucideDynamicIcon,
    Segmented,
    EmptyState,
    ErrorState,
    CommentComposer,
    CommentThreadView,
    ReportSheet,
    DeleteCommentSheet,
  ],
  providers: [CommentsStore, provideCommentIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  // The pill floats under the sticky top bar without taking space in the list.
  styles: `
    .pill-rail {
      height: 0;
    }
    .comments-list {
      scroll-margin-top: 6rem;
    }
  `,
  template: `
    <div [dir]="language.dir()" data-comments>
      @if (variant() === 'card') {
        <h2 [id]="titleId()" class="sr-only" tabindex="-1" data-comments-title>{{ 'comments.title' | transloco: { count: store.total() } }}</h2>
      } @else {
        <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
          <h2 [id]="titleId()" class="m-0 text-lg font-semibold outline-none" tabindex="-1" data-comments-title>
            {{ 'comments.title' | transloco: { count: store.total() } }}
          </h2>
          <rd-segmented
            class="min-w-36"
            [options]="sortOptions()"
            [value]="store.sort()"
            (valueChange)="setSort($event)"
            [label]="'comments.sort.label' | transloco"
            data-comments-sort
          />
        </div>
      }

      @if (session.isAuthenticated()) {
        <rd-comment-composer
          class="mb-2"
          [(text)]="draft"
          [label]="'comments.composer.label' | transloco"
          [placeholder]="'commentBox.placeholder' | transloco"
          [submitLabel]="'commentBox.send' | transloco"
          [error]="postError()"
          (submitted)="post($event)"
          data-new-comment
        />
      } @else if (session.isGuest()) {
        <div class="mb-2 flex flex-wrap items-center gap-3 rounded-card border border-border bg-surface p-4" data-comments-guest>
          <p class="m-0 flex-1 text-sm text-text-secondary">{{ 'comments.guest.body' | transloco }}</p>
          <button type="button" class="rd-btn rd-btn-primary" (click)="signIn()">{{ 'comments.guest.signIn' | transloco }}</button>
        </div>
      }

      <!-- New comments while you are away from the top (F27) -->
      <div class="pill-rail pointer-events-none sticky top-20 z-20 flex justify-center" aria-live="polite">
        @if (store.incomingCount() > 0) {
          <button
            type="button"
            class="pointer-events-auto mt-1 inline-flex min-h-10 items-center gap-1.5 rounded-chip bg-primary px-4 text-sm font-semibold text-on-primary shadow-raised"
            data-new-comments
            (click)="showIncoming()"
          >
            <svg lucideIcon="ArrowUp" [size]="16" aria-hidden="true"></svg>{{ incomingLabel() }}
          </button>
        }
      </div>

      <div #list class="comments-list" data-comments-list>
        @switch (store.status()) {
          @case ('error') {
            <rd-error-state [message]="'comments.loadError' | transloco" (retry)="store.load()" />
          }
          @case ('loaded') {
            @if (store.threads().length) {
              <!-- Compact threads, 8 px apart (each row keeps 6 px above and below its bubble) -->
              <ol class="m-0 flex list-none flex-col gap-2 p-0">
                @for (thread of visibleThreads(); track thread.comment.key) {
                  <li><rd-comment-thread [thread]="thread" /></li>
                }
              </ol>
              @if (collapsed()) {
                @if (store.threads().length > previewThreads || store.nextCursor()) {
                  <button type="button" class="rd-btn rd-btn-ghost mt-1 w-full text-primary" data-show-all-comments (click)="showAll()">
                    {{ 'feedCard.showAllComments' | transloco }}
                  </button>
                }
              } @else if (store.nextCursor()) {
                <button
                  type="button"
                  class="rd-btn rd-btn-outline mt-3 w-full"
                  [disabled]="store.loadingMore()"
                  [attr.aria-busy]="store.loadingMore()"
                  data-more-comments
                  (click)="store.loadMore()"
                >
                  {{ (store.moreFailed() ? 'common.retry' : 'comments.more') | transloco }}
                </button>
              }
            } @else if (variant() === 'card') {
              <p class="m-0 py-3 text-center text-sm text-text-secondary" data-comments-empty>{{ 'comments.empty.body' | transloco }}</p>
            } @else {
              <rd-empty-state [title]="'comments.empty.title' | transloco" [message]="'comments.empty.body' | transloco" />
            }
          }
          @default {
            <div class="flex flex-col gap-4 py-2" aria-busy="true" data-comments-loading>
              @for (i of skeletonRows; track i) {
                <div class="flex gap-2" aria-hidden="true">
                  <div class="rd-skeleton h-8 w-8 shrink-0 rounded-full"></div>
                  <div class="flex flex-1 flex-col gap-2 pt-1">
                    <div class="rd-skeleton h-3 w-1/3"></div>
                    <div class="rd-skeleton h-3.5 w-full"></div>
                    <div class="rd-skeleton h-3.5 w-2/3"></div>
                  </div>
                </div>
              }
            </div>
          }
        }
      </div>

      <rd-report-sheet [target]="reportTarget()" (closed)="store.closeDialog()" />
      <rd-delete-comment-sheet />
    </div>
  `,
})
export class CommentsSection {
  protected readonly store = inject(CommentsStore);
  protected readonly session = inject(SessionStore);
  protected readonly prompt = inject(AuthPromptService);
  protected readonly language = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(CommentErrors);
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  readonly article = input.required<ArticleCardDto>();
  readonly variant = input<CommentsVariant>('reader');
  /** The heading's id (`aria-labelledby` of a sheet; unique per card). */
  readonly titleId = input('comments-title');
  /** A guest pressed "sign in to comment" (the sign-in prompt is open). */
  readonly guestSignIn = output<void>();

  protected readonly draft = signal('');
  protected readonly previewThreads = CARD_PREVIEW_THREADS;
  /** The card's inline section, after "Show all comments". */
  protected readonly expandedAll = signal(false);
  protected readonly collapsed = computed(() => this.variant() === 'card' && !this.expandedAll());
  protected readonly visibleThreads = computed(() => (this.collapsed() ? this.store.threads().slice(0, CARD_PREVIEW_THREADS) : this.store.threads()));
  private readonly memory = inject(FeedMemory);
  protected readonly postError = signal<string | null>(null);
  protected readonly skeletonRows = [1, 2, 3];
  private readonly list = viewChild<ElementRef<HTMLElement>>('list');

  protected readonly sortOptions = computed<SegmentOption<CommentSort>[]>(() => {
    this.language.lang(); // re-translate on UI language change
    return [
      { value: 'top', label: this.transloco.translate('comments.sort.top') },
      { value: 'new', label: this.transloco.translate('comments.sort.new') },
    ];
  });
  /** The comment being reported, in the shared report sheet (F22). */
  protected readonly reportTarget = computed<ReportTarget | null>(() => {
    const dialog = this.store.dialog();
    return dialog?.kind === 'report' ? { type: 'comment', id: dialog.comment.id } : null;
  });
  protected readonly incomingLabel = computed(() =>
    translatePlural(this.transloco, 'comments.newComments', this.store.incomingCount(), this.language.lang()),
  );

  constructor() {
    this.store.nearTop = () => this.isListTopOnScreen();

    effect(() => {
      const article = this.article();
      untracked(() => this.store.setArticle(article));
    });

    // Load once the session is known (your likes and menus are personal), and again for another account or article.
    const userId = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null));
    const articleId = computed(() => this.article().id);
    let loadedFor: string | null = null;
    effect(() => {
      if (!this.isBrowser || !this.session.isResolved()) return;
      const key = `${userId() ?? 'guest'}|${articleId()}`;
      untracked(() => {
        if (key === loadedFor) return;
        loadedFor = key;
        // A card's unsent text waits for you (F34); the reader starts empty.
        this.draft.set(this.variant() === 'reader' ? '' : this.memory.draft(key));
        this.postError.set(null);
        this.store.setArticle(this.article());
        void this.store.load();
      });
    });

    effect(() => {
      const text = this.draft();
      if (loadedFor && untracked(this.variant) !== 'reader') this.memory.setDraft(loadedFor, text);
    });

    // Live comment events of this article (F27), browser only, until the reader closes (or the card's comments do).
    const realtime = inject(RealtimeService);
    effect((onCleanup) => {
      const id = articleId();
      if (!this.isBrowser) return;
      onCleanup(realtime.watchCommentEvents(id, (event) => void this.store.applyEvent(event)));
    });
  }

  protected setSort(sort: CommentSort): void {
    this.store.setSort(sort);
  }

  /** The comment shows at once (pending) and the field empties; a failure puts your text back with the reason. */
  protected async post(body: string): Promise<void> {
    this.postError.set(null);
    this.draft.set('');
    try {
      await this.store.post(body);
    } catch (error) {
      if (!this.draft()) this.draft.set(body);
      this.postError.set(this.errors.message(error));
    }
  }

  protected signIn(): void {
    this.prompt.requireAuth();
    this.guestSignIn.emit();
  }

  /** "Show all comments": the threads loaded so far, then the rest page by page. */
  protected showAll(): void {
    this.expandedAll.set(true);
    if (this.store.threads().length <= CARD_PREVIEW_THREADS) void this.store.loadMore();
  }

  protected showIncoming(): void {
    this.store.showIncoming();
    if (this.collapsed()) this.expandedAll.set(true);
    this.document.getElementById(this.titleId())?.focus({ preventScroll: true });
    const reduce = this.document.defaultView?.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
    this.list()?.nativeElement.scrollIntoView?.({ behavior: reduce ? 'auto' : 'smooth', block: 'start' });
  }

  private isListTopOnScreen(): boolean {
    const el = this.list()?.nativeElement;
    const view = this.document.defaultView;
    if (!el || !view) return true;
    const top = el.getBoundingClientRect().top;
    return top > -NEAR_TOP_SLACK_PX && top < view.innerHeight;
  }
}
