import { Editor, Extension } from '@tiptap/core';
import { Node as PmNodeType } from '@tiptap/pm/model';
import { EditorState, NodeSelection, Plugin, PluginKey, Selection, TextSelection, Transaction } from '@tiptap/pm/state';
import { StepMap } from '@tiptap/pm/transform';
import { Decoration, DecorationSet, EditorView } from '@tiptap/pm/view';
import { newBlockId } from './rdoc-convert';

/**
 * Moving and deleting whole top-level blocks: the block handle (grip, trash and menu), drag and drop, and
 * Alt+Shift+↑/↓. Each change is one transaction, so undo, redo and autosave treat it like any other edit.
 */

const starts = new WeakMap<PmNodeType, number[]>();

/** Where each top-level block starts, by index (kept per document). */
export function blockPositions(doc: PmNodeType): number[] {
  let positions = starts.get(doc);
  if (!positions) {
    const list: number[] = [];
    doc.forEach((_node, offset) => list.push(offset));
    starts.set(doc, list);
    positions = list;
  }
  return positions;
}

/** Index of the top-level block with RDoc id `id`, or -1. */
export function blockIndexById(doc: PmNodeType, id: string): number {
  for (let i = 0; i < doc.childCount; i++) if (doc.child(i).attrs['id'] === id) return i;
  return -1;
}

/** Index of the top-level block holding the selection (the selected block itself for a selected image, embed…). */
export function selectedBlockIndex(state: EditorState): number | null {
  const { selection, doc } = state;
  if (!doc.childCount) return null;
  if (selection instanceof NodeSelection && selection.$from.depth === 0) return selection.$from.index(0);
  const { $head } = selection;
  return Math.min($head.index(0), doc.childCount - 1);
}

/**
 * Moves the block at index `from` so it sits right before the block now at index `to` (`to` = the number of blocks:
 * last). Null when nothing would change. A selection inside the block moves with it.
 */
export function moveBlockTr(state: EditorState, from: number, to: number): Transaction | null {
  const { doc, selection } = state;
  const count = doc.childCount;
  if (from < 0 || from >= count || to < 0 || to > count || to === from || to === from + 1) return null;
  const positions = blockPositions(doc);
  const node = doc.child(from);
  const start = positions[from];
  const end = start + node.nodeSize;
  const target = to === count ? doc.content.size : positions[to];
  const inside = selection.from >= start && selection.to <= end;
  const tr = state.tr.delete(start, end);
  const at = tr.mapping.map(target);
  tr.insert(at, node);
  if (inside) tr.setSelection(selection.map(tr.doc, StepMap.offset(at - start)));
  return tr;
}

/**
 * Deletes the block at `index` whole (a table, code tabs, a list…). The cursor, if it was in the block, goes to the
 * block that takes its place. Deleting the only block leaves an empty paragraph; null when that is all there is.
 */
export function deleteBlockTr(state: EditorState, index: number): Transaction | null {
  const { doc, selection, schema } = state;
  if (index < 0 || index >= doc.childCount) return null;
  const node = doc.child(index);
  const start = blockPositions(doc)[index];
  const end = start + node.nodeSize;
  const tr = state.tr;
  if (doc.childCount === 1) {
    if (node.type.name === 'paragraph' && node.content.size === 0) return null;
    tr.replaceWith(0, doc.content.size, schema.nodes['paragraph'].create({ id: newBlockId() }));
    return tr.setSelection(TextSelection.create(tr.doc, 1));
  }
  const inside = selection.from >= start && selection.to <= end;
  tr.delete(start, end);
  if (inside) tr.setSelection(Selection.near(tr.doc.resolve(Math.min(start, tr.doc.content.size)), 1));
  return tr;
}

/** Moves the block holding the selection one place up (-1) or down (1). */
export function moveSelectedBlock(editor: Editor, direction: -1 | 1): boolean {
  const index = selectedBlockIndex(editor.state);
  if (index === null) return false;
  const tr = moveBlockTr(editor.state, index, direction < 0 ? index - 1 : index + 2);
  if (!tr) return false;
  editor.view.dispatch(tr.scrollIntoView());
  return true;
}

// ── Decorations: the block the handle points at, and the block being dragged ──

export interface BlockMarks {
  /** The block the handle, its trash button or its menu acts on (tinted). */
  target: string | null;
  /** The block being dragged (faded). */
  dragging: string | null;
}

export const blockMarksKey = new PluginKey<BlockMarks>('rdocBlockMarks');

/** Inline, so block-editor.css stays within its size budget; the classes name the state for tests and tools. */
const MARK_STYLES = {
  'rd-ed-handle-target': 'border-radius: var(--rd-radius-sm); box-shadow: 0 0 0 4px var(--rd-color-surface-variant)',
  'rd-ed-dragging': 'opacity: 0.4',
} as const;

/** Updates the marks (by block id); nothing is stored in the document or the history. */
export function setBlockMarks(view: EditorView, patch: Partial<BlockMarks>): void {
  const current = blockMarksKey.getState(view.state);
  if (!current || Object.entries(patch).every(([key, value]) => current[key as keyof BlockMarks] === value)) return;
  view.dispatch(view.state.tr.setMeta(blockMarksKey, patch));
}

function blockMarksPlugin(): Plugin<BlockMarks> {
  return new Plugin<BlockMarks>({
    key: blockMarksKey,
    state: {
      init: () => ({ target: null, dragging: null }),
      apply: (tr, value) => {
        const patch = tr.getMeta(blockMarksKey) as Partial<BlockMarks> | undefined;
        return patch ? { ...value, ...patch } : value;
      },
    },
    props: {
      decorations(state) {
        const marks = blockMarksKey.getState(state);
        if (!marks?.target && !marks?.dragging) return DecorationSet.empty;
        const decorations: Decoration[] = [];
        state.doc.forEach((node, pos) => {
          const id = node.attrs['id'];
          if (!id) return;
          const classes = (['rd-ed-handle-target', 'rd-ed-dragging'] as const).filter((name) => id === (name === 'rd-ed-dragging' ? marks.dragging : marks.target));
          if (!classes.length) return;
          decorations.push(Decoration.node(pos, pos + node.nodeSize, { class: classes.join(' '), style: classes.map((name) => MARK_STYLES[name]).join('; ') }));
        });
        return DecorationSet.create(state.doc, decorations);
      },
    },
  });
}

/** Alt+Shift+↑ / Alt+Shift+↓ move the current block; the handle's decorations. */
export const BlockMoves = Extension.create({
  name: 'rdocBlockMoves',
  addKeyboardShortcuts() {
    // At the first or last block the keys are still taken (nothing else should happen).
    const move = (editor: Editor, direction: -1 | 1) => moveSelectedBlock(editor, direction) || selectedBlockIndex(editor.state) !== null;
    return {
      'Alt-Shift-ArrowUp': ({ editor }) => move(editor, -1),
      'Alt-Shift-ArrowDown': ({ editor }) => move(editor, 1),
    };
  },
  addProseMirrorPlugins() {
    return [blockMarksPlugin()];
  },
});
