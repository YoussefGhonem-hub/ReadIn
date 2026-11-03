import { DestroyRef, PLATFORM_ID, computed, effect, inject, untracked } from '@angular/core';
import { DOCUMENT, isPlatformBrowser } from '@angular/common';
import { patchState, signalStore, withHooks, withMethods, withState } from '@ngrx/signals';
import { firstValueFrom } from 'rxjs';
import { ReadingProgressResultDto, StreakDto } from '../../core/api/models';
import { ReadingApi } from '../../core/api/reading.api';
import { SessionStore } from '../../core/auth/session.store';

interface StreakState {
  /** Null for guests and until `GET /me/stats` answered. */
  streak: StreakDto | null;
}

/** A streak older than this is re-read when the tab becomes visible again. */
export const STREAK_STALE_AFTER_MS = 15 * 60_000;

/**
 * The signed-in user's streak (F08) for the 🔥 badge. Loads `GET /me/stats` when a user signs in (or the session is
 * restored), clears on sign out, and takes the fresher streak of a progress report that completed an article. When the
 * tab comes back after midnight or after {@link STREAK_STALE_AFTER_MS}, it re-reads it ("read today" changes at
 * midnight). Browser only: during SSR every page is anonymous.
 */
export const StreakStore = signalStore(
  { providedIn: 'root' },
  withState<StreakState>({ streak: null }),
  withMethods((store, api = inject(ReadingApi), session = inject(SessionStore)) => {
    const userId = () => (session.isAuthenticated() ? (session.me()?.id ?? null) : null);
    // Bumped by every write, so an older `load` that answers late never overwrites a fresher streak.
    let generation = 0;
    let freshAt: Date | null = null;
    const set = (streak: StreakDto | null) => {
      generation++;
      freshAt = streak ? new Date() : null;
      patchState(store, { streak });
    };

    const load = async (now: Date = new Date()): Promise<void> => {
      const owner = userId();
      if (!owner) return;
      const current = ++generation;
      try {
        const stats = await firstValueFrom(api.stats());
        if (current === generation && userId() === owner) {
          freshAt = now;
          patchState(store, { streak: stats.streak });
        }
      } catch {
        /* offline or a server error: the badge stays on "—" */
      }
    };

    return {
      /** `GET /me/stats`. A failure keeps the badge on "—"; the stats sheet has its own retry. */
      load,
      /** Re-reads the streak after midnight or when it is older than {@link STREAK_STALE_AFTER_MS}. */
      async refreshIfStale(now: Date = new Date()): Promise<void> {
        const sameDay = freshAt !== null && freshAt.toDateString() === now.toDateString();
        if (freshAt !== null && sameDay && now.getTime() - freshAt.getTime() < STREAK_STALE_AFTER_MS) return;
        await load(now);
      },
      clear(): void {
        set(null);
      },
      /** A fresher streak from a view that loaded the stats itself. */
      setStreak(streak: StreakDto): void {
        if (userId()) set(streak);
      },
      /** The answer to `PUT /articles/{id}/progress`; it carries the streak when it completed an article. */
      applyProgress(result: ReadingProgressResultDto): void {
        if (result.completedNow && result.streak && userId()) set(result.streak);
      },
    };
  }),
  withHooks({
    onInit(store) {
      if (!isPlatformBrowser(inject(PLATFORM_ID))) return;
      const session = inject(SessionStore);
      const userId = computed(() => (session.isAuthenticated() ? (session.me()?.id ?? null) : null));
      // Follows the session: a new user loads their streak, signing out forgets it.
      effect(() => {
        const id = userId();
        untracked(() => {
          store.clear();
          if (id) void store.load();
        });
      });
      // A tab left open overnight still says "read today": re-read it when the user comes back.
      const document = inject(DOCUMENT);
      const onVisible = () => {
        if (document.visibilityState === 'visible') void store.refreshIfStale();
      };
      document.addEventListener('visibilitychange', onVisible);
      inject(DestroyRef).onDestroy(() => document.removeEventListener('visibilitychange', onVisible));
    },
  }),
);

export type StreakStore = InstanceType<typeof StreakStore>;
