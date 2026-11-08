import { ChangeDetectionStrategy, Component, effect, inject, input, output, signal, untracked } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { BlockStore, BlockedPersonRef } from '../../core/social/block.store';
import { BottomSheet } from '../ui/bottom-sheet';

/**
 * "هل تريد حظر @username؟" (F36): what a block does, then «حظر» in the error color or «إلغاء». Blocking goes through the
 * BlockStore (the content leaves the lists at once; the toast has Undo). Guests get the sign-in prompt instead.
 */
@Component({
  selector: 'rd-block-dialog',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="!!person()" role="alertdialog" labelledBy="block-dialog-title" describedBy="block-dialog-body" [dismissible]="!busy()" (closed)="close()">
      @if (person(); as p) {
        <div class="flex flex-col gap-3 pt-1" data-block-dialog>
          <h2 id="block-dialog-title" class="m-0 pe-10 text-xl font-semibold">
            {{ 'block.dialog.title' | transloco }} <bdi dir="ltr">&#64;{{ p.username }}</bdi>{{ 'block.dialog.titleEnd' | transloco }}
          </h2>
          <p id="block-dialog-body" class="m-0 text-sm text-text-secondary">{{ 'block.dialog.body' | transloco }}</p>
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="close()">{{ 'common.cancel' | transloco }}</button>
            <button type="button" class="rd-btn flex-1 bg-error text-on-error" [disabled]="busy()" [attr.aria-busy]="busy()" (click)="confirm()" data-block-confirm>
              @if (busy()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ 'block.dialog.confirm' | transloco }}
            </button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class BlockDialog {
  private readonly blocks = inject(BlockStore);
  private readonly prompt = inject(AuthPromptService);

  /** Opens the dialog for this person; null closes it. */
  readonly person = input<BlockedPersonRef | null>(null);
  readonly closed = output<void>();
  /** The block was saved. */
  readonly blocked = output<BlockedPersonRef>();

  protected readonly busy = signal(false);

  constructor() {
    effect(() => {
      const person = this.person();
      untracked(() => {
        this.busy.set(false);
        if (person && !this.prompt.requireAuth()) this.closed.emit();
      });
    });
  }

  protected close(): void {
    if (!this.busy()) this.closed.emit();
  }

  protected async confirm(): Promise<void> {
    const person = this.person();
    if (!person || this.busy()) return;
    this.busy.set(true);
    const saved = await this.blocks.block(person);
    this.busy.set(false);
    if (saved) this.blocked.emit(person);
    this.closed.emit();
  }
}
