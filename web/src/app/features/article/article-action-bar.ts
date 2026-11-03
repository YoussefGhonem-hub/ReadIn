import { ChangeDetectionStrategy, Component, PLATFORM_ID, inject, input } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { CompactNumberPipe } from '../../shared/pipes/format.pipes';
import { ToastService } from '../../shared/ui/toast/toast.service';

interface ReactionOption {
  type: 'insightful' | 'love' | 'fire' | 'mindBlown';
  emoji: string;
}

/**
 * Floating action bar (F04): reactions, comments, save, share. Reactions/comments/saves ship with F10, F11 and
 * F13; until then guests get the sign-in prompt and members a "coming soon" note. Share works now.
 */
@Component({
  selector: 'rd-article-action-bar',
  imports: [TranslocoPipe, CompactNumberPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'fixed inset-x-0 bottom-0 z-30 block border-t border-border bg-surface pb-[env(safe-area-inset-bottom)] shadow-raised',
  },
  template: `
    <div class="mx-auto flex h-16 max-w-[720px] items-center justify-between gap-1 px-3">
      <div class="flex items-center gap-1" role="group" [attr.aria-label]="'article.reactions.label' | transloco">
        @for (reaction of reactions; track reaction.type) {
          <button
            type="button"
            class="flex min-w-11 flex-col items-center rounded-md px-2 py-1 text-[11px] text-text-secondary hover:bg-surface-variant"
            [attr.aria-label]="'article.reactions.' + reaction.type | transloco"
            (click)="interact()"
          >
            <span class="text-lg leading-none" aria-hidden="true">{{ reaction.emoji }}</span>
            @if ($first) {
              <span>{{ reactionCount() | rdCompactNumber: lang() }}</span>
            }
          </button>
        }
      </div>
      <div class="flex items-center gap-1">
        <button type="button" class="rd-btn min-h-10 bg-primary-container px-3 text-sm text-on-primary-container" (click)="interact()">
          <svg lucideIcon="MessageCircle" [size]="16" aria-hidden="true"></svg>
          {{ commentCount() | rdCompactNumber: lang() }}
          <span class="sr-only">{{ 'article.comments' | transloco }}</span>
        </button>
        <button type="button" class="rd-icon-btn border-0" [attr.aria-label]="'article.save' | transloco" (click)="interact()">
          <svg lucideIcon="Bookmark" [size]="18"></svg>
        </button>
        <button type="button" class="rd-icon-btn border-0" [attr.aria-label]="'common.share' | transloco" (click)="share()">
          <svg lucideIcon="Share2" [size]="18"></svg>
        </button>
      </div>
    </div>
  `,
})
export class ArticleActionBar {
  private readonly prompt = inject(AuthPromptService);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  protected readonly lang = inject(LanguageService).lang;

  readonly title = input.required<string>();
  readonly url = input.required<string>();
  readonly reactionCount = input(0);
  readonly commentCount = input(0);

  protected readonly reactions: ReactionOption[] = [
    { type: 'insightful', emoji: '💡' },
    { type: 'love', emoji: '❤️' },
    { type: 'fire', emoji: '🔥' },
    { type: 'mindBlown', emoji: '🤯' },
  ];

  protected interact(): void {
    if (this.prompt.requireAuth()) this.toasts.info(this.transloco.translate('common.comingSoonShort'));
  }

  /** Web Share API when available, otherwise copy the link (F24 basics). */
  protected async share(): Promise<void> {
    if (!this.isBrowser) return;
    const data = { title: this.title(), url: this.url() };
    try {
      if (navigator.share) {
        await navigator.share(data);
        return;
      }
      await navigator.clipboard.writeText(data.url);
      this.toasts.success(this.transloco.translate('common.linkCopied'));
    } catch {
      /* share sheet dismissed */
    }
  }
}
