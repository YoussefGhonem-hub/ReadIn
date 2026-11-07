import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { AuditEntryDto } from '../../../core/api/models';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { LocalizedDatePipe, RelativeTimePipe } from '../../../shared/pipes/format.pipes';
import { Avatar } from '../../../shared/ui/avatar';

/**
 * The label of an audit code: the console's own (`admin.audit.actions.{code}`), a moderation log entry's
 * (`moderation.log.action.{code}`), or the code itself when neither knows it (contract: "an unknown code shows as it is").
 */
export function auditActionLabel(transloco: TranslocoService, entry: Pick<AuditEntryDto, 'source' | 'action'>): string {
  const key = entry.source === 'moderation' ? `moderation.log.action.${entry.action}` : `admin.audit.actions.${entry.action}`;
  const text = transloco.translate(key);
  return text && text !== key ? text : entry.action;
}

/** Where an audit target opens in the console (or the app), or null. */
export function auditTargetLink(target: AuditEntryDto['target']): string | null {
  if (!target) return null;
  switch (target.type) {
    case 'user':
      return `/admin/users/${target.id}`;
    case 'article':
      return `/admin/content/${target.id}`;
    case 'ticket':
      return `/admin/tickets/${target.id}`;
    default:
      return null;
  }
}

/**
 * One audit entry (F23): who, what (labelled), about whom and which target, the details (`dir="auto"`), the IP (only
 * with `users.read.pii`) and when. Used by the audit log and a user's page.
 */
@Component({
  selector: 'rd-audit-entry',
  imports: [RouterLink, TranslocoPipe, BdiText, Avatar, LocalizedDatePipe, RelativeTimePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex gap-3 py-3 text-sm', '[attr.data-audit-entry]': 'entry().id', '[attr.data-audit-action]': 'entry().action' },
  template: `
    @let e = entry();
    <rd-avatar class="shrink-0" [name]="e.actor?.displayName ?? '?'" [src]="e.actor?.avatarUrl ?? null" [generic]="!e.actor" [size]="32" />
    <div class="min-w-0 flex-1">
      <p class="m-0">
        @if (e.actor; as actor) {
          <a [routerLink]="['/admin/users', actor.id]" class="font-semibold text-text-primary no-underline hover:underline"><rd-bdi-text [text]="actor.displayName" /></a>
        } @else {
          <span class="font-semibold text-text-secondary">{{ 'admin.audit.system' | transloco }}</span>
        }
        · <span data-audit-label>{{ label() }}</span>
        @if (e.source === 'moderation') {
          <span class="rd-tag rd-tag-neutral ms-1">{{ 'admin.audit.sources.moderation' | transloco }}</span>
        }
      </p>
      @if (e.targetUser || e.target) {
        <p class="m-0 mt-0.5 truncate text-text-secondary">
          @if (e.targetUser; as u) {
            <a [routerLink]="['/admin/users', u.id]" class="text-link no-underline hover:underline"><bdi dir="ltr">&#64;{{ u.username }}</bdi></a>
          }
          @if (e.target; as t) {
            @if (e.targetUser) {
              ·
            }
            {{ 'admin.audit.targets.' + t.type | transloco }}
            @if (t.label) {
              @if (targetLink(); as href) {
                <a [routerLink]="href" class="text-link no-underline hover:underline"><rd-bdi-text [text]="t.label" /></a>
              } @else {
                <rd-bdi-text [text]="t.label" />
              }
            }
          }
        </p>
      }
      @if (e.details) {
        <p class="m-0 mt-1 whitespace-pre-line rounded-md bg-surface-variant px-2 py-1 [overflow-wrap:anywhere]" dir="auto" data-audit-details>{{ e.details }}</p>
      }
      <p class="m-0 mt-1 text-xs text-text-secondary">
        <time [attr.datetime]="e.createdAt" [title]="e.createdAt | rdDate: lang() : 'long'">{{ e.createdAt | rdRelativeTime: lang() }}</time>
        @if (e.ip) {
          · <bdi dir="ltr" data-audit-ip>{{ e.ip }}</bdi>
        }
      </p>
    </div>
  `,
})
export class AuditEntry {
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  readonly entry = input.required<AuditEntryDto>();

  protected readonly label = computed(() => {
    this.lang();
    return auditActionLabel(this.transloco, this.entry());
  });
  protected readonly targetLink = computed(() => auditTargetLink(this.entry().target));
}
