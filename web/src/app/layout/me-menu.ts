import { ChangeDetectionStrategy, Component, ElementRef, afterNextRender, computed, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { AuthService } from '../core/auth/auth.service';
import { PreferencesService } from '../core/auth/preferences.service';
import { SessionStore } from '../core/auth/session.store';
import { ErrorMessages } from '../core/i18n/error-messages';
import { LanguageService } from '../core/i18n/language.service';
import { ModerationSummaryStore } from '../core/moderation/moderation-summary.store';
import { THEME_PREFERENCES, ThemePreference, ThemeService } from '../core/theme/theme.service';
import { BdiText } from '../shared/directives/bdi-text';
import { translatePlural } from '../shared/pipes/intl';
import { Avatar } from '../shared/ui/avatar';
import { ToastService } from '../shared/ui/toast/toast.service';
import { MeMenuHost } from './me-menu-host';
import { ME_MENU, NavItem, profilePath } from './nav-items';

const THEME_ICONS: Record<ThemePreference, string> = { light: 'Sun', dark: 'Moon', system: 'Monitor' };

/**
 * The top bar's "Me" menu (its own chunk): who you are with "View profile", Settings, My articles, My paths, the
 * moderation and verification-request pages for accounts with those permissions, Appearance (Light / Dark / System)
 * and Sign out. A WAI-ARIA menu: the first item takes the focus, the arrows, Home and End move it, Escape and Tab close
 * the menu and give the focus back to the Me button. Picking a theme keeps the menu open.
 */
@Component({
  selector: 'rd-me-menu',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, Avatar, BdiText],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    id: 'rd-me-menu',
    role: 'menu',
    '[attr.aria-label]': 'label()',
    class: 'rd-card block w-72 p-2 text-text-primary shadow-raised',
    '(keydown)': 'onKeydown($event)',
    'data-me-menu': '',
  },
  template: `
    <div role="none" class="flex items-center gap-3 px-2 pb-3 pt-2">
      <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="56" />
      <div id="rd-me-menu-who" role="none" class="min-w-0 flex-1">
        <span class="flex items-center gap-1 font-semibold">
          <rd-bdi-text class="truncate" [text]="session.displayName() ?? ''" />
          @if (verified()) {
            <svg lucideIcon="BadgeCheck" [size]="16" class="shrink-0 text-primary" role="img" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
          }
        </span>
        <span class="block truncate text-sm text-text-secondary"><bdi dir="ltr">&#64;{{ session.username() }}</bdi></span>
      </div>
    </div>
    <a
      role="menuitem"
      tabindex="-1"
      [routerLink]="profileLink()"
      class="rd-btn rd-btn-outline mb-2 flex min-h-9 w-full rounded-chip text-sm no-underline"
      aria-describedby="rd-me-menu-who"
      (click)="picked()"
      data-me-item="profile"
      >{{ 'me.viewProfile' | transloco }}</a
    >

    <div role="separator" class="my-1 h-px bg-border"></div>
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
        <svg [lucideIcon]="item.icon" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
        <span class="min-w-0 flex-1">{{ item.labelKey | transloco }}</span>
        @if (item.id === 'moderation' && moderation.total() > 0) {
          <span class="min-w-6 rounded-chip bg-error px-1.5 text-center text-xs font-semibold leading-5 text-on-error" aria-hidden="true" data-moderation-badge>{{
            moderation.total() > 99 ? '99+' : moderation.total()
          }}</span>
          <span class="sr-only">{{ moderationLabel() }}</span>
        }
      </a>
    }

    <div role="separator" class="my-1 h-px bg-border"></div>
    <div role="group" aria-labelledby="rd-me-menu-appearance" data-me-appearance>
      <span id="rd-me-menu-appearance" role="none" class="block px-3 pb-1 pt-2 text-xs font-semibold text-text-secondary">{{
        'settings.appearance' | transloco
      }}</span>
      @for (option of themes; track option) {
        <button
          type="button"
          role="menuitemradio"
          tabindex="-1"
          [attr.aria-checked]="theme.preference() === option"
          [class]="rowClass + ' w-full cursor-pointer text-start'"
          (click)="setTheme(option)"
          [attr.data-me-theme]="option"
        >
          <svg [lucideIcon]="themeIcons[option]" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
          <span class="min-w-0 flex-1">{{ 'settings.theme.' + option | transloco }}</span>
          @if (theme.preference() === option) {
            <svg lucideIcon="Check" [size]="18" class="shrink-0 text-primary" aria-hidden="true"></svg>
          }
        </button>
      }
    </div>

    <div role="separator" class="my-1 h-px bg-border"></div>
    <button
      type="button"
      role="menuitem"
      tabindex="-1"
      [class]="rowClass + ' w-full cursor-pointer text-start'"
      [attr.aria-disabled]="signingOut() || null"
      (click)="signOut()"
      data-me-item="signOut"
    >
      <svg lucideIcon="LogOut" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
      <span class="min-w-0 flex-1">{{ 'auth.signOut' | transloco }}</span>
    </button>
  `,
})
export class MeMenu {
  protected readonly session = inject(SessionStore);
  protected readonly theme = inject(ThemeService);
  protected readonly moderation = inject(ModerationSummaryStore);
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
    'flex min-h-11 items-center gap-3 rounded-md border-0 bg-transparent px-3 text-sm text-text-primary no-underline outline-offset-[-2px] hover:bg-surface-variant focus:bg-surface-variant';
  protected readonly signingOut = signal(false);

  protected readonly label = computed(() => this.transloco.translate('nav.me', {}, this.lang()));
  protected readonly verified = computed(() => this.session.me()?.isVerified ?? false);
  protected readonly profileLink = computed(() => profilePath(this.session.username()));
  protected readonly items = computed<NavItem[]>(() => ME_MENU.filter((item) => !item.permission || this.session.permissions().has(item.permission)));
  protected readonly moderationLabel = computed(() => translatePlural(this.transloco, 'moderation.openBadge', this.moderation.total(), this.lang()));

  constructor() {
    afterNextRender(() => this.menuItems()[0]?.focus());
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
