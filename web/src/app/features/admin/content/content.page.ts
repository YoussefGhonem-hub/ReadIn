import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminApi, AdminArticlesQuery } from '../../../core/api/admin.api';
import { AdminArticleRowDto, AdminCommentRowDto, FieldDto, TopicDto } from '../../../core/api/models';
import { TaxonomyApi } from '../../../core/api/taxonomy.api';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { ModerationActionDraft, ModerationActionSheet } from '../../../shared/moderation/moderation-action-sheet';
import { LocalizedDatePipe, RelativeTimePipe } from '../../../shared/pipes/format.pipes';
import { urlLangFor } from '../../../shared/ui/article-link';
import { Avatar } from '../../../shared/ui/avatar';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ADMIN_CARD, ADMIN_PAGE_SIZE, ADMIN_TABLE_STYLES, AdminPageHeader, AdminPager, PagedState, boolParam, dateParam, oneOf, pageParam } from '../admin-ui';

const TABS = ['articles', 'comments'] as const;
const STATUSES = ['published', 'archived'] as const;
const SORTS = ['published', 'featured'] as const;
type Tab = (typeof TABS)[number];

/**
 * Content (F23), `/admin/content?tab=articles|comments&…`: every published and archived article (newest first, hidden
 * ones too) filtered by the publish dates, field, topic, writer, status, hidden, featured and reported, searched by
 * title, 50 a page; a row opens the article's console page. "Latest comments" lists comments across all articles,
 * newest first, with Hide / Unhide and Delete, so spam shows up before anyone reports it. The URL keeps the view.
 */
