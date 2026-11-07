import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminSummaryStore } from '../../../core/admin/admin-summary.store';
import { AdminApi } from '../../../core/api/admin.api';
import { isApiError } from '../../../core/api/api.config';
import { AdminArticleRowDto } from '../../../core/api/models';
import { SessionStore } from '../../../core/auth/session.store';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { ModerationActionDraft, ModerationActionSheet } from '../../../shared/moderation/moderation-action-sheet';
import { LocalizedDatePipe, RelativeTimePipe } from '../../../shared/pipes/format.pipes';
import { urlLangFor } from '../../../shared/ui/article-link';
import { Avatar } from '../../../shared/ui/avatar';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { ADMIN_CARD, AdminConfirm } from '../admin-ui';
import { provideAdminIcons } from '../admin-icons';

type State = { status: 'loading' } | { status: 'loaded'; data: AdminArticleRowDto } | { status: 'error'; notFound: boolean };

/**
 * An article in the console (F23), `/admin/content/{id}` ("Open in console"): its writer, field, dates, numbers and
 * state, with Open, Hide / Unhide (F22, with a note), Feature / Unfeature (`articles.feature`, confirmed) and its
 * reports (the F22 case) when it has any.
 */
@Component({
  selector: 'rd-admin-article-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, Avatar, LocalizedDatePipe, RelativeTimePipe, EmptyState, ErrorState, ModerationActionSheet, AdminConfirm],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-admin-article': '' },
  styles: `
    .facts {
      display: grid;
      grid-template-columns: minmax(0, auto) minmax(0, 1fr);
      gap: 0.375rem 1rem;
    }
  `,
  template: `
    <a routerLink="/admin/content" class="mb-2 inline-flex min-h-11 items-center gap-1.5 text-sm text-text-secondary no-underline hover:text-text-primary" data-article-back>
      <svg lucideIcon="ArrowLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
      {{ 'admin.content.back' | transloco }}
    </a>

    @switch (state().status) {
      @case ('loaded') {
        @let a = data()!;
        <section [class]="card + ' p-4 lg:p-5'">
          <div class="mb-2 flex flex-wrap gap-1.5">
            <span class="rd-tag rd-tag-neutral">{{ 'admin.content.statuses.' + a.status | transloco }}</span>
            @if (a.hiddenAt) {
              <span class="rd-tag bg-callout-warning text-text-primary" data-tag-hidden>{{ 'admin.content.hiddenTag' | transloco }}</span>
            }
            @if (a.featuredAt) {
              <span class="rd-tag rd-tag-accent" data-tag-featured>{{ 'admin.content.featuredTag' | transloco }}</span>
            }
          </div>
          <h1 class="m-0 text-xl font-bold lg:text-2xl" [attr.lang]="a.language" [attr.dir]="a.language === 'ar-EG' ? 'rtl' : 'ltr'" data-article-title>
            <rd-bdi-text [text]="a.title" />
          </h1>
          @if (a.author; as author) {
            <a [routerLink]="session.hasPermission('users.read') ? ['/admin/users', author.id] : '/@' + author.username" class="mt-3 flex items-center gap-2 text-sm text-text-primary no-underline hover:underline" data-article-author>
              <rd-avatar [name]="author.displayName" [src]="author.avatarUrl" [size]="28" />
              <rd-bdi-text [text]="author.displayName" />
              <bdi dir="ltr" class="text-text-secondary">&#64;{{ author.username }}</bdi>
            </a>
          } @else {
            <p class="m-0 mt-3 text-sm text-text-secondary">{{ 'common.deletedUser' | transloco }}</p>
          }

          <dl class="facts m-0 mt-4 text-sm">
            <dt class="text-text-secondary">{{ 'admin.content.field' | transloco }}</dt>
            <dd class="m-0">
              {{ lang() === 'ar' ? a.field.nameAr : a.field.nameEn }}
              @if (a.topic; as topic) {
                · {{ lang() === 'ar' ? topic.nameAr : topic.nameEn }}
              }
            </dd>
            <dt class="text-text-secondary">{{ 'admin.content.columns.published' | transloco }}</dt>
            <dd class="m-0">
              @if (a.publishedAt; as published) {
                <time [attr.datetime]="published">{{ published | rdDate: lang() : 'long' }}</time>
              } @else {
                {{ 'admin.content.neverPublished' | transloco }}
              }
            </dd>
            <dt class="text-text-secondary">{{ 'admin.content.columns.reads' | transloco }}</dt>
            <dd class="m-0 tabular-nums">{{ a.readCount }}</dd>
            <dt class="text-text-secondary">{{ 'admin.content.columns.reactions' | transloco }}</dt>
            <dd class="m-0 tabular-nums">{{ a.reactionCount }}</dd>
            <dt class="text-text-secondary">{{ 'admin.content.columns.comments' | transloco }}</dt>
            <dd class="m-0 tabular-nums">{{ a.commentCount }}</dd>
            @if (a.hiddenAt; as at) {
              <dt class="text-text-secondary">{{ 'admin.content.hiddenAt' | transloco }}</dt>
              <dd class="m-0"><time [attr.datetime]="at">{{ at | rdRelativeTime: lang() }}</time></dd>
            }
            @if (a.featuredAt; as at) {
              <dt class="text-text-secondary">{{ 'admin.content.featuredAt' | transloco }}</dt>
              <dd class="m-0"><time [attr.datetime]="at">{{ at | rdRelativeTime: lang() }}</time></dd>
            }
            <dt class="text-text-secondary">{{ 'admin.content.reports' | transloco }}</dt>
            <dd class="m-0">
              @if (a.reportCount > 0) {
                <a [routerLink]="['/admin/reports', 'article', a.id]" class="text-link no-underline hover:underline" data-article-reports>{{
                  'admin.content.reportsOf' | transloco: { open: a.openReports, total: a.reportCount }
                }}</a>
              } @else {
                0
              }
            </dd>
          </dl>

          <div class="mt-4 flex flex-wrap gap-2" data-article-actions>
            <a [routerLink]="['/' + urlLang(a.language), 'a', a.slug]" class="rd-btn rd-btn-outline min-h-11 gap-1.5 px-4 text-sm" data-article-open>
              <svg lucideIcon="ExternalLink" [size]="16" aria-hidden="true"></svg>
              {{ 'admin.content.open' | transloco }}
            </a>
            @if (a.hiddenAt) {
              <button type="button" class="rd-btn rd-btn-outline min-h-11 gap-1.5 px-4 text-sm" (click)="draft.set({ action: 'unhide', targetType: 'article', targetId: a.id })" data-article-action="unhide">
                <svg lucideIcon="Eye" [size]="16" aria-hidden="true"></svg>
                {{ 'moderation.actions.unhide.article' | transloco }}
              </button>
            } @else {
              <button
                type="button"
                class="rd-btn rd-btn-outline min-h-11 gap-1.5 border-error px-4 text-sm text-error"
                (click)="draft.set({ action: 'hide', targetType: 'article', targetId: a.id })"
                data-article-action="hide"
              >
                <svg lucideIcon="EyeOff" [size]="16" aria-hidden="true"></svg>
                {{ 'moderation.actions.hide.article' | transloco }}
              </button>
            }
            @if (session.hasPermission('articles.feature')) {
              <button type="button" class="rd-btn rd-btn-outline min-h-11 gap-1.5 px-4 text-sm" (click)="featuring.set(true)" [attr.data-article-action]="a.featuredAt ? 'unfeature' : 'feature'">
                <svg [lucideIcon]="a.featuredAt ? 'StarOff' : 'Star'" [size]="16" aria-hidden="true"></svg>
                {{ (a.featuredAt ? 'admin.content.unfeature' : 'admin.content.feature') | transloco }}
              </button>
            }
          </div>
        </section>
      }
      @case ('error') {
        <div [class]="card">
          @if (notFound()) {
            <rd-empty-state [title]="'admin.content.notFound' | transloco" data-article-not-found>
              <a routerLink="/admin/content" class="rd-btn rd-btn-primary mt-3">{{ 'admin.content.back' | transloco }}</a>
            </rd-empty-state>
          } @else {
            <rd-error-state [message]="'admin.loadError' | transloco" (retry)="load()" />
          }
        </div>
      }
      @default {
        <div [class]="card + ' flex flex-col gap-3 p-5'" aria-busy="true" data-article-loading>
          <div class="rd-skeleton h-7 w-2/3" aria-hidden="true"></div>
          <div class="rd-skeleton h-24 w-full" aria-hidden="true"></div>
        </div>
      }
    }

    <rd-moderation-action-sheet [draft]="draft()" (done)="afterAction()" (closed)="draft.set(null)" />
    <rd-admin-confirm
      [open]="featuring()"
      [title]="(data()?.featuredAt ? 'admin.content.confirmUnfeature.title' : 'admin.content.confirmFeature.title') | transloco"
      [body]="(data()?.featuredAt ? 'admin.content.confirmUnfeature.body' : 'admin.content.confirmFeature.body') | transloco"
      [busy]="busy()"
      [error]="error()"
      (confirmed)="toggleFeatured()"
      (closed)="featuring.set(false); error.set(null)"
    />
  `,
})
export class AdminArticlePage {
  private readonly api = inject(AdminApi);
  private readonly summary = inject(AdminSummaryStore);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly title = inject(Title);
  protected readonly session = inject(SessionStore);
  protected readonly lang = inject(LanguageService).lang;

