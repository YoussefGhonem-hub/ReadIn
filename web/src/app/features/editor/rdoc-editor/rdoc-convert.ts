import {
  BlockDir,
  CalloutVariant,
  CodeTab,
  InlineContent,
  InlineNode,
  Mark,
  RDoc,
  RDocBlock,
  RDocLanguage,
} from '../../../shared/rdoc/rdoc.models';

/**
 * RDoc (SPEC §13) ⇄ editor document (ProseMirror JSON for the Tiptap schema in `rdoc-schema.ts`). Pure functions, no
 * Tiptap import, so they are unit-tested on their own and every format detail lives in one place.
 *
 * Editor node names: paragraph, heading, bulletList / orderedList → listItem → paragraph, steps → stepItem →
 * (stepTitle, paragraph), quote, callout, summary (inline content directly), codeBlock (text), codeTabs, image, embed
 * (atoms, everything in attrs), horizontalRule (divider), table → tableRow → tableHeader / tableCell → paragraph.
 * Inline: text with marks (bold, italic, code, strike, highlight, link), hardBreak, mention, term.
 *
 * Top-level nodes carry the RDoc block `id` (kept as is, so ids are stable across saves) and, where RDoc has one,
 * `dir` (null = not set, which RDoc reads as `auto`).
 */

/** A ProseMirror JSON node (the shape of `editor.getJSON()`). */
export interface PmNode {
  type: string;
  attrs?: Record<string, unknown>;
  content?: PmNode[];
  marks?: PmMark[];
  text?: string;
}

export interface PmMark {
  type: string;
  attrs?: Record<string, unknown>;
}

