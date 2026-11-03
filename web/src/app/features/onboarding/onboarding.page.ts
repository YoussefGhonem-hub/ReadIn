import { ChangeDetectionStrategy, Component, PLATFORM_ID, computed, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { MeApi } from '../../core/api/me.api';
import { ArticleLanguage, FieldDto, TopicDto } from '../../core/api/models';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { AuthService } from '../../core/auth/auth.service';
import { PreferencesService } from '../../core/auth/preferences.service';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { FieldIcon } from '../../shared/ui/field-icon';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { ErrorState } from '../../shared/ui/states';
import { Wordmark } from '../../shared/ui/wordmark';

type Step = 1 | 2 | 3;
type NotificationState = 'default' | 'granted' | 'denied' | 'unsupported';
const MIN_INTERESTS = 3;

/** Onboarding (F02): welcome → interests (≥ 3) → preferences. */
@Component({
  selector: 'rd-onboarding-page',
  imports: [FormsModule, TranslocoPipe, BdiText, FieldIcon, Segmented, ErrorState, Wordmark, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex min-h-dvh flex-col items-center px-4 py-8' },
  template: `
    <div class="w-full max-w-[560px]">
      <div class="flex justify-center"><rd-wordmark [size]="26" [withIcon]="true" /></div>
      <div class="mt-6 flex justify-center gap-1.5" dir="ltr" role="progressbar" aria-valuemin="1" aria-valuemax="3" [attr.aria-valuenow]="step()"
        [attr.aria-label]="'onboarding.step' | transloco: { current: step(), total: 3 }">
        @for (s of [1, 2, 3]; track s) {
          <span class="h-1.5 rounded-chip transition-all" [class]="s === step() ? 'w-6 bg-primary' : 'w-1.5 bg-border'"></span>
        }
      </div>

      <main class="mt-8">
        @switch (step()) {
          @case (1) {
            <section class="text-center">
              <h1 class="m-0 text-3xl font-bold tracking-tight">{{ 'onboarding.welcome.title' | transloco }}</h1>
              <p class="mx-auto mt-3 max-w-md text-text-secondary">{{ 'onboarding.welcome.body' | transloco }}</p>
              <ul class="mx-auto mt-8 flex max-w-sm list-none flex-col gap-4 p-0 text-start">
                <li class="flex items-start gap-3">
                  <span class="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-primary-container text-on-primary-container"><svg lucideIcon="Sparkles" [size]="20"></svg></span>
                  <span>{{ 'onboarding.welcome.point1' | transloco }}</span>
                </li>
                <li class="flex items-start gap-3">
                  <span class="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-accent-container text-text-primary"><svg lucideIcon="Flame" [size]="20"></svg></span>
                  <span>{{ 'onboarding.welcome.point2' | transloco }}</span>
                </li>
                <li class="flex items-start gap-3">
                  <span class="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-primary-container text-on-primary-container"><svg lucideIcon="ShieldCheck" [size]="20"></svg></span>
                  <span>{{ 'onboarding.welcome.point3' | transloco }}</span>
                </li>
              </ul>
              <button type="button" class="rd-btn rd-btn-primary mt-10 w-full" (click)="step.set(2)">
                {{ 'onboarding.welcome.start' | transloco }} <svg lucideIcon="ArrowLeft" [size]="18" class="ltr:rotate-180"></svg>
              </button>
            </section>
          }
          @case (2) {
            <section>
              <h1 class="m-0 text-2xl font-bold">{{ 'onboarding.interests.title' | transloco }}</h1>
              <p class="mt-1 text-sm text-text-secondary">{{ 'onboarding.interests.subtitle' | transloco }}</p>

              @if (fieldsStatus() === 'error') {
                <rd-error-state (retry)="loadFields()" />
              } @else if (fieldsStatus() === 'loading') {
                <div class="mt-5 grid grid-cols-2 gap-2 sm:grid-cols-3" aria-busy="true">
                  @for (i of [1, 2, 3, 4, 5, 6]; track i) {
                    <div class="rd-skeleton h-12 rounded-md"></div>
                  }
                </div>
              } @else {
                <div class="mt-5 grid grid-cols-2 gap-2 sm:grid-cols-3">
                  @for (field of fields(); track field.id) {
                    <button
                      type="button"
                      class="flex min-h-12 items-center gap-2 rounded-md border px-3 text-start text-sm transition-colors"
                      [class]="fieldIds().has(field.id) ? 'border-primary bg-primary-container font-semibold text-on-primary-container' : 'border-border bg-surface'"
                      [attr.aria-pressed]="fieldIds().has(field.id)"
                      (click)="toggleField(field)"
                    >
                      <rd-field-icon [name]="field.icon" class="text-primary" />
                      <span class="min-w-0 flex-1 truncate"><rd-bdi-text [text]="fieldName(field)" /></span>
                      @if (fieldIds().has(field.id)) {
                        <svg lucideIcon="Check" [size]="16" aria-hidden="true"></svg>
                      }
                    </button>
                  }
                </div>

                @for (field of selectedFields(); track field.id) {
                  @if (topics()[field.slug]?.length) {
                    <div class="mt-5">
                      <h2 class="mb-2 text-sm font-semibold">{{ 'onboarding.interests.topicsOf' | transloco: { field: fieldName(field) } }}</h2>
                      <div class="flex flex-wrap gap-2">
                        @for (topic of topics()[field.slug]; track topic.id) {
                          <button type="button" class="rd-chip" [attr.aria-pressed]="topicIds().has(topic.id)" (click)="toggleTopic(topic)">
                            <rd-bdi-text [text]="lang() === 'ar' ? topic.nameAr : topic.nameEn" />
                          </button>
                        }
                      </div>
                    </div>
                  }
                }
              }

              <p class="mt-6 text-sm" [class]="canContinue() ? 'text-success' : 'text-text-secondary'" aria-live="polite">
                {{ 'onboarding.interests.selected' | transloco: { count: selectedCount(), min: minInterests } }}
              </p>
              <div class="mt-3 flex gap-2">
                <button type="button" class="rd-btn rd-btn-ghost" (click)="step.set(1)">{{ 'common.back' | transloco }}</button>
                <button type="button" class="rd-btn rd-btn-primary flex-1" [disabled]="!canContinue()" (click)="step.set(3)">
                  {{ 'common.continue' | transloco }}
                </button>
              </div>
            </section>
          }
          @case (3) {
            <section>
              <h1 class="m-0 text-2xl font-bold">{{ 'onboarding.prefs.title' | transloco }}</h1>
              <p class="mt-1 text-sm text-text-secondary">{{ 'onboarding.prefs.subtitle' | transloco }}</p>

              <div class="mt-6">
                <span class="rd-label">{{ 'onboarding.prefs.articleLanguage' | transloco }}</span>
                <rd-segmented [options]="articleLanguageOptions()" [(value)]="articleLanguage" [label]="'onboarding.prefs.articleLanguage' | transloco" />
              </div>

              <div class="mt-5">
                <label class="rd-label" for="reminder">{{ 'onboarding.prefs.reminder' | transloco }}</label>
                <input id="reminder" type="time" class="rd-input" dir="ltr" [(ngModel)]="reminderTime" step="900" />
                <p class="mt-1 text-xs text-text-secondary">{{ 'onboarding.prefs.reminderHint' | transloco }}</p>
              </div>

              <div class="mt-5 rd-card flex items-center gap-3 p-4 shadow-none">
                <svg lucideIcon="Bell" [size]="20" class="shrink-0 text-primary" aria-hidden="true"></svg>
                <div class="flex-1 text-sm">
                  <div class="font-semibold">{{ 'onboarding.prefs.notifications' | transloco }}</div>
                  <div class="text-text-secondary">{{ 'onboarding.prefs.notificationsState.' + notificationState() | transloco }}</div>
                </div>
                @if (notificationState() === 'default') {
                  <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" (click)="enableNotifications()">
                    {{ 'onboarding.prefs.enableNotifications' | transloco }}
                  </button>
                }
              </div>

              @if (error()) {
                <p class="mt-4 rounded-md bg-callout-danger p-3 text-sm" role="alert">{{ error() }}</p>
              }
              <div class="mt-8 flex gap-2">
                <button type="button" class="rd-btn rd-btn-ghost" (click)="step.set(2)" [disabled]="saving()">{{ 'common.back' | transloco }}</button>
                <button type="button" class="rd-btn rd-btn-primary flex-1" [disabled]="saving()" (click)="finish()">
                  {{ (saving() ? 'common.saving' : 'onboarding.prefs.finish') | transloco }}
                </button>
              </div>
            </section>
          }
        }
      </main>
    </div>
  `,
})
export class OnboardingPage {
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly meApi = inject(MeApi);
  private readonly auth = inject(AuthService);
  private readonly preferences = inject(PreferencesService);
  private readonly session = inject(SessionStore);
  private readonly router = inject(Router);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  protected readonly lang = inject(LanguageService).lang;
  protected readonly minInterests = MIN_INTERESTS;

  protected readonly step = signal<Step>(1);
  protected readonly fields = signal<FieldDto[]>([]);
  protected readonly fieldsStatus = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly topics = signal<Record<string, TopicDto[]>>({});
  protected readonly fieldIds = signal(new Set<string>(this.session.me()?.interests.fieldIds ?? []));
  protected readonly topicIds = signal(new Set<string>(this.session.me()?.interests.topicIds ?? []));
  protected readonly articleLanguage = signal<ArticleLanguage>(this.session.me()?.articleLanguage ?? (this.lang() === 'ar' ? 'ar-EG' : 'en'));
  protected readonly reminderTime = signal(this.session.me()?.reminderTime ?? '08:00');
  protected readonly notificationState = signal<NotificationState>(this.readNotificationState());
  protected readonly saving = signal(false);
  protected readonly error = signal<string | null>(null);

  protected readonly selectedCount = computed(() => this.fieldIds().size + this.topicIds().size);
  protected readonly canContinue = computed(() => this.selectedCount() >= MIN_INTERESTS);
  protected readonly selectedFields = computed(() => this.fields().filter((f) => this.fieldIds().has(f.id)));
  protected readonly articleLanguageOptions = computed<SegmentOption<ArticleLanguage>[]>(() => {
    this.lang();
    return [
      { value: 'ar-EG', label: this.transloco.translate('onboarding.prefs.arEG') },
      { value: 'en', label: this.transloco.translate('onboarding.prefs.en'), ltr: true },
    ];
  });

  constructor() {
    void this.loadFields();
  }

  protected fieldName(field: FieldDto): string {
    return this.lang() === 'ar' ? field.nameAr : field.nameEn;
  }

  protected async loadFields(): Promise<void> {
    this.fieldsStatus.set('loading');
    try {
      this.fields.set(await firstValueFrom(this.taxonomy.fields()));
      this.fieldsStatus.set('loaded');
      for (const field of this.selectedFields()) void this.loadTopics(field);
    } catch {
      this.fieldsStatus.set('error');
    }
  }

  protected toggleField(field: FieldDto): void {
    const next = new Set(this.fieldIds());
    if (next.has(field.id)) {
      next.delete(field.id);
      // Drop topics of a deselected field.
      const fieldTopics = new Set((this.topics()[field.slug] ?? []).map((t) => t.id));
      this.topicIds.update((ids) => new Set([...ids].filter((id) => !fieldTopics.has(id))));
    } else {
      next.add(field.id);
      void this.loadTopics(field);
    }
    this.fieldIds.set(next);
  }

  protected toggleTopic(topic: TopicDto): void {
    const next = new Set(this.topicIds());
    if (next.has(topic.id)) next.delete(topic.id);
    else next.add(topic.id);
    this.topicIds.set(next);
  }

  protected async enableNotifications(): Promise<void> {
    if (!this.isBrowser || !('Notification' in window)) return;
    // FCM web-push token registration (POST /me/devices) is wired with F17.
    const result = await Notification.requestPermission();
    this.notificationState.set(result === 'granted' ? 'granted' : result === 'denied' ? 'denied' : 'default');
  }

  protected async finish(): Promise<void> {
    this.saving.set(true);
    this.error.set(null);
    try {
      await firstValueFrom(this.meApi.updateInterests({ fieldIds: [...this.fieldIds()], topicIds: [...this.topicIds()] }));
      await this.preferences.save({ articleLanguage: this.articleLanguage(), reminderTime: this.reminderTime() || '08:00' });
      // The API derives onboardingCompleted from ≥ 3 interests; patch locally if the refresh fails.
      const me = await this.auth.refreshMe();
      if (!me?.onboardingCompleted) this.session.patchMe({ onboardingCompleted: true });
      await this.router.navigateByUrl('/');
    } catch (error) {
      this.error.set(this.errors.forError(error));
    } finally {
      this.saving.set(false);
    }
  }

  private async loadTopics(field: FieldDto): Promise<void> {
    if (this.topics()[field.slug] || field.topicCount === 0) return;
    try {
      const topics = await firstValueFrom(this.taxonomy.topics(field.slug));
      this.topics.update((map) => ({ ...map, [field.slug]: topics }));
    } catch {
      /* topics are optional */
    }
  }

  private readNotificationState(): NotificationState {
    if (!this.isBrowser || !('Notification' in window)) return 'unsupported';
    return Notification.permission === 'granted' ? 'granted' : Notification.permission === 'denied' ? 'denied' : 'default';
  }
}
