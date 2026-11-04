import { ChangeDetectionStrategy, Component, DestroyRef, RESPONSE_INIT, computed, effect, inject, input, signal } from '@angular/core';
import { HttpContext, httpResource } from '@angular/common/http';
import { CdkMenu, CdkMenuItem, CdkMenuTrigger } from '@angular/cdk/menu';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { SILENT_ERRORS, isApiError } from '../../core/api/api.config';
import { ArticleCardDto, PathArticleRefDto, PathDetailsDto } from '../../core/api/models';
import { PathsApi } from '../../core/api/paths.api';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { PluralPipe, ReadingTimePipe } from '../../shared/pipes/format.pipes';
import { articleLink } from '../../shared/ui/article-link';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ProgressBar } from '../../shared/ui/progress-bar';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { PathCover, fieldName, isCompleted } from './path-card';
import { providePathIcons } from './path-icons';
import { PathSeoService } from './path-seo.service';
import { reloadOnSessionChange } from './session-change';

/** The primary action of a path (F09): start it (guests get the sign-in prompt), continue with the next one, or read again. */
export type PathAction = 'start' | 'continue' | 'again';

export function pathAction(path: PathDetailsDto, signedIn: boolean): PathAction {
  if (!signedIn || !path.enrollment) return 'start';
  return path.progress?.next ? 'continue' : 'again';
}

/**
 * A learning path (F09), `/paths/{slug}`: server-rendered for guests and crawlers. Header with the cover, progress and
 * completion badge; Start / Continue / Read again; Leave path in the ⋯ menu (with a confirm); the ordered articles with
 * a ✓ on the ones you read and the next one highlighted. Signed in, it loads again with your token once hydrated.
 */
