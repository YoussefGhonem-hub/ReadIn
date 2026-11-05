import { RDocBlockType } from './rdoc.models';
import { HIGHLIGHTABLE_BLOCKS } from './text-marks';

/**
 * Highlights (F30): a text selection in a rendered RDoc document (`<rd-rdoc>`) → `{ blockId, startOffset, endOffset,
 * text }`, by the contract's rule (docs/api/contract-v1.md → Highlights, shared/rdoc/highlight-fixtures.json):
 * order the two ends; the block (list: the item) where the selection starts decides; a block that can't be
 * highlighted gives nothing; the end is clipped to that block's (item's) text; whitespace at both ends is trimmed;
 * fewer than 3 code units is too short, more than 1,000 too long.
 *
 * Offsets count UTF-16 code units in the block's plain text, read from the DOM the renderer drew: every text node
 * inside the block's `rd-inline` (a list: the item's) plus "\n" for each `<br>` (a hard break). `<bdi>` and marks
 * add no characters; isolate and embedding characters (U+2066–U+2069, U+202A–U+202E) never count, though this
 * renderer inserts none.
 */

export interface HighlightRange {
  blockId: string;
  startOffset: number;
  endOffset: number;
  text: string;
}

export const HIGHLIGHT_MIN = 3;
export const HIGHLIGHT_MAX = 1000;

export type SelectionResult =
  | { kind: 'ok'; range: HighlightRange }
  /** Not in the document, or in a block that can't be highlighted (code, table, steps…): no toolbar. */
  | { kind: 'none' }
  | { kind: 'block_not_allowed' }
  /**
   * Fewer than 3 code units once trimmed: no Highlight. `range` is what is left (null when nothing is): inside one of
   * your highlights it still offers Remove.
   */
  | { kind: 'too_short'; range: HighlightRange | null }
  /** More than 1,000: the toolbar says so instead of offering Highlight. */
  | { kind: 'too_long'; length: number };

const ISOLATES = /[⁦-⁩‪-‮]/g;
const ISOLATE = /^[⁦-⁩‪-‮]$/;

/** U+0009–U+000D, U+0020, U+0085, U+00A0, U+1680, U+2000–U+200A, U+2028, U+2029, U+202F, U+205F, U+3000. */
export function isTrimmedSpace(code: number): boolean {
  return (
    (code >= 0x09 && code <= 0x0d) ||
    code === 0x20 ||
    code === 0x85 ||
    code === 0xa0 ||
    code === 0x1680 ||
    (code >= 0x2000 && code <= 0x200a) ||
    code === 0x2028 ||
    code === 0x2029 ||
    code === 0x202f ||
    code === 0x205f ||
    code === 0x3000
  );
}

/** A rendered string without the isolate and embedding characters a renderer may insert. */
export function withoutIsolates(rendered: string): string {
  return rendered.replace(ISOLATES, '');
}

/** The plain offset of `renderedOffset` in `rendered`: the isolate characters before it don't count. */
export function plainOffsetOf(rendered: string, renderedOffset: number): number {
  return withoutIsolates(rendered.slice(0, renderedOffset)).length;
}

interface TextUnit {
  node: Node;
  /** Its plain text: a text node's data without isolates, "\n" for a `<br>`. */
  text: string;
  start: number;
}

/** The text of one unit of a block: a paragraph's (or heading's, quote's…) `rd-inline`, or one list item's. */
export class TextRoot {
  readonly units: TextUnit[] = [];
  readonly text: string;

  constructor(readonly element: Element) {
    let text = '';
    const doc = element.ownerDocument;
    const walker = doc.createTreeWalker(element, 0x1 | 0x4 /* SHOW_ELEMENT | SHOW_TEXT */);
    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
      const piece = node.nodeType === 3 ? withoutIsolates((node as Text).data) : node.nodeName === 'BR' ? '\n' : null;
      if (piece === null) continue;
      this.units.push({ node, text: piece, start: text.length });
      text += piece;
    }
    this.text = text;
  }

  /** The plain offset of a DOM point: 0 before this root, its length after it. */
  offsetOf(container: Node, offset: number): number {
    const doc = this.element.ownerDocument;
    const span = doc.createRange();
    span.selectNodeContents(this.element);
    const side = comparePoint(span, container, offset);
    if (side < 0) return 0;
    if (side > 0) return this.text.length;
    if (container.nodeType === 3) {
      const unit = this.units.find((u) => u.node === container);
      if (unit) return unit.start + plainOffsetOf((container as Text).data, offset);
    }
    // An element boundary (or a text node that holds nothing of ours): the first unit at or after the point.
    const point = doc.createRange();
    point.setStart(container, offset);
    for (const unit of this.units) {
      if (comparePoint(point, unit.node, 0) >= 0) return unit.start;
    }
    return this.text.length;
  }

  /** The DOM point of a plain offset (the start of the unit it falls in; text node offsets skip isolates). */
  pointOf(offset: number): { node: Node; offset: number } {
    for (const unit of this.units) {
      if (offset > unit.start + unit.text.length) continue;
      if (unit.node.nodeType !== 3) {
        // A <br>: before it, or after it at its end.
        const parent = unit.node.parentNode!;
        const index = Array.prototype.indexOf.call(parent.childNodes, unit.node) as number;
        return { node: parent, offset: offset > unit.start ? index + 1 : index };
      }
      const data = (unit.node as Text).data;
      let rendered = 0;
      for (let plain = unit.start; plain < offset && rendered < data.length; rendered++) if (!ISOLATE.test(data[rendered])) plain++;
      return { node: unit.node, offset: rendered };
    }
    return { node: this.element, offset: this.element.childNodes.length };
  }
}

