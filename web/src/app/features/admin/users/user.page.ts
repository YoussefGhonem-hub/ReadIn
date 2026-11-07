import { ChangeDetectionStrategy, Component, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminSummaryStore } from '../../../core/admin/admin-summary.store';
import { AdminApi } from '../../../core/api/admin.api';
import { isApiError } from '../../../core/api/api.config';
import { AdminUserDto } from '../../../core/api/models';
import { VerificationApi } from '../../../core/api/verification.api';
import { SessionStore } from '../../../core/auth/session.store';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { isolate } from '../../../shared/directives/bidi';
import { ModerationActionDraft, ModerationActionSheet } from '../../../shared/moderation/moderation-action-sheet';
import { LocalizedDatePipe, RelativeTimePipe } from '../../../shared/pipes/format.pipes';
import { Avatar } from '../../../shared/ui/avatar';
import { BottomSheet } from '../../../shared/ui/bottom-sheet';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { VerifiedBadge } from '../../../shared/ui/verified-badge';
import { ModerationLogEntry } from '../../moderation/moderation-ui';
import { LinkIcon } from '../../profile/link-icon';
import { profileLinks } from '../../profile/profile-links';
import { ADMIN_CARD, AdminConfirm } from '../admin-ui';
import { AuditEntry } from '../audit/audit-entry';
import { AdminReportRow, SignInMethods, UserStatus } from './user-bits';
import { provideAdminIcons } from '../admin-icons';

type State = { status: 'loading' } | { status: 'loaded'; data: AdminUserDto } | { status: 'error'; notFound: boolean };
/** The actions confirmed with a plain dialog (the moderation ones use the moderation sheet). */
type ConfirmKind = 'resetPassword' | 'logoutAll' | 'removeBadge';

export interface UserAction {
  id: string;
  labelKey: string;
  icon: string;
  danger?: boolean;
  run: () => void;
}

/**
 * A user's page in the console (F23), `/admin/users/{id}`: the profile and stats, sign-in methods and active sessions,
 * the masked phone number with "Show" (`users.read.pii`, audited), and the sections this session may see (moderation
 * history and reports, verification requests, tickets, audit entries; newest 20 each). The actions are the ones
 * `actions` allows: suspend (1/3/7/30 days, custom, permanent; optionally hiding all their content) or unsuspend, warn,
 * hide or restore all their content, reset the password (the temporary password is shown once), sign out of all
 * devices, remove the Verified badge, clear the title or links. Each is confirmed, audited by its endpoint, and the page
 * loads again after it.
 */
