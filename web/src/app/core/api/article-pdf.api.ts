import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, catchError, from, map, switchMap, throwError, timeout } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { withBlobProblem } from './media.api';
import { ArticleLanguage } from './models';

/** `filename` of the response: the name to save under when `filename*` is missing or doesn't decode. */
export const PDF_FALLBACK_FILE_NAME = 'readin-article.pdf';

/**
 * How long the call may take: the API waits up to 30 s for a build slot, then builds for up to 60 s, so the client
 * waits longer than that (contract: at least 100 s). Past it the call fails like `article.pdf_failed`.
 */
export const PDF_TIMEOUT_MS = 120_000;

export interface ArticlePdfFile {
  blob: Blob;
  /** `{slug}-{lang}.pdf` from `Content-Disposition`, or {@link PDF_FALLBACK_FILE_NAME}. */
  fileName: string;
}

/**
 * Article PDF (F33, permission `articles.export_pdf`): any published article you can open, and your own archived one.
 * The API builds the file in the request and never stores it. Silent: the download action shows its own messages.
 */
@Injectable({ providedIn: 'root' })
export class ArticlePdfApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);

  /**
   * `GET /articles/{id}/pdf?lang=` → the published version in `lang`. Errors are `ApiError`s with the problem's code
   * (`article.not_found`, `article.pdf_hidden`, `article.pdf_limit`, `article.pdf_busy`, `article.pdf_failed`, …);
   * past {@link PDF_TIMEOUT_MS} it fails with rxjs' `TimeoutError` (the request is cancelled).
   */
  pdf(id: string, lang: ArticleLanguage): Observable<ArticlePdfFile> {
    return this.http
      .get(`${this.base}/articles/${encodeURIComponent(id)}/pdf`, {
        params: new HttpParams().set('lang', lang),
        responseType: 'blob',
        observe: 'response',
        context: new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true),
      })
      .pipe(
        timeout({ first: PDF_TIMEOUT_MS }),
        map((response) => {
          const body = response.body ?? new Blob([]);
          return {
            blob: body.type === 'application/pdf' ? body : new Blob([body], { type: 'application/pdf' }),
            fileName: pdfFileName(response.headers.get('Content-Disposition')),
          };
        }),
        catchError((error: unknown) => from(withBlobProblem(error)).pipe(switchMap((e) => throwError(() => e)))),
      );
  }
}

/**
 * The file name from `Content-Disposition`: RFC 5987 `filename*=UTF-8''…` percent-decoded (so Arabic slugs work), else
 * {@link PDF_FALLBACK_FILE_NAME}. Path separators and control characters are dropped.
 */
export function pdfFileName(contentDisposition: string | null | undefined): string {
  const extended = /(?:^|;)\s*filename\*\s*=\s*"?([^";]+)"?/i.exec(contentDisposition ?? '')?.[1]?.trim();
  const parts = extended ? /^([^']*)'[^']*'(.+)$/.exec(extended) : null;
  if (!parts || parts[1].toLowerCase() !== 'utf-8') return PDF_FALLBACK_FILE_NAME;
  try {
    // eslint-disable-next-line no-control-regex -- control characters are exactly what is removed
    const name = decodeURIComponent(parts[2]).replace(/[\u0000-\u001f\u007f/\\]/g, '').trim();
    return name && name !== '.pdf' ? name : PDF_FALLBACK_FILE_NAME;
  } catch {
    return PDF_FALLBACK_FILE_NAME;
  }
}
