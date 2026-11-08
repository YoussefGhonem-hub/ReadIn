import { ChangeDetectionStrategy, Component, inject, input, output, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { BlockStore, BlockedPersonRef } from '../../core/social/block.store';
import { BLOCK_ICON } from './block-icons';

/**
 * What the blocker sees on a direct link to someone they blocked (F36, `403 block.blocked`, or a block made on the
 * page): «هذا الحساب غير متاح» / «هذا المحتوى غير متاح», with «إلغاء الحظر». The blocked person never sees this: for them
 * the API answers 404, as if the content were deleted.
 */
@Component({
  selector: 'rd-blocked-state',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col items-center gap-2 px-6 py-12 text-center', role: 'status', '[attr.data-blocked-state]': 'kind()' },
  template: `
    <span class="mb-2 grid h-14 w-14 place-items-center rounded-card bg-surface-variant text-text-secondary" aria-hidden="true">
      <svg [lucideIcon]="icon" [size]="26"></svg>
    </span>
    <h3 class="m-0 text-lg font-semibold">{{ 'block.unavailable.' + kind() | transloco }}</h3>
    <p class="m-0 max-w-sm text-sm text-text-secondary">
      {{ 'block.unavailable.youBlocked' | transloco }} <bdi dir="ltr">&#64;{{ user().username }}</bdi>
    </p>
    <div class="mt-3 flex flex-wrap justify-center gap-2">
      <button type="button" class="rd-btn rd-btn-primary" [disabled]="busy()" [attr.aria-busy]="busy()" (click)="unblock()" data-unblock>{{ 'block.unblock' | transloco }}</button>
      <a routerLink="/" class="rd-btn rd-btn-outline">{{ 'comingSoon.backHome' | transloco }}</a>
    </div>
  `,
})
export class BlockedState {
  private readonly blocks = inject(BlockStore);

  readonly kind = input<'account' | 'content'>('content');
  readonly user = input.required<BlockedPersonRef>();
  /** Unblocked: the page loads again. */
  readonly unblocked = output<void>();

  protected readonly icon = BLOCK_ICON.UserRoundX;
  protected readonly busy = signal(false);

  protected async unblock(): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    const done = await this.blocks.unblock(this.user());
    this.busy.set(false);
    if (done) this.unblocked.emit();
  }
}
