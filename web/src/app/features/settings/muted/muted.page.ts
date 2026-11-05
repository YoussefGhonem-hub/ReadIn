import { ChangeDetectionStrategy, Component, PLATFORM_ID, computed, inject, signal } from '@angular/core';
import { NgTemplateOutlet, isPlatformBrowser } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { MutedFieldDto, MutedTopicDto, MutesDto, UserSummaryDto } from '../../../core/api/models';
import { MutesApi } from '../../../core/api/mutes.api';
import { LanguageService } from '../../../core/i18n/language.service';
import { MuteStore } from '../../../core/social/mute.store';
import { isolate } from '../../../shared/directives/bidi';
import { provideMuteIcons } from '../../../shared/mutes/mute-icons';
import { Avatar } from '../../../shared/ui/avatar';
import { FieldIcon } from '../../../shared/ui/field-icon';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { fieldColorOf } from '../../search/search-query';

type Status = 'loading' | 'loaded' | 'error';

/**
 * Settings → Muted (F18, F28), `/settings/muted`: one list of the writers, fields and topics you muted (`GET /me/mutes`,
 * newest first in each group), each with "إلغاء الكتم". Unmuting a row removes it once saved and confirms with a toast;
 * it doesn't follow the writer again. With nothing muted: the empty state, which says where muting happens. Signed-in
 * only; rendered in the browser.
 */
