import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ExternalProvider } from '../../../core/api/models';
import { AuthService } from '../../../core/auth/auth.service';
import { ExternalIdentityService } from '../../../core/auth/external-identity.service';
import { SessionStore } from '../../../core/auth/session.store';
import { Avatar } from '../../../shared/ui/avatar';
import { formatPhoneForDisplay } from '../../../shared/ui/phone/phone-number';
import { ChangePasswordSheet, ChangePhoneSheet, ChangePinSheet, DeleteAccountSheet, SignOutEverywhereSheet } from './account-sheets';
import { AddPhoneSignInSheet, LinkProviderSheet, PROVIDER_NAMES, UnlinkProviderSheet } from './external-sheets';

type Sheet = 'phone' | 'password' | 'pin' | 'signOutEverywhere' | 'delete' | 'addPhone';

/**
 * Settings → Account (F18): the phone number (shown to its owner only) with "change number", change password,
 * change PIN, linked Google/Apple accounts, sign out, sign out of all devices and delete account. Google/Apple-only
 * accounts get "add phone + password" instead of the number, password and PIN rows. Guests get a sign-in prompt.
 */
@Component({
  selector: 'rd-account-settings',
  imports: [
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    Avatar,
    ChangePhoneSheet,
    ChangePasswordSheet,
    ChangePinSheet,
    SignOutEverywhereSheet,
    DeleteAccountSheet,
    AddPhoneSignInSheet,
    LinkProviderSheet,
    UnlinkProviderSheet,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <section class="rd-card p-5 shadow-none" aria-labelledby="account" data-account>
      <h2 id="account" class="m-0 mb-4 text-base font-semibold">{{ 'settings.account' | transloco }}</h2>
      @if (session.isAuthenticated()) {
        <div class="flex items-center gap-3">
          <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="44" />
          <div class="min-w-0 flex-1">
            <div class="truncate font-semibold"><bdi>{{ session.displayName() }}</bdi></div>
            <div class="truncate text-sm text-text-secondary"><span dir="ltr">&#64;{{ session.username() }}</span></div>
          </div>
        </div>

        <ul class="m-0 mt-5 list-none divide-y divide-border border-y border-border p-0">
          @if (hasPassword()) {
          <li class="flex flex-wrap items-center gap-3 py-3">
            <svg lucideIcon="Smartphone" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
            <div class="min-w-0 flex-1">
              <div class="text-sm font-semibold">{{ 'account.phone' | transloco }}</div>
              <div class="font-latin text-sm text-text-secondary"><span dir="ltr" data-account-phone>{{ phone() }}</span></div>
              <div class="text-xs text-text-secondary">{{ 'account.phoneOwnerOnly' | transloco }}</div>
            </div>
            <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" (click)="sheet.set('phone')" data-open="phone">
              {{ 'account.changePhone.action' | transloco }}
            </button>
          </li>
          <li class="flex flex-wrap items-center gap-3 py-3">
            <svg lucideIcon="LockKeyhole" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
            <div class="min-w-0 flex-1">
              <div class="text-sm font-semibold">{{ 'auth.password' | transloco }}</div>
              <div class="text-sm text-text-secondary" aria-hidden="true"><span dir="ltr">••••••••</span></div>
            </div>
            <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" (click)="sheet.set('password')" data-open="password">
              {{ 'account.changePassword.action' | transloco }}
            </button>
          </li>
          <li class="flex flex-wrap items-center gap-3 py-3">
            <svg lucideIcon="KeyRound" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
            <div class="min-w-0 flex-1">
              <div class="text-sm font-semibold">{{ 'auth.pin' | transloco }}</div>
              <div class="text-sm text-text-secondary">{{ (hasPin() ? 'account.pinSet' : 'account.pinNotSet') | transloco }}</div>
            </div>
            <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" (click)="sheet.set('pin')" data-open="pin">
              {{ 'account.changePin.action' | transloco }}
            </button>
          </li>
          } @else {
            <!-- Google/Apple-only accounts (ADR 0012): no number, password or PIN yet. -->
            <li class="flex flex-wrap items-center gap-3 py-3" data-add-phone-row>
              <svg lucideIcon="Smartphone" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
              <div class="min-w-0 flex-1">
                <div class="text-sm font-semibold">{{ 'account.addPhone.action' | transloco }}</div>
                <div class="text-xs text-text-secondary">{{ 'account.addPhone.hint' | transloco }}</div>
              </div>
              <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" (click)="sheet.set('addPhone')" data-open="addPhone">
                {{ 'account.addPhone.button' | transloco }}
              </button>
            </li>
          }
        </ul>

        @if (linkRows().length) {
          <div class="mt-5" data-linked-accounts>
            <h3 class="m-0 text-sm font-semibold">{{ 'account.linked.title' | transloco }}</h3>
            <p class="m-0 mt-1 text-xs text-text-secondary">{{ 'account.linked.hint' | transloco }}</p>
            <ul class="m-0 mt-2 list-none divide-y divide-border p-0">
              @for (row of linkRows(); track row.provider) {
                <li class="flex flex-wrap items-center gap-3 py-3" [attr.data-provider]="row.provider">
                  <span class="grid h-8 w-8 shrink-0 place-items-center rounded-full border border-border font-latin text-sm font-bold" aria-hidden="true">{{ row.initial }}</span>
                  <div class="min-w-0 flex-1">
                    <div class="text-sm font-semibold">{{ row.name }}</div>
                    <div class="truncate text-xs text-text-secondary" data-provider-status>
                      @if (row.linked) {
                        @if (row.email) {
                          <span dir="ltr">{{ row.email }}</span>
                        } @else {
                          {{ 'account.linked.linked' | transloco }}
                        }
                      } @else {
                        {{ 'account.linked.notLinked' | transloco }}
                      }
                    </div>
                  </div>
                  @if (row.linked) {
                    <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm" (click)="unlinkProvider.set(row.provider)" data-unlink>
                      {{ 'account.linked.unlink' | transloco }}
                    </button>
                  } @else if (row.available) {
                    <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" (click)="linkProvider.set(row.provider)" data-link>
                      {{ 'account.linked.link' | transloco }}
                    </button>
                  }
                </li>
              }
            </ul>
          </div>
        }

        <div class="mt-5 flex flex-col gap-2 sm:flex-row">
          <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="signingOut()" (click)="signOut()" data-sign-out>
            <svg lucideIcon="LogOut" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>{{ 'auth.signOut' | transloco }}
          </button>
          <button type="button" class="rd-btn rd-btn-outline flex-1" (click)="sheet.set('signOutEverywhere')" data-open="signOutEverywhere">
            <svg lucideIcon="MonitorSmartphone" [size]="16" aria-hidden="true"></svg>{{ 'account.signOutEverywhere.action' | transloco }}
          </button>
        </div>

        <div class="mt-6 border-t border-border pt-4">
          <h3 class="m-0 text-sm font-semibold text-error">{{ 'account.dangerZone' | transloco }}</h3>
          <p class="m-0 mt-1 text-xs text-text-secondary">{{ 'account.delete.hint' | transloco }}</p>
          <button type="button" class="rd-btn rd-btn-ghost mt-2 px-0 text-error" (click)="sheet.set('delete')" data-open="delete">
            <svg lucideIcon="Trash2" [size]="16" aria-hidden="true"></svg>{{ 'account.delete.action' | transloco }}
          </button>
        </div>
      } @else {
        <p class="m-0 mb-4 text-sm text-text-secondary">{{ 'settings.guestHint' | transloco }}</p>
        <a routerLink="/auth/sign-in" [queryParams]="{ returnUrl: '/settings' }" class="rd-btn rd-btn-primary w-full">{{ 'auth.signIn.submit' | transloco }}</a>
      }
    </section>

    <rd-change-phone-sheet [open]="sheet() === 'phone'" (closed)="sheet.set(null)" />
    <rd-change-password-sheet [open]="sheet() === 'password'" (closed)="sheet.set(null)" />
    <rd-change-pin-sheet [open]="sheet() === 'pin'" (closed)="sheet.set(null)" />
    <rd-sign-out-everywhere-sheet [open]="sheet() === 'signOutEverywhere'" (closed)="sheet.set(null)" />
    <rd-delete-account-sheet [open]="sheet() === 'delete'" (closed)="sheet.set(null)" />
    <rd-add-phone-sign-in-sheet [open]="sheet() === 'addPhone'" (closed)="sheet.set(null)" />
    <rd-link-provider-sheet [provider]="linkProvider()" (closed)="linkProvider.set(null)" />
    <rd-unlink-provider-sheet [provider]="unlinkProvider()" (closed)="unlinkProvider.set(null)" />
  `,
})
export class AccountSettings {
  protected readonly session = inject(SessionStore);
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  protected readonly sheet = signal<Sheet | null>(null);
  protected readonly signingOut = signal(false);
  protected readonly phone = computed(() => formatPhoneForDisplay(this.session.phoneNumber()));
  protected readonly hasPin = computed(() => this.session.me()?.hasRecoveryPin ?? false);
  protected readonly hasPassword = computed(() => this.session.me()?.hasPassword ?? true);
  protected readonly linkProvider = signal<ExternalProvider | null>(null);
  protected readonly unlinkProvider = signal<ExternalProvider | null>(null);
  private readonly external = inject(ExternalIdentityService);

  /** Google and Apple rows: the ones this web build offers, plus any already linked (so they can be unlinked). */
  protected readonly linkRows = computed(() => {
    const logins = this.session.me()?.externalLogins ?? [];
    const available = this.external.providers();
    return (['google', 'apple'] as const)
      .filter((p) => available.includes(p) || logins.some((l) => l.provider === p))
      .map((provider) => {
        const login = logins.find((l) => l.provider === provider);
        return {
          provider,
          name: PROVIDER_NAMES[provider],
          initial: PROVIDER_NAMES[provider][0],
          linked: !!login,
          email: login?.email ?? null,
          available: available.includes(provider),
        };
      });
  });

  constructor() {
    void this.external.load();
  }

  protected async signOut(): Promise<void> {
    if (this.signingOut()) return;
    this.signingOut.set(true);
    try {
      await this.auth.signOut();
      await this.router.navigateByUrl('/');
    } finally {
      this.signingOut.set(false);
    }
  }
}
