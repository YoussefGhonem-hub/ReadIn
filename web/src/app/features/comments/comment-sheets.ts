import { ChangeDetectionStrategy, Component, computed, effect, inject, signal, untracked } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { CommentErrors } from './comment-errors';
import { CommentsStore } from './comments.store';

/** "Delete this comment?" for your own comment, or as a moderator (audited). */
@Component({
  selector: 'rd-delete-comment-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet
      [open]="open()"
      role="alertdialog"
      labelledBy="delete-comment-title"
      describedBy="delete-comment-body"
      [dismissible]="!busy()"
      (closed)="close()"
    >
      <div class="flex flex-col gap-3 pt-1" data-delete-comment-sheet>
        <h2 id="delete-comment-title" class="m-0 pe-10 text-xl font-semibold">
          {{ (asModerator() ? 'comments.deleteSheet.moderatorTitle' : 'comments.deleteSheet.title') | transloco }}
        </h2>
        <p id="delete-comment-body" class="m-0 text-sm text-text-secondary">
          {{ (asModerator() ? 'comments.deleteSheet.moderatorBody' : 'comments.deleteSheet.body') | transloco }}
        </p>
        @if (error()) {
          <p class="rd-alert rd-alert-error m-0" role="alert">{{ error() }}</p>
        }
        <div class="mt-2 flex gap-2">
          <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="close()">{{ 'common.cancel' | transloco }}</button>
          <button type="button" class="rd-btn flex-1 bg-error text-on-error" [disabled]="busy()" [attr.aria-busy]="busy()" data-confirm-delete (click)="confirm()">
            @if (busy()) {
              <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
            }
            {{ 'comments.delete' | transloco }}
          </button>
        </div>
      </div>
    </rd-bottom-sheet>
  `,
})
export class DeleteCommentSheet {
  private readonly store = inject(CommentsStore);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(CommentErrors);

  protected readonly target = computed(() => {
    const dialog = this.store.dialog();
    return dialog?.kind === 'delete' || dialog?.kind === 'moderatorDelete' ? dialog : null;
  });
  protected readonly open = computed(() => this.target() !== null);
  protected readonly asModerator = computed(() => this.target()?.kind === 'moderatorDelete');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);

  constructor() {
    effect(() => {
      this.target();
      untracked(() => this.error.set(null));
    });
  }

  protected close(): void {
    if (!this.busy()) this.store.closeDialog();
  }

  protected async confirm(): Promise<void> {
    const target = this.target();
    if (!target || this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      if (target.kind === 'moderatorDelete') {
        await this.store.moderate(target.comment.id, 'delete');
        this.toasts.success(this.transloco.translate('comments.moderation.deleted'));
      } else {
        await this.store.remove(target.comment.id);
      }
      this.busy.set(false);
      this.store.closeDialog();
    } catch (error) {
      this.error.set(this.errors.message(error));
    } finally {
      this.busy.set(false);
    }
  }
}
