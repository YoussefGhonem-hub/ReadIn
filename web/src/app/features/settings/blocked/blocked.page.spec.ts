import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { BlockedUserDto } from '../../../core/api/models';
import { BlockStore } from '../../../core/social/block.store';
import { BlockedPage } from './blocked.page';

const URL = `${TEST_API}/me/blocked`;

function entry(id: string, displayName: string, username: string, blockedAt = '2026-11-01T10:00:00Z'): BlockedUserDto {
  return { user: { id, displayName, username, avatarUrl: null, isVerified: id === 'u1' }, blockedAt };
}

describe('Settings → Blocked accounts (F36)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
  });
  afterEach(() => http.verify());

  async function render() {
    const fixture = TestBed.createComponent(BlockedPage);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
    };
    return { fixture, root, stable, $: (s: string) => root.querySelector<HTMLElement>(s), $$: (s: string) => [...root.querySelectorAll<HTMLElement>(s)] };
  }

  it('lists the people you blocked, newest first, each with when and «إلغاء الحظر»', async () => {
    const t = await render();
    expect(t.$('[data-blocked-loading]')).not.toBeNull();
    const get = http.expectOne(URL);
    expect(get.request.method).toBe('GET');
    get.flush({ items: [entry('u1', 'Omar', 'omar'), entry('u2', 'سارة', 'sara', '2026-10-01T10:00:00Z')] });
    await t.stable();

    expect(t.$('h1')!.textContent!.trim()).toBe('الحسابات المحظورة');
    expect(t.$$('[data-blocked-user]').map((li) => li.getAttribute('data-blocked-user'))).toEqual(['u1', 'u2']);
    const first = t.$('[data-blocked-user="u1"]')!;
    expect(first.textContent).toContain('Omar');
    expect(first.textContent).toContain('@omar');
    expect(first.textContent).toContain('حُظر في');
    expect(first.querySelector('rd-verified-badge')).not.toBeNull();
    expect(first.querySelector('[data-unblock]')!.textContent!.trim()).toBe('إلغاء الحظر');
    expect(t.$('[data-back-to-settings]')!.getAttribute('href')).toBe('/settings');
  });

  it('Unblock removes the row once saved, without following them again', async () => {
    const t = await render();
    http.expectOne(URL).flush({ items: [entry('u1', 'Omar', 'omar'), entry('u2', 'Sara', 'sara')] });
    await t.stable();
    t.$('[data-blocked-user="u1"] [data-unblock]')!.click();
    await t.stable();
    expect((t.$('[data-blocked-user="u1"] [data-unblock]') as HTMLButtonElement).disabled).toBe(true);
    const del = http.expectOne(`${TEST_API}/users/u1/block`);
    expect(del.request.method).toBe('DELETE');
    expect(del.request.params.has('restoreFollow')).toBe(false);
    del.flush({ userId: 'u1', isBlocked: false, followRemoved: false });
    await t.stable();
    expect(t.$$('[data-blocked-user]').map((li) => li.getAttribute('data-blocked-user'))).toEqual(['u2']);
    expect(TestBed.inject(BlockStore).isBlocked('u1', true)).toBe(false);
  });

  it('a failed unblock keeps the row', async () => {
    const t = await render();
    http.expectOne(URL).flush({ items: [entry('u1', 'Omar', 'omar')] });
    await t.stable();
    t.$('[data-unblock]')!.click();
    http.expectOne(`${TEST_API}/users/u1/block`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    await t.stable();
    expect(t.$$('[data-blocked-user]')).toHaveLength(1);
    expect((t.$('[data-unblock]') as HTMLButtonElement).disabled).toBe(false);
  });

  it('an empty list says how to block someone', async () => {
    const t = await render();
    http.expectOne(URL).flush({ items: [] });
    await t.stable();
    const empty = t.$('[data-blocked-empty]')!;
    expect(empty.textContent).toContain('لم تحظر أحدًا');
    expect(empty.textContent).toContain('قائمة ⋯');
  });

  it('a load error shows a retry that loads again', async () => {
    const t = await render();
    http.expectOne(URL).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    await t.stable();
    expect(t.$('rd-error-state')!.textContent).toContain('تعذّر تحميل الحسابات المحظورة.');
    t.$('rd-error-state button')!.click();
    http.expectOne(URL).flush({ items: [entry('u1', 'Omar', 'omar')] });
    await t.stable();
    expect(t.$$('[data-blocked-user]')).toHaveLength(1);
  });
});
