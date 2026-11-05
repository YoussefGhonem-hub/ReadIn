import { Editor, Range } from '@tiptap/core';
import { Node as PmNodeType } from '@tiptap/pm/model';
import { EditorState, NodeSelection, TextSelection } from '@tiptap/pm/state';
import { TableMap } from '@tiptap/pm/tables';
import { BlockDir, CalloutVariant } from '../../../shared/rdoc/rdoc.models';
import { AppIconName } from '../../../shared/ui/icons';
import { openPickerForNextImage } from './node-views';
import { PLAIN_CODE_LANG, codeLanguageName } from './rdoc-convert';
import { currentTopBlock } from './rdoc-schema';

export type BlockKind =
  | 'paragraph'
  | 'heading2'
  | 'heading3'
  | 'bulletList'
  | 'orderedList'
  | 'steps'
  | 'quote'
  | 'callout'
  | 'code'
  | 'codeTabs'
  | 'table'
  | 'image'
  | 'divider'
  | 'embed'
  | 'summary';

export interface BlockMenuItem {
  kind: BlockKind;
  /** `editor.blocks.menu.{kind}` (label) and `editor.blocks.menu.{kind}Hint`. */
  icon: AppIconName | EditorIconName;
  /** Extra words that find the item in the slash menu (English and Arabic). */
  keywords: string;
}

/** Icons only the editor uses: registered for the editor route, never in the initial bundle. */
export type EditorIconName =
  | 'Pilcrow'
  | 'Heading2'
  | 'Heading3'
  | 'List'
  | 'ListOrdered'
  | 'ListChecks'
  | 'Quote'
  | 'MessageSquareWarning'
  | 'SquareCode'
  | 'Table'
  | 'Image'
  | 'Minus'
  | 'SquarePlay'
  | 'NotebookText';

/** Every RDoc block type (SPEC §13.2), in slash-menu order. */
export const BLOCK_MENU: readonly BlockMenuItem[] = [
  { kind: 'paragraph', icon: 'Pilcrow', keywords: 'text paragraph نص فقرة' },
  { kind: 'heading2', icon: 'Heading2', keywords: 'h2 heading title عنوان' },
  { kind: 'heading3', icon: 'Heading3', keywords: 'h3 heading subheading عنوان فرعي' },
  { kind: 'bulletList', icon: 'List', keywords: 'bullet list unordered قائمة نقط' },
  { kind: 'orderedList', icon: 'ListOrdered', keywords: 'numbered ordered list قائمة مرقمة' },
  { kind: 'steps', icon: 'ListChecks', keywords: 'steps how to guide خطوات' },
  { kind: 'quote', icon: 'Quote', keywords: 'quote blockquote citation اقتباس' },
  { kind: 'callout', icon: 'MessageSquareWarning', keywords: 'callout tip info warning danger note ملاحظة نصيحة تحذير' },
  { kind: 'code', icon: 'SquareCode', keywords: 'code snippet كود' },
  { kind: 'codeTabs', icon: 'CodeXml', keywords: 'code tabs languages تابات كود' },
  { kind: 'table', icon: 'Table', keywords: 'table grid comparison جدول مقارنة' },
  { kind: 'image', icon: 'Image', keywords: 'image picture photo diagram صورة' },
  { kind: 'divider', icon: 'Minus', keywords: 'divider separator line hr فاصل' },
  { kind: 'embed', icon: 'SquarePlay', keywords: 'embed youtube video gist github فيديو' },
  { kind: 'summary', icon: 'NotebookText', keywords: 'summary tldr tl;dr خلاصة ملخص' },
];

/** Slash-menu filter: matches the translated label and the keywords, ignoring case. */
export function filterBlockMenu(query: string, label: (kind: BlockKind) => string): BlockMenuItem[] {
  const q = query.trim().toLowerCase();
  if (!q) return [...BLOCK_MENU];
  return BLOCK_MENU.filter((item) => `${label(item.kind)} ${item.keywords} ${item.kind}`.toLowerCase().includes(q));
}

const TEXTBLOCKS = new Set(['paragraph', 'heading', 'quote', 'callout', 'summary']);

/** A new table's size: columns, and body rows under the header row. */
export interface TableSize {
  cols: number;
  rows: number;
}

/** The size picker's grid (Insert → Table): 2 to 6 columns and 1 to 8 rows under the header; 2 × 2 at first. */
export const TABLE_PICKER = { minCols: 2, maxCols: 6, minRows: 1, maxRows: 8, initial: { cols: 2, rows: 2 } } as const;
/** shared/rdoc/rdoc.schema.json: a table has 1 to 12 columns and at most 200 rows under the header. */
export const TABLE_MAX_COLS = 12;
export const TABLE_MAX_ROWS = 200;

