import { ChangeDetectionStrategy, Component, computed, inject, input, output, signal } from '@angular/core';
import { CdkMenu, CdkMenuItem, CdkMenuTrigger } from '@angular/cdk/menu';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon, LucideIconData } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { HttpClient, HttpContext } from '@angular/common/http';
import { Router } from '@angular/router';
import { API_BASE_URL, SILENT_ERRORS } from '../../core/api/api.config';
import { ModerationApi } from '../../core/api/moderation.api';
import { ArticleCardDto, ArticleModerationDto, ModerationActionRequest } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { FollowStore } from '../../core/social/follow.store';
import { MuteStore } from '../../core/social/mute.store';
import { ModerationActionDraft, ModerationActionSheet } from '../../shared/moderation/moderation-action-sheet';
import { ModerationErrors } from '../../shared/moderation/moderation-errors';
import { provideModerationIcons } from '../../shared/moderation/moderation-icons';
import { ReportSheet, ReportTarget } from '../../shared/moderation/report-sheet';
import { MUTE_ICON } from '../../shared/mutes/mute-icons';
import { MuteTopicsSheet } from '../../shared/mutes/mute-topics-sheet';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { HIGHLIGHT_ICON } from '../highlights/highlight-icons';
import { HighlightsPrefs } from '../highlights/highlights-prefs';
import { ArticlePdfService } from '../pdf/article-pdf.service';

/** An article in the reader, with its moderation state when it is hidden (F22) and whether it is featured (F23). */
export type MenuArticle = ArticleCardDto & { moderation?: ArticleModerationDto | null; isFeatured?: boolean };

export type ArticleMenuAction =
  | 'showLess'
  | 'highlights'
  | 'follow'
  | 'muteAuthor'
  | 'muteTopics'
  | 'downloadPdf'
  | 'hide'
  | 'unhide'
  | 'report'
  // F23: admins
  | 'feature'
  | 'unfeature'
  | 'openInConsole';

/** What the items decide on: the article and where you stand with it. */
export interface ArticleMenuContext {
  article: MenuArticle;
  /** Signed in, and you wrote it. */
  isOwn: boolean;
  isModerator: boolean;
  /** You follow the writer (false for guests). */
  following: boolean;
  /** You muted the writer (false for guests). */
  authorMuted: boolean;
  /** The menu offers Download PDF (`pdf.download`, F33): the reader's menu, not a post card's. */
  pdf: boolean;
  /** That article's PDF is being built (F33): "Preparing the PDF…" (`pdf.building`), disabled, with a spinner. */
  pdfBuilding: boolean;
  /** The reader's menu: highlights are shown or hidden (F30). Absent on a post card's menu. */
  highlights?: 'shown' | 'hidden' | null;
  /** F23: `articles.feature`, and the article says whether it is featured (the reader's details do). */
  featured?: boolean | null;
  /** F23: `moderation.manage` and the console (`admin.access`): "Open in console". */
  console?: boolean;
}

type MenuIcon = string | LucideIconData;

/** One entry of {@link ARTICLE_MENU}. */
export interface ArticleMenuEntry {
  id: ArticleMenuAction;
  /** Shown when this says so; always when omitted. */
  visible?: (ctx: ArticleMenuContext) => boolean;
  labelKey: string | ((ctx: ArticleMenuContext) => string);
  icon: MenuIcon | ((ctx: ArticleMenuContext) => MenuIcon);
  /** In the error color (Report). */
  danger?: boolean;
  /** The moderators' items: after a divider, last. */
  moderation?: boolean;
  /** Working on it: disabled, with a spinning icon. */
  busy?: (ctx: ArticleMenuContext) => boolean;
  /** Its keyboard shortcut (`aria-keyshortcuts`, and the item's tooltip). */
  shortcut?: string;
}

/** An item as the menu shows it. */
export interface ArticleMenuItem {
  id: ArticleMenuAction;
  labelKey: string;
  icon: MenuIcon;
  danger: boolean;
  /** A divider goes above it: the first moderator item after the reader's items. */
  divider: boolean;
  /** Disabled, with a spinning icon (a PDF being built). */
  busy: boolean;
  shortcut: string | null;
}

