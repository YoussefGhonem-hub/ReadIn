import { Component, PLATFORM_ID, REQUEST } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { translocoTesting } from '../../../testing/transloco-testing';
import { provideAppIcons } from '../../shared/ui/icons';
import { READING_MODE_COOKIE, ReadingMode, ReadingModeService } from './reading-mode';

/** The reader's toolbar with the toggle, and a field and a sheet that own their own Escape. */
@Component({
  imports: [ReadingMode],
  template: `
    <div class="flex gap-2" data-toolbar><rd-reading-mode /></div>
    <input data-field />
  `,
})
class Host {}

function clearCookie(): void {
  document.cookie = `${READING_MODE_COOKIE}=; Path=/; Max-Age=0`;
}

async function render(lang: 'ar' | 'en' = 'ar') {
  TestBed.resetTestingModule();
  TestBed.configureTestingModule({ imports: [translocoTesting()], providers: [provideAppIcons()] });
  TestBed.inject(TranslocoService).setActiveLang(lang);
  const fixture: ComponentFixture<Host> = TestBed.createComponent(Host);
  const stable = async () => {
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
  };
  await stable();
  const root = fixture.nativeElement as HTMLElement;
  const $ = <T extends Element = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  const escape = (target: EventTarget = document.body) => {
    const event = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true });
    target.dispatchEvent(event);
    return event;
  };
  return { fixture, root, $, stable, escape, host: () => $('rd-reading-mode')!, toggle: () => $<HTMLButtonElement>('[data-reading-mode-toggle]')! };
}

