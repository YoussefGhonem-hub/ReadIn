import { ChangeDetectionStrategy, Component, ElementRef, computed, effect, inject, input, signal, untracked, viewChild } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { PathCardDto, ProfileDto } from '../../core/api/models';
import { PathsApi } from '../../core/api/paths.api';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { LocalizedDatePipe } from '../../shared/pipes/format.pipes';
import { ArticleCard } from '../../shared/ui/article-card';
import { FieldIcon } from '../../shared/ui/field-icon';
import { ArticleCardSkeleton, PostCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { PostCard } from '../feed/post-card';
import { PathCard, PathCardSkeleton } from '../paths/path-card';
import { SavedStore } from '../saved/saved.store';
import { fieldColor } from '../reading/reading-stats-card';
import { loadMoreNearEnd } from './infinite-scroll';
import { ProfileArticlesStore } from './profile-articles.store';
import { PROFILE_ICONS } from './profile-icons';
import { LinkIcon } from './link-icon';
import { profileLinks } from './profile-links';

/**
 * Articles tab (F14): the user's published articles as post cards (F34), with infinite scroll. The page owns the
 * store (SSR loads it).
 */
@Component({
  selector: 'rd-profile-articles',
  imports: [RouterLink, TranslocoPipe, PostCard, PostCardSkeleton, EmptyState, ErrorState],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-profile-articles': '' },
  template: `
    @switch (store.status()) {
      @case ('error') {
        <rd-error-state [message]="'profile.articles.loadError' | transloco" (retry)="store.load(username())" />
      }
      @case ('loaded') {
        @if (store.items().length) {
          <div class="flex flex-col gap-3 pt-3">
            @for (article of store.items(); track article.id) {
              <rd-post-card [article]="article" />
            }
            @if (store.loadingMore()) {
              <rd-post-card-skeleton />
            }
          </div>
        } @else {
          @if (isMe()) {
            <rd-empty-state [title]="'profile.articles.emptyOwnTitle' | transloco" [message]="'profile.articles.emptyOwnBody' | transloco" data-articles-empty>
              @if (canWrite()) {
                <a routerLink="/write" class="rd-btn rd-btn-primary mt-3">{{ 'profile.articles.write' | transloco }}</a>
              }
            </rd-empty-state>
          } @else {
            <rd-empty-state [title]="'profile.articles.emptyTitle' | transloco" [message]="'profile.articles.emptyBody' | transloco" data-articles-empty />
          }
        }
        @if (store.loadMoreFailed()) {
          <div class="py-4 text-center">
            <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
          </div>
        }
        @if (store.items().length > 0 && !store.nextCursor()) {
          <p class="py-6 text-center text-sm text-text-secondary">{{ 'profile.articles.end' | transloco }}</p>
        }
      }
      @default {
        <div class="flex flex-col gap-3 pt-3">
          @for (i of [1, 2, 3]; track i) {
            <rd-post-card-skeleton />
          }
        </div>
      }
    }
    <div #sentinel class="h-px" aria-hidden="true"></div>
  `,
})
export class ProfileArticles {
  protected readonly store = inject(ProfileArticlesStore);
  private readonly session = inject(SessionStore);
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');

  readonly username = input.required<string>();
  readonly isMe = input(false);
  protected readonly canWrite = computed(() => this.session.permissions().has('articles.create'));

  constructor() {
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.store.loadMore(),
    );
  }
}

