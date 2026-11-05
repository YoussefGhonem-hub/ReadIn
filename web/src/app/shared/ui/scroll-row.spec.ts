import { Component, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { LanguageService, UiLanguage } from '../../core/i18n/language.service';
import { provideAppIcons } from './icons';
import { ScrollRow } from './scroll-row';

@Component({
  imports: [ScrollRow],
  template: `
    <rd-scroll-row label="Filter by field">
      <button type="button" class="rd-chip">All</button>
      <button type="button" class="rd-chip">.NET</button>
      <button type="button" class="rd-chip">Flutter</button>
    </rd-scroll-row>
  `,
})
class Host {}

@Component({
  imports: [ScrollRow],
  template: `
    <rd-scroll-row [role]="'tablist'" label="Profile" [flush]="true">
      <button type="button" role="tab">Articles</button>
      <button type="button" role="tab">About</button>
    </rd-scroll-row>
  `,
})
class TabsHost {}

interface Layout {
  scrollWidth: number;
  clientWidth: number;
  scrollLeft: number;
}

async function render<T = Host>(lang: UiLanguage = 'en', host: new () => T = Host as new () => T): Promise<ComponentFixture<T>> {
  TestBed.configureTestingModule({
    providers: [provideAppIcons(), { provide: LanguageService, useValue: { lang: signal(lang), dir: signal(lang === 'ar' ? 'rtl' : 'ltr') } }],
  });
  const fixture = TestBed.createComponent(host);
  await fixture.whenStable();
  return fixture;
}

const el = (fixture: ComponentFixture<Host>) => fixture.nativeElement as HTMLElement;
const track = (fixture: ComponentFixture<Host>) => el(fixture).querySelector('[data-scroll-track]') as HTMLElement;
const startArrow = (fixture: ComponentFixture<Host>) => el(fixture).querySelector<HTMLButtonElement>('[data-scroll-start]');
const endArrow = (fixture: ComponentFixture<Host>) => el(fixture).querySelector<HTMLButtonElement>('[data-scroll-end]');

/** jsdom has no layout: give the track a size and a scroll position, then let it measure (a scroll event). */
async function layout(fixture: ComponentFixture<Host>, values: Layout): Promise<HTMLElement> {
  const row = track(fixture);
  for (const [name, value] of Object.entries(values)) {
    Object.defineProperty(row, name, { configurable: true, writable: true, value });
  }
  row.dispatchEvent(new Event('scroll'));
  await fixture.whenStable();
  return row;
}

describe('ScrollRow', () => {
  it('is the labelled toolbar around the chips, with no arrows or fades when everything fits', async () => {
    const fixture = await render();
    const row = await layout(fixture, { scrollWidth: 300, clientWidth: 300, scrollLeft: 0 });

    expect(row.getAttribute('role')).toBe('toolbar');
    expect(row.getAttribute('aria-label')).toBe('Filter by field');
    expect(row.querySelectorAll('.rd-chip').length).toBe(3);
    expect(startArrow(fixture)).toBeNull();
    expect(endArrow(fixture)).toBeNull();
    expect(row.classList.contains('rd-scroll-row-fade-start')).toBe(false);
    expect(row.classList.contains('rd-scroll-row-fade-end')).toBe(false);
  });

  it('at the start of a long row: only the end fades and only the end arrow shows', async () => {
    const fixture = await render();
    const row = await layout(fixture, { scrollWidth: 900, clientWidth: 300, scrollLeft: 0 });

    expect(startArrow(fixture)).toBeNull();
    expect(endArrow(fixture)).not.toBeNull();
    expect(row.classList.contains('rd-scroll-row-fade-start')).toBe(false);
    expect(row.classList.contains('rd-scroll-row-fade-end')).toBe(true);
  });

  it('in the middle both edges fade and both arrows show; at the end only the start does', async () => {
    const fixture = await render();
    let row = await layout(fixture, { scrollWidth: 900, clientWidth: 300, scrollLeft: 250 });
    expect(startArrow(fixture)).not.toBeNull();
    expect(endArrow(fixture)).not.toBeNull();
    expect(row.classList.contains('rd-scroll-row-fade-start')).toBe(true);
    expect(row.classList.contains('rd-scroll-row-fade-end')).toBe(true);

    row = await layout(fixture, { scrollWidth: 900, clientWidth: 300, scrollLeft: 600 });
    expect(startArrow(fixture)).not.toBeNull();
    expect(endArrow(fixture)).toBeNull();
    expect(row.classList.contains('rd-scroll-row-fade-end')).toBe(false);
  });

  it('keeps the arrows out of the tab order and the accessibility tree (chips are reachable themselves)', async () => {
    const fixture = await render();
    await layout(fixture, { scrollWidth: 900, clientWidth: 300, scrollLeft: 250 });

    for (const arrow of [startArrow(fixture)!, endArrow(fixture)!]) {
      expect(arrow.getAttribute('tabindex')).toBe('-1');
      expect(arrow.getAttribute('aria-hidden')).toBe('true');
      expect(arrow.classList.contains('rd-chip')).toBe(false);
    }
  });

  it('pages 80% of the visible width towards the end, to the right in English', async () => {
    const fixture = await render('en');
    const row = await layout(fixture, { scrollWidth: 900, clientWidth: 300, scrollLeft: 0 });
    const scrollBy = vi.fn();
    row.scrollBy = scrollBy as unknown as typeof row.scrollBy;

    endArrow(fixture)!.click();

    expect(scrollBy).toHaveBeenCalledWith({ left: 240, behavior: expect.any(String) });
  });

  it('in Arabic the row starts on the right: scrollLeft runs negative and the end is to the left', async () => {
    const fixture = await render('ar');
    const row = await layout(fixture, { scrollWidth: 900, clientWidth: 300, scrollLeft: 0 });
    expect(startArrow(fixture)).toBeNull();
    expect(endArrow(fixture)).not.toBeNull();

    const scrollBy = vi.fn();
    row.scrollBy = scrollBy as unknown as typeof row.scrollBy;
    endArrow(fixture)!.click();
    expect(scrollBy).toHaveBeenCalledWith({ left: -240, behavior: expect.any(String) });

    await layout(fixture, { scrollWidth: 900, clientWidth: 300, scrollLeft: -600 });
    expect(startArrow(fixture)).not.toBeNull();
    expect(endArrow(fixture)).toBeNull();
  });

  it('brings a chip that gets focus fully into view', async () => {
    const fixture = await render();
    const chip = track(fixture).querySelectorAll<HTMLButtonElement>('.rd-chip')[2];
    const scrollIntoView = vi.fn();
    chip.scrollIntoView = scrollIntoView;

    chip.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));

    expect(scrollIntoView).toHaveBeenCalledWith({ block: 'nearest', inline: 'nearest', behavior: expect.any(String) });
  });

  it('as a row of tabs (flush): the tablist itself, with no padding above and below and no vertical scrolling', async () => {
    const fixture = await render('en', TabsHost);
    const host = (fixture.nativeElement as HTMLElement).querySelector('rd-scroll-row') as HTMLElement;
    const row = host.querySelector('[data-scroll-track]') as HTMLElement;

    expect(row.getAttribute('role')).toBe('tablist');
    expect(row.getAttribute('aria-label')).toBe('Profile');
    expect(host.getAttribute('role')).toBeNull();
    expect(row.querySelectorAll('[role="tab"]').length).toBe(2);
    expect(row.classList.contains('rd-scroll-row')).toBe(true);
    expect(row.classList.contains('py-1')).toBe(false);
    expect(row.classList.contains('overflow-y-hidden')).toBe(true);
  });

  it('chips keep their padding above and below', async () => {
    const fixture = await render();
    expect(track(fixture).classList.contains('py-1')).toBe(true);
    expect(track(fixture).classList.contains('overflow-y-hidden')).toBe(false);
  });
});
