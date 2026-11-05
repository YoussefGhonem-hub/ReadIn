import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LanguageService } from '../../core/i18n/language.service';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { CommentComposer } from './comment-composer';
import { CommentErrors } from './comment-errors';
import { CommentItem } from './comment-item';
import { CommentThread, CommentsStore, hiddenReplies } from './comments.store';

/**
 * A top-level comment and its replies: one indented level with a connector line (SPEC F11). The first 2 replies come
 * with the list; "show N more replies" loads the rest. Your reply (to the comment or to one of its replies) is
 * written at the end of the thread and shows there at once.
 */
@Component({
  selector: 'rd-comment-thread',
  imports: [TranslocoPipe, PluralPipe, CommentItem, CommentComposer],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', '[attr.data-thread]': 'thread().comment.id' },
  // One indented level with a connector line under the comment's avatar (36 px).
  styles: `
    .replies {
      margin-inline-start: 17px;
      border-inline-start: 2px solid var(--rd-color-border);
      padding-inline-start: 1rem;
    }
  `,
  template: `
    @let t = thread();
    <rd-comment-item [comment]="t.comment" [threadId]="t.comment.id" />

    @if (showReplies()) {
      <div
        class="replies mb-3"
        role="group"
        [attr.aria-label]="'comments.replies' | transloco: { name: t.comment.author?.displayName ?? ('comments.deletedUser' | transloco) }"
        data-replies
      >
        @for (reply of t.replies; track reply.key) {
          <rd-comment-item [comment]="reply" [threadId]="t.comment.id" />
        }
        @if (hidden() > 0 || t.repliesFailed) {
          <button
            type="button"
            class="my-1 inline-flex min-h-9 items-center rounded-md px-2 text-sm font-semibold text-primary hover:bg-surface-variant disabled:opacity-60"
            [disabled]="t.repliesLoading"
            [attr.aria-busy]="t.repliesLoading"
            data-more-replies
            (click)="store.loadReplies(t.comment.id)"
          >
            @if (t.repliesFailed) {
              {{ 'comments.repliesError' | transloco }}
            } @else {
              {{ hidden() | rdPlural: 'comments.moreReplies' : lang() }}
            }
          </button>
        }
        @for (reply of t.tail; track reply.key) {
          <rd-comment-item [comment]="reply" [threadId]="t.comment.id" />
        }
        @if (replying(); as target) {
          <rd-comment-composer
            class="py-2"
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
  protected readonly lang = inject(LanguageService).lang;

  readonly thread = input.required<CommentThread>();

  protected readonly draft = signal('');
  protected readonly error = signal<string | null>(null);

  protected readonly hidden = computed(() => hiddenReplies(this.thread()));
  protected readonly replying = computed(() => {
    const target = this.store.composer();
    return target?.kind === 'reply' && target.threadId === this.thread().comment.id ? target : null;
  });
  protected readonly showReplies = computed(() => {
    const t = this.thread();
    return t.replies.length > 0 || t.tail.length > 0 || this.hidden() > 0 || t.repliesFailed || !!this.replying();
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

  /** The composer closes and the reply shows at once (pending); a failure reopens it with your text. */
  protected async send(targetId: string, body: string): Promise<void> {
    const thread = this.thread();
    const threadId = thread.comment.id;
    this.store.closeComposer();
    try {
      await this.store.reply(threadId, targetId, body);
    } catch (error) {
      const current = this.thread();
      const target = [...current.replies, ...current.tail].find((r) => r.id === targetId) ?? current.comment;
      this.restore = { body, error: this.errors.message(error) };
      this.store.openReply(threadId, target);
    }
  }
}