/**
 * Inserts a block of `kind` (slash menu, toolbar). Text blocks convert the current block in place, keeping its text
 * and id; lists wrap it; other blocks replace an empty paragraph or go after the current block. `range` is the typed
 * `/query`, removed first. A table is 2 × 2 here; {@link insertTable} picks the size.
 */
export function insertBlock(editor: Editor, kind: BlockKind, range?: Range, callout: CalloutVariant = 'tip'): boolean {
  if (range) editor.chain().focus().deleteRange(range).run();
  const top = currentTopBlock(editor);
  if (!top) return false;
  const { schema } = editor.state;

  const convert = (typeName: string, attrs: Record<string, unknown> = {}) => {
    if (!TEXTBLOCKS.has(top.node.type.name)) return insert(schema.nodes[typeName].create(attrs));
    const tr = editor.state.tr.setNodeMarkup(top.pos, schema.nodes[typeName], { ...attrs, id: top.node.attrs['id'], dir: top.node.attrs['dir'] ?? null });
    editor.view.dispatch(tr.scrollIntoView());
    editor.view.focus();
    return true;
  };

  const insert = (node: PmNodeType, select: 'inside' | 'node' = 'inside') => insertAfter(editor, top, node, select);

  switch (kind) {
    case 'paragraph':
      return convert('paragraph');
    case 'heading2':
    case 'heading3':
      return convert('heading', { level: kind === 'heading2' ? 2 : 3 });
    case 'quote':
      return convert('quote');
    case 'callout':
      return convert('callout', { variant: callout });
    case 'summary':
      return convert('summary');
    case 'bulletList':
    case 'orderedList': {
      const chain = editor.chain().focus();
      if (top.node.type.name === 'paragraph' || top.node.type.name === 'bulletList' || top.node.type.name === 'orderedList') {
        return kind === 'bulletList' ? chain.toggleBulletList().run() : chain.toggleOrderedList().run();
      }
      return insert(schema.nodes[kind].create(null, schema.nodes['listItem'].create(null, schema.nodes['paragraph'].create())));
    }
    case 'steps':
      return insert(
        schema.nodes['steps'].create(null, schema.nodes['stepItem'].create(null, [schema.nodes['stepTitle'].create(), schema.nodes['paragraph'].create()])),
      );
    case 'code':
      return insert(schema.nodes['codeBlock'].create({ language: PLAIN_CODE_LANG }));
    case 'codeTabs':
      return insert(
        schema.nodes['codeTabs'].create({
          tabs: [
            { label: codeLanguageName('csharp'), lang: 'csharp', code: '' },
            { label: codeLanguageName('typescript'), lang: 'typescript', code: '' },
          ],
        }),
        'node',
      );
    case 'table':
      return insert(tableNode(editor, TABLE_PICKER.initial));
    case 'image':
      openPickerForNextImage();
      return insert(schema.nodes['image'].create({ alt: '' }), 'node');
    case 'divider':
      return insert(schema.nodes['horizontalRule'].create(), 'node');
    case 'embed': {
      const done = insert(schema.nodes['embed'].create({ provider: 'youtube', url: '' }), 'node');
      queueMicrotask(() => editor.view.dom.querySelector<HTMLInputElement>('.ProseMirror-selectednode [data-embed-url]')?.focus());
      return done;
    }
  }
}

/** Puts `node` in place of the current block if it is an empty paragraph, or after it; selects it or its start. */
function insertAfter(editor: Editor, top: { node: PmNodeType; pos: number }, node: PmNodeType, select: 'inside' | 'node'): boolean {
  const { tr, schema } = editor.state;
  const isEmptyParagraph = top.node.type.name === 'paragraph' && top.node.content.size === 0;
  const from = isEmptyParagraph ? top.pos : top.pos + top.node.nodeSize;
  if (isEmptyParagraph) tr.replaceWith(from, from + top.node.nodeSize, node);
  else tr.insert(from, node);
  const end = from + node.nodeSize;
  // Something to type into after a block that is not text.
  if (node.isAtom && end >= tr.doc.content.size) tr.insert(end, schema.nodes['paragraph'].create());
  if (select === 'node') tr.setSelection(NodeSelection.create(tr.doc, from));
  else tr.setSelection(TextSelection.near(tr.doc.resolve(from + 1)));
  editor.view.dispatch(tr.scrollIntoView());
  editor.view.focus();
  return true;
}

/** A table of `size` (kept within the RDoc limits): a header row and `rows` rows, every cell an empty paragraph. */
function tableNode(editor: Editor, size: TableSize): PmNodeType {
  const { schema } = editor.state;
  const cols = clamp(Math.round(size.cols), 1, TABLE_MAX_COLS);
  const rows = clamp(Math.round(size.rows), 0, TABLE_MAX_ROWS);
  const cell = (type: string) => schema.nodes[type].create(null, schema.nodes['paragraph'].create());
  const row = (type: string) => schema.nodes['tableRow'].create(null, Array.from({ length: cols }, () => cell(type)));
  return schema.nodes['table'].create(null, [row('tableHeader'), ...Array.from({ length: rows }, () => row('tableCell'))]);
}