const hasOtherAuthor = (c: ArticleMenuContext) => !c.isOwn && !!c.article.author;

/**
 * The "⋯" menu, in the SPEC F28 order: the one list every item comes from (the reader's action bar and the post card's
 * header). Report ends the reader's items; the moderators' Hide/Unhide come last, after a divider (the same order on
 * mobile). A later feature adds its entry here and a case in {@link ArticleMenu.run}. The reader's "إخفاء الـ
 * Highlights" (F30) comes after Show less, also on your own article. On your own article Mute topics stays. The reader
 * has Download PDF (`pdf.download`, F33) before Report for everyone, except on someone else's hidden article; guests
 * get the sign-in prompt. Follow and Mute author need a writer (not a deleted account).
 */
export const ARTICLE_MENU: readonly ArticleMenuEntry[] = [
  { id: 'showLess', visible: (c) => !c.isOwn, labelKey: 'mute.menu.showLess', icon: MUTE_ICON.ThumbsDown },
  // F30: the reader's menu only; "إظهار الـ Highlights" while they are hidden. Ctrl + / does the same.
  {
    id: 'highlights',
    visible: (c) => !!c.highlights,
    labelKey: (c) => (c.highlights === 'hidden' ? 'highlights.menu.show' : 'highlights.menu.hide'),
    icon: HIGHLIGHT_ICON.Highlighter,
    shortcut: 'Control+/',
  },
  {
    id: 'follow',
    visible: hasOtherAuthor,
    labelKey: (c) => (c.following ? 'mute.menu.unfollow' : 'mute.menu.follow'),
    icon: (c) => (c.following ? MUTE_ICON.UserMinus : 'UserPlus'),
  },
  {
    id: 'muteAuthor',
    visible: hasOtherAuthor,
    labelKey: (c) => (c.authorMuted ? 'mute.menu.unmuteAuthor' : 'mute.menu.muteAuthor'),
    icon: (c) => (c.authorMuted ? MUTE_ICON.Volume2 : MUTE_ICON.VolumeX),
  },
  { id: 'muteTopics', labelKey: 'mute.menu.muteTopics', icon: MUTE_ICON.ListX },
  // F33: the published version on screen, in the reader, for every member (guests sign in first). A hidden article (F22)
  // has no PDF: a moderator reading someone else's gets no item; its author keeps it and is told why (409).
  {
    id: 'downloadPdf',
    visible: (c) => c.pdf && (c.isOwn || !c.article.moderation),
    labelKey: (c) => (c.pdfBuilding ? 'pdf.building' : 'pdf.download'),
    icon: (c) => (c.pdfBuilding ? 'LoaderCircle' : 'Download'),
    busy: (c) => c.pdfBuilding,
  },
  // The reader's last item, in the error color; never on your own article.
  { id: 'report', visible: (c) => !c.isOwn, labelKey: 'article.menu.report', icon: 'Flag', danger: true },
  // Moderators (F22), after a divider: hide, or unhide a hidden article.
  { id: 'hide', visible: (c) => c.isModerator && !c.article.moderation, labelKey: 'article.menu.hide', icon: 'EyeOff', moderation: true },
  { id: 'unhide', visible: (c) => c.isModerator && !!c.article.moderation, labelKey: 'article.menu.unhide', icon: 'Eye', moderation: true },
  // Admins (F23): feature or unfeature (`articles.feature`, the reader only), and the article's console page.
  { id: 'feature', visible: (c) => c.featured === false, labelKey: 'article.menu.feature', icon: 'Sparkles', moderation: true },
  { id: 'unfeature', visible: (c) => c.featured === true, labelKey: 'article.menu.unfeature', icon: 'Sparkles', moderation: true },
  { id: 'openInConsole', visible: (c) => !!c.console, labelKey: 'article.menu.openInConsole', icon: 'LayoutDashboard', moderation: true },
];

