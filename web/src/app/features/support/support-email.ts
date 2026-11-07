import { HttpClient, HttpContext } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { firstValueFrom } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from '../../core/api/api.config';
import type { SupportConfigDto } from '../../core/api/models';
import { environment } from '../../../environments/environment';

/**
 * "To appeal, write to {email}" (F35): a suspended account can't sign in, so the suspension message carries the support
 * email from `GET /support/config` (or this build's address when the API can't answer; nothing when the API has none).
 * Calls HttpClient itself, so the sign-in chunk doesn't load the support API.
 */
@Component({
  selector: 'rd-support-email',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-support-email-note': '' },
  template: `
    @if (email(); as address) {
      <p class="m-0 text-sm">
        {{ 'support.appeal' | transloco }}
        <a [href]="'mailto:' + address" class="font-semibold text-link" dir="ltr" data-appeal-email>{{ address }}</a>
      </p>
    }
  `,
})
export class SupportEmail {
  protected readonly email = signal<string | null>(null);

  constructor() {
    const http = inject(HttpClient);
    const url = `${inject(API_BASE_URL)}/support/config`;
    void firstValueFrom(http.get<SupportConfigDto>(url, { context: new HttpContext().set(SILENT_ERRORS, true) })).then(
      (config) => this.email.set(config.email),
      () => this.email.set(environment.supportEmail || null),
    );
  }
}
