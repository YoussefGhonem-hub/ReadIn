import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SessionStore } from '../core/auth/session.store';
import { RealtimeService } from '../core/realtime/realtime.service';
import { Avatar } from '../shared/ui/avatar';
import { StreakBadge } from '../shared/ui/streak-badge';
import { Wordmark } from '../shared/ui/wordmark';
import { profilePath } from './nav-items';

@Component({
  selector: 'rd-top-bar',
  imports: [RouterLink, TranslocoPipe, Wordmark, StreakBadge, Avatar, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'sticky top-0 z-30 block border-b border-border bg-bg/90 backdrop-blur' },
  template: `
    <div class="mx-auto flex h-16 max-w-[1200px] items-center gap-3 px-4 lg:px-6">
      <a routerLink="/" class="no-underline" [attr.aria-label]="'nav.home' | transloco">
        <rd-wordmark [size]="24" [withIcon]="true" />
      </a>
      <div class="ms-auto flex items-center gap-2">
        @if (session.isAuthenticated()) {
          <rd-streak-badge />
        }
        <a routerLink="/search" class="rd-icon-btn hidden sm:inline-grid" [attr.aria-label]="'nav.search' | transloco">
          <svg lucideIcon="Search" [size]="18"></svg>
        </a>
        <a routerLink="/notifications" class="rd-icon-btn relative" [attr.aria-label]="'nav.notifications' | transloco">
          <svg lucideIcon="Bell" [size]="18"></svg>
          @if (realtime.unreadNotifications() > 0) {
            <span class="absolute -end-1 -top-1 h-2.5 w-2.5 rounded-full bg-accent" aria-hidden="true"></span>
          }
        </a>
        @if (session.isAuthenticated()) {
          <a [routerLink]="profileLink()" class="hidden lg:inline-flex" [attr.aria-label]="'nav.profile' | transloco">
            <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="36" />
          </a>
        } @else if (session.isGuest()) {
          <a routerLink="/auth/sign-in" class="rd-btn rd-btn-primary hidden min-h-10 sm:inline-flex">{{ 'auth.signIn.submit' | transloco }}</a>
        }
      </div>
    </div>
  `,
})
export class TopBar {
  protected readonly session = inject(SessionStore);
  protected readonly realtime = inject(RealtimeService);
  protected profileLink(): string {
    return profilePath(this.session.username());
  }
}
