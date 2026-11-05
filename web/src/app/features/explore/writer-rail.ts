import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { UserSummaryDto } from '../../core/api/models';
import { BdiText } from '../../shared/directives/bdi-text';
import { FollowButton } from '../../shared/social/follow-button';
import { Avatar } from '../../shared/ui/avatar';

/**
 * Writers in a row that scrolls sideways (F15: Explore's new writers, a field's top writers): photo, name, @handle and
 * Follow (F12; none on your own tile, guests get the sign-in prompt). The photo and name open the profile. It sits in a
 * card padded `p-4 lg:p-5` and scrolls to the card's edges.
 */
@Component({
  selector: 'rd-writer-rail',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, Avatar, FollowButton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <ul class="-mx-4 my-0 flex list-none gap-3 overflow-x-auto px-4 pb-2 pt-1 lg:-mx-5 lg:px-5" [attr.aria-label]="label()">
      @for (user of users(); track user.id) {
        <!-- Relative: the Follow button's screen-reader text stays inside the scroller, so it can't widen the page. -->
        <li class="relative w-40 shrink-0" data-writer [attr.data-user]="user.id">
          <div class="rd-card flex h-full flex-col items-center gap-2 p-3 text-center shadow-none">
            <a [routerLink]="'/@' + user.username" class="flex w-full min-w-0 flex-col items-center gap-1 rounded-md text-inherit no-underline">
              <rd-avatar [name]="user.displayName" [src]="user.avatarUrl" [size]="56" />
              <span class="mt-1 flex w-full min-w-0 items-center justify-center gap-1 text-sm font-semibold text-text-primary">
                <rd-bdi-text class="truncate" [text]="user.displayName" />
                @if (user.isVerified) {
                  <svg lucideIcon="BadgeCheck" [size]="14" class="shrink-0 text-primary" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
                }
              </span>
              <span class="block w-full truncate text-xs text-text-secondary"><bdi dir="ltr">&#64;{{ user.username }}</bdi></span>
            </a>
            <div class="mt-auto flex w-full justify-center">
              <rd-follow-button [user]="user" [initial]="user.isFollowing" />
            </div>
          </div>
        </li>
      }
    </ul>
  `,
})
export class WriterRail {
  readonly users = input.required<UserSummaryDto[]>();
  /** What the list is, for screen readers (the section's heading). */
  readonly label = input.required<string>();
}

/** The rail while it loads: four tiles. */
@Component({
  selector: 'rd-writer-rail-skeleton',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: '-mx-4 flex gap-3 overflow-hidden px-4 pb-2 pt-1 lg:-mx-5 lg:px-5', 'aria-hidden': 'true' },
  template: `
    @for (i of [1, 2, 3, 4]; track i) {
      <div class="rd-card flex w-40 shrink-0 flex-col items-center gap-2 p-3 shadow-none">
        <div class="rd-skeleton h-14 w-14 rounded-full"></div>
        <div class="rd-skeleton mt-1 h-3 w-24"></div>
        <div class="rd-skeleton h-3 w-16"></div>
        <div class="rd-skeleton mt-1 h-10 w-24 rounded-md"></div>
      </div>
    }
  `,
})
export class WriterRailSkeleton {}
