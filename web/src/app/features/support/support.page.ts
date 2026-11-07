import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { SupportConfigDto } from '../../core/api/models';
import { SupportApi } from '../../core/api/support.api';
import { SessionStore } from '../../core/auth/session.store';
import { environment } from '../../../environments/environment';
import { NewTicketForm } from './new-ticket-form';

/**
 * Help & support (F35), `/support`: public, server-rendered and indexable (it is the App Store support URL). How to reach
 * support and the support email (`GET /support/config`; hidden when the API has none). Signed-in members get the "New
 * ticket" form and a link to "My tickets"; guests get "Sign in to send a ticket". Until the browser knows who is signed
 * in (and on the server), the form's place shows a placeholder.
 */
@Component({
  selector: 'rd-support-page',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, NewTicketForm],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[640px] flex-col gap-2 px-4 pt-5 lg:pt-8', 'data-support-page': '' },
  template: `
    <header class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5">
      <h1 class="m-0 flex items-center gap-2 text-xl font-bold lg:text-2xl">
        <svg lucideIcon="LifeBuoy" [size]="24" class="text-primary" aria-hidden="true"></svg>
        {{ 'support.title' | transloco }}
      </h1>
      <p class="m-0 mt-2 text-sm text-text-secondary">{{ 'support.intro' | transloco }}</p>
      @if (email(); as address) {
        <p class="m-0 mt-3 flex flex-wrap items-center gap-2 text-sm" data-support-email>
          <svg lucideIcon="Mail" [size]="16" class="text-text-secondary" aria-hidden="true"></svg>
          {{ 'support.emailLabel' | transloco }}
          <a [href]="'mailto:' + address" class="font-semibold text-link" dir="ltr">{{ address }}</a>
        </p>
      }
    </header>

    @switch (session.status()) {
      @case ('authenticated') {
        <section class="rd-card p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" aria-labelledby="new-ticket" data-support-member>
          <div class="mb-4 flex flex-wrap items-center justify-between gap-2">
            <h2 id="new-ticket" class="m-0 text-base font-semibold">{{ 'support.newTicket' | transloco }}</h2>
            <a routerLink="/support/tickets" class="inline-flex min-h-11 items-center gap-1.5 text-sm font-semibold text-link no-underline hover:underline" data-my-tickets>
              {{ 'support.myTickets' | transloco }}
              <svg lucideIcon="ChevronRight" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
            </a>
          </div>
          <rd-new-ticket-form [config]="config()" [screen]="cameFrom" />
        </section>
      }
      @case ('guest') {
        <section class="rd-card flex flex-col items-start gap-3 p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" data-support-guest>
          <p class="m-0 text-sm">{{ 'support.guest' | transloco }}</p>
          <a routerLink="/auth/sign-in" [queryParams]="{ returnUrl: '/support' }" class="rd-btn rd-btn-primary min-h-11 px-5" data-support-sign-in>{{ 'support.signIn' | transloco }}</a>
        </section>
      }
      @default {
        <div class="rd-card flex flex-col gap-3 p-5 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" aria-hidden="true" data-support-pending>
          <div class="rd-skeleton h-5 w-1/3"></div>
          <div class="rd-skeleton h-11 w-full"></div>
          <div class="rd-skeleton h-24 w-full"></div>
        </div>
      }
    }
  `,
})
export class SupportPage {
  protected readonly session = inject(SessionStore);
  private readonly api = inject(SupportApi);

  protected readonly config = signal<SupportConfigDto | null>(null);
  private readonly failed = signal(false);
  /** The API's address; when it can't answer, the one this build knows. Null: none to show. */
  protected readonly email = computed(() => (this.config() ? this.config()!.email : this.failed() ? environment.supportEmail || null : null));
  /** The route the member opened support from (the ticket's "screen"). */
  protected readonly cameFrom = inject(Router).currentNavigation()?.previousNavigation?.finalUrl?.toString() ?? '/support';

  constructor() {
    void firstValueFrom(this.api.config()).then(
      (config) => this.config.set(config),
      () => this.failed.set(true),
    );
  }
}
