import { ChangeDetectionStrategy, Component, computed, inject, input, output, signal } from '@angular/core';
import { CdkMenu, CdkMenuItem, CdkMenuTrigger } from '@angular/cdk/menu';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ModerationApi } from '../../core/api/moderation.api';
import { ArticleCardDto, ArticleModerationDto, ModerationActionRequest } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { ModerationActionDraft, ModerationActionSheet } from '../../shared/moderation/moderation-action-sheet';
import { ModerationErrors } from '../../shared/moderation/moderation-errors';
import { provideModerationIcons } from '../../shared/moderation/moderation-icons';
import { ReportSheet, ReportTarget } from '../../shared/moderation/report-sheet';
import { ToastService } from '../../shared/ui/toast/toast.service';

/** An article in the reader, with its moderation state when it is hidden (F22). */
export type MenuArticle = ArticleCardDto & { moderation?: ArticleModerationDto | null };

/**
 * One entry of the reader's "⋯" menu. F28 adds Show less, Hide highlights, Follow, Mute author and Mute topics here:
 * give the item an id, a label, an icon and a case in {@link ArticleMenu.run}.
 */
export interface ArticleMenuItem {
  id: ArticleMenuAction;
  labelKey: string;
  icon: string;
  /** Shown in the error color (Report). */
  danger?: boolean;
}

export type ArticleMenuAction = 'hide' | 'unhide' | 'report';

/**
 * The reader's "⋯" menu (F22 now, F28 later). Report article (error color) for everyone but its author; guests get
 * the sign-in prompt for every item. Moderators also Hide (with a note dialog) or Unhide the article; the new
 * moderation state goes up through `moderationChange`, so the reader shows or drops the "hidden" banner at once.
 */
@Component({
  selector: 'rd-article-menu',
  imports: [TranslocoPipe, LucideDynamicIcon, CdkMenu, CdkMenuItem, CdkMenuTrigger, ReportSheet, ModerationActionSheet],
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
      <div cdkMenu class="min-w-52 rounded-md border border-border bg-surface-raised p-1 shadow-raised" data-article-menu-panel>
        @for (item of items(); track item.id) {
          <button
            type="button"
            cdkMenuItem
            class="flex min-h-11 w-full items-center gap-2 rounded-sm px-3 text-start text-sm hover:bg-surface-variant"
            [class]="item.danger ? 'text-error' : 'text-text-primary'"
            [attr.data-menu-action]="item.id"
            (cdkMenuItemTriggered)="run(item.id)"
          >
            <svg [lucideIcon]="item.icon" [size]="16" aria-hidden="true"></svg>
            {{ item.labelKey | transloco }}
          </button>
        }
      </div>
    </ng-template>

    <rd-report-sheet [target]="reporting()" (closed)="reporting.set(null)" />
    <rd-moderation-action-sheet [draft]="moderating()" (done)="onModerated($event)" (closed)="moderating.set(null)" />
  `,
})
export class ArticleMenu {
  private readonly session = inject(SessionStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly api = inject(ModerationApi);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ModerationErrors);

  readonly article = input.required<MenuArticle>();
  /** Hidden (the new state) or visible again (null), after a moderator's action. */
  readonly moderationChange = output<ArticleModerationDto | null>();

  protected readonly reporting = signal<ReportTarget | null>(null);
  protected readonly moderating = signal<ModerationActionDraft | null>(null);

  private readonly isOwn = computed(() => this.session.isAuthenticated() && this.session.me()?.id === this.article().author.id);
  private readonly isModerator = computed(() => this.session.permissions().has('moderation.manage'));

  protected readonly items = computed<ArticleMenuItem[]>(() => {
    const items: ArticleMenuItem[] = [];
    if (this.isModerator()) {
      items.push(
        this.article().moderation
          ? { id: 'unhide', labelKey: 'article.menu.unhide', icon: 'Eye' }
          : { id: 'hide', labelKey: 'article.menu.hide', icon: 'EyeOff' },
      );
    }
    // Last, in the error color; never on your own article.
    if (!this.isOwn()) items.push({ id: 'report', labelKey: 'article.menu.report', icon: 'Flag', danger: true });
    return items;
  });

  protected run(action: ArticleMenuAction): void {
    if (!this.prompt.requireAuth()) return;
    const article = this.article();
    switch (action) {
      case 'report':
        this.reporting.set({ type: 'article', id: article.id });
        return;
      case 'hide':
        this.moderating.set({ action: 'hide', targetType: 'article', targetId: article.id });
        return;
      case 'unhide':
        void this.unhide(article.id);
        return;
    }
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
