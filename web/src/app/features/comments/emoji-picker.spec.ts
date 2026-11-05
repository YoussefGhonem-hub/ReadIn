import { TestBed } from '@angular/core/testing';
import { setupSocialTesting } from '../../../testing/social-testing';
import { LanguageService } from '../../core/i18n/language.service';
import { EMOJI_CATEGORIES } from './emoji-data';
import { EmojiPicker } from './emoji-picker';

async function render(lang: 'ar' | 'en' = 'en') {
  setupSocialTesting();
  await TestBed.inject(LanguageService).setLanguage(lang);
  const fixture = TestBed.createComponent(EmojiPicker);
  const picked: string[] = [];
  let closed = 0;
  fixture.componentInstance.picked.subscribe((e) => picked.push(e));
  fixture.componentInstance.closed.subscribe(() => closed++);
  fixture.autoDetectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const stable = () => fixture.whenStable();
  return { root, picked, closed: () => closed, stable };
}

function key(target: Element, key: string): void {
  target.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true }));
}

describe('EmojiPicker (F11)', () => {
  beforeEach(() => TestBed.resetTestingModule());

  it('lists well-supported emoji in named categories, with no repeats inside one', () => {
    expect(EMOJI_CATEGORIES.map((c) => c.id)).toEqual(['smileys', 'people', 'hearts', 'nature', 'food', 'activities', 'travel', 'objects', 'symbols']);
    for (const category of EMOJI_CATEGORIES) {
      expect(category.emoji.length).toBeGreaterThan(20);
      expect(new Set(category.emoji).size).toBe(category.emoji.length);
    }
  });

  it('tabs with their names; a tab shows its emoji; a pick is emitted', async () => {
    const t = await render();
    const tabs = [...t.root.querySelectorAll<HTMLElement>('[role="tab"]')];
    expect(tabs.map((tab) => tab.getAttribute('aria-label'))).toEqual(['Smileys', 'People & gestures', 'Hearts', 'Animals & nature', 'Food & drink', 'Activities', 'Travel & places', 'Objects', 'Symbols']);
    expect(tabs[0].getAttribute('aria-selected')).toBe('true');
    const panel = t.root.querySelector('[role="tabpanel"]')!;
    expect(panel.getAttribute('aria-labelledby')).toBe(tabs[0].id);

    tabs[2].click();
    await t.stable();
    expect(tabs[2].getAttribute('aria-selected')).toBe('true');
    expect(panel.getAttribute('aria-labelledby')).toBe(tabs[2].id);
    const first = panel.querySelector<HTMLElement>('[data-emoji]')!;
    expect(first.textContent!.trim()).toBe('❤️');
    first.click();
    expect(t.picked).toEqual(['❤️']);
  });

  it('the tabs follow the reading direction from the keyboard; Escape asks to close', async () => {
    const t = await render('ar');
    const tablist = t.root.querySelector('[role="tablist"]')!;
    key(tablist.querySelector('[aria-selected="true"]')!, 'ArrowLeft'); // RTL: forward
    await t.stable();
    expect(tablist.querySelector('[aria-selected="true"]')!.getAttribute('data-emoji-category')).toBe('people');
    key(tablist.querySelector('[aria-selected="true"]')!, 'End');
    await t.stable();
    expect(tablist.querySelector('[aria-selected="true"]')!.getAttribute('data-emoji-category')).toBe('symbols');
    key(tablist, 'Escape');
    expect(t.closed()).toBe(1);
  });
});
