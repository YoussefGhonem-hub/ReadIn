import { AnyExtension, Editor, Extension, Node, mergeAttributes, textblockTypeInputRule } from '@tiptap/core';
import { Bold } from '@tiptap/extension-bold';
import { Code } from '@tiptap/extension-code';
import { CodeBlock } from '@tiptap/extension-code-block';
import { Document } from '@tiptap/extension-document';
import { HardBreak } from '@tiptap/extension-hard-break';
import { Heading } from '@tiptap/extension-heading';
import { Highlight } from '@tiptap/extension-highlight';
import { HorizontalRule } from '@tiptap/extension-horizontal-rule';
import { Italic } from '@tiptap/extension-italic';
import { Link } from '@tiptap/extension-link';
import { BulletList, ListItem, OrderedList } from '@tiptap/extension-list';
import { Paragraph } from '@tiptap/extension-paragraph';
import { Strike } from '@tiptap/extension-strike';
import { Table, TableCell, TableHeader, TableRow } from '@tiptap/extension-table';
import { Text } from '@tiptap/extension-text';
import { Dropcursor, Gapcursor, Placeholder, UndoRedo } from '@tiptap/extensions';
import { Node as PmNodeType } from '@tiptap/pm/model';
import { NodeSelection, TextSelection } from '@tiptap/pm/state';
import { BlockMoves } from './block-moves';
import { RDocEditorHost } from './editor-host';
import { RDocPlugins } from './editor-plugins';
import { CalloutView, CodeBlockView, CodeTabsView, EmbedView, ImageView, QuoteView, SummaryView } from './node-views';
import { PLAIN_CODE_LANG, newBlockId } from './rdoc-convert';

type Attrs = Record<string, unknown>;

function parseDir(value: string | null): string | null {
  return value === 'auto' || value === 'rtl' || value === 'ltr' ? value : null;
}

/** `id` (RDoc block id, never copied to the second half of a split block) and, optionally, the `dir` override. */
function blockAttributes(withDir = true) {
  return {
    id: {
      default: null,
      keepOnSplit: false,
      parseHTML: (element: HTMLElement) => element.getAttribute('data-block-id'),
      renderHTML: (attrs: Attrs) => (attrs['id'] ? { 'data-block-id': attrs['id'] } : {}),
    },
    ...(withDir
      ? {
          dir: {
            default: null,
            parseHTML: (element: HTMLElement) => parseDir(element.getAttribute('data-dir')),
            renderHTML: (attrs: Attrs) => (attrs['dir'] ? { 'data-dir': attrs['dir'] } : {}),
          },
        }
      : {}),
  };
}

/** Attribute `key`, kept through copy and paste as `data-{name}` (JSON-encoded when `json`). */
function dataAttribute(key: string, name: string, fallback: unknown = null, json = false) {
  const attribute = `data-${name}`;
  return {
    default: fallback,
    parseHTML: (element: HTMLElement) => {
      const value = element.getAttribute(attribute);
      if (value === null) return fallback;
      if (!json) return value;
      try {
        return JSON.parse(value) as unknown;
      } catch {
        return fallback;
      }
    },
    renderHTML: (attrs: Attrs) => {
      const value = attrs[key];
      return value === null || value === undefined || value === '' ? {} : { [attribute]: json ? JSON.stringify(value) : String(value) };
    },
  };
}

/**
 * Top-level block containing the selection head, with its position (depth 1); a selected image, embed or code tabs
 * block itself; or null at the document level.
 */
export function currentTopBlock(editor: Editor): { node: PmNodeType; pos: number } | null {
  const { selection } = editor.state;
  // A node selection's head is after the node: the block itself, not the one after it.
  if (selection instanceof NodeSelection && selection.$from.depth === 0) return { node: selection.node, pos: selection.from };
  const { $head } = selection;
  if ($head.depth < 1) {
    const node = editor.state.doc.nodeAt($head.pos);
    return node ? { node, pos: $head.pos } : null;
  }
  return { node: $head.node(1), pos: $head.before(1) };
}