/** shared/rdoc/rdoc.schema.json limits. */
export const TEXT_NODE_MAX = 20_000;
const BLOCK_ID = /^[A-Za-z0-9_-]{1,64}$/;
const CODE_LANG = /^[a-z0-9+#.-]{1,32}$/;
/** Code without a language is plain text. */
export const PLAIN_CODE_LANG = 'text';
const CALLOUT_VARIANTS: readonly CalloutVariant[] = ['tip', 'info', 'warning', 'danger'];
const MARK_TYPES = new Set(['bold', 'italic', 'code', 'strike', 'highlight', 'link']);

/** A new block id: `b` + 10 random base-36 characters (matches the schema's `^[A-Za-z0-9_-]{1,64}$`). */
export function newBlockId(): string {
  const bytes = new Uint8Array(10);
  if (typeof crypto !== 'undefined' && typeof crypto.getRandomValues === 'function') crypto.getRandomValues(bytes);
  else for (let i = 0; i < bytes.length; i++) bytes[i] = Math.floor(Math.random() * 256);
  return 'b' + Array.from(bytes, (b) => (b % 36).toString(36)).join('');
}

export function isBlockId(id: unknown): id is string {
  return typeof id === 'string' && BLOCK_ID.test(id);
}

// ── RDoc → editor ───────────────────────────────────────────

/** An empty editor document (one empty paragraph, as ProseMirror needs at least one block). */
export function emptyEditorDoc(newId: () => string = newBlockId): PmNode {
  return { type: 'doc', content: [{ type: 'paragraph', attrs: { id: newId(), dir: null } }] };
}

export function rdocToEditor(doc: RDoc | null | undefined, newId: () => string = newBlockId): PmNode {
  const content = (doc?.blocks ?? []).flatMap((block) => {
    const node = blockToPm(block);
    return node ? [node] : [];
  });
  return content.length ? { type: 'doc', content } : emptyEditorDoc(newId);
}

function dirAttr(dir: BlockDir | undefined): BlockDir | null {
  return dir === 'auto' || dir === 'rtl' || dir === 'ltr' ? dir : null;
}

function withContent(node: PmNode, content: PmNode[]): PmNode {
  return content.length ? { ...node, content } : node;
}

function innerParagraph(content: InlineContent | undefined): PmNode {
  return withContent({ type: 'paragraph', attrs: { id: null, dir: null } }, inlineToPm(content));
}

function blockToPm(block: RDocBlock): PmNode | null {
  switch (block.type) {
    case 'paragraph':
      return withContent({ type: 'paragraph', attrs: { id: block.id, dir: dirAttr(block.dir) } }, inlineToPm(block.content));
    case 'heading':
      return withContent({ type: 'heading', attrs: { id: block.id, dir: dirAttr(block.dir), level: block.level === 3 ? 3 : 2 } }, inlineToPm(block.content));
    case 'bulletList':
    case 'orderedList':
      return {
        type: block.type,
        attrs: { id: block.id, dir: dirAttr(block.dir) },
        content: (block.items.length ? block.items : [[]]).map((item) => ({ type: 'listItem', content: [innerParagraph(item)] })),
      };
    case 'steps':
      return {
        type: 'steps',
        attrs: { id: block.id, dir: dirAttr(block.dir) },
        content: (block.items.length ? block.items : [{ title: '', content: [] }]).map((item) => ({
          type: 'stepItem',
          content: [withContent({ type: 'stepTitle' }, item.title ? [{ type: 'text', text: item.title }] : []), innerParagraph(item.content)],
        })),
      };
    case 'quote':
      return withContent({ type: 'quote', attrs: { id: block.id, dir: dirAttr(block.dir), cite: block.cite ?? null } }, inlineToPm(block.content));
    case 'callout':
      return withContent(
        { type: 'callout', attrs: { id: block.id, dir: dirAttr(block.dir), variant: block.variant, title: block.title ?? null } },
        inlineToPm(block.content),
      );
    case 'summary':
      return withContent({ type: 'summary', attrs: { id: block.id, dir: dirAttr(block.dir) } }, inlineToPm(block.content));
    case 'code':
      return withContent(
        {
          type: 'codeBlock',
          attrs: {
            id: block.id,
            language: block.lang,
            filename: block.filename ?? null,
            highlightLines: block.highlightLines ? [...block.highlightLines] : null,
            compile: typeof block.compile === 'boolean' ? block.compile : null,
          },
        },
        block.code ? [{ type: 'text', text: block.code }] : [],
      );
    case 'codeTabs':
      return { type: 'codeTabs', attrs: { id: block.id, tabs: block.tabs.map((tab) => ({ ...tab })) } };
    case 'table': {
      const row = (cells: InlineContent[], cellType: 'tableHeader' | 'tableCell'): PmNode => ({
        type: 'tableRow',
        content: cells.map((cell) => ({ type: cellType, content: [innerParagraph(cell)] })),
      });
      return {
        type: 'table',
        attrs: { id: block.id, dir: dirAttr(block.dir) },
        content: [row(block.header, 'tableHeader'), ...block.rows.map((cells) => row(cells, 'tableCell'))],
      };
    }
    case 'image':
      return {
        type: 'image',
        attrs: {
          id: block.id,
          src: block.src,
          darkSrc: block.darkSrc ?? null,
          alt: block.alt ?? '',
          caption: block.caption ?? null,
          width: block.width ?? null,
          height: block.height ?? null,
        },
      };
    case 'divider':
      return { type: 'horizontalRule', attrs: { id: block.id } };
    case 'embed':
      return { type: 'embed', attrs: { id: block.id, provider: block.provider, url: block.url } };
    default:
      return null; // a block type this client doesn't know (the schema rejects it anyway)
  }
}

export function inlineToPm(content: InlineContent | undefined): PmNode[] {
  const nodes: PmNode[] = [];
  for (const node of content ?? []) {
    switch (node.type) {
      case 'text': {
        if (!node.text) break; // ProseMirror has no empty text nodes
        const marks = (node.marks ?? []).map(markToPm);
        nodes.push(marks.length ? { type: 'text', text: node.text, marks } : { type: 'text', text: node.text });
        break;
      }
      case 'hardBreak':
        nodes.push({ type: 'hardBreak' });
        break;
      case 'mention':
        nodes.push({ type: 'mention', attrs: { userId: node.userId, text: node.text } });
        break;
      case 'term':
        nodes.push({ type: 'term', attrs: { termId: node.termId, text: node.text } });
        break;
    }
  }
  return nodes;
}

function markToPm(mark: Mark): PmMark {
  return mark.type === 'link' ? { type: 'link', attrs: { href: mark.href } } : { type: mark.type };
}

// ── Editor → RDoc ───────────────────────────────────────────

/**
 * Editor document → RDoc for `language`. Block ids are kept; a block without a valid id, or with one already used
 * earlier in the document (copy/paste), gets a new one, so ids are always unique. Optional strings that are blank
 * are left out. Work in progress that has nothing to save yet is skipped: an image still uploading (no `src`) and an
 * embed without a link. An empty heading is saved as an empty paragraph (a heading needs text).
 */
export function editorToRDoc(doc: PmNode | null | undefined, language: RDocLanguage, newId: () => string = newBlockId): RDoc {
  const nodes = doc?.content ?? [];
  // First come, first kept: a valid id stays with the first block that has it; new ids never take an existing one.
  const reserved = new Set<string>();
  const kept = nodes.map((node) => {
    const id = node.attrs?.['id'];
    if (!isBlockId(id) || reserved.has(id)) return null;
    reserved.add(id);
    return id;
  });
  const blocks: RDocBlock[] = [];
  nodes.forEach((node, i) => {
    const block = pmToBlock(node, () => {
      let id = kept[i];
      if (id) return id;
      do id = newId();
      while (reserved.has(id));
      reserved.add(id);
      return id;
    });
    if (block) blocks.push(block);
  });
  return { version: 1, language, blocks };
}

/** One top-level editor node as an RDoc block (for direction and checks; the id is kept as is), or null. */
export function editorBlockToRDoc(node: PmNode): RDocBlock | null {
  const id = node.attrs?.['id'];
  return pmToBlock(node, () => (typeof id === 'string' ? id : ''));
}

function rdocDir(attrs: Record<string, unknown> | undefined): { dir?: BlockDir } {
  const dir = attrs?.['dir'];
  return dir === 'auto' || dir === 'rtl' || dir === 'ltr' ? { dir } : {};
}

function nonBlank(value: unknown): string | null {
  return typeof value === 'string' && value.trim() ? value : null;
}

/** Plain text of a node (text children only; hard breaks become spaces). */
function plainText(node: PmNode | undefined): string {
  return (node?.content ?? []).map((child) => (child.type === 'text' ? (child.text ?? '') : child.type === 'hardBreak' ? ' ' : '')).join('');
}

/** Inline content of the first textblock inside `node` (list items, table cells and step bodies hold one paragraph). */
function innerInline(node: PmNode | undefined): InlineContent {
  const parts = (node?.content ?? []).filter((child) => child.type === 'paragraph');
  const result: InlineContent = [];
  parts.forEach((part, i) => {
    if (i > 0) result.push({ type: 'hardBreak' });
    result.push(...pmToInline(part.content));
  });
  return result;
}

function pmToBlock(node: PmNode, blockId: () => string): RDocBlock | null {
  const attrs = node.attrs ?? {};
  switch (node.type) {
    case 'paragraph':
      return { id: blockId(), type: 'paragraph', ...rdocDir(attrs), content: pmToInline(node.content) };
    case 'heading': {
      const content = pmToInline(node.content);
      if (!content.length) return { id: blockId(), type: 'paragraph', ...rdocDir(attrs), content };
      return { id: blockId(), type: 'heading', level: attrs['level'] === 3 ? 3 : 2, ...rdocDir(attrs), content };
    }
    case 'bulletList':
    case 'orderedList':
      return {
        id: blockId(),
        type: node.type,
        ...rdocDir(attrs),
        items: (node.content ?? []).filter((item) => item.type === 'listItem').map((item) => innerInline(item)),
      };
    case 'steps':
      return {
        id: blockId(),
        type: 'steps',
        ...rdocDir(attrs),
        items: (node.content ?? [])
          .filter((item) => item.type === 'stepItem')
          .map((item) => {
            const title = item.content?.find((child) => child.type === 'stepTitle');
            return { title: plainText(title).replace(/\s*\n\s*/g, ' '), content: innerInline(item) };
          }),
      };
    case 'quote': {
      const cite = nonBlank(attrs['cite']);
      return { id: blockId(), type: 'quote', ...rdocDir(attrs), content: pmToInline(node.content), ...(cite ? { cite } : {}) };
    }
    case 'callout': {
      const title = nonBlank(attrs['title']);
      const variant = CALLOUT_VARIANTS.includes(attrs['variant'] as CalloutVariant) ? (attrs['variant'] as CalloutVariant) : 'tip';
      return { id: blockId(), type: 'callout', variant, ...(title ? { title } : {}), ...rdocDir(attrs), content: pmToInline(node.content) };
    }
    case 'summary':
      return { id: blockId(), type: 'summary', ...rdocDir(attrs), content: pmToInline(node.content) };
    case 'codeBlock': {
      const filename = nonBlank(attrs['filename']);
      const highlightLines = Array.isArray(attrs['highlightLines']) ? (attrs['highlightLines'] as number[]) : null;
      const compile = typeof attrs['compile'] === 'boolean' ? (attrs['compile'] as boolean) : null;
      return {
        id: blockId(),
        type: 'code',
        lang: codeLang(attrs['language']),
        ...(filename ? { filename } : {}),
        code: (node.content ?? []).map((child) => child.text ?? '').join(''),
        ...(highlightLines ? { highlightLines: [...highlightLines] } : {}),
        ...(compile !== null ? { compile } : {}),
      };
    }
    case 'codeTabs': {
      const tabs = Array.isArray(attrs['tabs']) ? (attrs['tabs'] as Partial<CodeTab>[]) : [];
      return { id: blockId(), type: 'codeTabs', tabs: (tabs.length ? tabs : [{}]).map(codeTab) };
    }
    case 'table': {
      const rows = (node.content ?? []).filter((row) => row.type === 'tableRow').map((row) => (row.content ?? []).map((cell) => innerInline(cell)));
      const [header = [[]], ...body] = rows;
      return { id: blockId(), type: 'table', ...rdocDir(attrs), header, rows: body };
    }
    case 'image': {
      const src = nonBlank(attrs['src']);
      if (!src) return null; // still uploading, or the upload failed
      const darkSrc = nonBlank(attrs['darkSrc']);
      const caption = nonBlank(attrs['caption']);
      const width = typeof attrs['width'] === 'number' ? attrs['width'] : null;
      const height = typeof attrs['height'] === 'number' ? attrs['height'] : null;
      return {
        id: blockId(),
        type: 'image',
        src,
        ...(darkSrc ? { darkSrc } : {}),
        alt: typeof attrs['alt'] === 'string' ? attrs['alt'] : '',
        ...(caption ? { caption } : {}),
        ...(width ? { width } : {}),
        ...(height ? { height } : {}),
      };
    }
    case 'horizontalRule':
      return { id: blockId(), type: 'divider' };
    case 'embed': {
      const url = nonBlank(attrs['url']);
      if (!url) return null;
      return { id: blockId(), type: 'embed', provider: attrs['provider'] === 'github-gist' ? 'github-gist' : 'youtube', url: url.trim() };
    }
    default:
      return null;
  }
}

function codeLang(value: unknown): string {
  const lang = typeof value === 'string' ? value.trim().toLowerCase() : '';
  return CODE_LANG.test(lang) ? lang : PLAIN_CODE_LANG;
}

function codeTab(tab: Partial<CodeTab>): CodeTab {
  const lang = codeLang(tab.lang);
  const label = nonBlank(tab.label) ?? codeLanguageName(lang);
  return {
    label,
    lang,
    ...(nonBlank(tab.filename) ? { filename: tab.filename } : {}),
    code: tab.code ?? '',
    ...(typeof tab.compile === 'boolean' ? { compile: tab.compile } : {}),
  };
}

/** A tab label for a language when the writer left it empty ("csharp" → "C#"). */
export function codeLanguageName(lang: string): string {
  return CODE_LANGUAGES.find((l) => l.id === lang)?.label ?? (lang === PLAIN_CODE_LANG ? 'Text' : lang);
}

export function pmToInline(nodes: PmNode[] | undefined): InlineContent {
  const result: InlineContent = [];
  for (const node of nodes ?? []) {
    switch (node.type) {
      case 'text': {
        const text = node.text ?? '';
        if (!text) break;
        const marks = pmMarks(node.marks);
        for (let start = 0; start < text.length; start += TEXT_NODE_MAX) {
          const part = text.slice(start, start + TEXT_NODE_MAX);
          result.push(marks.length ? { type: 'text', text: part, marks } : { type: 'text', text: part });
        }
        break;
      }
      case 'hardBreak':
        result.push({ type: 'hardBreak' });
        break;
      case 'mention': {
        const userId = node.attrs?.['userId'];
        const text = node.attrs?.['text'];
        if (typeof userId === 'string' && typeof text === 'string' && text) result.push({ type: 'mention', userId, text });
        break;
      }
      case 'term': {
        const termId = node.attrs?.['termId'];
        const text = node.attrs?.['text'];
        if (typeof termId === 'string' && typeof text === 'string' && text) result.push({ type: 'term', termId, text });
        break;
      }
    }
  }
  return result;
}

function pmMarks(marks: PmMark[] | undefined): Mark[] {
  const result: Mark[] = [];
  for (const mark of marks ?? []) {
    if (!MARK_TYPES.has(mark.type)) continue;
    if (mark.type === 'link') {
      const href = mark.attrs?.['href'];
      if (typeof href === 'string' && /^https?:\/\/[^\s<>"']+$/i.test(href)) result.push({ type: 'link', href });
    } else {
      result.push({ type: mark.type } as Mark);
    }
  }
  return result;
}

// ── Helpers for tests and the editor ────────────────────────

const MARK_ORDER = ['bold', 'italic', 'strike', 'highlight', 'code', 'link'];

/**
 * The canonical form of an RDoc document: adjacent text nodes with the same marks merged, `marks` sorted and left out
 * when empty. Two documents with the same canonical form render identically; the editor (ProseMirror) works in this
 * form, so round-trip comparisons use it.
 */
export function canonicalRDoc(doc: RDoc): RDoc {
  return { ...doc, blocks: doc.blocks.map(canonicalBlock) };
}

function canonicalBlock(block: RDocBlock): RDocBlock {
  switch (block.type) {
    case 'paragraph':
    case 'heading':
    case 'quote':
    case 'callout':
    case 'summary':
      return { ...block, content: canonicalInline(block.content) };
    case 'bulletList':
    case 'orderedList':
      return { ...block, items: block.items.map(canonicalInline) };
    case 'steps':
      return { ...block, items: block.items.map((item) => ({ ...item, content: canonicalInline(item.content) })) };
    case 'table':
      return { ...block, header: block.header.map(canonicalInline), rows: block.rows.map((row) => row.map(canonicalInline)) };
    default:
      return block;
  }
}

export function canonicalInline(content: InlineContent): InlineContent {
  const result: InlineContent = [];
  for (const node of content) {
    if (node.type !== 'text') {
      result.push(node);
      continue;
    }
    if (!node.text) continue;
    const marks = [...(node.marks ?? [])].sort((a, b) => MARK_ORDER.indexOf(a.type) - MARK_ORDER.indexOf(b.type));
    const last = result[result.length - 1] as InlineNode | undefined;
    if (last?.type === 'text' && sameMarks(last.marks ?? [], marks) && last.text.length + node.text.length <= TEXT_NODE_MAX) {
      result[result.length - 1] = { ...last, text: last.text + node.text };
      continue;
    }
    result.push(marks.length ? { type: 'text', text: node.text, marks } : { type: 'text', text: node.text });
  }
  return result;
}

function sameMarks(a: Mark[], b: Mark[]): boolean {
  return a.length === b.length && a.every((mark, i) => JSON.stringify(mark) === JSON.stringify(b[i]));
}

/** Languages offered for code blocks (the reader highlights these, SPEC §13.2). */
export const CODE_LANGUAGES: readonly { id: string; label: string }[] = [
  { id: 'csharp', label: 'C#' },
  { id: 'typescript', label: 'TypeScript' },
  { id: 'javascript', label: 'JavaScript' },
  { id: 'tsx', label: 'TSX' },
  { id: 'dart', label: 'Dart' },
  { id: 'json', label: 'JSON' },
  { id: 'bash', label: 'Bash' },
  { id: 'powershell', label: 'PowerShell' },
  { id: 'sql', label: 'SQL' },
  { id: 'html', label: 'HTML' },
  { id: 'css', label: 'CSS' },
  { id: 'scss', label: 'SCSS' },
  { id: 'yaml', label: 'YAML' },
  { id: 'python', label: 'Python' },
  { id: 'kotlin', label: 'Kotlin' },
  { id: 'swift', label: 'Swift' },
  { id: 'java', label: 'Java' },
  { id: 'go', label: 'Go' },
  { id: 'rust', label: 'Rust' },
  { id: 'xml', label: 'XML' },
  { id: 'dockerfile', label: 'Dockerfile' },
  { id: 'markdown', label: 'Markdown' },
  { id: 'razor', label: 'Razor' },
  { id: PLAIN_CODE_LANG, label: 'Text' },
];
