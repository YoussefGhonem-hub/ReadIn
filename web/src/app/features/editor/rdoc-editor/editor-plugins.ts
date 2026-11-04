import { Extension } from '@tiptap/core';
import { Node as PmNodeType } from '@tiptap/pm/model';
import { Plugin, PluginKey, Transaction } from '@tiptap/pm/state';
import { Mapping } from '@tiptap/pm/transform';
import { Decoration, DecorationSet } from '@tiptap/pm/view';
import { TextDir, segmentBidi } from '../../../shared/directives/bidi';
import { resolveBlockDir } from '../../../shared/rdoc/rdoc.utils';
import { RDocEditorHost } from './editor-host';
import { PmNode, editorBlockToRDoc, isBlockId, newBlockId } from './rdoc-convert';

/** Code and code tabs are always LTR (SPEC §14.2 rule 3). */
const ALWAYS_LTR = new Set(['codeBlock', 'codeTabs']);
/** Blocks without text: no direction. */
const NO_DIR = new Set(['image', 'horizontalRule', 'embed']);

/**
 * Keeps every top-level block's `id` present, valid and unique (SPEC §13: ids are stable and unique). A block that
 * lost its id because its type changed (paragraph → heading, wrapping in a list) takes the id of the block it
 * replaced; a split, pasted or duplicated block gets a new one.
 */
export function blockIdPlugin(newId: () => string = newBlockId): Plugin {
  return new Plugin({
    key: new PluginKey('rdocBlockIds'),
    appendTransaction(transactions, oldState, newState) {
      if (!transactions.some((t) => t.docChanged)) return null;
      const mapping = new Mapping();
      transactions.forEach((t) => mapping.appendMapping(t.mapping));
      const inverse = mapping.invert();

      const seen = new Set<string>();
      const missing: { pos: number; node: PmNodeType }[] = [];
      newState.doc.forEach((node, pos) => {
        const id = node.attrs['id'];
        if (!('id' in node.attrs)) return;
        if (isBlockId(id) && !seen.has(id)) seen.add(id);
        else missing.push({ pos, node });
      });
      if (!missing.length) return null;

      // Ids of old top-level blocks that no longer appear: candidates to inherit.
      const tr = newState.tr;
      for (const { pos } of missing) {
        let id: string | null = null;
        const oldPos = Math.max(0, Math.min(oldState.doc.content.size, inverse.map(pos, 1)));
        const $old = oldState.doc.resolve(oldPos);
        const oldTop = $old.depth >= 1 ? $old.node(1) : $old.nodeAfter;
        const candidate = oldTop?.attrs['id'];
        if (isBlockId(candidate) && !seen.has(candidate)) id = candidate;
        while (!id || seen.has(id)) id = newId();
        seen.add(id);
        tr.setNodeAttribute(pos, 'id', id);
      }
      tr.setMeta('addToHistory', false);
      return tr;
    },
  });
}

/** Assigns ids to a freshly loaded document (the plugin only runs on changes). */
export function ensureBlockIds(tr: Transaction, newId: () => string = newBlockId): Transaction {
  const seen = new Set<string>();
  const missing: number[] = [];
  tr.doc.forEach((node, pos) => {
    if (!('id' in node.attrs)) return;
    const id = node.attrs['id'];
    if (isBlockId(id) && !seen.has(id)) seen.add(id);
    else missing.push(pos);
  });
  for (const pos of missing) {
    let id: string;
    do id = newId();
    while (seen.has(id));
    seen.add(id);
    tr.setNodeAttribute(pos, 'id', id);
  }
  return tr;
}

/** The direction a top-level block gets, exactly as the reader resolves it (`resolveBlockDir`), or null. */
export function editorBlockDir(node: PmNodeType, fallback: TextDir): TextDir | null {
  const name = node.type.name;
  if (ALWAYS_LTR.has(name)) return 'ltr';
  if (NO_DIR.has(name)) return null;
  const block = editorBlockToRDoc(node.toJSON() as PmNode);
  if (!block) return null;
  return resolveBlockDir(block, 'dir' in block ? block.dir : undefined, fallback);
}

interface DirCacheEntry {
  fallback: TextDir;
  dir: TextDir | null;
  isolates: { from: number; to: number }[];
}

/**
 * Per-block direction and BiDi isolation, as decorations (nothing is stored in the document):
 * - every top-level block gets `dir` from its first strong character or its manual override, like the reader;
 * - runs in the opposite direction (English inside Arabic and the other way round) are wrapped in `<bdi>`, so
 *   punctuation and word order look the same while writing as when reading (SPEC §14.2 rules 1–3).
 */
export function blockDirPlugin(host: Pick<RDocEditorHost, 'fallbackDir'>): Plugin {
  const cache = new WeakMap<PmNodeType, DirCacheEntry>();

  function analyse(node: PmNodeType, fallback: TextDir): DirCacheEntry {
    const cached = cache.get(node);
    if (cached && cached.fallback === fallback) return cached;
    const dir = editorBlockDir(node, fallback);
    const isolates: { from: number; to: number }[] = [];
    if (dir && !ALWAYS_LTR.has(node.type.name)) {
      node.descendants((child, pos) => {
        if (!child.isText || !child.text || child.marks.some((m) => m.type.name === 'code')) return;
        let offset = 0;
        for (const segment of segmentBidi(child.text, dir)) {
          if (segment.isolate) isolates.push({ from: pos + offset, to: pos + offset + segment.text.length });
          offset += segment.text.length;
        }
      });
    }
    const entry = { fallback, dir, isolates };
    cache.set(node, entry);
    return entry;
  }

  function build(doc: PmNodeType): DecorationSet {
    const fallback = host.fallbackDir();
    const decorations: Decoration[] = [];
    doc.forEach((node, pos) => {
      const { dir, isolates } = analyse(node, fallback);
      if (!dir) return;
      decorations.push(Decoration.node(pos, pos + node.nodeSize, { dir }));
      for (const run of isolates) {
        // +1: positions inside the block start after its opening token.
        decorations.push(Decoration.inline(pos + 1 + run.from, pos + 1 + run.to, { nodeName: 'bdi' }));
      }
    });
    return DecorationSet.create(doc, decorations);
  }

  const key = new PluginKey<DecorationSet>('rdocBlockDir');
  return new Plugin<DecorationSet>({
    key,
    state: {
      init: (_config, state) => build(state.doc),
      apply: (tr, value, _old, state) => (tr.docChanged || tr.getMeta(key) ? build(state.doc) : value),
    },
    props: {
      decorations: (state) => key.getState(state),
    },
  });
}

/** Wires the plugins into Tiptap. */
export const RDocPlugins = Extension.create<{ host: Pick<RDocEditorHost, 'fallbackDir'>; newId: () => string }>({
  name: 'rdocPlugins',
  addOptions() {
    return { host: { fallbackDir: () => 'rtl' }, newId: newBlockId };
  },
  addProseMirrorPlugins() {
    return [blockIdPlugin(this.options.newId), blockDirPlugin(this.options.host)];
  },
});
