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
import { PROFILE_ICONS } from './profile-icons';
import { profileLinks } from './profile-links';

/** `src` + `srcset` for the profile photo (80 px box; the 512 px variant is only used on this page, SPEC §25). */
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
 * Profile header (F14): photo, name, verified badge, @username (always LTR), "Follows you", Follow or Edit profile, the
 * bio (its own direction), links (open in a new tab) and the stats row, where followers and following open the lists.
 */
@Component({
  selector: 'rd-profile-header',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, CompactNumberPipe, FollowButton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-profile-header': '' },
  styles: `
    /* Line breaks in a bio are kept. */
    .bio {
      white-space: pre-line;
    }
  `,
  template: `
    @let p = profile();
    <div class="flex items-start gap-4">
      <span
        class="rd-photo grid h-20 w-20 shrink-0 place-items-center overflow-hidden rounded-full bg-primary-container text-3xl font-bold text-on-primary-container"
        aria-hidden="true"
      >
        @if (avatar(); as a) {
          <img [src]="a.src" [attr.srcset]="a.srcset" sizes="80px" width="80" height="80" alt="" class="h-full w-full object-cover" referrerpolicy="no-referrer" />
        } @else {
          {{ initial() }}
        }
      </span>
      <div class="min-w-0 flex-1">
        <h1 class="m-0 flex flex-wrap items-center gap-1.5 text-2xl font-bold leading-tight" data-profile-name>
          <rd-bdi-text [text]="p.displayName" />
          @if (p.isVerified) {
            <svg lucideIcon="BadgeCheck" [size]="20" class="shrink-0 text-primary" role="img" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
          }
        </h1>
        <p class="m-0 mt-1 flex flex-wrap items-center gap-2 text-sm text-text-secondary">
          <span dir="ltr" data-profile-username>&#64;{{ p.username }}</span>
          @if (p.followsYou && !isMe()) {
            <span class="rd-tag rd-tag-neutral" data-follows-you>{{ 'profile.followsYou' | transloco }}</span>
          }
        </p>
        <div class="mt-3 flex flex-wrap gap-2">
          @if (isMe()) {
            <a routerLink="/settings/profile" class="rd-btn rd-btn-outline min-h-11 gap-1.5 px-4 text-sm" data-edit-profile>
              <svg lucideIcon="Pencil" [size]="16" aria-hidden="true"></svg>
              {{ 'profile.editProfile' | transloco }}
            </a>
          } @else {
            <span class="contents" data-profile-follow><rd-follow-button [user]="p" [initial]="p.isFollowing" /></span>
          }
        </div>
      </div>
    </div>

    @if (p.bio) {
      <!-- A bio is mixed text: its own paragraph direction, from its first strong character (SPEC §14.2). -->
      <p class="bio m-0 mt-4 text-[15px] leading-relaxed" [attr.dir]="bioDir()" data-profile-bio><rd-bdi-text [text]="p.bio" /></p>
    }

    @if (links().length) {
      <ul class="m-0 mt-2 flex list-none flex-wrap gap-x-4 p-0" [attr.aria-label]="'profile.links.label' | transloco" data-profile-links>
        @for (link of links(); track link.kind) {
          <li>
            <a
              [href]="link.url"
              target="_blank"
              rel="me nofollow noopener noreferrer"
              class="inline-flex min-h-11 items-center gap-1.5 text-sm text-link no-underline hover:underline"
              [attr.data-profile-link]="link.kind"
            >
              <svg [lucideIcon]="icons[link.kind]" [size]="16" class="shrink-0" aria-hidden="true"></svg>
              <span class="sr-only">{{ 'profile.links.' + link.kind | transloco }}:</span>
              <bdi dir="ltr">{{ link.label }}</bdi>
              <span class="sr-only">{{ 'profile.links.newTab' | transloco }}</span>
            </a>
          </li>
        }
      </ul>
    }

    <!-- Stats -->
    <ul class="m-0 mt-4 flex list-none gap-1 border-y border-border p-0 py-2 text-center" [attr.aria-label]="'profile.stats.label' | transloco" data-profile-stats>
      <li class="flex min-h-11 flex-1 flex-col justify-center" data-stat="articles">
        <span class="text-lg font-bold leading-tight">{{ p.stats.articles | rdCompactNumber: lang() }}</span>
        <span class="text-xs text-text-secondary">{{ 'profile.stats.articles' | transloco }}</span>
      </li>
      <li class="flex-1">
        <a [routerLink]="['/@' + p.username, 'followers']" class="flex min-h-11 flex-col justify-center rounded-md text-inherit no-underline hover:bg-surface-variant" data-stat="followers">
          <span class="text-lg font-bold leading-tight">{{ followers() | rdCompactNumber: lang() }}</span>
          <span class="text-xs text-text-secondary">{{ 'profile.stats.followers' | transloco }}</span>
        </a>
      </li>
      <li class="flex-1">
        <a [routerLink]="['/@' + p.username, 'following']" class="flex min-h-11 flex-col justify-center rounded-md text-inherit no-underline hover:bg-surface-variant" data-stat="following">
          <span class="text-lg font-bold leading-tight">{{ p.stats.following | rdCompactNumber: lang() }}</span>
          <span class="text-xs text-text-secondary">{{ 'profile.stats.following' | transloco }}</span>
        </a>
      </li>
      <li class="flex min-h-11 flex-1 flex-col justify-center" data-stat="reads">
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
  protected readonly icons = PROFILE_ICONS;

  readonly profile = input.required<ProfileDto>();
  /** Your own profile (the server says so, or the session knows it before the personalized copy arrives). */
  readonly isMe = input(false);

  protected readonly avatar = computed(() => profileAvatar(this.profile()));
  protected readonly initial = computed(() => (this.profile().displayName.trim()[0] ?? '?').toUpperCase());
  protected readonly links = computed(() => profileLinks(this.profile().links));
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
