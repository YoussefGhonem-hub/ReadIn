import { Editor } from '@tiptap/core';
import { TextSelection } from '@tiptap/pm/state';
import { RDoc } from '../../../shared/rdoc/rdoc.models';
import { RDocEditorHost } from './editor-host';
import { editorBlockDir, ensureBlockIds } from './editor-plugins';
import { PmNode, canonicalRDoc, editorToRDoc, rdocToEditor } from './rdoc-convert';
import { BIDI_FIXTURES, KITCHEN_SINK, bidiDocument } from '../../../../testing/rdoc-testing';
import { rdocExtensions } from './rdoc-schema';

const FIXTURES = BIDI_FIXTURES;

const host: RDocEditorHost = {
  t: (key) => key,
  uploadImage: () => Promise.reject('unknown'),
  uploadsChanged: () => undefined,
  resolveAsset: (src) => src,
  fallbackDir: () => 'rtl',
};

let counter = 0;
const ids = () => `t${++counter}`;

function createEditor(doc: RDoc | null): Editor {
  const element = document.createElement('div');
  document.body.appendChild(element);
  const editor = new Editor({ element, extensions: rdocExtensions(host, [], ids), content: rdocToEditor(doc, ids) as never });
  editor.view.dispatch(ensureBlockIds(editor.state.tr, ids));
  return editor;
}

const toRDoc = (editor: Editor, language: RDoc['language'] = 'ar-EG') => editorToRDoc(editor.getJSON() as PmNode, language, ids);

/** Types `text` like a keyboard does, so input rules (markdown shortcuts) run. */
function type(editor: Editor, text: string): void {
  for (const char of text) {
    const { from, to } = editor.state.selection;
    const handled = editor.view.someProp('handleTextInput', (f) => f(editor.view, from, to, char, () => editor.state.tr.insertText(char, from, to)));
    if (!handled) editor.view.dispatch(editor.state.tr.insertText(char, from, to));
  }
}

function press(editor: Editor, key: string): void {
  const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true });
  editor.view.someProp('handleKeyDown', (f) => f(editor.view, event));
}

function topTypes(editor: Editor): string[] {
  const types: string[] = [];
  editor.state.doc.forEach((node) => types.push(node.type.name));
  return types;
}

