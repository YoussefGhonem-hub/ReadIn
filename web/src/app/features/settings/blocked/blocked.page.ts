import { ChangeDetectionStrategy, Component, PLATFORM_ID, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { BlocksApi } from '../../../core/api/blocks.api';
import { BlockedUserDto } from '../../../core/api/models';
import { LanguageService } from '../../../core/i18n/language.service';
import { BlockStore } from '../../../core/social/block.store';
import { BdiText } from '../../../shared/directives/bdi-text';
import { LocalizedDatePipe } from '../../../shared/pipes/format.pipes';
import { Avatar } from '../../../shared/ui/avatar';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { VerifiedBadge } from '../../../shared/ui/verified-badge';

type Status = 'loading' | 'loaded' | 'error';

/**
 * Settings → Blocked accounts (F18, F36), `/settings/blocked`: the people you blocked (`GET /me/blocked`, newest first)
 * with when, each with «إلغاء الحظر». Unblocking a row removes it once saved and confirms with a toast; it never follows
 * them again. Signed-in only; rendered in the browser.
 */
@Component({
  selector: 'rd-blocked-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, LocalizedDatePipe, Avatar, EmptyState, ErrorState, VerifiedBadge],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[640px] flex-col gap-2 px-4 pb-16 pt-5 lg:pt-8', 'data-blocked-page': '' },
  template: `
    <header class="rd-card px-4 pb-4 pt-2 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:px-5 lg:pb-5 lg:pt-3">
      <a routerLink="/settings" class="-ms-1 inline-flex min-h-11 items-center gap-1 rounded-md px-1 text-sm text-text-secondary no-underline hover:text-text-primary" data-back-to-settings>
        <svg lucideIcon="ArrowRight" [size]="18" class="shrink-0 ltr:rotate-180" aria-hidden="true"></svg>
        {{ 'mute.settings.back' | transloco }}
      </a>
      <h1 class="m-0 mt-1 text-xl font-bold lg:text-2xl">{{ 'block.settings.title' | transloco }}</h1>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'block.settings.subtitle' | transloco }}</p>
    </header>

    @switch (status()) {
      @case ('error') {
        <rd-error-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [message]="'block.settings.loadError' | transloco" (retry)="load()" />
      }
      @case ('loaded') {
        @if (items().length) {
          <ul class="rd-card m-0 list-none divide-y divide-border p-0 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" data-blocked-list>
            @for (b of items(); track b.user.id) {
              <li class="flex items-center gap-3 px-4 py-3 lg:px-5" [attr.data-blocked-user]="b.user.id">
                <rd-avatar [name]="b.user.displayName" [src]="b.user.avatarUrl" [size]="40" />
                <span class="min-w-0 flex-1">
                  <span class="flex items-center gap-1 font-semibold">
                    <rd-bdi-text class="truncate" [text]="b.user.displayName" />
                    @if (b.user.isVerified) {
                      <rd-verified-badge [size]="14" />
                    }
                  </span>
                  <span class="block truncate text-xs text-text-secondary">
                    <bdi dir="ltr">&#64;{{ b.user.username }}</bdi> · {{ 'block.settings.since' | transloco: { date: (b.blockedAt | rdDate: lang()) } }}
                  </span>
                </span>
                <button type="button" class="rd-btn rd-btn-outline min-h-10 shrink-0 px-3 text-sm" [disabled]="busy().has(b.user.id)" (click)="unblock(b)" data-unblock>
                  {{ 'block.unblock' | transloco }}
                </button>
              </li>
            }
          </ul>
        } @else {
          <rd-empty-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [title]="'block.settings.emptyTitle' | transloco" [message]="'block.settings.emptyBody' | transloco" data-blocked-empty />
        }
      }
      @default {
        <div class="rd-card flex flex-col gap-3 p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-busy="true" data-blocked-loading>
          @for (i of [1, 2, 3]; track i) {
            <div class="flex items-center gap-3" aria-hidden="true">
              <div class="rd-skeleton h-10 w-10 rounded-full"></div>
              <div class="rd-skeleton h-4 flex-1"></div>
            </div>
          }
        </div>
      }
    }
  `,
})
export class BlockedPage {
  private readonly api = inject(BlocksApi);
  private readonly blocks = inject(BlockStore);
  protected readonly lang = inject(LanguageService).lang;

  protected readonly status = signal<Status>('loading');
  protected readonly items = signal<BlockedUserDto[]>([]);
  protected readonly busy = signal<ReadonlySet<string>>(new Set());

  constructor() {
    if (isPlatformBrowser(inject(PLATFORM_ID))) void this.load();
  }

  async load(): Promise<void> {
    this.status.set('loading');
    try {
      const { items } = await firstValueFrom(this.api.blocked());
      this.items.set(items);
      this.status.set('loaded');
    } catch {
      this.status.set('error');
    }
  }

  protected async unblock(entry: BlockedUserDto): Promise<void> {
    const id = entry.user.id;
    if (this.busy().has(id)) return;
    this.busy.update((set) => new Set(set).add(id));
    const done = await this.blocks.unblock({ id, displayName: entry.user.displayName, username: entry.user.username });
    if (done) this.items.update((items) => items.filter((b) => b.user.id !== id));
    this.busy.update((set) => {
      const next = new Set(set);
      next.delete(id);
      return next;
    });
  }
}
