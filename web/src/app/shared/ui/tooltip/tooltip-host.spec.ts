import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { TOOLTIP_DELAY_MS, TOOLTIP_ID, TOOLTIP_WARM_MS, TooltipHost } from './tooltip-host';

@Component({
  imports: [TooltipHost],
  template: `
    <rd-tooltip-host />
    <button type="button" id="save" title="Save the draft">Save</button>
    <button type="button" id="trash" title="Delete the block"><svg data-icon></svg></button>
    <button type="button" id="named" aria-label="Undo" title="Undo (Ctrl+Z)"></button>
    <button type="button" id="native" title="Stays native" data-rd-tip="off">Native</button>
    <button type="button" id="dark" title="Dark">
      <svg data-icon></svg><span class="sr-only">Dark</span>
    </button>
  `,
})
class Host {}

let fixture: ComponentFixture<Host>;
const $ = (id: string) => document.getElementById(id)!;
const tip = () => document.querySelector<HTMLElement>('[data-tooltip]')!;
const visible = () => !tip().hidden;

function pointer(
  type: 'pointerover' | 'pointerout' | 'pointerdown',
  target: Element,
  pointerType = 'mouse',
  relatedTarget: Element | null = null,
) {
  const event = new Event(type, { bubbles: true }) as PointerEvent;
  Object.defineProperty(event, 'pointerType', { value: pointerType });
  Object.defineProperty(event, 'relatedTarget', { value: relatedTarget });
  target.dispatchEvent(event);
}

function key(name: string) {
  document.dispatchEvent(new KeyboardEvent('keydown', { key: name, bubbles: true }));
}

describe('TooltipHost', () => {
  beforeEach(async () => {
    vi.useFakeTimers();
    fixture = TestBed.createComponent(Host);
    document.body.appendChild(fixture.nativeElement);
    fixture.detectChanges();
    await fixture.whenStable();
  });

  afterEach(() => {
    fixture.destroy();
    fixture.nativeElement.remove();
    vi.useRealTimers();
  });

  it('shows the title after the mouse rests on the element, and gives it back on leave', () => {
    const save = $('save');
    pointer('pointerover', save);

    expect(save.hasAttribute('title')).toBe(false); // the browser's own never shows
    expect(visible()).toBe(false);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(visible()).toBe(true);
    expect(tip().textContent).toBe('Save the draft');
    expect(tip().getAttribute('role')).toBe('tooltip');
    expect(save.getAttribute('aria-describedby')).toBe(TOOLTIP_ID);

    pointer('pointerout', save, 'mouse', document.body);
    expect(visible()).toBe(false);
    expect(save.getAttribute('title')).toBe('Save the draft');
    expect(save.hasAttribute('aria-describedby')).toBe(false);
  });

  it('shows nothing when the pointer leaves before the delay, or on touch', () => {
    const save = $('save');
    pointer('pointerover', save);
    pointer('pointerout', save, 'mouse', document.body);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(visible()).toBe(false);
    expect(save.getAttribute('title')).toBe('Save the draft');

    pointer('pointerover', save, 'touch');
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(visible()).toBe(false);
    expect(save.getAttribute('title')).toBe('Save the draft');
  });

  it('stays open while the pointer moves over the element’s own children', () => {
    const trash = $('trash');
    pointer('pointerover', trash);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    const icon = trash.querySelector('[data-icon]')!;
    pointer('pointerout', trash, 'mouse', icon);
    pointer('pointerover', icon);
    expect(visible()).toBe(true);
    expect(tip().textContent).toBe('Delete the block');
  });

  it('names an element whose title was its only name, and doesn’t repeat a title that is already its name', () => {
    const trash = $('trash');
    pointer('pointerover', trash);
    expect(trash.getAttribute('aria-label')).toBe('Delete the block');
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(trash.hasAttribute('aria-describedby')).toBe(false);
    pointer('pointerout', trash, 'mouse', document.body);
    expect(trash.hasAttribute('aria-label')).toBe(false);

    const named = $('named');
    pointer('pointerover', named);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(named.getAttribute('aria-label')).toBe('Undo');
    expect(named.getAttribute('aria-describedby')).toBe(TOOLTIP_ID);
    pointer('pointerout', named, 'mouse', document.body);

    // A title that repeats the element's own (screen-reader) text describes nothing new.
    const dark = $('dark');
    pointer('pointerover', dark);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(tip().textContent).toBe('Dark');
    expect(dark.hasAttribute('aria-describedby')).toBe(false);
    expect(dark.hasAttribute('aria-label')).toBe(false);
  });

  it('shows the next one at once while moving along a row, and waits again later', () => {
    pointer('pointerover', $('save'));
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    pointer('pointerout', $('save'), 'mouse', $('named'));
    pointer('pointerover', $('named'));
    vi.advanceTimersByTime(0);
    expect(tip().textContent).toBe('Undo (Ctrl+Z)');

    pointer('pointerout', $('named'), 'mouse', document.body);
    vi.advanceTimersByTime(TOOLTIP_WARM_MS + 1);
    pointer('pointerover', $('save'));
    vi.advanceTimersByTime(0);
    expect(visible()).toBe(false);
  });

  it('shows at once on keyboard focus, not on focus from a click', () => {
    const save = $('save');
    key('Tab');
    save.focus();
    vi.advanceTimersByTime(0);
    expect(visible()).toBe(true);
    save.blur();
    expect(visible()).toBe(false);

    pointer('pointerdown', save);
    save.focus();
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(visible()).toBe(false);
    save.blur();

    // Focus the app moves after typing or Escape (a menu giving it back to its button) shows nothing either.
    key('Tab');
    key('Escape');
    save.focus();
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(visible()).toBe(false);
    save.blur();
    key('a');
    save.focus();
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(visible()).toBe(false);
  });

  it('closes on Escape and on a click, and stays closed until the pointer leaves the clicked element', () => {
    const save = $('save');
    pointer('pointerover', save);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    key('Escape');
    expect(visible()).toBe(false);
    expect(save.getAttribute('title')).toBe('Save the draft');

    pointer('pointerover', save);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    pointer('pointerdown', save);
    expect(visible()).toBe(false);
    pointer('pointerover', save);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(visible()).toBe(false);

    pointer('pointerout', save, 'mouse', document.body);
    pointer('pointerover', save);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(visible()).toBe(true);
  });

  it('follows the app when it changes or removes the title meanwhile', async () => {
    const save = $('save');
    pointer('pointerover', save);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);

    save.setAttribute('title', 'Saved');
    await Promise.resolve();
    expect(tip().textContent).toBe('Saved');
    expect(save.hasAttribute('title')).toBe(false);

    save.setAttribute('title', '');
    await Promise.resolve();
    expect(visible()).toBe(false);
    pointer('pointerout', save, 'mouse', document.body);
    expect(save.hasAttribute('title')).toBe(false);
  });

  it('leaves elements that opt out to the browser', () => {
    const native = $('native');
    pointer('pointerover', native);
    vi.advanceTimersByTime(TOOLTIP_DELAY_MS);
    expect(visible()).toBe(false);
    expect(native.getAttribute('title')).toBe('Stays native');
  });
});