describe('RDoc editor schema (Tiptap)', () => {
  let editor: Editor;
  afterEach(() => editor?.destroy());

  it('loads the kitchen sink and gives it back without loss', () => {
    editor = createEditor(KITCHEN_SINK);
    expect(toRDoc(editor)).toEqual(canonicalRDoc(KITCHEN_SINK));
  });

  it('loads every BiDi fixture in every text position and gives it back without loss', () => {
    for (const language of ['ar-EG', 'en'] as const) {
      editor = createEditor(bidiDocument(language));
      expect(toRDoc(editor, language)).toEqual(bidiDocument(language));
      editor.destroy();
    }
  });

  it('resolves each block direction like the reader (first strong character, overrides, code always LTR)', () => {
    editor = createEditor(bidiDocument());
    const dirs = new Map<string, string | null>();
    editor.state.doc.forEach((node) => dirs.set(String(node.attrs['id']), editorBlockDir(node, 'rtl')));
    for (const fixture of FIXTURES) {
      expect(dirs.get(`p-${fixture.id}`), fixture.id).toBe(fixture.expectedDir);
      expect(dirs.get(`h-${fixture.id}`), fixture.id).toBe(fixture.expectedDir);
    }
    expect(dirs.get('ol')).toBe('rtl'); // manual override
    expect(dirs.get('sum')).toBe('ltr'); // manual override on Arabic text
    expect(dirs.get('code')).toBe('ltr');
    expect(dirs.get('img')).toBeNull();

    // The DOM gets the same direction, and English inside Arabic is isolated in <bdi>.
    const paragraph = editor.view.dom.querySelector('[data-block-id="p-english-term-question"]')!;
    expect(paragraph.getAttribute('dir')).toBe('rtl');
    expect([...paragraph.querySelectorAll('bdi')].map((b) => b.textContent)).toEqual(['Dependency Injection']);
    expect(editor.view.dom.querySelector('[data-block-id="code"]')!.getAttribute('dir')).toBe('ltr');
  });

  it('keeps block ids stable and unique while editing', () => {
    editor = createEditor({ version: 1, language: 'en', blocks: [{ id: 'first', type: 'paragraph', content: [{ type: 'text', text: 'Hello world' }] }] });
    // Split the paragraph in the middle: the first half keeps the id, the second gets a new one.
    editor.commands.setTextSelection(6);
    editor.commands.splitBlock();
    const [a, b] = toRDoc(editor, 'en').blocks;
    expect(a.id).toBe('first');
    expect(b.id).toMatch(/^t\d+$/);

    // Changing the block type keeps the id.
    editor.commands.setTextSelection(2);
    editor.commands.setNode('heading', { level: 2 });
    expect(toRDoc(editor, 'en').blocks[0]).toMatchObject({ id: 'first', type: 'heading', level: 2 });

    // Pasting a copy of a block: the copy gets a new id.
    const json = editor.getJSON() as PmNode;
    editor.commands.insertContentAt(editor.state.doc.content.size, json.content![0] as never);
    const after = toRDoc(editor, 'en').blocks.map((block) => block.id);
    expect(new Set(after).size).toBe(after.length);
    expect(after[0]).toBe('first');
  });

  it('turns markdown shortcuts into blocks and marks', () => {
    editor = createEditor(null);
    const reset = () => editor.commands.setContent(rdocToEditor(null, ids) as never);
    const cases: [string, string, Record<string, unknown>?][] = [
      ['# ', 'heading', { level: 2 }],
      ['## ', 'heading', { level: 3 }],
      ['- ', 'bulletList'],
      ['* ', 'bulletList'],
      ['1. ', 'orderedList'],
      ['> ', 'quote'],
      ['```', 'codeBlock'],
    ];
    for (const [input, nodeType, attrs] of cases) {
      reset();
      editor.commands.focus('start');
      type(editor, input);
      if (input === '```') type(editor, ' ');
      expect(topTypes(editor)[0], input).toBe(nodeType);
      if (attrs) expect(editor.state.doc.firstChild!.attrs, input).toMatchObject(attrs);
    }

    reset();
    editor.commands.focus('start');
    type(editor, '---');
    expect(topTypes(editor)).toContain('horizontalRule');

    reset();
    editor.commands.focus('start');
    type(editor, 'make it **bold** and `code` ');
    expect(toRDoc(editor).blocks[0]).toMatchObject({
      type: 'paragraph',
      content: [
        { type: 'text', text: 'make it ' },
        { type: 'text', text: 'bold', marks: [{ type: 'bold' }] },
        { type: 'text', text: ' and ' },
        { type: 'text', text: 'code', marks: [{ type: 'code' }] },
        { type: 'text', text: ' ' },
      ],
    });
  });

  it('only accepts http(s) links', () => {
    editor = createEditor({ version: 1, language: 'en', blocks: [{ id: 'p', type: 'paragraph', content: [{ type: 'text', text: 'docs' }] }] });
    editor.commands.setTextSelection({ from: 1, to: 5 });
    expect(editor.commands.setLink({ href: 'javascript:alert(1)' })).toBe(false);
    expect(editor.commands.setLink({ href: 'https://learn.microsoft.com' })).toBe(true);
    expect(toRDoc(editor, 'en').blocks[0]).toEqual({
      id: 'p',
      type: 'paragraph',
      content: [{ type: 'text', text: 'docs', marks: [{ type: 'link', href: 'https://learn.microsoft.com' }] }],
    });
  });

  it('writes steps: Enter goes from the title to its text, then to a new step; an empty last step leaves the block', () => {
    editor = createEditor({ version: 1, language: 'en', blocks: [{ id: 's', type: 'steps', items: [{ title: '', content: [] }] }] });
    editor.view.dispatch(editor.state.tr.setSelection(TextSelection.create(editor.state.doc, 3)));
    type(editor, 'Install');
    press(editor, 'Enter');
    type(editor, 'npm i');
    press(editor, 'Enter');
    type(editor, 'Run');
    press(editor, 'Enter');
    press(editor, 'Enter'); // empty text of step 2 is not "empty step": the title has text → a third step
    press(editor, 'Enter'); // the empty third step leaves the block
    expect(toRDoc(editor, 'en').blocks).toEqual([
      {
        id: 's',
        type: 'steps',
        items: [
          { title: 'Install', content: [{ type: 'text', text: 'npm i' }] },
          { title: 'Run', content: [] },
        ],
      },
      { id: expect.any(String), type: 'paragraph', content: [] },
    ]);
  });

  it('Enter in a callout adds a line break; Enter on an empty last line leaves it', () => {
    editor = createEditor({ version: 1, language: 'en', blocks: [{ id: 'c', type: 'callout', variant: 'tip', content: [{ type: 'text', text: 'Tip' }] }] });
    editor.commands.setTextSelection(4);
    press(editor, 'Enter');
    type(editor, 'more');
    press(editor, 'Enter');
    press(editor, 'Enter');
    expect(toRDoc(editor, 'en').blocks).toEqual([
      { id: 'c', type: 'callout', variant: 'tip', content: [{ type: 'text', text: 'Tip' }, { type: 'hardBreak' }, { type: 'text', text: 'more' }] },
      { id: expect.any(String), type: 'paragraph', content: [] },
    ]);
  });
});
