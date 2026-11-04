import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ModerationNoticeDialog } from '../../features/moderation/notice-dialog';
import { ModerationNoticeDto } from '../api/models';
import { ModerationNotices } from './moderation-notices';

const NOTICES = `${TEST_API}/me/moderation-notices`;

const WARNING: ModerationNoticeDto = {
  id: 'n1',
  kind: 'warning',
  note: 'Please keep the comments respectful.',
  article: null,
  createdAt: '2026-11-02T10:00:00Z',
};
const HIDDEN: ModerationNoticeDto = {
  id: 'n2',
  kind: 'article_hidden',
  note: 'ضيف المصدر وكلّمنا.',
  article: { id: 'a1', slug: 'clean-architecture', title: 'Clean Architecture on one whiteboard' },
  createdAt: '2026-11-02T12:00:00Z',
};

async function start(options: { guest?: boolean; setupPending?: boolean } = {}) {
  const { http, session } = setupSocialTesting({ guest: options.guest });
  if (options.setupPending) session.setMe(testMe({ mustSetRecoveryPin: true, hasRecoveryPin: false }));
  const notices = TestBed.inject(ModerationNotices);
  TestBed.tick();
  await flushMicrotasks();
  return { http, session, notices };
}

describe('Moderation notices (F22)', () => {
  let http: HttpTestingController;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http.verify());

  it('loads your notices once signed in and loads the dialog only when there are some', async () => {
    const t = await start();
    http = t.http;
    t.http.expectOne(NOTICES).flush({ items: [WARNING, HIDDEN] });
    await flushMicrotasks(20);
    await vi.waitFor(() => expect(t.notices.dialog()).toBe(ModerationNoticeDialog));
    expect(t.notices.current()).toEqual(WARNING);
  });

  it('nothing to show: no dialog', async () => {
    const t = await start();
    http = t.http;
    t.http.expectOne(NOTICES).flush({ items: [] });
    await flushMicrotasks(20);
    expect(t.notices.current()).toBeNull();
    expect(t.notices.dialog()).toBeNull();
  });

  it('guests and accounts still in their setup steps are not asked', async () => {
    const guest = await start({ guest: true });
    http = guest.http;
    guest.http.expectNone(NOTICES);

    TestBed.resetTestingModule();
    const pending = await start({ setupPending: true });
    http = pending.http;
    pending.http.expectNone(NOTICES);
    // Once the PIN is set, they come.
    pending.session.setMe(testMe());
    TestBed.tick();
    await flushMicrotasks();
    pending.http.expectOne(NOTICES).flush({ items: [] });
  });

  it('a moderation_notice push loads them again, and the dialog follows', async () => {
    const t = await start();
    http = t.http;
    t.http.expectOne(NOTICES).flush({ items: [] });
    await flushMicrotasks(20);
    expect(t.notices.dialog()).toBeNull();

    t.notices.reload();
    t.http.expectOne(NOTICES).flush({ items: [WARNING] });
    await flushMicrotasks(20);
    await vi.waitFor(() => expect(t.notices.dialog()).toBe(ModerationNoticeDialog));
    expect(t.notices.current()).toEqual(WARNING);
  });

  it('signing out forgets them', async () => {
    const t = await start();
    http = t.http;
    t.http.expectOne(NOTICES).flush({ items: [WARNING] });
    await flushMicrotasks(20);
    t.session.setGuest();
    TestBed.tick();
    expect(t.notices.notices()).toEqual([]);
  });

  describe('dialog', () => {
    async function render(items: ModerationNoticeDto[]) {
      const t = await start();
      http = t.http;
      t.http.expectOne(NOTICES).flush({ items });
      await flushMicrotasks(20);
      const fixture = TestBed.createComponent(ModerationNoticeDialog);
      fixture.detectChanges();
      await fixture.whenStable();
      const root = fixture.nativeElement as HTMLElement;
      const stable = async () => {
        await flushMicrotasks();
        fixture.detectChanges();
        await fixture.whenStable();
      };
      const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
      return { ...t, fixture, root, stable, $ };
    }

    it('shows each notice in turn; "فهمت" acknowledges it', async () => {
      const t = await render([WARNING, HIDDEN]);
      const dialog = t.root.querySelector('section[role="alertdialog"]')!;
      expect(dialog).not.toBeNull();
      // No close button, no dismissing: it has to be acknowledged.
      expect(dialog.querySelector('[aria-label="إغلاق"]')).toBeNull();
      expect(t.$('[data-moderation-notice]')!.getAttribute('data-notice-kind')).toBe('warning');
      expect(t.$('[data-notice-title]')!.textContent!.trim()).toBe('وصلك تحذير من فريق الإشراف');
      expect(t.$('[data-notice-note]')!.textContent).toContain('Please keep the comments respectful.');
      expect(t.$('[data-notice-ack]')!.textContent!.trim()).toBe('فهمت');

      t.$('[data-notice-ack]')!.click();
      await t.stable();
      const ack = t.http.expectOne(`${NOTICES}/n1/acknowledge`);
      expect(ack.request.method).toBe('POST');
      ack.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();

      expect(t.$('[data-moderation-notice]')!.getAttribute('data-notice-kind')).toBe('article_hidden');
      expect(t.$('[data-notice-title]')!.textContent!.trim()).toBe('مقالك «⁨Clean Architecture on one whiteboard⁩» اتخفى');
      expect(t.$('[data-notice-note]')!.textContent).toContain('ضيف المصدر وكلّمنا.');

      t.$('[data-notice-ack]')!.click();
      await t.stable();
      t.http.expectOne(`${NOTICES}/n2/acknowledge`).flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      expect(t.$('[data-moderation-notice]')).toBeNull();
      expect(t.notices.notices()).toEqual([]);
    });

    it('a notice that no longer exists goes away; another failure stays with its message', async () => {
      const t = await render([WARNING, HIDDEN]);
      t.$('[data-notice-ack]')!.click();
      await t.stable();
      t.http.expectOne(`${NOTICES}/n1/acknowledge`).flush(problem(404, 'moderation.notice_not_found'), { status: 404, statusText: 'Not Found' });
      await t.stable();
      expect(t.$('[data-moderation-notice]')!.getAttribute('data-notice-kind')).toBe('article_hidden');

      t.$('[data-notice-ack]')!.click();
      await t.stable();
      t.http.expectOne(`${NOTICES}/n2/acknowledge`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
      await t.stable();
      expect(t.$('[data-moderation-notice]')!.getAttribute('data-notice-kind')).toBe('article_hidden');
      expect(t.root.querySelector('[role="alert"]')!.textContent).toContain('السيرفر واجه مشكلة');
    });
  });
});