describe('Reading mode (F04)', () => {
  beforeEach(() => clearCookie());
  afterEach(() => {
    clearCookie();
    document.getSelection()?.removeAllRanges();
    document.querySelectorAll('[data-test-sheet]').forEach((el) => el.remove());
  });

  it('off by default: a toggle named «وضع القراءة», not pressed, no floating control, nothing announced', async () => {
    const t = await render();
    expect(t.toggle().getAttribute('aria-label')).toBe('وضع القراءة');
    expect(t.toggle().getAttribute('aria-pressed')).toBe('false');
    expect(t.toggle().type).toBe('button');
    expect(t.toggle().querySelector('svg')!.getAttribute('aria-hidden')).toBe('true');
    expect(t.host().hasAttribute('data-reading-mode')).toBe(false);
    expect(t.$('[data-reading-mode-exit]')).toBeNull();
    expect(t.$('[data-reading-mode-status]')!.getAttribute('role')).toBe('status');
    expect(t.$('[data-reading-mode-status]')!.textContent).toBe('');
    // In the toolbar's row like the buttons around it (no box of its own).
    expect(t.host().classList).toContain('contents');
  });

  it('the toggle turns it on: pressed, the host says so (the chrome hides), the exit control, remembered in a cookie, announced', async () => {
    const t = await render();
    t.toggle().click();
    await t.stable();
    expect(t.toggle().getAttribute('aria-pressed')).toBe('true');
    // Same name on and off: the pressed state says which.
    expect(t.toggle().getAttribute('aria-label')).toBe('وضع القراءة');
    expect(t.host().getAttribute('data-reading-mode')).toBe('on');
    const exit = t.$<HTMLButtonElement>('[data-reading-mode-exit]')!;
    expect(exit.type).toBe('button');
    expect(exit.textContent!.trim()).toBe('الخروج من وضع القراءة');
    expect(exit.getAttribute('aria-keyshortcuts')).toBe('Escape');
    expect(exit.classList).toContain('fixed');
    expect(exit.classList).toContain('end-4');
    expect(document.cookie).toContain(`${READING_MODE_COOKIE}=1`);
    expect(t.$('[data-reading-mode-status]')!.textContent).toBe('تم تفعيل وضع القراءة.');

    // Pressing it again turns it off.
    t.toggle().click();
    await t.stable();
    expect(t.toggle().getAttribute('aria-pressed')).toBe('false');
    expect(t.host().hasAttribute('data-reading-mode')).toBe(false);
    expect(t.$('[data-reading-mode-exit]')).toBeNull();
    expect(document.cookie).toContain(`${READING_MODE_COOKIE}=0`);
    expect(t.$('[data-reading-mode-status]')!.textContent).toBe('تم إيقاف وضع القراءة.');
  });

  it('the page style hides the top bar, bottom nav, action bar and Following panel while a reader is in reading mode', async () => {
    await render();
    const css = [...document.querySelectorAll('style')].map((s) => s.textContent ?? '').join('\n').replace(/\s+/g, '');
    expect(css).toContain('body:has(rd-reading-mode[data-reading-mode]):is(rd-top-bar,rd-bottom-nav,rd-article-action-bar,rd-following-dock){display:none!important');
    // The exit control only fades in without reduced motion.
    expect(css).toContain('@media(prefers-reduced-motion:no-preference){.rd-reading-exit{animation:rd-reading-exit-in');
  });

  it('opens in reading mode when this device chose it (the cookie, also read on the server), without announcing it', async () => {
    document.cookie = `${READING_MODE_COOKIE}=1; Path=/`;
    const t = await render('en');
    expect(t.toggle().getAttribute('aria-pressed')).toBe('true');
    expect(t.toggle().getAttribute('aria-label')).toBe('Reading mode');
    expect(t.$('[data-reading-mode-exit]')!.textContent!.trim()).toBe('Exit reading mode');
    expect(t.$('[data-reading-mode-status]')!.textContent).toBe('');

    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      providers: [
        { provide: PLATFORM_ID, useValue: 'server' },
        { provide: REQUEST, useValue: new Request('https://readin.app/ar/a/x', { headers: { cookie: `lang=ar; ${READING_MODE_COOKIE}=1` } }) },
      ],
    });
    expect(TestBed.inject(ReadingModeService).on()).toBe(true);
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      providers: [
        { provide: PLATFORM_ID, useValue: 'server' },
        { provide: REQUEST, useValue: new Request('https://readin.app/ar/a/x', { headers: { cookie: `${READING_MODE_COOKIE}=0` } }) },
      ],
    });
    expect(TestBed.inject(ReadingModeService).on()).toBe(false);
  });

  it('the floating control turns it off and gives the focus back to the toggle', async () => {
    document.cookie = `${READING_MODE_COOKIE}=1; Path=/`;
    const t = await render('en');
    const exit = t.$<HTMLButtonElement>('[data-reading-mode-exit]')!;
    exit.focus();
    exit.click();
    await t.stable();
    expect(t.$('[data-reading-mode-exit]')).toBeNull();
    expect(t.toggle().getAttribute('aria-pressed')).toBe('false');
    expect(document.activeElement).toBe(t.toggle());
    expect(document.cookie).toContain(`${READING_MODE_COOKIE}=0`);
    expect(t.$('[data-reading-mode-status]')!.textContent).toBe('Reading mode is off.');
  });

  it('Escape turns it off; from the floating control the focus goes back to the toggle', async () => {
    document.cookie = `${READING_MODE_COOKIE}=1; Path=/`;
    let t = await render();
    expect(t.escape().defaultPrevented).toBe(false);
    await t.stable();
    expect(t.toggle().getAttribute('aria-pressed')).toBe('false');
    expect(document.cookie).toContain(`${READING_MODE_COOKIE}=0`);

    document.cookie = `${READING_MODE_COOKIE}=1; Path=/`;
    t = await render();
    const exit = t.$<HTMLButtonElement>('[data-reading-mode-exit]')!;
    exit.focus();
    t.escape(exit);
    await t.stable();
    expect(t.$('[data-reading-mode-exit]')).toBeNull();
    expect(document.activeElement).toBe(t.toggle());
  });

  it('Escape is left to what owns it first: an open sheet, a field, a menu, a selected passage, a handled key', async () => {
    document.cookie = `${READING_MODE_COOKIE}=1; Path=/`;
    const t = await render();
    const on = () => t.toggle().getAttribute('aria-pressed') === 'true';

    const sheet = document.createElement('section');
    sheet.setAttribute('role', 'dialog');
    sheet.setAttribute('aria-modal', 'true');
    sheet.setAttribute('data-test-sheet', '');
    document.body.appendChild(sheet);
    t.escape();
    await t.stable();
    expect(on()).toBe(true);
    sheet.remove();

    t.escape(t.$('[data-field]')!);
    await t.stable();
    expect(on()).toBe(true);

    const menu = document.createElement('div');
    menu.setAttribute('role', 'menu');
    menu.setAttribute('data-test-sheet', '');
    const item = menu.appendChild(document.createElement('button'));
    document.body.appendChild(menu);
    t.escape(item);
    await t.stable();
    expect(on()).toBe(true);
    menu.remove();

    const text = document.body.appendChild(document.createElement('p'));
    text.setAttribute('data-test-sheet', '');
    text.textContent = 'A passage to highlight';
    const range = document.createRange();
    range.selectNodeContents(text);
    document.getSelection()!.addRange(range);
    t.escape();
    await t.stable();
    expect(on()).toBe(true);
    document.getSelection()!.removeAllRanges();

    const handled = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true });
    handled.preventDefault();
    document.body.dispatchEvent(handled);
    await t.stable();
    expect(on()).toBe(true);

    // Nothing else wants it: off.
    t.escape();
    await t.stable();
    expect(on()).toBe(false);
  });

  it('other keys do nothing, and Escape does nothing while it is off', async () => {
    const t = await render();
    document.body.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
    t.escape();
    await t.stable();
    expect(t.toggle().getAttribute('aria-pressed')).toBe('false');
    expect(t.$('[data-reading-mode-status]')!.textContent).toBe('');
    expect(document.cookie).not.toContain(`${READING_MODE_COOKIE}=`);
  });
});
