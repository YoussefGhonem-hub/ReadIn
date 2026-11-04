import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { ArticleLanguage, GlossaryTermDto, GlossaryTermSummaryDto } from './models';

/** Glossary (F21). Anonymous-friendly and silent: the term sheet and the editor's picker render their own states. */
@Injectable({ providedIn: 'root' })
export class GlossaryApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);

  /** `GET /glossary/{slug}?lang=`. `lang` is the version being read; it picks the titles of `articles`. `404 glossary.term_not_found`. */
  term(slug: string, lang: ArticleLanguage): Observable<GlossaryTermDto> {
    return this.http.get<GlossaryTermDto>(`${this.base}/glossary/${encodeURIComponent(slug)}`, {
      params: new HttpParams().set('lang', lang),
      context: new HttpContext().set(SILENT_ERRORS, true),
    });
  }

  /** `GET /glossary?q=&limit=`: matches on the English term or the slug, those starting with `q` first, then A–Z. */
  search(q: string, limit = 8): Observable<GlossaryTermSummaryDto[]> {
    return this.http.get<GlossaryTermSummaryDto[]>(`${this.base}/glossary`, {
      params: new HttpParams().set('q', q).set('limit', limit),
      context: new HttpContext().set(SILENT_ERRORS, true),
    });
  }
}
