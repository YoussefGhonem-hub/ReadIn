import { TextDir, detectDir } from '../directives/bidi';
import { BlockDir, HeadingBlock, InlineContent, RDoc, RDocBlock, RDocLanguage } from './rdoc.models';

export interface TocEntry {
  id: string;
  anchor: string;
  level: 2 | 3;
  text: string;
}

export function headingAnchor(blockId: string): string {
  return `h-${blockId}`;
}

export function languageDir(language: RDocLanguage): TextDir {
  return language === 'en' ? 'ltr' : 'rtl';
}

/**
 * Plain text of inline content. Inline code is skipped by default so a leading `AddScoped` doesn't flip an
 * Arabic paragraph to LTR (the same thing the browser does for `dir="auto"`, which ignores isolated children).
 */
export function inlineText(content: InlineContent | undefined, { includeCode = false } = {}): string {
  if (!content) return '';
  let text = '';
  for (const node of content) {
    if (node.type === 'text') {
      if (!includeCode && node.marks?.some((m) => m.type === 'code')) continue;
      text += node.text;
    } else if (node.type === 'term' || node.type === 'mention') {
      text += node.text;
    } else {
      text += '\n';
    }
  }
  return text;
}

/** Text used to resolve a block's direction. */
export function blockText(block: RDocBlock): string {
  switch (block.type) {
    case 'paragraph':
    case 'heading':
    case 'quote':
    case 'callout':
    case 'summary':
      return (block.type === 'callout' && block.title ? block.title + ' ' : '') + inlineText(block.content);
    case 'bulletList':
    case 'orderedList':
      return block.items.map((item) => inlineText(item)).join(' ');
    case 'steps':
      return block.items.map((item) => `${item.title} ${inlineText(item.content)}`).join(' ');
    case 'table':
      return [...block.header, ...block.rows.flat()].map((cell) => inlineText(cell)).join(' ');
    case 'image':
      return block.caption ?? block.alt;
    default:
      return '';
  }
}

/**
 * Effective direction of a block: an explicit `rtl`/`ltr` wins; `auto` (default) resolves from the block's first
 * strong character, falling back to the article language (SPEC §14.2 rule 1). Code is handled separately (always LTR).
 */
export function resolveBlockDir(block: RDocBlock, dir: BlockDir | undefined, fallback: TextDir): TextDir {
  if (dir === 'rtl' || dir === 'ltr') return dir;
  return detectDir(blockText(block)) ?? fallback;
}

export function tableOfContents(doc: RDoc | null | undefined): TocEntry[] {
  if (!doc) return [];
  return doc.blocks
    .filter((b): b is HeadingBlock => b.type === 'heading')
    .map((b) => ({ id: b.id, anchor: headingAnchor(b.id), level: b.level, text: inlineText(b.content, { includeCode: true }).trim() }));
}

export function hasBlock(doc: RDoc | null | undefined, type: RDocBlock['type']): boolean {
  return !!doc?.blocks.some((b) => b.type === type);
}

/** Only http(s) links are allowed in content (SPEC §13.3, §13.5). */
export function safeHttpUrl(url: string | null | undefined): string | null {
  if (!url) return null;
  return /^https?:\/\/[^\s<>"']+$/i.test(url) ? url : null;
}

const YOUTUBE_ID = /^[A-Za-z0-9_-]{11}$/;

export function youtubeId(url: string): string | null {
  try {
    const u = new URL(url);
    const host = u.hostname.replace(/^www\.|^m\./, '');
    let id: string | null = null;
    if (host === 'youtu.be') id = u.pathname.slice(1);
    else if (host === 'youtube.com' || host === 'youtube-nocookie.com') {
      id = u.searchParams.get('v') ?? u.pathname.match(/^\/(?:embed|shorts|live)\/([^/]+)/)?.[1] ?? null;
    }
    return id && YOUTUBE_ID.test(id) ? id : null;
  } catch {
    return null;
  }
}

const LANG_LABELS: Record<string, string> = {
  csharp: 'C#',
  cs: 'C#',
  typescript: 'TypeScript',
  ts: 'TypeScript',
  tsx: 'TSX',
  javascript: 'JavaScript',
  js: 'JavaScript',
  dart: 'Dart',
  json: 'JSON',
  bash: 'Bash',
  sh: 'Shell',
  shell: 'Shell',
  powershell: 'PowerShell',
  sql: 'SQL',
  html: 'HTML',
  css: 'CSS',
  scss: 'SCSS',
  yaml: 'YAML',
  yml: 'YAML',
  python: 'Python',
  py: 'Python',
  kotlin: 'Kotlin',
  swift: 'Swift',
  xml: 'XML',
  dockerfile: 'Dockerfile',
  java: 'Java',
  go: 'Go',
  rust: 'Rust',
  markdown: 'Markdown',
  razor: 'Razor',
};

export function codeLanguageLabel(lang: string): string {
  return LANG_LABELS[lang.toLowerCase()] ?? lang;
}
