import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { RepostDialog, RepostDialogMode } from './repost-dialog';

const REPOST_URL = `${TEST_API}/articles/a1/repost`;

async function render(options: { mode?: RepostDialogMode; lang?: 'ar' | 'en'; article?: ArticleCardDto } = {}) {
  const { http, toasts } = setupSocialTesting();
  await TestBed.inject(LanguageService).setLanguage(options.lang ?? 'en');
  const article = options.article ?? testCard({ repostCount: 3 });
  const fixture = TestBed.createComponent(RepostDialog);
  let closed = 0;
  fixture.componentInstance.closed.subscribe(() => {
    closed++;
    fixture.componentRef.setInput('request', null);
  });
  fixture.componentRef.setInput('request', { article, mode: options.mode ?? 'new' });
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    for (let i = 0; i < 3; i++) {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    }
  };
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  const field = () => $<HTMLTextAreaElement>('[data-repost-caption]')!;
  const submit = () => $<HTMLButtonElement>('[data-repost-submit]')!;
  const type = async (text: string) => {
    field().value = text;
    field().dispatchEvent(new Event('input'));
    await stable();
  };
  const send = async () => {
    $<HTMLFormElement>('[data-repost-dialog]')!.dispatchEvent(new Event('submit', { cancelable: true }));
    await stable();
  };
  const store = TestBed.inject(ArticleSocialStore);
  return { fixture, root, http, toasts, stable, $, field, submit, type, send, article, store, closed: () => closed };
}

