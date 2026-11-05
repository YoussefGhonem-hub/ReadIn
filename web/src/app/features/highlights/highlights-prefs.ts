import { Injectable, PLATFORM_ID, computed, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { PreferencesService } from '../../core/auth/preferences.service';
import { SessionStore } from '../../core/auth/session.store';

const STORAGE_KEY = 'rd.highlights.hidden';

/**
 * Show or hide highlights (F30, F18): the reader's "⋯" item, `Ctrl + /` and the Settings switch. Signed in, it is
 * `MeDto.showHighlights` (default on), synced with `PUT /me/preferences`: optimistic, rolled back if the save fails
 * (the error interceptor shows why). Guests keep their choice on this device, with no sign-in prompt.
 */
@Injectable({ providedIn: 'root' })
export class HighlightsPrefs {
  private readonly session = inject(SessionStore);
  private readonly preferences = inject(PreferencesService);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly guestHidden = signal(this.readLocal());
  /** The latest change: an older save that fails doesn't roll a newer one back. */
  private version = 0;

  readonly visible = computed(() => (this.session.isAuthenticated() ? this.session.me()?.showHighlights !== false : !this.guestHidden()));

  toggle(): Promise<boolean> {
    return this.set(!this.visible());
  }

  /** Resolves true once it is kept (the server has it, or this device for a guest). */
  async set(visible: boolean): Promise<boolean> {
    if (visible === this.visible()) return true;
    if (!this.session.isAuthenticated()) {
      this.guestHidden.set(!visible);
      this.writeLocal(!visible);
      return true;
    }
    const version = ++this.version;
    const previous = this.session.me()?.showHighlights;
    this.session.patchMe({ showHighlights: visible });
    try {
      await this.preferences.save({ showHighlights: visible });
      return true;
    } catch {
      if (version === this.version) this.session.patchMe({ showHighlights: previous });
      return false;
    }
  }

  private readLocal(): boolean {
    if (!this.isBrowser) return false;
    try {
      return localStorage.getItem(STORAGE_KEY) === '1';
    } catch {
      return false;
    }
  }

  private writeLocal(hidden: boolean): void {
    if (!this.isBrowser) return;
    try {
      if (hidden) localStorage.setItem(STORAGE_KEY, '1');
      else localStorage.removeItem(STORAGE_KEY);
    } catch {
      /* storage unavailable (private mode): the choice lasts until the tab closes */
    }
  }
}
