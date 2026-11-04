import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { Title } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { LocalizedDatePipe } from '../../shared/pipes/format.pipes';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ErrorState } from '../../shared/ui/states';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { VerificationForm } from './verification-form';
import { provideVerificationIcons } from './verification-icons';
import { VerificationStore } from './verification.store';

/**
 * Writer verification (F19), `/verification` (also where `readin://verification` lands): you're verified; your request
 * is under review (with what you sent, and Withdraw); it wasn't approved (the reason, and Request again, which starts
 * from it); or the form. Signed-in only, rendered in the browser.
 */
@Component({
  selector: 'rd-verification-page',
  imports: [NgTemplateOutlet, RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, LocalizedDatePipe, BottomSheet, ErrorState, VerificationForm],
  providers: [VerificationStore, provideVerificationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[640px] px-4 pb-10 pt-6', '[attr.data-view]': 'store.view()' },
  template: `
    <a routerLink="/settings" class="-ms-1 mb-2 inline-flex min-h-11 items-center gap-1 rounded-md px-1 text-sm text-text-secondary no-underline hover:text-text-primary" data-back-to-settings>
      <svg lucideIcon="ArrowRight" [size]="18" class="shrink-0 ltr:rotate-180" aria-hidden="true"></svg>
      {{ 'verification.back' | transloco }}
    </a>
    <h1 class="m-0 text-2xl font-bold">{{ 'verification.title' | transloco }}</h1>
    <p class="m-0 mb-6 mt-1 text-sm text-text-secondary">{{ 'verification.intro' | transloco }}</p>

    @switch (store.status()) {
      @case ('error') {
        <rd-error-state [message]="'verification.loadError' | transloco" (retry)="store.load()" />
      }
      @case ('loaded') {
        @let request = store.request();
        @switch (store.view()) {
          @case ('verified') {
            <section class="rd-card flex items-start gap-4 p-5 shadow-none" data-verification-status="verified">
              <span class="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-primary-container text-on-primary-container" aria-hidden="true">
                <svg lucideIcon="BadgeCheck" [size]="26"></svg>
              </span>
              <div class="min-w-0">
                <h2 class="m-0 text-lg font-semibold">{{ 'verification.verified.title' | transloco }}</h2>
                <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'verification.verified.body' | transloco }}</p>
                @if (request?.status === 'approved') {
                  <p class="m-0 mt-2 text-sm text-text-secondary">
                    <rd-bdi-text [text]="request!.field.name" />
                    @if (request!.decidedAt) {
                      · {{ 'verification.approvedOn' | transloco: { date: (request!.decidedAt | rdDate: lang() : 'long') } }}
                    }
                  </p>
                }
              </div>
            </section>
          }
          @case ('pending') {
            <section class="rd-card p-5 shadow-none" data-verification-status="pending">
              <div class="flex items-start gap-4">
                <span class="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-callout-warning text-text-primary" aria-hidden="true">
                  <svg lucideIcon="Hourglass" [size]="24"></svg>
                </span>
                <div class="min-w-0">
                  <h2 class="m-0 text-lg font-semibold">{{ 'verification.pending.title' | transloco }}</h2>
                  <p class="m-0 mt-1 text-sm text-text-secondary" data-verification-submitted>
                    {{ 'verification.pending.body' | transloco: { date: (request!.submittedAt | rdDate: lang() : 'long') } }}
                  </p>
                </div>
              </div>
              <ng-container *ngTemplateOutlet="summary" />
              <button
                type="button"
                class="rd-btn rd-btn-outline mt-5 w-full border-error text-error sm:w-auto"
                [disabled]="store.withdrawing()"
                (click)="confirmWithdraw.set(true)"
                data-verification-withdraw
              >
                {{ 'verification.pending.withdraw' | transloco }}
              </button>
            </section>
          }
          @case ('rejected') {
            @if (again()) {
              <rd-verification-form [from]="request" (cancelled)="again.set(false)" />
            } @else {
              <section class="rd-card p-5 shadow-none" data-verification-status="rejected">
                <div class="flex items-start gap-4">
                  <span class="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-callout-danger text-error" aria-hidden="true">
                    <svg lucideIcon="BadgeX" [size]="24"></svg>
                  </span>
                  <div class="min-w-0">
                    <h2 class="m-0 text-lg font-semibold">{{ 'verification.rejected.title' | transloco }}</h2>
                    @if (request!.decidedAt) {
                      <p class="m-0 mt-1 text-sm text-text-secondary">
                        {{ 'verification.rejected.decided' | transloco: { date: (request!.decidedAt | rdDate: lang() : 'long') } }}
                      </p>
                    }
                  </div>
                </div>
                @if (request!.rejectionReason; as reason) {
                  <div class="mt-4 rounded-md bg-surface-variant px-4 py-3">
                    <p class="m-0 text-xs font-semibold text-text-secondary">{{ 'verification.rejected.reason' | transloco }}</p>
                    <p class="m-0 mt-1 whitespace-pre-line text-sm [overflow-wrap:anywhere]" [attr.dir]="dirOf(reason)" data-verification-reason>
                      <rd-bdi-text [text]="reason" />
                    </p>
                  </div>
                }
                <ng-container *ngTemplateOutlet="summary" />
                <button type="button" class="rd-btn rd-btn-primary mt-5 w-full sm:w-auto" (click)="again.set(true)" data-verification-again>
                  {{ 'verification.rejected.again' | transloco }}
                </button>
              </section>
            }
          }
          @case ('unavailable') {
            <section class="rd-card flex items-start gap-4 p-5 shadow-none" data-verification-status="unavailable">
              <span class="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-surface-variant text-text-secondary" aria-hidden="true">
                <svg lucideIcon="Info" [size]="24"></svg>
              </span>
              <div class="min-w-0">
                <h2 class="m-0 text-lg font-semibold">{{ 'verification.unavailable.title' | transloco }}</h2>
                <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'verification.unavailable.body' | transloco }}</p>
              </div>
            </section>
          }
          @default {
            <rd-verification-form />
          }
        }
      }
      @default {
        <div class="rd-card flex flex-col gap-3 p-5 shadow-none" aria-busy="true" data-verification-loading>
          <div class="rd-skeleton h-6 w-1/2"></div>
          <div class="rd-skeleton h-4 w-3/4"></div>
          <div class="rd-skeleton h-11 w-full"></div>
          <div class="rd-skeleton h-11 w-full"></div>
        </div>
      }
    }

    <!-- What was sent: field, job title, link, file, note -->
    <ng-template #summary>
      @if (store.request(); as r) {
        <dl class="m-0 mt-4 grid grid-cols-[auto_minmax(0,1fr)] gap-x-4 gap-y-2 border-t border-border pt-4 text-sm" data-verification-summary>
          <dt class="text-text-secondary">{{ 'verification.summary.field' | transloco }}</dt>
          <dd class="m-0 font-semibold"><rd-bdi-text [text]="r.field.name" /></dd>
          <dt class="text-text-secondary">{{ 'verification.summary.jobTitle' | transloco }}</dt>
          <dd class="m-0 [overflow-wrap:anywhere]" data-summary-job-title><rd-bdi-text [text]="r.jobTitle" /></dd>
          @if (r.proofUrl) {
            <dt class="text-text-secondary">{{ 'verification.summary.proofUrl' | transloco }}</dt>
            <dd class="m-0 flex min-w-0"><bdi dir="ltr" class="min-w-0 truncate" data-summary-proof-url>{{ r.proofUrl }}</bdi></dd>
          }
          @if (r.proofFileName) {
            <dt class="text-text-secondary">{{ 'verification.summary.proofFile' | transloco }}</dt>
            <dd class="m-0 flex min-w-0"><bdi dir="auto" class="min-w-0 truncate" data-summary-proof-file>{{ r.proofFileName }}</bdi></dd>
          }
          @if (r.note) {
            <dt class="text-text-secondary">{{ 'verification.summary.note' | transloco }}</dt>
            <dd class="m-0 whitespace-pre-line [overflow-wrap:anywhere]" [attr.dir]="dirOf(r.note)"><rd-bdi-text [text]="r.note" /></dd>
          }
        </dl>
      }
    </ng-template>

    <rd-bottom-sheet [open]="confirmWithdraw()" role="alertdialog" labelledBy="withdraw-title" describedBy="withdraw-body" (closed)="confirmWithdraw.set(false)">
      <div class="flex flex-col gap-3 pt-1" data-withdraw-sheet>
        <h2 id="withdraw-title" class="m-0 pe-10 text-xl font-semibold">{{ 'verification.withdrawSheet.title' | transloco }}</h2>
        <p id="withdraw-body" class="m-0 text-sm text-text-secondary">{{ 'verification.withdrawSheet.body' | transloco }}</p>
        <div class="mt-2 flex gap-2">
          <button type="button" class="rd-btn rd-btn-outline flex-1" (click)="confirmWithdraw.set(false)">{{ 'common.cancel' | transloco }}</button>
          <button type="button" class="rd-btn flex-1 bg-error text-on-error" (click)="withdraw()" data-withdraw-confirm>{{ 'verification.withdrawSheet.confirm' | transloco }}</button>
        </div>
      </div>
    </rd-bottom-sheet>
  `,
})
export class VerificationPage {
  protected readonly store = inject(VerificationStore);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);
  private readonly toasts = inject(ToastService);
  protected readonly lang = inject(LanguageService).lang;

  /** "Request again" after a rejection: the form, starting from the rejected request. */
  protected readonly again = signal(false);
  protected readonly confirmWithdraw = signal(false);
  protected readonly dirOf = (text: string | null | undefined) => detectDir(text) ?? 'auto';

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('verification.title')} — ReadIn`);
    void this.store.load();
  }

  protected async withdraw(): Promise<void> {
    this.confirmWithdraw.set(false);
    this.again.set(false);
    try {
      await this.store.withdraw();
      this.toasts.success(this.transloco.translate('verification.withdrawn'));
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
    }
  }
}
