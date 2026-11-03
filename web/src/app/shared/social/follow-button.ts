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
        class="rd-btn min-h-11 shrink-0 gap-1.5 px-3 text-sm"
        [class]="following() ? 'bg-primary-container text-on-primary-container' : 'rd-btn-outline'"
        [attr.aria-pressed]="following()"
        (click)="toggle()"
      >
        <svg [lucideIcon]="following() ? 'UserCheck' : 'UserPlus'" [size]="16" aria-hidden="true"></svg>
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

  protected readonly isSelf = computed(() => this.session.isAuthenticated() && this.session.me()?.id === this.user().id);
  protected readonly following = computed(() => this.session.isAuthenticated() && this.follows.isFollowing(this.user().id, this.initial()));

  protected toggle(): void {
    if (!this.prompt.requireAuth()) return;
    void this.follows.toggle(this.user().id, this.initial());
  }
}
