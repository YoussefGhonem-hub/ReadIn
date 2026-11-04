import { RDoc } from '../../../shared/rdoc/rdoc.models';
import { KITCHEN_SINK, bidiDocument } from '../../../../testing/rdoc-testing';
import { PmNode, TEXT_NODE_MAX, canonicalRDoc, editorToRDoc, emptyEditorDoc, isBlockId, newBlockId, rdocToEditor } from './rdoc-convert';

function sequentialIds(prefix = 'n'): () => string {
  let next = 1;
  return () => `${prefix}${next++}`;
}

const roundTrip = (doc: RDoc) => editorToRDoc(rdocToEditor(doc), doc.language);

describe('RDoc ⇄ editor conversion (SPEC §13)', () => {
  it('round-trips the kitchen sink (every block type, mark and inline node) without loss', () => {
    expect(roundTrip(KITCHEN_SINK)).toEqual(canonicalRDoc(KITCHEN_SINK));
    // The only normalization in the canonical form here: the empty `marks: []` of one text node.
    expect(JSON.stringify(canonicalRDoc(KITCHEN_SINK)).length).toBeLessThan(JSON.stringify(KITCHEN_SINK).length);
  });

  it('round-trips every BiDi fixture in every text position, in both article languages', () => {
    for (const language of ['ar-EG', 'en'] as const) {
      const doc = bidiDocument(language);
      expect(roundTrip(doc)).toEqual(doc);
    }
  });

  it('maps every RDoc block type to its editor node and back', () => {
    const editor = rdocToEditor(KITCHEN_SINK);
    expect(editor.type).toBe('doc');
    expect(editor.content!.map((n) => n.type)).toEqual([
      'summary',
      'paragraph',
      'heading',
      'bulletList',
      'orderedList',
      'heading',
      'steps',
      'callout',
      'callout',
      'callout',
      'callout',
      'codeBlock',
      'codeTabs',
      'table',
      'quote',
      'image',
      'horizontalRule',
      'embed',
      'paragraph',
    ]);
    expect(editor.content!.map((n) => n.attrs?.['id'])).toEqual(KITCHEN_SINK.blocks.map((b) => b.id));
  });

  it('keeps glossary terms, mentions and hard breaks exactly as they came', () => {
    const doc: RDoc = {
      version: 1,
      language: 'ar-EG',
      blocks: [
        {
          id: 'p1',
          type: 'paragraph',
          content: [
            { type: 'term', termId: 'dependency-injection', text: 'Dependency Injection' },
            { type: 'hardBreak' },
            { type: 'mention', userId: '0195f3a0-0000-7000-8000-000000000001', text: '@editorial' },
          ],
        },
      ],
    };
    expect(rdocToEditor(doc).content![0].content).toEqual([
      { type: 'term', attrs: { termId: 'dependency-injection', text: 'Dependency Injection' } },
      { type: 'hardBreak' },
      { type: 'mention', attrs: { userId: '0195f3a0-0000-7000-8000-000000000001', text: '@editorial' } },
    ]);
    expect(roundTrip(doc)).toEqual(doc);
  });

  it('keeps attributes the editor has no controls for: highlight lines, compile flags, tab file names, image size', () => {
    const doc: RDoc = {
      version: 1,
      language: 'en',
      blocks: [
        { id: 'c', type: 'code', lang: 'csharp', filename: 'Program.cs', code: 'var x = 1;\n\nvar y = 2;', highlightLines: [1, 3], compile: false },
        { id: 't', type: 'codeTabs', tabs: [{ label: 'C#', lang: 'csharp', filename: 'A.cs', code: 'class A {}', compile: true }] },
        { id: 'i', type: 'image', src: 'rdoc-asset://articles/di/diagram.png', darkSrc: 'rdoc-asset://articles/di/diagram-dark.png', alt: 'Diagram', width: 1200, height: 630 },
      ],
    };
    expect(roundTrip(doc)).toEqual(doc);
  });

  it('writes content.language from the translation it belongs to', () => {
    const doc = editorToRDoc(rdocToEditor(KITCHEN_SINK), 'en');
    expect(doc.language).toBe('en');
    expect(doc.version).toBe(1);
  });

  describe('block ids', () => {
    it('keeps valid ids and gives missing, invalid and duplicate ones a new unique id', () => {
      const editor: PmNode = {
        type: 'doc',
        content: [
          { type: 'paragraph', attrs: { id: 'keep-me', dir: null }, content: [{ type: 'text', text: 'a' }] },
          { type: 'paragraph', attrs: { id: null, dir: null }, content: [{ type: 'text', text: 'b' }] },
          { type: 'paragraph', attrs: { id: 'has space', dir: null }, content: [{ type: 'text', text: 'c' }] },
          { type: 'paragraph', attrs: { id: 'keep-me', dir: null }, content: [{ type: 'text', text: 'd' }] },
          { type: 'horizontalRule', attrs: { id: 'x'.repeat(65) } },
        ],
      };
      const doc = editorToRDoc(editor, 'ar-EG', sequentialIds());
      expect(doc.blocks.map((b) => b.id)).toEqual(['keep-me', 'n1', 'n2', 'n3', 'n4']);
    });

    it('never hands out an id a later block already has (that block keeps it)', () => {
      const editor: PmNode = {
        type: 'doc',
        content: [
          { type: 'paragraph', attrs: { id: null } },
          { type: 'paragraph', attrs: { id: 'n1' } },
        ],
      };
      expect(editorToRDoc(editor, 'ar-EG', sequentialIds()).blocks.map((b) => b.id)).toEqual(['n2', 'n1']);
    });

    it('generates ids the schema accepts', () => {
      const ids = Array.from({ length: 200 }, () => newBlockId());
      expect(ids.every(isBlockId)).toBe(true);
      expect(new Set(ids).size).toBe(200);
    });

    it('gives an empty document one empty paragraph to type in', () => {
      expect(rdocToEditor({ version: 1, language: 'en', blocks: [] }, () => 'first')).toEqual(emptyEditorDoc(() => 'first'));
      expect(editorToRDoc(emptyEditorDoc(() => 'first'), 'en')).toEqual({ version: 1, language: 'en', blocks: [{ id: 'first', type: 'paragraph', content: [] }] });
    });
  });

  describe('work in progress', () => {
    const one = (node: PmNode) => editorToRDoc({ type: 'doc', content: [node] }, 'en', sequentialIds()).blocks;

    it('skips an image that has no picture yet and an embed without a link', () => {
      expect(one({ type: 'image', attrs: { id: 'i', src: null, alt: '' } })).toEqual([]);
      expect(one({ type: 'embed', attrs: { id: 'e', provider: 'youtube', url: '  ' } })).toEqual([]);
    });

    it('saves an image block without alt text (a problem until filled, not an error)', () => {
      expect(one({ type: 'image', attrs: { id: 'i', src: 'https://cdn.test/a.webp', alt: '' } })).toEqual([{ id: 'i', type: 'image', src: 'https://cdn.test/a.webp', alt: '' }]);
    });

    it('saves an empty heading as an empty paragraph (a heading needs text)', () => {
      expect(one({ type: 'heading', attrs: { id: 'h', level: 2, dir: 'rtl' } })).toEqual([{ id: 'h', type: 'paragraph', dir: 'rtl', content: [] }]);
    });

    it('leaves out blank optional strings', () => {
      expect(one({ type: 'callout', attrs: { id: 'c', variant: 'warning', title: '   ' } })).toEqual([{ id: 'c', type: 'callout', variant: 'warning', content: [] }]);
      expect(one({ type: 'quote', attrs: { id: 'q', cite: '' } })).toEqual([{ id: 'q', type: 'quote', content: [] }]);
      expect(one({ type: 'codeBlock', attrs: { id: 'k', language: null, filename: '' } })).toEqual([{ id: 'k', type: 'code', lang: 'text', code: '' }]);
    });

    it('names a code tab after its language when the label is empty', () => {
      expect(one({ type: 'codeTabs', attrs: { id: 't', tabs: [{ label: '', lang: 'csharp', code: '' }, { label: ' ', lang: 'Not Valid', code: 'x' }] } })).toEqual([
        {
          id: 't',
          type: 'codeTabs',
          tabs: [
            { label: 'C#', lang: 'csharp', code: '' },
            { label: 'Text', lang: 'text', code: 'x' },
          ],
        },
      ]);
    });

    it('drops links that are not http(s) and splits text longer than a text node may be', () => {
      const long = 'a'.repeat(TEXT_NODE_MAX + 5);
      const [block] = one({
        type: 'paragraph',
        attrs: { id: 'p' },
        content: [
          { type: 'text', text: 'click', marks: [{ type: 'link', attrs: { href: 'javascript:alert(1)' } }, { type: 'bold' }] },
          { type: 'text', text: long },
        ],
      });
      expect(block).toEqual({
        id: 'p',
        type: 'paragraph',
        content: [
          { type: 'text', text: 'click', marks: [{ type: 'bold' }] },
          { type: 'text', text: 'a'.repeat(TEXT_NODE_MAX) },
          { type: 'text', text: 'aaaaa' },
        ],
      });
    });

    it('turns a step title into one line of plain text', () => {
      const [steps] = one({
        type: 'steps',
        attrs: { id: 's' },
        content: [{ type: 'stepItem', content: [{ type: 'stepTitle', content: [{ type: 'text', text: 'Install' }] }, { type: 'paragraph', content: [{ type: 'text', text: 'npm i' }] }] }],
      });
      expect(steps).toEqual({ id: 's', type: 'steps', items: [{ title: 'Install', content: [{ type: 'text', text: 'npm i' }] }] });
    });
  });

  describe('canonicalRDoc', () => {
    it('merges adjacent text with the same marks, sorts marks and drops empty mark lists', () => {
      const doc: RDoc = {
        version: 1,
        language: 'en',
        blocks: [
          {
            id: 'p',
            type: 'paragraph',
            content: [
              { type: 'text', text: 'a', marks: [] },
              { type: 'text', text: 'b' },
              { type: 'text', text: 'c', marks: [{ type: 'code' }, { type: 'bold' }] },
              { type: 'text', text: 'd', marks: [{ type: 'bold' }, { type: 'code' }] },
            ],
          },
        ],
      };
      expect(canonicalRDoc(doc).blocks[0]).toEqual({
        id: 'p',
        type: 'paragraph',
        content: [
          { type: 'text', text: 'ab' },
          { type: 'text', text: 'cd', marks: [{ type: 'bold' }, { type: 'code' }] },
        ],
      });
    });
  });
});