@Component({
  selector: 'rd-admin-content-page',
  imports: [
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    BdiText,
    Avatar,
    LocalizedDatePipe,
    RelativeTimePipe,
    EmptyState,
    ErrorState,
    ModerationActionSheet,
    AdminPageHeader,
    AdminPager,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-admin-content': '' },
  styles: ADMIN_TABLE_STYLES,
  template: `
    <rd-admin-page-header [title]="'admin.nav.content' | transloco" [subtitle]="'admin.content.subtitle' | transloco" />

    <div [class]="card">
      <nav class="flex gap-5 border-b border-border px-4" [attr.aria-label]="'admin.content.tabs' | transloco" data-content-tabs>
        @for (t of tabs; track t) {
          <a
            routerLink="/admin/content"
            [queryParams]="t === 'articles' ? {} : { tab: t }"
            class="-mb-px inline-flex min-h-11 items-center border-b-2 px-1 text-sm no-underline"
            [class]="currentTab() === t ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary hover:text-text-primary'"
            [attr.aria-current]="currentTab() === t ? 'page' : null"
            [attr.data-content-tab]="t"
            >{{ 'admin.content.tab.' + t | transloco }}</a
          >
        }
      </nav>

      @if (currentTab() === 'articles') {
        <form class="flex flex-col gap-3 border-b border-border p-4" role="search" (submit)="search($event, q.value)" data-content-filters>
          <div class="flex gap-2">
            <label for="content-q" class="sr-only">{{ 'admin.content.search' | transloco }}</label>
            <input #q id="content-q" type="search" class="rd-input flex-1" dir="auto" maxlength="100" [value]="query().q ?? ''" [placeholder]="'admin.content.search' | transloco" />
            <button type="submit" class="rd-btn rd-btn-primary min-h-11 px-4">
              <svg lucideIcon="Search" [size]="16" aria-hidden="true"></svg>
              {{ 'admin.search' | transloco }}
            </button>
          </div>
          <div class="flex flex-wrap items-end gap-2 text-sm">
            <label class="flex flex-col gap-1">
              <span class="text-xs text-text-secondary">{{ 'admin.content.from' | transloco }}</span>
              <input type="date" class="rd-input min-h-10 py-1" dir="ltr" [value]="query().from ?? ''" (change)="set({ from: $any($event.target).value })" data-filter="from" />
            </label>
            <label class="flex flex-col gap-1">
              <span class="text-xs text-text-secondary">{{ 'admin.content.to' | transloco }}</span>
              <input type="date" class="rd-input min-h-10 py-1" dir="ltr" [value]="query().to ?? ''" (change)="set({ to: $any($event.target).value })" data-filter="to" />
            </label>
            <label class="flex flex-col gap-1">
              <span class="text-xs text-text-secondary">{{ 'admin.content.field' | transloco }}</span>
              <select class="rd-input min-h-10 py-1" [value]="query().field ?? ''" (change)="set({ field: $any($event.target).value, topic: null })" data-filter="field">
                <option value="">{{ 'admin.all' | transloco }}</option>
                @for (f of fields(); track f.id) {
                  <option [value]="f.id">{{ lang() === 'ar' ? f.nameAr : f.nameEn }}</option>
                }
              </select>
            </label>
            @if (topics().length) {
              <label class="flex flex-col gap-1">
                <span class="text-xs text-text-secondary">{{ 'admin.content.topic' | transloco }}</span>
                <select class="rd-input min-h-10 py-1" [value]="query().topic ?? ''" (change)="set({ topic: $any($event.target).value })" data-filter="topic">
                  <option value="">{{ 'admin.all' | transloco }}</option>
                  @for (t of topics(); track t.id) {
                    <option [value]="t.id">{{ lang() === 'ar' ? t.nameAr : t.nameEn }}</option>
                  }
                </select>
              </label>
            }
            <label class="flex flex-col gap-1">
              <span class="text-xs text-text-secondary">{{ 'admin.content.status' | transloco }}</span>
              <select class="rd-input min-h-10 py-1" [value]="query().status ?? ''" (change)="set({ status: $any($event.target).value })" data-filter="status">
                <option value="">{{ 'admin.all' | transloco }}</option>
                @for (s of statuses; track s) {
                  <option [value]="s">{{ 'admin.content.statuses.' + s | transloco }}</option>
                }
              </select>
            </label>
            @for (flag of flags; track flag) {
              <label class="flex flex-col gap-1">
                <span class="text-xs text-text-secondary">{{ 'admin.content.' + flag | transloco }}</span>
                <select class="rd-input min-h-10 py-1" [value]="flagValue(flag)" (change)="setFlag(flag, $any($event.target).value)" [attr.data-filter]="flag">
                  <option value="">{{ 'admin.all' | transloco }}</option>
                  <option value="true">{{ 'admin.yes' | transloco }}</option>
                  @if (flag !== 'reported') {
                    <option value="false">{{ 'admin.no' | transloco }}</option>
                  }
                </select>
              </label>
            }
            <label class="flex flex-col gap-1">
              <span class="text-xs text-text-secondary">{{ 'admin.sortBy' | transloco }}</span>
              <select class="rd-input min-h-10 py-1" [value]="query().sort ?? 'published'" (change)="set({ sort: $any($event.target).value })" data-filter="sort">
                @for (s of sorts; track s) {
                  <option [value]="s">{{ 'admin.content.sorts.' + s | transloco }}</option>
                }
              </select>
            </label>
          </div>
          @if (query().writer) {
            <p class="m-0 flex flex-wrap items-center gap-2 text-sm" data-writer-filter>
              <span class="rd-tag rd-tag-neutral gap-1.5">
                {{ 'admin.content.writer' | transloco }}:
                @if (writerName(); as name) {
                  <rd-bdi-text [text]="name" />
                } @else {
                  <bdi dir="ltr">{{ query().writer }}</bdi>
                }
              </span>
              <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2" (click)="set({ writer: null })" data-clear-writer>{{ 'admin.clear' | transloco }}</button>
            </p>
          }
        </form>

        @switch (articles.status()) {
          @case ('error') {
            <rd-error-state [message]="'admin.loadError' | transloco" (retry)="articles.load()" />
          }
          @case ('loaded') {
            @if (articles.items().length) {
              <table class="admin-table" [attr.aria-busy]="articles.refreshing()" data-articles-table>
                <thead>
                  <tr>
                    <th scope="col">{{ 'admin.content.columns.article' | transloco }}</th>
                    <th scope="col">{{ 'admin.content.columns.published' | transloco }}</th>
                    <th scope="col" class="num">{{ 'admin.content.columns.reads' | transloco }}</th>
                    <th scope="col" class="num">{{ 'admin.content.columns.reactions' | transloco }}</th>
                    <th scope="col" class="num">{{ 'admin.content.columns.comments' | transloco }}</th>
                    <th scope="col">{{ 'admin.content.columns.state' | transloco }}</th>
                  </tr>
                </thead>
                <tbody>
                  @for (a of articles.items(); track a.id) {
                    <tr [attr.data-article-row]="a.id">
                      <td class="cell-main">
                        <a [routerLink]="['/admin/content', a.id]" class="line-clamp-2 font-semibold text-text-primary no-underline hover:underline" [attr.lang]="a.language" [attr.dir]="a.language === 'ar-EG' ? 'rtl' : 'ltr'">
                          <rd-bdi-text [text]="a.title" />
                        </a>
                        <span class="block truncate text-xs text-text-secondary">
                          @if (a.author; as author) {
                            <rd-bdi-text [text]="author.displayName" />
                          } @else {
                            {{ 'common.deletedUser' | transloco }}
                          }
                          · {{ lang() === 'ar' ? a.field.nameAr : a.field.nameEn }}
                          @if (a.topic; as topic) {
                            · {{ lang() === 'ar' ? topic.nameAr : topic.nameEn }}
                          }
                        </span>
                      </td>
                      <td [attr.data-label]="'admin.content.columns.published' | transloco">
                        @if (a.publishedAt; as published) {
                          <time [attr.datetime]="published">{{ published | rdDate: lang() }}</time>
                        } @else {
                          <span class="text-text-secondary" data-never-published>{{ 'admin.content.neverPublished' | transloco }}</span>
                        }
                      </td>
                      <td class="num" [attr.data-label]="'admin.content.columns.reads' | transloco">{{ a.readCount }}</td>
                      <td class="num" [attr.data-label]="'admin.content.columns.reactions' | transloco">{{ a.reactionCount }}</td>
                      <td class="num" [attr.data-label]="'admin.content.columns.comments' | transloco">{{ a.commentCount }}</td>
                      <td [attr.data-label]="'admin.content.columns.state' | transloco">
                        <span class="inline-flex flex-wrap justify-end gap-1">
                          @if (a.status === 'archived') {
                            <span class="rd-tag rd-tag-neutral">{{ 'admin.content.statuses.archived' | transloco }}</span>
                          }
                          @if (a.hiddenAt) {
                            <span class="rd-tag bg-callout-warning text-text-primary" data-tag-hidden>{{ 'admin.content.hiddenTag' | transloco }}</span>
                          }
                          @if (a.featuredAt) {
                            <span class="rd-tag rd-tag-accent" data-tag-featured>{{ 'admin.content.featuredTag' | transloco }}</span>
                          }
                          @if (a.openReports > 0) {
                            <span class="rd-tag bg-callout-danger text-text-primary">{{ 'admin.content.openReports' | transloco: { count: a.openReports } }}</span>
                          }
                        </span>
                      </td>
                    </tr>
                  }
                </tbody>
              </table>
              <rd-admin-pager [page]="articles.page()" [totalPages]="articles.totalPages()" [totalCount]="articles.totalCount()" (pageChange)="goTo($event)" />
            } @else {
              <rd-empty-state [title]="'admin.content.emptyArticles' | transloco" [message]="'admin.emptyFilters' | transloco" data-articles-empty />
            }
          }
          @default {
            <div class="flex flex-col gap-3 p-4" aria-busy="true" data-articles-loading>
              @for (i of skeletons; track i) {
                <div class="rd-skeleton h-10 w-full" aria-hidden="true"></div>
              }
            </div>
          }
        }
      } @else {
        <!-- Latest comments -->
        <div class="flex flex-wrap items-center gap-2 border-b border-border p-4 text-sm" role="toolbar" [attr.aria-label]="'admin.content.commentFilter' | transloco" data-comment-filter>
          @for (option of hiddenOptions; track option.key) {
            <button type="button" class="rd-chip" [attr.aria-pressed]="commentHidden() === option.value" [attr.data-hidden-chip]="option.key" (click)="set({ hidden: option.key === 'all' ? null : option.key })">
              {{ 'admin.content.commentHidden.' + option.key | transloco }}
            </button>
          }
        </div>
        @switch (comments.status()) {
          @case ('error') {
            <rd-error-state [message]="'admin.loadError' | transloco" (retry)="comments.load()" />
          }
          @case ('loaded') {
            @if (comments.items().length) {
              <ol class="m-0 list-none divide-y divide-border p-0" data-comments-list>
                @for (c of comments.items(); track c.id) {
                  <li class="flex gap-3 px-4 py-3" [attr.data-comment-row]="c.id">
                    <rd-avatar [name]="c.author?.displayName ?? '?'" [src]="c.author?.avatarUrl ?? null" [generic]="!c.author" [size]="32" />
                    <div class="min-w-0 flex-1 text-sm">
                      <p class="m-0 flex flex-wrap items-center gap-x-1.5">
                        @if (c.author; as author) {
                          <a [routerLink]="['/admin/users', author.id]" class="font-semibold text-text-primary no-underline hover:underline"><rd-bdi-text [text]="author.displayName" /></a>
                        } @else {
                          <span class="font-semibold text-text-secondary">{{ 'common.deletedUser' | transloco }}</span>
                        }
                        <span class="text-xs text-text-secondary">
                          <time [attr.datetime]="c.createdAt" [title]="c.createdAt | rdDate: lang() : 'long'">{{ c.createdAt | rdRelativeTime: lang() }}</time>
                          @if (c.parentId) {
                            · {{ 'admin.content.reply' | transloco }}
                          }
                        </span>
                        @if (c.hiddenAt) {
                          <span class="rd-tag bg-callout-warning text-text-primary" data-tag-hidden>{{ 'admin.content.hiddenTag' | transloco }}</span>
                        }
                        @if (c.openReports > 0) {
                          <a [routerLink]="['/admin/reports', 'comment', c.id]" class="rd-tag bg-callout-danger text-text-primary no-underline">{{
                            'admin.content.openReports' | transloco: { count: c.openReports }
                          }}</a>
                        }
                      </p>
                      <p class="m-0 mt-1 line-clamp-4 whitespace-pre-line [overflow-wrap:anywhere]" dir="auto" data-comment-body>{{ c.body }}</p>
                      <a
                        [routerLink]="['/' + urlLang(c.article.language), 'a', c.article.slug]"
                        [fragment]="'comment-' + c.id"
                        class="mt-1 block truncate text-xs text-link no-underline hover:underline"
                        [attr.lang]="c.article.language"
                        ><rd-bdi-text [text]="c.article.title"
                      /></a>
                      <div class="mt-2 flex flex-wrap gap-2">
                        @if (c.hiddenAt) {
                          <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-xs" (click)="moderate(c, 'unhide')" data-comment-action="unhide">
                            <svg lucideIcon="Eye" [size]="14" aria-hidden="true"></svg>{{ 'moderation.actions.unhide.comment' | transloco }}
                          </button>
                        } @else {
                          <button type="button" class="rd-btn rd-btn-outline min-h-9 border-error px-3 text-xs text-error" (click)="moderate(c, 'hide')" data-comment-action="hide">
                            <svg lucideIcon="EyeOff" [size]="14" aria-hidden="true"></svg>{{ 'moderation.actions.hide.comment' | transloco }}
                          </button>
                        }
                        <button type="button" class="rd-btn rd-btn-outline min-h-9 border-error px-3 text-xs text-error" (click)="moderate(c, 'delete')" data-comment-action="delete">
                          <svg lucideIcon="Trash2" [size]="14" aria-hidden="true"></svg>{{ 'moderation.actions.delete' | transloco }}
                        </button>
                      </div>
                    </div>
                  </li>
                }
              </ol>
              <rd-admin-pager [page]="comments.page()" [totalPages]="comments.totalPages()" [totalCount]="comments.totalCount()" (pageChange)="goTo($event)" />
            } @else {
              <rd-empty-state [title]="'admin.content.emptyComments' | transloco" data-comments-empty />
            }
          }
          @default {
            <div class="flex flex-col gap-3 p-4" aria-busy="true" data-comments-loading>
              @for (i of skeletons; track i) {
                <div class="rd-skeleton h-14 w-full" aria-hidden="true"></div>
              }
            </div>
          }
        }
      }
    </div>

    <rd-moderation-action-sheet [draft]="draft()" (done)="afterAction($event.action)" (closed)="draft.set(null)" />
  `,
})
export class AdminContentPage {
  private readonly api = inject(AdminApi);
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly router = inject(Router);
  protected readonly lang = inject(LanguageService).lang;

  // `?…` (component input binding)
  readonly tab = input<string | undefined>();
  readonly from = input<string | undefined>();
  readonly to = input<string | undefined>();
  readonly field = input<string | undefined>();
  readonly topic = input<string | undefined>();
  readonly writer = input<string | undefined>();
  readonly status = input<string | undefined>();
  readonly hidden = input<string | undefined>();
  readonly featured = input<string | undefined>();
  readonly reported = input<string | undefined>();
  readonly q = input<string | undefined>();
  readonly sort = input<string | undefined>();
  readonly page = input<string | undefined>();

  protected readonly card = ADMIN_CARD;
  protected readonly tabs = TABS;
  protected readonly statuses = STATUSES;
  protected readonly sorts = SORTS;
  protected readonly flags = ['hidden', 'featured', 'reported'] as const;
  protected readonly hiddenOptions = [
    { key: 'all', value: null },
    { key: 'false', value: false },
    { key: 'true', value: true },
  ] as const;
  protected readonly skeletons = [1, 2, 3, 4, 5];
  protected readonly urlLang = urlLangFor;

  protected readonly fields = signal<FieldDto[]>([]);
  protected readonly topics = signal<TopicDto[]>([]);
  protected readonly draft = signal<ModerationActionDraft | null>(null);

  protected readonly currentTab = computed<Tab>(() => oneOf(this.tab(), TABS) ?? 'articles');
  protected readonly query = computed<AdminArticlesQuery>(() => ({
    from: dateParam(this.from()),
    to: dateParam(this.to()),
    field: this.field() || null,
    topic: this.topic() || null,
    writer: this.writer() || null,
    status: oneOf(this.status(), STATUSES),
    hidden: boolParam(this.hidden()),
    featured: boolParam(this.featured()),
    reported: this.reported() === 'true' ? true : null,
    q: this.q()?.trim() || null,
    sort: oneOf(this.sort(), SORTS),
    page: pageParam(this.page()),
    pageSize: ADMIN_PAGE_SIZE,
  }));
  protected readonly commentHidden = computed(() => boolParam(this.hidden()));
  /** The writer filter's name, from a row of theirs. */
  protected readonly writerName = computed(() => {
    const id = this.query().writer;
    return this.articles.items().find((a) => a.author?.id === id)?.author?.displayName ?? null;
  });

  protected readonly articles = new PagedState<AdminArticleRowDto>(() => this.api.articles(this.query()));
  protected readonly comments = new PagedState<AdminCommentRowDto>(() =>
    this.api.comments({ hidden: this.commentHidden(), page: pageParam(this.page()), pageSize: ADMIN_PAGE_SIZE }),
  );

  constructor() {
    effect(() => {
      const tab = this.currentTab();
      if (tab === 'articles') this.query();
      else {
        this.commentHidden();
        this.page();
      }
      untracked(() => void (tab === 'articles' ? this.articles.load() : this.comments.load()));
    });
    void firstValueFrom(this.taxonomy.fields()).then(
      (fields) => this.fields.set(fields),
      () => undefined,
    );
    // The topics of the chosen field (by its slug).
    effect(() => {
      const fieldId = this.query().field;
      const field = this.fields().find((f) => f.id === fieldId);
      untracked(() => {
        if (!field) {
          this.topics.set([]);
          return;
        }
        void firstValueFrom(this.taxonomy.topics(field.slug)).then(
          (topics) => this.topics.set(topics),
          () => this.topics.set([]),
        );
      });
    });
  }

  protected flagValue(flag: 'hidden' | 'featured' | 'reported'): string {
    const value = this.query()[flag];
    return value === true ? 'true' : value === false ? 'false' : '';
  }

  protected setFlag(flag: string, value: string): void {
    this.set({ [flag]: value });
  }

  protected search(event: Event, q: string): void {
    event.preventDefault();
    this.set({ q: q.trim() });
  }

  /** Changes filters (an empty value removes one) and goes back to the first page. */
  protected set(change: Record<string, string | null>): void {
    const queryParams: Record<string, string | null> = { page: null };
    for (const [key, value] of Object.entries(change)) queryParams[key] = value || null;
    void this.router.navigate(['/admin/content'], { queryParams, queryParamsHandling: 'merge' });
  }

  protected goTo(page: number): void {
    void this.router.navigate(['/admin/content'], { queryParams: { page: page > 1 ? page : null }, queryParamsHandling: 'merge' });
  }

  protected moderate(comment: AdminCommentRowDto, action: 'hide' | 'unhide' | 'delete'): void {
    this.draft.set({ action, targetType: 'comment', targetId: comment.id });
  }

  protected afterAction(action: string): void {
    const id = this.draft()?.targetId;
    if (action === 'delete' && id) {
      void this.comments.load();
      return;
    }
    if (id) this.comments.update((c) => c.id === id, (c) => ({ ...c, hiddenAt: action === 'hide' ? new Date().toISOString() : null }));
  }
}
