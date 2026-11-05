import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleModerationDto, FieldRefDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { FollowStore } from '../../core/social/follow.store';
import { MuteStore } from '../../core/social/mute.store';
import { ArticleActionBar } from './article-action-bar';
import { MenuArticle } from './article-menu';

const MODERATOR = ['articles.read', 'reports.create', 'moderation.manage', 'users.suspend'];
const OTHERS = ['showLess', 'follow', 'muteAuthor', 'muteTopics', 'report'];
const DOTNET: FieldRefDto = { id: 't1', slug: 'dotnet', name: '.NET', nameAr: 'دوت نت', nameEn: '.NET' };
const FEED = { applies: true } as const;

async function render(article: MenuArticle = testCard(), options: { guest?: boolean; permissions?: string[]; myId?: string } = {}) {
  const { http, session, toasts } = setupSocialTesting({ guest: options.guest });
  if (!options.guest) session.setMe(testMe({ id: options.myId ?? 'user-1', permissions: options.permissions ?? ['articles.read', 'reports.create'] }));
  const fixture = TestBed.createComponent(ArticleActionBar);
  fixture.componentRef.setInput('article', article);
  fixture.componentRef.setInput('url', 'https://readin.test/en/a/clean-architecture');
  const changes: (ArticleModerationDto | null)[] = [];
  fixture.componentInstance.moderationChange.subscribe((value) => changes.push(value));
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  /** Opens the "⋯" menu (a CDK overlay on the document) and lists its actions. */
  const openMenu = async () => {
    $('[data-article-menu]')!.click();
    await stable();
    return [...document.querySelectorAll('[data-article-menu-panel] [data-menu-action]')].map((el) => el.getAttribute('data-menu-action'));
  };
  const label = (action: string) => document.querySelector(`[data-article-menu-panel] [data-menu-action="${action}"]`)!.textContent!.trim();
  const pick = async (action: string) => {
    (document.querySelector(`[data-article-menu-panel] [data-menu-action="${action}"]`) as HTMLElement).click();
    await stable();
  };
  /** Waits for a lazy part (the topics sheet's chunk) to render. */
  const waitFor = async (selector: string) => {
    for (let i = 0; i < 50 && !$(selector); i++) {
      await new Promise((resolve) => setTimeout(resolve, 10));
      await stable();
    }
    return $(selector);
  };
  const toastList = () => toasts.toasts().map((toast) => toast.message);
  return { fixture, root, http, toasts, toastList, stable, $, openMenu, label, pick, waitFor, changes };
}

