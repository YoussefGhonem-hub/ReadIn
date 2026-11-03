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
import { DeleteCommentSheet, ReportCommentSheet } from './comment-sheets';
import { CommentThreadView } from './comment-thread';
import { CommentsStore } from './comments.store';

/** The list's top counts as "on screen" from this far above the viewport (it may sit under the sticky top bar). */
const NEAR_TOP_SLACK_PX = 160;

/**
 * Comments at the end of the reader (F11): "التعليقات (N)" with the live total, Top / Newest, the composer (or a
 * sign-in prompt for guests), threads, "more comments", and empty / loading / error states. Created lazily by the
 * reader (`@defer`, never during SSR); it loads on creation and again when the account changes. Live comment events
 * (F27) are followed from then until the reader closes; new comments that arrive while you are away from the top of
 * the list wait behind the "N تعليقات جديدة" pill.
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
    ReportCommentSheet,
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
      <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h2 id="comments-title" class="m-0 text-lg font-semibold outline-none" tabindex="-1" data-comments-title>
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

      @if (session.isAuthenticated()) {
        <rd-comment-composer
          class="mb-2"
          [(text)]="draft"
          [label]="'comments.composer.label' | transloco"
          [placeholder]="'comments.composer.placeholder' | transloco"
          [submitLabel]="'comments.composer.send' | transloco"
          [error]="postError()"
          (submitted)="post($event)"
          data-new-comment
        />
      } @else if (session.isGuest()) {
        <div class="mb-2 flex flex-wrap items-center gap-3 rounded-card border border-border bg-surface p-4" data-comments-guest>
          <p class="m-0 flex-1 text-sm text-text-secondary">{{ 'comments.guest.body' | transloco }}</p>
          <button type="button" class="rd-btn rd-btn-primary" (click)="prompt.requireAuth()">{{ 'comments.guest.signIn' | transloco }}</button>
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
              <ol class="m-0 list-none p-0">
                @for (thread of store.threads(); track thread.comment.key) {
                  <li class="border-t border-border first:border-t-0"><rd-comment-thread [thread]="thread" /></li>
                }
              </ol>
              @if (store.nextCursor()) {
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
            } @else {
              <rd-empty-state [title]="'comments.empty.title' | transloco" [message]="'comments.empty.body' | transloco" />
            }
          }
          @default {
            <div class="flex flex-col gap-5 py-3" aria-busy="true" data-comments-loading>
              @for (i of skeletonRows; track i) {
                <div class="flex gap-3" aria-hidden="true">
                  <div class="rd-skeleton h-9 w-9 shrink-0 rounded-full"></div>
                  <div class="flex flex-1 flex-col gap-2 pt-1">
                    <div class="rd-skeleton h-3 w-1/3"></div>
                    <div class="rd-skeleton h-4 w-full"></div>
                    <div class="rd-skeleton h-4 w-2/3"></div>
                  </div>
                </div>
              }
            </div>
          }
        }
      </div>

      <rd-report-comment-sheet />
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

  protected readonly draft = signal('');
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
        this.draft.set('');
        this.postError.set(null);
        this.store.setArticle(this.article());
        void this.store.load();
      });
    });

    // Live comment events of this article (F27), browser only, until the reader closes.
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

  protected showIncoming(): void {
    this.store.showIncoming();
    this.document.getElementById('comments-title')?.focus({ preventScroll: true });
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
