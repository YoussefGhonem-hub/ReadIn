import { Injectable, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { MentionPolicy, PrivacySettingsDto } from '../../core/api/models';
import { ProfilesApi } from '../../core/api/profiles.api';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { ToastService } from '../../shared/ui/toast/toast.service';

const DEFAULTS: PrivacySettingsDto = { publicReadingStats: false, whoCanMention: 'everyone' };

/**
 * Settings → Privacy (F18) for the signed-in user, shared by the profile's "Show on my public profile" switch and the
 * Settings page (that switch and "Who can mention me"). Optimistic: the control moves at once and goes back (with the
 * translated error) if `PUT /me/privacy` fails. One save at a time; the controls are disabled meanwhile.
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
  readonly whoCanMention = computed(() => this.settings().whoCanMention);

  /** Resolves true once the server has it. */
  setPublicReadingStats(publicReadingStats: boolean): Promise<boolean> {
    return this.save({ publicReadingStats });
  }

  /** Resolves true once the server has it. */
  setWhoCanMention(whoCanMention: MentionPolicy): Promise<boolean> {
    return this.save({ whoCanMention });
  }

  private async save(change: Partial<PrivacySettingsDto>): Promise<boolean> {
    if (!this.session.isAuthenticated() || this._saving()) return false;
    const previous = this.settings();
    const next = { ...previous, ...change };
    if ((Object.keys(change) as (keyof PrivacySettingsDto)[]).every((key) => previous[key] === next[key])) return true;
    // The whole settings object goes back, so the other settings stay as they are.
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
