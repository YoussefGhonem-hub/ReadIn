import { DOCUMENT, Injectable, PLATFORM_ID, REQUEST, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

const ONE_YEAR_SECONDS = 60 * 60 * 24 * 365;

/** SSR-safe cookie access: reads the incoming request's `Cookie` header on the server, `document.cookie` in the browser. */
@Injectable({ providedIn: 'root' })
export class CookieService {
  private readonly document = inject(DOCUMENT);
  private readonly request = inject(REQUEST, { optional: true });
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  get(name: string): string | null {
    const source = this.isBrowser ? this.document.cookie : (this.request?.headers.get('cookie') ?? '');
    for (const part of source.split(';')) {
      const [key, ...rest] = part.trim().split('=');
      if (key === name) return decodeURIComponent(rest.join('='));
    }
    return null;
  }

  set(name: string, value: string, maxAgeSeconds = ONE_YEAR_SECONDS): void {
    if (!this.isBrowser) return;
    const secure = this.document.location?.protocol === 'https:' ? '; Secure' : '';
    this.document.cookie = `${name}=${encodeURIComponent(value)}; Path=/; Max-Age=${maxAgeSeconds}; SameSite=Lax${secure}`;
  }
}
