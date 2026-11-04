import { Injectable, inject } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { GlossaryApi } from '../../core/api/glossary.api';
import { ArticleLanguage, GlossaryTermDto } from '../../core/api/models';

/**
 * Glossary terms already looked up in this session (F21), so tapping a term again asks nothing. A term that isn't in
 * the glossary (`404`) is remembered too; failures are not, so "try again" asks again.
 */
@Injectable({ providedIn: 'root' })
export class GlossaryStore {
  private readonly api = inject(GlossaryApi);
  /** By language and slug; null: not in the glossary. */
  private readonly terms = new Map<string, GlossaryTermDto | null>();
  private readonly pending = new Map<string, Promise<GlossaryTermDto | null>>();

  /** Resolves null for `404 glossary.term_not_found`; rejects with the ApiError of any other failure. */
  term(slug: string, lang: ArticleLanguage): Promise<GlossaryTermDto | null> {
    const key = `${lang}|${slug}`;
    if (this.terms.has(key)) return Promise.resolve(this.terms.get(key) ?? null);
    let request = this.pending.get(key);
    if (!request) {
      request = firstValueFrom(this.api.term(slug, lang))
        .catch((error: unknown) => {
          if (isApiError(error) && error.status === 404) return null;
          throw error;
        })
        .then((term) => {
          this.terms.set(key, term);
          return term;
        })
        .finally(() => this.pending.delete(key));
      this.pending.set(key, request);
    }
    return request;
  }
}
