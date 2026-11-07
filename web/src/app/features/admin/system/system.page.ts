import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminApi } from '../../../core/api/admin.api';
import { AdminSystemDto } from '../../../core/api/models';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { LocalizedDatePipe, PluralPipe, RelativeTimePipe, formatFileSize } from '../../../shared/pipes/format.pipes';
import { ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { ADMIN_CARD, ADMIN_TABLE_STYLES, AdminConfirm, AdminPageHeader } from '../admin-ui';

/** "1.2 s" / "340 ms". */
export function formatDuration(ms: number | null): string {
  if (ms === null) return '—';
  return ms >= 1000 ? `${(ms / 1000).toFixed(1)} s` : `${Math.round(ms)} ms`;
}

/**
 * System (F23, `system.settings`, web only), `/admin/system`: read only. The API's version, start time and environment;
 * the app update policy (§8.3); whether the database and Firebase answer; each background job's last run and its runs and
 * failures in the last 24 hours; push deliveries in the last 24 hours; and the disk used by uploads and the private store.
 * "Rebuild counters" (F27) is the one action, confirmed. Settings change in configuration, not here.
 */
@Component({
  selector: 'rd-admin-system-page',
  imports: [TranslocoPipe, LucideDynamicIcon, LocalizedDatePipe, PluralPipe, RelativeTimePipe, ErrorState, AdminConfirm, AdminPageHeader],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col gap-2', 'data-admin-system': '' },
  styles: [
    ADMIN_TABLE_STYLES,
    `
      .tiles {
        display: grid;
        gap: 0.5rem;
      }
      @media (width >= 48rem) {
        .tiles {
          grid-template-columns: repeat(2, minmax(0, 1fr));
        }
      }
      .facts {
        display: grid;
        grid-template-columns: minmax(0, auto) minmax(0, 1fr);
        gap: 0.375rem 1rem;
      }
    `,
  ],
  template: `
    <rd-admin-page-header [title]="'admin.nav.system' | transloco" [subtitle]="'admin.system.subtitle' | transloco">
      <button type="button" class="rd-btn rd-btn-outline min-h-11 px-4" [disabled]="loading()" (click)="load()" data-system-refresh>
        <svg lucideIcon="RefreshCw" [size]="16" aria-hidden="true"></svg>
        {{ 'admin.refresh' | transloco }}
      </button>
    </rd-admin-page-header>

    @if (data(); as s) {
      <div class="tiles">
        <section [class]="card + ' p-4'" aria-labelledby="system-api" data-system-api>
          <h2 id="system-api" class="m-0 mb-2 text-base font-semibold">{{ 'admin.system.api' | transloco }}</h2>
          <dl class="facts m-0 text-sm">
            <dt class="text-text-secondary">{{ 'admin.system.version' | transloco }}</dt>
            <dd class="m-0 [overflow-wrap:anywhere]" dir="ltr">{{ s.api.version }}</dd>
            <dt class="text-text-secondary">{{ 'admin.system.started' | transloco }}</dt>
            <dd class="m-0"><time [attr.datetime]="s.api.startedAt" [title]="s.api.startedAt | rdDate: lang() : 'long'">{{ s.api.startedAt | rdRelativeTime: lang() }}</time></dd>
            <dt class="text-text-secondary">{{ 'admin.system.environment' | transloco }}</dt>
            <dd class="m-0" dir="ltr">{{ s.api.environment }}</dd>
          </dl>
        </section>

        <section [class]="card + ' p-4'" aria-labelledby="system-health" data-system-health>
          <h2 id="system-health" class="m-0 mb-2 text-base font-semibold">{{ 'admin.system.health' | transloco }}</h2>
          <ul class="m-0 flex list-none flex-col gap-1.5 p-0 text-sm">
            <li class="flex items-center gap-2" [attr.data-health]="'database'">
              <svg [lucideIcon]="s.database.reachable ? 'CircleCheck' : 'CircleX'" [size]="16" [class]="s.database.reachable ? 'text-success' : 'text-error'" aria-hidden="true"></svg>
              {{ 'admin.system.database' | transloco }}:
              {{ (s.database.reachable ? 'admin.system.reachable' : 'admin.system.unreachable') | transloco }}
              @if (s.database.latencyMs !== null) {
                <bdi dir="ltr" class="text-text-secondary">({{ s.database.latencyMs }} ms)</bdi>
              }
            </li>
            <li class="flex items-center gap-2" data-health="messaging">
              <svg [lucideIcon]="s.firebase.messagingConfigured ? 'CircleCheck' : 'CircleAlert'" [size]="16" [class]="s.firebase.messagingConfigured ? 'text-success' : 'text-text-secondary'" aria-hidden="true"></svg>
              {{ 'admin.system.messaging' | transloco }}: {{ (s.firebase.messagingConfigured ? 'admin.system.configured' : 'admin.system.notConfigured') | transloco }}
            </li>
            <li class="flex items-center gap-2" data-health="realtime">
              @let rtdb = s.firebase.realtimeReachable;
              <svg
                [lucideIcon]="!s.firebase.realtimeConfigured ? 'CircleAlert' : rtdb ? 'CircleCheck' : 'CircleX'"
                [size]="16"
                [class]="!s.firebase.realtimeConfigured ? 'text-text-secondary' : rtdb ? 'text-success' : 'text-error'"
                aria-hidden="true"
              ></svg>
              {{ 'admin.system.realtime' | transloco }}:
              @if (!s.firebase.realtimeConfigured) {
                {{ 'admin.system.notConfigured' | transloco }}
              } @else {
                {{ (rtdb ? 'admin.system.reachable' : 'admin.system.unreachable') | transloco }}
              }
            </li>
          </ul>
        </section>

        <section [class]="card + ' p-4'" aria-labelledby="system-policy" data-system-policy>
          <h2 id="system-policy" class="m-0 mb-2 text-base font-semibold">{{ 'admin.system.updatePolicy' | transloco }}</h2>
          <dl class="facts m-0 text-sm">
            @for (platform of platforms; track platform) {
              @let p = s.updatePolicy[platform];
              <dt class="text-text-secondary" dir="ltr">{{ platform === 'ios' ? 'iOS' : 'Android' }}</dt>
              <dd class="m-0">
                <bdi dir="ltr">{{ p.minimumVersion ?? ('admin.system.noMinimum' | transloco) }}</bdi>
                @if (p.storeUrl; as url) {
                  · <a [href]="url" target="_blank" rel="noopener noreferrer" class="text-link">{{ 'admin.system.store' | transloco }}</a>
                }
              </dd>
            }
          </dl>
        </section>

        <section [class]="card + ' p-4'" aria-labelledby="system-push" data-system-push>
          <h2 id="system-push" class="m-0 mb-2 text-base font-semibold">{{ 'admin.system.push' | transloco }}</h2>
          <dl class="facts m-0 text-sm">
            <dt class="text-text-secondary">{{ 'admin.system.pushSent' | transloco }}</dt>
            <dd class="m-0 tabular-nums">{{ s.push.sent }}</dd>
            <dt class="text-text-secondary">{{ 'admin.system.pushFailed' | transloco }}</dt>
            <dd class="m-0 tabular-nums" [class.text-error]="s.push.failed > 0">{{ s.push.failed }}</dd>
            <dt class="text-text-secondary">{{ 'admin.system.invalidTokens' | transloco }}</dt>
            <dd class="m-0 tabular-nums">{{ s.push.invalidTokens }}</dd>
          </dl>
          <h2 class="m-0 mb-2 mt-4 text-base font-semibold">{{ 'admin.system.storage' | transloco }}</h2>
          <dl class="facts m-0 text-sm" data-system-storage>
            <dt class="text-text-secondary">{{ 'admin.system.uploads' | transloco }}</dt>
            <dd class="m-0">{{ size(s.storage.uploadsBytes) }} · {{ s.storage.uploadsFiles | rdPlural: 'admin.system.files' : lang() }}</dd>
            <dt class="text-text-secondary">{{ 'admin.system.private' | transloco }}</dt>
            <dd class="m-0">{{ size(s.storage.privateBytes) }} · {{ s.storage.privateFiles | rdPlural: 'admin.system.files' : lang() }}</dd>
          </dl>
          <p class="m-0 mt-2 text-xs text-text-secondary">{{ 'admin.system.measured' | transloco: { time: (s.storage.measuredAt | rdRelativeTime: lang()) } }}</p>
        </section>
      </div>

      <section [class]="card" aria-labelledby="system-jobs" data-system-jobs>
        <h2 id="system-jobs" class="m-0 px-4 pb-2 pt-4 text-base font-semibold">{{ 'admin.system.jobs' | transloco }}</h2>
        <table class="admin-table">
          <thead>
            <tr>
              <th scope="col">{{ 'admin.system.job' | transloco }}</th>
              <th scope="col">{{ 'admin.system.lastRun' | transloco }}</th>
              <th scope="col" class="num">{{ 'admin.system.duration' | transloco }}</th>
              <th scope="col" class="num">{{ 'admin.system.runs24h' | transloco }}</th>
              <th scope="col" class="num">{{ 'admin.system.failures24h' | transloco }}</th>
            </tr>
          </thead>
          <tbody>
            @for (j of s.jobs; track j.id) {
              <tr [attr.data-job]="j.id">
                <td class="cell-main">
                  <bdi dir="ltr" class="font-semibold">{{ j.id }}</bdi>
                  @if (j.schedule) {
                    <bdi dir="ltr" class="block text-xs text-text-secondary">{{ j.schedule }}</bdi>
                  } @else {
                    <span class="block text-xs text-text-secondary" data-job-unregistered>{{ 'admin.system.unregistered' | transloco }}</span>
                  }
                  @if (j.lastError) {
                    <span class="mt-1 block text-xs text-error [overflow-wrap:anywhere]" dir="ltr" data-job-error>{{ j.lastError }}</span>
                  }
                </td>
                <td [attr.data-label]="'admin.system.lastRun' | transloco">
                  @if (j.lastRunAt; as at) {
                    <span class="inline-flex items-center gap-1">
                      <svg [lucideIcon]="j.lastSucceeded ? 'CircleCheck' : 'CircleX'" [size]="14" [class]="j.lastSucceeded ? 'text-success' : 'text-error'" aria-hidden="true"></svg>
                      <span class="sr-only">{{ (j.lastSucceeded ? 'admin.system.succeeded' : 'admin.system.failed') | transloco }}</span>
                      <time [attr.datetime]="at" [title]="at | rdDate: lang() : 'long'">{{ at | rdRelativeTime: lang() }}</time>
                    </span>
                  } @else {
                    <span class="text-text-secondary">{{ 'admin.system.never' | transloco }}</span>
                  }
                </td>
                <td class="num" [attr.data-label]="'admin.system.duration' | transloco">{{ duration(j.lastDurationMs) }}</td>
                <td class="num" [attr.data-label]="'admin.system.runs24h' | transloco">{{ j.runs24h }}</td>
                <td class="num" [attr.data-label]="'admin.system.failures24h' | transloco" [class.text-error]="j.failures24h > 0">{{ j.failures24h }}</td>
              </tr>
            }
          </tbody>
        </table>
      </section>

      <section [class]="card + ' flex flex-wrap items-center gap-3 p-4'" aria-labelledby="system-counters">
        <div class="min-w-0 flex-1">
          <h2 id="system-counters" class="m-0 text-base font-semibold">{{ 'admin.system.counters' | transloco }}</h2>
          <p class="m-0 text-sm text-text-secondary">{{ 'admin.system.countersHint' | transloco }}</p>
        </div>
        <button type="button" class="rd-btn rd-btn-outline min-h-11 px-4" (click)="rebuilding.set(true)" data-rebuild-counters>{{ 'admin.system.rebuild' | transloco }}</button>
      </section>
    } @else if (failed()) {
      <div [class]="card"><rd-error-state [message]="'admin.loadError' | transloco" (retry)="load()" /></div>
    } @else {
      <div [class]="card + ' flex flex-col gap-3 p-4'" aria-busy="true" data-system-loading>
        <div class="rd-skeleton h-24 w-full" aria-hidden="true"></div>
        <div class="rd-skeleton h-40 w-full" aria-hidden="true"></div>
      </div>
    }

    <rd-admin-confirm
      [open]="rebuilding()"
      [title]="'admin.system.rebuildTitle' | transloco"
      [body]="'admin.system.rebuildBody' | transloco"
      [busy]="busy()"
      [error]="error()"
      (confirmed)="rebuild()"
      (closed)="rebuilding.set(false); error.set(null)"
    />
  `,
})
export class AdminSystemPage {
  private readonly api = inject(AdminApi);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  protected readonly card = ADMIN_CARD;
  protected readonly platforms = ['ios', 'android'] as const;
  protected readonly data = signal<AdminSystemDto | null>(null);
  protected readonly loading = signal(false);
  protected readonly failed = signal(false);
  protected readonly rebuilding = signal(false);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly duration = formatDuration;

  constructor() {
    void this.load();
  }

  async load(): Promise<void> {
    this.loading.set(true);
    this.failed.set(false);
    try {
      this.data.set(await firstValueFrom(this.api.system()));
    } catch (error) {
      if (this.data()) this.toasts.error(this.errors.forError(error));
      else this.failed.set(true);
    } finally {
      this.loading.set(false);
    }
  }

  protected size(bytes: number): string {
    return formatFileSize(this.transloco, bytes, this.lang());
  }

  protected async rebuild(): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      await firstValueFrom(this.api.rebuildCounters());
      this.toasts.success(this.transloco.translate('admin.system.rebuilt'));
      this.busy.set(false);
      this.rebuilding.set(false);
    } catch (error) {
      this.error.set(this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }
}