const INLINE_BLOCKS = new Set(['quote', 'callout', 'summary']);

/**
 * Enter inside a quote, callout or summary adds a line break; Enter on an empty last line leaves the block and starts
 * a paragraph (the "press Enter twice" rule). Backspace at the start of an empty one turns it into a paragraph.
 */
const InlineBlockKeys = Extension.create({
  name: 'rdocInlineBlockKeys',
  addKeyboardShortcuts() {
    return {
      Enter: ({ editor }) => {
        const { $from, empty } = editor.state.selection;
        const parent = $from.parent;
        if (!empty || !INLINE_BLOCKS.has(parent.type.name) || $from.depth !== 1) return false;
        const before = $from.nodeBefore;
        const atEnd = $from.parentOffset === parent.content.size;
        if (atEnd && (before?.type.name === 'hardBreak' || parent.content.size === 0)) {
          const after = $from.after(1);
          const { tr, schema } = editor.state;
          if (before?.type.name === 'hardBreak') tr.delete($from.pos - before.nodeSize, $from.pos);
          const insertAt = tr.mapping.map(after);
          tr.insert(insertAt, schema.nodes['paragraph'].create());
          tr.setSelection(TextSelection.create(tr.doc, insertAt + 1)).scrollIntoView();
          editor.view.dispatch(tr);
          return true;
        }
        return editor.commands.setHardBreak();
      },
      Backspace: ({ editor }) => {
        const { $from, empty } = editor.state.selection;
        const parent = $from.parent;
        if (!empty || !INLINE_BLOCKS.has(parent.type.name) || $from.parentOffset !== 0 || parent.content.size) return false;
        const pos = $from.before(1);
        editor.view.dispatch(editor.state.tr.setNodeMarkup(pos, editor.schema.nodes['paragraph'], { id: parent.attrs['id'], dir: parent.attrs['dir'] }));
        return true;
      },
    };
  },
});

const Quote = Node.create<{ host: RDocEditorHost }>({
  name: 'quote',
  group: 'block',
  content: 'inline*',
  defining: true,
  addAttributes: () => ({ ...blockAttributes(), cite: dataAttribute('cite', 'cite') }),
  parseHTML: () => [{ tag: 'blockquote', contentElement: (dom: globalThis.Node) => ((dom as HTMLElement).querySelector('p') as HTMLElement | null) ?? (dom as HTMLElement) }],
  renderHTML: ({ HTMLAttributes }) => ['blockquote', mergeAttributes(HTMLAttributes, { 'data-block-type': 'quote' }), ['p', 0]],
  addNodeView() {
    return (props) => new QuoteView(props, this.options.host);
  },
  addInputRules() {
    return [textblockTypeInputRule({ find: /^>\s$/, type: this.type })];
  },
});

const Callout = Node.create<{ host: RDocEditorHost }>({
  name: 'callout',
  group: 'block',
  content: 'inline*',
  defining: true,
  addAttributes: () => ({ ...blockAttributes(), variant: dataAttribute('variant', 'variant', 'tip'), title: dataAttribute('title', 'title') }),
  parseHTML: () => [{ tag: 'aside[data-block-type="callout"]', contentElement: '[data-callout-content]' }],
  renderHTML: ({ HTMLAttributes }) => ['aside', mergeAttributes(HTMLAttributes, { 'data-block-type': 'callout' }), ['div', { 'data-callout-content': '' }, 0]],
  addNodeView() {
    return (props) => new CalloutView(props, this.options.host);
  },
});

const Summary = Node.create<{ host: RDocEditorHost }>({
  name: 'summary',
  group: 'block',
  content: 'inline*',
  defining: true,
  addAttributes: () => blockAttributes(),
  parseHTML: () => [{ tag: 'aside[data-block-type="summary"]', contentElement: '[data-summary-content]' }],
  renderHTML: ({ HTMLAttributes }) => ['aside', mergeAttributes(HTMLAttributes, { 'data-block-type': 'summary' }), ['div', { 'data-summary-content': '' }, 0]],
  addNodeView() {
    return (props) => new SummaryView(props, this.options.host);
  },
});

