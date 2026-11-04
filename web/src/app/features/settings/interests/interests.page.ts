import { ChangeDetectionStrategy, Component, PLATFORM_ID, WritableSignal, computed, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { Observable, firstValueFrom } from 'rxjs';
import { isApiError } from '../../../core/api/api.config';
import { FollowsApi } from '../../../core/api/follows.api';
import { FieldDto, InterestsDto, TopicDto } from '../../../core/api/models';
import { TaxonomyApi } from '../../../core/api/taxonomy.api';
import { AuthService } from '../../../core/auth/auth.service';
import { SessionStore } from '../../../core/auth/session.store';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { PluralPipe } from '../../../shared/pipes/format.pipes';
import { ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { InterestChips, interestKey } from '../../onboarding/interest-chips';

type Status = 'loading' | 'loaded' | 'error';

function toggled(ids: ReadonlySet<string>, id: string, on: boolean): ReadonlySet<string> {
  const next = new Set(ids);
  if (on) next.add(id);
  else next.delete(id);
  return next;
}

/**
 * Settings → Your interests (F12), `/settings/interests`: the fields and topics you follow, with the same chips as
 * onboarding (F02). Each tap is saved at once (`PUT`/`DELETE /me/interests/{fields|topics}/{id}`) and shows right away;
 * a refusal undoes it (the API keeps at least 3 interests). The session's `me.interests` follows, so Home's For you and
 * the suggested writers use the new interests. Signed-in only; rendered in the browser.
 */
@Component({
  selector: 'rd-interests-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, ErrorState, InterestChips, PluralPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[640px] px-4 pb-16 pt-6' },
  template: `
    <a routerLink="/settings" class="-ms-1 mb-2 inline-flex min-h-11 items-center gap-1 rounded-md px-1 text-sm text-text-secondary no-underline hover:text-text-primary" data-back-to-settings>
      <svg lucideIcon="ArrowRight" [size]="18" class="shrink-0 ltr:rotate-180" aria-hidden="true"></svg>
      {{ 'settings.interests.back' | transloco }}
    </a>
    <h1 class="m-0 text-2xl font-bold">{{ 'settings.interests.title' | transloco }}</h1>
    <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'settings.interests.subtitle' | transloco }}</p>

    @switch (status()) {
      @case ('error') {
        <rd-error-state class="mt-6" (retry)="load()" />
      }
      @case ('loaded') {
        <section data-interests>
          <rd-interest-chips
            [fields]="fields()"
            [topics]="topics()"
            [fieldIds]="fieldIds()"
            [topicIds]="topicIds()"
            [lang]="lang()"
            [busy]="busy()"
            (fieldToggle)="toggleField($event)"
            (topicToggle)="toggleTopic($event)"
          />
          <p class="m-0 mt-6 text-sm text-text-secondary" aria-live="polite" data-interest-count>
            {{ count() | rdPlural: 'settings.interests.count' : lang() }}
          </p>
        </section>
      }
      @default {
        <div class="mt-5 grid grid-cols-2 gap-2 sm:grid-cols-3" aria-busy="true" data-interests-loading>
          @for (i of [1, 2, 3, 4, 5, 6]; track i) {
            <div class="rd-skeleton h-12 rounded-md"></div>
          }
        </div>
      }
    }
  `,
})
export class InterestsPage {
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly api = inject(FollowsApi);
  private readonly auth = inject(AuthService);
  private readonly session = inject(SessionStore);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  protected readonly status = signal<Status>('loading');
  protected readonly fields = signal<FieldDto[]>([]);
  protected readonly topics = signal<Record<string, TopicDto[]>>({});
  /** What the chips show: your saved interests, plus the taps still on their way to the API. */
  protected readonly fieldIds = signal<ReadonlySet<string>>(new Set());
  protected readonly topicIds = signal<ReadonlySet<string>>(new Set());
  /** Chips being saved ({@link interestKey}); another tap on one waits until it is done. */
  protected readonly busy = signal<ReadonlySet<string>>(new Set());
  protected readonly count = computed(() => this.fieldIds().size + this.topicIds().size);

  constructor() {
    if (isPlatformBrowser(inject(PLATFORM_ID))) void this.load();
  }

  protected async load(): Promise<void> {
    this.status.set('loading');
    try {
      // Your interests may have changed on another device: the page starts from a fresh `GET /me`.
      const [fields] = await Promise.all([firstValueFrom(this.taxonomy.fields()), this.auth.refreshMe()]);
      this.fields.set(fields);
      this.showSaved();
      this.status.set('loaded');
      void this.loadTopics();
    } catch {
      this.status.set('error');
    }
  }

  protected toggleField(field: FieldDto): Promise<void> {
    const follow = !this.fieldIds().has(field.id);
    if (follow) void this.topicsOf(field);
    return this.save(interestKey('field', field.id), this.fieldIds, field.id, follow, () =>
      follow ? this.api.followField(field.id) : this.api.unfollowField(field.id),
    );
  }

  protected toggleTopic(topic: TopicDto): Promise<void> {
    const follow = !this.topicIds().has(topic.id);
    return this.save(interestKey('topic', topic.id), this.topicIds, topic.id, follow, () =>
      follow ? this.api.followTopic(topic.id) : this.api.unfollowTopic(topic.id),
    );
  }

  /** Shows the change at once; the API's answer becomes the session's interests, a refusal undoes the change. */
  private async save(key: string, ids: WritableSignal<ReadonlySet<string>>, id: string, follow: boolean, request: () => Observable<InterestsDto>): Promise<void> {
    if (this.busy().has(key)) return;
    this.busy.update((keys) => toggled(keys, key, true));
    ids.update((current) => toggled(current, id, follow));
    try {
      const saved = await firstValueFrom(request());
      this.session.patchMe({ interests: { fieldIds: [...saved.fieldIds], topicIds: [...saved.topicIds] } });
    } catch (error) {
      ids.update((current) => toggled(current, id, !follow));
      this.toasts.error(
        isApiError(error) && error.code === 'user.interests.min_three' ? this.transloco.translate('settings.interests.minThree') : this.errors.forError(error),
      );
    } finally {
      this.busy.update((keys) => toggled(keys, key, false));
      // Once nothing is on its way, the chips show what the API last confirmed.
      if (!this.busy().size) this.showSaved();
    }
  }

  private showSaved(): void {
    const interests = this.session.me()?.interests ?? { fieldIds: [], topicIds: [] };
    this.fieldIds.set(new Set(interests.fieldIds));
    this.topicIds.set(new Set(interests.topicIds));
  }

  /**
   * The topics of the fields you follow; when you follow a topic of another field (chosen elsewhere, e.g. in the app),
   * the other fields' topics too, so every followed topic shows (and can be unfollowed).
   */
  private async loadTopics(): Promise<void> {
    const followed = this.fields().filter((f) => this.fieldIds().has(f.id));
    await Promise.all(followed.map((f) => this.topicsOf(f)));
    const listed = new Set(Object.values(this.topics()).flatMap((list) => list.map((t) => t.id)));
    if ([...this.topicIds()].some((id) => !listed.has(id))) {
      await Promise.all(this.fields().map((f) => this.topicsOf(f)));
    }
  }

  private async topicsOf(field: FieldDto): Promise<void> {
    if (this.topics()[field.slug] || field.topicCount === 0) return;
    try {
      const topics = await firstValueFrom(this.taxonomy.topics(field.slug));
      this.topics.update((map) => ({ ...map, [field.slug]: topics }));
    } catch {
      /* the field's topics stay hidden; the field itself can still be followed */
    }
  }
}
