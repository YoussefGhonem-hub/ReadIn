import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, catchError, from, map, switchMap, throwError, timeout } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { withBlobProblem } from './media.api';
import { ArticleLanguage } from './models';

// ── Quote card (F24), docs/api/contract-v1.md → "Quote card (F24)", ADR 0019 ──

export type QuoteCardTheme = 'light' | 'dark';
export type QuoteCardFormat = 'square' | 'landscape';

/** The F30 selection range (exactly what Highlight sends) plus how to draw it. All 7 fields are required. */
export interface QuoteCardRequest {
  /** The version on screen (`ArticleDetailsDto.language`). */
  language: ArticleLanguage;
  blockId: string;
  /** UTF-16 code units in the block's plain text, end exclusive. */
  startOffset: number;
  endOffset: number;
  /** Exactly the block's plain text between the offsets, trimmed. */
  text: string;
  theme: QuoteCardTheme;
  format: QuoteCardFormat;
}

/** The pixel size of each format (1x). */
export const QUOTE_CARD_SIZE: Record<QuoteCardFormat, { width: number; height: number }> = {
  square: { width: 1080, height: 1080 },
  landscape: { width: 1200, height: 630 },
};

/** `filename` of the response: the name to save under when `filename*` is missing or doesn't decode. */
export const QUOTE_CARD_FALLBACK_FILE_NAME = 'readin-quote.png';

/**
 * How long the call may take: the API waits up to 10 s for a build slot, then draws for up to 20 s; the contract asks
 * for a receive timeout of at least 40 s. Past it the call fails like `quote.failed` (rxjs' `TimeoutError`).
 */
export const QUOTE_CARD_TIMEOUT_MS = 45_000;

export interface QuoteCardImage {
  /** `image/png`. */
  blob: Blob;
  /** `readin-quote-{slug}.png` from `Content-Disposition`, or {@link QUOTE_CARD_FALLBACK_FILE_NAME}. */
  fileName: string;
}

/**
 * Quote cards (F24): `POST /articles/{id}/quote-card` → a PNG drawn by the server and never stored. Guests may call it
 * (the token goes along when signed in). Silent: the quote card dialog shows its own messages. Used only by the lazy
 * quote card dialog, so this client stays out of the initial bundle.
 */
@Injectable({ providedIn: 'root' })
export class QuoteCardApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);

  /**
   * The card of `request` for article `id`. Errors are `ApiError`s with the problem's code (`quote.text_mismatch`,
   * `quote.limit`, `quote.busy`, `quote.failed`, `article.not_found`, …, `network` without a connection); past
   * {@link QUOTE_CARD_TIMEOUT_MS} it fails with rxjs' `TimeoutError` (the request is cancelled).
   */
  card(id: string, request: QuoteCardRequest): Observable<QuoteCardImage> {
    return this.http
      .post(`${this.base}/articles/${encodeURIComponent(id)}/quote-card`, request, {
        responseType: 'blob',
        observe: 'response',
        context: new HttpContext().set(SILENT_ERRORS, true),
      })
      .pipe(
        timeout({ first: QUOTE_CARD_TIMEOUT_MS }),
        map((response) => {
          const body = response.body ?? new Blob([]);
          return {
            blob: body.type === 'image/png' ? body : new Blob([body], { type: 'image/png' }),
            fileName: quoteCardFileName(response.headers.get('Content-Disposition')),
          };
        }),
        catchError((error: unknown) => from(withBlobProblem(error)).pipe(switchMap((e) => throwError(() => e)))),
      );
  }
}

/**
 * The file name from `Content-Disposition`: RFC 5987 `filename*=UTF-8''…` percent-decoded (so Arabic slugs work), else
 * {@link QUOTE_CARD_FALLBACK_FILE_NAME}. Path separators and control characters are dropped; the name always ends in
 * `.png`.
 */
export function quoteCardFileName(contentDisposition: string | null | undefined): string {
  const extended = /(?:^|;)\s*filename\*\s*=\s*"?([^";]+)"?/i.exec(contentDisposition ?? '')?.[1]?.trim();
  const parts = extended ? /^([^']*)'[^']*'(.+)$/.exec(extended) : null;
  if (!parts || parts[1].toLowerCase() !== 'utf-8') return QUOTE_CARD_FALLBACK_FILE_NAME;
  try {
    // eslint-disable-next-line no-control-regex -- control characters are exactly what is removed
    const name = decodeURIComponent(parts[2]).replace(/[\u0000-\u001f\u007f/\\]/g, '').trim();
    return name && name.toLowerCase().endsWith('.png') && name.length > 4 ? name : QUOTE_CARD_FALLBACK_FILE_NAME;
  } catch {
    return QUOTE_CARD_FALLBACK_FILE_NAME;
  }
}
