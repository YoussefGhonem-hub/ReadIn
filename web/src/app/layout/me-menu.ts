import { ChangeDetectionStrategy, Component, ElementRef, afterNextRender, computed, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { AuthService } from '../core/auth/auth.service';
import { PreferencesService } from '../core/auth/preferences.service';
import { SessionStore } from '../core/auth/session.store';
import { ErrorMessages } from '../core/i18n/error-messages';
import { LanguageService } from '../core/i18n/language.service';
import { AdminSummaryStore } from '../core/admin/admin-summary.store';
import { THEME_PREFERENCES, ThemePreference, ThemeService } from '../core/theme/theme.service';
import { BdiText } from '../shared/directives/bdi-text';
import { translatePlural } from '../shared/pipes/intl';
import { Avatar } from '../shared/ui/avatar';
import { VerifiedBadge } from '../shared/ui/verified-badge';
import { ToastService } from '../shared/ui/toast/toast.service';
import { MeMenuHost } from './me-menu-host';
import { ME_MENU, NavItem, profilePath } from './nav-items';

const THEME_ICONS: Record<ThemePreference, string> = { light: 'Sun', dark: 'Moon', system: 'Monitor' };

/**
 * The top bar's "Me" menu (its own chunk): who you are with "View profile", Settings, My articles, My paths, the
 * admin console with its badge for accounts with `admin.access` (F23), Appearance (Light / Dark / System)
 * and Sign out. A WAI-ARIA menu: the first item takes the focus, the arrows, Home and End move it, Escape and Tab close
 * the menu and give the focus back to the Me button. Picking a theme keeps the menu open.
 */
@Component({
  selector: 'rd-me-menu',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, Avatar, BdiText, VerifiedBadge],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    id: 'rd-me-menu',
    role: 'menu',
    '[attr.aria-label]': 'label()',
    class: 'rd-card block w-72 p-1.5 text-text-primary shadow-raised',
    '(keydown)': 'onKeydown($event)',
    'data-me-menu': '',
  },
  template: `
    <!-- Who you are: a soft card with the avatar, the name and handle, and "View profile" -->
    <div role="none" class="rounded-md bg-surface-variant p-3">
      <div role="none" class="flex items-center gap-3">
        <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="44" />
        <div id="rd-me-menu-who" role="none" class="min-w-0 flex-1 leading-5">
          <span class="flex items-center gap-1 text-[15px] font-semibold">
            <rd-bdi-text class="truncate" [text]="session.displayName() ?? ''" />
            @if (verified()) {
              <rd-verified-badge [size]="16" />
            }
          </span>
          <span class="block truncate text-[13px] text-text-secondary"><bdi dir="ltr">&#64;{{ session.username() }}</bdi></span>
        </div>
      </div>
      <a
        role="menuitem"
        tabindex="-1"
        [routerLink]="profileLink()"
        class="mt-3 flex min-h-8 w-full items-center justify-center rounded-sm border border-border bg-surface px-3 text-[13px] font-semibold text-primary no-underline transition-colors hover:border-primary focus:border-primary pointer-coarse:min-h-10"
        aria-describedby="rd-me-menu-who"
        (click)="picked()"
        data-me-item="profile"
        >{{ 'me.viewProfile' | transloco }}</a
      >
    </div>

    <div role="none" class="pt-1">
      @for (item of items(); track item.id) {
        <a
          role="menuitem"
          tabindex="-1"
          [routerLink]="item.path"
          [queryParams]="item.queryParams ?? null"
          [class]="rowClass"
          (click)="picked()"
          [attr.data-me-item]="item.id"
        >
          <svg [lucideIcon]="item.icon" [size]="18" [class]="iconClass" aria-hidden="true"></svg>
          <span class="min-w-0 flex-1">{{ item.labelKey | transloco }}</span>
          @if (item.id === 'admin' && admin.total() > 0) {
            <span class="min-w-6 rounded-chip bg-error px-1.5 text-center text-xs font-semibold leading-5 text-on-error" aria-hidden="true" data-admin-badge>{{
              admin.total() > 99 ? '99+' : admin.total()
            }}</span>
            <span class="sr-only">{{ adminLabel() }}</span>
          }
        </a>
      }
    </div>

    <div role="separator" class="-mx-1.5 my-1.5 h-px bg-border"></div>
    <!-- Appearance: one row with a segmented control at its end; each choice keeps its name for screen readers and shows it as a tooltip -->
    <div role="group" aria-labelledby="rd-me-menu-appearance" class="flex min-h-10 items-center gap-3 ps-3 pe-1" data-me-appearance>
      <span id="rd-me-menu-appearance" role="none" class="min-w-0 flex-1 truncate text-sm text-text-secondary">{{ 'settings.appearance' | transloco }}</span>
      <div role="none" class="flex shrink-0 gap-0.5 rounded-sm border border-border bg-surface-variant p-0.5">
        @for (option of themes; track option) {
          <button
            type="button"
            role="menuitemradio"
            tabindex="-1"
            [attr.aria-checked]="theme.preference() === option"
            [title]="'settings.theme.' + option | transloco"
            [class]="segmentClass"
            (click)="setTheme(option)"
            [attr.data-me-theme]="option"
          >
            <svg [lucideIcon]="themeIcons[option]" [size]="16" aria-hidden="true"></svg>
            <span class="sr-only">{{ 'settings.theme.' + option | transloco }}</span>
          </button>
        }
      </div>
    </div>

    <div role="separator" class="-mx-1.5 my-1.5 h-px bg-border"></div>
    <button
      type="button"
      role="menuitem"
      tabindex="-1"
      [class]="rowClass + ' w-full cursor-pointer text-start'"
      [attr.aria-disabled]="signingOut() || null"
      (click)="signOut()"
      data-me-item="signOut"
    >
      <svg lucideIcon="LogOut" [size]="18" [class]="iconClass + ' rd-flip-rtl'" aria-hidden="true"></svg>
      <span class="min-w-0 flex-1">{{ 'auth.signOut' | transloco }}</span>
    </button>
  `,
})
export class MeMenu {
  protected readonly session = inject(SessionStore);
  protected readonly theme = inject(ThemeService);
  /** The admin console's badge (F23): open reports + open tickets + pending verification requests. */
  protected readonly admin = inject(AdminSummaryStore);
  private readonly menuHost = inject(MeMenuHost);
  private readonly preferences = inject(PreferencesService);
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;
  private readonly element = inject<ElementRef<HTMLElement>>(ElementRef);

