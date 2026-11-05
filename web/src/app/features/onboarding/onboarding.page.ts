import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { MeApi } from '../../core/api/me.api';
import { ArticleLanguage, FieldDto, TopicDto } from '../../core/api/models';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { safeReturnUrl } from '../../core/auth/account-setup';
import { AuthService } from '../../core/auth/auth.service';
import { PreferencesService } from '../../core/auth/preferences.service';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { PushService } from '../../core/push/push.service';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { ErrorState } from '../../shared/ui/states';
import { Wordmark } from '../../shared/ui/wordmark';
import { InterestChips } from './interest-chips';

type Step = 1 | 2 | 3;
const MIN_INTERESTS = 3;

/** Onboarding (F02): welcome → interests (≥ 3) → preferences. */
@Component({
  selector: 'rd-onboarding-page',
  imports: [FormsModule, TranslocoPipe, InterestChips, Segmented, ErrorState, Wordmark, LucideDynamicIcon],
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

      <!-- One card, like the sign-in screens. -->
      <main class="rd-card mt-8 p-6 sm:p-8">
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
                <rd-interest-chips
                  [fields]="fields()"
                  [topics]="topics()"
                  [fieldIds]="fieldIds()"
                  [topicIds]="topicIds()"
                  [lang]="lang()"
                  (fieldToggle)="toggleField($event)"
                  (topicToggle)="toggleTopic($event)"
                />
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
  protected readonly lang = inject(LanguageService).lang;
  protected readonly minInterests = MIN_INTERESTS;
  /** Where the user was going before the account-setup steps (SPEC §9.2). */
  readonly returnUrl = input<string | null>(null);

  protected readonly step = signal<Step>(1);
  protected readonly fields = signal<FieldDto[]>([]);
  protected readonly fieldsStatus = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly topics = signal<Record<string, TopicDto[]>>({});
  protected readonly fieldIds = signal(new Set<string>(this.session.me()?.interests.fieldIds ?? []));
  protected readonly topicIds = signal(new Set<string>(this.session.me()?.interests.topicIds ?? []));
  protected readonly articleLanguage = signal<ArticleLanguage>(this.session.me()?.articleLanguage ?? (this.lang() === 'ar' ? 'ar-EG' : 'en'));
  protected readonly reminderTime = signal(this.session.me()?.reminderTime ?? '08:00');
  private readonly push = inject(PushService);
  protected readonly notificationState = this.push.permission;
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

  /** In context, from the reminder step (SPEC §21.1); granting registers this browser for web push. */
  protected async enableNotifications(): Promise<void> {
    await this.push.enable();
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
      await this.router.navigateByUrl(safeReturnUrl(this.returnUrl()));
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
}
