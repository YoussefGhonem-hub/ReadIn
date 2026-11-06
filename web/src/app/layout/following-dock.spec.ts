import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { UserSummaryDto } from '../core/api/models';
import { flushMicrotasks, setupSocialTesting, TEST_API } from '../../testing/social-testing';
import { DOCK_SEARCH_DEBOUNCE_MS, DOCK_STORAGE_KEY, DOCK_SUGGESTIONS, FollowingDock } from './following-dock';

const FOLLOWING_URL = `${TEST_API}/users/user-1/following`;
const SUGGESTED_URL = `${TEST_API}/users/suggested`;

function person(id: string, patch: Partial<UserSummaryDto> = {}): UserSummaryDto {
  return { id, displayName: `Writer ${id}`, username: `writer${id}`, avatarUrl: null, isVerified: false, bio: null, isFollowing: true, followsYou: false, ...patch };
}

describe('FollowingDock', () => {
  let http: HttpTestingController;

  function render() {
    http = setupSocialTesting().http;
    const fixture = TestBed.createComponent(FollowingDock);
    document.body.appendChild(fixture.nativeElement);
    fixture.detectChanges();
    TestBed.tick();
    const root = fixture.nativeElement as HTMLElement;
    const toggle = root.querySelector<HTMLButtonElement>('[data-dock-toggle]')!;
    return { fixture, root, toggle };
  }

  /** Answers the following list (and lets the store take it in). */
  async function answer(fixture: ReturnType<typeof render>['fixture'], items: UserSummaryDto[], nextCursor: string | null = null, q?: string) {
    const req = http.expectOne((r) => r.url === FOLLOWING_URL && (q === undefined || r.params.get('q') === q));
    expect(req.request.params.get('limit')).toBe('20');
    req.flush({ items, nextCursor });
    await flushMicrotasks();
    fixture.detectChanges();
    TestBed.tick();
  }

  beforeEach(() => localStorage.removeItem(DOCK_STORAGE_KEY));
  afterEach(() => {
    document.querySelectorAll('rd-following-dock').forEach((el) => el.remove());
    localStorage.removeItem(DOCK_STORAGE_KEY);
    vi.useRealTimers();
  });

  it('starts as its header bar only, and loads nothing until it is opened', () => {
    const { root, toggle } = render();
    expect(toggle.getAttribute('aria-expanded')).toBe('false');
    expect(toggle.textContent).toContain('المتابَعون');
    expect(root.querySelector('[data-dock-panel]')).toBeNull();
    http.expectNone(FOLLOWING_URL);
  });

  it('opens on the header: the people you follow, each opening their profile, with "Follows you"; it stays as you left it', async () => {
    const { fixture, root, toggle } = render();
    toggle.click();
    fixture.detectChanges();
    TestBed.tick();
    expect(toggle.getAttribute('aria-expanded')).toBe('true');
    expect(root.querySelector('[data-dock-loading]')).not.toBeNull();
    expect(localStorage.getItem(DOCK_STORAGE_KEY)).toBe('open');

    const many = [person('1', { displayName: 'Sara Ali', username: 'sara', bio: 'Backend engineer', followsYou: true, isVerified: true })];
    for (let i = 2; i <= 6; i++) many.push(person(String(i)));
    await answer(fixture, many);

    const rows = root.querySelectorAll<HTMLAnchorElement>('[data-dock-person]');
    expect(rows).toHaveLength(6);
    expect(rows[0].getAttribute('href')).toBe('/@sara');
    expect(rows[0].textContent).toContain('Sara Ali');
    expect(rows[0].textContent).toContain('Backend engineer');
    expect(rows[0].querySelector('[data-dock-follows-you]')!.textContent!.trim()).toBe('يتابعك');
    expect(rows[0].querySelector('svg[aria-label="كاتب موثّق"]')).not.toBeNull();
    expect(rows[1].textContent).toContain('@writer2'); // no bio: the handle
    expect(rows[1].querySelector('[data-dock-follows-you]')).toBeNull();
    // Following plenty: no suggestions.
    http.expectNone((r) => r.url === SUGGESTED_URL);
    expect(root.querySelector('[data-dock-suggestions]')).toBeNull();

    toggle.click();
    fixture.detectChanges();
    expect(root.querySelector('[data-dock-panel]')).toBeNull();
    expect(localStorage.getItem(DOCK_STORAGE_KEY)).toBe('closed');
  });

  it('opens by itself when it was left open', () => {
    localStorage.setItem(DOCK_STORAGE_KEY, 'open');
    const { root, toggle } = render();
    expect(toggle.getAttribute('aria-expanded')).toBe('true');
    expect(root.querySelector('[data-dock-panel]')).not.toBeNull();
    http.expectOne((r) => r.url === FOLLOWING_URL);
  });

  it('following only a few: writers you might like from your interests, each with Follow', async () => {
    localStorage.setItem(DOCK_STORAGE_KEY, 'open');
    const { fixture, root } = render();
    await answer(fixture, [person('1'), person('2')]);

    const req = http.expectOne((r) => r.url === SUGGESTED_URL);
    expect(req.request.params.get('limit')).toBe(String(DOCK_SUGGESTIONS));
    req.flush([person('9', { displayName: 'Omar Hany', username: 'omar', isFollowing: false }), person('8', { isFollowing: false })]);
    await flushMicrotasks();
    fixture.detectChanges();

    const section = root.querySelector('[data-dock-suggestions]')!;
    expect(section.textContent).toContain('كتّاب قد يعجبونك');
    expect(section.textContent).toContain('بناءً على اهتماماتك');
    const rows = section.querySelectorAll('[data-dock-suggestion]');
    expect(rows).toHaveLength(2);
    expect(rows[0].querySelector('a[href="/@omar"]')).not.toBeNull();
    expect(rows[0].querySelector('[data-follow]')!.getAttribute('aria-pressed')).toBe('false');
  });

  it('following nobody: says so, then the suggestions', async () => {
    localStorage.setItem(DOCK_STORAGE_KEY, 'open');
    const { fixture, root } = render();
    await answer(fixture, []);
    expect(root.querySelector('[data-dock-empty]')!.textContent!.trim()).toBe('لا تتابع أحدًا بعد.');
    http.expectOne((r) => r.url === SUGGESTED_URL).flush([person('9', { isFollowing: false })]);
    await flushMicrotasks();
    fixture.detectChanges();
    expect(root.querySelectorAll('[data-dock-suggestion]')).toHaveLength(1);
  });

  it('searches by name or @username after a pause; a search shows no suggestions', async () => {
    localStorage.setItem(DOCK_STORAGE_KEY, 'open');
    const { fixture, root } = render();
    await answer(fixture, [person('1')]);
    http.expectOne((r) => r.url === SUGGESTED_URL).flush([person('9', { isFollowing: false })]);
    await flushMicrotasks();
    fixture.detectChanges();
    expect(root.querySelector('[data-dock-suggestions]')).not.toBeNull();

    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    const box = root.querySelector<HTMLInputElement>('[data-dock-search]')!;
    box.value = 'zz';
    box.dispatchEvent(new Event('input'));
    http.expectNone((r) => r.url === FOLLOWING_URL);
    vi.advanceTimersByTime(DOCK_SEARCH_DEBOUNCE_MS);
    fixture.detectChanges();
    await answer(fixture, [], null, 'zz');

    expect(root.querySelector('[data-dock-empty]')!.textContent!.trim()).toBe('لا أحد ممن تتابعهم يطابق «zz»');
    expect(root.querySelector('[data-dock-suggestions]')).toBeNull();
  });

  it('Escape closes it and gives the focus to its header', async () => {
    localStorage.setItem(DOCK_STORAGE_KEY, 'open');
    const { fixture, root, toggle } = render();
    await answer(fixture, [person('1'), person('2'), person('3'), person('4'), person('5')]);
    const box = root.querySelector<HTMLInputElement>('[data-dock-search]')!;
    box.focus();
    box.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    fixture.detectChanges();
    expect(root.querySelector('[data-dock-panel]')).toBeNull();
    expect(document.activeElement).toBe(toggle);
  });

  it('a failed load offers Retry', async () => {
    localStorage.setItem(DOCK_STORAGE_KEY, 'open');
    const { fixture, root } = render();
    http.expectOne((r) => r.url === FOLLOWING_URL).flush(null, { status: 500, statusText: 'Server Error' });
    await flushMicrotasks();
    fixture.detectChanges();
    const error = root.querySelector('[data-dock-error]')!;
    expect(error.textContent).toContain('تعذّر تحميل من تتابعهم.');
    error.querySelector('button')!.click();
    fixture.detectChanges();
    await answer(fixture, [person('1'), person('2'), person('3'), person('4'), person('5')]);
    expect(root.querySelectorAll('[data-dock-person]')).toHaveLength(5);
  });
});
