import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../../testing/social-testing';
import { MutesDto } from '../../../core/api/models';
import { MuteStore } from '../../../core/social/mute.store';
import { MutedPage } from './muted.page';

const MUTES: MutesDto = {
  users: [{ id: 'u-omar', displayName: 'عمر سمير', username: 'omar_dev', avatarUrl: null, isVerified: true, bio: null, isFollowing: false, followsYou: false }],
  fields: [{ id: 'f-health', slug: 'health', name: 'الصحة', nameAr: 'الصحة', nameEn: 'Health', icon: 'heart-pulse', color: 'error' }],
  topics: [
    {
      id: 't-crypto',
      slug: 'crypto',
      name: 'كريبتو',
      nameAr: 'كريبتو',
      nameEn: 'Crypto',
      field: { id: 'f-business', slug: 'business', name: 'بيزنس', nameAr: 'بيزنس', nameEn: 'Business', icon: 'briefcase', color: 'accent' },
    },
  ],
};

async function render(mutes: MutesDto | 'error') {
  const { http, toasts } = setupSocialTesting();
  const fixture = TestBed.createComponent(MutedPage);
  fixture.detectChanges();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  expect(root.querySelector('[data-muted-loading]')).not.toBeNull();
  const req = http.expectOne(`${TEST_API}/me/mutes`);
  if (mutes === 'error') req.flush(null, { status: 503, statusText: 'Unavailable' });
  else req.flush(mutes);
  await stable();
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
  return { http, toasts, root, stable, $, $$ };
}

describe('Settings → Muted (F18, F28)', () => {
  let http: HttpTestingController;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http.verify());

  it('lists the writers, fields and topics you muted, each with Unmute', async () => {
    const t = await render(MUTES);
    http = t.http;
    expect(t.$('h1')!.textContent!.trim()).toBe('اللي كتمته');
    expect(t.$$('[data-muted-list] h2').map((h) => h.textContent!.trim())).toEqual(['الكتّاب', 'المجالات', 'المواضيع']);
    const writer = t.$('[data-muted-user][data-muted-id="u-omar"]')!;
    expect(writer.querySelector('a[href="/@omar_dev"]:not([aria-hidden])')!.textContent).toContain('عمر سمير');
    expect(writer.querySelector('bdi')!.textContent).toBe('@omar_dev');
    expect(t.$('[data-muted-field][data-muted-id="f-health"]')!.textContent).toContain('الصحة');
    const topic = t.$('[data-muted-topic][data-muted-id="t-crypto"]')!;
    expect(topic.textContent).toContain('كريبتو');
    expect(topic.textContent).toContain('بيزنس');
    expect(topic.textContent).toContain('في '); // "في {field}", as on mobile
    expect(t.$$('[data-muted-unmute]').map((b) => b.getAttribute('aria-label'))).toEqual([
      'إلغاء كتم \u2068عمر سمير\u2069',
      'إلغاء كتم \u2068الصحة\u2069',
      'إلغاء كتم \u2068كريبتو\u2069',
    ]);
    // Everything listed is muted everywhere in the app.
    const mutes = TestBed.inject(MuteStore);
    expect(mutes.isAuthorMuted('u-omar')).toBe(true);
    expect(mutes.isTopicMuted('t-crypto')).toBe(true);
  });

  it('Unmute removes the row once saved; the last one leaves the empty state', async () => {
    const t = await render({ ...MUTES, fields: [], topics: [] });
    http = t.http;
    t.$<HTMLButtonElement>('[data-muted-user] [data-muted-unmute]')!.click();
    await t.stable();
    const req = t.http.expectOne(`${TEST_API}/users/u-omar/mute`);
    expect(req.request.method).toBe('DELETE');
    req.flush({ isMuted: false, isFollowing: false, followerCount: 12, followRemoved: false });
    await t.stable();
    expect(t.$('[data-muted-user]')).toBeNull();
    expect(t.$('[data-muted-empty]')!.textContent).toContain('مكتمتش حاجة لسه');
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['لغيت كتم \u2068عمر سمير\u2069.']);
  });

  it('unmutes a field and a topic', async () => {
    const t = await render({ ...MUTES, users: [] });
    http = t.http;
    t.$<HTMLButtonElement>('[data-muted-field] [data-muted-unmute]')!.click();
    await t.stable();
    const field = t.http.expectOne(`${TEST_API}/me/mutes/fields/f-health`);
    expect(field.request.method).toBe('DELETE');
    field.flush({ fieldIds: [], topicIds: ['t-crypto'] });
    await t.stable();
    expect(t.$('[data-muted-field]')).toBeNull();

    t.$<HTMLButtonElement>('[data-muted-topic] [data-muted-unmute]')!.click();
    await t.stable();
    t.http.expectOne(`${TEST_API}/me/mutes/topics/t-crypto`).flush({ fieldIds: [], topicIds: [] });
    await t.stable();
    expect(t.$('[data-muted-empty]')).not.toBeNull();
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['لغيت كتم \u2068الصحة\u2069.', 'لغيت كتم \u2068كريبتو\u2069.']);
  });

  it('nothing muted: the empty state says where muting happens', async () => {
    const t = await render({ users: [], fields: [], topics: [] });
    http = t.http;
    expect(t.$('[data-muted-empty]')!.textContent).toContain('من اختيارات أي مقال');
    expect(t.$('[data-muted-list]')).toBeNull();
  });

  it('a failed load offers Retry', async () => {
    const t = await render('error');
    http = t.http;
    expect(t.$('rd-error-state')!.textContent).toContain('معرفناش نجيب اللي كتمته');
    t.$<HTMLButtonElement>('rd-error-state button')!.click();
    await t.stable();
    t.http.expectOne(`${TEST_API}/me/mutes`).flush(MUTES);
    await t.stable();
    expect(t.$('[data-muted-list]')).not.toBeNull();
  });
});
