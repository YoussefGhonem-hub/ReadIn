import { ChangeDetectionStrategy, Component, computed, effect, inject, input, linkedSignal, signal, untracked } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../../core/api/api.config';
import { AdminVerificationRequestDto, VERIFICATION_STATUSES, VerificationStatus } from '../../../core/api/models';
import { VerificationApi } from '../../../core/api/verification.api';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { detectDir, isolate } from '../../../shared/directives/bidi';
import { LocalizedDatePipe, RelativeTimePipe, intlLocale } from '../../../shared/pipes/format.pipes';
import { Avatar } from '../../../shared/ui/avatar';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { provideVerificationIcons } from '../../verification/verification-icons';
import { isProofUrl } from '../../verification/verification-rules';
import { AdminVerificationStore, VerificationDecision } from './admin-verification.store';
import { DecisionDraft, DecisionSheet } from './decision-sheet';
import { ProofPreview } from './proof-preview';

const PATH = '/admin/verification';

/** A request opened by id that isn't on the current tab (a deep link): loaded on its own. */
type Detail = { id: string; status: 'loading' } | { id: string; status: 'loaded'; data: AdminVerificationRequestDto } | { id: string; status: 'error'; notFound: boolean };

/**
 * Verification requests (F19), `/admin/verification?status=&id=`, for `verification.manage`: Pending / Approved /
 * Rejected (pending oldest first), one row per request (who, field, job title, when), and the request itself: the job
 * title and note, the proof link (a new tab, no referrer) and the proof file (fetched with the session, never linked to),
 * then Approve or Reject with a reason. A decision leaves the list at once and comes back when the API refuses. Wide
 * screens show the list and the request side by side; narrow ones one at a time. The URL keeps the tab and the request.
 */
