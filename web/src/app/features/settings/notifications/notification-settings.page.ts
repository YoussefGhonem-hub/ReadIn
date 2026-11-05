import { ChangeDetectionStrategy, Component, PLATFORM_ID, computed, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Title } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../../core/api/api.config';
import { ConfigurableNotificationType, NotificationMode, NotificationSettingsDto, QuietHoursDto } from '../../../core/api/models';
import { NotificationsApi } from '../../../core/api/notifications.api';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { PushService } from '../../../core/push/push.service';
import { SegmentOption, Segmented } from '../../../shared/ui/segmented';
import { ErrorState } from '../../../shared/ui/states';
import { Switch } from '../../../shared/ui/switch';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { provideNotificationIcons } from '../../notifications/notification-icons';
import { PushPermissionRow } from './push-permission-row';

/** The types a user can configure, in the order they are listed. */
export const CONFIGURABLE_TYPES: readonly ConfigurableNotificationType[] = [
  'daily_article',
  'streak_reminder',
  'followed_writer_article',
  'new_follower',
  'article_comment',
  'comment_reply',
  'mention',
  'reactions_milestone',
  // F29: someone reposted your article.
  'article_reposted',
];
const MODES: readonly NotificationMode[] = ['all', 'inApp', 'off'];
/** Every configurable type defaults to `all` (a type the API leaves out has its default). */
const DEFAULT_MODE: NotificationMode = 'all';
const TIME = /^([01]\d|2[0-3]):[0-5]\d$/;

type Status = 'loading' | 'loaded' | 'error';

/**
 * Settings → Notifications (F17), `/settings/notifications`: push in this browser, a mode per configurable type (All =
 * push + the center, In app = the center only, Off) and quiet hours (on/off, from–to in the user's time zone). Each
 * change is saved at once with `PUT /me/notification-settings` (only the type that changed); the times with Save.
 * Choosing "All" asks for push permission in context when the browser hasn't been asked yet (SPEC §21.1).
 */
