import { Injectable, Signal, computed, inject, signal } from '@angular/core';
import { environment } from '../../../environments/environment';
import { TextDir } from '../directives/bidi';
import { RDoc } from './rdoc.models';
import { languageDir } from './rdoc.utils';
import { TermSheetService } from './term-sheet.service';

export { TermSheetService, type OpenTerm } from './term-sheet.service';

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