  protected readonly themes = THEME_PREFERENCES;
  protected readonly themeIcons = THEME_ICONS;
  protected readonly rowClass =
    'group flex min-h-10 items-center gap-3 rounded-sm border-0 bg-transparent px-3 text-sm text-text-primary no-underline outline-offset-[-2px] transition-colors hover:bg-surface-variant focus:bg-surface-variant pointer-coarse:min-h-11';
  protected readonly iconClass = 'shrink-0 text-text-secondary transition-colors group-hover:text-text-primary group-focus:text-text-primary';
  /** One choice of the Appearance control; the chosen one is a raised chip in the brand colour. */
  protected readonly segmentClass =
    'grid h-7 w-9 cursor-pointer place-items-center rounded-[6px] border-0 bg-transparent text-text-secondary outline-offset-0 transition-colors hover:text-text-primary focus:text-text-primary pointer-coarse:h-9 pointer-coarse:w-11 aria-checked:bg-surface aria-checked:text-primary aria-checked:shadow-[0_1px_2px_rgb(0_0_0/0.12)] dark:aria-checked:bg-surface-raised dark:aria-checked:shadow-[inset_0_0_0_1px_var(--rd-color-border)]';
  protected readonly signingOut = signal(false);

  protected readonly label = computed(() => this.transloco.translate('nav.me', {}, this.lang()));
  protected readonly verified = computed(() => this.session.me()?.isVerified ?? false);
  protected readonly profileLink = computed(() => profilePath(this.session.username()));
  protected readonly items = computed<NavItem[]>(() => ME_MENU.filter((item) => !item.permission || this.session.permissions().has(item.permission)));
  protected readonly adminLabel = computed(() => translatePlural(this.transloco, 'admin.badge', this.admin.total(), this.lang()));

  constructor() {
    afterNextRender(() => this.menuItems()[0]?.focus());
    // Opening the menu refreshes the console's badge (F23).
    void this.admin.refresh();
  }

  protected picked(): void {
    this.menuHost.closeMeMenu(true);
  }

  protected async setTheme(theme: ThemePreference): Promise<void> {
    try {
      await this.preferences.setTheme(theme);
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
    }
  }

  protected async signOut(): Promise<void> {
    if (this.signingOut()) return;
    this.signingOut.set(true);
    try {
      await this.auth.signOut();
      this.menuHost.closeMeMenu(false);
      await this.router.navigateByUrl('/');
    } finally {
      this.signingOut.set(false);
    }
  }

  protected onKeydown(event: KeyboardEvent): void {
    const items = this.menuItems();
    const index = items.indexOf(document.activeElement as HTMLElement);
    let next: number;
    switch (event.key) {
      case 'ArrowDown':
        next = (index + 1) % items.length;
        break;
      case 'ArrowUp':
        next = (index - 1 + items.length) % items.length;
        break;
      case 'Home':
        next = 0;
        break;
      case 'End':
        next = items.length - 1;
        break;
      case 'Escape':
      case 'Tab':
        event.preventDefault();
        event.stopPropagation();
        this.menuHost.closeMeMenu(true);
        return;
      case ' ':
        // Space activates a link item too (Enter already does).
        if (index >= 0 && items[index].tagName === 'A') {
          event.preventDefault();
          items[index].click();
        }
        return;
      default:
        return;
    }
    event.preventDefault();
    items[next]?.focus();
  }

  private menuItems(): HTMLElement[] {
    return Array.from(this.element.nativeElement.querySelectorAll<HTMLElement>('[role="menuitem"], [role="menuitemradio"]'));
  }
}
