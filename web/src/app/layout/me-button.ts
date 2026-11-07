import { ChangeDetectionStrategy, Component, ElementRef, PLATFORM_ID, Type, computed, inject, input, signal, viewChild } from '@angular/core';
import { NgComponentOutlet, isPlatformBrowser } from '@angular/common';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationStart, Router } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { filter } from 'rxjs';
import { SessionStore } from '../core/auth/session.store';
import { AdminSummaryStore } from '../core/admin/admin-summary.store';
import { appIconsReady } from '../shared/ui/app-icons';
import { Avatar } from '../shared/ui/avatar';
import { ShellIcon } from '../shared/ui/shell-icon';
import { MeMenuHost } from './me-menu-host';
import { profilePath } from './nav-items';

/**
 * The top bar's "Me" for a signed-in member: `stacked` is the wide bar's avatar above "Me ⌄" (full header height, a bar
 * under it while open), `icon` the narrow bar's round avatar. Its menu (layout/me-menu.ts: profile, links, appearance,
 * sign out) is a chunk of its own, loaded when the button is hovered, focused or opened. Escape, a click outside or
 * navigating closes it; Escape gives the focus back to the button.
 *
 * Only signed-in members have it and the server renders every page signed out, so this is a chunk of its own too: the
 * top bar loads it once the session is restored (layout/top-bar.ts).
 */
@Component({
  selector: 'rd-me-button',
  imports: [NgComponentOutlet, TranslocoPipe, Avatar, ShellIcon],
  providers: [{ provide: MeMenuHost, useExisting: MeButton }],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'relative flex',
    '[class.h-full]': "variant() === 'stacked'",
    '(document:pointerdown)': 'onDocumentPointer($event)',
    '(document:keydown.escape)': 'closeMeMenu(true)',
  },
  template: `
    @if (variant() === 'stacked') {
      <button
        #trigger
        type="button"
        class="relative flex h-full min-w-12 cursor-pointer flex-col items-center justify-center gap-0.5 px-2 text-text-secondary transition-colors hover:text-text-primary aria-expanded:text-text-primary lg:min-w-20"
        aria-haspopup="menu"
        [attr.aria-expanded]="open()"
        [attr.aria-controls]="open() && meMenu() ? 'rd-me-menu' : null"
        (click)="toggle()"
        (pointerenter)="preload()"
        (focus)="preload()"
        data-me-trigger="stacked"
      >
        <span class="relative">
          <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="24" />
          @if (attention()) {
            <span class="absolute -end-0.5 -top-0.5 h-2.5 w-2.5 rounded-full bg-error ring-2 ring-surface" aria-hidden="true" data-me-attention></span>
          }
        </span>
        <span class="sr-only items-center gap-0.5 text-xs leading-4 lg:not-sr-only lg:flex">
          {{ 'nav.me' | transloco }}<svg rdIcon="ChevronDown" [size]="14" aria-hidden="true"></svg>
        </span>
        @if (open()) {
          <span class="absolute inset-x-1 bottom-0 h-0.5 rounded-full bg-text-primary" aria-hidden="true"></span>
        }
      </button>
    } @else {
      <button
        #trigger
        type="button"
        class="relative grid h-10 w-10 cursor-pointer place-items-center rounded-full"
        aria-haspopup="menu"
        [attr.aria-expanded]="open()"
        [attr.aria-controls]="open() && meMenu() ? 'rd-me-menu' : null"
        (click)="toggle()"
        (focus)="preload()"
        data-me-trigger="icon"
      >
        <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="32" />
        @if (attention()) {
          <span class="absolute end-0 top-0 h-2.5 w-2.5 rounded-full bg-error ring-2 ring-surface" aria-hidden="true" data-me-attention></span>
        }
        <span class="sr-only">{{ 'nav.me' | transloco }}</span>
      </button>
    }
    @if (open()) {
      <div class="absolute end-0 top-full z-40 mt-2" data-me-menu-panel>
        @if (meMenu(); as component) {
          <ng-container *ngComponentOutlet="component" />
        } @else {
          <div class="rd-card w-72 p-4 shadow-raised" aria-hidden="true">
            <div class="flex items-center gap-3">
              <div class="rd-skeleton h-14 w-14 shrink-0 rounded-full"></div>
              <div class="flex flex-1 flex-col gap-2"><div class="rd-skeleton h-4 w-3/4"></div><div class="rd-skeleton h-3 w-1/2"></div></div>
            </div>
          </div>
        }
      </div>
    }
  `,
})
export class MeButton implements MeMenuHost {
  readonly variant = input<'icon' | 'stacked'>('stacked');

  protected readonly session = inject(SessionStore);
  /** The admin console's queues (F23): a dot on Me while something waits; the count is in the menu. */
  private readonly admin = inject(AdminSummaryStore);
  private readonly router = inject(Router);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  protected readonly attention = computed(() => this.admin.canAccess() && this.admin.total() > 0);
  protected readonly open = signal(false);
  /** The Me menu (layout/me-menu.ts), once its chunk arrived. */
  protected readonly meMenu = signal<Type<unknown> | null>(null);
  private loading: Promise<boolean> | null = null;
  private readonly trigger = viewChild<ElementRef<HTMLElement>>('trigger');

  constructor() {
    // Leaving the page closes the Me menu (one of its links was opened).
    this.router.events
      .pipe(
        filter((e) => e instanceof NavigationStart),
        takeUntilDestroyed(),
      )
      .subscribe(() => this.open.set(false));
  }

  /** Starts loading the Me menu's chunk (hover or focus on the button); resolves to false when it couldn't load. */
  protected preload(): Promise<boolean> {
    if (!this.isBrowser) return Promise.resolve(false);
    this.loading ??= Promise.all([import('./me-menu'), appIconsReady()]).then(
      ([{ MeMenu }]) => {
        this.meMenu.set(MeMenu);
        return true;
      },
      () => {
        this.loading = null; // offline: the next click tries again
        return false;
      },
    );
    return this.loading;
  }

  protected toggle(): void {
    if (this.open()) {
      this.closeMeMenu(true);
      return;
    }
    this.open.set(true);
    void this.preload().then((loaded) => {
      if (loaded) return;
      // Offline before the menu's code arrived: the profile page has the same links.
      this.open.set(false);
      void this.router.navigateByUrl(profilePath(this.session.username()));
    });
  }

  /** Closes the menu; `refocus` gives the focus back to the button (Escape, Tab, a picked item). */
  closeMeMenu(refocus: boolean): void {
    if (!this.open()) return;
    this.open.set(false);
    if (refocus) this.trigger()?.nativeElement.focus();
  }

  /** A click outside the button and its menu closes the menu. */
  protected onDocumentPointer(event: PointerEvent): void {
    if (this.open() && !this.host.nativeElement.contains(event.target as Node | null)) this.open.set(false);
  }
}
