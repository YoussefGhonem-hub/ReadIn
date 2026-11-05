import { ChangeDetectionStrategy, Component, computed, effect, inject, signal, untracked } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ExpertiseFieldDto } from '../../core/api/models';
import { ProfilesApi } from '../../core/api/profiles.api';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { Avatar } from '../../shared/ui/avatar';
import { profilePath } from '../../layout/nav-items';
import { StreakStore } from '../reading/streak.store';
import { HomeFooter } from './home-footer';
import { HomeLayout } from './home-layout';

/** `unknown` until the browser knows who is signed in (always during SSR). */
export type RailAudience = 'unknown' | 'guest' | 'member';

export function railAudience(session: InstanceType<typeof SessionStore>): RailAudience {
  return session.isAuthenticated() ? 'member' : session.isGuest() ? 'guest' : 'unknown';
}

const ROW_LINK =
  'flex min-h-9 items-center justify-between gap-2 px-4 text-sm text-text-secondary no-underline transition-colors hover:bg-surface-variant hover:text-text-primary';

/**
 * Home's profile card: a banner strip from the theme's colors, the avatar over it, your name with the Verified badge,
 * @username and up to three fields of expertise (`GET /users/{username}`; your bio when you have none). The whole card
 * opens your profile.
 */
@Component({
  selector: 'rd-home-profile-card',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, Avatar, BdiText],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <a [routerLink]="profileLink()" class="rd-card block overflow-hidden p-0 text-inherit no-underline shadow-none transition-colors hover:border-text-secondary" data-home-profile-card>
      <div class="h-14 bg-linear-to-b from-primary-container to-surface-variant" aria-hidden="true"></div>
      <div class="-mt-10 px-4 pb-4">
        <span class="inline-block rounded-full bg-surface p-1">
          <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="72" />
        </span>
        <span class="mt-1 flex items-center gap-1 text-base font-bold text-text-primary">
          <rd-bdi-text class="truncate" [text]="session.displayName() ?? ''" />
          @if (verified()) {
            <svg lucideIcon="BadgeCheck" [size]="16" class="shrink-0 text-primary" role="img" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
          }
        </span>
        <span class="block truncate text-sm text-text-secondary"><bdi dir="ltr">&#64;{{ session.username() }}</bdi></span>
        <!-- One line, always the same height: the fields arrive after the card. -->
        <span class="mt-2 flex h-6 items-center gap-1 overflow-hidden" data-home-profile-fields>
          @switch (fieldsStatus()) {
            @case ('loaded') {
              @if (fields().length) {
                <span class="sr-only">{{ 'home.profileCard.fields' | transloco }}:</span>
                @for (field of fields(); track field.id) {
                  <span class="rd-tag rd-tag-neutral max-w-full shrink truncate" data-home-profile-field><rd-bdi-text [text]="field.name" /></span>
                }
              } @else if (bio()) {
                <span class="truncate text-xs text-text-secondary" dir="auto"><rd-bdi-text [text]="bio()!" /></span>
              }
            }
            @case ('error') {}
            @default {
              <span class="rd-skeleton h-5 w-16" aria-hidden="true"></span>
              <span class="rd-skeleton h-5 w-12" aria-hidden="true"></span>
            }
          }
        </span>
      </div>
    </a>
  `,
})
export class HomeProfileCard {
  protected readonly session = inject(SessionStore);
  private readonly profiles = inject(ProfilesApi);
  private readonly layout = inject(HomeLayout);

  protected readonly fields = signal<ExpertiseFieldDto[]>([]);
  protected readonly fieldsStatus = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly verified = computed(() => this.session.me()?.isVerified ?? false);
  protected readonly bio = computed(() => this.session.me()?.bio ?? null);
  protected readonly profileLink = computed(() => profilePath(this.session.username()));

  constructor() {
    let loadedFor: string | null = null;
    effect(() => {
      const username = this.layout.active() ? this.session.username() : null;
      if (!username || username === loadedFor) return;
      loadedFor = username;
      untracked(() => void this.load(username));
    });
  }

  private async load(username: string): Promise<void> {
    this.fieldsStatus.set('loading');
    try {
      const profile = await firstValueFrom(this.profiles.profile(username));
      this.fields.set(profile.expertise.slice(0, 3));
      this.fieldsStatus.set('loaded');
    } catch {
      this.fieldsStatus.set('error');
    }
  }
}

/**
 * "Your reading": the current streak, this week's articles and minutes (`GET /me/stats` through the streak store,
 * re-read when it's stale or an article was completed since). Each row opens your profile, where the full stats are.
 */
@Component({
  selector: 'rd-home-reading-card',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, PluralPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <section class="rd-card p-0 py-2 shadow-none" aria-labelledby="home-reading-title" data-home-reading>
      <h2 id="home-reading-title" class="m-0 px-4 pb-1 pt-1 text-sm font-semibold">{{ 'home.reading.title' | transloco }}</h2>
      <ul class="m-0 list-none p-0">
        <li>
          <a [routerLink]="profileLink()" [class]="rowLink" data-home-reading-row="streak">
            <span>{{ 'home.reading.streak' | transloco }}</span>
            @if (streaks.streak(); as streak) {
              <span class="inline-flex items-center gap-1 font-semibold text-text-primary">
                <svg lucideIcon="Flame" [size]="14" [class]="streak.current === 0 ? 'text-text-secondary' : 'text-accent'" aria-hidden="true"></svg>
                {{ streak.current | rdPlural: 'reading.days' : lang() }}
              </span>
            } @else {
              <span class="rd-skeleton h-3 w-10" aria-hidden="true"></span>
            }
          </a>
        </li>
        <li>
          <a [routerLink]="profileLink()" [class]="rowLink" data-home-reading-row="articles">
            <span>{{ 'home.reading.articlesThisWeek' | transloco }}</span>
            @if (streaks.stats(); as stats) {
              <span class="font-semibold text-primary">{{ stats.articlesThisWeek }}</span>
            } @else {
              <span class="rd-skeleton h-3 w-6" aria-hidden="true"></span>
            }
          </a>
        </li>
        <li>
          <a [routerLink]="profileLink()" [class]="rowLink" data-home-reading-row="minutes">
            <span>{{ 'home.reading.minutesThisWeek' | transloco }}</span>
            @if (streaks.stats(); as stats) {
              <span class="font-semibold text-primary">{{ stats.minutesThisWeek }}</span>
            } @else {
              <span class="rd-skeleton h-3 w-6" aria-hidden="true"></span>
            }
          </a>
        </li>
      </ul>
    </section>
  `,
})
export class HomeReadingCard {
  protected readonly streaks = inject(StreakStore);
  private readonly session = inject(SessionStore);
  private readonly layout = inject(HomeLayout);
  protected readonly lang = inject(LanguageService).lang;
  protected readonly rowLink = ROW_LINK;
  protected readonly profileLink = computed(() => profilePath(this.session.username()));