@Component({
  selector: 'rd-notification-settings-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, Segmented, Switch, ErrorState, PushPermissionRow],
  providers: [provideNotificationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[640px] flex-col gap-2 px-4 pt-5 lg:pt-8' },
  template: `
    <header class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 px-4 pb-4 pt-2 lg:px-5 lg:pb-5 lg:pt-3">
      <a routerLink="/settings" class="-ms-1 inline-flex min-h-11 items-center gap-1 rounded-md px-1 text-sm text-text-secondary no-underline hover:text-text-primary" data-back-to-settings>
        <svg lucideIcon="ArrowRight" [size]="18" class="shrink-0 ltr:rotate-180" aria-hidden="true"></svg>
        {{ 'settings.notifications.back' | transloco }}
      </a>
      <h1 class="m-0 mt-1 text-xl font-bold lg:text-2xl">{{ 'settings.notifications.preferences' | transloco }}</h1>
    </header>

    @switch (status()) {
      @case ('error') {
        <rd-error-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [message]="'settings.notifications.loadError' | transloco" (retry)="load()" />
      }
      @case ('loaded') {
        <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-4 lg:p-5" [attr.aria-label]="'settings.push.title' | transloco">
          <rd-push-permission-row />
        </section>

        <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-4 lg:p-5" aria-labelledby="notification-types" data-notification-types>
          <h2 id="notification-types" class="m-0 mb-1 text-base font-semibold">{{ 'settings.notifications.typesTitle' | transloco }}</h2>
          <p class="m-0 mb-2 text-sm text-text-secondary">{{ 'settings.notifications.modesHint' | transloco }}</p>
          <ul class="m-0 list-none divide-y divide-border p-0">
            @for (type of types; track type) {
              <li class="flex flex-wrap items-center gap-x-4 gap-y-2 py-3" [attr.data-notification-type]="type" [attr.data-mode]="modeOf(type)">
                <div class="min-w-48 flex-1">
                  <div class="text-sm font-semibold" [id]="'notification-type-' + type">{{ 'settings.notifications.types.' + type + '.label' | transloco }}</div>
                  <div class="text-xs text-text-secondary">{{ 'settings.notifications.types.' + type + '.hint' | transloco }}</div>
                </div>
                <rd-segmented
                  class="w-full sm:w-72"
                  [options]="modeOptions()"
                  [value]="modeOf(type)"
                  (valueChange)="setMode(type, $event)"
                  [disabled]="savingType() !== null"
                  [label]="'settings.notifications.types.' + type + '.label' | transloco"
                />
              </li>
            }
          </ul>
          <p class="m-0 mt-3 flex items-start gap-2 text-xs text-text-secondary">
            <svg lucideIcon="ShieldCheck" [size]="16" class="mt-px shrink-0" aria-hidden="true"></svg>
            <span>{{ 'settings.notifications.alwaysOn' | transloco }}</span>
          </p>
        </section>

        <section class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 p-4 lg:p-5" aria-labelledby="quiet-hours" data-quiet-hours>
          <h2 id="quiet-hours" class="m-0 mb-3 flex items-center gap-2 text-base font-semibold">
            <svg lucideIcon="MoonStar" [size]="18" class="text-text-secondary" aria-hidden="true"></svg>
            {{ 'settings.notifications.quietHours.title' | transloco }}
          </h2>
          <rd-switch
            [checked]="quietHours().enabled"
            [label]="'settings.notifications.quietHours.toggle' | transloco"
            [hint]="'settings.notifications.quietHours.hint' | transloco"
            [disabled]="savingQuiet()"
            [busy]="savingQuiet()"
            (changed)="setQuietEnabled($event)"
            data-quiet-toggle
          />
          @if (quietHours().enabled) {
            <div class="mt-4 grid grid-cols-2 gap-3">
              <div>
                <label class="rd-label" for="quiet-start">{{ 'settings.notifications.quietHours.start' | transloco }}</label>
                <input
                  id="quiet-start"
                  type="time"
                  class="rd-input"
                  dir="ltr"
                  required
                  [value]="draftStart()"
                  (input)="editTime('start', $event)"
                  [attr.aria-invalid]="quietError() ? true : null"
                  [attr.aria-describedby]="quietError() ? 'quiet-error' : null"
                />
              </div>
              <div>
                <label class="rd-label" for="quiet-end">{{ 'settings.notifications.quietHours.end' | transloco }}</label>
                <input
                  id="quiet-end"
                  type="time"
                  class="rd-input"
                  dir="ltr"
                  required
                  [value]="draftEnd()"
                  (input)="editTime('end', $event)"
                  [attr.aria-invalid]="quietError() ? true : null"
                  [attr.aria-describedby]="quietError() ? 'quiet-error' : null"
                />
              </div>
            </div>
            @if (quietError(); as error) {
              <p id="quiet-error" class="m-0 mt-2 text-sm text-error" role="alert" data-quiet-error>{{ error }}</p>
            }
            <button type="button" class="rd-btn rd-btn-outline mt-4" [disabled]="!timesChanged() || savingQuiet()" (click)="saveTimes()" data-quiet-save>
              {{ (savingQuiet() ? 'common.saving' : 'common.save') | transloco }}
            </button>
          }
        </section>
      }
      @default {
        <div class="flex flex-col gap-2" aria-busy="true" data-notification-settings-loading>
          <div class="rd-skeleton h-20 w-full rounded-card max-sm:-mx-4 max-sm:w-auto max-sm:rounded-none"></div>
          <div class="rd-skeleton h-96 w-full rounded-card max-sm:-mx-4 max-sm:w-auto max-sm:rounded-none"></div>
          <div class="rd-skeleton h-40 w-full rounded-card max-sm:-mx-4 max-sm:w-auto max-sm:rounded-none"></div>
        </div>
      }
    }
  `,
})
export class NotificationSettingsPage {
  private readonly api = inject(NotificationsApi);
  private readonly push = inject(PushService);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;

  protected readonly types = CONFIGURABLE_TYPES;
  protected readonly status = signal<Status>('loading');
  private readonly settings = signal<NotificationSettingsDto | null>(null);
  protected readonly savingType = signal<ConfigurableNotificationType | null>(null);
  protected readonly savingQuiet = signal(false);
  protected readonly draftStart = signal('');
  protected readonly draftEnd = signal('');
  protected readonly quietError = signal<string | null>(null);

  protected readonly quietHours = computed<QuietHoursDto>(() => this.settings()?.quietHours ?? { enabled: true, start: '23:00', end: '07:00' });
  protected readonly timesChanged = computed(() => this.draftStart() !== this.quietHours().start || this.draftEnd() !== this.quietHours().end);
  protected readonly modeOptions = computed<SegmentOption<NotificationMode>[]>(() => {
    this.lang();
    return MODES.map((mode) => ({ value: mode, label: this.transloco.translate(`settings.notifications.modes.${mode}`) }));
  });

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('settings.notifications.preferences')} — ReadIn`);
    if (isPlatformBrowser(inject(PLATFORM_ID))) void this.load();
  }

  protected async load(): Promise<void> {
    this.status.set('loading');
    try {
      const settings = await firstValueFrom(this.api.settings());
      this.settings.set({ quietHours: { ...settings.quietHours }, types: { ...(settings.types ?? {}) } });
      this.resetDrafts();
      this.status.set('loaded');
    } catch {
      this.status.set('error');
    }
  }

  protected modeOf(type: ConfigurableNotificationType): NotificationMode {
    return this.settings()?.types[type] ?? DEFAULT_MODE;
  }

  /** Saved at once; undone when the API refuses it. */
  protected async setMode(type: ConfigurableNotificationType, mode: NotificationMode): Promise<void> {
    const current = this.settings();
    const previous = this.modeOf(type);
    if (!current || previous === mode || this.savingType()) return;
    this.patch({ types: { ...current.types, [type]: mode } });
    this.savingType.set(type);
    // "All" includes a push: ask for permission now, in context, when this browser hasn't been asked (SPEC §21.1).
    if (mode === 'all' && this.push.permission() === 'default') void this.push.enable();
    try {
      await firstValueFrom(this.api.updateSettings({ quietHours: current.quietHours, types: { [type]: mode } }));
    } catch (error) {
      this.patch({ types: { ...this.settings()!.types, [type]: previous } });
      this.toasts.error(this.errors.forError(error));
    } finally {
      this.savingType.set(null);
    }
  }

  protected setQuietEnabled(enabled: boolean): Promise<void> {
    const saved = this.quietHours();
    return this.saveQuietHours({ ...saved, enabled }, false);
  }

  protected editTime(which: 'start' | 'end', event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    (which === 'start' ? this.draftStart : this.draftEnd).set(value);
    this.quietError.set(null);
  }

  /** "HH:mm" both, and not the same time (a zero-length window); the API checks the same and answers in kind. */
  protected saveTimes(): Promise<void> {
    const start = this.draftStart();
    const end = this.draftEnd();
    if (!TIME.test(start) || !TIME.test(end) || start === end) {
      this.quietError.set(this.errors.forCode('notification.quiet_hours_invalid'));
      return Promise.resolve();
    }
    return this.saveQuietHours({ enabled: true, start, end }, true);
  }

  private async saveQuietHours(next: QuietHoursDto, confirm: boolean): Promise<void> {
    const previous = this.quietHours();
    if (this.savingQuiet()) return;
    this.savingQuiet.set(true);
    this.quietError.set(null);
    this.patch({ quietHours: next });
    try {
      await firstValueFrom(this.api.updateSettings({ quietHours: next, types: {} }));
      this.resetDrafts();
      if (confirm) this.toasts.success(this.transloco.translate('settings.saved'));
    } catch (error) {
      this.patch({ quietHours: previous });
      if (isApiError(error) && (error.code === 'notification.quiet_hours_invalid' || error.code === 'validation.failed')) {
        this.quietError.set(this.errors.forCode('notification.quiet_hours_invalid'));
      } else {
        this.toasts.error(this.errors.forError(error));
      }
    } finally {
      this.savingQuiet.set(false);
    }
  }

  private patch(partial: Partial<NotificationSettingsDto>): void {
    this.settings.update((settings) => (settings ? { ...settings, ...partial } : settings));
  }

  private resetDrafts(): void {
    this.draftStart.set(this.quietHours().start);
    this.draftEnd.set(this.quietHours().end);
  }
}
