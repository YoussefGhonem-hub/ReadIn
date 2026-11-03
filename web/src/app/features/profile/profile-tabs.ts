import { ChangeDetectionStrategy, Component, ElementRef, computed, inject, input, viewChild } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ProfileDto } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { LocalizedDatePipe } from '../../shared/pipes/format.pipes';
import { ArticleCard } from '../../shared/ui/article-card';
import { FieldIcon } from '../../shared/ui/field-icon';
import { ArticleCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { SavedStore } from '../saved/saved.store';
import { fieldColor } from '../reading/reading-stats-card';
import { loadMoreNearEnd } from './infinite-scroll';
import { ProfileArticlesStore } from './profile-articles.store';
import { PROFILE_ICONS } from './profile-icons';
import { profileLinks } from './profile-links';

/** Articles tab (F14): the user's published articles with infinite scroll. The page owns the store (SSR loads it). */
@Component({
  selector: 'rd-profile-articles',
  imports: [RouterLink, TranslocoPipe, ArticleCard, ArticleCardSkeleton, EmptyState, ErrorState],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-profile-articles': '' },
  template: `
    @switch (store.status()) {
      @case ('error') {
        <rd-error-state [message]="'profile.articles.loadError' | transloco" (retry)="store.load(username())" />
      }
      @case ('loaded') {
        @for (article of store.items(); track article.id) {
          <rd-article-card [article]="article" />
        } @empty {
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
        @if (store.loadingMore()) {
          <rd-article-card-skeleton />
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
        @for (i of [1, 2, 3]; track i) {
          <rd-article-card-skeleton />
        }
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
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, FieldIcon, LocalizedDatePipe],
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
          @for (link of links(); track link.kind) {
            <li>
              <a [href]="link.url" target="_blank" rel="me nofollow noopener noreferrer" class="inline-flex min-h-11 items-center gap-2 text-link no-underline hover:underline">
                <svg [lucideIcon]="icons[link.kind]" [size]="18" class="shrink-0" aria-hidden="true"></svg>
                <span class="text-text-primary">{{ 'profile.links.' + link.kind | transloco }}</span>
                <bdi dir="ltr" class="text-sm">{{ link.label }}</bdi>
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

/** Paths tab: learning paths are F09 (Phase 2), so there is nothing to list yet. */
@Component({
  selector: 'rd-profile-paths',
  imports: [TranslocoPipe, EmptyState],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-profile-paths': '' },
  template: `<rd-empty-state [title]="'profile.paths.title' | transloco" [message]="'profile.paths.body' | transloco" />`,
})
export class ProfilePaths {}
