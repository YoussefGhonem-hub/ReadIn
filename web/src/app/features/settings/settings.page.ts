import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Title } from '@angular/platform-browser';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleLanguage } from '../../core/api/models';
import { PreferencesService } from '../../core/auth/preferences.service';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService, UiLanguage } from '../../core/i18n/language.service';
import { ModerationSummaryStore } from '../../core/moderation/moderation-summary.store';
import { ARTICLE_FONT_SIZES, ArticleFontSize, ReaderPrefsService } from '../../core/theme/reader-prefs.service';
import { ThemePreference, ThemeService } from '../../core/theme/theme.service';
import { MUTE_ICON } from '../../shared/mutes/mute-icons';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { Switch } from '../../shared/ui/switch';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { HighlightsPrefs } from '../highlights/highlights-prefs';
import { AccountSettings } from './account/account-settings';
import { PushPermissionRow } from './notifications/push-permission-row';
import { ProfileSettings } from './profile-settings';

/**
 * Settings (F18): theme, UI language, article language, reminder time, your interests (F12, their own page), what you
 * muted (F28, its own page), font size, show highlights (F30),
 * notifications (push in this browser and a link to the notification preferences, F17), profile (with writer
 * verification, F19) and privacy, Moderation for moderators (F22; the side nav isn't there on narrow screens),
 * verification requests for admins (F19), account. A header card, then each section as a card.
 */