describe('RepostDialog (F29: repost with your thoughts)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    http?.verify();
    http = null;
  });

  it('the title, the article (title, writer), the field with its placeholder, "0/500", Repost and Cancel', async () => {
    const t = await render();
    http = t.http;
    const dialog = t.$('section[role="dialog"]')!;
    expect(dialog.getAttribute('aria-modal')).toBe('true');
    const title = t.$('h2')!;
    expect(title.textContent!.trim()).toBe('Repost this article');
    expect(dialog.getAttribute('aria-labelledby')).toBe(title.id);
    expect(t.$('[data-repost-preview-title]')!.textContent!.trim()).toBe('Clean Architecture on one whiteboard');
    expect(t.$('[data-repost-preview-author]')!.textContent!.trim()).toBe('Karim Hassan');
    expect(t.$('[data-repost-preview] rd-avatar')).not.toBeNull();
    expect(t.field().getAttribute('placeholder')).toBe('Add your thoughts… (optional)');
    expect(t.root.querySelector(`label[for="${t.field().id}"]`)!.textContent!.trim()).toBe('Your thoughts on the article');
    expect(t.field().hasAttribute('data-initial-focus')).toBe(true);
    expect(t.field().readOnly).toBe(false);
    expect(t.$('[data-repost-count]')!.textContent!.trim()).toBe('0/500');
    expect(t.field().getAttribute('aria-describedby')).toBe(t.$('[data-repost-count]')!.id);
    expect(t.submit().textContent!.trim()).toBe('Repost');
    expect(t.submit().disabled).toBe(false); // thoughts are optional
    expect(t.$('[data-repost-cancel]')!.textContent!.trim()).toBe('Cancel');
    // The field grows with its text and never scrolls inside itself.
    expect(t.field().classList).toContain('caption');
    expect(t.field().classList).not.toContain('rd-autogrow');
  });

  it('in Arabic: the texts, and the field takes the UI direction until you type', async () => {
    const t = await render({ lang: 'ar' });
    http = t.http;
    expect(t.$('h2')!.textContent!.trim()).toBe('إعادة نشر المقال');
    expect(t.field().getAttribute('placeholder')).toBe('اكتب رأيك في المقال… (اختياري)');
    expect(t.submit().textContent!.trim()).toBe('نشر');
    expect(t.$('[data-repost-cancel]')!.textContent!.trim()).toBe('إلغاء');
    expect(t.field().getAttribute('dir')).toBe('rtl');
    await t.type('Great read');
    expect(t.field().getAttribute('dir')).toBe('ltr');
  });

  it('the counter counts what is left after trimming; over 500 it turns red and Repost is disabled', async () => {
    const t = await render();
    http = t.http;
    await t.type('  Worth a read.\n');
    expect(t.$('[data-repost-count]')!.textContent!.trim()).toBe('13/500'); // "Worth a read."
    await t.type('x'.repeat(500) + '   ');
    expect(t.$('[data-repost-count]')!.textContent!.trim()).toBe('500/500');
    expect(t.submit().disabled).toBe(false);
    expect(t.field().getAttribute('aria-invalid')).toBeNull();

    await t.type('x'.repeat(501));
    const count = t.$('[data-repost-count]')!;
    expect(count.textContent!.trim()).toBe('501/500');
    expect(count.classList).toContain('text-error');
    expect(count.hasAttribute('data-over')).toBe(true);
    expect(t.field().getAttribute('aria-invalid')).toBe('true');
    expect(t.submit().disabled).toBe(true);
    await t.send();
    t.http.expectNone(REPOST_URL);
  });

  it('Repost sends PUT { caption }; on success the button state and count change everywhere, a toast confirms, the dialog closes', async () => {
    const t = await render();
    http = t.http;
    await t.type('أحسن مقال قريته.\nWorth it.');
    await t.send();
    expect(t.submit().disabled).toBe(true); // busy
    expect(t.field().readOnly).toBe(true);
    const put = t.http.expectOne(REPOST_URL);
    expect(put.request.method).toBe('PUT');
    expect(put.request.body).toEqual({ caption: 'أحسن مقال قريته.\nWorth it.' });
    put.flush({ repostCount: 4, isReposted: true, caption: 'أحسن مقال قريته.\nWorth it.' });
    await t.stable();
    expect(t.store.state(t.article)).toEqual(expect.objectContaining({ isReposted: true, repostCount: 4 }));
    expect(t.store.myCaption('a1')).toBe('أحسن مقال قريته.\nWorth it.');
    expect(t.toasts.toasts().map((toast) => [toast.kind, toast.message])).toEqual([['success', 'You reposted this article.']]);
    expect(t.closed()).toBe(1);
    expect(t.$('[data-repost-dialog]')).toBeNull();
  });

  it('stays open on an error and shows it: repost.caption_too_long, repost.own_article, then the others', async () => {
    const t = await render({ lang: 'ar' });
    http = t.http;
    await t.type('رأيي');
    await t.send();
    t.http
      .expectOne(REPOST_URL)
      .flush(problem(400, 'validation.failed', { caption: ['repost.caption_too_long'] }), { status: 400, statusText: 'Bad Request' });
    await t.stable();
    expect(t.closed()).toBe(0);
    expect(t.$('[data-repost-error]')!.textContent!.trim()).toBe('يجب ألا يتجاوز رأيك 500 حرف.');
    expect(t.$('[data-repost-error]')!.getAttribute('role')).toBe('alert');
    expect(t.submit().disabled).toBe(false);
    expect(t.field().value).toBe('رأيي');

    await t.send();
    expect(t.$('[data-repost-error]')).toBeNull(); // a new try clears the old error
    t.http.expectOne(REPOST_URL).flush(problem(400, 'repost.own_article'), { status: 400, statusText: 'Bad Request' });
    await t.stable();
    expect(t.$('[data-repost-error]')!.textContent!.trim()).toBe('لا يمكنك إعادة نشر مقالك.');

    await t.send();
    t.http.expectOne(REPOST_URL).flush(problem(429, 'rate_limited'), { status: 429, statusText: 'Too Many Requests' });
    await t.stable();
    expect(t.$('[data-repost-error]')!.textContent!.trim()).toBe('طلبات كثيرة جدًا. انتظر قليلًا ثم حاول مرة أخرى.');
    expect(t.closed()).toBe(0);
    expect(t.toasts.toasts()).toEqual([]);
    // Nothing changed on the button.
    expect(t.store.state(t.article)).toEqual(expect.objectContaining({ isReposted: false, repostCount: 3 }));
  });

  it('editing: prefilled from GET (read-only while it loads), "Save", and an empty field clears your thoughts', async () => {
    const article = testCard({ repostCount: 5, isReposted: true });
    const t = await render({ mode: 'edit', article });
    http = t.http;
    expect(t.$('[data-repost-dialog]')!.getAttribute('data-state')).toBe('loading');
    expect(t.$('[data-repost-loading]')!.textContent!.trim()).toBe('Loading your thoughts…');
    expect(t.field().readOnly).toBe(true);
    expect(t.submit().disabled).toBe(true);
    const get = t.http.expectOne(REPOST_URL);
    expect(get.request.method).toBe('GET');
    get.flush({ repostCount: 6, isReposted: true, caption: 'My old thoughts' });
    await t.stable();
    expect(t.field().value).toBe('My old thoughts');
    expect(t.field().readOnly).toBe(false);
    expect(t.$('[data-repost-count]')!.textContent!.trim()).toBe('15/500');
    expect(t.submit().textContent!.trim()).toBe('Save');
    expect(t.store.state(article).repostCount).toBe(6); // the server's count

    await t.type('');
    await t.send();
    const put = t.http.expectOne(REPOST_URL);
    expect(put.request.method).toBe('PUT');
    expect(put.request.body).toEqual({ caption: '' });
    put.flush({ repostCount: 6, isReposted: true, caption: null });
    await t.stable();
    expect(t.store.myCaption('a1')).toBeNull();
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['Your thoughts were saved.']);
    expect(t.closed()).toBe(1);
  });

  it('editing when the repost was undone elsewhere: a new repost ("Repost"), and the button shows it', async () => {
    const article = testCard({ repostCount: 5, isReposted: true });
    const t = await render({ mode: 'edit', article, lang: 'ar' });
    http = t.http;
    t.http.expectOne(REPOST_URL).flush({ repostCount: 4, isReposted: false, caption: null });
    await t.stable();
    expect(t.$('[data-repost-dialog]')!.getAttribute('data-mode')).toBe('new');
    expect(t.submit().textContent!.trim()).toBe('نشر');
    expect(t.field().value).toBe('');
    expect(t.store.state(article)).toEqual(expect.objectContaining({ isReposted: false, repostCount: 4 }));
  });

  it('editing: a failed GET shows the error with Retry, and Save waits', async () => {
    const t = await render({ mode: 'edit', article: testCard({ isReposted: true, repostCount: 1 }) });
    http = t.http;
    t.http.expectOne(REPOST_URL).error(new ProgressEvent('error'));
    await t.stable();
    expect(t.$('[data-repost-dialog]')!.getAttribute('data-state')).toBe('error');
    expect(t.$('[data-repost-error]')).not.toBeNull();
    expect(t.submit().disabled).toBe(true);
    t.$<HTMLButtonElement>('[data-repost-retry]')!.click();
    await t.stable();
    t.http.expectOne(REPOST_URL).flush({ repostCount: 1, isReposted: true, caption: 'Again' });
    await t.stable();
    expect(t.$('[data-repost-error]')).toBeNull();
    expect(t.field().value).toBe('Again');
    expect(t.submit().disabled).toBe(false);
  });

  it('a deleted writer: the generic avatar and "deleted account"', async () => {
    const t = await render({ article: testCard({ author: null }) });
    http = t.http;
    expect(t.$('[data-repost-preview-author]')!.textContent!.trim()).toBe(TestBed.inject(TranslocoService).translate('common.deletedUser'));
    expect(t.$('[data-repost-preview] rd-avatar')).not.toBeNull();
  });
});
