import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ProfileDto } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { FollowStore } from '../../core/social/follow.store';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { CompactNumberPipe } from '../../shared/pipes/format.pipes';
import { FollowButton } from '../../shared/social/follow-button';
import { LinkIcon } from './link-icon';
import { ProfileMenu } from './profile-menu';
import { profileLinks } from './profile-links';
import { VerifiedBadge } from '../../shared/ui/verified-badge';

/**
 * `src` + `srcset` for the profile photo (a 96 px box, 112 px on large screens; the 512 px variant is only used on this
 * page, SPEC §25).
 */
export function profileAvatar(profile: Pick<ProfileDto, 'avatarUrl' | 'avatarVariants'>): { src: string; srcset: string | null } | null {
  const variants = profile.avatarVariants;
  const src = variants?.['256'] ?? profile.avatarUrl;
  if (!src) return null;
  const srcset = variants
    ? (['128', '256', '512'] as const)
        .filter((width) => variants[width])
        .map((width) => `${variants[width]} ${width}w`)
        .join(', ')
    : '';
  return { src, srcset: srcset || null };
}

/**
 * Profile header (F14), the profile's top card: a banner in the theme's colors with the photo over its lower start
 * edge, the name, verified badge, the title in full (its own direction; hidden when empty), @username (always LTR),
 * "Follows you", the bio (its own direction), the social links as a row of icons in the member's order (each named for
 * its platform, or by its label for Other; a new tab; for guests too), Follow and "⋯" (report and moderate, F22) or
 * Edit profile and Settings, and the stats row at the card's foot, where followers and following open the lists.
 */