// ── Steps ───────────────────────────────────────────────────

const Steps = Node.create({
  name: 'steps',
  group: 'block',
  content: 'stepItem+',
  defining: true,
  addAttributes: () => blockAttributes(),
  parseHTML: () => [{ tag: 'ol[data-block-type="steps"]' }],
  renderHTML: ({ HTMLAttributes }) => ['ol', mergeAttributes(HTMLAttributes, { class: 'rd-steps rd-ed-block', 'data-block-type': 'steps' }), 0],
  addKeyboardShortcuts() {
    return {
      Enter: ({ editor }) => {
        const { $from, empty } = editor.state.selection;
        if (!empty || $from.depth < 3 || $from.node(2).type.name !== 'stepItem') return false;
        const { tr, schema } = editor.state;
        const item = $from.node(2);
        const itemPos = $from.before(2);
        const steps = $from.node(1);
        const stepsPos = $from.before(1);
        const isEmpty = item.textContent.trim() === '';
        const isLast = $from.index(1) === steps.childCount - 1;
        if ($from.parent.type.name === 'stepTitle' && !(isEmpty && isLast)) {
          // Title → its text.
          const bodyStart = $from.after(3) + 1;
          editor.view.dispatch(tr.setSelection(TextSelection.create(tr.doc, bodyStart)));
          return true;
        }
        if (isEmpty && isLast) {
          // An empty last step: leave the steps block.
          const paragraph = schema.nodes['paragraph'].create();
          if (steps.childCount === 1) {
            tr.replaceWith(stepsPos, stepsPos + steps.nodeSize, paragraph);
            tr.setSelection(TextSelection.create(tr.doc, stepsPos + 1));
          } else {
            tr.delete(itemPos, itemPos + item.nodeSize);
            const after = tr.mapping.map(stepsPos + steps.nodeSize);
            tr.insert(after, paragraph);
            tr.setSelection(TextSelection.create(tr.doc, after + 1));
          }
          editor.view.dispatch(tr.scrollIntoView());
          return true;
        }
        const next = schema.nodes['stepItem'].create(null, [schema.nodes['stepTitle'].create(), schema.nodes['paragraph'].create()]);
        const insertAt = itemPos + item.nodeSize;
        tr.insert(insertAt, next);
        tr.setSelection(TextSelection.create(tr.doc, insertAt + 2));
        editor.view.dispatch(tr.scrollIntoView());
        return true;
      },
      Backspace: ({ editor }) => {
        const { $from, empty } = editor.state.selection;
        if (!empty || $from.depth < 3 || $from.node(2).type.name !== 'stepItem' || $from.parentOffset !== 0) return false;
        const { tr, schema } = editor.state;
        if ($from.parent.type.name === 'paragraph') {
          // Start of the text → end of the title (never merge them).
          const titleEnd = $from.before(3) - 1;
          editor.view.dispatch(tr.setSelection(TextSelection.create(tr.doc, titleEnd)));
          return true;
        }
        const item = $from.node(2);
        if (item.textContent.trim() !== '') return true; // keep the step; nothing sensible to merge into
        const steps = $from.node(1);
        const stepsPos = $from.before(1);
        const itemPos = $from.before(2);
        if (steps.childCount === 1) {
          tr.replaceWith(stepsPos, stepsPos + steps.nodeSize, schema.nodes['paragraph'].create({ id: steps.attrs['id'], dir: steps.attrs['dir'] }));
          tr.setSelection(TextSelection.create(tr.doc, stepsPos + 1));
        } else {
          tr.delete(itemPos, itemPos + item.nodeSize);
          tr.setSelection(TextSelection.near(tr.doc.resolve(Math.max(stepsPos + 1, itemPos - 1)), -1));
        }
        editor.view.dispatch(tr);
        return true;
      },
    };
  },
});

const StepItem = Node.create({
  name: 'stepItem',
  content: 'stepTitle paragraph',
  defining: true,
  parseHTML: () => [{ tag: 'ol[data-block-type="steps"] > li' }],
  renderHTML: () => ['li', 0],
});