/** The items of {@link ARTICLE_MENU} shown for `ctx`, with their labels and icons resolved. */
export function articleMenuItems(ctx: ArticleMenuContext): ArticleMenuItem[] {
  const shown = ARTICLE_MENU.filter((entry) => entry.visible?.(ctx) ?? true);
  return shown.map((entry, i) => ({
    id: entry.id,
    labelKey: typeof entry.labelKey === 'function' ? entry.labelKey(ctx) : entry.labelKey,
    icon: typeof entry.icon === 'function' ? entry.icon(ctx) : entry.icon,
    danger: entry.danger ?? false,
    divider: i > 0 && !!entry.moderation && !shown[i - 1].moderation,
    busy: entry.busy?.(ctx) ?? false,
    shortcut: entry.shortcut ?? null,
  }));
}

/**
 * The "⋯" menu of the reader's action bar and the post card's header (F28, F22, F34). Guests get the sign-in prompt for
 * every item. Show less and Mute author confirm with a toast and Undo, and the cards they concern leave the lists on
 * screen (MuteStore, PostCard); in the reader, a muted writer's article shows the "انت كاتم الكاتب ده" banner instead.
 * Mute topics opens a sheet with the field and topic toggles (its own lazy chunk). In the reader, admins with
 * `articles.feature` also Feature / Unfeature it (F23, confirmed), and with the console "Open in console" goes to its
 * console page. Moderators also Hide (with a note
 * dialog) or Unhide the article; the new moderation state goes up through `moderationChange`, so the reader shows or
 * drops the "hidden" banner at once. In the reader (`pdf`), every article but someone else's hidden one also has
 * Download PDF (F33): a normal download of the version on screen, "Preparing the PDF…" (`pdf.building`) and disabled
 * while it is built ({@link ArticlePdfService}).
 */