  constructor() {
    // The store loads on sign in; coming back to Home re-reads it when stale (or after a completed article).
    effect(() => {
      if (this.layout.active() && this.session.isAuthenticated()) untracked(() => void this.streaks.refreshIfStale());
    });
  }
}

/** Shortcuts: Saved, My paths and (with `articles.create`) My articles. */
@Component({
  selector: 'rd-home-shortcuts-card',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <nav class="rd-card p-0 py-2 shadow-none" [attr.aria-label]="'home.shortcuts.title' | transloco" data-home-shortcuts>
      <h2 class="m-0 px-4 pb-1 pt-1 text-sm font-semibold" aria-hidden="true">{{ 'home.shortcuts.title' | transloco }}</h2>
      <ul class="m-0 list-none p-0">
        @for (link of links(); track link.id) {
          <li>
            <a
              [routerLink]="link.path"
              [queryParams]="link.queryParams"
              class="flex min-h-9 items-center gap-3 px-4 text-sm text-text-primary no-underline transition-colors hover:bg-surface-variant"
              [attr.data-home-shortcut]="link.id"
            >
              <svg [lucideIcon]="link.icon" [size]="16" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
              {{ link.labelKey | transloco }}
            </a>
          </li>
        }
      </ul>
    </nav>
  `,
})
export class HomeShortcutsCard {
  private readonly session = inject(SessionStore);
  protected readonly links = computed(() =>
    [
      { id: 'saved', labelKey: 'nav.saved', icon: 'Bookmark', path: '/saved', queryParams: null },
      { id: 'myPaths', labelKey: 'nav.myPaths', icon: 'Route', path: '/paths', queryParams: { tab: 'mine' } },
      { id: 'myArticles', labelKey: 'nav.myArticles', icon: 'FileText', path: '/write', queryParams: null },
    ].filter((link) => link.id !== 'myArticles' || this.session.hasPermission('articles.create')),
  );
}

/** For guests: why to sign up, with Sign in and Create account. */
@Component({
  selector: 'rd-home-guest-card',
  imports: [RouterLink, TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <section class="rd-card p-4 shadow-none" aria-labelledby="home-guest-title" data-home-guest>
      <h2 id="home-guest-title" class="m-0 text-base font-bold">{{ 'home.guest.title' | transloco }}</h2>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'home.guest.body' | transloco }}</p>
      <a routerLink="/auth/sign-in" class="rd-btn rd-btn-primary mt-3 min-h-10 w-full text-sm">{{ 'auth.signIn.submit' | transloco }}</a>
      <a routerLink="/auth/sign-up" class="rd-btn rd-btn-outline mt-2 min-h-10 w-full text-sm">{{ 'auth.signIn.createAccount' | transloco }}</a>
    </section>
  `,
})
export class HomeGuestCard {}

/**
 * Home's start column: signed in, the profile, reading and shortcut cards; a guest, one card to sign up. Until the
 * browser knows (and on the server) the guest card holds the place, invisible, so neither shows the wrong one. The
 * footer links come here only when the end column has no card to put them under.
 */
@Component({
  selector: 'rd-home-start-rail',
  imports: [HomeProfileCard, HomeReadingCard, HomeShortcutsCard, HomeGuestCard, HomeFooter],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col gap-2' },
  template: `
    @switch (audience()) {
      @case ('member') {
        <rd-home-profile-card />
        <rd-home-reading-card />
        <rd-home-shortcuts-card />
      }
      @case ('guest') {
        <rd-home-guest-card />
      }
      @default {
        <rd-home-guest-card class="invisible" aria-hidden="true" inert />
      }
    }
    @if (layout?.footerInStart()) {
      <rd-home-footer />
    }
  `,
})
export class HomeStartRail {
  private readonly session = inject(SessionStore);
  protected readonly layout = inject(HomeLayout, { optional: true });
  protected readonly audience = computed(() => railAudience(this.session));
}
