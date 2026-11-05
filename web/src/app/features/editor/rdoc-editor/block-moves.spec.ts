import { Editor } from '@tiptap/core';
import { NodeSelection, TextSelection } from '@tiptap/pm/state';
import { RDoc } from '../../../shared/rdoc/rdoc.models';
import { blockIndexById, blockPositions, deleteBlockTr, moveBlockTr, moveSelectedBlock, selectedBlockIndex, setBlockMarks } from './block-moves';
import { RDocEditorHost } from './editor-host';
import { PmNode, editorToRDoc, rdocToEditor } from './rdoc-convert';
import { rdocExtensions } from './rdoc-schema';

const host: RDocEditorHost = {
  t: (key) => key,
  uploadImage: () => Promise.reject('unknown'),
  uploadsChanged: () => undefined,
  resolveAsset: (src) => src,
  fallbackDir: () => 'rtl',
};

const text = (value: string) => [{ type: 'text' as const, text: value }];

/** Every kind of block the handle moves: text, heading, list, table, code, code tabs, callout, divider. */
const DOC: RDoc = {
  version: 1,
  language: 'ar-EG',
  blocks: [
    { id: 'p1', type: 'paragraph', content: text('أول فقرة') },
    { id: 'h1', type: 'heading', level: 2, content: text('عنوان') },
    { id: 'l1', type: 'bulletList', items: [text('نقطة')] },
    { id: 't1', type: 'table', header: [text('A'), text('B'), text('C')], rows: [[text('1'), text('2'), text('3')]] },
    { id: 'c1', type: 'code', lang: 'csharp', code: 'var x = 1;' },
    { id: 'ct', type: 'codeTabs', tabs: [{ label: 'C#', lang: 'csharp', code: 'a' }, { label: 'TS', lang: 'typescript', code: 'b' }] },
    { id: 'co', type: 'callout', variant: 'tip', content: text('نصيحة') },
    { id: 'd1', type: 'divider' },
    { id: 'p2', type: 'paragraph', content: text('آخر فقرة') },
  ],
};

