import { Injectable, computed, effect, inject } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { ProfileDto } from '../../core/api/models';
import { ProfilesApi } from '../../core/api/profiles.api';
import { SessionStore } from '../../core/auth/session.store';

/** How long a profile the card loaded stays fresh. */
export const PROFILE_CARD_TTL_MS = 2 * 60 * 1000;

interface Entry {
  promise: Promise<ProfileDto>;
  /** The profile once it arrived, and when; null while the request is on its way. */
  value: ProfileDto | null;
  at: number | null;
}

/**
 * The profiles the hover card shows (`GET /users/{username}`, contract "Profile card on hover"), kept briefly so moving
 * the pointer over the same names again doesn't ask again. A request on its way is shared; an entry stays about 2
 * minutes. Entries are kept per viewer and username, and all dropped when the account changes, so the follow state
 * always belongs to whoever is looking. A failure isn't kept: the next card asks again.
 */
@Injectable({ providedIn: 'root' })
export class ProfileCardCache {
  private readonly api = inject(ProfilesApi);
  private readonly session = inject(SessionStore);
  private readonly entries = new Map<string, Entry>();
  private readonly viewer = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? 'guest') : 'guest'));

  /** The clock (tests move it). */
  now: () => number = () => Date.now();

  constructor() {
    let previous: string | undefined;
    effect(() => {
      const viewer = this.viewer();
      if (previous !== undefined && previous !== viewer) this.entries.clear();
      previous = viewer;
    });
  }

  /** The fresh profile already loaded for this viewer, or null (to draw the card at once). */
  peek(username: string): ProfileDto | null {
    const entry = this.entries.get(this.key(username));
    return entry?.value && this.fresh(entry) ? entry.value : null;
  }

  /** The profile: from memory while fresh, else from the API (one request per name at a time). */
  get(username: string): Promise<ProfileDto> {
    const key = this.key(username);
    const cached = this.entries.get(key);
    if (cached && this.fresh(cached)) return cached.promise;
    const entry: Entry = { promise: firstValueFrom(this.api.profile(username)), value: null, at: null };
    this.entries.set(key, entry);
    entry.promise.then(
      (profile) => {
        entry.value = profile;
        entry.at = this.now();
      },
      () => {
        if (this.entries.get(key) === entry) this.entries.delete(key);
      },
    );
    return entry.promise;
  }

  /** On its way, or arrived less than {@link PROFILE_CARD_TTL_MS} ago. */
  private fresh(entry: Entry): boolean {
    return entry.at === null || this.now() - entry.at < PROFILE_CARD_TTL_MS;
  }

  private key(username: string): string {
    return `${this.viewer()}|${username.replace(/^@/, '').toLowerCase()}`;
  }
}
