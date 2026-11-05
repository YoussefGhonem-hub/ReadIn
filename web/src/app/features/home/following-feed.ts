import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, afterNextRender, computed, effect, inject, untracked, viewChild } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { FollowStore } from '../../core/social/follow.store';
import { MUTE_SCOPE, MuteStore } from '../../core/social/mute.store';
import { FollowButton } from '../../shared/social/follow-button';
import { UserRow } from '../../shared/social/user-row';
import { PostCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { PostCard } from '../feed/post-card';
import { HomeStore } from './home.store';

/** Writers to follow (F12): verified first, then by followers; each with a Follow button. */
@Component({
  selector: 'rd-suggested-writers',
  imports: [TranslocoPipe, UserRow, FollowButton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'rd-card block p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5' },
  template: `
    <section aria-labelledby="suggested-writers-title" data-suggested-writers>
      <h2 id="suggested-writers-title" class="m-0 mb-1 text-base font-semibold">{{ 'home.following.suggested' | transloco }}</h2>
      @switch (store.suggestedStatus()) {
        @case ('error') {
          <div class="flex flex-wrap items-center justify-between gap-2 py-2 text-sm text-text-secondary" role="alert">
            {{ 'home.following.suggestedError' | transloco }}
            <button type="button" class="rd-btn rd-btn-outline min-h-11 px-3 text-sm" (click)="store.loadSuggested()">{{ 'common.retry' | transloco }}</button>
          </div>
        }
        @case ('loaded') {
          <ul class="m-0 list-none divide-y divide-border p-0">
            @for (user of store.suggested(); track user.id) {
              <li data-suggested-writer [attr.data-user]="user.id">
                <rd-user-row [user]="user" [bio]="user.bio" [note]="user.followsYou ? ('home.following.followsYou' | transloco) : null">
                  <rd-follow-button [user]="user" [initial]="user.isFollowing" />
                </rd-user-row>
              </li>
            } @empty {
              <li class="py-4 text-center text-sm text-text-secondary">{{ 'home.following.suggestedEmpty' | transloco }}</li>
            }
          </ul>
        }
        @default {
          <div class="flex flex-col gap-3 py-2" aria-busy="true">
            @for (i of [1, 2, 3]; track i) {
              <div class="flex items-center gap-3" aria-hidden="true">
                <div class="rd-skeleton h-10 w-10 rounded-full"></div>
                <div class="flex flex-1 flex-col gap-2"><div class="rd-skeleton h-3 w-1/2"></div><div class="rd-skeleton h-3 w-2/3"></div></div>
              </div>
            }
          </div>
        }
      }
    </section>
  `,
})
export class SuggestedWriters {
  protected readonly store = inject(HomeStore);
}

/**
 * Home → Following (F12): published articles by people you follow, newest first, with infinite scroll. When it is
 * empty it suggests writers to follow; once you follow one, "Show my feed" loads their articles.
 */
@Component({
  selector: 'rd-following-feed',
  imports: [TranslocoPipe, PostCard, PostCardSkeleton, EmptyState, ErrorState, SuggestedWriters],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @switch (store.followingStatus()) {
      @case ('error') {
        <rd-error-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [message]="'home.following.error' | transloco" (retry)="store.loadFollowing()" />
      }
      @case ('loaded') {
        <!-- Muted cards fold away but stay in the list (Undo puts them back): count the ones still shown (F28). -->
        @if (anyShown() || store.followingCursor()) {
          <div class="flex flex-col gap-2" data-feed>
            @for (article of store.following(); track article.id) {
              <rd-post-card [article]="article" />
            }
            @if (store.followingLoadingMore()) {
              <rd-post-card-skeleton />
            }
          </div>
        } @else {
          <div class="flex flex-col gap-2 pb-6" data-following-empty>
            <rd-empty-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [title]="'home.following.title' | transloco" [message]="'home.following.body' | transloco" />
            <rd-suggested-writers />
            @if (followedSomeone()) {
              <button type="button" class="rd-btn rd-btn-primary w-full" data-following-refresh (click)="store.loadFollowing()">
                {{ 'home.following.showFeed' | transloco }}
              </button>
            }
          </div>
        }
        @if (store.followingMoreFailed()) {
          <div class="py-4 text-center">
            <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMoreFollowing()">{{ 'common.retry' | transloco }}</button>
          </div>
        }
        @if (anyShown() && !store.followingCursor()) {
          <p class="py-6 text-center text-sm text-text-secondary">{{ 'home.endOfFeed' | transloco }}</p>
        }
      }
      @default {
        <div class="flex flex-col gap-2">
          @for (i of [1, 2, 3]; track i) {
            <rd-post-card-skeleton />
          }
        </div>
      }
    }
    <div #sentinel class="h-px" aria-hidden="true"></div>
  `,
})
export class FollowingFeed {
  protected readonly store = inject(HomeStore);
  private readonly follows = inject(FollowStore);
  private readonly sentinel = viewChild.required<ElementRef<HTMLElement>>('sentinel');

  /** True once you follow one of the suggested writers (optimistically). */
  protected readonly followedSomeone = computed(() => this.store.suggested().some((u) => this.follows.isFollowing(u.id, u.isFollowing)));
  private readonly mutes = inject(MuteStore);
  private readonly muteScope = inject(MUTE_SCOPE);
  /** A card of the feed is still shown (not muted away, F28). */
  protected readonly anyShown = computed(() => this.mutes.anyShown(this.store.following(), this.muteScope));

  constructor() {
    // A feed emptied by mutes shows the empty state, which suggests writers: load them if the feed came with articles.
    effect(() => {
      if (this.store.followingStatus() !== 'loaded' || this.anyShown() || this.store.followingCursor()) return;
      if (untracked(this.store.suggestedStatus) === 'idle') untracked(() => void this.store.loadSuggested());
    });
    const destroyRef = inject(DestroyRef);
    afterNextRender(() => {
      const observer = new IntersectionObserver(
        (entries) => {
          if (entries.some((e) => e.isIntersecting)) void this.store.loadMoreFollowing();
        },
        { rootMargin: '600px 0px' },
      );
      observer.observe(this.sentinel().nativeElement);
      destroyRef.onDestroy(() => observer.disconnect());
    });
  }
}
