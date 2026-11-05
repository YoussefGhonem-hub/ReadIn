import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import fixtures from '../../../../../shared/rdoc/highlight-fixtures.json';
import { translocoTesting } from '../../../testing/transloco-testing';
import { provideAppIcons } from '../ui/icons';
import { HighlighterService } from './highlighter.service';
import { BlockMarks } from './rdoc-marks';
import { RDocRenderer } from './rdoc-renderer';
import { InlineContent, RDoc, RDocBlock } from './rdoc.models';
import { HIGHLIGHT_MAX, domRangeOf, plainOffsetOf, renderedPlainText, selectionToHighlight, withoutIsolates } from './selection-offsets';
import { TextMark, blockPlainText, inlinePlainText, itemRanges } from './text-marks';

/**
 * F30: the web's selection → `{ blockId, startOffset, endOffset, text }` mapping and the drawn highlights, against the
 * shared fixtures (shared/rdoc/highlight-fixtures.json, owned by the backend; the API and mobile test the same file).
 */

type DocKey = 'ar' | 'en';
interface Position {
  block: string;
  item?: number;
  inline?: number;
  offset: number;
  part?: 'title' | 'cite' | 'code' | 'cell' | 'step';
}
interface Expected {
  blockId: string;
  startOffset: number;
  endOffset: number;
  text: string;
}
interface Selection {
  id: string;
  document: DocKey;
  anchor: Position;
  focus: Position;
  expected: Expected | null;
  reason?: 'too_short' | 'block_not_allowed';
}
interface Fixtures {
  documents: Record<DocKey, RDoc>;
  blocks: Record<DocKey, { blockId: string; type: string; highlightable: boolean; plainText: string | null }[]>;
  selections: Selection[];
  isolateMapping: { cases: { id: string; document: DocKey; blockId: string; rendered: string; renderedStart: number; renderedEnd: number; expected: Expected }[] };
}

const F = fixtures as unknown as Fixtures;

async function render(doc: RDoc, marks: BlockMarks | null = null): Promise<HTMLElement> {
  const fixture = TestBed.createComponent(RDocRenderer);
  fixture.componentRef.setInput('doc', doc);
  fixture.componentRef.setInput('marks', marks);
  await fixture.whenStable();
  return fixture.nativeElement as HTMLElement;
}

const blockEl = (host: HTMLElement, id: string) => host.querySelector<HTMLElement>(`[data-block-id="${id}"]`)!;

/** The text node and offset where a plain offset falls inside `root` (walked here, apart from the code under test). */
function domPoint(root: Element, plain: number): { node: Node; offset: number } {
  const walker = root.ownerDocument.createTreeWalker(root, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT);
  let seen = 0;
  for (let node = walker.nextNode(); node; node = walker.nextNode()) {
    if (node.nodeType === Node.TEXT_NODE) {
      const length = (node as Text).data.length;
      if (plain <= seen + length) return { node, offset: plain - seen };
      seen += length;
    } else if (node.nodeName === 'BR') {
      if (plain === seen) return { node: node.parentNode!, offset: [...node.parentNode!.childNodes].indexOf(node as ChildNode) };
      seen += 1;
    }
  }
  return { node: root, offset: root.childNodes.length };
}

/** A fixture position → a DOM point in the rendered document. */
function pointFor(host: HTMLElement, doc: RDoc, p: Position): { node: Node; offset: number } {
  const block = blockEl(host, p.block);
  if (p.part) {
    const selector = { title: 'strong', cite: 'cite rd-bdi-text', code: 'code, pre', cell: 'td', step: '.rd-step-title' }[p.part];
    const el = block.querySelector(selector) ?? block;
    const text = el.ownerDocument.createTreeWalker(el, NodeFilter.SHOW_TEXT).nextNode() as Text;
    return { node: text, offset: Math.min(p.offset, text.data.length) };
  }
  const model = doc.blocks.find((b) => b.id === p.block)!;
  const content = contentOf(model, p.item);
  const before = inlinePlainText(content.slice(0, p.inline));
  const roots = block.querySelectorAll('rd-inline');
  return domPoint(roots[p.item ?? 0], before.length + p.offset);
}

function contentOf(block: RDocBlock, item?: number): InlineContent {
  if (block.type === 'bulletList' || block.type === 'orderedList') return block.items[item ?? 0];
  return 'content' in block ? (block.content as InlineContent) : [];
}

