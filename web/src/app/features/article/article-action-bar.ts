import { ChangeDetectionStrategy, Component, computed, inject, input, output, signal } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleModerationDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { CompactNumberPipe, translatePlural } from '../../shared/pipes/format.pipes';
import { ShareService } from '../../shared/social/share.service';
import { RepostButton } from '../feed/repost-button';
import { ArticleMenu, MenuArticle } from './article-menu';
import { ReactionButton } from './reaction-button';
import { REACTION_EMOJI, topReactions } from './reactions';
import { ReactorsSheet } from './reactors-sheet';

/**
 * Floating action bar of the reader (F04, F10, F11, F13, F29): the reaction button, who reacted, comments (the count; a
 * tap takes you to them), Repost with its count, save, share and the "⋯" menu (F22 report and moderation; F28 adds
 * more; F30 Hide highlights). The reaction button (reaction-button.ts, shared with the post card) reacts 💡 on a tap and removes your reaction
 * when you have one; holding it (touch), hovering it (mouse), its ⌃ button or ArrowUp open the floating reactions bar.
 * Guests get the soft sign-in prompt. Counts come from ArticleSocialStore (optimistic, live counters on top).
 */
@Component({
  selector: 'rd-article-action-bar',
  imports: [TranslocoPipe, CompactNumberPipe, LucideDynamicIcon, ReactorsSheet, ArticleMenu, ReactionButton, RepostButton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'fixed inset-x-0 bottom-0 z-30 block border-t border-border bg-surface pb-[env(safe-area-inset-bottom)] shadow-raised',
  },
  template: `
    <div class="mx-auto flex h-16 max-w-[720px] items-center justify-between gap-1 px-2 sm:px-3">
      <!-- Phones: tighter gaps and one reaction emoji (and no total below 400 px: it stays in the label), so the bar fits
           with Repost (F29) at 360 px -->
      <div class="relative flex min-w-0 items-center gap-0.5 sm:gap-1" data-reactions>
        <rd-reaction-button [article]="article()" />

        <button
          type="button"
          data-reactions-summary
          class="flex h-11 min-w-10 items-center gap-1.5 rounded-md px-1.5 text-sm text-text-secondary hover:bg-surface-variant disabled:cursor-default disabled:hover:bg-transparent sm:min-w-11 sm:px-2"
          [disabled]="state().reactionCount === 0"
          [attr.aria-label]="summaryLabel()"
          (click)="whoOpen.set(true)"
        >
          @if (topTypes().length) {
            <span class="flex items-center" aria-hidden="true">
              @for (type of topTypes(); track type; let first = $first) {
                <span class="-ms-1 text-base leading-none first:ms-0" [class.max-sm:hidden]="!first">{{ emoji[type] }}</span>
              }
            </span>
          }
          <span class="max-[399px]:hidden" aria-hidden="true" data-reaction-total>{{ state().reactionCount | rdCompactNumber: lang() }}</span>
        </button>
      </div>

      <div class="flex shrink-0 items-center gap-0.5 sm:gap-1">
        <button
          type="button"
          class="inline-flex min-h-11 items-center gap-1 rounded-md bg-primary-container px-2 text-sm font-semibold text-on-primary-container sm:gap-1.5 sm:px-3"
          aria-controls="comments"
          data-comment-count
          (click)="commentsOpen.emit()"
        >
          <svg lucideIcon="MessageCircle" [size]="16" aria-hidden="true"></svg>
          {{ state().commentCount | rdCompactNumber: lang() }}
          <span class="sr-only">{{ 'article.comments' | transloco }}</span>
        </button>
        <rd-repost-button [article]="article()" variant="bar" />
        <button
          type="button"
          class="rd-icon-btn h-11 w-10 border-0 sm:w-11"
          [class.text-primary]="state().isSaved"
          data-save
          [attr.aria-pressed]="state().isSaved"
          [attr.aria-label]="'article.save' | transloco"
          (click)="toggleSave()"
        >
          <svg lucideIcon="Bookmark" [size]="20" [class.fill-current]="state().isSaved" aria-hidden="true"></svg>
        </button>
        <button type="button" class="rd-icon-btn h-11 w-10 border-0 sm:w-11" [attr.aria-label]="'common.share' | transloco" (click)="share()">
          <svg lucideIcon="Share2" [size]="18" aria-hidden="true"></svg>
        </button>
        <rd-article-menu [article]="article()" [pdf]="true" [highlights]="true" (moderationChange)="moderationChange.emit($event)" />
      </div>
    </div>

    <rd-reactors-sheet
      [open]="whoOpen()"
      [articleId]="article().id"
      [counts]="state().reactions"
      [total]="state().reactionCount"
      (closed)="whoOpen.set(false)"
    />
  `,
})
export class ArticleActionBar {
  private readonly prompt = inject(AuthPromptService);
  private readonly social = inject(ArticleSocialStore);
  private readonly sharing = inject(ShareService);
  private readonly transloco = inject(TranslocoService);
  private readonly language = inject(LanguageService);
  protected readonly lang = this.language.lang;
  protected readonly emoji = REACTION_EMOJI;

  readonly article = input.required<MenuArticle>();
  readonly url = input.required<string>();
  /** The comment count was pressed: the reader scrolls to the comments (F11). */
  readonly commentsOpen = output<void>();
  /** A moderator hid the article (its new state) or made it visible again (null), from the "⋯" menu (F22). */
  readonly moderationChange = output<ArticleModerationDto | null>();

  protected readonly state = computed(() => this.social.state(this.article()));
  protected readonly whoOpen = signal(false);

  /** The most used reactions first, for the "who reacted" button. */
  protected readonly topTypes = computed(() => topReactions(this.state().reactions));

  protected readonly summaryLabel = computed(() => {
    const lang = this.lang();
    const count = translatePlural(this.transloco, 'article.reactions.count', this.state().reactionCount, lang);
    return this.transloco.translate('article.reactions.summary', { count });
  });

  protected toggleSave(): void {
    if (!this.prompt.requireAuth()) return;
    void this.social.toggleSave(this.article());
  }

  /** Web Share API when available, otherwise copy the link (F24 basics). */
  protected share(): Promise<void> {
    return this.sharing.share({ title: this.article().title, url: this.url() });
  }
}
