import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { CdkMenu, CdkMenuItem, CdkMenuTrigger } from '@angular/cdk/menu';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleCardDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { CompactNumberPipe } from '../../shared/pipes/format.pipes';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { providePostBarIcons } from './post-bar-icons';
import { RepostDialog } from './repost-dialog';
import type { RepostDialogMode, RepostDialogRequest } from './repost-dialog';

let nextHintId = 0;

/** The Repost menu's items: what each does depends on whether you reposted the article. */
export type RepostMenuAction = 'repost' | 'thoughts' | 'edit' | 'undo';

/**
 * Repost (F29) in the post card's action bar (`card`, between Comment and Share) and in the reader's bar (`bar`, next
 * to the comments): the icon with the count beside it (no number at 0), pressed when you reposted. A tap opens a small
 * menu (CDK menu: arrow keys, Escape and focus back on the button, placed on the reading side):
 * - not reposted yet: "أعد النشر" reposts at once (optimistic, rolled back with the error when the API refuses,
 *   ArticleSocialStore) and "أعد النشر مع رأيك" opens the caption dialog;
 * - reposted: "عدّل رأيك" opens the dialog prefilled with your thoughts, and "إلغاء إعادة النشر" undoes the repost at
 *   once (optimistic).
 *
 * Guests get the sign-in prompt and no menu; nothing is sent. On your own article it stays focusable but disabled
 * (`aria-disabled`), with the hint "مينفعش تعيد نشر مقالك" as its description, its tooltip and, when pressed, a toast.
 * The dialog (repost-dialog.ts) is its own chunk, loaded the first time it opens.
 */
@Component({
  selector: 'rd-repost-button',
  imports: [TranslocoPipe, LucideDynamicIcon, CompactNumberPipe, CdkMenu, CdkMenuItem, CdkMenuTrigger, RepostDialog],
  providers: [providePostBarIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents' },
  template: `
    <button
      type="button"
      data-repost
      [class]="classes()"
      [cdkMenuTriggerFor]="hasMenu() ? menu : null"
      [attr.aria-pressed]="own() ? null : state().isReposted"
      [attr.aria-disabled]="own() ? true : null"
      [attr.aria-describedby]="own() ? hintId : null"
      [attr.title]="own() ? ('postBar.repostOwn' | transloco) : null"
      [attr.aria-label]="label()"
      [attr.data-reposted]="state().isReposted ? true : null"
      (click)="tap()"
    >
      <svg lucideIcon="Repeat2" [size]="variant() === 'card' ? 20 : 18" aria-hidden="true"></svg>
      @if (state().repostCount > 0) {
        <span aria-hidden="true" data-repost-count>{{ state().repostCount | rdCompactNumber: lang() }}</span>
      }
    </button>
    @if (own()) {
      <span [id]="hintId" class="sr-only">{{ 'postBar.repostOwn' | transloco }}</span>
    }

    <ng-template #menu>
      <div cdkMenu class="min-w-56 rounded-md border border-border bg-surface-raised p-1 shadow-raised" data-repost-menu>
        @for (item of items(); track item.id) {
          <button
            type="button"
            cdkMenuItem
            class="flex min-h-11 w-full items-center gap-2 rounded-sm px-3 text-start text-sm text-text-primary hover:bg-surface-variant"
            [attr.data-repost-action]="item.id"
            (cdkMenuItemTriggered)="run(item.id)"
          >
            <svg [lucideIcon]="item.icon" [size]="16" aria-hidden="true"></svg>
            {{ item.labelKey | transloco }}
          </button>
        }
      </div>
    </ng-template>

    <!-- The caption dialog is its own chunk, loaded the first time it opens; it stays so it can give focus back. -->
    @if (dialogUsed()) {
      @defer (on immediate) {
        <rd-repost-dialog [request]="dialog()" (closed)="dialog.set(null)" />
      }
    }
  `,
})
export class RepostButton {
  private readonly social = inject(ArticleSocialStore);
  private readonly session = inject(SessionStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;
  protected readonly hintId = `repost-hint-${nextHintId++}`;

  readonly article = input.required<ArticleCardDto>();
  /** `card`: the post card's icon button. `bar`: the reader's floating action bar. */
  readonly variant = input<'card' | 'bar'>('card');

  protected readonly state = computed(() => this.social.state(this.article()));
  /** Your own article: `repost.own_article`, so the button never sends. */
  protected readonly own = computed(() => {
    const author = this.article().author;
    return !!author && this.session.isAuthenticated() && this.session.me()?.id === author.id;
  });
  /** Signed in and not your article: the tap opens the menu. Guests and your own article get their answer instead. */
  protected readonly hasMenu = computed(() => this.session.isAuthenticated() && !this.own());

  protected readonly items = computed(() =>
    this.state().isReposted
      ? [
          { id: 'edit' as const, labelKey: 'postBar.editThoughts', icon: 'PenLine' },
          { id: 'undo' as const, labelKey: 'postBar.undoRepost', icon: 'Undo2' },
        ]
      : [
          { id: 'repost' as const, labelKey: 'postBar.repostNow', icon: 'Repeat2' },
          { id: 'thoughts' as const, labelKey: 'postBar.repostWithThoughts', icon: 'PenLine' },
        ],
  );

  protected readonly dialog = signal<RepostDialogRequest | null>(null);
  protected readonly dialogUsed = signal(false);

  protected readonly label = computed(() => {
    this.lang();
    const count = this.state().repostCount;
    return count > 0 ? this.transloco.translate('postBar.repostCount', { count }) : this.transloco.translate('postBar.repost');
  });

  protected readonly classes = computed(() => {
    const on = this.state().isReposted;
    const tone = this.own() ? 'cursor-not-allowed text-text-secondary opacity-50' : on ? 'text-primary' : 'text-text-secondary';
    const shape =
      this.variant() === 'card'
        ? 'flex min-h-11 min-w-11 items-center justify-center gap-1.5 rounded-md px-2.5 text-sm font-semibold'
        : 'inline-flex h-11 min-w-10 items-center justify-center gap-1.5 rounded-md px-1.5 text-sm font-semibold sm:min-w-11 sm:px-2';
    return `${shape} ${tone} ${this.own() ? '' : 'hover:bg-surface-variant'}`;
  });

  /** The menu opens by itself (CdkMenuTrigger); without one, your own article answers with the hint, guests sign in. */
  protected tap(): void {
    if (this.hasMenu()) return;
    if (this.own()) {
      this.toasts.info(this.transloco.translate('postBar.repostOwn'));
      return;
    }
    this.prompt.requireAuth();
  }

  protected run(action: RepostMenuAction): void {
    const article = this.article();
    switch (action) {
      case 'repost':
        void this.social.setReposted(article, true);
        return;
      case 'undo':
        void this.social.setReposted(article, false);
        return;
      case 'thoughts':
        this.openDialog('new');
        return;
      case 'edit':
        this.openDialog('edit');
        return;
    }
  }

  private openDialog(mode: RepostDialogMode): void {
    this.dialogUsed.set(true);
    this.dialog.set({ article: this.article(), mode });
  }
}