/** Saved tab (F14, own profile only): your saved articles, newest first, as on the Saved page (F13). */
@Component({
  selector: 'rd-profile-saved',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, ArticleCard, ArticleCardSkeleton, EmptyState, ErrorState],
  providers: [SavedStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-profile-saved': '' },
  template: `
    <div class="flex flex-wrap items-center justify-between gap-2 py-3 text-xs text-text-secondary">
      <span class="inline-flex items-center gap-1.5">
        <svg lucideIcon="LockKeyhole" [size]="14" aria-hidden="true"></svg>
        {{ 'profile.saved.onlyYou' | transloco }}
      </span>
      <a routerLink="/saved" class="rd-btn rd-btn-ghost min-h-11 px-2 text-xs text-primary" data-open-saved>
        {{ 'profile.saved.openAll' | transloco }}
        <svg lucideIcon="ChevronRight" [size]="14" class="rd-flip-rtl" aria-hidden="true"></svg>
      </a>
    </div>
    @switch (store.status()) {
      @case ('error') {
        <rd-error-state [message]="'saved.loadError' | transloco" (retry)="store.load()" />
      }
      @case ('loaded') {
        @for (item of store.visible(); track item.article.id) {
          <rd-article-card [article]="item.article" data-saved-item />
        } @empty {
          <rd-empty-state [title]="'saved.empty.title' | transloco" [message]="'saved.empty.body' | transloco" data-saved-empty />
        }
        @if (store.loadingMore()) {
          <rd-article-card-skeleton />
        }
        @if (store.loadMoreFailed()) {
          <div class="py-4 text-center">
            <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMore()">{{ 'common.retry' | transloco }}</button>
          </div>
        }
      }
      @default {
        @for (i of [1, 2, 3]; track i) {
          <rd-article-card-skeleton />
        }
      }
    }
    <div #sentinel class="h-px" aria-hidden="true"></div>
  `,
})
export class ProfileSaved {
  protected readonly store = inject(SavedStore);
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');

  constructor() {
    void this.store.load();
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.store.loadMore(),
    );
  }
}

/** About tab (F14): bio, links, fields of expertise and the join date. */
@Component({
  selector: 'rd-profile-about',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, FieldIcon, LocalizedDatePipe, LinkIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block py-4', 'data-profile-about': '' },
  template: `
    @let p = profile();
    @if (p.bio) {
      <section class="mb-6" aria-labelledby="about-bio">
        <h2 id="about-bio" class="m-0 mb-2 text-sm font-semibold text-text-secondary">{{ 'profile.about.bio' | transloco }}</h2>
        <p class="m-0 leading-relaxed" style="white-space: pre-line" [attr.dir]="bioDir()"><rd-bdi-text [text]="p.bio" /></p>
      </section>
    }
    @if (links().length) {
      <section class="mb-6" aria-labelledby="about-links">
        <h2 id="about-links" class="m-0 mb-1 text-sm font-semibold text-text-secondary">{{ 'profile.about.links' | transloco }}</h2>
        <ul class="m-0 flex list-none flex-col p-0">
          @for (link of links(); track $index) {
            <li>
              <a
                [href]="link.url"
                target="_blank"
                rel="me nofollow ugc noopener noreferrer"
                class="inline-flex min-h-11 max-w-full items-center gap-2 text-link no-underline hover:underline"
                [attr.data-about-link]="link.platform"
              >
                <rd-link-icon [platform]="link.platform" [size]="18" />
                @if (link.label; as label) {
                  <span class="text-text-primary"><bdi dir="auto">{{ label }}</bdi></span>
                } @else {
                  <span class="text-text-primary">{{ 'profile.links.platforms.' + link.platform | transloco }}</span>
                }
                <bdi dir="ltr" class="min-w-0 truncate text-sm">{{ link.display }}</bdi>
                <span class="sr-only">{{ 'profile.links.newTab' | transloco }}</span>
              </a>
            </li>
          }
        </ul>
      </section>
    }
    @if (p.expertise.length) {
      <section class="mb-6" aria-labelledby="about-expertise">
        <h2 id="about-expertise" class="m-0 mb-2 text-sm font-semibold text-text-secondary">{{ 'profile.about.expertise' | transloco }}</h2>
        <ul class="m-0 flex list-none flex-wrap gap-2 p-0" data-profile-expertise>
          @for (field of p.expertise; track field.id) {
            <li
              class="inline-flex min-h-9 items-center gap-1.5 rounded-chip border border-border px-3 text-sm"
              [style.background-color]="'color-mix(in srgb, ' + color(field.color) + ' 14%, transparent)'"
            >
              <span class="inline-flex" [style.color]="color(field.color)"><rd-field-icon [name]="field.icon" [size]="16" /></span>
              <rd-bdi-text [text]="field.name" />
            </li>
          }
        </ul>
      </section>
    }
    @if (!p.bio && !links().length && !p.expertise.length) {
      <p class="m-0 mb-6 text-sm text-text-secondary" data-about-empty>
        {{ (isMe() ? 'profile.about.emptyOwn' : 'profile.about.empty') | transloco }}
        @if (isMe()) {
          <a routerLink="/settings/profile" class="ms-1 font-semibold text-primary">{{ 'profile.editProfile' | transloco }}</a>
        }
      </p>
    }
    <p class="m-0 inline-flex items-center gap-2 text-sm text-text-secondary" data-profile-joined>
      <svg [lucideIcon]="icons.calendar" [size]="16" aria-hidden="true"></svg>
      {{ 'profile.about.joined' | transloco: { date: (p.joinedAt | rdDate: lang() : 'monthYear') } }}
    </p>
  `,
})
export class ProfileAbout {
  protected readonly lang = inject(LanguageService).lang;
  protected readonly icons = PROFILE_ICONS;
  protected readonly color = fieldColor;