@Component({
  selector: 'rd-path-page',
  imports: [
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    CdkMenu,
    CdkMenuItem,
    CdkMenuTrigger,
    BdiText,
    PluralPipe,
    ReadingTimePipe,
    BottomSheet,
    ProgressBar,
    EmptyState,
    ErrorState,
    PathCover,
  ],
  providers: [providePathIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pt-4 lg:pt-8' },
  template: `
    <a routerLink="/paths" class="rd-icon-btn mb-4" [attr.aria-label]="'paths.detail.backToPaths' | transloco" data-back-to-paths>
      <svg lucideIcon="ArrowRight" [size]="18" class="ltr:rotate-180" aria-hidden="true"></svg>
    </a>

    @if (path(); as p) {
      <header data-path-header>
        <rd-path-cover class="mb-4 h-36 rounded-card" [path]="p" [iconSize]="48" [eager]="true" />
        <div class="mb-2 flex flex-wrap items-center gap-2 text-xs">
          <span class="rd-tag"><rd-bdi-text [text]="field()" /></span>
          @if (completed()) {
            <span class="rd-tag bg-success/15 text-success" data-path-completed>{{ 'paths.completed' | transloco }}</span>
          }
        </div>
        <div class="flex items-start gap-2">
          <h1 class="m-0 flex-1 text-2xl font-bold leading-snug" [attr.dir]="titleDir()" data-path-title><rd-bdi-text [text]="p.title" /></h1>
          @if (signedIn() && p.enrollment) {
            <button
              type="button"
              class="rd-icon-btn h-11 w-11 shrink-0 border-0"
              [cdkMenuTriggerFor]="menu"
              [attr.aria-label]="'paths.detail.actions' | transloco"
              data-path-menu
            >
              <svg lucideIcon="EllipsisVertical" [size]="18" aria-hidden="true"></svg>
            </button>
          }
        </div>
        @if (p.description) {
          <p class="m-0 mt-2 text-text-secondary" [attr.dir]="descriptionDir()"><rd-bdi-text [text]="p.description" /></p>
        }
        <p class="m-0 mt-2 text-sm text-text-secondary" data-path-meta>
          {{ p.articleCount | rdPlural: 'reading.articles' : lang() }} · {{ p.readingTimeMinutes | rdPlural: 'reading.minutes' : lang() }}
        </p>
        @if (signedIn() && p.progress; as progress) {
          <div class="mt-3 flex items-center gap-3" data-path-progress>
            <rd-progress-bar
              class="flex-1"
              [value]="progress.percent"
              [tone]="completed() ? 'success' : 'primary'"
              [label]="'paths.progressLabel' | transloco: { read: progress.readCount, total: progress.total }"
            />
            <span class="text-sm font-semibold" dir="ltr" aria-hidden="true">{{ 'paths.progress' | transloco: { read: progress.readCount, total: progress.total } }}</span>
          </div>
        }

        <div class="mt-4" data-path-action>
          @switch (action()) {
            @case ('continue') {
              @if (p.progress?.next; as next) {
                <a class="rd-btn rd-btn-primary w-full" [routerLink]="link(next)" data-path-continue>
                  <span class="truncate">{{ 'paths.detail.continue' | transloco }} <rd-bdi-text [text]="next.title" /></span>
                  <svg lucideIcon="ArrowLeft" [size]="18" class="shrink-0 ltr:rotate-180" aria-hidden="true"></svg>
                </a>
              }
            }
            @case ('again') {
              @if (p.items[0]; as first) {
                <a class="rd-btn rd-btn-outline w-full" [routerLink]="link(first.article)" data-path-again>
                  <svg lucideIcon="RotateCw" [size]="18" aria-hidden="true"></svg>
                  {{ 'paths.detail.readAgain' | transloco }}
                </a>
              }
            }
            @default {
              <button type="button" class="rd-btn rd-btn-primary w-full" [disabled]="busy()" [attr.aria-busy]="busy()" data-path-start (click)="start()">
                @if (busy()) {
                  <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
                }
                {{ 'paths.detail.start' | transloco }}
              </button>
            }
          }
        </div>
      </header>

      @if (action() === 'again') {
        <div class="mt-5 flex items-start gap-3 rounded-card bg-success/10 p-4" role="status" data-path-celebration>
          <svg lucideIcon="PartyPopper" [size]="24" class="shrink-0 text-success" aria-hidden="true"></svg>
          <div>
            <p class="m-0 font-semibold">{{ 'paths.detail.completedTitle' | transloco }}</p>
            <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'paths.detail.completedBody' | transloco }}</p>
          </div>
        </div>
      }

      <section class="mt-6" aria-labelledby="path-items-title">
        <h2 id="path-items-title" class="m-0 mb-2 text-lg font-semibold">{{ 'paths.detail.items' | transloco }}</h2>
        <ol class="m-0 flex list-none flex-col gap-1 p-0" data-path-items>
          @for (item of p.items; track item.article.id) {
            @let isNext = item.article.id === nextId();
            <li [attr.data-path-item]="item.position" [attr.data-read]="item.isRead" [attr.data-next]="isNext || null">
              <a
                [routerLink]="link(item.article)"
                class="flex items-center gap-3 rounded-md border p-2 text-inherit no-underline transition-colors hover:bg-surface-variant"
                [class]="isNext ? 'border-primary bg-primary-container/40' : 'border-transparent'"
                [attr.aria-current]="isNext ? 'step' : null"
              >
                <span
                  class="grid h-8 w-8 shrink-0 place-items-center rounded-full text-sm font-bold"
                  [class]="item.isRead ? 'bg-success text-on-primary' : isNext ? 'bg-primary text-on-primary' : 'border border-border text-text-secondary'"
                  aria-hidden="true"
                  >{{ item.position }}</span
                >
                <span class="h-14 w-14 shrink-0 overflow-hidden rounded-md bg-primary-container" aria-hidden="true">
                  @if (item.article.coverUrl) {
                    <img [src]="item.article.coverUrl" alt="" class="h-full w-full object-cover" loading="lazy" />
                  } @else {
                    <span class="grid h-full w-full place-items-center font-mono text-xs text-on-primary-container" dir="ltr">&lt;/&gt;</span>
                  }
                </span>
                <span class="min-w-0 flex-1">
                  <span class="line-clamp-2 text-[15px] font-semibold leading-snug" [attr.dir]="dirOf(item.article.title)" [attr.lang]="item.article.language"
                    ><rd-bdi-text [text]="item.article.title"
                  /></span>
                  <span class="mt-0.5 flex flex-wrap items-center gap-2 text-xs text-text-secondary">
                    <span class="sr-only">{{ item.position }}.</span>
                    {{ item.article.readingTimeMinutes | rdReadingTime: lang() }}
                    @if (isNext) {
                      <span class="rd-tag">{{ 'paths.detail.upNext' | transloco }}</span>
                    }
                  </span>
                </span>
                @if (item.isRead) {
                  <span class="shrink-0 text-success" data-read-tick>
                    <svg lucideIcon="CircleCheck" [size]="20" aria-hidden="true"></svg>
                    <span class="sr-only">{{ 'paths.detail.read' | transloco }}</span>
                  </span>
                }
              </a>
            </li>
          }
        </ol>
      </section>

      <ng-template #menu>
        <div cdkMenu class="rounded-md border border-border bg-surface-raised p-1 shadow-raised" data-path-menu-panel>
          <button
            type="button"
            cdkMenuItem
            class="flex min-h-11 w-full items-center gap-2 rounded-sm px-3 text-start text-sm text-error hover:bg-surface-variant"
            data-path-leave
            (cdkMenuItemTriggered)="leaving.set(true)"
          >
            <svg lucideIcon="LogOut" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
            {{ 'paths.detail.leave' | transloco }}
          </button>
        </div>
      </ng-template>

      <rd-bottom-sheet
        [open]="leaving()"
        role="alertdialog"
        labelledBy="leave-path-title"
        describedBy="leave-path-body"
        [dismissible]="!busy()"
        (closed)="leaving.set(false)"
      >
        <div class="flex flex-col gap-3 pt-1" data-leave-path>
          <h2 id="leave-path-title" class="m-0 pe-10 text-xl font-semibold">
            <rd-bdi-text [text]="'paths.detail.leaveTitle' | transloco: { title: p.title }" />
          </h2>
          <p id="leave-path-body" class="m-0 text-sm text-text-secondary">{{ 'paths.detail.leaveBody' | transloco }}</p>
          <div class="mt-2 flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="leaving.set(false)">{{ 'common.cancel' | transloco }}</button>
            <button
              type="button"
              class="rd-btn flex-1 bg-error text-on-error"
              [disabled]="busy()"
              [attr.aria-busy]="busy()"
              data-confirm-leave
              (click)="leave()"
            >
              @if (busy()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ 'paths.detail.leave' | transloco }}
            </button>
          </div>
        </div>
      </rd-bottom-sheet>
    } @else if (notFound()) {
      <rd-empty-state [title]="'paths.detail.notFoundTitle' | transloco" [message]="'paths.detail.notFoundBody' | transloco" data-path-not-found>
        <a routerLink="/paths" class="rd-btn rd-btn-primary mt-3">{{ 'paths.detail.backToPaths' | transloco }}</a>
      </rd-empty-state>
    } @else if (resource.status() === 'error') {
      <rd-error-state [message]="'paths.detail.loadError' | transloco" (retry)="resource.reload()" />
    } @else {
      <div class="flex flex-col gap-3" aria-busy="true" data-path-loading>
        <div class="rd-skeleton h-36 w-full rounded-card"></div>
        <div class="rd-skeleton h-4 w-24"></div>
        <div class="rd-skeleton h-7 w-3/4"></div>
        <div class="rd-skeleton h-4 w-full"></div>
        <div class="rd-skeleton h-11 w-full"></div>
        @for (i of [1, 2, 3]; track i) {
          <div class="rd-skeleton h-16 w-full"></div>
        }
      </div>
    }
  `,
})
export class PathPage {
  private readonly api = inject(PathsApi);
  private readonly session = inject(SessionStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly router = inject(Router);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);
  private readonly responseInit = inject(RESPONSE_INIT, { optional: true });
  protected readonly lang = inject(LanguageService).lang;

  /** Route param (`/paths/{slug}`, component input binding). */
  readonly slug = input.required<string>();

  protected readonly resource = httpResource<PathDetailsDto>(() => ({
    url: this.api.pathUrl(this.slug()),
    context: new HttpContext().set(SILENT_ERRORS, true),
  }));
  protected readonly path = computed(() => (this.resource.hasValue() ? this.resource.value() : null));
  protected readonly notFound = computed(() => {
    const error = this.resource.error();
    return isApiError(error) && error.status === 404;
  });

  protected readonly signedIn = this.session.isAuthenticated;
  protected readonly action = computed<PathAction>(() => {
    const p = this.path();
    return p ? pathAction(p, this.signedIn()) : 'start';
  });
  /** The next unread article (signed in), highlighted in the list. */
  protected readonly nextId = computed(() => (this.signedIn() ? (this.path()?.progress?.next?.id ?? null) : null));
  protected readonly completed = computed(() => {
    const p = this.path();
    return !!p && this.signedIn() && isCompleted(p);
  });
  protected readonly field = computed(() => {
    const p = this.path();
    return p ? fieldName(p, this.lang()) : '';
  });
  protected readonly titleDir = computed(() => detectDir(this.path()?.title) ?? 'auto');
  protected readonly descriptionDir = computed(() => detectDir(this.path()?.description) ?? 'auto');

  protected readonly busy = signal(false);
  protected readonly leaving = signal(false);

  constructor() {
    const seo = inject(PathSeoService);
    effect(() => {
      const p = this.path();
      if (p) seo.path(p);
      else if (this.notFound()) {
        seo.notFound();
        // A real 404 for crawlers when rendered on the server.
        if (this.responseInit) this.responseInit.status = 404;
      }
    });
    inject(DestroyRef).onDestroy(() => seo.clear());
    // Your progress and enrollment once signed in (the server-rendered copy is anonymous); signing out drops them.
    reloadOnSessionChange(() => this.resource.reload());
  }

  protected link(article: PathArticleRefDto | ArticleCardDto): string[] {
    return articleLink(article);
  }

  protected dirOf(text: string): string {
    return detectDir(text) ?? 'auto';
  }

  /** Enrolls (`PUT /me/paths/{id}`), then opens the first unread article (or the first one). Guests get the prompt. */
  protected async start(): Promise<void> {
    const p = this.path();
    if (!p || this.busy() || !this.prompt.requireAuth()) return;
    this.busy.set(true);
    try {
      const card = await firstValueFrom(this.api.enroll(p.id));
      this.resource.update((current) => (current ? { ...current, ...card } : current));
      const target = card.progress?.next ?? p.items[0]?.article;
      if (target) void this.router.navigate(this.link(target));
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }

  /** Leaves the path (`DELETE /me/paths/{id}`); reading history is kept, so the progress stays on screen. */
  protected async leave(): Promise<void> {
    const p = this.path();
    if (!p || this.busy()) return;
    this.busy.set(true);
    try {
      await firstValueFrom(this.api.leave(p.id));
      this.resource.update((current) => (current ? { ...current, enrollment: null } : current));
      this.leaving.set(false);
      this.toasts.success(this.transloco.translate('paths.detail.left'));
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }
}