/** Inserts a table of `size` columns × rows (plus the header row), with the cursor in its first header cell. */
export function insertTable(editor: Editor, size: TableSize, range?: Range): boolean {
  if (range) editor.chain().focus().deleteRange(range).run();
  const top = currentTopBlock(editor);
  if (!top) return false;
  return insertAfter(editor, top, tableNode(editor, size), 'inside');
}

/** Columns, and rows under the header, of the table holding the selection; null outside a table. */
export function tableShape(state: EditorState): TableSize | null {
  const { $head } = state.selection;
  for (let depth = $head.depth; depth > 0; depth--) {
    const node = $head.node(depth);
    if (node.type.name === 'table') {
      const map = TableMap.get(node);
      return { cols: map.width, rows: Math.max(0, map.height - 1) };
    }
  }
  return null;
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, Number.isFinite(value) ? value : min));
}

/** Sets the manual direction override of the current top-level block (`auto` clears it). Code stays LTR. */
export function setBlockDir(editor: Editor, dir: BlockDir): boolean {
  const top = currentTopBlock(editor);
  if (!top || !('dir' in top.node.attrs)) return false;
  editor.view.dispatch(editor.state.tr.setNodeAttribute(top.pos, 'dir', dir === 'auto' ? null : dir));
  editor.view.focus();
  return true;
}

/** The direction override of the current block: `auto` (none), `rtl` or `ltr`; null when the block has no direction. */
export function currentBlockDir(editor: Editor): BlockDir | null {
  const top = currentTopBlock(editor);
  if (!top || !('dir' in top.node.attrs)) return null;
  const dir = top.node.attrs['dir'];
  return dir === 'rtl' || dir === 'ltr' ? dir : 'auto';
}

/** The longest text a glossary term node keeps (RDoc schema). */
export const TERM_TEXT_MAX = 200;

/**
 * What the toolbar's glossary button (F21) works on: a term node the writer selected (`termId` set), or plain text
 * selected inside one text block (`termId` null). `from`/`to` leave out spaces around the selected words.
 */
export interface TermTarget {
  from: number;
  to: number;
  text: string;
  termId: string | null;
}

export function termTarget(editor: Editor): TermTarget | null {
  const { selection, doc } = editor.state;
  if (selection instanceof NodeSelection) {
    const { node } = selection;
    if (node.type.name !== 'term') return null;
    return { from: selection.from, to: selection.to, text: String(node.attrs['text'] ?? ''), termId: String(node.attrs['termId'] ?? '') };
  }
  const { $from, $to, empty } = selection;
  if (empty || !$from.sameParent($to) || !$from.parent.inlineContent || $from.parent.type.spec.code) return null;
  // Only text: a mention, another term or a line break inside the selection can't become part of a term.
  let onlyText = true;
  doc.nodesBetween(selection.from, selection.to, (node) => {
    if (node.isInline && !node.isText) onlyText = false;
  });
  if (!onlyText) return null;
  const raw = doc.textBetween(selection.from, selection.to);
  const text = raw.trim();
  if (!text || text.length > TERM_TEXT_MAX) return null;
  const from = selection.from + (raw.length - raw.trimStart().length);
  return { from, to: from + text.length, text, termId: null };
}

/** Turns the target's text into a glossary term node (an existing term gets the new `termId`). */
export function markTerm(editor: Editor, target: TermTarget, termId: string): boolean {
  return editor
    .chain()
    .focus()
    .insertContentAt({ from: target.from, to: target.to }, { type: 'term', attrs: { termId, text: target.text } })
    .run();
}

/** Turns a glossary term node back into plain text. */
export function unmarkTerm(editor: Editor, target: TermTarget): boolean {
  if (target.termId === null) return false;
  return editor.chain().focus().insertContentAt({ from: target.from, to: target.to }, { type: 'text', text: target.text }).run();
}

/** Which text-block type the toolbar shows for the current block. */
export function currentTextKind(editor: Editor): BlockKind | null {
  const top = currentTopBlock(editor);
  if (!top) return null;
  switch (top.node.type.name) {
    case 'paragraph':
      return 'paragraph';
    case 'heading':
      return top.node.attrs['level'] === 3 ? 'heading3' : 'heading2';
    case 'quote':
    case 'callout':
    case 'summary':
    case 'bulletList':
    case 'orderedList':
    case 'steps':
      return top.node.type.name as BlockKind;
    default:
      return null;
  }
}
