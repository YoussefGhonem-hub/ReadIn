import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CommentPageDto } from '../../core/api/models';
import { RealtimeService } from '../../core/realtime/realtime.service';
import { LanguageService } from '../../core/i18n/language.service';
import { CommentsSection } from './comments-section';

const LIST = `${TEST_API}/articles/a1/comments`;

async function render(page: Partial<CommentPageDto> = {}, lang: 'ar' | 'en' = 'ar') {
  const realtime = { watchCommentEvents: () => () => undefined };
  const { http } = setupSocialTesting({ providers: [{ provide: RealtimeService, useValue: realtime }] });
  await TestBed.inject(LanguageService).setLanguage(lang);
  const fixture = TestBed.createComponent(CommentsSection);
  fixture.componentRef.setInput('article', testCard());
  fixture.detectChanges();
  await fixture.whenStable();
  http.expectOne((r) => r.url === LIST && r.method === 'GET').flush({ items: [], nextCursor: null, total: 0, ...page });
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  await stable();
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  /** Waits for a lazy (`@defer`) part to show up. */
  const until = async (selector: string) => {
    for (let i = 0; i < 100 && !$(selector); i++) {
      await new Promise((resolve) => setTimeout(resolve, 10));
      await stable();
    }
    return $(selector)!;
  };
  return { fixture, root, http, $, stable, until };
}

function type(field: HTMLTextAreaElement, value: string, caret = value.length): void {
  field.value = value;
  field.setSelectionRange(caret, caret);
  field.dispatchEvent(new Event('input'));
}

/** jsdom's selector engine can't match emoji in attribute values: compare the attribute instead. */
function emoji(root: Element, value: string): HTMLElement {
  return [...root.querySelectorAll<HTMLElement>('[data-emoji]')].find((b) => b.getAttribute('data-emoji') === value)!;
}

function key(target: Element, key: string): void {
  target.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true }));
}

describe('The comment box (F11)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http?.verify());

  it('your avatar, a rounded field with "اكتب تعليق…", and the emoji and send icons inside it', async () => {
    const t = await render();
    http = t.http;
    const box = t.$('[data-new-comment]')!;
    expect(box.querySelector('[data-composer-avatar]')!.textContent!.trim()).toBe('M'); // Mona Adel
    expect(box.querySelector('[data-composer-avatar]')!.getAttribute('aria-hidden')).toBe('true');
    const field = box.querySelector('[data-comment-field]')!;
    expect(field.classList).toContain('comment-field');
    expect(field.querySelector('textarea')!.getAttribute('placeholder')).toBe('اكتب تعليق…');
    expect(field.querySelector('[data-comment-emoji]')!.getAttribute('aria-label')).toBe('ضيف إيموجي');
    const send = field.querySelector<HTMLButtonElement>('[data-comment-send]')!;
    expect(send.getAttribute('aria-label')).toBe('ابعت التعليق');
    // An icon, not a "نشر" text button; no cancel on a new comment.
    expect(send.textContent!.trim()).toBe('');
    expect(box.querySelector('[data-comment-cancel]')).toBeNull();
  });

  it('text and emoji only: no attachment, image or GIF button', async () => {
    const t = await render();
    http = t.http;
    const box = t.$('[data-new-comment]')!;
    expect(box.querySelector('input[type="file"]')).toBeNull();
    const buttons = [...box.querySelectorAll('button')];
    expect(buttons).toHaveLength(2);
    expect(buttons.every((b) => b.hasAttribute('data-comment-emoji') || b.hasAttribute('data-comment-send'))).toBe(true);
  });

  it('send stays disabled until there is text', async () => {
    const t = await render();
    http = t.http;
    const field = t.$<HTMLTextAreaElement>('[data-new-comment] textarea')!;
    const send = t.$<HTMLButtonElement>('[data-new-comment] [data-comment-send]')!;
    expect(send.disabled).toBe(true);
    type(field, '  ');
    await t.stable();
    expect(send.disabled).toBe(true);
    type(field, 'شكراً');
    await t.stable();
    expect(send.disabled).toBe(false);
  });

  it('the emoji picker loads on the press, puts the emoji at the caret and keeps open for more', async () => {
    const t = await render();
    http = t.http;
    const field = t.$<HTMLTextAreaElement>('[data-new-comment] textarea')!;
    type(field, 'جميل جدا', 4); // the caret after "جميل"
    await t.stable();
    expect(t.$('[data-emoji-picker]')).toBeNull();

    const button = t.$<HTMLButtonElement>('[data-comment-emoji]')!;
    expect(button.getAttribute('aria-expanded')).toBe('false');
    button.click();
    await t.stable();
    const picker = await t.until('[data-emoji-picker]');
    expect(button.getAttribute('aria-expanded')).toBe('true');
    expect(picker.getAttribute('role')).toBe('dialog');
    expect(picker.getAttribute('aria-label')).toBe('اختار إيموجي');
    expect(picker.querySelectorAll('[role="tab"]').length).toBe(9);
    // The first emoji takes the focus.
    await t.stable();
    expect(document.activeElement?.getAttribute('data-emoji')).toBe('😀');

    emoji(picker, '😂').click();
    await t.stable();
    expect(field.value).toBe('جميل😂 جدا');
    t.$<HTMLElement>('[data-emoji-category="hearts"]')!.click();
    await t.stable();
    emoji(t.root, '❤️').click();
    await t.stable();
    expect(field.value).toBe('جميل😂❤️ جدا');
    expect(t.$('[data-emoji-picker]')).not.toBeNull();
    expect(t.$<HTMLButtonElement>('[data-new-comment] [data-comment-send]')!.disabled).toBe(false);

    // Escape closes it and gives the focus back to the emoji button (a browser focuses the clicked emoji; jsdom doesn't).
    emoji(t.root, '❤️').focus();
    key(document.activeElement!, 'Escape');
    await t.stable();
    expect(t.$('[data-emoji-picker]')).toBeNull();
    expect(document.activeElement).toBe(button);
  });

  it('arrows move in the reading direction and by rows in the emoji grid', async () => {
    const t = await render();
    http = t.http;
    t.$<HTMLButtonElement>('[data-comment-emoji]')!.click();
    await t.stable();
    await t.until('[data-emoji-picker]');
    await t.stable();
    const at = () => document.activeElement?.getAttribute('data-emoji');
    expect(at()).toBe('😀');
    key(document.activeElement!, 'ArrowLeft'); // RTL: forward
    await t.stable();
    expect(at()).toBe('😃');
    key(document.activeElement!, 'ArrowDown'); // one row of 8
    await t.stable();
    expect(at()).toBe('😇');
    key(document.activeElement!, 'Home');
    await t.stable();
    expect(at()).toBe('😀');
  });

  it('a click outside closes the picker', async () => {
    const t = await render();
    http = t.http;
    t.$<HTMLButtonElement>('[data-comment-emoji]')!.click();
    await t.stable();
    await t.until('[data-emoji-picker]');
    document.body.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
    await t.stable();
    expect(t.$('[data-emoji-picker]')).toBeNull();
  });

  it('English: "Add a comment…", "Post comment", "Add an emoji"', async () => {
    const t = await render({}, 'en');
    http = t.http;
    expect(t.$('[data-new-comment] textarea')!.getAttribute('placeholder')).toBe('Add a comment…');
    expect(t.$('[data-new-comment] [data-comment-send]')!.getAttribute('aria-label')).toBe('Post comment');
    expect(t.$('[data-new-comment] [data-comment-emoji]')!.getAttribute('aria-label')).toBe('Add an emoji');
  });
});
