import { Editor } from '@tiptap/core';
import { TextSelection } from '@tiptap/pm/state';
import { RDocBlockType } from '../../../shared/rdoc/rdoc.models';
import { BLOCK_MENU, BlockKind, currentBlockDir, filterBlockMenu, insertBlock, setBlockDir } from './block-commands';
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

const LABELS: Record<BlockKind, string> = {
  paragraph: 'نص',
  heading2: 'عنوان',
  heading3: 'عنوان فرعي',
  bulletList: 'قائمة نقط',
  orderedList: 'قائمة مرقّمة',
  steps: 'خطوات',
  quote: 'اقتباس',
  callout: 'ملاحظة',
  code: 'كود',
  codeTabs: 'تابات كود',
  table: 'جدول',
  image: 'صورة',
  divider: 'فاصل',
  embed: 'تضمين',
  summary: 'الخلاصة',
};

describe('block commands (slash menu, toolbar)', () => {
  let editor: Editor;

  // jsdom has no layout: ProseMirror scrolls the selection into view after inserting a block.
  beforeAll(() => {
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
    editor = new Editor({ element, extensions: rdocExtensions(host), content: rdocToEditor({ version: 1, language: 'ar-EG', blocks: [{ id: 'p1', type: 'paragraph', content: [{ type: 'text', text: 'نص' }] }] }) as never });
  });

  afterEach(() => editor.destroy());

  const blocks = () => editorToRDoc(editor.getJSON() as PmNode, 'ar-EG').blocks;

  it('offers every RDoc block type, found by its label or an English or Arabic keyword', () => {
    const types = new Set(BLOCK_MENU.map((item) => item.kind));
    expect(types.size).toBe(15);
    const label = (kind: BlockKind) => LABELS[kind];
    expect(filterBlockMenu('', label)).toHaveLength(15);
    expect(filterBlockMenu('code', label).map((i) => i.kind)).toEqual(['code', 'codeTabs']);
    expect(filterBlockMenu('جدول', label).map((i) => i.kind)).toEqual(['table']);
    expect(filterBlockMenu('tl;dr', label).map((i) => i.kind)).toEqual(['summary']);
    expect(filterBlockMenu('youtube', label).map((i) => i.kind)).toEqual(['embed']);
    expect(filterBlockMenu('zzz', label)).toEqual([]);
  });

  it('turns the current text block into another text block, keeping its text and id', () => {
    editor.commands.setTextSelection(2);
    for (const [kind, type] of [
      ['heading2', 'heading'],
      ['quote', 'quote'],
      ['callout', 'callout'],
      ['summary', 'summary'],
      ['paragraph', 'paragraph'],
    ] as [BlockKind, RDocBlockType][]) {
      insertBlock(editor, kind);
      expect(blocks()).toEqual([expect.objectContaining({ id: 'p1', type, content: [{ type: 'text', text: 'نص' }] })]);
    }
    insertBlock(editor, 'bulletList');
    expect(blocks()).toEqual([{ id: 'p1', type: 'bulletList', items: [[{ type: 'text', text: 'نص' }]] }]);
  });

  it('inserts the other blocks after the current one (or in place of an empty paragraph)', () => {
    const inserted: [BlockKind, RDocBlockType | null][] = [
      ['steps', 'steps'],
      ['code', 'code'],
      ['codeTabs', 'codeTabs'],
      ['table', 'table'],
      ['divider', 'divider'],
    ];
    for (const [kind, type] of inserted) {
      editor.commands.setContent(rdocToEditor({ version: 1, language: 'ar-EG', blocks: [{ id: 'p1', type: 'paragraph', content: [{ type: 'text', text: 'نص' }] }] }) as never);
      editor.view.dispatch(editor.state.tr.setSelection(TextSelection.create(editor.state.doc, 2)));
      insertBlock(editor, kind);
      const result = blocks();
      expect(result[0]).toMatchObject({ id: 'p1', type: 'paragraph' });
      expect(result[1]?.type, kind).toBe(type);
    }
    // An image or embed has nothing to save until it has a picture or a link.
    editor.commands.setContent(rdocToEditor(null) as never);
    insertBlock(editor, 'embed');
    expect(editor.state.doc.firstChild?.type.name).toBe('embed');
    expect(blocks().map((b) => b.type)).toEqual(['paragraph']); // the empty paragraph after it
  });

  it('sets and clears the direction override of the current block', () => {
    editor.commands.setTextSelection(2);
    expect(currentBlockDir(editor)).toBe('auto');
    setBlockDir(editor, 'ltr');
    expect(blocks()[0]).toMatchObject({ dir: 'ltr' });
    setBlockDir(editor, 'auto');
    expect(blocks()[0]).not.toHaveProperty('dir');
  });
});
