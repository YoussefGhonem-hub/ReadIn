import { Injectable, computed, effect, inject, signal, untracked } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { FollowsApi } from '../api/follows.api';
import { SessionStore } from '../auth/session.store';
import { ErrorMessages } from '../i18n/error-messages';
import { ToastService } from '../../shared/ui/toast/toast.service';

interface FollowEntry {
  /** What the server last confirmed. */
  server: boolean;
  /** What the UI shows (the user's wish while a request runs). */
  view: boolean;
}

/**
 * Who the signed-in user follows (F12), shared by the reader's author row and the suggested writers, so following
 * someone in one place shows everywhere. Optimistic like reactions: one request per user at a time, quick taps
 * coalesce, a failure rolls back and shows the translated error.
 */
@Injectable({ providedIn: 'root' })
export class FollowStore {
  private readonly api = inject(FollowsApi);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly session = inject(SessionStore);

  private readonly entries = signal<ReadonlyMap<string, FollowEntry>>(new Map());
  private readonly inFlight = new Set<string>();
  /** Told each time the server confirms a follow: following a writer you muted ends the mute (F28). */
  private readonly followListeners: ((userId: string) => void)[] = [];

  constructor() {
    const userId = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null));
    let previous: string | null | undefined;
    effect(() => {
      const current = userId();
      if (previous !== undefined && previous !== current) untracked(() => this.entries.set(new Map()));
      previous = current;
    });
  }

  /** Whether the viewer follows `userId`; `fallback` is what the API said when the page loaded. */
  isFollowing(userId: string, fallback: boolean): boolean {
    return this.entries().get(userId)?.view ?? fallback;
  }

  /** A fresh value from the API (e.g. the reader reloaded) replaces local state unless a request is running. */
  absorb(userId: string, isFollowing: boolean): void {
    if (this.inFlight.has(userId) || !this.entries().has(userId)) return;
    this.entries.update((map) => new Map(map).set(userId, { server: isFollowing, view: isFollowing }));
  }

  /**
   * A follow state the server confirmed through another call (F28: a mute ends your follow, its Undo follows again),
   * shown everywhere at once; a running follow request keeps its own answer.
   */
  learn(userId: string, isFollowing: boolean): void {
    if (this.inFlight.has(userId)) return;
    this.entries.update((map) => new Map(map).set(userId, { server: isFollowing, view: isFollowing }));
  }

  /** `listener(userId)` runs each time the server confirms a follow. */
  onFollowed(listener: (userId: string) => void): void {
    this.followListeners.push(listener);
  }

  toggle(userId: string, fallback: boolean): Promise<void> {
    return this.set(userId, !this.isFollowing(userId, fallback), fallback);
  }

  async set(userId: string, follow: boolean, fallback: boolean): Promise<void> {
    const entry = this.entries().get(userId) ?? { server: fallback, view: fallback };
    if (entry.view === follow) return;
    this.entries.update((map) => new Map(map).set(userId, { ...entry, view: follow }));
    if (this.inFlight.has(userId)) return; // the running request sends the newest wish when it ends
    this.inFlight.add(userId);
    try {
      for (;;) {
        const current = this.entries().get(userId);
        if (!current || current.view === current.server) return;
        const target = current.view;
        try {
          const result = await firstValueFrom(target ? this.api.follow(userId) : this.api.unfollow(userId));
          // The server's answer wins when it differs from the wish that was sent (never loop on it).
          this.update(userId, (e) => ({ server: result.isFollowing, view: e.view === target ? result.isFollowing : e.view }));
          if (result.isFollowing) for (const listener of this.followListeners) listener(userId);
        } catch (error) {
          if (this.entries().get(userId)?.view !== target) continue;
          this.update(userId, (e) => ({ ...e, view: e.server }));
          this.toasts.error(this.errors.forError(error));
          return;
        }
      }
    } finally {
      this.inFlight.delete(userId);
    }
  }

  private update(userId: string, change: (entry: FollowEntry) => FollowEntry): void {
    const entry = this.entries().get(userId);
    if (entry) this.entries.update((map) => new Map(map).set(userId, change(entry)));
  }
}
