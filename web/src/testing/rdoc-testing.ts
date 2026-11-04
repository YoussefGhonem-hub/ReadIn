import kitchenSink from '../../../shared/rdoc/examples/kitchen-sink.ar-EG.json';
import bidiFile from '../../../shared/bidi/fixtures.json';
import { InlineContent, RDoc, RDocBlock } from '../app/shared/rdoc/rdoc.models';

export interface BidiFixture {
  id: string;
  text: string;
  expectedDir: 'rtl' | 'ltr';
}

/** shared/rdoc/examples/kitchen-sink.ar-EG.json: every block type, mark and inline node. */
export const KITCHEN_SINK = kitchenSink as unknown as RDoc;

/** shared/bidi/fixtures.json (SPEC §14.2 rule 7). */
export const BIDI_FIXTURES = (bidiFile as { fixtures: BidiFixture[] }).fixtures;

const text = (value: string): InlineContent => [{ type: 'text', text: value }];

/** Every BiDi fixture in every place an RDoc document holds text. */
export function bidiDocument(language: RDoc['language'] = 'ar-EG'): RDoc {
  const blocks: RDocBlock[] = [];
  BIDI_FIXTURES.forEach((f, i) => {
    blocks.push({ id: `p-${f.id}`, type: 'paragraph', content: text(f.text) });
    blocks.push({ id: `h-${f.id}`, type: 'heading', level: i % 2 ? 3 : 2, dir: 'auto', content: text(f.text) });
    blocks.push({ id: `c-${f.id}`, type: 'callout', variant: 'info', title: f.text, content: text(f.text) });
    blocks.push({ id: `q-${f.id}`, type: 'quote', cite: f.text, content: text(f.text) });
  });
  blocks.push({ id: 'ul', type: 'bulletList', items: BIDI_FIXTURES.map((f) => text(f.text)) });
  blocks.push({ id: 'ol', type: 'orderedList', dir: 'rtl', items: BIDI_FIXTURES.map((f) => text(f.text)) });
  blocks.push({ id: 'steps', type: 'steps', items: BIDI_FIXTURES.map((f) => ({ title: f.text, content: text(f.text) })) });
  blocks.push({ id: 'sum', type: 'summary', dir: 'ltr', content: text(BIDI_FIXTURES[0].text) });
  blocks.push({ id: 'tbl', type: 'table', header: [text('Text'), text('النص')], rows: BIDI_FIXTURES.map((f) => [text(f.id), text(f.text)]) });
  blocks.push({ id: 'img', type: 'image', src: 'https://cdn.test/uploads/a/1600.webp', alt: BIDI_FIXTURES[1].text, caption: BIDI_FIXTURES[2].text, width: 1600, height: 900 });
  blocks.push({ id: 'code', type: 'code', lang: 'text', code: BIDI_FIXTURES.map((f) => f.text).join('\n') });
  return { version: 1, language, blocks };
}
