import type { ArticleLanguage } from '../../core/api/models';
import type { HighlightRange } from '../../shared/rdoc/selection-offsets';

/**
 * Quote card (F24): the small part the reader's selection toolbar needs (the article chunk). The dialog itself, its API
 * client and its icons are a lazy chunk (quote-card-dialog.ts), loaded on the first **Share quote**.
 */

/** Fewer code units than this (after trimming) offer no **Share quote** (the same as Highlight). */
export const QUOTE_MIN = 3;
/** More than this is refused before any call: the toolbar says `quote.too_long` (contract → Quote card (F24)). */
export const QUOTE_MAX = 400;

/** The article version a quote is shared from: null while quotes can't be shared from it (hidden by moderators). */
export interface QuoteCardArticle {
  id: string;
  /** The version on screen (`ArticleDetailsDto.language`). */
  language: ArticleLanguage;
  /** Its web link, `{siteUrl}/{ar|en}/a/{slug}` (F24): Copy link and the text shared with the card. */
  url: string;
}

/** What the dialog draws: an article version and the F30 selection range in it. */
export interface QuoteCardSource {
  article: QuoteCardArticle;
  range: HighlightRange;
}

/** What **Share quote** offers for a selection: the range, or `too_long` (said without calling), or nothing. */
export function quoteOffer(range: HighlightRange | null, tooLongForHighlight: boolean): HighlightRange | 'too_long' | null {
  if (tooLongForHighlight) return 'too_long';
  if (!range) return null;
  const length = range.endOffset - range.startOffset;
  if (length < QUOTE_MIN) return null;
  return length > QUOTE_MAX ? 'too_long' : range;
}
