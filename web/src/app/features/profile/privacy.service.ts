import { Injectable, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { PrivacySettingsDto } from '../../core/api/models';
import { ProfilesApi } from '../../core/api/profiles.api';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { ToastService } from '../../shared/ui/toast/toast.service';

const DEFAULTS: PrivacySettingsDto = { publicReadingStats: false };

/**
 * Settings → Privacy (F18) for the signed-in user, shared by the profile's "Show on my public profile" switch and the
 * Settings page. Optimistic: the switch moves at once and goes back (with the translated error) if `PUT /me/privacy`
 * fails. One save at a time; the switch is disabled meanwhile.
 */
@Injectable({ providedIn: 'root' })
export class PrivacyService {
  private readonly api = inject(ProfilesApi);
  private readonly session = inject(SessionStore);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);

  private readonly _saving = signal(false);
  readonly saving = this._saving.asReadonly();
  readonly settings = computed<PrivacySettingsDto>(() => ({ ...DEFAULTS, ...this.session.me()?.privacy }));
  readonly publicReadingStats = computed(() => this.settings().publicReadingStats);

  /** Resolves true once the server has it. */
  async setPublicReadingStats(publicReadingStats: boolean): Promise<boolean> {
    if (!this.session.isAuthenticated() || this._saving()) return false;
    const previous = this.settings();
    if (previous.publicReadingStats === publicReadingStats) return true;
    // The whole settings object goes back, so settings added later (F11's mentions) are kept.
    const next = { ...previous, publicReadingStats };
    this.session.patchMe({ privacy: next });
    this._saving.set(true);
    try {
      await firstValueFrom(this.api.updatePrivacy(next));
      return true;
    } catch (error) {
      this.session.patchMe({ privacy: previous });
      this.toasts.error(this.errors.forError(error));
      return false;
    } finally {
      this._saving.set(false);
    }
  }
}
