import { Injectable, Signal, computed, inject, signal } from '@angular/core';
import { environment } from '../../../environments/environment';
import { TextDir } from '../directives/bidi';
import { RDoc, RDocLanguage } from './rdoc.models';
import { languageDir } from './rdoc.utils';

export interface OpenTerm {
  termId: string;
  /** The text tapped in the article. */
  text: string;
  /** The version being read: the glossary answers in it (`?lang=`) and it picks which explanation comes first. */
  language: RDocLanguage;
  /** The article the term was tapped in, left out of "articles that use this term"; null outside an article. */
  articleId: string | null;
}

/** App-wide glossary sheet state (F21). The sheet itself (term-sheet.ts) is mounted once, in app.ts. */
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

/** Per-document context shared by the block components of one `<rd-rdoc>`. */
@Injectable()
export class RDocContext {
  private readonly terms = inject(TermSheetService);
  private doc: Signal<RDoc | null | undefined> = signal(null);
  private articleId: Signal<string | null> = signal(null);
  private embedsLinks: Signal<boolean> = signal(false);

  /** Direction used when a block has no strong characters: the article language's direction. */
  readonly fallbackDir = computed<TextDir>(() => languageDir(this.doc()?.language ?? 'ar-EG'));

  bind(doc: Signal<RDoc | null | undefined>, articleId: Signal<string | null> = signal(null), embedsAsLinks: Signal<boolean> = signal(false)): void {
    this.doc = doc;
    this.articleId = articleId;
    this.embedsLinks = embedsAsLinks;
  }

  /** Embeds show as a link, never a player (a post card's preview, F34). */
  embedsAsLinks(): boolean {
    return this.embedsLinks();
  }

  /** `rdoc-asset://path` → Firebase Storage URL; https URLs pass through; anything else is dropped. */
  resolveAsset(src: string | undefined): string | null {
    if (!src) return null;
    if (src.startsWith('rdoc-asset://')) return `${environment.assetsBaseUrl}/${src.slice('rdoc-asset://'.length)}`;
    return /^https:\/\//i.test(src) ? src : null;
  }

  openTerm(termId: string, text: string): void {
    this.terms.open({ termId, text, language: this.doc()?.language ?? 'ar-EG', articleId: this.articleId() });
  }
}
