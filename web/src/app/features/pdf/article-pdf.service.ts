import { DOCUMENT, Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoService } from '@jsverse/transloco';
import { TimeoutError, firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { ArticlePdfApi } from '../../core/api/article-pdf.api';
import { ArticleLanguage, MyArticleDto } from '../../core/api/models';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { ToastService } from '../../shared/ui/toast/toast.service';

/** Answers whose message offers "حاول تاني": the hourly limit, no build slot, a failed build (contract → Article PDF). */
const RETRYABLE = new Set(['article.pdf_limit', 'article.pdf_busy', 'article.pdf_failed']);

/** The object URL lives a little after the click, so every browser has started the download from it. */
const REVOKE_AFTER_MS = 10_000;

/** A failed download as the user sees it. */
export interface PdfFailure {
  message: string;
  /** Shows "حاول تاني" / "Try again", which asks again for the same article and language. */
  retry: boolean;
}

/**
 * The languages "Download PDF" offers for an article in My articles: `MyArticleDto.publishedLanguages` (F33, source
 * language first; two → ask which). An API older than F33 doesn't send it: then the source language.
 */
export function pdfLanguages(article: MyArticleDto): readonly ArticleLanguage[] {
  return article.publishedLanguages?.length ? article.publishedLanguages : [article.language];
}

/**
 * Download article PDF (F33): your own article's published version in one language, built by the API
 * (`GET /articles/{id}/pdf`). Web saves it as a normal browser download under the server's file name
 * (`{slug}-{lang}.pdf`). While an article's file is being built, {@link isBuilding} is true for it (the action shows
 * "بنجهز الـ PDF…" and is disabled) and another download of it does nothing. Failures show a toast, with "حاول تاني"
 * when trying again can help. App-wide, so the reader's "⋯" menu (F28) and My articles share the building state.
 */
@Injectable({ providedIn: 'root' })
export class ArticlePdfService {
  private readonly api = inject(ArticlePdfApi);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly toasts = inject(ToastService);
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  private readonly building = signal<ReadonlySet<string>>(new Set());

  /** True while the article's PDF is being built (reactive). */
  isBuilding(articleId: string): boolean {
    return this.building().has(articleId);
  }

  /**
   * Builds and downloads the PDF of `articleId` in `lang`. Resolves true once the browser got the file; false when it
   * failed (a toast says why) or when that article's PDF is already being built (nothing happens).
   */
  async download(articleId: string, lang: ArticleLanguage): Promise<boolean> {
    if (!this.isBrowser || this.isBuilding(articleId)) return false;
    if (this.document.defaultView?.navigator.onLine === false) {
      this.show(this.offline(), articleId, lang);
      return false;
    }
    this.setBuilding(articleId, true);
    try {
      const file = await firstValueFrom(this.api.pdf(articleId, lang));
      this.save(file.blob, file.fileName);
      return true;
    } catch (error) {
      this.show(this.failureOf(error), articleId, lang);
      return false;
    } finally {
      this.setBuilding(articleId, false);
    }
  }

  /**
   * What a failure says (contract → Article PDF → Errors, the same texts as mobile): `article.pdf_limit` / `pdf_busy` /
   * `pdf_failed` with "حاول تاني"; `article.not_found` → the contract's "المقال مش موجود."; `article.pdf_hidden` and any
   * other known code (a generic `rate_limited` too) with its usual message and no retry; no connection → "محتاج إنترنت…"
   * with retry; `server.error`, a timeout or anything unexpected → "معرفناش نجهّز الـ PDF" with retry.
   */
  failureOf(error: unknown): PdfFailure {
    if (error instanceof TimeoutError || !isApiError(error)) return this.failed();
    if (error.code === 'network') return this.offline();
    if (error.code === 'article.not_found') return { message: this.transloco.translate('pdf.notFound'), retry: false };
    if (RETRYABLE.has(error.code)) return { message: this.errors.forCode(error.code), retry: true };
    if (error.code === 'server.error' || !this.isKnown(error.code)) return this.failed();
    return { message: this.errors.forError(error), retry: false };
  }

  private failed(): PdfFailure {
    return { message: this.errors.forCode('article.pdf_failed'), retry: true };
  }

  private offline(): PdfFailure {
    return { message: this.transloco.translate('pdf.offline'), retry: true };
  }

  /** A code the app has a message for (`errors.{code}`); others count as a failed build. */
  private isKnown(code: string): boolean {
    const key = `errors.${code}`;
    const text: unknown = this.transloco.translate(key);
    return typeof text === 'string' && !!text && text !== key;
  }

  private show(failure: PdfFailure, articleId: string, lang: ArticleLanguage): void {
    const retry = failure.retry ? { label: this.transloco.translate('pdf.retry'), run: () => void this.download(articleId, lang) } : null;
    this.toasts.error(failure.message, retry);
  }

  private setBuilding(articleId: string, on: boolean): void {
    this.building.update((ids) => {
      const next = new Set(ids);
      if (on) next.add(articleId);
      else next.delete(articleId);
      return next;
    });
  }

  /** A normal browser download: an object URL on `<a download="{name}">`, clicked, then revoked. */
  private save(blob: Blob, fileName: string): void {
    const url = URL.createObjectURL(blob);
    const link = this.document.createElement('a');
    link.href = url;
    link.download = fileName;
    link.rel = 'noopener';
    link.style.display = 'none';
    this.document.body.appendChild(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), REVOKE_AFTER_MS);
  }
}
