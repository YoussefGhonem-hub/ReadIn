import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { ProfileDto } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { FollowStore } from '../../core/social/follow.store';
import { BdiText } from '../directives/bdi-text';
import { CompactNumberPipe, PluralPipe } from '../pipes/format.pipes';
import { FollowButton } from '../social/follow-button';
import { Avatar } from '../ui/avatar';
import { ProfileCardCache } from './profile-card.cache';
import { VerifiedBadge } from '../ui/verified-badge';

type CardState = { status: 'loading' } | { status: 'loaded'; profile: ProfileDto } | { status: 'error' };

/**
 * The small card about a person that a pointer resting on their name or @mention opens (web only, like LinkedIn's
 * mini profile): the photo and name (both open the profile), ✓, `@username`, the title on up to 2 lines, "Follows you",
 * "N followers · M articles", and a full-width Follow (the shared follow store; guests get the sign-in prompt) or, on
 * your own card, "View profile". A skeleton while it loads, one short line when it can't.
 *
 * A non-modal dialog named by the person: it never takes the focus itself. {@link ProfileCardService} shows it.
 */
@Component({
  selector: 'rd-profile-card',
  imports: [RouterLink, TranslocoPipe, BdiText, CompactNumberPipe, PluralPipe, FollowButton, Avatar, VerifiedBadge],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    // The overlay pane is a flex box: the card fills its 320 px (at most the window less 16 px).
    class: 'block w-full rounded-card border border-border bg-surface-raised p-4 text-text-primary shadow-raised',
    role: 'dialog',
    '[attr.aria-label]': 'label()',
    '[attr.aria-busy]': "state().status === 'loading' || null",
    'data-profile-card': '',
  },
  template: `
    @let s = state();
    @if (s.status === 'loaded') {
      @let p = s.profile;
      <div class="flex items-start gap-3">
        <a [routerLink]="profileLink()" class="shrink-0 rounded-full" tabindex="-1" aria-hidden="true">
          <rd-avatar [name]="p.displayName" [src]="avatarSrc()" [size]="64" />
        </a>
        <div class="min-w-0 flex-1">
          <a
            [routerLink]="profileLink()"
            class="flex min-w-0 items-center gap-1 text-base font-semibold leading-snug text-text-primary no-underline hover:underline"
            data-profile-card-name
          >
            <rd-bdi-text class="truncate" [text]="p.displayName" />
            @if (p.isVerified) {
              <rd-verified-badge [size]="16" />
            }
          </a>
          <p class="m-0 mt-0.5 flex flex-wrap items-center gap-x-2 gap-y-1 text-[13px] text-text-secondary">
            <bdi dir="ltr" data-profile-card-username>&#64;{{ p.username }}</bdi>
            @if (p.followsYou && !isMe()) {
              <span class="rd-tag rd-tag-neutral" data-profile-card-follows-you>{{ 'profile.followsYou' | transloco }}</span>
            }
          </p>
          @if (headline(); as title) {
            <!-- The title (F14): its own direction, at most 2 lines -->
            <p class="m-0 mt-1 line-clamp-2 text-sm leading-snug [overflow-wrap:anywhere]" dir="auto" data-profile-card-headline>{{ title }}</p>
          }
        </div>
      </div>

      <p class="m-0 mt-3 text-[13px] text-text-secondary" data-profile-card-stats>
        <span data-profile-card-followers>{{
          followers() | rdPlural: 'profileCard.followers' : lang() : { count: (followers() | rdCompactNumber: lang()) }
        }}</span>
        <span aria-hidden="true"> · </span>
        <span data-profile-card-articles>{{
          p.stats.articles | rdPlural: 'profileCard.articles' : lang() : { count: (p.stats.articles | rdCompactNumber: lang()) }
        }}</span>
      </p>

      <div class="mt-3 flex" data-profile-card-action>
        @if (isMe()) {
          <a [routerLink]="profileLink()" class="rd-btn rd-btn-outline w-full text-sm" data-profile-card-view>{{ 'me.viewProfile' | transloco }}</a>
        } @else {
          <rd-follow-button [user]="p" [initial]="p.isFollowing" [wide]="true" />
        }
      </div>
    } @else if (s.status === 'error') {
      <p class="m-0 text-sm text-text-secondary" data-profile-card-error>{{ 'profile.loadError' | transloco }}</p>
    } @else {
      <div class="flex items-center gap-3" aria-hidden="true" data-profile-card-loading>
        <div class="rd-skeleton h-16 w-16 shrink-0 rounded-full"></div>
        <div class="flex flex-1 flex-col gap-2">
          <div class="rd-skeleton h-4 w-2/3"></div>
          <div class="rd-skeleton h-3 w-1/2"></div>
        </div>
      </div>
      <span class="sr-only">{{ 'common.loading' | transloco }}</span>
    }
  `,
})
export class ProfileCard {
  private readonly cache = inject(ProfileCardCache);
  private readonly follows = inject(FollowStore);
  private readonly session = inject(SessionStore);
  protected readonly lang = inject(LanguageService).lang;

  /** Whose card (with or without the `@`). */
  readonly username = input.required<string>();

  protected readonly state = signal<CardState>({ status: 'loading' });

  private readonly profile = computed(() => {
    const s = this.state();
    return s.status === 'loaded' ? s.profile : null;
  });
  protected readonly handle = computed(() => this.username().replace(/^@/, ''));
  protected readonly profileLink = computed(() => '/@' + (this.profile()?.username ?? this.handle()));
  /** The dialog's name: the person's name, or their @username until it is known. */
  protected readonly label = computed(() => this.profile()?.displayName ?? `@${this.handle()}`);
  /** The 128 px rendition for the 64 px photo (sharp on 2× screens), else the photo every author carries. */
  protected readonly avatarSrc = computed(() => {
    const p = this.profile();
    return p ? (p.avatarVariants?.['128'] ?? p.avatarUrl) : null;
  });
  protected readonly headline = computed(() => this.profile()?.headline?.trim() || null);
  protected readonly isMe = computed(() => {
    const p = this.profile();
    return !!p && (p.isMe || (this.session.isAuthenticated() && this.session.me()?.id === p.id));
  });
  /** Moves with your Follow / Unfollow at once, like the profile header. */
  protected readonly followers = computed(() => {
    const p = this.profile();
    if (!p) return 0;
    if (!this.session.isAuthenticated() || this.isMe()) return p.stats.followers;
    const now = this.follows.isFollowing(p.id, p.isFollowing);
    return Math.max(0, p.stats.followers + Number(now) - Number(p.isFollowing));
  });

  constructor() {
    effect(() => {
      const username = this.handle();
      untracked(() => this.load(username));
    });
  }

  private load(username: string): void {
    // The follow state: what this session knows (FollowStore), else what the profile said when it loaded.
    const cached = this.cache.peek(username);
    if (cached) {
      this.state.set({ status: 'loaded', profile: cached });
      return;
    }
    this.state.set({ status: 'loading' });
    this.cache.get(username).then(
      (profile) => {
        if (this.handle() === username) this.state.set({ status: 'loaded', profile });
      },
      () => {
        if (this.handle() === username) this.state.set({ status: 'error' });
      },
    );
  }
}
