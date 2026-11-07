import { ChangeDetectionStrategy, Component, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { AdminUserReportDto, SignInMethod } from '../../../core/api/models';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { LocalizedDatePipe, RelativeTimePipe } from '../../../shared/pipes/format.pipes';

/** "Phone · Google" and the masked number ("+20***1234", always LTR). */
@Component({
  selector: 'rd-sign-in-methods',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'inline-flex flex-col', '[attr.data-sign-in]': 'methods().join(",")' },
  template: `
    <span>
      @for (m of methods(); track m; let last = $last) {
        {{ 'admin.signIn.' + m | transloco }}{{ last ? '' : ' · ' }}
      } @empty {
        <span class="text-text-secondary">—</span>
      }
    </span>
    @if (phone()) {
      <bdi dir="ltr" class="text-xs text-text-secondary tabular-nums" data-phone-masked>{{ phone() }}</bdi>
    }
  `,
})
export class SignInMethods {
  readonly methods = input.required<SignInMethod[]>();
  readonly phone = input<string | null>(null);
}

/**
 * A report in a user's page or a ticket's (F23): what it is about (linking to its F22 case), the reason, its status,
 * the reporter (reports against them) and when.
 */
@Component({
  selector: 'rd-admin-report-row',
  imports: [RouterLink, TranslocoPipe, BdiText, RelativeTimePipe, LocalizedDatePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block py-2.5 text-sm', '[attr.data-report-row]': 'report().id' },
  template: `
    @let r = report();
    <p class="m-0 flex flex-wrap items-center gap-1.5">
      <span class="rd-tag rd-tag-neutral">{{ 'moderation.type.' + r.targetType | transloco }}</span>
      <a [routerLink]="['/admin/reports', r.targetType, r.targetId]" class="min-w-0 truncate text-link no-underline hover:underline" data-report-case>
        @if (r.targetLabel) {
          <rd-bdi-text [text]="r.targetLabel" />
        } @else {
          {{ 'admin.users.deletedTarget' | transloco }}
        }
      </a>
    </p>
    <p class="m-0 mt-1 flex flex-wrap items-center gap-1.5 text-xs text-text-secondary">
      <span class="rd-tag rd-tag-neutral">{{ 'report.reasons.' + r.reason | transloco }}</span>
      <span>{{ 'moderation.case.status.' + r.status | transloco }}</span>
      @if (r.reporter; as by) {
        · <rd-bdi-text [text]="by.displayName" />
      }
      · <time [attr.datetime]="r.createdAt" [title]="r.createdAt | rdDate: lang() : 'long'">{{ r.createdAt | rdRelativeTime: lang() }}</time>
    </p>
    @if (r.details) {
      <p class="m-0 mt-1 whitespace-pre-line text-text-secondary [overflow-wrap:anywhere]" dir="auto">{{ r.details }}</p>
    }
  `,
})
export class AdminReportRow {
  protected readonly lang = inject(LanguageService).lang;
  readonly report = input.required<AdminUserReportDto>();
}

/** Active, or "Suspended until 12 Nov 2026" / "Suspended permanently". */
@Component({
  selector: 'rd-user-status',
  imports: [TranslocoPipe, LocalizedDatePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'inline-flex', '[attr.data-user-status]': 'status()' },
  template: `
    @if (status() === 'suspended') {
      <span class="rd-tag bg-callout-danger text-text-primary">
        @if (until(); as date) {
          {{ 'admin.users.suspendedUntil' | transloco: { date: (date | rdDate: lang()) } }}
        } @else {
          {{ 'admin.users.suspendedPermanently' | transloco }}
        }
      </span>
    } @else {
      <span class="rd-tag rd-tag-neutral">{{ 'admin.users.statuses.active' | transloco }}</span>
    }
  `,
})
export class UserStatus {
  protected readonly lang = inject(LanguageService).lang;
  readonly status = input.required<'active' | 'suspended'>();
  readonly until = input<string | null>(null);
}