@Component({
  selector: 'rd-article-menu',
  imports: [TranslocoPipe, LucideDynamicIcon, CdkMenu, CdkMenuItem, CdkMenuTrigger, ReportSheet, ModerationActionSheet, MuteTopicsSheet, BottomSheet],
  providers: [provideModerationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents' },
  template: `
    @if (items().length) {
      <button
        type="button"
        class="rd-icon-btn h-11 w-11 border-0"
        [cdkMenuTriggerFor]="menu"
        [attr.aria-label]="'article.menu.label' | transloco"
        data-article-menu
      >
        <svg lucideIcon="Ellipsis" [size]="20" aria-hidden="true"></svg>
      </button>
    }

    <ng-template #menu>
      <div cdkMenu class="min-w-56 rounded-md border border-border bg-surface-raised p-1 shadow-raised" data-article-menu-panel>
        @for (item of items(); track item.id) {
          @if (item.divider) {
            <div role="separator" class="mx-2 my-1 h-px bg-border" data-menu-divider></div>
          }
          <button
            type="button"
            cdkMenuItem
            class="flex min-h-11 w-full items-center gap-2 rounded-sm px-3 text-start text-sm hover:bg-surface-variant aria-disabled:cursor-not-allowed aria-disabled:opacity-55"
            [class]="item.danger ? 'text-error' : 'text-text-primary'"
            [cdkMenuItemDisabled]="item.busy"
            [attr.data-menu-action]="item.id"
            [attr.data-state]="item.id === 'downloadPdf' ? (item.busy ? 'building' : 'idle') : null"
            [attr.aria-keyshortcuts]="item.shortcut"
            [attr.title]="item.shortcut ? 'Ctrl + /' : null"
            (cdkMenuItemTriggered)="run(item.id)"
          >
            <svg [lucideIcon]="item.icon" [size]="16" [class.animate-spin]="item.busy" aria-hidden="true"></svg>
            {{ item.labelKey | transloco }}
          </button>
        }
      </div>
    </ng-template>

    <rd-report-sheet [target]="reporting()" (closed)="reporting.set(null)" />
    <rd-moderation-action-sheet [draft]="moderating()" (done)="onModerated($event)" (closed)="moderating.set(null)" />
    <!-- F23: featuring asks first -->
    <rd-bottom-sheet [open]="!!featuring()" role="alertdialog" labelledBy="feature-sheet-title" describedBy="feature-sheet-body" [dismissible]="!featureBusy()" (closed)="featuring.set(null)">
      @if (featuring(); as action) {
        <div class="flex flex-col gap-3 pt-1" data-feature-sheet>
          <h2 id="feature-sheet-title" class="m-0 pe-10 text-xl font-semibold">{{ (action === 'feature' ? 'admin.content.confirmFeature.title' : 'admin.content.confirmUnfeature.title') | transloco }}</h2>
          <p id="feature-sheet-body" class="m-0 text-sm text-text-secondary">{{ (action === 'feature' ? 'admin.content.confirmFeature.body' : 'admin.content.confirmUnfeature.body') | transloco }}</p>
          @if (featureError()) {
            <p class="rd-alert rd-alert-error m-0" role="alert">{{ featureError() }}</p>
          }
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="featureBusy()" (click)="featuring.set(null)">{{ 'common.cancel' | transloco }}</button>
            <button type="button" class="rd-btn rd-btn-primary flex-1" [disabled]="featureBusy()" (click)="setFeatured()" data-feature-confirm>{{ 'admin.confirm.ok' | transloco }}</button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
    <!-- The topics sheet is its own chunk, loaded the first time it opens; it stays so it can give focus back. -->
    @if (topicsUsed()) {
      @defer (on immediate) {
        <rd-mute-topics-sheet [article]="topics()" (closed)="closeTopics()" />
      }
    }
  `,
})
export class ArticleMenu {
  private readonly session = inject(SessionStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly api = inject(ModerationApi);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ModerationErrors);
  private readonly follows = inject(FollowStore);
  private readonly mutes = inject(MuteStore);
  private readonly pdfs = inject(ArticlePdfService);
  private readonly highlightPrefs = inject(HighlightsPrefs);
  // F23's two featuring calls go straight to HttpClient: the post cards' chunk shouldn't carry the console's API.
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly router = inject(Router);

  readonly article = input.required<MenuArticle>();
  /** The reader's menu: Download PDF (F33), but not on someone else's hidden article. A post card's menu has none. */
  readonly pdf = input(false);
  /** The reader's menu: "إخفاء الـ Highlights" / "إظهار الـ Highlights" (F30). A post card's menu doesn't have it. */
  readonly highlights = input(false);
  /** Hidden (the new state) or visible again (null), after a moderator's action. */
  readonly moderationChange = output<ArticleModerationDto | null>();
  /**
   * The topics sheet opened (true) or closed (false). It is drawn inside this menu, so a post card holds its fold while
   * its own sheet is open (a toggle can mute the card itself) and folds once it closes (F28).
   */
  readonly topicsSheetOpen = output<boolean>();

  protected readonly reporting = signal<ReportTarget | null>(null);
  protected readonly moderating = signal<ModerationActionDraft | null>(null);
  protected readonly topics = signal<MenuArticle | null>(null);
  protected readonly topicsUsed = signal(false);
  /** F23: the feature dialog, and the featured state after an admin changed it here (by article id). */
  protected readonly featuring = signal<'feature' | 'unfeature' | null>(null);
  protected readonly featureBusy = signal(false);
  protected readonly featureError = signal<string | null>(null);
  private readonly featuredNow = signal<Record<string, boolean>>({});

  private readonly context = computed<ArticleMenuContext>(() => {
    const article = this.article();
    const signedIn = this.session.isAuthenticated();
    const author = article.author;
    return {
      article,
      isOwn: signedIn && !!author && this.session.me()?.id === author.id,
      isModerator: this.session.permissions().has('moderation.manage'),
      following: signedIn && !!author && this.follows.isFollowing(author.id, article.isFollowingAuthor),
      authorMuted: signedIn && !!author && this.mutes.isAuthorMuted(author.id, article.isAuthorMuted ?? false),
      pdf: this.pdf(),
      pdfBuilding: this.pdfs.isBuilding(article.id),
      highlights: this.highlights() ? (this.highlightPrefs.visible() ? 'shown' : 'hidden') : null,
      featured: this.session.permissions().has('articles.feature') && article.isFeatured !== undefined ? (this.featuredNow()[article.id] ?? article.isFeatured) : null,
      console: this.session.permissions().has('moderation.manage') && this.session.permissions().has('admin.access'),
    };
  });

  protected readonly items = computed(() => articleMenuItems(this.context()));

  protected run(action: ArticleMenuAction): void {
    // Guests can hide highlights too: their device keeps the choice (F30).
    if (action === 'highlights') {
      void this.highlightPrefs.toggle();
      return;
    }
    if (!this.prompt.requireAuth()) return;
    const { article, authorMuted } = this.context();
    const author = article.author;
    switch (action) {
      case 'showLess':
        void this.mutes.showLess(article.id);
        return;
      case 'follow':
        if (author) void this.follows.toggle(author.id, article.isFollowingAuthor);
        return;
      case 'muteAuthor':
        if (author) void (authorMuted ? this.mutes.unmuteAuthor(author) : this.mutes.muteAuthor(author));
        return;
      case 'muteTopics':
        this.topicsUsed.set(true);
        this.topics.set(article);
        this.topicsSheetOpen.emit(true);
        return;
      case 'downloadPdf':
        // The version on screen; a second press while it builds does nothing (the item is disabled too).
        void this.pdfs.download(article.id, article.language);
        return;
      case 'report':
        this.reporting.set({ type: 'article', id: article.id });
        return;
      case 'hide':
        this.moderating.set({ action: 'hide', targetType: 'article', targetId: article.id });
        return;
      case 'unhide':
        void this.unhide(article.id);
        return;
      case 'feature':
      case 'unfeature':
        this.featureError.set(null);
        this.featuring.set(action);
        return;
      case 'openInConsole':
        void this.router.navigate(['/admin/content', article.id]);
        return;
    }
  }

  /** Feature or unfeature (F23), after the dialog: `PUT` / `DELETE /admin/articles/{id}/featured`. */
  protected async setFeatured(): Promise<void> {
    const action = this.featuring();
    const id = this.article().id;
    if (!action || this.featureBusy()) return;
    this.featureBusy.set(true);
    this.featureError.set(null);
    try {
      const url = `${this.base}/admin/articles/${encodeURIComponent(id)}/featured`;
      const context = new HttpContext().set(SILENT_ERRORS, true);
      await firstValueFrom(action === 'feature' ? this.http.put<void>(url, null, { context }) : this.http.delete<void>(url, { context }));
      this.featuredNow.update((map) => ({ ...map, [id]: action === 'feature' }));
      this.toasts.success(this.transloco.translate(action === 'feature' ? 'admin.content.featuredDone' : 'admin.content.unfeaturedDone'));
      this.featureBusy.set(false);
      this.featuring.set(null);
    } catch (error) {
      this.featureError.set(this.errors.message(error));
    } finally {
      this.featureBusy.set(false);
    }
  }

  protected closeTopics(): void {
    this.topics.set(null);
    this.topicsSheetOpen.emit(false);
  }

  protected onModerated(request: ModerationActionRequest): void {
    if (request.action === 'hide') this.moderationChange.emit({ hiddenAt: new Date().toISOString(), note: request.note ?? null });
  }

  /** Unhiding is not destructive: no dialog, a toast. */
  private async unhide(articleId: string): Promise<void> {
    try {
      await firstValueFrom(this.api.act({ action: 'unhide', targetType: 'article', targetId: articleId }));
      this.toasts.success(this.transloco.translate('moderation.actions.done.unhide'));
      this.moderationChange.emit(null);
    } catch (error) {
      this.toasts.error(this.errors.message(error));
    }
  }
}
