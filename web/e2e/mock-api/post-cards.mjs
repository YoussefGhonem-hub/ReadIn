/**
 * The post card's text (F34) for the mock API, by the contract's rules (docs/api/contract-v1.md "Post-card text"), so
 * the cards and `GET /articles/{id}/preview` agree with the articles the reader shows.
 */

const EXCERPT_MAX = 400;
const PREVIEW_WORDS = 300;

const inlineText = (nodes = []) => nodes.map((n) => (n.type === 'hardBreak' ? '\n' : (n.text ?? ''))).join('');
const normalize = (value) => (value ?? '').replace(/[ \t]+/g, ' ').replace(/\s*\n\s*/g, '\n').trim();

/** `{ excerpt, hasMore }`: summary, paragraphs, list items, steps, quotes and callouts, one line each; the rest is skipped. */
export function excerptOf(blocks) {
  const lines = [];
  let skipped = false;
  const add = (value) => {
    const line = normalize(value);
    if (line) lines.push(line);
  };
  for (const block of blocks) {
    switch (block.type) {
      case 'paragraph':
      case 'summary':
        add(inlineText(block.content));
        break;
      case 'quote':
        add(inlineText(block.content));
        if (block.cite?.trim()) skipped = true;
        break;
      case 'callout':
        add(block.title);
        add(inlineText(block.content));
        break;
      case 'bulletList':
      case 'orderedList':
        for (const item of block.items) add(inlineText(item));
        break;
      case 'steps':
        for (const step of block.items) {
          add(step.title);
          add(inlineText(step.content));
        }
        break;
      case 'divider':
        break;
      default:
        skipped = true;
    }
  }
  const text = lines.join('\n');
  if (text.length <= EXCERPT_MAX) return { excerpt: text, hasMore: skipped || text.length === 0 };
  let end = EXCERPT_MAX;
  if (!/\s/.test(text[end])) {
    const space = text.lastIndexOf(' ', end - 1);
    const lineBreak = text.lastIndexOf('\n', end - 1);
    end = Math.max(space, lineBreak) > 0 ? Math.max(space, lineBreak) : end;
  }
  return { excerpt: text.slice(0, end).trimEnd(), hasMore: true };
}

function wordsOf(block) {
  const text = [
    inlineText(block.content),
    block.title ?? '',
    ...(block.items ?? []).map((item) => (Array.isArray(item) ? inlineText(item) : `${item.title ?? ''} ${inlineText(item.content)}`)),
    block.code ?? '',
  ].join(' ');
  return text.split(/\s+/).filter(Boolean).length;
}

/** `ArticlePreviewDto.content` + `isComplete`: whole blocks until ~300 words, at least one, never ending on a heading. */
export function previewOf(content) {
  const blocks = [];
  let words = 0;
  for (const block of content.blocks) {
    blocks.push(block);
    words += wordsOf(block);
    if (words >= PREVIEW_WORDS) break;
  }
  const isComplete = blocks.length === content.blocks.length;
  while (!isComplete && blocks.length > 1 && ['heading', 'divider'].includes(blocks[blocks.length - 1].type)) blocks.pop();
  return { content: { ...content, blocks }, isComplete };
}
