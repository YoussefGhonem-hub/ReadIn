import { TestBed } from '@angular/core/testing';
import { AdminSummaryStore } from '../../../core/admin/admin-summary.store';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { renderAdmin, testArticleRow, testCommentRow, testPage } from '../../../../testing/admin-testing';
import { testMe } from '../../../../testing/auth-testing';
import { TEST_API, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { AdminArticlePage } from './article.page';
import { AdminContentPage } from './content.page';

const params = (req: TestRequest) => Object.fromEntries(req.request.params.keys().map((k) => [k, req.request.params.get(k)]));

describe('Admin console: Content (F23)', () => {
  let http: HttpTestingController;

  function setup(permissions = ['admin.access', 'moderation.manage', 'articles.feature', 'users.read']) {
    TestBed.resetTestingModule();
    // The console's badge store is not what these pages test.
    const testing = setupSocialTesting({ providers: [{ provide: AdminSummaryStore, useValue: { refresh: () => Promise.resolve() } }] });
    http = testing.http;
    testing.session.setMe(testMe({ permissions }));
    return testing;
  }

  afterEach(() => http.verify());

  it('articles: the filters from the URL, a row per article with its state, linking to its console page', async () => {
    setup();
    const t = renderAdmin(AdminContentPage, { from: '2026-11-01', to: '2026-11-07', hidden: 'true', reported: 'true', featured: 'nope', writer: 'writer-1', q: 'clean' });
    http.expectOne(`${TEST_API}/fields`).flush([]);
    const req = http.expectOne((r) => r.url === `${TEST_API}/admin/articles`);
    expect(params(req)).toEqual({ from: '2026-11-01', to: '2026-11-07', writer: 'writer-1', hidden: 'true', reported: 'true', q: 'clean', page: '1', pageSize: '50' });
    req.flush(
      testPage([
        testArticleRow({ hiddenAt: '2026-11-05T00:00:00Z', openReports: 2, reportCount: 3 }),
        // As built: an archived article that was never published has no publish date.
        testArticleRow({ id: 'a2', status: 'archived', publishedAt: null }),
      ]),
    );
    await t.stable();
    const row = t.$('[data-article-row="a1"]')!;
    expect(row.querySelector('a')!.getAttribute('href')).toBe('/admin/content/a1');
    expect(row.querySelector('[data-tag-hidden]')).not.toBeNull();
    expect(row.querySelector('[data-tag-featured]')).toBeNull();
    expect(t.$('[data-article-row="a2"] [data-never-published]')!.textContent).toContain('لم يُنشر قط');
    // The writer filter names the writer from their rows.
    expect(t.$('[data-writer-filter]')!.textContent).toContain('Karim Hassan');
  });

  it('latest comments: hide and delete go through the moderation sheet', async () => {
    setup();
    const t = renderAdmin(AdminContentPage, { tab: 'comments' });
    http.expectOne(`${TEST_API}/fields`).flush([]);
    const req = http.expectOne((r) => r.url === `${TEST_API}/admin/comments`);
    expect(params(req)).toEqual({ page: '1', pageSize: '50' });
    req.flush(testPage([testCommentRow()]));
    await t.stable();
    expect(t.$('[data-comment-body]')!.getAttribute('dir')).toBe('auto');

    t.$('[data-comment-action="hide"]')!.click();
    await t.stable();
    t.$<HTMLButtonElement>('[data-moderation-confirm]')!.click();
    const act = http.expectOne(`${TEST_API}/moderation/actions`);
    expect(act.request.body).toEqual({ action: 'hide', targetType: 'comment', targetId: 'c1' });
    act.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.$('[data-comment-row="c1"] [data-tag-hidden]')).not.toBeNull();
    expect(t.$('[data-comment-action="unhide"]')).not.toBeNull();
  });

  it("an article's console page: Hide, Feature (confirmed) and its reports", async () => {
    setup();
    const t = renderAdmin(AdminArticlePage, { id: 'a1' });
    http.expectOne(`${TEST_API}/admin/articles/a1`).flush(testArticleRow({ reportCount: 2, openReports: 1 }));
    await t.stable();
    expect(t.$('[data-article-reports]')!.getAttribute('href')).toBe('/admin/reports/article/a1');
    expect(t.$('[data-article-open]')!.getAttribute('href')).toBe('/en/a/clean-architecture');
    expect(t.$('[data-article-author]')!.getAttribute('href')).toBe('/admin/users/writer-1');

    t.$('[data-article-action="feature"]')!.click();
    await t.stable();
    t.$('[data-confirm-ok]')!.click();
    http.expectOne({ method: 'PUT', url: `${TEST_API}/admin/articles/a1/featured` }).flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    http.expectOne(`${TEST_API}/admin/articles/a1`).flush(testArticleRow({ featuredAt: '2026-11-07T10:00:00Z' }));
    await t.stable();
    expect(t.$('[data-tag-featured]')).not.toBeNull();
    expect(t.$('[data-article-action="unfeature"]')).not.toBeNull();
  });

  it('without articles.feature there is no Feature; an unknown article is "not found"', async () => {
    setup(['admin.access', 'moderation.manage']);
    const t = renderAdmin(AdminArticlePage, { id: 'a1' });
    http.expectOne(`${TEST_API}/admin/articles/a1`).flush(testArticleRow());
    await t.stable();
    expect(t.$('[data-article-action="feature"]')).toBeNull();
    expect(t.$('[data-article-action="hide"]')).not.toBeNull();

    const missing = renderAdmin(AdminArticlePage, { id: 'gone' });
    http.expectOne(`${TEST_API}/admin/articles/gone`).flush(problem(404, 'article.not_found'), { status: 404, statusText: 'Not Found' });
    await missing.stable();
    expect(missing.$('[data-article-not-found]')).not.toBeNull();
  });
});
