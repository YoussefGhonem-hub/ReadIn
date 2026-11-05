import { ChangeDetectionStrategy, Component, PLATFORM_ID, computed, effect, inject, input, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { NotificationDto } from '../../core/api/models';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { ModerationNotices } from '../../core/moderation/moderation-notices';
import { NotificationBadge } from '../../core/notifications/notification-badge';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { provideNotificationIcons } from './notification-icons';
import { NotificationItem } from './notification-item';
import { notificationPath } from './notification-view';
import { NotificationsStore } from './notifications.store';

/** How many of the latest notifications the dropdown shows; the rest are on `/notifications`. */
export const PANEL_ITEMS = 8;

/**
 * The inside of the notifications dropdown (F17), loaded the first time the bell opens it: the latest notifications as
 * on the center (same rows), "Mark all as read", and "See all notifications". Opening it marks everything seen, like
 * the center, so the badge clears; new ones that arrive while it is open show up at once. Tapping a row marks it read,
 * opens its link and closes the dropdown.
 */
@Component({
  selector: 'rd-notifications-panel',
  imports: [TranslocoPipe, LucideDynamicIcon, RouterLink, NotificationItem],
  providers: [NotificationsStore, provideNotificationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex max-h-[min(70vh,560px)] flex-col', 'data-notifications-panel': '' },
  template: `
    <header class="flex min-h-14 items-center justify-between gap-2 border-b border-border px-4 py-2 lg:px-5">
      <h2 class="m-0 text-base font-semibold">{{ 'notifications.title' | transloco }}</h2>
      @if (store.status() === 'loaded' && store.items().length) {
        <button
          type="button"
          class="rd-btn rd-btn-ghost min-h-9 gap-1.5 px-2 text-xs"
          [disabled]="!store.hasUnread() || store.markingAll()"
          (click)="markAllRead()"
          data-mark-all-read
        >
          <svg lucideIcon="CheckCheck" [size]="16" aria-hidden="true"></svg>
          {{ 'notifications.markAllRead' | transloco }}
        </button>
      }
    </header>

    <div class="min-h-0 flex-1 overflow-y-auto overscroll-contain" [attr.aria-busy]="store.status() === 'loading' || null">
      @switch (store.status()) {
        @case ('error') {
          <div class="flex flex-col items-center gap-3 px-4 py-8 text-center" data-panel-error>
            <p class="m-0 text-sm text-text-secondary">{{ 'notifications.loadError' | transloco }}</p>
            <button type="button" class="rd-btn rd-btn-outline min-h-10" (click)="store.load()">{{ 'common.retry' | transloco }}</button>
          </div>
        }
        @case ('loaded') {
          @if (latest().length) {
            <ul class="m-0 list-none divide-y divide-border p-0">
              @for (n of latest(); track n.id) {
                <li><rd-notification-item [notification]="n" [path]="paths().get(n.id) ?? null" (opened)="opened(n)" /></li>
              }
            </ul>
          } @else {
            <div class="flex flex-col items-center gap-2 px-6 py-10 text-center" data-panel-empty>
              <span class="grid h-12 w-12 place-items-center rounded-full bg-primary-container text-on-primary-container" aria-hidden="true">
                <svg lucideIcon="Bell" [size]="22"></svg>
              </span>
              <p class="m-0 font-semibold">{{ 'notifications.empty.title' | transloco }}</p>
              <p class="m-0 text-sm text-text-secondary">{{ 'notifications.empty.body' | transloco }}</p>
            </div>
          }
        }
        @default {
          <div class="flex flex-col divide-y divide-border" data-panel-loading>
            @for (i of [1, 2, 3, 4]; track i) {
              <div class="flex items-start gap-3 px-4 py-3 lg:px-5" aria-hidden="true">
                <div class="rd-skeleton h-11 w-11 shrink-0 rounded-full"></div>
                <div class="flex flex-1 flex-col gap-2 pt-1"><div class="rd-skeleton h-3 w-3/4"></div><div class="rd-skeleton h-3 w-1/3"></div></div>
              </div>
            }
          </div>
        }
      }
    </div>

    <footer class="border-t border-border p-1">
      <a
        routerLink="/notifications"
        class="flex min-h-11 items-center justify-center rounded-md text-sm font-semibold text-primary no-underline hover:bg-surface-variant"
        (click)="dismiss()()"
        data-see-all
      >
        {{ 'notifications.seeAll' | transloco }}
      </a>
    </footer>
  `,
})
export class NotificationsPanel {
  /** Closes the dropdown (set by the bell's menu). */
  readonly dismiss = input<() => void>(() => undefined);

  protected readonly store = inject(NotificationsStore);
  private readonly badge = inject(NotificationBadge);
  private readonly notices = inject(ModerationNotices);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly lang = inject(LanguageService).lang;
  private readonly origin = typeof location === 'undefined' ? '' : location.origin;

  protected readonly latest = computed(() => this.store.items().slice(0, PANEL_ITEMS));
  protected readonly paths = computed(() => {
    const lang = this.lang();
    return new Map(this.latest().map((n) => [n.id, notificationPath(n, lang, this.origin)]));
  });

  constructor() {
    if (!isPlatformBrowser(inject(PLATFORM_ID))) return;
    void this.store.open();
    // New notifications while it is open: show them (and they are seen, like on the center).
    effect(() => {
      if (this.badge.count() > 0 && untracked(() => this.store.status()) === 'loaded') untracked(() => void this.store.refresh());
    });
  }

  /** Read at once; a moderation notice opens its dialog when it is still to be acknowledged (F22). */
  protected opened(n: NotificationDto): void {
    this.store.markRead(n.id);
    if (n.type === 'moderation_notice') this.notices.reload();
    this.dismiss()();
  }

  protected async markAllRead(): Promise<void> {
    try {
      await this.store.markAllRead();
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
    }
  }
}