@Component({
  selector: 'rd-muted-page',
  imports: [NgTemplateOutlet, RouterLink, TranslocoPipe, LucideDynamicIcon, Avatar, FieldIcon, EmptyState, ErrorState],
  providers: [provideMuteIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[640px] flex-col gap-2 px-4 pb-16 pt-5 lg:pt-8' },
  template: `
    <header class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 px-4 pb-4 pt-2 lg:px-5 lg:pb-5 lg:pt-3">
      <a routerLink="/settings" class="-ms-1 inline-flex min-h-11 items-center gap-1 rounded-md px-1 text-sm text-text-secondary no-underline hover:text-text-primary" data-back-to-settings>
        <svg lucideIcon="ArrowRight" [size]="18" class="shrink-0 ltr:rotate-180" aria-hidden="true"></svg>
        {{ 'mute.settings.back' | transloco }}
      </a>
      <h1 class="m-0 mt-1 text-xl font-bold lg:text-2xl">{{ 'mute.settings.title' | transloco }}</h1>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'mute.settings.subtitle' | transloco }}</p>
    </header>

    @switch (status()) {
      @case ('error') {
        <rd-error-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [message]="'mute.settings.loadError' | transloco" (retry)="load()" />
      }
      @case ('loaded') {
        @if (empty()) {
          <rd-empty-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [title]="'mute.settings.emptyTitle' | transloco" [message]="'mute.settings.emptyBody' | transloco" data-muted-empty />
        } @else {
          <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" data-muted-list>
            @if (users().length) {
              <section aria-labelledby="muted-writers">
                <h2 id="muted-writers" class="m-0 px-4 pb-1 pt-4 text-sm font-semibold text-text-secondary lg:px-5">{{ 'mute.settings.writers' | transloco }}</h2>
                <ul class="m-0 list-none divide-y divide-border p-0">
                  @for (user of users(); track user.id) {
                    <li class="flex items-center gap-3 px-4 py-3 lg:px-5" data-muted-user [attr.data-muted-id]="user.id">
                      <a [routerLink]="'/@' + user.username" class="flex shrink-0 rounded-full" tabindex="-1" aria-hidden="true">
                        <rd-avatar [name]="user.displayName" [src]="user.avatarUrl" [size]="40" />
                      </a>
                      <div class="min-w-0 flex-1">
                        <a [routerLink]="'/@' + user.username" class="flex min-w-0 items-center gap-1 font-semibold text-text-primary no-underline hover:underline">
                          <span class="truncate" dir="auto">{{ user.displayName }}</span>
                          @if (user.isVerified) {
                            <svg lucideIcon="BadgeCheck" [size]="15" class="shrink-0 text-primary" role="img" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
                          }
                        </a>
                        <bdi dir="ltr" class="block truncate text-xs text-text-secondary">&#64;{{ user.username }}</bdi>
                      </div>
                      <ng-container *ngTemplateOutlet="unmuteButton; context: { key: 'user:' + user.id, name: user.displayName }" />
                    </li>
                  }
                </ul>
              </section>
            }
            @if (fields().length) {
              <section [class.border-t]="users().length" class="border-border" aria-labelledby="muted-fields">
                <h2 id="muted-fields" class="m-0 px-4 pb-1 pt-4 text-sm font-semibold text-text-secondary lg:px-5">{{ 'mute.settings.fields' | transloco }}</h2>
                <ul class="m-0 list-none divide-y divide-border p-0">
                  @for (field of fields(); track field.id) {
                    <li class="flex items-center gap-3 px-4 py-3 lg:px-5" data-muted-field [attr.data-muted-id]="field.id">
                      <span class="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-surface-variant" [style.color]="color(field.color)">
                        <rd-field-icon [name]="field.icon" [size]="20" />
                      </span>
                      <span class="min-w-0 flex-1 truncate font-semibold"><bdi>{{ nameOf(field) }}</bdi></span>
                      <ng-container *ngTemplateOutlet="unmuteButton; context: { key: 'field:' + field.id, name: nameOf(field) }" />
                    </li>
                  }
                </ul>
              </section>
            }
            @if (topics().length) {
              <section [class.border-t]="users().length || fields().length" class="border-border" aria-labelledby="muted-topics">
                <h2 id="muted-topics" class="m-0 px-4 pb-1 pt-4 text-sm font-semibold text-text-secondary lg:px-5">{{ 'mute.settings.topics' | transloco }}</h2>
                <ul class="m-0 list-none divide-y divide-border p-0">
                  @for (topic of topics(); track topic.id) {
                    <li class="flex items-center gap-3 px-4 py-3 lg:px-5" data-muted-topic [attr.data-muted-id]="topic.id">
                      <span class="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-surface-variant" [style.color]="color(topic.field.color)">
                        <rd-field-icon [name]="topic.field.icon" [size]="20" />
                      </span>
                      <span class="min-w-0 flex-1">
                        <span class="block truncate font-semibold"><bdi>{{ nameOf(topic) }}</bdi></span>
                        <span class="block truncate text-xs text-text-secondary">{{ 'mute.settings.topicIn' | transloco: { field: isolate(nameOf(topic.field)) } }}</span>
                      </span>
                      <ng-container *ngTemplateOutlet="unmuteButton; context: { key: 'topic:' + topic.id, name: nameOf(topic) }" />
                    </li>
                  }
                </ul>
              </section>
            }
          </div>
        }
      }
      @default {
        <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 flex flex-col gap-4 p-4 lg:p-5" aria-busy="true" data-muted-loading>
          @for (i of [1, 2, 3]; track i) {
            <div class="flex items-center gap-3">
              <div class="rd-skeleton h-10 w-10 shrink-0 rounded-full"></div>
              <div class="rd-skeleton h-4 flex-1"></div>
              <div class="rd-skeleton h-9 w-24"></div>
            </div>
          }
        </div>
      }
    }

    <ng-template #unmuteButton let-key="key" let-name="name">
      <button
        type="button"
        class="rd-btn rd-btn-outline min-h-11 shrink-0 gap-1.5 px-3 text-sm"
        [disabled]="busy().has(key)"
        [attr.aria-label]="'mute.settings.unmuteLabel' | transloco: { name: isolate(name) }"
        data-muted-unmute
        (click)="unmute(key)"
      >
        <svg lucideIcon="Volume2" [size]="16" aria-hidden="true"></svg>
        {{ 'mute.settings.unmute' | transloco }}
      </button>
    </ng-template>
  `,
})
export class MutedPage {
  private readonly api = inject(MutesApi);
  private readonly mutes = inject(MuteStore);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;
  protected readonly isolate = isolate;

  protected readonly status = signal<Status>('loading');
  protected readonly users = signal<UserSummaryDto[]>([]);
  protected readonly fields = signal<MutedFieldDto[]>([]);
  protected readonly topics = signal<MutedTopicDto[]>([]);
  /** Rows being unmuted (`user:{id}`, `field:{id}`, `topic:{id}`). */
  protected readonly busy = signal<ReadonlySet<string>>(new Set());
  protected readonly empty = computed(() => !this.users().length && !this.fields().length && !this.topics().length);

  constructor() {
    if (isPlatformBrowser(inject(PLATFORM_ID))) void this.load();
  }

  protected async load(): Promise<void> {
    this.status.set('loading');
    try {
      const mutes: MutesDto = await firstValueFrom(this.api.mutes());
      this.mutes.learn(mutes);
      this.users.set(mutes.users);
      this.fields.set(mutes.fields);
      this.topics.set(mutes.topics);
      this.status.set('loaded');
    } catch {
      this.status.set('error');
    }
  }

  protected nameOf(ref: { nameAr: string; nameEn: string }): string {
    return this.lang() === 'ar' ? ref.nameAr : ref.nameEn;
  }

  protected color(token: string): string {
    return fieldColorOf(token);
  }

  /** Unmutes a row; it leaves the list once saved (a failure keeps it, with the error toast). */
  protected async unmute(key: string): Promise<void> {
    if (this.busy().has(key)) return;
    const [kind, id] = [key.slice(0, key.indexOf(':')), key.slice(key.indexOf(':') + 1)];
    this.busy.update((set) => new Set(set).add(key));
    try {
      if (kind === 'user') {
        const user = this.users().find((u) => u.id === id);
        if (user && (await this.mutes.unmuteAuthor(user))) this.users.update((list) => list.filter((u) => u.id !== id));
      } else if (kind === 'field') {
        const field = this.fields().find((f) => f.id === id);
        if (field && (await this.mutes.setFieldMuted(id, false))) {
          this.fields.update((list) => list.filter((f) => f.id !== id));
          this.unmuted(this.nameOf(field));
        }
      } else {
        const topic = this.topics().find((t) => t.id === id);
        if (topic && (await this.mutes.setTopicMuted(id, false))) {
          this.topics.update((list) => list.filter((t) => t.id !== id));
          this.unmuted(this.nameOf(topic));
        }
      }
    } finally {
      this.busy.update((set) => {
        const next = new Set(set);
        next.delete(key);
        return next;
      });
    }
  }

  private unmuted(name: string): void {
    this.toasts.success(this.transloco.translate('mute.toast.unmuted', { name: isolate(name) }));
  }
}
