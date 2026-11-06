import { ChangeDetectionStrategy, Component, ElementRef, Injector, afterNextRender, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { LanguageService } from '../../core/i18n/language.service';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { CommentComposer } from './comment-composer';
import { CommentErrors } from './comment-errors';
import { CommentItem } from './comment-item';
import { CommentThread, CommentsStore, hiddenReplies } from './comments.store';

/**
 * A top-level comment and its replies, like Facebook and LinkedIn (SPEC F11): the replies are indented by the comment's
 * avatar and gap (no connector line), and only the first shows. "↳ show N more replies" shows up to 5 more per tap and
 * "Hide replies" folds the thread back to its first reply. Your reply (to the comment or to one of its replies) is
 * written at the end of the thread and shows there at once, as live replies do, even while older ones are hidden.
 */
@Component({
  selector: 'rd-comment-thread',
  imports: [TranslocoPipe, LucideDynamicIcon, PluralPipe, CommentItem, CommentComposer],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', '[attr.data-thread]': 'thread().comment.id' },
  // One indented level: the top-level avatar (32 px) plus the gap (8 px).
  styles: `
    .replies {
      margin-inline-start: 40px;
    }
  `,
  template: `
    @let t = thread();
    <rd-comment-item [comment]="t.comment" [threadId]="t.comment.id" />

    @if (showReplies()) {
      <div
        class="replies"
        role="group"
        [attr.aria-label]="'comments.replies' | transloco: { name: t.comment.author?.displayName ?? ('comments.deletedUser' | transloco) }"
        data-replies
      >
        @for (reply of shown(); track reply.key) {
          <rd-comment-item [comment]="reply" [threadId]="t.comment.id" />
        }
        @if (hidden() > 0 || t.repliesFailed || canHide()) {
          <div class="flex flex-wrap items-center gap-x-1 text-[13px] font-semibold text-text-secondary" data-replies-pager>
            @if (hidden() > 0 || t.repliesFailed) {
              <button
                type="button"
                class="inline-flex min-h-8 items-center gap-1 rounded-md px-1 hover:bg-surface-variant hover:text-text-primary disabled:opacity-60"
                [disabled]="t.repliesLoading"
                [attr.aria-busy]="t.repliesLoading"
                data-more-replies
                (click)="showMore()"
              >
                <svg lucideIcon="CornerDownRight" [size]="15" class="rd-flip-rtl shrink-0" aria-hidden="true"></svg>
                @if (t.repliesFailed) {
                  {{ 'comments.repliesError' | transloco }}
                } @else {
                  {{ hidden() | rdPlural: 'comments.moreReplies' : lang() }}
                }
              </button>
            }
            @if (canHide()) {
              @if (hidden() > 0 || t.repliesFailed) {
                <span aria-hidden="true">·</span>
              }
              <button
                type="button"
                class="inline-flex min-h-8 items-center rounded-md px-1 hover:bg-surface-variant hover:text-text-primary"
                data-hide-replies
                (click)="hide()"
              >
                {{ 'comments.hideReplies' | transloco }}
              </button>
            }
          </div>
        }
        @for (reply of t.tail; track reply.key) {
          <rd-comment-item [comment]="reply" [threadId]="t.comment.id" />
        }
        @if (replying(); as target) {
          <rd-comment-composer
            class="py-1.5"
            [(text)]="draft"
            [label]="'comments.composer.replyLabel' | transloco"
            [placeholder]="'comments.composer.replyPlaceholder' | transloco"
            [submitLabel]="'commentBox.sendReply' | transloco"
            [error]="error()"
            [cancelable]="true"
            [cancelLabel]="'commentBox.cancelReply' | transloco"
            [autofocus]="true"
            (submitted)="send(target.targetId, $event)"
            (cancelled)="store.closeComposer()"
            data-reply-composer
          />
        }
      </div>
    }
  `,
})
export class CommentThreadView {
  protected readonly store = inject(CommentsStore);
  private readonly errors = inject(CommentErrors);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly injector = inject(Injector);
  protected readonly lang = inject(LanguageService).lang;

  readonly thread = input.required<CommentThread>();

  protected readonly draft = signal('');
  protected readonly error = signal<string | null>(null);

  /** The loaded replies that show, oldest first (the new ones at the end are `tail`). */
  protected readonly shown = computed(() => {
    const t = this.thread();
    return t.shown >= t.replies.length ? t.replies : t.replies.slice(0, t.shown);
  });
  protected readonly hidden = computed(() => hiddenReplies(this.thread()));
  /** "Hide replies" whenever more than one reply shows. */
  protected readonly canHide = computed(() => this.shown().length + this.thread().tail.length > 1);
  protected readonly replying = computed(() => {
    const target = this.store.composer();
    return target?.kind === 'reply' && target.threadId === this.thread().comment.id ? target : null;
  });
  protected readonly showReplies = computed(() => {
    const t = this.thread();
    return this.shown().length > 0 || t.tail.length > 0 || this.hidden() > 0 || t.repliesFailed || !!this.replying();
  });

  /** Your text and the reason, put back in the composer when sending failed. */
  private restore: { body: string; error: string } | null = null;

  constructor() {
    // A new reply target starts from its pre-filled @handle (or from the text that failed to send).
    effect(() => {
      const target = this.replying();
      untracked(() => {
        if (!target) return;
        this.draft.set(this.restore?.body ?? target.prefill);
        this.error.set(this.restore?.error ?? null);
        this.restore = null;
      });
    });
  }

  /** Shows up to 5 more; once none are left, the focus moves from the gone button to "Hide replies". */
  protected async showMore(): Promise<void> {
    await this.store.loadReplies(this.thread().comment.id);
    this.keepFocus('[data-more-replies]', '[data-hide-replies]');
  }

  /** Folds the thread; the focus moves from the gone button to "show N more replies". */
  protected hide(): void {
    this.store.hideReplies(this.thread().comment.id);
    this.keepFocus('[data-hide-replies]', '[data-more-replies]');
  }

  /** After the next render: when the pressed button (`from`) is gone and the focus with it, focus `to`. */
  private keepFocus(from: string, to: string): void {
    const root = this.host.nativeElement;
    const doc = root.ownerDocument;
    afterNextRender(
      () => {
        const active = doc.activeElement;
        if (root.querySelector(from) || (active && active !== doc.body && active.isConnected)) return;
        root.querySelector<HTMLElement>(to)?.focus();
      },
      { injector: this.injector },
    );
  }

  /** The composer closes and the reply shows at once (pending); a failure reopens it with your text. */
  protected async send(targetId: string, body: string): Promise<void> {
    const thread = this.thread();
    const threadId = thread.comment.id;
    this.store.closeComposer();
    try {
      await this.store.reply(threadId, targetId, body);
    } catch (error) {
      const current = this.thread();
      const target = [...current.replies, ...current.tail, ...current.folded].find((r) => r.id === targetId) ?? current.comment;
      this.restore = { body, error: this.errors.message(error) };
      this.store.openReply(threadId, target);
    }
  }
}
