import { ChangeDetectionStrategy, Component, ElementRef, computed, input, viewChild } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { PostCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { PostCard } from '../feed/post-card';
import { loadMoreNearEnd } from '../profile/infinite-scroll';
import { CardPages } from './card-pages';

/**
 * A {@link CardPages} list as post cards (F34): skeletons while the first page loads, an error with Retry, the empty
 * state (content inside the element goes under its message), infinite scroll with Retry when a page fails, and a line
 * once everything is shown.
 */
@Component({
  selector: 'rd-card-pages-list',
  imports: [TranslocoPipe, PostCard, PostCardSkeleton, EmptyState, ErrorState],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @let list = pages();
    @switch (list.status()) {
      @case ('loaded') {
        @if (list.items().length) {
          <div class="flex flex-col gap-3" data-card-list>
            @for (article of list.items(); track article.id) {
              <rd-post-card [article]="article" [priorityMedia]="article.id === firstMediaId()" />
            }
            @if (list.loadingMore()) {
              <rd-post-card-skeleton />
            }
          </div>
          @if (list.loadMoreFailed()) {
            <div class="py-4 text-center">
              <button type="button" class="rd-btn rd-btn-outline" data-load-more-retry (click)="list.loadMore()">{{ 'common.retry' | transloco }}</button>
            </div>
          }
          @if (list.nextCursor()) {
            <!-- Only under a loaded list: one on screen beside the skeletons would load page 2 right away. -->
            <div #sentinel class="h-px" aria-hidden="true"></div>
          } @else {
            <p class="m-0 py-6 text-center text-sm text-text-secondary" data-list-end>{{ endText() }}</p>
          }
        } @else {
          <rd-empty-state [title]="emptyTitle()" [message]="emptyBody()" data-list-empty>
            <ng-content />
          </rd-empty-state>
        }
      }
      @case ('error') {
        <rd-error-state [message]="errorText()" (retry)="list.load()" />
      }
      @default {
        <div class="flex flex-col gap-3" aria-busy="true" data-list-loading>
          @for (i of [1, 2, 3]; track i) {
            <rd-post-card-skeleton />
          }
        </div>
      }
    }
  `,
})
export class CardPagesList {
  readonly pages = input.required<CardPages>();
  readonly endText = input.required<string>();
  readonly emptyTitle = input.required<string>();
  readonly emptyBody = input<string | null>(null);
  readonly errorText = input<string | null>(null);

  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');

  /** The first card with an image loads it eagerly (as on Home). */
  protected readonly firstMediaId = computed(() => this.pages().items().find((a) => a.attachments || a.coverUrl)?.id ?? null);

  constructor() {
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.pages().loadMore(),
    );
  }
}
