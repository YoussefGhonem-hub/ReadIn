import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { MuteStore, MutedAuthorRef } from '../../core/social/mute.store';
import { provideMuteIcons } from './mute-icons';

let nextId = 0;

/**
 * "انت كاتم الكاتب ده" with "إلغاء الكتم" (F28): on the reader of a muted writer's article (a direct link still opens)
 * and on their profile. Unmuting removes the banner at once (MuteStore) and confirms with a toast; it doesn't follow
 * the writer again.
 */
@Component({
  selector: 'rd-muted-banner',
  imports: [TranslocoPipe, LucideDynamicIcon],
  providers: [provideMuteIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <section class="flex flex-wrap items-center gap-3 rounded-card bg-callout-info p-4 text-sm" role="status" [attr.aria-labelledby]="titleId" data-muted-banner>
      <svg lucideIcon="VolumeX" [size]="20" class="shrink-0 self-start text-callout-info-accent" aria-hidden="true"></svg>
      <div class="min-w-0 flex-1 basis-48">
        <h2 [id]="titleId" class="m-0 text-base font-semibold">{{ 'mute.banner.title' | transloco }}</h2>
        <p class="m-0 mt-1 text-text-secondary">{{ 'mute.banner.body' | transloco }}</p>
      </div>
      <button type="button" class="rd-btn rd-btn-outline min-h-11 shrink-0 px-4 text-sm" [disabled]="busy()" data-muted-unmute (click)="unmute()">
        {{ 'mute.banner.unmute' | transloco }}
      </button>
    </section>
  `,
})
export class MutedBanner {
  private readonly mutes = inject(MuteStore);

  /** The muted writer. */
  readonly user = input.required<MutedAuthorRef>();

  protected readonly titleId = `muted-banner-title-${nextId++}`;
  protected readonly busy = signal(false);

  protected async unmute(): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    try {
      const { id, displayName } = this.user();
      await this.mutes.unmuteAuthor({ id, displayName });
    } finally {
      this.busy.set(false);
    }
  }
}
