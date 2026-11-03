import { computed } from '@angular/core';
import { patchState, signalStore, withComputed, withMethods, withState } from '@ngrx/signals';
import { MeDto } from '../api/models';

/** `unknown` until Firebase reports the persisted session (always `unknown` during SSR). */
export type SessionStatus = 'unknown' | 'guest' | 'authenticated';

export interface FirebaseUserSummary {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  emailVerified: boolean;
}

interface SessionState {
  status: SessionStatus;
  user: FirebaseUserSummary | null;
  me: MeDto | null;
  syncing: boolean;
  syncFailed: boolean;
}

/** Guests can only read (SPEC §10.2). */
const GUEST_PERMISSIONS: readonly string[] = ['articles.read'];

export const SessionStore = signalStore(
  { providedIn: 'root' },
  withState<SessionState>({ status: 'unknown', user: null, me: null, syncing: false, syncFailed: false }),
  withComputed(({ status, me, user }) => ({
    isResolved: computed(() => status() !== 'unknown'),
    isAuthenticated: computed(() => status() === 'authenticated'),
    isGuest: computed(() => status() === 'guest'),
    permissions: computed(() => new Set(status() === 'authenticated' ? (me()?.permissions ?? []) : GUEST_PERMISSIONS)),
    displayName: computed(() => me()?.displayName ?? user()?.displayName ?? null),
    username: computed(() => me()?.username ?? null),
    avatarUrl: computed(() => me()?.avatarUrl ?? user()?.photoUrl ?? null),
    needsOnboarding: computed(() => status() === 'authenticated' && me() !== null && !me()!.onboardingCompleted),
  })),
  withMethods((store) => ({
    setGuest(): void {
      patchState(store, { status: 'guest', user: null, me: null, syncing: false, syncFailed: false });
    },
    setUser(user: FirebaseUserSummary): void {
      const sameUser = store.user()?.uid === user.uid;
      patchState(store, { status: 'authenticated', user, me: sameUser ? store.me() : null });
    },
    setSyncing(syncing: boolean): void {
      patchState(store, { syncing });
    },
    setMe(me: MeDto): void {
      patchState(store, { me, syncing: false, syncFailed: false });
    },
    setSyncFailed(): void {
      patchState(store, { syncing: false, syncFailed: true });
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
