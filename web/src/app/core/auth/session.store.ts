import { Injectable, computed, signal } from '@angular/core';
import { MeDto } from '../api/models';
import { nextSetupStep } from './account-setup';

/** `unknown` until the browser has tried to restore the session (always `unknown` during SSR). */
export type SessionStatus = 'unknown' | 'guest' | 'authenticated';

interface SessionState {
  status: SessionStatus;
  me: MeDto | null;
}

/** Guests can only read (SPEC §10.2). */
const GUEST_PERMISSIONS: readonly string[] = ['articles.read'];

/**
 * Who is signed in, as UI state. The access token itself never lives here (AuthService keeps it in a private field);
 * nothing about the session is ever written to localStorage or sessionStorage (SPEC §9.3).
 *
 * Plain signals (one state signal, updated as a whole, with computed slices), not an NgRx signal store: the store is in
 * the initial bundle, and `@ngrx/signals` then stays in the chunks of the pages that use it.
 */
@Injectable({ providedIn: 'root' })
export class SessionStore {
  private readonly state = signal<SessionState>({ status: 'unknown', me: null });

  readonly status = computed(() => this.state().status);
  readonly me = computed(() => this.state().me);

  readonly isResolved = computed(() => this.status() !== 'unknown');
  readonly isAuthenticated = computed(() => this.status() === 'authenticated');
  readonly isGuest = computed(() => this.status() === 'guest');
  readonly permissions = computed(() => new Set(this.status() === 'authenticated' ? (this.me()?.permissions ?? []) : GUEST_PERMISSIONS));
  readonly displayName = computed(() => this.me()?.displayName ?? null);
  readonly username = computed(() => this.me()?.username ?? null);
  readonly avatarUrl = computed(() => this.me()?.avatarUrl ?? null);
  readonly phoneNumber = computed(() => this.me()?.phoneNumber ?? null);
  /** The mandatory step this account has to finish first (SPEC §9.2), or null. */
  readonly setupStep = computed(() => {
    const current = this.me();
    return this.status() === 'authenticated' && current ? nextSetupStep(current) : null;
  });

  setGuest(): void {
    this.state.set({ status: 'guest', me: null });
  }

  setMe(me: MeDto): void {
    this.state.set({ status: 'authenticated', me });
  }

  patchMe(partial: Partial<MeDto>): void {
    const me = this.me();
    if (me) this.state.update((state) => ({ ...state, me: { ...me, ...partial } }));
  }

  hasPermission(permission: string): boolean {
    return this.permissions().has(permission);
  }
}