  readonly profile = input.required<ProfileDto>();
  readonly isMe = input(false);
  protected readonly links = computed(() => profileLinks(this.profile().links));
  /** The bio's own direction (see ProfileHeader.bioDir). */
  protected readonly bioDir = computed(() => detectDir(this.profile().bio) ?? 'auto');
}

/**
 * Paths tab (F09, F14): the user's enrolled paths with their progress and completion badges, in progress first. Shown
 * under the same rule as the reading stats (yours, or made public); otherwise the private state.
 */
@Component({
  selector: 'rd-profile-paths',
  imports: [RouterLink, TranslocoPipe, EmptyState, ErrorState, PathCard, PathCardSkeleton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block py-4', 'data-profile-paths': '' },
  template: `
    @if (!visible() || status() === 'private') {
      <rd-empty-state [title]="'profile.paths.privateTitle' | transloco" [message]="'profile.paths.privateBody' | transloco" data-paths-private />
    } @else {
      @switch (status()) {
        @case ('error') {
          <rd-error-state [message]="'profile.paths.loadError' | transloco" (retry)="load()" />
        }
        @case ('loaded') {
          <ul class="m-0 flex list-none flex-col gap-3 p-0">
            @for (path of paths(); track path.id) {
              <li><rd-path-card [path]="path" /></li>
            }
          </ul>
          @if (!paths().length) {
            <rd-empty-state
              [title]="'profile.paths.emptyTitle' | transloco"
              [message]="(isMe() ? 'profile.paths.emptyOwnBody' : 'profile.paths.emptyBody') | transloco"
              data-paths-empty
            >
              @if (isMe()) {
                <a routerLink="/paths" class="rd-btn rd-btn-primary mt-3" data-browse-paths>{{ 'profile.paths.browse' | transloco }}</a>
              }
            </rd-empty-state>
          }
        }
        @default {
          <div class="flex flex-col gap-3" aria-busy="true">
            @for (i of [1, 2]; track i) {
              <rd-path-card-skeleton />
            }
          </div>
        }
      }
    }
  `,
})
export class ProfilePaths {
  private readonly api = inject(PathsApi);

  readonly username = input.required<string>();
  readonly isMe = input(false);
  /** `ProfileDto.readingStatsVisible` (or your own profile): the API answers 403 otherwise. */
  readonly visible = input(false);

  protected readonly status = signal<'loading' | 'loaded' | 'error' | 'private'>('loading');
  protected readonly paths = signal<PathCardDto[]>([]);
  private generation = 0;

  constructor() {
    effect(() => {
      if (this.visible()) untracked(() => void this.load());
    });
  }

  /** `GET /users/{username}/paths`; a 403 (stats made private meanwhile) shows the private state. */
  protected async load(): Promise<void> {
    const generation = ++this.generation;
    const username = this.username();
    this.status.set('loading');
    try {
      const paths = await firstValueFrom(this.api.userPaths(username));
      if (generation !== this.generation) return;
      this.paths.set(paths);
      this.status.set('loaded');
    } catch (error) {
      if (generation === this.generation) this.status.set(isApiError(error) && error.code === 'profile.stats_private' ? 'private' : 'error');
    }
  }
}
