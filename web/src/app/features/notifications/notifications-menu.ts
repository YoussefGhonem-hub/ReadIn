import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Injector,
  PLATFORM_ID,
  Type,
  afterNextRender,
  computed,
  inject,
  input,
  signal,
  viewChild,
} from '@angular/core';
import { NgComponentOutlet, NgTemplateOutlet, isPlatformBrowser } from '@angular/common';
import { takeUntilDestroyed, toSignal } from '@angular/core/rxjs-interop';
import { NavigationEnd, NavigationStart, Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { filter, map } from 'rxjs';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { NotificationBadge, notificationsLabel } from '../../core/notifications/notification-badge';
import { appIconsReady } from '../../shared/ui/app-icons';
import { ShellIcon } from '../../shared/ui/shell-icon';

let nextId = 0;

/**
 * The navbar's notifications bell (F17) with its dropdown: the unread dot, and for a signed-in user a panel under the
 * bell with the latest notifications, "Mark all as read" and "See all notifications" (the panel's code loads the first
 * time it opens). Guests get a link to `/notifications`, which asks them to sign in.
 *
 * `variant`: `icon` is the round icon button; `stacked` is a navbar item with the icon above a small label (shown from
 * `lg`), full header height, and a bar under it on `/notifications`. Escape, a click outside, leaving it with Tab or
 * navigating closes the panel; Escape gives the focus back to the bell. On narrow screens the panel spans the width
 * under the header.
 */
@Component({
  selector: 'rd-notifications-menu',
  imports: [RouterLink, TranslocoPipe, ShellIcon, NgComponentOutlet, NgTemplateOutlet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'relative inline-flex',
    '[class.self-stretch]': "variant() === 'stacked'",
    '(document:keydown.escape)': 'onEscape()',
    '(document:pointerdown)': 'onDocumentPointer($event)',
    '(focusout)': 'onFocusOut($event)',
    'data-notifications-menu': '',
  },
  template: `
    <ng-template #bell>
      @if (variant() === 'stacked') {
        <span class="relative">
          <svg rdIcon="Bell" [size]="22" aria-hidden="true"></svg>
          @if (badge.count() > 0) {
            <span class="absolute -end-0.5 -top-0.5 h-2.5 w-2.5 rounded-full bg-accent ring-2 ring-surface" aria-hidden="true" data-unread-badge></span>
          }
        </span>
        <span class="hidden text-xs leading-4 lg:block" aria-hidden="true">{{ 'nav.notifications' | transloco }}</span>
        @if (current() || open()) {
          <span class="absolute inset-x-1 bottom-0 h-0.5 rounded-full bg-text-primary" aria-hidden="true"></span>
        }
      } @else {
        <svg rdIcon="Bell" [size]="18" aria-hidden="true"></svg>
        @if (badge.count() > 0) {
          <span class="absolute -end-1 -top-1 h-2.5 w-2.5 rounded-full bg-accent" aria-hidden="true" data-unread-badge></span>
        }
      }
    </ng-template>

    @if (session.isAuthenticated()) {
      <button
        #trigger
        type="button"
        [class]="triggerClass()"
        [attr.aria-label]="label()"
        aria-haspopup="dialog"
        [attr.aria-expanded]="open()"
        [attr.aria-controls]="open() ? panelId : null"
        (click)="toggle()"
        data-notifications-link
      >
        <ng-container [ngTemplateOutlet]="bell" />
      </button>
    } @else {
      <a routerLink="/notifications" [class]="triggerClass()" [attr.aria-label]="label()" data-notifications-link>
        <ng-container [ngTemplateOutlet]="bell" />
      </a>
    }

    @if (open()) {
      <div
        #panel
        [id]="panelId"
        role="dialog"
        [attr.aria-label]="'notifications.title' | transloco"
        tabindex="-1"
        class="rd-card absolute end-0 top-full z-40 mt-2 w-[380px] overflow-hidden p-0 shadow-raised outline-none max-sm:fixed max-sm:inset-x-4 max-sm:top-16 max-sm:mt-1 max-sm:w-auto"
        data-notifications-dropdown
      >
        @if (panelComponent(); as component) {
          <ng-container *ngComponentOutlet="component; inputs: panelInputs" />
        } @else {
          <div class="flex flex-col divide-y divide-border" aria-hidden="true">
            @for (i of [1, 2, 3]; track i) {
              <div class="flex items-start gap-3 px-4 py-3 lg:px-5">
                <div class="rd-skeleton h-11 w-11 shrink-0 rounded-full"></div>
                <div class="flex flex-1 flex-col gap-2 pt-1"><div class="rd-skeleton h-3 w-3/4"></div><div class="rd-skeleton h-3 w-1/3"></div></div>
              </div>
            }
          </div>
        }
      </div>
    }
  `,
})
export class NotificationsMenu {
  /** `icon`: the round icon button. `stacked`: a navbar item, icon above a small label. */
  readonly variant = input<'icon' | 'stacked'>('icon');

  protected readonly session = inject(SessionStore);
  protected readonly badge = inject(NotificationBadge);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;
  private readonly router = inject(Router);
  private readonly injector = inject(Injector);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  protected readonly panelId = `rd-notifications-panel-${++nextId}`;
  protected readonly open = signal(false);
  protected readonly panelComponent = signal<Type<unknown> | null>(null);
  protected readonly panelInputs = { dismiss: () => this.close() };
  private readonly trigger = viewChild<ElementRef<HTMLElement>>('trigger');
  private readonly panel = viewChild<ElementRef<HTMLElement>>('panel');

  /** "Notifications", or "Notifications, 3 new": the dot alone says nothing to a screen reader. */
  protected readonly label = computed(() => notificationsLabel(this.transloco, this.lang(), this.badge.count()));
  /** On `/notifications` (the stacked item's bar). */
  protected readonly current = toSignal(
    this.router.events.pipe(
      filter((e) => e instanceof NavigationEnd),
      map(() => this.onCenter()),
    ),
    { initialValue: this.onCenter() },
  );
  protected readonly triggerClass = computed(() =>
    this.variant() === 'stacked'
      ? 'relative flex h-full min-w-20 flex-col items-center justify-center gap-0.5 px-2 text-text-secondary transition-colors hover:text-text-primary aria-expanded:text-text-primary'
      : 'rd-icon-btn relative',
  );

  constructor() {
    // Leaving the page closes the panel (a row or "See all" was opened).
    this.router.events
      .pipe(
        filter((e) => e instanceof NavigationStart),
        takeUntilDestroyed(),
      )
      .subscribe(() => this.open.set(false));
  }

  toggle(): void {
    if (this.open()) this.close(true);
    else this.show();
  }

  close(refocus = false): void {
    if (!this.open()) return;
    this.open.set(false);
    if (refocus) this.trigger()?.nativeElement.focus();
  }

  private show(): void {
    this.open.set(true);
    if (!this.panelComponent() && this.isBrowser) {
      Promise.all([import('./notifications-panel'), appIconsReady()]).then(
        ([{ NotificationsPanel }]) => this.panelComponent.set(NotificationsPanel),
        () => {
          // Offline before the panel's code arrived: the center still works.
          this.open.set(false);
          void this.router.navigateByUrl('/notifications');
        },
      );
    }
    // The panel takes the focus, so Tab continues inside it.
    afterNextRender(() => this.panel()?.nativeElement.focus({ preventScroll: true }), { injector: this.injector });
  }

  protected onEscape(): void {
    this.close(true);
  }

  protected onDocumentPointer(event: PointerEvent): void {
    if (this.open() && !this.host.nativeElement.contains(event.target as Node | null)) this.close();
  }

  /** Tab moved the focus out of the bell and its panel. */
  protected onFocusOut(event: FocusEvent): void {
    const next = event.relatedTarget as Node | null;
    if (this.open() && next && !this.host.nativeElement.contains(next)) this.close();
  }

  private onCenter(): boolean {
    return this.router.url.split(/[?#]/)[0] === '/notifications';
  }
}
