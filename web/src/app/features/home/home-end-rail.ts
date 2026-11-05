import { ChangeDetectionStrategy, Component, computed, effect, inject, output, signal, untracked } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { PathCardDto } from '../../core/api/models';
import { PathsApi } from '../../core/api/paths.api';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { FollowButton } from '../../shared/social/follow-button';
import { Avatar } from '../../shared/ui/avatar';
import { PathCover } from '../paths/path-card';
import { HomeFooter } from './home-footer';
import { HomeStore } from './home.store';
import { HomeLayout } from './home-layout';
import { railAudience } from './home-start-rail';

/** Writers the suggestions card shows (the store loads more, for the Following tab's empty state). */
export const RAIL_SUGGESTIONS = 3;

/**
 * "Add to your feed" (signed in): three writers from `GET /users/suggested` (the list the Following tab shows when it's
 * empty, loaded once for both), each with an outlined "+ Follow" that turns into "✓ Following" (optimistic, shared with
 * every follow button), and "See all suggestions" → Explore. Hidden when there is nobody to suggest.
 */
@Component({
  selector: 'rd-home-suggestions-card',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, Avatar, BdiText, FollowButton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @switch (store.suggestedStatus()) {
      @case ('loaded') {
        @if (users().length) {
          <section class="rd-card p-0 pt-3 shadow-none" aria-labelledby="home-suggestions-title" data-home-suggestions>
            <h2 id="home-suggestions-title" class="m-0 px-4 text-sm font-semibold">{{ 'home.suggestions.title' | transloco }}</h2>
            <ul class="m-0 list-none px-4 py-1">
              @for (user of users(); track user.id) {
                <li class="flex gap-3 py-2" data-home-suggestion [attr.data-user]="user.id">
                  <a [routerLink]="'/@' + user.username" class="shrink-0" tabindex="-1" aria-hidden="true">
                    <rd-avatar [name]="user.displayName" [src]="user.avatarUrl" [size]="48" />
                  </a>
                  <div class="min-w-0 flex-1">
                    <a [routerLink]="'/@' + user.username" class="flex items-center gap-1 text-sm font-semibold text-text-primary no-underline hover:underline">
                      <rd-bdi-text class="truncate" [text]="user.displayName" />
                      @if (user.isVerified) {
                        <svg lucideIcon="BadgeCheck" [size]="14" class="shrink-0 text-primary" role="img" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
                      }
                    </a>
                    <p class="m-0 truncate text-xs text-text-secondary" [attr.dir]="user.bio ? 'auto' : 'ltr'">
                      @if (user.bio) {
                        <rd-bdi-text [text]="user.bio" />
                      } @else {
                        <bdi>&#64;{{ user.username }}</bdi>
                      }
                    </p>
                    <div class="mt-2 flex">
                      <rd-follow-button [user]="user" [initial]="user.isFollowing" [pill]="true" />
                    </div>
                  </div>
                </li>
              }
            </ul>
            <a
              routerLink="/explore"
              class="flex min-h-11 items-center justify-center gap-1 rounded-b-card border-t border-border text-sm font-semibold text-text-secondary no-underline transition-colors hover:bg-surface-variant hover:text-text-primary"
              data-home-suggestions-all
            >
              {{ 'home.suggestions.seeAll' | transloco }}
              <svg lucideIcon="ArrowRight" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
            </a>
          </section>
        }
      }
      @case ('error') {}
      @default {
        <div class="rd-card p-4 shadow-none" aria-hidden="true" data-home-suggestions-loading>
          <div class="rd-skeleton h-4 w-24"></div>
          @for (i of [1, 2, 3]; track i) {
            <div class="mt-4 flex gap-3">
              <div class="rd-skeleton h-12 w-12 shrink-0 rounded-full"></div>
              <div class="flex flex-1 flex-col gap-2">
                <div class="rd-skeleton h-3 w-3/4"></div>
                <div class="rd-skeleton h-3 w-1/2"></div>
                <div class="rd-skeleton mt-1 h-9 w-24 rounded-chip"></div>
              </div>
            </div>
          }
        </div>
      }
    }
  `,
})
export class HomeSuggestionsCard {
  protected readonly store = inject(HomeStore);
  private readonly session = inject(SessionStore);
  protected readonly users = computed(() => this.store.suggested().slice(0, RAIL_SUGGESTIONS));

  constructor() {
    const layout = inject(HomeLayout, { optional: true });
    effect(() => {
      if ((layout && !layout.active()) || !this.session.isAuthenticated()) return;
      untracked(() => {
        if (this.store.suggestedStatus() === 'idle') void this.store.loadSuggested();
      });
    });
  }
}

/**
 * "Suggested path": the first path of `GET /paths` you haven't enrolled in (the first one for a guest), with its cover
 * (or field color), title and "N articles · M min"; the card opens the path, where you start it. Hidden when there's
 * none. `settled` fires once it knows what it shows (whether it shows a path), so the footer under it never jumps.
 */
@Component({
  selector: 'rd-home-suggested-path',
  imports: [RouterLink, TranslocoPipe, BdiText, PluralPipe, PathCover],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @switch (status()) {
      @case ('loaded') {
        @if (path(); as p) {
          <section class="rd-card p-0 shadow-none" aria-labelledby="home-path-title" data-home-suggested-path>
            <h2 id="home-path-title" class="m-0 px-4 pb-2 pt-3 text-sm font-semibold">{{ 'home.suggestedPath.title' | transloco }}</h2>
            <a [routerLink]="['/paths', p.slug]" class="block px-4 pb-4 text-inherit no-underline" [attr.data-rail-path]="p.slug">
              <rd-path-cover class="block h-24 rounded-md" [path]="p" [iconSize]="32" />
              <span class="mt-2 line-clamp-2 block min-h-[2.75rem] text-[15px] font-semibold leading-snug" [attr.dir]="titleDir()"><rd-bdi-text [text]="p.title" /></span>
              <span class="mt-1 block text-xs text-text-secondary" data-rail-path-meta>
                {{ p.articleCount | rdPlural: 'reading.articles' : lang() }} · {{ p.readingTimeMinutes | rdPlural: 'reading.minutes' : lang() }}
              </span>
              <span class="rd-btn rd-btn-outline mt-3 flex min-h-9 w-full rounded-chip text-sm">{{ 'home.suggestedPath.start' | transloco }}</span>
            </a>
          </section>
        }
      }
      @case ('error') {}
      @default {
        <div class="rd-card px-4 pb-4 pt-3 shadow-none" aria-hidden="true" data-rail-path-loading>
          <div class="rd-skeleton h-4 w-24"></div>
          <div class="rd-skeleton mt-3 h-24 w-full rounded-md"></div>
          <div class="rd-skeleton mt-3 h-4 w-full"></div>
          <div class="rd-skeleton mt-2 h-4 w-2/3"></div>
          <div class="rd-skeleton mt-3 h-3 w-1/3"></div>
          <div class="rd-skeleton mt-3 h-9 w-full rounded-chip"></div>
        </div>
      }
    }
  `,
})
export class HomeSuggestedPath {
  private readonly api = inject(PathsApi);
  private readonly session = inject(SessionStore);
  protected readonly lang = inject(LanguageService).lang;

