import { Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { firstValueFrom } from 'rxjs';
import { AuthApi } from '../api/auth.api';
import { AuthConfigDto } from '../api/models';
import { DEFAULT_PASSWORD_POLICY } from '../../shared/ui/password/password-rules';
import { DEFAULT_PIN_LENGTH } from '../../shared/ui/pin/pin-rules';

export const DEFAULT_AUTH_CONFIG: AuthConfigDto = { pinLength: DEFAULT_PIN_LENGTH, password: DEFAULT_PASSWORD_POLICY, externalProviders: [] };

/**
 * `GET /auth/config` (PIN length, password rules) for the forms. Starts from the documented defaults, so forms work
 * at once and offline; the API's values replace them as soon as they arrive. Loaded once per page.
 */
@Injectable({ providedIn: 'root' })
export class AuthConfigService {
  private readonly api = inject(AuthApi);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly _config = signal<AuthConfigDto>(DEFAULT_AUTH_CONFIG);
  private loading: Promise<void> | null = null;

  readonly config = this._config.asReadonly();

  load(): Promise<void> {
    if (!this.isBrowser) return Promise.resolve();
    this.loading ??= firstValueFrom(this.api.config()).then(
      (config) => {
        if (config && config.pinLength > 0 && config.password) this._config.set({ ...config, externalProviders: config.externalProviders ?? [] });
      },
      () => {
        this.loading = null; // keep the defaults; try again next time a form opens
      },
    );
    return this.loading;
  }
}
