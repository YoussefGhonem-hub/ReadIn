/**
 * RDoc v1 — ReadIn Document (SPEC §13). Mirrors shared/rdoc/rdoc.schema.json.
 * Content is structured JSON; it is never stored or rendered as raw HTML.
 */

export type RDocLanguage = 'ar-EG' | 'en';
export type BlockDir = 'auto' | 'rtl' | 'ltr';

// ── Inline ──────────────────────────────────────────────────

export type Mark =
  | { type: 'bold' }
  | { type: 'italic' }
  | { type: 'code' }
  | { type: 'highlight' }
  | { type: 'strike' }
  | { type: 'link'; href: string };

export type MarkType = Mark['type'];

export interface TextNode {
  type: 'text';
  text: string;
  marks?: Mark[];
}

export interface TermNode {
  type: 'term';
  termId: string;
  text: string;
}

export interface MentionNode {
  type: 'mention';
  userId: string;
  text: string;
}

export interface HardBreakNode {
  type: 'hardBreak';
}

export type InlineNode = TextNode | TermNode | MentionNode | HardBreakNode;
export type InlineContent = InlineNode[];

// ── Blocks ──────────────────────────────────────────────────

interface BlockBase {
  id: string;
}

export interface ParagraphBlock extends BlockBase {
  type: 'paragraph';
  dir?: BlockDir;
  content: InlineContent;
}

export interface HeadingBlock extends BlockBase {
  type: 'heading';
  level: 2 | 3;
  dir?: BlockDir;
  content: InlineContent;
}

export interface BulletListBlock extends BlockBase {
  type: 'bulletList';
  dir?: BlockDir;
  items: InlineContent[];
}

export interface OrderedListBlock extends BlockBase {
  type: 'orderedList';
  dir?: BlockDir;
  items: InlineContent[];
}

export interface StepItem {
  title: string;
  content: InlineContent;
}

export interface StepsBlock extends BlockBase {
  type: 'steps';
  dir?: BlockDir;
  items: StepItem[];
}

export interface QuoteBlock extends BlockBase {
  type: 'quote';
  dir?: BlockDir;
  content: InlineContent;
  cite?: string;
}

export type CalloutVariant = 'tip' | 'info' | 'warning' | 'danger';

export interface CalloutBlock extends BlockBase {
  type: 'callout';
  variant: CalloutVariant;
  title?: string;
  dir?: BlockDir;
  content: InlineContent;
}

export interface CodeBlock extends BlockBase {
  type: 'code';
  lang: string;
  filename?: string;
  code: string;
  highlightLines?: number[];
  compile?: boolean;
}

export interface CodeTab {
  label: string;
  lang: string;
  filename?: string;
  code: string;
  compile?: boolean;
}

export interface CodeTabsBlock extends BlockBase {
  type: 'codeTabs';
  tabs: CodeTab[];
}

export interface TableBlock extends BlockBase {
  type: 'table';
  dir?: BlockDir;
  header: InlineContent[];
  rows: InlineContent[][];
}

export interface ImageBlock extends BlockBase {
  type: 'image';
  src: string;
  darkSrc?: string;
  alt: string;
  caption?: string;
  width?: number;
  height?: number;
}

export interface DividerBlock extends BlockBase {
  type: 'divider';
}

export interface EmbedBlock extends BlockBase {
  type: 'embed';
  provider: 'youtube' | 'github-gist';
  url: string;
}

export interface SummaryBlock extends BlockBase {
  type: 'summary';
  dir?: BlockDir;
  content: InlineContent;
}

export type RDocBlock =
  | ParagraphBlock
  | HeadingBlock
  | BulletListBlock
  | OrderedListBlock
  | StepsBlock
  | QuoteBlock
  | CalloutBlock
  | CodeBlock
  | CodeTabsBlock
  | TableBlock
  | ImageBlock
  | DividerBlock
  | EmbedBlock
  | SummaryBlock;

export type RDocBlockType = RDocBlock['type'];

export const RDOC_BLOCK_TYPES: readonly RDocBlockType[] = [
  'paragraph',
  'heading',
  'bulletList',
  'orderedList',
  'steps',
  'quote',
  'callout',
  'code',
  'codeTabs',
  'table',
  'image',
  'divider',
  'embed',
  'summary',
];

export interface RDoc {
  version: 1;
  language: RDocLanguage;
  blocks: RDocBlock[];
}