@Component({
  selector: 'rd-admin-verification-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, LocalizedDatePipe, RelativeTimePipe, Avatar, EmptyState, ErrorState, DecisionSheet, ProofPreview],
  providers: [AdminVerificationStore, provideVerificationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[1100px] px-4 pb-10 pt-5 lg:pt-8' },
  template: `
    <header class="mb-4">
      <h1 class="m-0 text-2xl font-bold">{{ 'verification.admin.title' | transloco }}</h1>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'verification.admin.subtitle' | transloco }}</p>
    </header>
    <nav class="-mx-4 flex gap-5 overflow-x-auto border-b border-border px-4" [attr.aria-label]="'verification.admin.tabs.label' | transloco" data-verification-tabs>
      @for (tab of tabs; track tab) {
        <a
          [routerLink]="path"
          [queryParams]="{ status: tab === 'pending' ? null : tab }"
          class="-mb-px inline-flex min-h-11 shrink-0 items-center border-b-2 px-1 text-sm no-underline"
          [class]="currentTab() === tab ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary hover:text-text-primary'"
          [attr.aria-current]="currentTab() === tab ? 'page' : null"
          [attr.data-verification-tab]="tab"
        >
          {{ 'verification.admin.tabs.' + tab | transloco }}
        </a>
      }
    </nav>

    <div class="mt-4 lg:grid lg:grid-cols-[minmax(0,360px)_minmax(0,1fr)] lg:items-start lg:gap-6">
      <!-- The list -->
      <section class="lg:block" [class.hidden]="!!selectedId()" [attr.aria-label]="'verification.admin.tabs.' + currentTab() | transloco" aria-live="polite" data-verification-list>
        @switch (store.status()) {
          @case ('error') {
            <rd-error-state [message]="'verification.admin.loadError' | transloco" (retry)="store.load()" />
          }
          @case ('loaded') {
            @if (store.items().length) {
              <ol class="m-0 flex list-none flex-col gap-2 p-0">
                @for (item of store.items(); track item.id) {
                  <li>
                    <a
                      [routerLink]="path"
                      [queryParams]="{ status: statusParam(), id: item.id }"
                      class="rd-card flex items-start gap-3 p-3 text-inherit no-underline shadow-none transition-colors hover:border-primary"
                      [class.border-primary]="selectedId() === item.id"
                      [class.bg-primary-container]="selectedId() === item.id"
                      [attr.aria-current]="selectedId() === item.id ? 'true' : null"
                      [attr.data-verification-row]="item.id"
                    >
                      <rd-avatar [name]="item.user.displayName" [src]="item.user.avatarUrl" [size]="40" />
                      <span class="min-w-0 flex-1">
                        <span class="flex min-w-0 items-center gap-1 text-sm font-semibold">
                          <rd-bdi-text class="truncate" [text]="item.user.displayName" />
                          @if (item.user.isVerified) {
                            <svg lucideIcon="BadgeCheck" [size]="14" class="shrink-0 text-primary" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
                          }
                        </span>
                        <bdi dir="ltr" class="block truncate text-xs text-text-secondary">&#64;{{ item.user.username }}</bdi>
                        <span class="mt-1 block truncate text-sm" [attr.dir]="dirOf(item.jobTitle)" data-row-job-title><rd-bdi-text [text]="item.jobTitle" /></span>
                        <span class="mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-text-secondary">
                          <span class="rd-tag rd-tag-neutral" data-row-field><rd-bdi-text [text]="item.field.name" /></span>
                          <time [attr.datetime]="item.decidedAt ?? item.submittedAt" data-row-time>
                            {{ (item.decidedAt ? 'verification.admin.decided' : 'verification.admin.submitted') | transloco: { time: ((item.decidedAt ?? item.submittedAt) | rdRelativeTime: lang()) } }}
                          </time>
                        </span>
                      </span>
                    </a>
                  </li>
                }
              </ol>
              @if (store.nextCursor()) {
                <button type="button" class="rd-btn rd-btn-outline mt-3 w-full" [disabled]="store.loadingMore()" [attr.aria-busy]="store.loadingMore()" (click)="store.loadMore()" data-verification-more>
                  {{ (store.moreFailed() ? 'common.retry' : 'verification.admin.more') | transloco }}
                </button>
              }
            } @else {
              <rd-empty-state
                [title]="'verification.admin.empty.' + currentTab() + '.title' | transloco"
                [message]="'verification.admin.empty.' + currentTab() + '.body' | transloco"
                data-verification-empty
              />
            }
          }
          @default {
            <div class="flex flex-col gap-2" aria-busy="true" data-verification-list-loading>
              @for (i of skeletons; track i) {
                <div class="rd-card flex gap-3 p-3 shadow-none" aria-hidden="true">
                  <div class="rd-skeleton h-10 w-10 rounded-full"></div>
                  <div class="flex flex-1 flex-col gap-2">
                    <div class="rd-skeleton h-4 w-2/5"></div>
                    <div class="rd-skeleton h-4 w-4/5"></div>
                    <div class="rd-skeleton h-3 w-1/3"></div>
                  </div>
                </div>
              }
            </div>
          }
        }
      </section>

      <!-- The request -->
      <section class="lg:block" [class.hidden]="!selectedId()" [attr.aria-label]="'verification.admin.detail.label' | transloco" data-verification-detail-pane>
        @if (selectedId()) {
          <a [routerLink]="path" [queryParams]="{ status: statusParam() }" class="mb-3 inline-flex min-h-11 items-center gap-1.5 text-sm text-text-secondary no-underline hover:text-text-primary lg:hidden" data-verification-back>
            <svg lucideIcon="ArrowLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
            {{ 'verification.admin.back' | transloco }}
          </a>
          @if (selected(); as r) {
            <article class="rd-card p-5 shadow-none" [attr.data-verification-detail]="r.id" [attr.data-status]="r.status">
              <header class="flex items-start gap-3">
                <rd-avatar [name]="r.user.displayName" [src]="r.user.avatarUrl" [size]="48" />
                <div class="min-w-0 flex-1">
                  <h2 class="m-0 flex items-center gap-1 text-lg font-semibold">
                    <rd-bdi-text class="truncate" [text]="r.user.displayName" />
                    @if (r.user.isVerified) {
                      <svg lucideIcon="BadgeCheck" [size]="18" class="shrink-0 text-primary" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
                    }
                  </h2>
                  <a [routerLink]="'/@' + r.user.username" class="text-sm text-link no-underline hover:underline"><bdi dir="ltr">&#64;{{ r.user.username }}</bdi></a>
                </div>
                <span class="rd-tag shrink-0" [class]="statusTone(r.status)" data-detail-status>{{ 'verification.admin.status.' + r.status | transloco }}</span>
              </header>

              <dl class="m-0 mt-5 grid grid-cols-[auto_minmax(0,1fr)] gap-x-4 gap-y-3 text-sm">
                <dt class="text-text-secondary">{{ 'verification.summary.field' | transloco }}</dt>
                <dd class="m-0 font-semibold" data-detail-field><rd-bdi-text [text]="r.field.name" /></dd>
                <dt class="text-text-secondary">{{ 'verification.summary.jobTitle' | transloco }}</dt>
                <dd class="m-0 [overflow-wrap:anywhere]" data-detail-job-title><rd-bdi-text [text]="r.jobTitle" /></dd>
                <dt class="text-text-secondary">{{ 'verification.admin.detail.submitted' | transloco }}</dt>
                <dd class="m-0"><time [attr.datetime]="r.submittedAt">{{ r.submittedAt | rdDate: lang() : 'long' }}</time></dd>
                @if (r.note) {
                  <dt class="text-text-secondary">{{ 'verification.summary.note' | transloco }}</dt>
                  <dd class="m-0 whitespace-pre-line [overflow-wrap:anywhere]" [attr.dir]="dirOf(r.note)" data-detail-note><rd-bdi-text [text]="r.note" /></dd>
                }
                @if (r.proofUrl) {
                  <dt class="text-text-secondary">{{ 'verification.summary.proofUrl' | transloco }}</dt>
                  <dd class="m-0 min-w-0">
                    @if (safeUrl(r.proofUrl)) {
                      <a [href]="r.proofUrl" target="_blank" rel="noopener noreferrer" class="inline-flex max-w-full items-center gap-1.5 text-link no-underline hover:underline" data-detail-proof-url>
                        <bdi dir="ltr" class="truncate">{{ r.proofUrl }}</bdi>
                        <svg lucideIcon="ExternalLink" [size]="14" class="shrink-0" aria-hidden="true"></svg>
                      </a>
                    } @else {
                      <span class="flex min-w-0"><bdi dir="ltr" class="min-w-0 truncate" data-detail-proof-url>{{ r.proofUrl }}</bdi></span>
                    }
                  </dd>
                }
              </dl>

              <section class="mt-5" aria-labelledby="detail-proof-title">
                <h3 id="detail-proof-title" class="m-0 mb-2 text-sm font-semibold">{{ 'verification.summary.proofFile' | transloco }}</h3>
                @if (r.proof; as proof) {
                  <rd-proof-preview [requestId]="r.id" [proof]="proof" />
                } @else {
                  <p class="m-0 text-sm text-text-secondary" data-detail-no-file>
                    {{ (r.status === 'pending' ? 'verification.admin.detail.noFile' : 'verification.admin.detail.fileDeleted') | transloco }}
                  </p>
                }
              </section>

              @if (r.status === 'pending') {
                <div class="mt-6 flex flex-wrap gap-2 border-t border-border pt-4" data-detail-actions>
                  <button type="button" class="rd-btn rd-btn-primary flex-1 gap-1.5 sm:flex-none" (click)="decision.set({ kind: 'approve', item: r })" data-detail-approve>
                    <svg lucideIcon="BadgeCheck" [size]="18" aria-hidden="true"></svg>
                    {{ 'verification.admin.approve' | transloco }}
                  </button>
                  <button type="button" class="rd-btn rd-btn-outline flex-1 gap-1.5 border-error text-error sm:flex-none" (click)="decision.set({ kind: 'reject', item: r })" data-detail-reject>
                    <svg lucideIcon="BadgeX" [size]="18" aria-hidden="true"></svg>
                    {{ 'verification.admin.reject' | transloco }}
                  </button>
                </div>
              } @else {
                <div class="mt-6 border-t border-border pt-4 text-sm" data-detail-decision>
                  <p class="m-0 text-text-secondary">
                    {{ decidedBy(r) }}
                  </p>
                  @if (r.rejectionReason; as reason) {
                    <div class="mt-3 rounded-md bg-surface-variant px-4 py-3">
                      <p class="m-0 text-xs font-semibold text-text-secondary">{{ 'verification.rejected.reason' | transloco }}</p>
                      <p class="m-0 mt-1 whitespace-pre-line [overflow-wrap:anywhere]" [attr.dir]="dirOf(reason)" data-detail-reason><rd-bdi-text [text]="reason" /></p>
                    </div>
                  }
                </div>
              }
            </article>
          } @else {
            @switch (detailStatus()) {
              @case ('error') {
                <rd-error-state [message]="detailError()" (retry)="reloadDetail()" />
              }
              @default {
                <div class="rd-card flex flex-col gap-3 p-5 shadow-none" aria-busy="true" data-verification-detail-loading>
                  <div class="rd-skeleton h-12 w-1/2"></div>
                  <div class="rd-skeleton h-4 w-3/4"></div>
                  <div class="rd-skeleton h-40 w-full"></div>
                </div>
              }
            }
          }
        } @else {
          <div class="rd-card hidden flex-col items-center gap-2 px-6 py-16 text-center shadow-none lg:flex" data-verification-pick>
            <svg lucideIcon="BadgeCheck" [size]="28" class="text-text-secondary" aria-hidden="true"></svg>
            <p class="m-0 text-sm text-text-secondary">{{ 'verification.admin.pick' | transloco }}</p>
          </div>
        }
      </section>
    </div>

    <rd-decision-sheet [draft]="decision()" (closed)="decision.set(null)" (decided)="decide($event.item, $event.decision)" />
  `,
})
export class AdminVerificationPage {
  protected readonly store = inject(AdminVerificationStore);
  private readonly api = inject(VerificationApi);
  private readonly router = inject(Router);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);
  private readonly toasts = inject(ToastService);
  protected readonly lang = inject(LanguageService).lang;

  /** `?status=` and `?id=` (component input binding); anything else means Pending and no request open. */
  readonly status = input<string | undefined>();
  readonly id = input<string | undefined>();

  protected readonly path = PATH;
  protected readonly tabs = VERIFICATION_STATUSES;
  protected readonly skeletons = [1, 2, 3];
  protected readonly currentTab = computed<VerificationStatus>(() =>
    VERIFICATION_STATUSES.includes(this.status() as VerificationStatus) ? (this.status() as VerificationStatus) : 'pending',
  );
  protected readonly statusParam = computed(() => (this.currentTab() === 'pending' ? null : this.currentTab()));
  /** The open request; cleared at once by a decision, before the URL follows. */
  protected readonly selectedId = linkedSignal(() => this.id()?.trim() || null);
  /** A request opened by id that isn't on this tab. */
  private readonly detail = signal<Detail | null>(null);
  protected readonly selected = computed<AdminVerificationRequestDto | null>(() => {
    const id = this.selectedId();
    const fromList = this.store.find(id);
    if (fromList) return fromList;
    const detail = this.detail();
    return detail?.id === id && detail.status === 'loaded' ? detail.data : null;
  });
  protected readonly detailStatus = computed(() => this.detail()?.status ?? 'loading');
  protected readonly detailError = computed(() => {
    this.lang();
    const detail = this.detail();
    const key = detail?.status === 'error' && detail.notFound ? 'errors.verification.not_found' : 'verification.admin.detail.loadError';
    return this.transloco.translate(key);
  });
  protected readonly decision = signal<DecisionDraft | null>(null);

  protected readonly dirOf = (text: string | null | undefined) => detectDir(text) ?? 'auto';
  protected readonly safeUrl = isProofUrl;

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('verification.admin.title')} — ReadIn`);
    effect(() => {
      const tab = this.currentTab();
      untracked(() => void this.store.load(tab));
    });
    // A request that isn't on the loaded tab (a deep link) is loaded on its own.
    effect(() => {
      const id = this.selectedId();
      const listed = this.store.status() !== 'loading' && !this.store.find(id);
      untracked(() => {
        if (id && listed && this.detail()?.id !== id) void this.loadDetail(id);
      });
    });
  }

  protected statusTone(status: VerificationStatus): string {
    switch (status) {
      case 'pending':
        return 'bg-callout-warning text-text-primary';
      case 'approved':
        return 'bg-primary-container text-on-primary-container';
      default:
        return 'bg-callout-danger text-text-primary';
    }
  }

  /** "Approved by @nour · November 3, 2026" (a reviewer whose account is gone: "a deleted account"). */
  protected decidedBy(r: AdminVerificationRequestDto): string {
    const lang = this.lang();
    const name = r.decidedBy ? isolate(`@${r.decidedBy.username}`) : this.transloco.translate('verification.admin.decidedBy.deleted', {}, lang);
    const date = r.decidedAt ? new Intl.DateTimeFormat(intlLocale(lang), { day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(r.decidedAt)) : '';
    return this.transloco.translate(`verification.admin.decidedBy.${r.status}`, { name, date }, lang);
  }

  protected reloadDetail(): void {
    const id = this.selectedId();
    if (id) void this.loadDetail(id);
  }

  private async loadDetail(id: string): Promise<void> {
    this.detail.set({ id, status: 'loading' });
    try {
      const data = await firstValueFrom(this.api.get(id));
      if (this.detail()?.id === id) this.detail.set({ id, status: 'loaded', data });
    } catch (error) {
      if (this.detail()?.id === id) this.detail.set({ id, status: 'error', notFound: isApiError(error) && error.status === 404 });
    }
  }

  /** Applies a confirmed decision: the request leaves the list (and the pane) at once; a refusal brings it back. */
  protected async decide(item: AdminVerificationRequestDto, decision: VerificationDecision): Promise<void> {
    this.decision.set(null);
    if (this.selectedId() === item.id) {
      this.selectedId.set(null);
      this.detail.set(null);
      void this.router.navigate([PATH], { queryParams: { status: this.statusParam() }, replaceUrl: true });
    }
    try {
      await this.store.decide(item, decision);
      const name = isolate(item.user.displayName);
      this.toasts.success(this.transloco.translate(decision.kind === 'approve' ? 'verification.admin.approved' : 'verification.admin.rejected', { name }));
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
      // Back on screen (as it is now, when someone else decided it), unless another request was opened meanwhile.
      if (!this.selectedId()) void this.router.navigate([PATH], { queryParams: { status: this.statusParam(), id: item.id }, replaceUrl: true });
    }
  }
}