const StepTitle = Node.create<{ placeholder: () => string }>({
  name: 'stepTitle',
  content: 'text*',
  marks: '',
  defining: true,
  parseHTML: () => [{ tag: 'div.rd-step-title' }],
  renderHTML() {
    return ['div', { class: 'rd-step-title', 'data-step-placeholder': this.options.placeholder() }, 0];
  },
});

// ── Atoms ───────────────────────────────────────────────────

const CodeTabs = Node.create<{ host: RDocEditorHost }>({
  name: 'codeTabs',
  group: 'block',
  atom: true,
  selectable: true,
  addAttributes: () => ({ ...blockAttributes(false), tabs: dataAttribute('tabs', 'tabs', [], true) }),
  parseHTML: () => [{ tag: 'div[data-block-type="codeTabs"]' }],
  renderHTML: ({ HTMLAttributes }) => ['div', mergeAttributes(HTMLAttributes, { 'data-block-type': 'codeTabs' })],
  addNodeView() {
    return (props) => new CodeTabsView(props, this.options.host);
  },
});

const Image = Node.create<{ host: RDocEditorHost }>({
  name: 'image',
  group: 'block',
  atom: true,
  selectable: true,
  addAttributes: () => ({
    ...blockAttributes(false),
    src: dataAttribute('src', 'src'),
    darkSrc: dataAttribute('darkSrc', 'dark-src'),
    alt: dataAttribute('alt', 'alt', ''),
    caption: dataAttribute('caption', 'caption'),
    width: dataAttribute('width', 'width', null, true),
    height: dataAttribute('height', 'height', null, true),
  }),
  // Only our own blocks: a picture pasted from another site was never uploaded through ReadIn.
  parseHTML: () => [{ tag: 'figure[data-block-type="image"]' }],
  renderHTML: ({ HTMLAttributes }) => ['figure', mergeAttributes(HTMLAttributes, { 'data-block-type': 'image' })],
  addNodeView() {
    return (props) => new ImageView(props, this.options.host);
  },
});

const Embed = Node.create<{ host: RDocEditorHost }>({
  name: 'embed',
  group: 'block',
  atom: true,
  selectable: true,
  addAttributes: () => ({ ...blockAttributes(false), provider: dataAttribute('provider', 'provider', 'youtube'), url: dataAttribute('url', 'url', '') }),
  parseHTML: () => [{ tag: 'div[data-block-type="embed"]' }],
  renderHTML: ({ HTMLAttributes }) => ['div', mergeAttributes(HTMLAttributes, { 'data-block-type': 'embed' })],
  addNodeView() {
    return (props) => new EmbedView(props, this.options.host);
  },
});

// ── Inline atoms ────────────────────────────────────────────

/** `@username` (RDoc `mention`): inserted from the suggestions, shown isolated LTR like the reader. */
export const Mention = Node.create({
  name: 'mention',
  group: 'inline',
  inline: true,
  atom: true,
  selectable: false,
  addAttributes: () => ({ userId: dataAttribute('userId', 'mention'), text: dataAttribute('text', 'text', '') }),
  parseHTML: () => [{ tag: 'span[data-mention]' }],
  renderHTML: ({ node, HTMLAttributes }) => ['span', mergeAttributes(HTMLAttributes, { class: 'rd-mention', dir: 'ltr' }), String(node.attrs['text'] ?? '')],
  renderText: ({ node }) => String(node.attrs['text'] ?? ''),
});

/** Glossary term (F21): an atom; the toolbar's glossary button adds, changes and removes it (block-commands `markTerm`). */
const Term = Node.create({
  name: 'term',
  group: 'inline',
  inline: true,
  atom: true,
  selectable: true,
  addAttributes: () => ({ termId: dataAttribute('termId', 'term'), text: dataAttribute('text', 'text', '') }),
  parseHTML: () => [{ tag: 'span[data-term]' }],
  renderHTML: ({ node, HTMLAttributes }) => ['span', mergeAttributes(HTMLAttributes, { class: 'rd-term' }), String(node.attrs['text'] ?? '')],
  renderText: ({ node }) => String(node.attrs['text'] ?? ''),
});