function select(host: HTMLElement, doc: RDoc, s: Selection): Range {
  const anchor = pointFor(host, doc, s.anchor);
  const focus = pointFor(host, doc, s.focus);
  const selection = document.getSelection()!;
  selection.setBaseAndExtent(anchor.node, anchor.offset, focus.node, focus.offset);
  return selection.getRangeAt(0);
}

describe('Highlight offsets (shared/rdoc/highlight-fixtures.json)', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [translocoTesting()],
      providers: [provideRouter([]), provideAppIcons(), { provide: HighlighterService, useValue: { highlight: () => Promise.resolve(null) } }],
    });
  });
  afterEach(() => document.getSelection()?.removeAllRanges());

  for (const key of ['ar', 'en'] as const) {
    it(`draws every block's plain text exactly as the fixtures (${key}), and the model agrees`, async () => {
      const doc = F.documents[key];
      const host = await render(doc);
      for (const expected of F.blocks[key]) {
        expect(renderedPlainText(blockEl(host, expected.blockId)), expected.blockId).toBe(expected.plainText);
        expect(blockPlainText(doc.blocks.find((b) => b.id === expected.blockId)!), expected.blockId).toBe(expected.plainText);
      }
    });
  }

  for (const s of F.selections) {
    it(`selection ${s.id}`, async () => {
      const doc = F.documents[s.document];
      const host = await render(doc);
      const result = selectionToHighlight(host, select(host, doc, s));
      if (s.expected) {
        expect(result).toEqual({ kind: 'ok', range: s.expected });
      } else {
        expect(result.kind).toBe(s.reason);
      }
    });
  }

  it('maps rendered offsets past the isolates a renderer inserts (isolateMapping)', () => {
    for (const c of F.isolateMapping.cases) {
      const plain = withoutIsolates(c.rendered);
      expect(plain, c.id).toBe(F.blocks[c.document].find((b) => b.blockId === c.blockId)!.plainText);
      const start = plainOffsetOf(c.rendered, c.renderedStart);
      const end = plainOffsetOf(c.rendered, c.renderedEnd);
      const trimmed = plain.slice(start, end);
      expect({ blockId: c.blockId, startOffset: start, endOffset: end, text: trimmed }, c.id).toEqual(c.expected);
    }
  });

  it('an element boundary (a triple click) starts at the block and ends at the next one', async () => {
    const doc = F.documents.ar;
    const host = await render(doc);
    const range = document.createRange();
    range.setStart(blockEl(host, 'p4'), 0);
    range.setEnd(host, host.childNodes.length);
    const text = F.blocks.ar.find((b) => b.blockId === 'p4')!.plainText!;
    expect(selectionToHighlight(host, range)).toEqual({ kind: 'ok', range: { blockId: 'p4', startOffset: 0, endOffset: text.length, text } });
  });

  it('a selection outside the document, or over 1,000 characters, gets no Highlight', async () => {
    const long = 'كلام كتير '.repeat(110);
    const doc: RDoc = { version: 1, language: 'ar-EG', blocks: [{ id: 'long', type: 'paragraph', content: [{ type: 'text', text: long }] }] };
    const host = await render(doc);
    const outside = document.createRange();
    outside.selectNodeContents(document.body);
    expect(selectionToHighlight(host.querySelector('[data-block-id]')!, outside).kind).toBe('none');
    const all = document.createRange();
    all.selectNodeContents(host);
    expect(selectionToHighlight(host, all)).toEqual({ kind: 'too_long', length: long.trimEnd().length });
    expect(long.trimEnd().length).toBeGreaterThan(HIGHLIGHT_MAX);
  });

  describe('drawn highlights never break mixed text (SPEC §14)', () => {
    /**
     * Every expected range of the fixtures: as one of yours when it overlaps none of yours drawn before (yours never
     * overlap), else as a popular one; every other one is popular too.
     */
    function marksOf(key: DocKey): { marks: BlockMarks; mine: Selection[] } {
      const map = new Map<string, TextMark[]>();
      const mine: Selection[] = [];
      F.selections
        .filter((s) => s.document === key && s.expected)
        .forEach((s, i) => {
          const e = s.expected!;
          const list = map.get(e.blockId) ?? [];
          const free = !list.some((m) => m.mine !== null && m.start < e.endOffset && m.end > e.startOffset);
          if (free) mine.push(s);
          list.push({ start: e.startOffset, end: e.endOffset, mine: free ? s.id : null, count: !free || i % 2 === 0 ? 3 + i : null });
          map.set(e.blockId, list);
        });
      return { marks: map, mine };
    }

    const bdiTexts = (host: HTMLElement) => [...host.querySelectorAll('bdi')].map((b) => b.textContent);

    for (const key of ['ar', 'en'] as const) {
      it(`keeps the text, its order and every isolated run whole (${key})`, async () => {
        const doc = F.documents[key];
        const plain = await render(doc);
        const plainRuns = bdiTexts(plain);
        const plainText = plain.textContent;
        const { marks, mine } = marksOf(key);
        const host = await render(doc, marks);

        expect(host.textContent).toBe(plainText);
        expect(bdiTexts(host)).toEqual(plainRuns);
        for (const expected of F.blocks[key]) expect(renderedPlainText(blockEl(host, expected.blockId))).toBe(expected.plainText);
        // The marks are plain spans: no direction of their own, nothing isolated or embedded.
        const spans = [...host.querySelectorAll('span.rd-hl')];
        expect(spans.length).toBeGreaterThan(0);
        for (const span of spans) {
          expect(span.getAttribute('dir')).toBeNull();
          expect(span.querySelector('bdi')).toBeNull();
        }
        // Each of yours is drawn over exactly its text (a hard break is a <br>), and each popular one carries its count.
        expect(mine.length).toBeGreaterThan(3);
        for (const s of mine) {
          const drawn = [...host.querySelectorAll(`[data-hl-mine="${s.id}"]`)].map((el) => el.textContent).join('');
          expect(drawn, s.id).toBe(s.expected!.text.replace(/\n/g, ''));
        }
        for (const [blockId, list] of marks) {
          for (const mark of list.filter((m) => m.count !== null && m.mine === null)) {
            const block = blockEl(host, blockId);
            const counted = [...block.querySelectorAll(`[data-hl-count="${mark.count}"]`)].map((el) => el.textContent).join('');
            expect(counted.length, `${blockId} ${mark.start}`).toBeGreaterThan(0);
          }
        }
        // Selections still map the same way over the drawn marks.
        for (const s of F.selections.filter((x) => x.document === key)) {
          const result = selectionToHighlight(host, select(host, doc, s));
          if (s.expected) expect(result, s.id).toEqual({ kind: 'ok', range: s.expected });
          else expect(result.kind, s.id).toBe(s.reason);
        }
      });
    }

    it('a range drawn over a bold English run inside Arabic stays inside its <bdi>', async () => {
      const doc = F.documents.ar;
      const host = await render(doc, new Map([['p1', [{ start: 19, end: 27, mine: 'h1', count: null }]]]));
      const span = blockEl(host, 'p1').querySelector('[data-hl-mine="h1"]')!;
      expect(span.textContent).toBe('NET Core');
      expect(span.closest('bdi')?.textContent).toBe('ASP.NET Core');
      expect(span.closest('strong')).not.toBeNull();
    });

    it('list items get their own part of a list mark, and the DOM range of a mark is its text', async () => {
      const doc = F.documents.ar;
      const list = doc.blocks.find((b) => b.id === 'l1')!;
      expect(itemRanges(list.type === 'bulletList' ? list.items : [])).toEqual([
        { start: 0, end: 31 },
        { start: 32, end: 63 },
        { start: 64, end: 99 },
      ]);
      const host = await render(doc, new Map([['l1', [{ start: 39, end: 63, mine: 'h2', count: null }]]]));
      const items = blockEl(host, 'l1').querySelectorAll('li');
      // Two pieces: the isolated English run and, outside it, " 💉".
      const pieces = [...items[1].querySelectorAll('[data-hl-mine="h2"]')];
      expect(pieces.map((p) => p.textContent)).toEqual(['constructor injection', ' 💉']);
      expect(pieces[0].parentElement?.tagName).toBe('BDI');
      expect(items[0].querySelector('.rd-hl')).toBeNull();
      expect(domRangeOf(blockEl(host, 'l1'), 39, 63)?.toString()).toBe('constructor injection 💉');
      expect(domRangeOf(blockEl(host, 'p3'), 16, 27)?.toString()).toBe('مُهِمّ جداً');
    });
  });
});
