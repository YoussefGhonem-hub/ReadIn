import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
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

let nextHintId = 0;

/**
 * Repost (F29) in the post card's action bar (`card`, between Comment and Share) and in the reader's bar (`bar`, next
 * to the comments): the icon with the count beside it (no number at 0), pressed when you reposted. A tap toggles at once
 * and rolls back with the error when the API refuses (ArticleSocialStore). Guests get the sign-in prompt and nothing is
 * sent. On your own article it stays focusable but disabled (`aria-disabled`), with the hint "مينفعش تعيد نشر مقالك"
 * as its description, its tooltip and, when pressed, a toast.
 */
@Component({
  selector: 'rd-repost-button',
  imports: [TranslocoPipe, LucideDynamicIcon, CompactNumberPipe],
  providers: [providePostBarIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents' },
  template: `
    <button
      type="button"
      data-repost
      [class]="classes()"
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

  protected tap(): void {
    if (this.own()) {
      this.toasts.info(this.transloco.translate('postBar.repostOwn'));
      return;
    }
    if (!this.prompt.requireAuth()) return;
    void this.social.toggleRepost(this.article());
  }
}
