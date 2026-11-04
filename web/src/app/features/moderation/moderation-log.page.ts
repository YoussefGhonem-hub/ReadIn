import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { ModerationApi } from '../../core/api/moderation.api';
import { ModerationActionDto } from '../../core/api/models';
import { provideModerationIcons } from '../../shared/moderation/moderation-icons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { CursorList } from './cursor-list';
import { ModerationHeader, ModerationLogEntry } from './moderation-ui';

export const LOG_PAGE_SIZE = 30;

/** The moderation log (F22, SPEC §16), `/moderation/log`: every moderator action, newest first. Moderators only. */
@Component({
  selector: 'rd-moderation-log-page',
  imports: [TranslocoPipe, EmptyState, ErrorState, ModerationHeader, ModerationLogEntry],
  providers: [provideModerationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pt-5 lg:pt-8' },
  template: `
    <rd-moderation-header active="log" />

    <section class="mt-2" [attr.aria-label]="'moderation.log.title' | transloco" data-moderation-log>
      @switch (list.status()) {
        @case ('error') {
          <rd-error-state [message]="'moderation.loadError' | transloco" (retry)="list.load()" />
        }
        @case ('loaded') {
          @if (list.items().length) {
            <ol class="m-0 list-none divide-y divide-border p-0">
              @for (entry of list.items(); track entry.id) {
                <li><rd-moderation-log-entry [entry]="entry" /></li>
              }
            </ol>
            @if (list.hasMore()) {
              <button
                type="button"
                class="rd-btn rd-btn-outline mt-3 w-full"
                [disabled]="list.loadingMore()"
                [attr.aria-busy]="list.loadingMore()"
                data-log-more
                (click)="list.loadMore()"
              >
                {{ (list.moreFailed() ? 'common.retry' : 'moderation.more') | transloco }}
              </button>
            }
          } @else {
            <rd-empty-state [title]="'moderation.empty.log.title' | transloco" [message]="'moderation.empty.log.body' | transloco" data-log-empty />
          }
        }
        @default {
          <div class="flex flex-col gap-4 py-3" aria-busy="true" data-log-loading>
            @for (i of skeletons; track i) {
              <div class="flex gap-3" aria-hidden="true">
                <div class="rd-skeleton h-9 w-9 shrink-0 rounded-full"></div>
                <div class="flex flex-1 flex-col gap-2 pt-1">
                  <div class="rd-skeleton h-4 w-2/3"></div>
                  <div class="rd-skeleton h-3 w-1/3"></div>
                </div>
              </div>
            }
          </div>
        }
      }
    </section>
  `,
})
export class ModerationLogPage {
  private readonly api = inject(ModerationApi);
  private readonly transloco = inject(TranslocoService);
  protected readonly skeletons = [1, 2, 3, 4];

  protected readonly list = new CursorList<ModerationActionDto>(
    (cursor) => this.api.log({ cursor, limit: LOG_PAGE_SIZE }),
    (entry) => entry.id,
  );

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('moderation.log.title')} — ReadIn`);
    void this.list.load();
  }
}