/** -1 when the point is before the range, 0 inside it, 1 after it (points in other documents count as outside). */
function comparePoint(range: Range, node: Node, offset: number): number {
  try {
    return range.comparePoint(node, offset);
  } catch {
    return 1;
  }
}

/** The blocks of a rendered document, in order. */
export function blockElements(host: Element): HTMLElement[] {
  return [...host.querySelectorAll<HTMLElement>('[data-block-id]')];
}

export function blockTypeOf(block: Element): RDocBlockType {
  return block.getAttribute('data-block-type') as RDocBlockType;
}

/** The text units of a highlightable block: one, or one per list item (`rd-inline` elements, in order). */
export function textRoots(block: Element): TextRoot[] {
  return [...block.querySelectorAll('rd-inline')].map((el) => new TextRoot(el));
}

/** Where a block's plain text starts for each of its roots (list items are joined by one "\n"). */
function rootStarts(roots: TextRoot[]): number[] {
  let start = 0;
  return roots.map((root) => {
    const at = start;
    start += root.text.length + 1;
    return at;
  });
}

/** A block's plain text as drawn (the backend's and the fixtures' `plainText`), or null when it can't be highlighted. */
export function renderedPlainText(block: Element): string | null {
  if (!HIGHLIGHTABLE_BLOCKS.has(blockTypeOf(block))) return null;
  return textRoots(block)
    .map((r) => r.text)
    .join('\n');
}

/** The DOM range of a block's plain-text range (to place the toolbar or to select it in tests). */
export function domRangeOf(block: Element, startOffset: number, endOffset: number): Range | null {
  const roots = textRoots(block);
  const starts = rootStarts(roots);
  let i = -1;
  starts.forEach((s, index) => {
    if (s <= startOffset) i = index;
  });
  if (i < 0) return null;
  const range = block.ownerDocument.createRange();
  const start = roots[i].pointOf(startOffset - starts[i]);
  const end = roots[i].pointOf(Math.min(endOffset - starts[i], roots[i].text.length));
  range.setStart(start.node, start.offset);
  range.setEnd(end.node, end.offset);
  return range;
}

/**
 * The highlight a selection asks for (`range` is the selection's range: its start is always the earlier end, also
 * for a backwards selection). `host` is the rendered document.
 */
export function selectionToHighlight(host: Element, range: Range): SelectionResult {
  const block = startBlock(host, range);
  if (!block) return { kind: 'none' };
  if (!HIGHLIGHTABLE_BLOCKS.has(blockTypeOf(block))) return { kind: 'block_not_allowed' };
  const roots = textRoots(block);
  if (!roots.length) return { kind: 'none' };
  const starts = rootStarts(roots);
  // A list: the item where the selection starts (or the first one it reaches); anything else has one root.
  let index = roots.findIndex((root) => root.element.closest('li')?.contains(range.startContainer));
  if (index < 0) index = Math.max(0, roots.findIndex((root) => range.intersectsNode(root.element)));
  const root = roots[index];

  let start = root.offsetOf(range.startContainer, range.startOffset);
  let end = Math.max(start, root.offsetOf(range.endContainer, range.endOffset));
  const text = root.text;
  while (start < end && isTrimmedSpace(text.charCodeAt(start))) start++;
  while (end > start && isTrimmedSpace(text.charCodeAt(end - 1))) end--;
  const length = end - start;
  const base = starts[index];
  const found: HighlightRange = { blockId: block.getAttribute('data-block-id')!, startOffset: base + start, endOffset: base + end, text: text.slice(start, end) };
  if (length < HIGHLIGHT_MIN) return { kind: 'too_short', range: length > 0 ? found : null };
  if (length > HIGHLIGHT_MAX) return { kind: 'too_long', length };
  return { kind: 'ok', range: found };
}

/** The block the selection starts in; a start between blocks takes the first block the selection reaches. */
function startBlock(host: Element, range: Range): HTMLElement | null {
  const start = range.startContainer;
  const element = start.nodeType === 1 ? (start as Element) : start.parentElement;
  if (!element || !host.contains(element)) return null;
  const inside = element.closest<HTMLElement>('[data-block-id]');
  if (inside && host.contains(inside)) return inside;
  return blockElements(host).find((block) => range.intersectsNode(block)) ?? null;
}