  readonly settled = output<boolean>();
  protected readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly path = signal<PathCardDto | null>(null);
  protected readonly titleDir = computed(() => detectDir(this.path()?.title ?? '') ?? 'auto');

  constructor() {
    const layout = inject(HomeLayout, { optional: true });
    let loaded = false;
    effect(() => {
      if (loaded || (layout && !layout.active())) return;
      loaded = true;
      untracked(() => void this.load());
    });
  }

  private async load(): Promise<void> {
    try {
      const paths = await firstValueFrom(this.api.list());
      const member = this.session.isAuthenticated();
      this.path.set((member ? paths.find((p) => !p.enrollment) : paths[0]) ?? null);
      this.status.set('loaded');
    } catch {
      this.status.set('error');
    }
    this.settled.emit(this.status() === 'loaded' && this.path() !== null);
  }
}

/**
 * Home's end column. Shown only in the browser once it knows who is signed in, top to bottom, each part after the one
 * above it settled: nothing ever moves down under the reader (no layout shift). The footer goes under its cards; when
 * it has none (nobody to suggest and no path, or neither loaded), under the start column's cards instead, so it never
 * stands alone at the top of an empty column.
 */
@Component({
  selector: 'rd-home-end-rail',
  imports: [HomeSuggestionsCard, HomeSuggestedPath, HomeFooter],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col gap-2' },
  template: `
    @if (audience() !== 'unknown') {
      @if (audience() === 'member') {
        <rd-home-suggestions-card />
      }
      @if (suggestionsSettled()) {
        <rd-home-suggested-path (settled)="pathSettled($event)" />
      }
      @if (footerHere()) {
        <rd-home-footer />
      }
    }
  `,
})
export class HomeEndRail {
  private readonly session = inject(SessionStore);
  private readonly store = inject(HomeStore);
  private readonly layout = inject(HomeLayout, { optional: true });
  protected readonly audience = computed(() => railAudience(this.session));
  protected readonly suggestionsSettled = computed(() => {
    if (this.audience() !== 'member') return true;
    const status = this.store.suggestedStatus();
    return status === 'loaded' || status === 'error';
  });
  protected readonly footerHere = signal(false);

  /** The path card knows what it shows (the suggestions settled before it): the footer's place is final now. */
  protected pathSettled(pathShown: boolean): void {
    const suggestionsShown =
      this.audience() === 'member' && this.store.suggestedStatus() === 'loaded' && this.store.suggested().length > 0;
    const here = pathShown || suggestionsShown || !this.layout;
    this.footerHere.set(here);
    this.layout?.footerInStart.set(!here);
  }
}