/** Every Tiptap extension of the RDoc editor (SPEC §13): all block types, inline nodes and marks, nothing else. */
export function rdocExtensions(host: RDocEditorHost, extra: AnyExtension[] = [], newId: () => string = newBlockId): AnyExtension[] {
  const t = host.t.bind(host);
  return [
    Document,
    Text,
    Paragraph.extend({ addAttributes: () => blockAttributes() }),
    Heading.extend({
      addAttributes() {
        return { ...this.parent?.(), ...blockAttributes() };
      },
      // H1 is the article title: "# " makes a heading 2 and "## " (or "### ") a heading 3.
      addInputRules() {
        return [
          textblockTypeInputRule({ find: /^#\s$/, type: this.type, getAttributes: { level: 2 } }),
          textblockTypeInputRule({ find: /^#{2,3}\s$/, type: this.type, getAttributes: { level: 3 } }),
        ];
      },
    }).configure({ levels: [2, 3] }),
    BulletList.extend({
      addAttributes() {
        return { ...this.parent?.(), ...blockAttributes() };
      },
    }),
    OrderedList.extend({
      addAttributes() {
        return { ...this.parent?.(), ...blockAttributes() };
      },
    }),
    ListItem.extend({ content: 'paragraph' }),
    Steps,
    StepItem,
    StepTitle.configure({ placeholder: () => t('editor.blocks.stepTitle') }),
    Quote.configure({ host }),
    Callout.configure({ host }),
    Summary.configure({ host }),
    InlineBlockKeys,
    CodeBlock.extend({
      addAttributes() {
        return {
          ...this.parent?.(),
          ...blockAttributes(false),
          filename: dataAttribute('filename', 'filename'),
          highlightLines: dataAttribute('highlightLines', 'highlight-lines', null, true),
          compile: dataAttribute('compile', 'compile', null, true),
        };
      },
      addNodeView() {
        return (props) => new CodeBlockView(props, host);
      },
    }).configure({ defaultLanguage: PLAIN_CODE_LANG, enableTabIndentation: true, tabSize: 2 }),
    CodeTabs.configure({ host }),
    Table.extend({
      addAttributes() {
        return { ...this.parent?.(), ...blockAttributes() };
      },
      renderHTML({ HTMLAttributes }) {
        return ['div', mergeAttributes(HTMLAttributes, { class: 'rd-table-wrap rd-ed-block', 'data-block-type': 'table' }), ['table', {}, ['tbody', 0]]];
      },
    }).configure({ resizable: false, View: null }),
    TableRow,
    TableHeader.extend({ content: 'paragraph' }),
    TableCell.extend({ content: 'paragraph' }),
    Image.configure({ host }),
    HorizontalRule.extend({ addAttributes: () => blockAttributes(false) }),
    Embed.configure({ host }),
    HardBreak,
    Mention,
    Term,
    Bold,
    Italic,
    Strike,
    Highlight,
    Code.configure({ HTMLAttributes: { class: 'rd-inline-code', dir: 'ltr' } }),
    Link.configure({
      openOnClick: false,
      autolink: true,
      linkOnPaste: true,
      defaultProtocol: 'https',
      // RDoc links are http(s) only (SPEC §13.3).
      isAllowedUri: (url) => /^https?:\/\/[^\s<>"']+$/i.test(url),
      HTMLAttributes: { rel: 'nofollow ugc noopener noreferrer', target: null, class: null },
    }),
    UndoRedo,
    Dropcursor,
    Gapcursor,
    Placeholder.configure({
      includeChildren: true,
      placeholder: ({ node }) => {
        switch (node.type.name) {
          case 'heading':
            return t('editor.placeholders.heading');
          case 'paragraph':
            return t('editor.placeholders.paragraph');
          case 'quote':
          case 'callout':
          case 'summary':
            return t('editor.placeholders.text');
          default:
            return '';
        }
      },
    }),
    RDocPlugins.configure({ host, newId }),
    BlockMoves,
    ...extra,
  ];
}