@Component({
  selector: 'rd-admin-user-page',
  imports: [
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    BdiText,
    Avatar,
    VerifiedBadge,
    LocalizedDatePipe,
    RelativeTimePipe,
    EmptyState,
    ErrorState,
    BottomSheet,
    ModerationActionSheet,
    ModerationLogEntry,
    LinkIcon,
    AdminConfirm,
    AuditEntry,
    AdminReportRow,
    SignInMethods,
    UserStatus,
  ],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-admin-user': '' },
  styles: `
    .facts {
      display: grid;
      grid-template-columns: minmax(0, auto) minmax(0, 1fr);
      gap: 0.375rem 1rem;
    }
    .stats {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(8rem, 1fr));
      gap: 0.5rem;
    }
  `,
  template: `
    <a routerLink="/admin/users" class="mb-2 inline-flex min-h-11 items-center gap-1.5 text-sm text-text-secondary no-underline hover:text-text-primary" data-user-back>
      <svg lucideIcon="ArrowLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
      {{ 'admin.users.back' | transloco }}
    </a>

    @switch (state().status) {
      @case ('loaded') {
        @let u = data()!;
        <div class="flex flex-col gap-2">
          <!-- Who -->
          <section [class]="card + ' p-4 lg:p-5'" data-user-profile>
            <div class="flex flex-wrap items-start gap-4">
              <rd-avatar [name]="u.displayName" [src]="u.avatarUrl" [size]="64" />
              <div class="min-w-0 flex-1">
                <h1 class="m-0 flex flex-wrap items-center gap-1.5 text-xl font-bold lg:text-2xl">
                  <rd-bdi-text [text]="u.displayName" />
                  @if (u.isVerified) {
                    <rd-verified-badge [size]="18" />
                  }
                </h1>
                <a [routerLink]="'/@' + u.username" class="text-sm text-link no-underline hover:underline" data-user-public><bdi dir="ltr">&#64;{{ u.username }}</bdi></a>
                <div class="mt-2 flex flex-wrap gap-1.5">
                  <rd-user-status [status]="u.status" [until]="u.suspendedUntil" />
                  @for (role of u.roles; track role) {
                    <span class="rd-tag rd-tag-neutral" dir="ltr">{{ role }}</span>
                  }
                  @if (u.isSystemAccount) {
                    <span class="rd-tag rd-tag-neutral">{{ 'admin.users.system' | transloco }}</span>
                  }
                </div>
              </div>
            </div>
            @if (u.headline) {
              <p class="m-0 mt-3 font-semibold [overflow-wrap:anywhere]" dir="auto" data-user-headline>{{ u.headline }}</p>
            }
            @if (u.bio) {
              <p class="m-0 mt-1 whitespace-pre-line text-sm text-text-secondary [overflow-wrap:anywhere]" dir="auto">{{ u.bio }}</p>
            }
            @if (links().length) {
              <ul class="m-0 mt-2 flex list-none flex-col p-0" data-user-links>
                @for (link of links(); track $index) {
                  <li class="flex min-h-9 items-center gap-2 text-sm">
                    <rd-link-icon class="text-text-secondary" [platform]="link.platform" [size]="16" />
                    <a [href]="link.url" target="_blank" rel="nofollow ugc noopener noreferrer" class="min-w-0 text-link [overflow-wrap:anywhere]" dir="ltr">{{ link.url }}</a>
                  </li>
                }
              </ul>
            }

            <dl class="facts m-0 mt-4 text-sm" data-user-facts>
              <dt class="text-text-secondary">{{ 'admin.users.columns.joined' | transloco }}</dt>
              <dd class="m-0"><time [attr.datetime]="u.joinedAt">{{ u.joinedAt | rdDate: lang() : 'long' }}</time></dd>
              <dt class="text-text-secondary">{{ 'admin.users.columns.lastSeen' | transloco }}</dt>
              <dd class="m-0">
                @if (u.lastSeenAt; as seen) {
                  <time [attr.datetime]="seen" [title]="seen | rdDate: lang() : 'long'">{{ seen | rdRelativeTime: lang() }}</time>
                } @else {
                  {{ 'admin.users.neverSeen' | transloco }}
                }
              </dd>
              <dt class="text-text-secondary">{{ 'admin.users.signUpMethod' | transloco }}</dt>
              <dd class="m-0">{{ u.signUpMethod ? ('admin.signIn.' + u.signUpMethod | transloco) : '—' }}</dd>
              <dt class="text-text-secondary">{{ 'admin.users.columns.signIn' | transloco }}</dt>
              <dd class="m-0"><rd-sign-in-methods [methods]="u.signInMethods" /></dd>
              <dt class="text-text-secondary">{{ 'admin.users.phone' | transloco }}</dt>
              <dd class="m-0 flex flex-wrap items-center gap-2" data-user-phone>
                @if (phone(); as full) {
                  <bdi dir="ltr" class="font-semibold tabular-nums" data-phone-full>{{ full }}</bdi>
                } @else if (u.phoneMasked) {
                  <bdi dir="ltr" class="tabular-nums">{{ u.phoneMasked }}</bdi>
                  @if (u.actions.canRevealPhone) {
                    <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-sm" [disabled]="revealing()" (click)="revealPhone()" data-phone-reveal>
                      <svg lucideIcon="Eye" [size]="16" aria-hidden="true"></svg>
                      {{ 'admin.users.showPhone' | transloco }}
                    </button>
                  }
                } @else {
                  —
                }
              </dd>
              <dt class="text-text-secondary">{{ 'admin.users.uiLanguage' | transloco }}</dt>
              <dd class="m-0">{{ u.uiLanguage === 'ar' ? 'العربية' : 'English' }}</dd>
            </dl>
          </section>

          <!-- Actions -->
          <section [class]="card + ' p-4 lg:p-5'" aria-labelledby="user-actions">
            <h2 id="user-actions" class="m-0 mb-3 text-base font-semibold">{{ 'admin.users.actions' | transloco }}</h2>
            @if (actions().length) {
              <div class="flex flex-wrap gap-2" data-user-actions>
                @for (a of actions(); track a.id) {
                  <button type="button" class="rd-btn rd-btn-outline min-h-11 gap-1.5 px-4 text-sm" [class]="a.danger ? 'border-error text-error' : ''" [attr.data-user-action]="a.id" (click)="a.run()">
                    <svg [lucideIcon]="a.icon" [size]="16" aria-hidden="true"></svg>
                    {{ a.labelKey | transloco }}
                  </button>
                }
              </div>
            } @else {
              <p class="m-0 text-sm text-text-secondary" data-user-no-actions>{{ (u.isStaff ? 'admin.users.protected' : 'admin.users.noActions') | transloco }}</p>
            }
            <div class="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-sm">
              @if (session.hasPermission('moderation.manage')) {
                <a routerLink="/admin/content" [queryParams]="{ writer: u.id }" class="text-link no-underline hover:underline" data-user-articles>{{ 'admin.users.theirArticles' | transloco }}</a>
              }
              @if (session.hasPermission('audit.read')) {
                <a routerLink="/admin/audit" [queryParams]="{ target: u.id }" class="text-link no-underline hover:underline">{{ 'admin.users.auditAbout' | transloco }}</a>
                <a routerLink="/admin/audit" [queryParams]="{ actor: u.id }" class="text-link no-underline hover:underline">{{ 'admin.users.auditBy' | transloco }}</a>
              }
            </div>
          </section>

          <!-- Stats and access -->
          <section [class]="card + ' p-4 lg:p-5'" aria-labelledby="user-stats">
            <h2 id="user-stats" class="m-0 mb-3 text-base font-semibold">{{ 'admin.users.stats' | transloco }}</h2>
            <div class="stats" data-user-stats>
              @for (s of stats(); track s.key) {
                <div class="rounded-md bg-surface-variant p-3">
                  <span class="block text-lg font-bold tabular-nums">{{ s.value }}</span>
                  <span class="block text-xs text-text-secondary">{{ 'admin.users.statLabels.' + s.key | transloco }}</span>
                </div>
              }
            </div>
            <h3 class="m-0 mb-2 mt-4 text-sm font-semibold">{{ 'admin.users.access' | transloco }}</h3>
            <dl class="facts m-0 text-sm" data-user-access>
              <dt class="text-text-secondary">{{ 'admin.users.sessions' | transloco }}</dt>
              <dd class="m-0 tabular-nums">{{ u.access.activeSessions }}</dd>
              <dt class="text-text-secondary">{{ 'admin.users.recoveryPin' | transloco }}</dt>
              <dd class="m-0">
                {{ (u.access.hasRecoveryPin ? 'admin.yes' : 'admin.no') | transloco }}
                @if (u.access.recoveryDisabled) {
                  · {{ 'admin.users.recoveryDisabled' | transloco }}
                }
              </dd>
              @if (u.access.mustChangePassword || u.access.mustSetRecoveryPin) {
                <dt class="text-text-secondary">{{ 'admin.users.pending' | transloco }}</dt>
                <dd class="m-0">
                  @if (u.access.mustChangePassword) {
                    {{ 'admin.users.mustChangePassword' | transloco }}
                  }
                  @if (u.access.mustSetRecoveryPin) {
                    {{ 'admin.users.mustSetPin' | transloco }}
                  }
                </dd>
              }
              @if (u.access.lockedOutUntil; as until) {
                <dt class="text-text-secondary">{{ 'admin.users.lockedOut' | transloco }}</dt>
                <dd class="m-0">{{ until | rdDate: lang() : 'long' }}</dd>
              }
            </dl>
          </section>

          <!-- Moderation history (moderation.manage) -->
          @if (u.moderation; as m) {
            <section [class]="card" aria-labelledby="user-moderation" data-user-moderation>
              <div class="px-4 pt-4 lg:px-5">
                <h2 id="user-moderation" class="m-0 text-base font-semibold">{{ 'admin.users.moderation' | transloco }}</h2>
                <p class="m-0 mt-1 text-sm text-text-secondary">
                  {{ 'admin.users.moderationCounts' | transloco: { warnings: m.warnings, suspensions: m.suspensions, articles: m.hiddenArticles, comments: m.hiddenComments } }}
                  @if (m.hiddenWithAccount > 0) {
                    · {{ 'admin.users.hiddenWithAccount' | transloco: { count: m.hiddenWithAccount } }}
                  }
                </p>
              </div>
              @if (m.history.length) {
                <ol class="m-0 list-none divide-y divide-border p-0">
                  @for (entry of m.history; track entry.id) {
                    <li class="px-4 lg:px-5"><rd-moderation-log-entry [entry]="entry" /></li>
                  }
                </ol>
                @if (m.historyTotal > m.history.length) {
                  <p class="m-0 px-4 pb-3 text-xs text-text-secondary lg:px-5">{{ 'admin.users.newest' | transloco: { shown: m.history.length, total: m.historyTotal } }}</p>
                }
              } @else {
                <p class="m-0 px-4 pb-4 pt-2 text-sm text-text-secondary lg:px-5">{{ 'admin.users.noHistory' | transloco }}</p>
              }
            </section>
          }

          <!-- Reports against them and filed by them (moderation.manage) -->
          @if (u.reports; as r) {
            <section [class]="card + ' p-4 lg:p-5'" aria-labelledby="user-reports" data-user-reports>
              <h2 id="user-reports" class="m-0 text-base font-semibold">{{ 'admin.users.reportsAgainst' | transloco }} ({{ r.againstTotal }})</h2>
              @if (r.against.length) {
                <ul class="m-0 list-none divide-y divide-border p-0" data-reports-against>
                  @for (report of r.against; track report.id) {
                    <li><rd-admin-report-row [report]="report" /></li>
                  }
                </ul>
              } @else {
                <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'admin.users.none' | transloco }}</p>
              }
              <h2 class="m-0 mt-4 text-base font-semibold">{{ 'admin.users.reportsFiled' | transloco }} ({{ r.filedTotal }})</h2>
              @if (r.filed.length) {
                <ul class="m-0 list-none divide-y divide-border p-0" data-reports-filed>
                  @for (report of r.filed; track report.id) {
                    <li><rd-admin-report-row [report]="report" /></li>
                  }
                </ul>
              } @else {
                <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'admin.users.none' | transloco }}</p>
              }
            </section>
          }

          <!-- Verification requests (verification.manage) -->
          @if (u.verification; as v) {
            <section [class]="card + ' p-4 lg:p-5'" aria-labelledby="user-verification" data-user-verification>
              <h2 id="user-verification" class="m-0 text-base font-semibold">{{ 'admin.users.verification' | transloco }} ({{ v.total }})</h2>
              @if (v.items.length) {
                <ul class="m-0 list-none divide-y divide-border p-0">
                  @for (request of v.items; track request.id) {
                    <li class="py-2.5 text-sm">
                      <a routerLink="/admin/verification" [queryParams]="{ status: request.status === 'pending' ? null : request.status, id: request.id }" class="font-semibold text-link no-underline hover:underline">
                        <bdi dir="auto">{{ request.jobTitle }}</bdi>
                      </a>
                      <span class="block text-xs text-text-secondary">
                        {{ request.field.name }} · {{ 'verification.admin.tabs.' + request.status | transloco }} ·
                        <time [attr.datetime]="request.submittedAt">{{ request.submittedAt | rdDate: lang() }}</time>
                      </span>
                    </li>
                  }
                </ul>
              } @else {
                <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'admin.users.none' | transloco }}</p>
              }
            </section>
          }

          <!-- Tickets (support.manage) -->
          @if (u.tickets; as t) {
            <section [class]="card + ' p-4 lg:p-5'" aria-labelledby="user-tickets" data-user-tickets>
              <h2 id="user-tickets" class="m-0 text-base font-semibold">{{ 'admin.users.tickets' | transloco }} ({{ t.total }})</h2>
              @if (t.items.length) {
                <ul class="m-0 list-none divide-y divide-border p-0">
                  @for (ticket of t.items; track ticket.id) {
                    <li class="py-2.5 text-sm">
                      <a [routerLink]="['/admin/tickets', ticket.id]" class="font-semibold text-link no-underline hover:underline">
                        <bdi dir="ltr">#{{ ticket.number }}</bdi> · <bdi dir="auto">{{ ticket.subject }}</bdi>
                      </a>
                      <span class="block text-xs text-text-secondary">
                        {{ 'support.statuses.' + ticket.status | transloco }} · {{ 'support.categories.' + ticket.category | transloco }} ·
                        <time [attr.datetime]="ticket.createdAt">{{ ticket.createdAt | rdDate: lang() }}</time>
                      </span>
                    </li>
                  }
                </ul>
              } @else {
                <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'admin.users.none' | transloco }}</p>
              }
            </section>
          }

          <!-- Audit entries about them (audit.read) -->
          @if (u.audit; as a) {
            <section [class]="card" aria-labelledby="user-audit" data-user-audit>
              <h2 id="user-audit" class="m-0 px-4 pt-4 text-base font-semibold lg:px-5">{{ 'admin.users.audit' | transloco }} ({{ a.total }})</h2>
              @if (a.items.length) {
                <ol class="m-0 list-none divide-y divide-border p-0">
                  @for (entry of a.items; track entry.id) {
                    <li class="px-4 lg:px-5"><rd-audit-entry [entry]="entry" /></li>
                  }
                </ol>
              } @else {
                <p class="m-0 px-4 pb-4 pt-1 text-sm text-text-secondary lg:px-5">{{ 'admin.users.none' | transloco }}</p>
              }
            </section>
          }
        </div>
      }
      @case ('error') {
        <div [class]="card">
          @if (notFound()) {
            <rd-empty-state [title]="'admin.users.notFound' | transloco" data-user-not-found>
              <a routerLink="/admin/users" class="rd-btn rd-btn-primary mt-3">{{ 'admin.users.back' | transloco }}</a>
            </rd-empty-state>
          } @else {
            <rd-error-state [message]="'admin.loadError' | transloco" (retry)="load()" />
          }
        </div>
      }
      @default {
        <div [class]="card + ' flex flex-col gap-3 p-5'" aria-busy="true" data-user-loading>
          <div class="flex items-center gap-4" aria-hidden="true">
            <div class="rd-skeleton h-16 w-16 rounded-full"></div>
            <div class="flex flex-1 flex-col gap-2"><div class="rd-skeleton h-6 w-1/2"></div><div class="rd-skeleton h-4 w-1/3"></div></div>
          </div>
          <div class="rd-skeleton h-24 w-full"></div>
        </div>
      }
    }

    <rd-moderation-action-sheet [draft]="draft()" (done)="afterAction()" (closed)="draft.set(null)" />

    <rd-admin-confirm
      [open]="!!confirming()"
      [title]="confirmTitle()"
      [body]="confirmBody()"
      [danger]="confirming() !== 'resetPassword'"
      [busy]="busy()"
      [error]="confirmError()"
      (confirmed)="runConfirmed()"
      (closed)="closeConfirm()"
    />

    <!-- The temporary password, shown once -->
    <rd-bottom-sheet [open]="!!temporaryPassword()" labelledBy="temp-password-title" describedBy="temp-password-body" (closed)="temporaryPassword.set(null)">
      @if (temporaryPassword(); as password) {
        <div class="flex flex-col gap-3 pt-1" data-temp-password>
          <h2 id="temp-password-title" class="m-0 pe-10 text-xl font-semibold">{{ 'admin.users.tempPasswordTitle' | transloco }}</h2>
          <p id="temp-password-body" class="m-0 text-sm text-text-secondary">{{ 'admin.users.tempPasswordBody' | transloco }}</p>
          <p class="m-0 select-all rounded-md bg-surface-variant p-3 text-center font-mono text-lg tracking-wider" dir="ltr" data-temp-password-value>{{ password }}</p>
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" (click)="copy(password)" data-temp-password-copy>
              <svg lucideIcon="Copy" [size]="16" aria-hidden="true"></svg>
              {{ 'admin.copy' | transloco }}
            </button>
            <button type="button" class="rd-btn rd-btn-primary flex-1" (click)="temporaryPassword.set(null)">{{ 'common.close' | transloco }}</button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class AdminUserPage {
  private readonly api = inject(AdminApi);
  private readonly verification = inject(VerificationApi);
  private readonly summary = inject(AdminSummaryStore);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly title = inject(Title);
  protected readonly session = inject(SessionStore);
  protected readonly lang = inject(LanguageService).lang;

  /** Route param (component input binding). */
  readonly id = input.required<string>();

  protected readonly card = ADMIN_CARD;
  protected readonly state = signal<State>({ status: 'loading' });
  protected readonly data = computed(() => {
    const s = this.state();
    return s.status === 'loaded' ? s.data : null;
  });
  protected readonly notFound = computed(() => {
    const s = this.state();
    return s.status === 'error' && s.notFound;
  });
  protected readonly links = computed(() => profileLinks(this.data()?.links ?? []));
  protected readonly phone = signal<string | null>(null);
  protected readonly revealing = signal(false);
  protected readonly draft = signal<ModerationActionDraft | null>(null);
  protected readonly confirming = signal<ConfirmKind | null>(null);
  protected readonly busy = signal(false);
  protected readonly confirmError = signal<string | null>(null);
  protected readonly temporaryPassword = signal<string | null>(null);

  protected readonly stats = computed(() => {
    const u = this.data();
    if (!u) return [];
    const s = u.stats;
    return [
      { key: 'articles', value: u.publishedArticles },
      { key: 'drafts', value: s.drafts },
      { key: 'comments', value: s.comments },
      { key: 'followers', value: u.followers },
      { key: 'following', value: s.following },
      { key: 'totalReads', value: s.totalReads },
      { key: 'articlesRead', value: s.articlesRead },
      { key: 'currentStreak', value: s.currentStreak },
      { key: 'longestStreak', value: s.longestStreak },
    ];
  });

  /** What this session may do to the account now (`actions`), in the order of the contract's table. */
  protected readonly actions = computed<UserAction[]>(() => {
    const u = this.data();
    if (!u) return [];
    const a = u.actions;
    const target = { targetType: 'user' as const, targetId: u.id, name: u.displayName };
    const sheet = (action: ModerationActionDraft['action']) => () => this.draft.set({ action, ...target });
    const confirm = (kind: ConfirmKind) => () => this.openConfirm(kind);
    const list: UserAction[] = [];
    if (a.canSuspend && u.status === 'active') list.push({ id: 'suspend', labelKey: 'moderation.actions.suspend', icon: 'Ban', danger: true, run: sheet('suspend') });
    if (a.canSuspend && u.status === 'suspended') list.push({ id: 'unsuspend', labelKey: 'moderation.actions.unsuspend', icon: 'UserRoundCheck', run: sheet('unsuspend') });
    if (a.canWarn) list.push({ id: 'warn', labelKey: 'moderation.actions.warn', icon: 'TriangleAlert', run: sheet('warn') });
    if (a.canWarn) list.push({ id: 'hideContent', labelKey: 'moderation.actions.hideContent', icon: 'EyeOff', danger: true, run: sheet('hide_content') });
    if (a.canRestoreContent) list.push({ id: 'restoreContent', labelKey: 'moderation.actions.unhideContent', icon: 'Eye', run: sheet('unhide_content') });
    if (a.canResetPassword) list.push({ id: 'resetPassword', labelKey: 'admin.users.resetPassword', icon: 'KeyRound', run: confirm('resetPassword') });
    if (a.canLogoutAll) list.push({ id: 'logoutAll', labelKey: 'admin.users.logoutAll', icon: 'LogOut', danger: true, run: confirm('logoutAll') });
    if (a.canRemoveBadge) list.push({ id: 'removeBadge', labelKey: 'verification.admin.removeBadge', icon: 'BadgeCheck', danger: true, run: confirm('removeBadge') });
    if (a.canClearProfile && u.headline) list.push({ id: 'clearHeadline', labelKey: 'moderation.actions.clearHeadline', icon: 'Eraser', danger: true, run: sheet('clear_headline') });
    if (a.canClearProfile && u.links.length) list.push({ id: 'clearLinks', labelKey: 'moderation.actions.clearLinks', icon: 'Eraser', danger: true, run: sheet('clear_links') });
    return list;
  });

  protected readonly confirmTitle = computed(() => {
    const kind = this.confirming();
    return kind ? this.transloco.translate(`admin.users.confirm.${kind}.title`, { name: isolate(this.data()?.displayName ?? '') }) : '';
  });
  protected readonly confirmBody = computed(() => {
    const kind = this.confirming();
    return kind ? this.transloco.translate(`admin.users.confirm.${kind}.body`) : '';
  });

  constructor() {
    effect(() => {
      this.id();
      untracked(() => {
        this.phone.set(null);
        this.state.set({ status: 'loading' });
        void this.load();
      });
    });
    effect(() => {
      const u = this.data();
      this.title.setTitle(`${u ? u.displayName : this.transloco.translate('admin.nav.users')} — ReadIn`);
    });
  }

  async load(): Promise<void> {
    const id = this.id();
    if (this.state().status === 'error') this.state.set({ status: 'loading' });
    try {
      const data = await firstValueFrom(this.api.user(id));
      if (id === this.id()) this.state.set({ status: 'loaded', data });
    } catch (error) {
      if (id === this.id()) this.state.set({ status: 'error', notFound: isApiError(error) && error.status === 404 });
    }
  }

  protected afterAction(): void {
    void this.load();
    void this.summary.refresh();
  }

  protected async revealPhone(): Promise<void> {
    const u = this.data();
    if (!u || this.revealing()) return;
    this.revealing.set(true);
    try {
      const { phoneNumber } = await firstValueFrom(this.api.phone(u.id));
      this.phone.set(phoneNumber ?? null);
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
    } finally {
      this.revealing.set(false);
    }
  }

  protected openConfirm(kind: ConfirmKind): void {
    this.confirmError.set(null);
    this.confirming.set(kind);
  }

  protected closeConfirm(): void {
    if (!this.busy()) this.confirming.set(null);
  }

  protected async runConfirmed(): Promise<void> {
    const kind = this.confirming();
    const u = this.data();
    if (!kind || !u || this.busy()) return;
    this.busy.set(true);
    this.confirmError.set(null);
    try {
      if (kind === 'resetPassword') {
        const { temporaryPassword } = await firstValueFrom(this.api.resetPassword(u.id));
        this.temporaryPassword.set(temporaryPassword);
      } else if (kind === 'logoutAll') {
        await firstValueFrom(this.api.logoutAll(u.id));
        this.toasts.success(this.transloco.translate('admin.users.done.logoutAll'));
      } else {
        await firstValueFrom(this.verification.removeBadge(u.id));
        this.toasts.success(this.transloco.translate('verification.admin.badgeRemoved', { name: isolate(u.displayName) }));
      }
      this.busy.set(false);
      this.confirming.set(null);
      this.afterAction();
    } catch (error) {
      this.confirmError.set(this.errors.forError(error));
    } finally {
      this.busy.set(false);
    }
  }

  protected async copy(text: string): Promise<void> {
    try {
      await navigator.clipboard.writeText(text);
      this.toasts.success(this.transloco.translate('admin.copied'));
    } catch {
      /* the password stays on screen to copy by hand */
    }
  }
}
