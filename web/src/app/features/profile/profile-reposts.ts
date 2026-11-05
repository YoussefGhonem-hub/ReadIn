import { ChangeDetectionStrategy, Component, ElementRef, Injectable, effect, inject, input, untracked, viewChild } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { Observable } from 'rxjs';
import { ArticleCardDto, CursorPage } from '../../core/api/models';
import { PostCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { PostCard } from '../feed/post-card';
import { loadMoreNearEnd } from './infinite-scroll';
import { ProfileArticlesStore } from './profile-articles.store';

/** The Reposts tab's list (F29): `GET /users/{username}/reposts`, newest repost first, in cursor pages. */
@Injectable()
export class ProfileRepostsStore extends ProfileArticlesStore {
  protected override page(username: string, query: { cursor?: string | null; limit: number }): Observable<CursorPage<ArticleCardDto>> {
    return this.api.reposts(username, query);
  }
}

/**
 * Reposts tab (F14, F29), on every profile: the articles this user reposted as post cards (F34), newest repost first,
 * each with its "أعاد نشره {name}" label (`repostedBy`), 8px apart, with infinite scroll; the empty and error states are
 * a card of their own. Loaded when the tab opens (it isn't server-rendered: the tab isn't in the URL).
 */
@Component({
  selector: 'rd-profile-reposts',
  imports: [TranslocoPipe, PostCard, PostCardSkeleton, EmptyState, ErrorState],
  providers: [ProfileRepostsStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-profile-reposts': '' },
  template: `
    @switch (store.status()) {
      @case ('error') {
        <rd-error-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [message]="'profile.reposts.loadError' | transloco" (retry)="store.load(username())" />
      }
      @case ('loaded') {
        @if (store.items().length) {
          <div class="flex flex-col gap-2">
            @for (article of store.items(); track article.id) {
              <rd-post-card [article]="article" data-repost-item />
            }
            @if (store.loadingMore()) {
              <rd-post-card-skeleton />
            }
          </div>
        } @else {
          <rd-empty-state
            class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0"
            [title]="(isMe() ? 'profile.reposts.emptyOwnTitle' : 'profile.reposts.emptyTitle') | transloco"
            [message]="(isMe() ? 'profile.reposts.emptyOwnBody' : 'profile.reposts.emptyBody') | transloco"
            data-reposts-empty
          />
        }
        @if (store.loadMoreFailed()) {
          <div class="py-4 text-center">
            <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
          </div>
        }
        @if (store.items().length > 0 && !store.nextCursor()) {
          <p class="py-6 text-center text-sm text-text-secondary" data-reposts-end>{{ 'profile.articles.end' | transloco }}</p>
        }
      }
      @default {
        <div class="flex flex-col gap-2" aria-busy="true">
          @for (i of [1, 2]; track i) {
            <rd-post-card-skeleton />
          }
        </div>
      }
    }
    <div #sentinel class="h-px" aria-hidden="true"></div>
  `,
})
export class ProfileReposts {
  protected readonly store = inject(ProfileRepostsStore);
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');

  readonly username = input.required<string>();
  readonly isMe = input(false);

  constructor() {
    effect(() => {
      const username = this.username();
      untracked(() => void this.store.load(username));
    });
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.store.loadMore(),
    );
  }
}