@Component({
  selector: 'rd-settings-page',
  imports: [FormsModule, RouterLink, TranslocoPipe, Segmented, Switch, LucideDynamicIcon, AccountSettings, ProfileSettings, PushPermissionRow],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[640px] flex-col gap-2 px-4 pt-5 lg:pt-8' },
  template: `
    <header class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-4 lg:p-5" data-settings-header>
      <h1 class="m-0 text-xl font-bold lg:text-2xl">{{ 'settings.title' | transloco }}</h1>
    </header>

    <!-- Appearance -->
    <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-4 lg:p-5" aria-labelledby="appearance">
      <h2 id="appearance" class="m-0 mb-4 text-base font-semibold">{{ 'settings.appearance' | transloco }}</h2>
      <span class="rd-label">{{ 'settings.theme.label' | transloco }}</span>
      <div class="grid grid-cols-3 gap-2" role="radiogroup" [attr.aria-label]="'settings.theme.label' | transloco">
        @for (option of themeOptions; track option) {
          <button
            type="button"
            role="radio"
            [attr.aria-checked]="theme.preference() === option"
            class="flex min-h-20 flex-col items-center justify-center gap-2 rounded-md border text-sm"
            [class]="theme.preference() === option ? 'border-primary bg-primary-container font-semibold text-on-primary-container' : 'border-border bg-surface text-text-secondary'"
            (click)="setTheme(option)"
          >
            @switch (option) {
              @case ('light') {
                <svg lucideIcon="Sun" [size]="20" aria-hidden="true"></svg>
              }
              @case ('dark') {
                <svg lucideIcon="Moon" [size]="20" aria-hidden="true"></svg>
              }
              @default {
                <svg lucideIcon="Monitor" [size]="20" aria-hidden="true"></svg>
              }
            }
            {{ 'settings.theme.' + option | transloco }}
          </button>
        }
      </div>

      <span class="rd-label mt-5">{{ 'settings.uiLanguage' | transloco }}</span>
      <rd-segmented [options]="uiLanguageOptions" [value]="language.lang()" (valueChange)="setUiLanguage($event)" [label]="'settings.uiLanguage' | transloco" />

      <span class="rd-label mt-5">{{ 'settings.fontSize' | transloco }}</span>
      <rd-segmented [options]="fontOptions()" [value]="readerPrefs.fontSize()" (valueChange)="readerPrefs.setFontSize($event)" [label]="'settings.fontSize' | transloco" />

      <!-- Highlights in the reader (F30): synced when signed in, kept on this device for guests -->
      <rd-switch
        class="mt-5"
        data-settings-highlights
        [checked]="highlightPrefs.visible()"
        [label]="'highlights.settings.label' | transloco"
        [hint]="'highlights.settings.hint' | transloco"
        (changed)="highlightPrefs.set($event)"
      />
    </section>

    <!-- Reading (profile-backed) -->
    <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-4 lg:p-5" aria-labelledby="reading">
      <h2 id="reading" class="m-0 mb-1 text-base font-semibold">{{ 'settings.reading' | transloco }}</h2>
      @if (!session.isAuthenticated()) {
        <p class="m-0 mb-3 text-sm text-text-secondary">{{ 'settings.signInForSync' | transloco }}</p>
      }
      <fieldset [disabled]="!session.isAuthenticated() || saving()" class="m-0 border-0 p-0 disabled:opacity-60">
        <span class="rd-label mt-3">{{ 'settings.articleLanguage' | transloco }}</span>
        <rd-segmented
          [options]="articleLanguageOptions()"
          [value]="articleLanguage()"
          (valueChange)="saveArticleLanguage($event)"
          [disabled]="!session.isAuthenticated()"
          [label]="'settings.articleLanguage' | transloco"
        />
        <label class="rd-label mt-5" for="reminder">{{ 'settings.reminderTime' | transloco }}</label>
        <div class="flex gap-2">
          <input id="reminder" type="time" class="rd-input" dir="ltr" step="900" [ngModel]="reminderTime()" (ngModelChange)="reminderDraft.set($event)" />
          <button type="button" class="rd-btn rd-btn-outline" [disabled]="!reminderDraft() || reminderDraft() === reminderTime()" (click)="saveReminder()">
            {{ 'common.save' | transloco }}
          </button>
        </div>
      </fieldset>
      <!-- The fields and topics you follow (F12), its own page -->
      @if (session.isAuthenticated()) {
        <a routerLink="/settings/interests" class="mt-4 flex min-h-14 items-center gap-3 border-t border-border pt-3 text-sm text-text-primary no-underline" data-settings-interests>
          <svg lucideIcon="Sparkles" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
          <span class="min-w-0 flex-1">
            <span class="block">{{ 'settings.interests.title' | transloco }}</span>
            <span class="block text-xs text-text-secondary">{{ 'settings.interests.rowHint' | transloco }}</span>
          </span>
          <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
        </a>
        <!-- The writers, fields and topics you muted (F28), its own page -->
        <a routerLink="/settings/muted" class="flex min-h-14 items-center gap-3 border-t border-border pt-3 text-sm text-text-primary no-underline" data-settings-muted>
          <svg [lucideIcon]="mutedIcon" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
          <span class="min-w-0 flex-1">
            <span class="block">{{ 'mute.settings.title' | transloco }}</span>
            <span class="block text-xs text-text-secondary">{{ 'mute.settings.rowHint' | transloco }}</span>
          </span>
          <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
        </a>
      }
    </section>

    <!-- Notifications (F17): push in this browser, and what you get (its own page) -->
    <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-4 lg:p-5" aria-labelledby="notifications" data-settings-notifications>
      <h2 id="notifications" class="m-0 mb-2 text-base font-semibold">{{ 'settings.notifications.title' | transloco }}</h2>
      @if (session.isAuthenticated()) {
        <ul class="m-0 list-none divide-y divide-border p-0">
          <li class="py-3"><rd-push-permission-row /></li>
          <li>
            <a routerLink="/settings/notifications" class="flex min-h-14 items-center gap-3 text-sm text-text-primary no-underline" data-settings-notification-preferences>
              <svg lucideIcon="Bell" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
              <span class="min-w-0 flex-1">
                <span class="block">{{ 'settings.notifications.preferences' | transloco }}</span>
                <span class="block text-xs text-text-secondary">{{ 'settings.notifications.preferencesHint' | transloco }}</span>
              </span>
              <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
            </a>
          </li>
        </ul>
      } @else {
        <p class="m-0 text-sm text-text-secondary">{{ 'settings.notifications.signIn' | transloco }}</p>
      }
    </section>

    <!-- Profile and privacy (F14, F18) -->
    <rd-profile-settings />

    <!-- Moderation (F22), for moderators -->
    @if (moderation.canModerate()) {
      <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-4 lg:p-5" aria-labelledby="settings-moderation" data-settings-moderation>
        <h2 id="settings-moderation" class="m-0 mb-2 text-base font-semibold">{{ 'moderation.title' | transloco }}</h2>
        <a routerLink="/moderation" class="flex min-h-12 items-center gap-3 text-sm text-text-primary no-underline">
          <svg lucideIcon="ShieldAlert" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
          <span class="flex-1">{{ 'moderation.settings.body' | transloco }}</span>
          @if (moderation.total() > 0) {
            <span class="min-w-6 rounded-chip bg-error px-1.5 text-center text-xs font-semibold leading-5 text-on-error" data-moderation-badge>{{ moderation.total() }}</span>
          }
          <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
        </a>
      </section>
    }

    <!-- Admin (F19): verification requests, for admins (the side nav isn't there on narrow screens) -->
    @if (session.hasPermission('verification.manage')) {
      <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-4 lg:p-5" aria-labelledby="settings-admin" data-settings-admin>
        <h2 id="settings-admin" class="m-0 mb-2 text-base font-semibold">{{ 'settings.admin.title' | transloco }}</h2>
        <a routerLink="/admin/verification" class="flex min-h-12 items-center gap-3 text-sm text-text-primary no-underline" data-settings-verification-requests>
          <svg lucideIcon="BadgeCheck" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
          <span class="flex-1">{{ 'settings.admin.verification' | transloco }}</span>
          <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
        </a>
      </section>
    }

    <!-- Account (F18): phone, password, PIN, sign out, sign out everywhere, delete -->
    <rd-account-settings />
  `,
})
export class SettingsPage {
  /** The muted speaker of the F28 menus, banner and Settings → Muted (as on mobile). */
  protected readonly mutedIcon = MUTE_ICON.VolumeX;
  protected readonly theme = inject(ThemeService);
  protected readonly language = inject(LanguageService);
  protected readonly readerPrefs = inject(ReaderPrefsService);
  protected readonly highlightPrefs = inject(HighlightsPrefs);
  protected readonly session = inject(SessionStore);
  protected readonly moderation = inject(ModerationSummaryStore);
  private readonly preferences = inject(PreferencesService);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);

  protected readonly themeOptions: ThemePreference[] = ['system', 'light', 'dark'];
  /** Language names are shown in their own language. */
  protected readonly uiLanguageOptions: SegmentOption<UiLanguage>[] = [
    { value: 'ar', label: 'العربية' },
    { value: 'en', label: 'English', ltr: true },
  ];
  protected readonly articleLanguageOptions = computed<SegmentOption<ArticleLanguage>[]>(() => {
    this.language.lang();
    return [
      { value: 'ar-EG', label: this.transloco.translate('onboarding.prefs.arEG') },
      { value: 'en', label: this.transloco.translate('onboarding.prefs.en'), ltr: true },
    ];
  });
  protected readonly fontOptions = computed<SegmentOption<ArticleFontSize>[]>(() => {
    this.language.lang();
    return ARTICLE_FONT_SIZES.map((size) => ({ value: size, label: this.transloco.translate(`article.fontSizes.${size}`) }));
  });

  protected readonly articleLanguage = computed<ArticleLanguage>(() => this.session.me()?.articleLanguage ?? 'ar-EG');
  protected readonly reminderTime = computed(() => this.session.me()?.reminderTime ?? '08:00');
  protected readonly reminderDraft = signal<string | null>(null);
  protected readonly saving = signal(false);

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('settings.title')} — ReadIn`);
  }

  protected setTheme(theme: ThemePreference): Promise<void> {
    return this.persist(() => this.preferences.setTheme(theme));
  }

  protected setUiLanguage(lang: UiLanguage): Promise<void> {
    return this.persist(() => this.preferences.setUiLanguage(lang));
  }

  protected saveArticleLanguage(articleLanguage: ArticleLanguage): Promise<void> {
    return this.persist(() => this.preferences.save({ articleLanguage }), true);
  }

  protected async saveReminder(): Promise<void> {
    const value = this.reminderDraft();
    if (!value) return;
    await this.persist(() => this.preferences.save({ reminderTime: value }), true);
    this.reminderDraft.set(null);
  }

  private async persist(action: () => Promise<unknown>, confirm = false): Promise<void> {
    this.saving.set(true);
    try {
      await action();
      if (confirm) this.toasts.success(this.transloco.translate('settings.saved'));
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
    } finally {
      this.saving.set(false);
    }
  }
}