@Component({
  selector: 'rd-profile-header',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, CompactNumberPipe, FollowButton, ProfileMenu, LinkIcon, VerifiedBadge],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'rd-card block shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0', 'data-profile-header': '' },
  styles: `
    /* Line breaks in a bio are kept. */
    .bio {
      white-space: pre-line;
    }
  `,
  template: `
    @let p = profile();
    <!-- The top card: a banner in the theme's colors (no image) under the photo's upper half; the photo sits on its
         lower start edge. -->
    <div
      class="h-20 rounded-t-[calc(var(--rd-radius-card)-1px)] bg-linear-to-b from-primary-container to-surface-variant max-sm:rounded-none sm:h-24 lg:h-28"
      aria-hidden="true"
      data-profile-banner
    ></div>
    <div class="px-4 pb-4 lg:px-6 lg:pb-5">
      <span class="-mt-12 block w-fit rounded-full bg-surface p-1 lg:-mt-16" aria-hidden="true">
        <span
          class="rd-photo grid h-24 w-24 place-items-center overflow-hidden rounded-full bg-primary-container text-4xl font-bold text-on-primary-container lg:h-28 lg:w-28"
        >
          @if (avatar(); as a) {
            <img
              [src]="a.src"
              [attr.srcset]="a.srcset"
              sizes="(min-width: 1024px) 112px, 96px"
              width="112"
              height="112"
              alt=""
              class="h-full w-full object-cover"
              referrerpolicy="no-referrer"
            />
          } @else {
            {{ initial() }}
          }
        </span>
      </span>

      <h1 class="m-0 mt-2 flex flex-wrap items-center gap-1.5 text-xl font-bold leading-tight lg:text-2xl" data-profile-name>
        <rd-bdi-text [text]="p.displayName" />
        @if (p.isVerified) {
          <rd-verified-badge [size]="20" />
        }
      </h1>
      @if (headline(); as title) {
        <!-- The title (F14) in full, wrapped, aligned with the name: the text is isolated in its own direction (SPEC §14.2). -->
        <p class="m-0 mt-1 text-[15px] leading-snug text-text-primary [overflow-wrap:anywhere]" data-profile-headline>
          <rd-bdi-text [text]="title" />
        </p>
      }
      <p class="m-0 mt-1 flex flex-wrap items-center gap-2 text-sm text-text-secondary">
        <span dir="ltr" data-profile-username>&#64;{{ p.username }}</span>
        @if (p.followsYou && !isMe()) {
          <span class="rd-tag rd-tag-neutral" data-follows-you>{{ 'profile.followsYou' | transloco }}</span>
        }
      </p>

      @if (p.bio) {
        <!-- A bio is mixed text: its own paragraph direction, from its first strong character (SPEC §14.2). -->
        <p class="bio m-0 mt-3 text-[15px] leading-relaxed" [attr.dir]="bioDir()" data-profile-bio><rd-bdi-text [text]="p.bio" /></p>
      }

      @if (links().length) {
        <!-- Icons only, in the member's order; brand icons don't mirror in RTL. -->
        <ul class="m-0 mt-1 -ms-2.5 flex list-none flex-wrap gap-1 p-0" [attr.aria-label]="'profile.links.label' | transloco" data-profile-links>
          @for (link of links(); track $index) {
            @let name = link.label ?? ('profile.links.platforms.' + link.platform | transloco);
            <li>
              <a
                [href]="link.url"
                target="_blank"
                rel="me nofollow ugc noopener noreferrer"
                class="grid h-11 w-11 place-items-center rounded-full text-text-secondary no-underline hover:bg-surface-variant hover:text-text-primary"
                [attr.aria-label]="name"
                [title]="name"
                aria-describedby="profile-links-new-tab"
                [attr.data-profile-link]="link.platform"
              >
                <rd-link-icon [platform]="link.platform" [size]="20" />
              </a>
            </li>
          }
        </ul>
        <span id="profile-links-new-tab" class="sr-only">{{ 'profile.links.newTab' | transloco }}</span>
      }

      <div class="mt-3 flex flex-wrap gap-2">
        @if (isMe()) {
          <a routerLink="/settings/profile" class="rd-btn rd-btn-outline min-h-11 gap-1.5 px-4 text-sm" data-edit-profile>
            <svg lucideIcon="Pencil" [size]="16" aria-hidden="true"></svg>
            {{ 'profile.editProfile' | transloco }}
          </a>
          <!-- Narrow screens have no side nav: Settings (and Delete account at its end) stays one tap from Profile. -->
          <a routerLink="/settings" class="rd-btn rd-btn-outline min-h-11 gap-1.5 px-4 text-sm" data-profile-settings>
            <svg lucideIcon="Settings" [size]="16" aria-hidden="true"></svg>
            {{ 'nav.settings' | transloco }}
          </a>
        } @else {
          <span class="contents" data-profile-follow><rd-follow-button [user]="p" [initial]="p.isFollowing" /></span>
          <rd-profile-menu [profile]="p" />
        }
      </div>
    </div>

    <!-- Stats: the card's bottom row, one cell each; followers and following open the lists. -->
    <ul class="m-0 flex list-none divide-x divide-border border-t border-border p-0 text-center" [attr.aria-label]="'profile.stats.label' | transloco" data-profile-stats>
      <li class="flex min-h-16 flex-1 flex-col justify-center py-2" data-stat="articles">
        <span class="text-lg font-bold leading-tight">{{ p.stats.articles | rdCompactNumber: lang() }}</span>
        <span class="text-xs text-text-secondary">{{ 'profile.stats.articles' | transloco }}</span>
      </li>
      <li class="flex-1">
        <a [routerLink]="['/@' + p.username, 'followers']" class="flex h-full min-h-16 flex-col justify-center py-2 text-inherit no-underline hover:bg-surface-variant" data-stat="followers">
          <span class="text-lg font-bold leading-tight">{{ followers() | rdCompactNumber: lang() }}</span>
          <span class="text-xs text-text-secondary">{{ 'profile.stats.followers' | transloco }}</span>
        </a>
      </li>
      <li class="flex-1">
        <a [routerLink]="['/@' + p.username, 'following']" class="flex h-full min-h-16 flex-col justify-center py-2 text-inherit no-underline hover:bg-surface-variant" data-stat="following">
          <span class="text-lg font-bold leading-tight">{{ p.stats.following | rdCompactNumber: lang() }}</span>
          <span class="text-xs text-text-secondary">{{ 'profile.stats.following' | transloco }}</span>
        </a>
      </li>
      <li class="flex min-h-16 flex-1 flex-col justify-center py-2" data-stat="reads">
        <span class="text-lg font-bold leading-tight">{{ p.stats.totalReads | rdCompactNumber: lang() }}</span>
        <span class="text-xs text-text-secondary">{{ 'profile.stats.reads' | transloco }}</span>
      </li>
    </ul>
  `,
})
export class ProfileHeader {
  private readonly follows = inject(FollowStore);
  private readonly session = inject(SessionStore);
  protected readonly lang = inject(LanguageService).lang;

  readonly profile = input.required<ProfileDto>();
  /** Your own profile (the server says so, or the session knows it before the personalized copy arrives). */
  readonly isMe = input(false);

  protected readonly avatar = computed(() => profileAvatar(this.profile()));
  protected readonly initial = computed(() => (this.profile().displayName.trim()[0] ?? '?').toUpperCase());
  protected readonly links = computed(() => profileLinks(this.profile().links));
  protected readonly headline = computed(() => this.profile().headline?.trim() || null);
  /**
   * `dir="auto"` resolved here: the browser skips the <rd-bdi-text> inside (it has its own `dir`), so it would
   * find no strong character and fall back to LTR.
   */
  protected readonly bioDir = computed(() => detectDir(this.profile().bio) ?? 'auto');
  /** Moves with your Follow / Unfollow at once (the server's count comes with the next load). */
  protected readonly followers = computed(() => {
    const p = this.profile();
    if (!this.session.isAuthenticated() || this.isMe()) return p.stats.followers;
    const now = this.follows.isFollowing(p.id, p.isFollowing);
    return Math.max(0, p.stats.followers + Number(now) - Number(p.isFollowing));
  });
}
