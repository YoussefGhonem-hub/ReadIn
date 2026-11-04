import { ChangeDetectionStrategy, Component, ElementRef, PLATFORM_ID, computed, inject, viewChild } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Title } from '@angular/platform-browser';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { NotificationDto } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { ModerationNotices } from '../../core/moderation/moderation-notices';
import { NotificationBadge } from '../../core/notifications/notification-badge';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { loadMoreNearEnd } from '../profile/infinite-scroll';
import { provideNotificationIcons } from './notification-icons';
import { NotificationItem } from './notification-item';
import { dayKey, notificationPath } from './notification-view';
import { NotificationsStore } from './notifications.store';

type SectionKey = 'today' | 'earlier';

/**
 * The notification center (F17), `/notifications`: Today / Earlier (the user's calendar day), unread rows highlighted,
 * "Mark all as read", infinite scroll. Opening it marks everything seen, so the badge clears; tapping a row marks it
 * read and opens its link. Signed-in only, rendered in the browser.
 */
@Component({
  selector: 'rd-notifications-page',
  imports: [TranslocoPipe, LucideDynamicIcon, NotificationItem, EmptyState, ErrorState],
  providers: [NotificationsStore, provideNotificationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pt-5 lg:pt-8' },
  template: `
    <header class="mb-2 flex flex-wrap items-center justify-between gap-3">
      <h1 class="m-0 text-2xl font-bold">{{ 'notifications.title' | transloco }}</h1>
      @if (store.status() === 'loaded' && store.items().length) {
        <button
          type="button"
          class="rd-btn rd-btn-ghost min-h-10 px-3 text-sm"
          [disabled]="!store.hasUnread() || store.markingAll()"
          (click)="markAllRead()"
          data-mark-all-read
        >
          <svg lucideIcon="CheckCheck" [size]="18" aria-hidden="true"></svg>
          {{ 'notifications.markAllRead' | transloco }}
        </button>
      }
    </header>

    @if (badge.count() > 0 && store.status() === 'loaded') {
      <div class="sticky top-20 z-10 my-2 flex justify-center">
        <button type="button" class="rd-btn rd-btn-primary min-h-10 px-4 text-sm shadow-raised" (click)="store.refresh()" data-new-notifications>
          {{ 'notifications.newItems' | transloco }}
        </button>
      </div>
    }

    <section [attr.aria-label]="'notifications.title' | transloco" [attr.aria-busy]="store.status() === 'loading' || null" data-notifications>
      @switch (store.status()) {
        @case ('error') {
          <rd-error-state [message]="'notifications.loadError' | transloco" (retry)="store.load()" />
        }
        @case ('loaded') {
          @for (section of sections(); track section.key) {
            <h2 class="m-0 mb-1 mt-4 px-3 text-sm font-semibold text-text-secondary" [id]="'notifications-' + section.key">
              {{ 'notifications.' + section.key | transloco }}
            </h2>
            <ul class="m-0 flex list-none flex-col gap-1 p-0" [attr.aria-labelledby]="'notifications-' + section.key" [attr.data-section]="section.key">
              @for (n of section.items; track n.id) {
                <li><rd-notification-item [notification]="n" [path]="paths().get(n.id) ?? null" (opened)="opened(n)" /></li>
              }
            </ul>
          }
          @if (!store.items().length) {
            <rd-empty-state [title]="'notifications.empty.title' | transloco" [message]="'notifications.empty.body' | transloco" data-notifications-empty />
          }
          @if (store.loadingMore()) {
            <div class="flex items-start gap-3 px-3 py-3" aria-hidden="true">
              <div class="rd-skeleton h-11 w-11 shrink-0 rounded-full"></div>
              <div class="flex flex-1 flex-col gap-2 pt-1"><div class="rd-skeleton h-3 w-3/4"></div><div class="rd-skeleton h-3 w-1/3"></div></div>
            </div>
          }
          @if (store.loadMoreFailed()) {
            <div class="py-4 text-center">
              <button type="button" class="rd-btn rd-btn-outline" (click)="store.loadMore()" data-load-more-retry>{{ 'common.retry' | transloco }}</button>
            </div>
          }
          @if (store.items().length > 0 && !store.nextCursor()) {
            <p class="py-6 text-center text-sm text-text-secondary" data-notifications-end>{{ 'notifications.end' | transloco }}</p>
          }
          <!-- Only once a page is shown: near the loading skeleton it would report "near the end" for a list that isn't there yet. -->
          <div #sentinel class="h-px" aria-hidden="true"></div>
        }
        @default {
          <div class="flex flex-col gap-1 pt-4" data-notifications-loading>
            @for (i of [1, 2, 3, 4, 5, 6]; track i) {
              <div class="flex items-start gap-3 px-3 py-3" aria-hidden="true">
                <div class="rd-skeleton h-11 w-11 shrink-0 rounded-full"></div>
                <div class="flex flex-1 flex-col gap-2 pt-1"><div class="rd-skeleton h-3 w-3/4"></div><div class="rd-skeleton h-3 w-1/3"></div></div>
              </div>
            }
          </div>
        }
      }
    </section>
  `,
})
export class NotificationsPage {
  protected readonly store = inject(NotificationsStore);
  protected readonly badge = inject(NotificationBadge);
  private readonly session = inject(SessionStore);
  private readonly notices = inject(ModerationNotices);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly lang = inject(LanguageService).lang;
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');
  private readonly origin = typeof location === 'undefined' ? '' : location.origin;

  /** Today / Earlier, by the user's calendar day (their time zone) when the list was loaded. */
  protected readonly sections = computed(() => {
    const timeZone = this.session.me()?.timeZone;
    const today = dayKey(this.store.loadedAt(), timeZone);
    const groups: Record<SectionKey, NotificationDto[]> = { today: [], earlier: [] };
    for (const n of this.store.items()) groups[dayKey(new Date(n.updatedAt), timeZone) === today ? 'today' : 'earlier'].push(n);
    return (['today', 'earlier'] as const).filter((key) => groups[key].length > 0).map((key) => ({ key, items: groups[key] }));
  });
  protected readonly paths = computed(() => {
    const lang = this.lang();
    return new Map(this.store.items().map((n) => [n.id, notificationPath(n, lang, this.origin)]));
  });

  constructor() {
    const transloco = inject(TranslocoService);
    inject(Title).setTitle(`${transloco.translate('notifications.title')} — ReadIn`);
    if (isPlatformBrowser(inject(PLATFORM_ID))) void this.store.open();
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.store.loadMore(),
    );
  }

  /** Read at once; a moderation notice opens its dialog when it is still to be acknowledged (F22). */
  protected opened(n: NotificationDto): void {
    this.store.markRead(n.id);
    if (n.type === 'moderation_notice') this.notices.reload();
  }

  protected async markAllRead(): Promise<void> {
    try {
      await this.store.markAllRead();
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
    }
  }
}
