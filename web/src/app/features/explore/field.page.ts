import { ChangeDetectionStrategy, Component, DestroyRef, RESPONSE_INIT, computed, effect, inject, input, untracked } from '@angular/core';
import { NavigationCancel, NavigationEnd, NavigationError, NavigationStart, Router, RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { FieldPageTopicDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { AppHistory } from '../../core/platform/app-history';
import { BdiText } from '../../shared/directives/bdi-text';
import { isolate } from '../../shared/directives/bidi';
import { CompactNumberPipe, PluralPipe } from '../../shared/pipes/format.pipes';
import { FieldIcon } from '../../shared/ui/field-icon';
import { PostCardSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ArticleHealthNotice } from '../article/article-parts';
import { reloadOnSessionChange } from '../paths/session-change';
import { fieldColorOf } from '../search/search-query';
import { CardPagesList } from './card-pages-list';
import { FieldPageStore } from './field-page.store';
import { FieldSeoService } from './field-seo.service';
import { WriterRail, WriterRailSkeleton } from './writer-rail';

/** A field page's path (any topic): its SEO stays while one is shown, also when Back brings it back alive. */
const FIELD_PATH = /^\/f\/[^/?#]+(?:[?#]|$)/;

/**
 * A field page (F15), `/f/{slug}` and `/f/{slug}?topic={topic}` (the link Search gives a topic): the field's icon in
 * its color, name, article count and followers with Follow (F12 interests; guests get the sign-in prompt), the health
 * note on a sensitive field, topic chips (a chip filters the articles; the chosen topic can be followed too), "Top
 * writers in this field" with Follow, then the articles as post cards (F34), newest first, with infinite scroll.
 * Server-rendered with title, description and canonical; an empty field or topic is `noindex`, an unknown field or a
 * topic it doesn't have a 404. Kept alive while you read (Back finds it as you left it).
 */
@Component({
  selector: 'rd-field-page',
  imports: [
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    BdiText,
    PluralPipe,
    CompactNumberPipe,
    FieldIcon,
    PostCardSkeleton,
    EmptyState,
    ErrorState,
    ArticleHealthNotice,
    CardPagesList,
    WriterRail,
    WriterRailSkeleton,
  ],
  providers: [FieldPageStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[640px] px-4 pt-4 lg:pt-8' },
  template: `
    <!-- Back to the page you came from in the app, else Explore (a plain link to Explore without JavaScript) -->
    <a href="/explore" class="rd-icon-btn mb-3" [attr.aria-label]="'common.back' | transloco" data-field-back (click)="goBack($event)">
      <svg lucideIcon="ArrowRight" [size]="18" class="ltr:rotate-180" aria-hidden="true"></svg>
    </a>

    @switch (store.status()) {
      @case ('loaded') {
        @if (store.field(); as field) {
          @let color = fieldColor(field.color);
          @let following = field.isFollowing;
          <header class="flex flex-wrap items-center gap-x-4 gap-y-3" data-field-header [attr.data-field]="field.slug">
            <span
              class="grid h-14 w-14 shrink-0 place-items-center rounded-full"
              [style.background-color]="'color-mix(in srgb, ' + color + ' 14%, transparent)'"
              [style.color]="color"
              aria-hidden="true"
              data-field-icon
              ><rd-field-icon [name]="field.icon" [size]="28"
            /></span>
            <div class="min-w-0 flex-1">
              <!-- The name keeps its own direction, isolated; the heading lines up with the page like the lines around it. -->
              <h1 class="m-0 break-words text-2xl font-bold leading-snug"><bdi dir="auto" data-field-name>{{ name() }}</bdi></h1>
              <p class="m-0 mt-1 text-sm text-text-secondary">
                <span data-field-count>{{ field.articleCount | rdPlural: 'reading.articles' : lang() }}</span>
                <span aria-hidden="true"> · </span>
                <span data-field-followers>{{ field.followerCount | rdPlural: 'fields.page.followers' : lang() : { n: (field.followerCount | rdCompactNumber: lang()) } }}</span>
              </p>
            </div>
            <button
              type="button"
              class="rd-btn min-h-11 shrink-0 gap-1.5 px-4 text-sm max-sm:w-full"
              [class]="following ? 'bg-primary-container text-on-primary-container' : 'rd-btn-primary'"
              [attr.aria-pressed]="following"
              [attr.aria-busy]="store.busy().has('field') || null"
              data-follow-field
              (click)="toggleField()"
            >
              <svg [lucideIcon]="following ? 'Check' : 'Plus'" [size]="16" aria-hidden="true"></svg>
              {{ (following ? 'fields.page.following' : 'fields.page.follow') | transloco }}
              <span class="sr-only">{{ name() }}</span>
            </button>
          </header>

          @if (field.isSensitive) {
            <!-- Health disclaimer (SPEC F04, §20), as above a sensitive field's articles. -->
            <rd-article-health-notice class="mt-4 mb-0!" />
          }

          @if (field.topics.length) {
            <nav class="mt-5" [attr.aria-label]="'fields.page.topics' | transloco" data-field-topics>
              <ul class="-mx-4 my-0 flex list-none gap-2 overflow-x-auto px-4 pb-1">
                <li>
                  <a
                    [routerLink]="[]"
                    [queryParams]="{ topic: null }"
                    class="rd-chip min-h-11"
                    [class.is-active]="!store.topic()"
                    [attr.aria-current]="!store.topic() ? 'page' : null"
                    data-topic-chip=""
                    >{{ 'fields.page.allTopics' | transloco }}</a
                  >
                </li>
                @for (topic of field.topics; track topic.id) {
                  @let selected = topic.id === store.selectedTopic()?.id;
                  <li>
                    <a
                      [routerLink]="[]"
                      [queryParams]="{ topic: topic.slug }"
                      class="rd-chip min-h-11"
                      [class.is-active]="selected"
                      [attr.aria-current]="selected ? 'page' : null"
                      [attr.data-topic-chip]="topic.slug"
                    >
                      <rd-bdi-text [text]="topicName(topic)" />
                      @if (topic.isFollowing) {
                        <!-- The same mark as the app's chips. Lucide hides an icon from screen readers, so the words are
                             text: the link reads "{topic} · Following". -->
                        <svg lucideIcon="Check" [size]="14" class="shrink-0" aria-hidden="true" data-topic-following></svg>
                        <span class="sr-only"> · {{ 'fields.page.followingTopic' | transloco }}</span>
                      }
                    </a>
                  </li>
                }
              </ul>
            </nav>
          }

          @if (store.selectedTopic(); as topic) {
            <div class="mt-3 flex flex-wrap items-center justify-between gap-2 rounded-card bg-surface-variant px-4 py-3" data-topic-bar [attr.data-topic]="topic.slug">
              <p class="m-0 min-w-0 text-sm">
                <span class="font-semibold"><rd-bdi-text [text]="topicName(topic)" /></span>
                <span class="text-text-secondary"> · {{ topic.articleCount | rdPlural: 'reading.articles' : lang() }}</span>
              </p>
              <button
                type="button"
                class="rd-btn min-h-11 shrink-0 gap-1.5 px-3 text-sm"
                [class]="topic.isFollowing ? 'bg-primary-container text-on-primary-container' : 'rd-btn-outline'"
                [attr.aria-pressed]="topic.isFollowing"
                [attr.aria-busy]="store.busy().has(topic.id) || null"
                data-follow-topic
                (click)="toggleTopic(topic)"
              >
                <svg [lucideIcon]="topic.isFollowing ? 'Check' : 'Plus'" [size]="16" aria-hidden="true"></svg>
                {{ (topic.isFollowing ? 'fields.page.followingTopic' : 'fields.page.followTopic') | transloco }}
                <span class="sr-only">{{ topicName(topic) }}</span>
              </button>
            </div>
          }

          @switch (store.writersStatus()) {
            @case ('loaded') {
              @if (store.writers().length) {
                <section class="mt-6" aria-labelledby="field-writers" data-field-writers>
                  <h2 id="field-writers" class="m-0 mb-2 text-lg font-bold">{{ 'fields.page.topWriters' | transloco }}</h2>
                  <rd-writer-rail [users]="store.writers()" [label]="'fields.page.topWriters' | transloco" />
                </section>
              }
            }
            @case ('error') {
              <div class="mt-6 flex flex-wrap items-center justify-between gap-2 text-sm text-text-secondary" role="alert" data-field-writers-error>
                {{ 'fields.page.writersError' | transloco }}
                <button type="button" class="rd-btn rd-btn-outline min-h-11 px-3 text-sm" (click)="store.loadWriters()">{{ 'common.retry' | transloco }}</button>
              </div>
            }
            @default {
              <div class="mt-6" aria-busy="true">
                <div class="rd-skeleton mb-3 h-5 w-40"></div>
                <rd-writer-rail-skeleton />
              </div>
            }
          }

          <section class="mt-6" aria-labelledby="field-articles" data-field-articles>
            <h2 id="field-articles" class="m-0 mb-3 text-lg font-bold">{{ 'fields.page.latest' | transloco }}</h2>
            @if (store.topicNotFound()) {
              <rd-empty-state
                [title]="'fields.page.topicNotFoundTitle' | transloco"
                [message]="'fields.page.topicNotFoundBody' | transloco: { field: isolate(name()) }"
                data-topic-not-found
              >
                <a [routerLink]="[]" [queryParams]="{ topic: null }" class="rd-btn rd-btn-primary mt-3">{{ 'fields.page.allArticles' | transloco }}</a>
              </rd-empty-state>
            } @else {
              <rd-card-pages-list
                [pages]="store.articles"
                [endText]="(store.topic() ? 'fields.page.endTopic' : 'fields.page.end') | transloco"
                [emptyTitle]="(store.topic() ? 'fields.page.emptyTopicTitle' : 'fields.page.emptyTitle') | transloco"
                [emptyBody]="'fields.page.emptyBody' | transloco"
                [errorText]="'fields.page.articlesError' | transloco"
              >
                <a routerLink="/explore" class="rd-btn rd-btn-primary mt-3">{{ 'fields.page.browse' | transloco }}</a>
              </rd-card-pages-list>
            }
          </section>
        }
      }
      @case ('notFound') {
        <rd-empty-state [title]="'fields.page.notFoundTitle' | transloco" [message]="'fields.page.notFoundBody' | transloco" data-field-not-found>
          <a routerLink="/explore" class="rd-btn rd-btn-primary mt-3">{{ 'fields.page.browse' | transloco }}</a>
        </rd-empty-state>
      }
      @case ('error') {
        <rd-error-state [message]="'fields.page.loadError' | transloco" (retry)="store.load()" />
      }
      @default {
        <div aria-busy="true" data-field-loading>
          <div class="flex items-center gap-4">
            <div class="rd-skeleton h-14 w-14 shrink-0 rounded-full"></div>
            <div class="flex-1">
              <div class="rd-skeleton h-7 w-1/2"></div>
              <div class="rd-skeleton mt-2 h-4 w-40"></div>
            </div>
          </div>
          <div class="mt-5 flex gap-2">
            @for (i of [1, 2, 3]; track i) {
              <div class="rd-skeleton h-11 w-24 rounded-chip"></div>
            }
          </div>
          <div class="mt-6 flex flex-col gap-3">
            @for (i of [1, 2, 3]; track i) {
              <rd-post-card-skeleton />
            }
          </div>
        </div>
      }
    }
  `,
})
export class FieldPage {
  protected readonly store = inject(FieldPageStore);
  private readonly history = inject(AppHistory);
  private readonly prompt = inject(AuthPromptService);
  private readonly router = inject(Router);
  private readonly responseInit = inject(RESPONSE_INIT, { optional: true });
  protected readonly lang = inject(LanguageService).lang;
  protected readonly fieldColor = fieldColorOf;
  protected readonly isolate = isolate;

  /** Route param (`/f/{slug}`, component input binding), already percent-decoded by the router. */
  readonly slug = input.required<string>();
  /** `?topic=`: a topic slug of this field. */
  readonly topic = input<string | undefined>();

  /** The field's name in the UI language. */
  protected readonly name = computed(() => {
    const field = this.store.field();
    return field ? (this.lang() === 'ar' ? field.nameAr : field.nameEn) : '';
  });

  constructor() {
    effect(() => {
      const slug = this.slug();
      const topic = this.topic()?.trim() || null;
      untracked(() => void this.store.open(slug, topic));
    });
    this.keepSeo();
    // Your follows, reactions and saves once signed in (the server-rendered copy is anonymous); signing out drops them.
    reloadOnSessionChange(() => void this.store.refresh());
  }

  protected topicName(topic: FieldPageTopicDto): string {
    return this.lang() === 'ar' ? topic.nameAr : topic.nameEn;
  }

  protected toggleField(): void {
    if (this.prompt.requireAuth()) void this.store.toggleField();
  }

  protected toggleTopic(topic: FieldPageTopicDto): void {
    if (this.prompt.requireAuth()) void this.store.toggleTopic(topic);
  }

  protected goBack(event: MouseEvent): void {
    // A new tab or window (a modifier key, another button) opens Explore, like any link.
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    this.history.back('/explore');
  }

  /**
   * Title, description, canonical and `noindex` for what is shown (a 404 status on the server for a missing field or
   * topic). They stay while a field page is shown, also when Back brings this one back alive, and are taken away as
   * soon as you leave it, before the next page sets its own.
   */
  private keepSeo(): void {
    const seo = inject(FieldSeoService);
    let shown = true;
    const apply = () => {
      const status = this.store.status();
      const field = this.store.field();
      if (status === 'notFound') {
        seo.notFound();
        if (this.responseInit) this.responseInit.status = 404;
      } else if (status === 'loaded' && field) {
        if (this.store.topicNotFound()) {
          seo.notFound(field);
          if (this.responseInit) this.responseInit.status = 404;
        } else {
          seo.field(field, this.store.selectedTopic());
        }
      }
    };
    effect(() => {
      this.store.status();
      this.store.field();
      this.store.selectedTopic();
      this.store.topicNotFound();
      this.lang();
      if (shown) untracked(apply);
    });
    const subscription = this.router.events.subscribe((event) => {
      if (event instanceof NavigationStart && shown && !FIELD_PATH.test(event.url)) {
        shown = false;
        seo.clear();
      } else if (event instanceof NavigationEnd || event instanceof NavigationCancel || event instanceof NavigationError) {
        const onField = FIELD_PATH.test(this.router.url);
        if (onField && !shown) {
          shown = true;
          apply();
        }
        shown = onField;
      }
    });
    inject(DestroyRef).onDestroy(() => {
      subscription.unsubscribe();
      if (shown) seo.clear();
    });
  }
}
