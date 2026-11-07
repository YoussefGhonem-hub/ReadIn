import { ChangeDetectionStrategy, Component, DestroyRef, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed, toSignal } from '@angular/core/rxjs-interop';
import { Meta } from '@angular/platform-browser';
import { NavigationEnd, Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { filter, map, startWith } from 'rxjs';
import { AdminSummaryStore } from '../../core/admin/admin-summary.store';
import { SessionStore } from '../../core/auth/session.store';
import { provideModerationIcons } from '../../shared/moderation/moderation-icons';
import { provideAdminIcons } from './admin-icons';
import { AdminSection, sectionOf, visibleSections } from './admin-nav';

/**
 * The admin console's layout (F23), `/admin/**`: a side menu with the sections this session may open (each with its
 * queue's count) and the section on the other side. Below `lg` the menu folds into a button that names the current
 * section and opens the list, so nothing scrolls sideways. `noindex` while it is shown; client-rendered
 * (app.routes.server.ts). The summary refreshes when the console opens.
 */
@Component({
  selector: 'rd-admin-layout',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, TranslocoPipe, LucideDynamicIcon],
  providers: [provideAdminIcons(), provideModerationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'admin-layout mx-auto block max-w-[1280px] px-4 pt-4 lg:px-6 lg:pt-6', 'data-admin-layout': '' },
  styles: `
    .admin-grid {
      display: grid;
      gap: 1rem;
    }
    @media (width >= 64rem) {
      .admin-grid {
        grid-template-columns: 15rem minmax(0, 1fr);
        gap: 1.5rem;
        align-items: start;
      }
      .admin-nav {
        position: sticky;
        top: 5rem;
        display: block !important;
      }
      .admin-menu-button {
        display: none !important;
      }
    }
  `,
  template: `
    <div class="admin-grid">
      <div>
        <!-- Narrow screens: the current section, opening the list of sections -->
        <button
          type="button"
          class="admin-menu-button rd-card flex min-h-12 w-full items-center gap-3 px-4 text-start text-sm font-semibold shadow-none"
          aria-controls="admin-nav"
          [attr.aria-expanded]="menuOpen()"
          (click)="menuOpen.set(!menuOpen())"
          data-admin-menu-button
        >
          <svg lucideIcon="Menu" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
          <span class="min-w-0 flex-1 truncate">
            <span class="text-text-secondary">{{ 'admin.title' | transloco }} ·</span>
            {{ (current()?.labelKey ?? 'admin.nav.dashboard') | transloco }}
          </span>
          @if (summary.total() > 0) {
            <span class="min-w-6 rounded-chip bg-error px-1.5 text-center text-xs font-semibold leading-5 text-on-error" aria-hidden="true">{{ badge(summary.total()) }}</span>
          }
          <svg lucideIcon="ChevronDown" [size]="18" class="shrink-0 text-text-secondary transition-transform" [class.rotate-180]="menuOpen()" aria-hidden="true"></svg>
        </button>

        <nav id="admin-nav" class="admin-nav rd-card mt-2 p-1.5 shadow-none lg:mt-0" [class.hidden]="!menuOpen()" [attr.aria-label]="'admin.title' | transloco" data-admin-nav>
          <p class="m-0 px-3 pb-1 pt-2 text-xs font-semibold uppercase text-text-secondary">{{ 'admin.title' | transloco }}</p>
          <ul class="m-0 flex list-none flex-col gap-0.5 p-0">
            @for (item of sections(); track item.id) {
              <li>
                <a
                  [routerLink]="item.path"
                  routerLinkActive="bg-primary-container font-semibold text-on-primary-container"
                  [routerLinkActiveOptions]="{ exact: item.id === 'dashboard' }"
                  ariaCurrentWhenActive="page"
                  class="flex min-h-10 items-center gap-3 rounded-sm px-3 text-sm text-text-primary no-underline transition-colors hover:bg-surface-variant pointer-coarse:min-h-11"
                  [attr.data-admin-section]="item.id"
                >
                  <svg [lucideIcon]="item.icon" [size]="18" class="shrink-0" aria-hidden="true"></svg>
                  <span class="min-w-0 flex-1 truncate">{{ item.labelKey | transloco }}</span>
                  @if (count(item); as n) {
                    <span class="min-w-6 rounded-chip bg-error px-1.5 text-center text-xs font-semibold leading-5 text-on-error" [attr.data-admin-badge]="item.id">{{ badge(n) }}</span>
                  }
                </a>
              </li>
            }
          </ul>
        </nav>
      </div>

      <div class="min-w-0 pb-10">
        <router-outlet />
      </div>
    </div>
  `,
})
export class AdminLayout {
  private readonly session = inject(SessionStore);
  private readonly router = inject(Router);
  protected readonly summary = inject(AdminSummaryStore);

  protected readonly menuOpen = signal(false);
  protected readonly sections = computed(() => visibleSections(this.session.permissions()));
  private readonly url = toSignal(
    this.router.events.pipe(
      filter((e) => e instanceof NavigationEnd),
      map(() => this.router.url),
      startWith(this.router.url),
    ),
    { initialValue: this.router.url },
  );
  protected readonly current = computed(() => sectionOf(this.url()));

  constructor() {
    const meta = inject(Meta);
    meta.updateTag({ name: 'robots', content: 'noindex' }, 'name="robots"');
    inject(DestroyRef).onDestroy(() => meta.removeTag('name="robots"'));
    // Picking a section folds the narrow menu again.
    this.router.events
      .pipe(
        filter((e) => e instanceof NavigationEnd),
        takeUntilDestroyed(),
      )
      .subscribe(() => this.menuOpen.set(false));
    void this.summary.refresh();
  }

  /** The section's queue count, or 0 (no badge). */
  protected count(item: AdminSection): number {
    const summary = this.summary.summary();
    return item.badge && summary ? (summary[item.badge] ?? 0) : 0;
  }

  protected badge(n: number): string {
    return n > 99 ? '99+' : String(n);
  }
}
