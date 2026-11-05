import { InlineContent, RDocBlock, RDocBlockType } from './rdoc.models';

/**
 * Highlights (F30) on RDoc text: the block plain text the offsets count in, and the ranges the renderer draws.
 * Offsets are UTF-16 code units in a block's plain text, end exclusive (shared/rdoc/highlight-fixtures.json):
 * `text`, `term` and `mention` nodes give their `text`, a `hardBreak` gives "\n", marks add nothing, and a list's
 * items are joined by one "\n" (each item is its own unit). Callout titles, quote cites, the summary label and list
 * bullets are never part of it.
 */

/** The blocks a reader can highlight; never code, code tabs, tables, steps, images, dividers or embeds. */
export const HIGHLIGHTABLE_BLOCKS: ReadonlySet<RDocBlockType> = new Set<RDocBlockType>([
  'paragraph',
  'heading',
  'bulletList',
  'orderedList',
  'quote',
  'callout',
  'summary',
]);

/** A range drawn in the text: one of yours (`mine` = its id), a popular one (`count` readers), or both. */
export interface TextMark {
  start: number;
  end: number;
  mine: string | null;
  count: number | null;
}

export const NO_MARKS: readonly TextMark[] = [];

/** The plain text of inline content (inline code included). */
export function inlinePlainText(content: InlineContent | undefined): string {
  let text = '';
  for (const node of content ?? []) text += node.type === 'hardBreak' ? '\n' : node.text;
  return text;
}

/** A block's plain text, or null for a block that can't be highlighted. */
export function blockPlainText(block: RDocBlock): string | null {
  switch (block.type) {
    case 'paragraph':
    case 'heading':
    case 'quote':
    case 'callout':
    case 'summary':
      return inlinePlainText(block.content);
    case 'bulletList':
    case 'orderedList':
      return block.items.map(inlinePlainText).join('\n');
    default:
      return null;
  }
}

/** Where each list item's text starts and ends in the list's plain text. */
export function itemRanges(items: readonly InlineContent[]): { start: number; end: number }[] {
  let start = 0;
  return items.map((item) => {
    const end = start + inlinePlainText(item).length;
    const range = { start, end };
    start = end + 1;
    return range;
  });
}

/** A list's marks per item, in offsets from the item's start (a highlight never crosses into the next item). */
export function marksByItem(items: readonly InlineContent[], marks: readonly TextMark[]): (readonly TextMark[])[] {
  const ranges = itemRanges(items);
  if (!marks.length) return ranges.map(() => NO_MARKS);
  return ranges.map(({ start, end }) => {
    const inside = marks
      .filter((m) => m.start < end && m.end > start)
      .map((m) => ({ ...m, start: Math.max(m.start, start) - start, end: Math.min(m.end, end) - start }));
    return inside.length ? inside : NO_MARKS;
  });
}

/** Same ranges, ids and counts (keeps a block from drawing again when another block's marks changed). */
export function sameMarks(a: readonly TextMark[], b: readonly TextMark[]): boolean {
  return a === b || (a.length === b.length && a.every((m, i) => m.start === b[i].start && m.end === b[i].end && m.mine === b[i].mine && m.count === b[i].count));
}

/** A piece of a text run: drawn as a highlight when `mine` or `count` is set. */
export interface MarkedPiece {
  text: string;
  mine: string | null;
  count: number | null;
}

/**
 * Cuts `text`, which starts at `offset` in the marks' plain text, at every mark boundary inside it. Null when no mark
 * touches it (the renderer then draws the text as before). The pieces keep the text's order; nothing is reordered.
 */
export function markPieces(text: string, offset: number, marks: readonly TextMark[]): MarkedPiece[] | null {
  const end = offset + text.length;
  const touching = marks.filter((m) => m.start < end && m.end > offset);
  if (!touching.length) return null;
  const cuts = new Set<number>([offset, end]);
  for (const m of touching) {
    if (m.start > offset) cuts.add(m.start);
    if (m.end < end) cuts.add(m.end);
  }
  const points = [...cuts].sort((a, b) => a - b);
  const pieces: MarkedPiece[] = [];
  for (let i = 0; i < points.length - 1; i++) {
    const [from, to] = [points[i], points[i + 1]];
    const covering = touching.filter((m) => m.start <= from && m.end >= to);
    const mine = covering.find((m) => m.mine !== null)?.mine ?? null;
    const counts = covering.map((m) => m.count).filter((c): c is number => c !== null);
    pieces.push({ text: text.slice(from - offset, to - offset), mine, count: counts.length ? Math.max(...counts) : null });
  }
  return pieces;
}
