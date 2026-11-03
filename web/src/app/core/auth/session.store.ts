import { computed } from '@angular/core';
import { patchState, signalStore, withComputed, withMethods, withState } from '@ngrx/signals';
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
 */
export const SessionStore = signalStore(
  { providedIn: 'root' },
  withState<SessionState>({ status: 'unknown', me: null }),
  withComputed(({ status, me }) => ({
    isResolved: computed(() => status() !== 'unknown'),
    isAuthenticated: computed(() => status() === 'authenticated'),
    isGuest: computed(() => status() === 'guest'),
    permissions: computed(() => new Set(status() === 'authenticated' ? (me()?.permissions ?? []) : GUEST_PERMISSIONS)),
    displayName: computed(() => me()?.displayName ?? null),
    username: computed(() => me()?.username ?? null),
    avatarUrl: computed(() => me()?.avatarUrl ?? null),
    phoneNumber: computed(() => me()?.phoneNumber ?? null),
    /** The mandatory step this account has to finish first (SPEC §9.2), or null. */
    setupStep: computed(() => {
      const current = me();
      return status() === 'authenticated' && current ? nextSetupStep(current) : null;
    }),
  })),
  withMethods((store) => ({
    setGuest(): void {
      patchState(store, { status: 'guest', me: null });
    },
    setMe(me: MeDto): void {
      patchState(store, { status: 'authenticated', me });
    },
    patchMe(partial: Partial<MeDto>): void {
      const me = store.me();
      if (me) patchState(store, { me: { ...me, ...partial } });
    },
    hasPermission(permission: string): boolean {
      return store.permissions().has(permission);
    },
  })),
);

export type SessionStore = InstanceType<typeof SessionStore>;
