import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import kitchenSink from '../../../../../shared/rdoc/examples/kitchen-sink.ar-EG.json';
import { translocoTesting } from '../../../testing/transloco-testing';
import { provideAppIcons } from '../ui/icons';
import { HighlighterService } from './highlighter.service';
import { RDocRenderer } from './rdoc-renderer';
import { RDOC_BLOCK_TYPES, RDoc } from './rdoc.models';
import { TermSheetService } from './rdoc-context';

const doc = kitchenSink as unknown as RDoc;

async function render(document: RDoc): Promise<HTMLElement> {
  const fixture = TestBed.createComponent(RDocRenderer);
  fixture.componentRef.setInput('doc', document);
  await fixture.whenStable();
  return fixture.nativeElement as HTMLElement;
}

describe('RDocRenderer (shared/rdoc/examples/kitchen-sink.ar-EG.json)', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [translocoTesting()],
      providers: [
        provideRouter([]),
        provideAppIcons(),
        // Shiki is browser-only and lazy; plain rendering is what SSR and the first paint show.
        { provide: HighlighterService, useValue: { highlight: () => Promise.resolve(null) } },
      ],
    });
  });

  it('uses every block type in the fixture', () => {
    const used = new Set(doc.blocks.map((b) => b.type));
    expect([...RDOC_BLOCK_TYPES].filter((t) => !used.has(t))).toEqual([]);
  });

  it('renders every block type (SPEC §13.2)', async () => {
    const el = await render(doc);
    for (const type of RDOC_BLOCK_TYPES) {
      expect(el.querySelector(`[data-block-type="${type}"]`), `block ${type}`).not.toBeNull();
    }
    expect(el.querySelectorAll('[data-block-id]').length).toBe(doc.blocks.length);
  });

  it('renders the article in its language direction', async () => {
    const el = await render(doc);
    expect(el.getAttribute('dir')).toBe('rtl');
    expect(el.getAttribute('lang')).toBe('ar-EG');
  });

  it('always renders code and code tabs LTR (SPEC §14.2 rule 3)', async () => {
    const el = await render(doc);
    const codeBlocks = el.querySelectorAll('[data-block-type="code"], [data-block-type="codeTabs"], .rd-code');
    expect(codeBlocks.length).toBeGreaterThanOrEqual(2);
    codeBlocks.forEach((block) => expect(block.getAttribute('dir')).toBe('ltr'));
    expect(el.querySelector('code.rd-inline-code')?.getAttribute('dir')).toBe('ltr');
  });

  it('shows filename, language label and highlighted lines', async () => {
    const el = await render(doc);
    const code = el.querySelector('[data-block-id="code1"]') as HTMLElement;
    expect(code.textContent).toContain('Program.cs');
    expect(code.textContent).toContain('C#');
    const lines = code.querySelectorAll('.line');
    expect(lines.length).toBe(3);
    expect(lines[1].classList.contains('highlighted')).toBe(true);
    expect(lines[0].classList.contains('highlighted')).toBe(false);
  });

  it('wraps inline English inside Arabic paragraphs in <bdi>', async () => {
    const el = await render(doc);
    const p1 = el.querySelector('[data-block-id="p1"]') as HTMLElement;
    expect(p1.getAttribute('dir')).toBe('rtl');
    const isolated = [...p1.querySelectorAll('bdi')].map((b) => b.textContent);
    expect(isolated).toContain('ASP.NET Core');
    expect(isolated).toContain('Dependency Injection');
  });

  it('resolves block direction from content (English quote inside an Arabic article)', async () => {
    const el = await render(doc);
    expect(el.querySelector('[data-block-id="q1"]')?.getAttribute('dir')).toBe('ltr');
  });

  it('renders safe links, terms, mentions and hard breaks', async () => {
    const el = await render(doc);
    const link = el.querySelector('[data-block-id="p1"] a') as HTMLAnchorElement;
    expect(link.getAttribute('href')).toMatch(/^https:\/\/learn\.microsoft\.com\//);
    expect(link.getAttribute('rel')).toContain('nofollow');
    expect(el.querySelector('[data-term="dependency-injection"]')).not.toBeNull();
    expect(el.querySelector('.rd-mention')?.textContent?.trim()).toBe('@editorial');
    expect(el.querySelector('[data-block-id="p2"] br')).not.toBeNull();
  });

  it('opens the glossary sheet when a term is tapped', async () => {
    const el = await render(doc);
    (el.querySelector('[data-term="dependency-injection"]') as HTMLButtonElement).click();
    expect(TestBed.inject(TermSheetService).openTerm()).toEqual({ termId: 'dependency-injection', text: 'Dependency Injection' });
  });

  it('renders callout variants with default titles', async () => {
    const el = await render(doc);
    const variants = [...el.querySelectorAll('[data-block-type="callout"]')].map((c) => c.getAttribute('data-variant'));
    expect(variants).toEqual(['tip', 'info', 'warning', 'danger']);
    expect(el.querySelector('[data-variant="info"]')?.textContent).toContain('معلومة');
  });

  it('renders darkSrc as a dark-only image and uses a privacy-friendly YouTube embed', async () => {
    const el = await render(doc);
    const imgs = el.querySelectorAll('[data-block-type="image"] img');
    expect(imgs.length).toBe(2);
    expect(imgs[0].classList.contains('rd-only-light')).toBe(true);
    expect(imgs[1].classList.contains('rd-only-dark')).toBe(true);
    expect(el.querySelector('[data-block-type="embed"] iframe')?.getAttribute('src')).toBe('https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ');
  });

  it('drops non-http links and unknown block types without breaking', async () => {
    const unsafe = {
      version: 1,
      language: 'en',
      blocks: [
        { id: 'a', type: 'paragraph', content: [{ type: 'text', text: 'click', marks: [{ type: 'link', href: 'javascript:alert(1)' }] }] },
        { id: 'b', type: 'futureBlock' },
      ],
    } as unknown as RDoc;
    const el = await render(unsafe);
    expect(el.querySelector('a')).toBeNull();
    expect(el.textContent).toContain('click');
    expect(el.getAttribute('dir')).toBe('ltr');
  });
});
