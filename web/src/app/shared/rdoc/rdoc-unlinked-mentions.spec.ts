import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { KITCHEN_SINK } from '../../../testing/rdoc-testing';
import { translocoTesting } from '../../../testing/transloco-testing';
import { provideAppIcons } from '../ui/icons';
import { HighlighterService } from './highlighter.service';
import { RDocRenderer } from './rdoc-renderer';

/** The kitchen sink's one mention (block p2). */
const EDITORIAL = '0195f3a0-0000-7000-8000-000000000001';

describe('RDocRenderer: mentions of people you are blocked with (F36)', () => {
  beforeEach(() => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      imports: [translocoTesting()],
      providers: [provideRouter([]), provideAppIcons(), { provide: HighlighterService, useValue: { highlight: () => Promise.resolve(null) } }],
    });
  });

  async function render(unlinked: string[] | null) {
    const fixture = TestBed.createComponent(RDocRenderer);
    fixture.componentRef.setInput('doc', KITCHEN_SINK);
    if (unlinked) fixture.componentRef.setInput('unlinkedMentions', unlinked);
    await fixture.whenStable();
    return fixture.nativeElement as HTMLElement;
  }

  it('stay plain text without a link or profile card', async () => {
    const el = await render([EDITORIAL]);
    const p2 = el.querySelector('[data-block-id="p2"]')!;
    expect(p2.querySelector('.rd-mention')).toBeNull();
    expect(p2.querySelector('a')).toBeNull();
    expect(p2.querySelector('[data-unlinked-mention]')!.textContent!.trim()).toBe('@editorial');
  });

  it('every other mention is a link', async () => {
    for (const unlinked of [null, [], ['someone-else']]) {
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        imports: [translocoTesting()],
        providers: [provideRouter([]), provideAppIcons(), { provide: HighlighterService, useValue: { highlight: () => Promise.resolve(null) } }],
      });
      const el = await render(unlinked);
      expect(el.querySelector('[data-block-id="p2"] .rd-mention')!.getAttribute('href')).toBe('/@editorial');
      expect(el.querySelector('[data-unlinked-mention]')).toBeNull();
    }
  });
});
