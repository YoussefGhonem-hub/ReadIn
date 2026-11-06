import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { FollowStore } from '../../core/social/follow.store';

/**
 * Follow / Following (F12). Hidden on yourself; guests get the soft sign-in prompt. Optimistic through FollowStore,
 * so every button for the same writer changes together.
 */
@Component({
  selector: 'rd-follow-button',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents' },
  template: `
    @if (!isSelf()) {
      <button
        type="button"
        data-follow
        [class]="classes()"
        [attr.aria-pressed]="following()"
        (click)="toggle()"
      >
        @if (!inline()) {
          <svg [lucideIcon]="icon()" [size]="16" aria-hidden="true"></svg>
        }
        {{ (following() ? 'article.following' : 'article.follow') | transloco }}
        <span class="sr-only">{{ user().displayName }}</span>
      </button>
    }
  `,
})
export class FollowButton {
  private readonly follows = inject(FollowStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly session = inject(SessionStore);

  readonly user = input.required<{ id: string; displayName: string }>();
  /** What the API said when the page loaded (`isFollowingAuthor`, `UserSummaryDto.isFollowing`). */
  readonly initial = input(false);
  /** A text button in the primary color ("+ متابعة"), for the post card's header (F34). */
  readonly compact = input(false);
  /** An outlined pill ("+ متابعة", then "✓ بتتابعه"), for Home's suggestions card. */
  readonly pill = input(false);
  /**
   * Text only, no icon ("متابعة" in the primary color, then "تتابعه"), for a comment's header after the name: 13 px and
   * no taller than the name's line, with a 28 px target.
   */
  readonly inline = input(false);
  /** A full-width filled button, for the profile card that opens on a name or a mention. */
  readonly wide = input(false);

  protected readonly isSelf = computed(() => this.session.isAuthenticated() && this.session.me()?.id === this.user().id);
  protected readonly following = computed(() => this.session.isAuthenticated() && this.follows.isFollowing(this.user().id, this.initial()));

  protected readonly icon = computed(() => {
    if (this.following()) return this.pill() ? 'Check' : 'UserCheck';
    return this.compact() || this.pill() ? 'Plus' : 'UserPlus';
  });

  protected readonly classes = computed(() => {
    if (this.inline()) {
      const base = '-my-1 inline-flex min-h-7 shrink-0 items-center rounded-sm px-1 text-[13px] font-semibold hover:underline ';
      return base + (this.following() ? 'text-text-secondary' : 'text-primary');
    }
    if (this.wide()) {
      return 'rd-btn w-full gap-1.5 text-sm ' +(this.following() ? 'bg-primary-container text-on-primary-container' : 'rd-btn-primary');
    }
    if (this.pill()) {
      const base = 'inline-flex min-h-9 shrink-0 cursor-pointer items-center gap-1 rounded-chip border px-4 text-sm font-semibold transition-colors ';
      return base + (this.following() ? 'border-transparent bg-primary-container text-on-primary-container' : 'border-text-secondary bg-transparent text-text-secondary hover:border-text-primary hover:bg-surface-variant hover:text-text-primary');
    }
    if (this.compact()) {
      return 'inline-flex min-h-11 shrink-0 items-center gap-1 rounded-md px-2 text-sm font-semibold text-primary hover:bg-primary-container';
    }
    return 'rd-btn min-h-11 shrink-0 gap-1.5 px-3 text-sm ' + (this.following() ? 'bg-primary-container text-on-primary-container' : 'rd-btn-outline');
  });

  protected toggle(): void {
    if (!this.prompt.requireAuth()) return;
    void this.follows.toggle(this.user().id, this.initial());
  }
}