  readonly id = input.required<string>();

  protected readonly card = ADMIN_CARD;
  protected readonly urlLang = urlLangFor;
  protected readonly state = signal<State>({ status: 'loading' });
  protected readonly data = computed(() => {
    const s = this.state();
    return s.status === 'loaded' ? s.data : null;
  });
  protected readonly notFound = computed(() => {
    const s = this.state();
    return s.status === 'error' && s.notFound;
  });
  protected readonly draft = signal<ModerationActionDraft | null>(null);
  protected readonly featuring = signal(false);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);

  constructor() {
    effect(() => {
      this.id();
      untracked(() => {
        this.state.set({ status: 'loading' });
        void this.load();
      });
    });
    effect(() => {
      const a = this.data();
      this.title.setTitle(`${a ? a.title : this.transloco.translate('admin.nav.content')} — ReadIn`);
    });
  }

  async load(): Promise<void> {
    const id = this.id();
    if (this.state().status === 'error') this.state.set({ status: 'loading' });
    try {
      const data = await firstValueFrom(this.api.article(id));
      if (id === this.id()) this.state.set({ status: 'loaded', data });
    } catch (error) {
      if (id === this.id()) this.state.set({ status: 'error', notFound: isApiError(error) && error.status === 404 });
    }
  }

  protected afterAction(): void {
    void this.load();
    void this.summary.refresh();
  }

  protected async toggleFeatured(): Promise<void> {
    const a = this.data();
    if (!a || this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      await firstValueFrom(a.featuredAt ? this.api.unfeature(a.id) : this.api.feature(a.id));
      this.toasts.success(this.transloco.translate(a.featuredAt ? 'admin.content.unfeaturedDone' : 'admin.content.featuredDone'));
      this.busy.set(false);
      this.featuring.set(false);
      void this.load();
    } catch (error) {
      this.error.set(this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }
}