describe('Reader "⋯" menu (F22, F28)', () => {
  let http: HttpTestingController;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    http.verify();
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
  });

  it("someone else's article: Show less, Follow, Mute author, Mute topics, then Report in the error color", async () => {
    const t = await render();
    http = t.http;
    expect(t.$('[data-article-menu]')!.getAttribute('aria-label')).toBe('خيارات المقال');
    expect(await t.openMenu()).toEqual(OTHERS);
    expect(OTHERS.map(t.label)).toEqual(['قلّل من النوع ده', 'تابع الكاتب', 'كتم الكاتب', 'كتم المواضيع', 'الإبلاغ عن المقال']);
    const report = document.querySelector('[data-menu-action="report"]')!;
    expect(report.classList).toContain('text-error');
    expect(document.querySelector('[data-menu-action="showLess"]')!.classList).not.toContain('text-error');

    await t.pick('report');
    expect(t.$('[data-report-sheet]')!.getAttribute('data-report-target')).toBe('article');
    t.$<HTMLInputElement>('[data-reason="spam"]')!.click();
    await t.stable();
    t.$('[data-report-submit]')!.click();
    const req = t.http.expectOne(`${TEST_API}/reports`);
    expect(req.request.body).toEqual({ targetType: 'article', targetId: 'a1', reason: 'spam' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.$('[data-report-sheet]')).toBeNull();
  });

  it('your own article: only Mute topics', async () => {
    const t = await render(testCard(), { myId: 'writer-1' });
    http = t.http;
    expect(await t.openMenu()).toEqual(['muteTopics']);
  });

  it("a deleted author's article: no Follow and no Mute author", async () => {
    const t = await render(testCard({ author: null }));
    http = t.http;
    expect(await t.openMenu()).toEqual(['showLess', 'muteTopics', 'report']);
  });

  it('guests see every item and get the sign-in prompt for each, without a request', async () => {
    const t = await render(testCard(), { guest: true });
    http = t.http;
    const prompt = TestBed.inject(AuthPromptService);
    expect(await t.openMenu()).toEqual(OTHERS);
    for (const action of OTHERS) {
      prompt.close();
      if (!document.querySelector('[data-article-menu-panel]')) await t.openMenu();
      await t.pick(action);
      expect(prompt.isOpen()).toBe(true);
    }
    expect(t.$('[data-report-sheet]')).toBeNull();
    expect(t.$('[data-mute-topics-sheet]')).toBeNull();
    expect(t.toastList()).toEqual([]);
  });

  it('Show less: the card leaves the feeds at once, a toast offers Undo, and Undo brings it back', async () => {
    const card = testCard();
    const t = await render(card);
    http = t.http;
    const mutes = TestBed.inject(MuteStore);
    await t.openMenu();
    await t.pick('showLess');
    expect(mutes.hides(card, FEED)).toBe(true);
    const put = t.http.expectOne(`${TEST_API}/articles/a1/show-less`);
    expect(put.request.method).toBe('PUT');
    put.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    const [toast] = t.toasts.toasts();
    expect(toast.message).toBe('تمام، هتشوف مقالات أقل من النوع ده.');
    expect(toast.action!.label).toBe('تراجع');

    toast.action!.run();
    expect(mutes.hides(card, FEED)).toBe(false);
    const undo = t.http.expectOne(`${TEST_API}/articles/a1/show-less`);
    expect(undo.request.method).toBe('DELETE');
    undo.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    // The writer's own pages never hid it.
    expect(mutes.hides(card, { applies: false })).toBe(false);
  });

  it('Mute author ends your follow; the toast names them and its Undo follows again', async () => {
    const card = testCard({ isFollowingAuthor: true });
    const t = await render(card);
    http = t.http;
    const mutes = TestBed.inject(MuteStore);
    const follows = TestBed.inject(FollowStore);
    await t.openMenu();
    expect(t.label('follow')).toBe('إلغاء متابعة الكاتب');
    await t.pick('muteAuthor');
    expect(mutes.hides(card, FEED)).toBe(true);
    const put = t.http.expectOne(`${TEST_API}/users/writer-1/mute`);
    expect(put.request.method).toBe('PUT');
    put.flush({ isMuted: true, isFollowing: false, followerCount: 41, followRemoved: true });
    await t.stable();
    expect(follows.isFollowing('writer-1', true)).toBe(false);
    const [toast] = t.toasts.toasts();
    expect(toast.message).toBe('كتمت \u2068Karim Hassan\u2069. مش هتشوف مقالاته ولا تعليقاته.');

    // The menu now offers to unmute, and to follow again.
    await t.openMenu();
    expect(t.label('muteAuthor')).toBe('إلغاء كتم الكاتب');
    expect(t.label('follow')).toBe('تابع الكاتب');
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));

    toast.action!.run();
    expect(mutes.hides(card, FEED)).toBe(false);
    const undo = t.http.expectOne(`${TEST_API}/users/writer-1/mute?restoreFollow=true`);
    expect(undo.request.method).toBe('DELETE');
    undo.flush({ isMuted: false, isFollowing: true, followerCount: 42, followRemoved: false });
    await t.stable();
    expect(follows.isFollowing('writer-1', false)).toBe(true);
  });

  it("an Undo after a mute that ended no follow doesn't follow", async () => {
    const t = await render();
    http = t.http;
    await t.openMenu();
    await t.pick('muteAuthor');
    t.http.expectOne(`${TEST_API}/users/writer-1/mute`).flush({ isMuted: true, isFollowing: false, followerCount: 40, followRemoved: false });
    await t.stable();
    t.toasts.toasts()[0].action!.run();
    const undo = t.http.expectOne(`${TEST_API}/users/writer-1/mute`);
    expect(undo.request.method).toBe('DELETE');
    undo.flush({ isMuted: false, isFollowing: false, followerCount: 40, followRemoved: false });
    await t.stable();
  });

  it('a refused mute puts the card back with the reason', async () => {
    const card = testCard();
    const t = await render(card);
    http = t.http;
    const mutes = TestBed.inject(MuteStore);
    await t.openMenu();
    await t.pick('muteAuthor');
    t.http.expectOne(`${TEST_API}/users/writer-1/mute`).flush(problem(400, 'mute.system_account'), { status: 400, statusText: 'Bad Request' });
    await t.stable();
    expect(mutes.hides(card, FEED)).toBe(false);
    expect(t.toastList()).toEqual(['مينفعش تكتم حساب ReadIn الرسمي.']);
  });

  it('Unmute author from the menu of a muted writer\'s article', async () => {
    const t = await render(testCard({ isAuthorMuted: true }));
    http = t.http;
    await t.openMenu();
    expect(t.label('muteAuthor')).toBe('إلغاء كتم الكاتب');
    await t.pick('muteAuthor');
    t.http.expectOne(`${TEST_API}/users/writer-1/mute`).flush({ isMuted: false, isFollowing: false, followerCount: 40, followRemoved: false });
    await t.stable();
    expect(TestBed.inject(MuteStore).isAuthorMuted('writer-1', true)).toBe(false);
    expect(t.toastList()).toEqual(['لغيت كتم \u2068Karim Hassan\u2069.']);
  });

  it('Follow author follows, and the item then offers to unfollow', async () => {
    const t = await render();
    http = t.http;
    await t.openMenu();
    expect(t.label('follow')).toBe('تابع الكاتب');
    await t.pick('follow');
    const req = t.http.expectOne(`${TEST_API}/users/writer-1/follow`);
    expect(req.request.method).toBe('PUT');
    req.flush({ isFollowing: true, followerCount: 43 });
    await t.stable();
    await t.openMenu();
    expect(t.label('follow')).toBe('إلغاء متابعة الكاتب');
  });

  it('following a writer you muted ends the mute (the server does too)', async () => {
    const t = await render(testCard({ isAuthorMuted: true }));
    http = t.http;
    await t.openMenu();
    await t.pick('follow');
    t.http.expectOne(`${TEST_API}/users/writer-1/follow`).flush({ isFollowing: true, followerCount: 43 });
    await t.stable();
    expect(TestBed.inject(MuteStore).isAuthorMuted('writer-1', true)).toBe(false);
  });

  it('Mute topics: a sheet with the field and topic toggles, each saved at once', async () => {
    const card = testCard({ topic: DOTNET });
    const t = await render(card);
    http = t.http;
    const mutes = TestBed.inject(MuteStore);
    await t.openMenu();
    await t.pick('muteTopics');
    const sheet = (await t.waitFor('[data-mute-topics-sheet]'))!;
    expect(sheet.querySelector('#mute-topics-title')!.textContent!.trim()).toBe('كتم المواضيع');
    const field = sheet.querySelector<HTMLButtonElement>('[data-mute-field="f1"] [role="switch"]')!;
    const topic = sheet.querySelector<HTMLButtonElement>('[data-mute-topic="t1"] [role="switch"]')!;
    expect(sheet.querySelector('[data-mute-field="f1"] label')!.textContent!.trim()).toBe('\u2068البرمجيات\u2069');
    expect(sheet.querySelector('[data-mute-topic="t1"] label')!.textContent!.trim()).toBe('\u2068دوت نت\u2069');
    expect(field.getAttribute('aria-checked')).toBe('false');

    // On: the cards in the topic leave at once.
    topic.click();
    await t.stable();
    expect(topic.getAttribute('aria-checked')).toBe('true');
    expect(mutes.hides(card, FEED)).toBe(true);
    const put = t.http.expectOne(`${TEST_API}/me/mutes/topics/t1`);
    expect(put.request.method).toBe('PUT');
    put.flush({ fieldIds: [], topicIds: ['t1'] });
    await t.stable();
    expect(topic.getAttribute('aria-checked')).toBe('true');

    // Off again is the Undo.
    topic.click();
    await t.stable();
    const del = t.http.expectOne(`${TEST_API}/me/mutes/topics/t1`);
    expect(del.request.method).toBe('DELETE');
    del.flush({ fieldIds: [], topicIds: [] });
    await t.stable();
    expect(topic.getAttribute('aria-checked')).toBe('false');
    expect(mutes.hides(card, FEED)).toBe(false);

    // The field; a field page keeps its own field.
    field.click();
    await t.stable();
    t.http.expectOne(`${TEST_API}/me/mutes/fields/f1`).flush({ fieldIds: ['f1'], topicIds: [] });
    await t.stable();
    expect(field.getAttribute('aria-checked')).toBe('true');
    expect(mutes.hides(card, FEED)).toBe(true);
    expect(mutes.hides(card, { applies: true, shownFieldId: () => 'f1', shownTopicId: () => null })).toBe(false);

    sheet.querySelector<HTMLButtonElement>('[data-mute-topics-done]')!.click();
    await t.stable();
    expect(t.$('[data-mute-topics-sheet]')).toBeNull();
  });

  it('Mute topics without a topic: the field alone; a refusal puts the toggle back', async () => {
    const t = await render(testCard({ topic: null }));
    http = t.http;
    await t.openMenu();
    await t.pick('muteTopics');
    const sheet = (await t.waitFor('[data-mute-topics-sheet]'))!;
    expect(sheet.querySelectorAll('[role="switch"]')).toHaveLength(1);
    const field = sheet.querySelector<HTMLButtonElement>('[data-mute-field="f1"] [role="switch"]')!;
    field.click();
    await t.stable();
    t.http.expectOne(`${TEST_API}/me/mutes/fields/f1`).flush(problem(404, 'field.not_found'), { status: 404, statusText: 'Not Found' });
    await t.stable();
    expect(field.getAttribute('aria-checked')).toBe('false');
    expect(t.toasts.toasts().map((toast) => toast.kind)).toEqual(['error']);
  });

  it('moderators also hide, with a note dialog; the reader learns the article is hidden', async () => {
    const t = await render(testCard(), { permissions: MODERATOR });
    http = t.http;
    // Report ends the reader's items; the moderator's item comes last, after a divider (as on mobile).
    expect(await t.openMenu()).toEqual(['showLess', 'follow', 'muteAuthor', 'muteTopics', 'report', 'hide']);
    expect(document.querySelector('[data-menu-action="hide"]')!.textContent!.trim()).toBe('إخفاء المقال');
    const dividers = document.querySelectorAll('[data-article-menu-panel] [data-menu-divider]');
    expect(dividers).toHaveLength(1);
    expect(dividers[0].previousElementSibling!.getAttribute('data-menu-action')).toBe('report');
    expect(dividers[0].nextElementSibling!.getAttribute('data-menu-action')).toBe('hide');

    await t.pick('hide');
    const sheet = t.$('[data-moderation-sheet]')!;
    expect(sheet.getAttribute('data-moderation-action')).toBe('hide');
    expect(t.$('#moderation-sheet-title')!.textContent!.trim()).toBe('تخفي المقال ده؟');
    expect(t.$('label[for="moderation-note"]')!.textContent!.trim()).toBe('ملاحظة (اختياري)');
    const confirm = t.$<HTMLButtonElement>('[data-moderation-confirm]')!;
    expect(confirm.disabled).toBe(false); // the note is optional for hide
    expect(confirm.classList).toContain('bg-error');

    const note = t.$<HTMLTextAreaElement>('[data-moderation-note]')!;
    note.value = 'Copied from another site.';
    note.dispatchEvent(new Event('input'));
    await t.stable();
    confirm.click();
    const req = t.http.expectOne(`${TEST_API}/moderation/actions`);
    expect(req.request.body).toEqual({ action: 'hide', targetType: 'article', targetId: 'a1', note: 'Copied from another site.' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();

    expect(t.$('[data-moderation-sheet]')).toBeNull();
    expect(t.changes).toHaveLength(1);
    expect(t.changes[0]!.note).toBe('Copied from another site.');
    expect(Number.isNaN(Date.parse(t.changes[0]!.hiddenAt))).toBe(false);
    expect(t.toastList()).toEqual(['اتخفى']);
  });

  it('a hidden article offers Unhide, at once with a toast', async () => {
    const t = await render({ ...testCard(), moderation: { hiddenAt: '2026-11-03T09:00:00Z', note: null } }, { permissions: MODERATOR });
    http = t.http;
    expect(await t.openMenu()).toEqual(['showLess', 'follow', 'muteAuthor', 'muteTopics', 'report', 'unhide']);
    await t.pick('unhide');
    const req = t.http.expectOne(`${TEST_API}/moderation/actions`);
    expect(req.request.body).toEqual({ action: 'unhide', targetType: 'article', targetId: 'a1' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.changes).toEqual([null]);
    expect(t.toastList()).toEqual(['رجع ظاهر']);
  });

  it('a failed hide stays in the dialog with the reason', async () => {
    const t = await render(testCard(), { permissions: MODERATOR });
    http = t.http;
    await t.openMenu();
    await t.pick('hide');
    t.$('[data-moderation-confirm]')!.click();
    t.http.expectOne(`${TEST_API}/moderation/actions`).flush(problem(404, 'article.not_found'), { status: 404, statusText: 'Not Found' });
    await t.stable();
    expect(t.$('[data-moderation-error]')!.textContent!.trim()).toBe('المقال ده مش موجود');
    expect(t.changes).toEqual([]);
  });

  it('a moderator on their own article can mute its topics and hide it, but not report it', async () => {
    const t = await render(testCard(), { permissions: MODERATOR, myId: 'writer-1' });
    http = t.http;
    expect(await t.openMenu()).toEqual(['muteTopics', 'hide']);
    expect(document.querySelectorAll('[data-article-menu-panel] [data-menu-divider]')).toHaveLength(1);
  });
});
