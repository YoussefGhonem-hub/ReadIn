import { Injectable, inject } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { MeApi } from '../api/me.api';
import { UpdatePreferencesRequest } from '../api/models';
import { LanguageService, UiLanguage } from '../i18n/language.service';
import { ThemePreference, ThemeService } from '../theme/theme.service';
import { localTimeZone } from './time-zone';
import { SessionStore } from './session.store';

/**
 * Applies preferences locally (cookie, `<html>` attributes) and, when signed in, syncs them to the profile
 * with `PUT /me/preferences` so they follow the user across devices (F18).
 */
@Injectable({ providedIn: 'root' })
export class PreferencesService {
  private readonly session = inject(SessionStore);
  private readonly meApi = inject(MeApi);
  private readonly theme = inject(ThemeService);
  private readonly language = inject(LanguageService);

  async setTheme(theme: ThemePreference): Promise<void> {
    this.theme.setPreference(theme);
    await this.save({ theme });
  }

  async setUiLanguage(uiLanguage: UiLanguage): Promise<void> {
    await this.language.setLanguage(uiLanguage);
    await this.save({ uiLanguage });
  }

  /** Saves to the profile. Returns false for guests (local-only change). */
  async save(partial: Partial<UpdatePreferencesRequest>): Promise<boolean> {
    const me = this.session.me();
    if (!this.session.isAuthenticated() || !me) return false;
    const body: UpdatePreferencesRequest = {
      uiLanguage: me.uiLanguage,
      articleLanguage: me.articleLanguage,
      theme: me.theme,
      timeZone: me.timeZone || localTimeZone(),
      reminderTime: me.reminderTime,
      ...partial,
    };
    await firstValueFrom(this.meApi.updatePreferences(body));
    this.session.patchMe(body);
    return true;
  }
}
