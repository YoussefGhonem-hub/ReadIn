import { ArticleLanguage, ArticleSourceDto } from '../../core/api/models';
import { InlineContent, ParagraphBlock, RDoc } from '../../shared/rdoc/rdoc.models';
import { safeHttpUrl } from '../../shared/rdoc/rdoc.utils';

export const TITLE_MIN = 5;
export const TITLE_MAX = 150;
/** shared/rdoc/rdoc.schema.json: a text node holds at most 20000 characters. */
const TEXT_NODE_MAX = 20_000;

export interface SourceRow {
  id: number;
  title: string;
  url: string;
}

/**
 * Plain composer text → RDoc (SPEC §13): every blank-line-separated paragraph becomes a `paragraph` block with
 * `dir: "auto"` (each block finds its own direction), single line breaks become `hardBreak` nodes.
 */
export function textToRDoc(text: string, language: ArticleLanguage): RDoc {
  const paragraphs = text
    .replace(/\r\n?/g, '\n')
    .split(/\n\s*\n/)
    .map((p) => p.trim())
    .filter(Boolean);
  const blocks: ParagraphBlock[] = paragraphs.map((paragraph, i) => ({
    id: `p${i + 1}`,
    type: 'paragraph',
    dir: 'auto',
    content: inline(paragraph),
  }));
  return { version: 1, language, blocks };
}

function inline(paragraph: string): InlineContent {
  const content: InlineContent = [];
  paragraph
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .forEach((line, i) => {
      if (i > 0) content.push({ type: 'hardBreak' });
      for (let start = 0; start < line.length; start += TEXT_NODE_MAX) {
        content.push({ type: 'text', text: line.slice(start, start + TEXT_NODE_MAX) });
      }
    });
  return content;
}

export function isTitleValid(title: string): boolean {
  const length = title.trim().length;
  return length >= TITLE_MIN && length <= TITLE_MAX;
}

export function isBlankSource(row: SourceRow): boolean {
  return !row.title.trim() && !row.url.trim();
}

export function isValidSourceUrl(url: string): boolean {
  return !!safeHttpUrl(url.trim());
}

/** A source row is usable when it has a title and an http(s) link; blank rows are ignored. */
export function isCompleteSource(row: SourceRow): boolean {
  return !!row.title.trim() && isValidSourceUrl(row.url);
}

export function sourcesForRequest(rows: readonly SourceRow[]): ArticleSourceDto[] {
  return rows.filter(isCompleteSource).map((row) => ({ title: row.title.trim(), url: row.url.trim() }));
}
