import { Injectable, signal } from '@angular/core';
import type { RDocLanguage } from './rdoc.models';

export interface OpenTerm {
  termId: string;
  /** The text tapped in the article. */
  text: string;
  /** The version being read: the glossary answers in it (`?lang=`) and it picks which explanation comes first. */
  language: RDocLanguage;
  /** The article the term was tapped in, left out of "articles that use this term"; null outside an article. */
  articleId: string | null;
}

/**
 * App-wide glossary sheet state (F21). The sheet itself (term-sheet.ts) is mounted once, in app.ts. A file of its own:
 * the app root needs only this, not the RDoc helpers next to it in rdoc-context.ts.
 */
@Injectable({ providedIn: 'root' })
export class TermSheetService {
  readonly openTerm = signal<OpenTerm | null>(null);

  open(term: OpenTerm): void {
    this.openTerm.set(term);
  }

  close(): void {
    this.openTerm.set(null);
  }
}