describe('block moves (handle, drag and drop, Alt+Shift+↑/↓)', () => {
  let editor: Editor;

  beforeAll(() => {
    // jsdom has no layout: ProseMirror scrolls the selection into view.
    const rects = () => Object.assign([], { item: () => null }) as unknown as DOMRectList;
    const rect = () => ({ x: 0, y: 0, top: 0, left: 0, right: 0, bottom: 0, width: 0, height: 0, toJSON: () => ({}) }) as DOMRect;
    for (const proto of [Element.prototype, Range.prototype] as { getClientRects?: unknown; getBoundingClientRect?: unknown }[]) {
      proto.getClientRects ??= rects;
      proto.getBoundingClientRect ??= rect;
    }
  });

  beforeEach(() => {
    const element = document.createElement('div');
    document.body.appendChild(element);
    editor = new Editor({ element, extensions: rdocExtensions(host), content: rdocToEditor(DOC) as never });
  });

  afterEach(() => editor.destroy());

  const ids = () => {
    const list: string[] = [];
    editor.state.doc.forEach((node) => list.push(String(node.attrs['id'])));
    return list;
  };
  const index = (id: string) => blockIndexById(editor.state.doc, id);
  const posOf = (id: string) => blockPositions(editor.state.doc)[index(id)];
  const run = (tr: ReturnType<typeof moveBlockTr>) => {
    expect(tr).not.toBeNull();
    editor.view.dispatch(tr!);
  };
  /** Starts a new undo step (the history joins changes made within half a second). */
  const pause = () => vi.advanceTimersByTime(1000);
  const press = (key: 'ArrowUp' | 'ArrowDown') =>
    editor.view.someProp('handleKeyDown', (f) => f(editor.view, new KeyboardEvent('keydown', { key, altKey: true, shiftKey: true, bubbles: true })));

  it('finds blocks by id and by the selection (a selected block itself, not the one after it)', () => {
    expect(index('t1')).toBe(3);
    expect(index('nope')).toBe(-1);
    editor.view.dispatch(editor.state.tr.setSelection(NodeSelection.create(editor.state.doc, posOf('d1'))));
    expect(selectedBlockIndex(editor.state)).toBe(index('d1'));
    editor.view.dispatch(editor.state.tr.setSelection(TextSelection.create(editor.state.doc, posOf('co') + 2)));
    expect(selectedBlockIndex(editor.state)).toBe(index('co'));
  });

  it('moves a block up, down, to the top and to the end, keeping every block whole', () => {
    run(moveBlockTr(editor.state, index('t1'), 0)); // the table to the very top
    expect(ids()).toEqual(['t1', 'p1', 'h1', 'l1', 'c1', 'ct', 'co', 'd1', 'p2']);
    run(moveBlockTr(editor.state, index('p1'), editor.state.doc.childCount)); // the first paragraph to the end
    expect(ids()).toEqual(['t1', 'h1', 'l1', 'c1', 'ct', 'co', 'd1', 'p2', 'p1']);
    run(moveBlockTr(editor.state, index('ct'), index('ct') + 2)); // code tabs one down
    expect(ids()).toEqual(['t1', 'h1', 'l1', 'c1', 'co', 'ct', 'd1', 'p2', 'p1']);

    const rdoc = editorToRDoc(editor.getJSON() as PmNode, 'ar-EG');
    expect(rdoc.blocks[0]).toEqual(DOC.blocks[3]);
    expect(rdoc.blocks.find((b) => b.id === 'ct')).toEqual(DOC.blocks[5]);
    expect(rdoc.blocks).toHaveLength(DOC.blocks.length);
  });

  it('does nothing when the block would stay where it is', () => {
    expect(moveBlockTr(editor.state, 2, 2)).toBeNull();
    expect(moveBlockTr(editor.state, 2, 3)).toBeNull(); // "before the next block" is where it already is
    expect(moveBlockTr(editor.state, -1, 0)).toBeNull();
    expect(moveBlockTr(editor.state, 0, 99)).toBeNull();
  });

  it('carries the cursor (or the selected block) with the moved block', () => {
    const start = posOf('co') + 1;
    editor.view.dispatch(editor.state.tr.setSelection(TextSelection.create(editor.state.doc, start + 2, start + 4)));
    run(moveBlockTr(editor.state, index('co'), 0));
    const moved = posOf('co') + 1;
    expect(editor.state.selection.from).toBe(moved + 2);
    expect(editor.state.selection.to).toBe(moved + 4);

    editor.view.dispatch(editor.state.tr.setSelection(NodeSelection.create(editor.state.doc, posOf('ct'))));
    run(moveBlockTr(editor.state, index('ct'), 1));
    expect(editor.state.selection).toBeInstanceOf(NodeSelection);
    expect((editor.state.selection as NodeSelection).node.attrs['id']).toBe('ct');
  });

  it('is one undo step: undo puts the block back, redo moves it again', () => {
    vi.useFakeTimers();
    try {
      pause();
      run(moveBlockTr(editor.state, index('t1'), 0));
      expect(ids()[0]).toBe('t1');
      editor.commands.undo();
      expect(ids()).toEqual(DOC.blocks.map((b) => b.id));
      editor.commands.redo();
      expect(ids()[0]).toBe('t1');
    } finally {
      vi.useRealTimers();
    }
  });

  it('Alt+Shift+↑ and Alt+Shift+↓ move the block holding the cursor; the keys stay taken at the ends', () => {
    editor.commands.setTextSelection(posOf('l1') + 3); // inside the list item's text
    expect(press('ArrowUp')).toBe(true);
    expect(ids().slice(0, 3)).toEqual(['p1', 'l1', 'h1']);
    expect(press('ArrowUp')).toBe(true);
    expect(ids().slice(0, 3)).toEqual(['l1', 'p1', 'h1']);
    expect(press('ArrowUp')).toBe(true); // already first: nothing moves, nothing else happens
    expect(ids().slice(0, 3)).toEqual(['l1', 'p1', 'h1']);
    expect(selectedBlockIndex(editor.state)).toBe(0);
    expect(press('ArrowDown')).toBe(true);
    expect(ids().slice(0, 3)).toEqual(['p1', 'l1', 'h1']);

    // From inside a table cell, the whole table moves.
    editor.commands.setTextSelection(posOf('t1') + 4);
    expect(moveSelectedBlock(editor, -1)).toBe(true);
    expect(ids().indexOf('t1')).toBe(2);
    editor.commands.setTextSelection(posOf('p2') + 2);
    expect(moveSelectedBlock(editor, 1)).toBe(false); // last block
  });

  it('deletes a whole block; the cursor goes to the block that takes its place', () => {
    editor.commands.setTextSelection(posOf('t1') + 4); // in a table cell
    run(deleteBlockTr(editor.state, index('t1')));
    expect(ids()).toEqual(['p1', 'h1', 'l1', 'c1', 'ct', 'co', 'd1', 'p2']);
    expect(selectedBlockIndex(editor.state)).toBe(index('c1'));

    // Code tabs and a divider go whole too; deleting the last block puts the cursor in the one before.
    run(deleteBlockTr(editor.state, index('ct')));
    run(deleteBlockTr(editor.state, index('d1')));
    editor.commands.setTextSelection(posOf('p2') + 1);
    run(deleteBlockTr(editor.state, index('p2')));
    expect(ids()).toEqual(['p1', 'h1', 'l1', 'c1', 'co']);
    expect(selectedBlockIndex(editor.state)).toBe(index('co'));

    // A cursor in another block stays where it was.
    editor.commands.setTextSelection(posOf('h1') + 2);
    run(deleteBlockTr(editor.state, index('c1')));
    expect(editor.state.selection.$head.parent.attrs['id']).toBe('h1');
  });

  it('deleting the only block leaves an empty paragraph (with a new id); an empty paragraph alone stays', () => {
    editor.commands.setContent(rdocToEditor({ version: 1, language: 'ar-EG', blocks: [DOC.blocks[3]] }) as never);
    run(deleteBlockTr(editor.state, 0));
    const only = editor.state.doc.child(0);
    expect(editor.state.doc.childCount).toBe(1);
    expect(only.type.name).toBe('paragraph');
    expect(only.content.size).toBe(0);
    expect(only.attrs['id']).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(only.attrs['id']).not.toBe('t1');
    expect(editor.state.selection.$head.parent).toBe(only);
    expect(deleteBlockTr(editor.state, 0)).toBeNull();
  });

  it('a delete is one undo step', () => {
    vi.useFakeTimers();
    try {
      pause();
      run(deleteBlockTr(editor.state, index('ct')));
      expect(ids()).not.toContain('ct');
      editor.commands.undo();
      expect(ids()).toEqual(DOC.blocks.map((b) => b.id));
    } finally {
      vi.useRealTimers();
    }
  });

  it('marks the block the handle acts on and the block being dragged, without touching the document', () => {
    const before = editor.state.doc;
    setBlockMarks(editor.view, { target: 't1' });
    setBlockMarks(editor.view, { dragging: 'co' });
    expect(editor.state.doc).toBe(before);
    expect(editor.view.dom.querySelector('[data-block-id="t1"]')?.classList).toContain('rd-ed-handle-target');
    expect(editor.view.dom.querySelector('[data-block-id="co"]')?.classList).toContain('rd-ed-dragging');
    expect(editor.view.dom.querySelector<HTMLElement>('[data-block-id="co"]')?.style.opacity).toBe('0.4');
    setBlockMarks(editor.view, { target: null, dragging: null });
    expect(editor.view.dom.querySelector('.rd-ed-handle-target, .rd-ed-dragging')).toBeNull();
    expect(editor.can().undo()).toBe(false); // nothing in the history
  });
});
