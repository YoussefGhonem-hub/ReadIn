import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { renderAdmin, testArticleRow, testPage } from '../../../testing/admin-testing';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, problem, setupSocialTesting } from '../../../testing/social-testing';
import { AdminPathDto, AdminSystemDto, AuditEntryDto } from '../../core/api/models';
import { AnnouncementForm, AdminAnnouncementsPage, announcementRequest } from './announcements/announcements.page';
import { AdminAuditPage } from './audit/audit.page';
import { auditActionLabel, auditTargetLink } from './audit/audit-entry';
import { AdminPathsPage } from './paths/paths.page';
import { AdminSystemPage, formatDuration } from './system/system.page';

const params = (req: TestRequest) => Object.fromEntries(req.request.params.keys().map((k) => [k, req.request.params.get(k)]));

function path(id: string, patch: Partial<AdminPathDto> = {}): AdminPathDto {
  return {
    id,
    slug: id,
    fieldId: 'f1',
    titleAr: `مسار ${id}`,
    titleEn: `Path ${id}`,
    descriptionAr: null,
    descriptionEn: null,
    sortOrder: 1,
    isPublished: true,
    isEditorial: false,
    articleIds: ['a1'],
    enrollmentCount: 3,
    isFeatured: false,
    featuredOrder: null,
    ...patch,
  };
}

describe('Admin console sections (F23)', () => {
  let http: HttpTestingController;

  function setup(permissions: string[]) {
    TestBed.resetTestingModule();
    const testing = setupSocialTesting();
    http = testing.http;
    testing.session.setMe(testMe({ permissions: ['admin.access', ...permissions] }));
  }

  afterEach(() => http.verify());

  describe('Paths & featured', () => {
    async function render() {
      setup(['paths.manage', 'articles.feature', 'moderation.manage']);
      const t = renderAdmin(AdminPathsPage);
      http.expectOne(`${TEST_API}/fields`).flush([]);
      http.expectOne((r) => r.url === `${TEST_API}/admin/articles` && r.params.get('featured') === 'true').flush(testPage([testArticleRow({ featuredAt: '2026-11-06T00:00:00Z' })]));
      http.expectOne(`${TEST_API}/admin/paths`).flush([path('p1', { isFeatured: true, featuredOrder: 1 }), path('p2'), path('ed', { isEditorial: true })]);
      await t.stable();
      return t;
    }

    it('editorial paths are read only; the featured list saves as a whole, in order', async () => {
      const t = await render();
      expect(t.$('[data-path-row="ed"] [data-path-edit]')).toBeNull();
      expect(t.$('[data-path-row="ed"] [data-editorial]')).not.toBeNull();
      expect(t.$('[data-path-row="p2"] [data-path-edit]')).not.toBeNull();
      expect(t.$$('[data-featured-path]').map((r) => r.getAttribute('data-featured-path'))).toEqual(['p1']);
      expect(t.$<HTMLButtonElement>('[data-save-featured]')!.disabled).toBe(true);

      t.type('[data-add-featured]', 'p2', 'change');
      await t.stable();
      expect(t.$$('[data-featured-path]').map((r) => r.getAttribute('data-featured-path'))).toEqual(['p1', 'p2']);
      t.$('[data-save-featured]')!.click();
      const req = http.expectOne({ method: 'PUT', url: `${TEST_API}/admin/paths/featured` });
      expect(req.request.body).toEqual({ pathIds: ['p1', 'p2'] });
      req.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      http.expectOne(`${TEST_API}/admin/paths`).flush([path('p1', { isFeatured: true, featuredOrder: 1 }), path('p2', { isFeatured: true, featuredOrder: 2 })]);
      await t.stable();
    });

    it('publishing sends the whole path back; the featured articles can be unfeatured', async () => {
      const t = await render();
      t.$('[data-path-row="p2"] [data-path-publish]')!.click();
      const put = http.expectOne({ method: 'PUT', url: `${TEST_API}/admin/paths/p2` });
      expect(put.request.body).toEqual({ slug: 'p2', fieldId: 'f1', titleAr: 'مسار p2', titleEn: 'Path p2', descriptionAr: null, descriptionEn: null, sortOrder: 1, isPublished: false });
      put.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      http.expectOne(`${TEST_API}/admin/paths`).flush([path('p1'), path('p2', { isPublished: false })]);
      await t.stable();

      // As built: an article deleted since answers 404; it leaves the list all the same.
      t.$('[data-featured-article="a1"] [data-unfeature]')!.click();
      http.expectOne({ method: 'DELETE', url: `${TEST_API}/admin/articles/a1/featured` }).flush(problem(404, 'article.not_found'), { status: 404, statusText: 'Not Found' });
      await t.stable();
      expect(t.$('[data-no-featured-articles]')).not.toBeNull();
    });
  });

  describe('Announcements', () => {
    const FORM: AnnouncementForm = {
      titleAr: 'ميزة جديدة',
      titleEn: 'Something new',
      bodyAr: 'جرّب المسارات',
      bodyEn: 'Try the paths',
      audience: 'all',
      fieldId: '',
      language: 'ar-EG',
      linkType: 'none',
      article: null,
      pathId: '',
    };

    it('builds the request only when complete and within the limits', () => {
      expect(announcementRequest(FORM)).toEqual({ titleAr: 'ميزة جديدة', titleEn: 'Something new', bodyAr: 'جرّب المسارات', bodyEn: 'Try the paths', link: null, audience: { type: 'all' } });
      expect(announcementRequest({ ...FORM, titleEn: '  ' })).toBeNull();
      expect(announcementRequest({ ...FORM, titleAr: 'x'.repeat(61) })).toBeNull();
      expect(announcementRequest({ ...FORM, audience: 'field' })).toBeNull();
      expect(announcementRequest({ ...FORM, audience: 'field', fieldId: 'f1' })!.audience).toEqual({ type: 'field', fieldId: 'f1' });
      expect(announcementRequest({ ...FORM, audience: 'language', language: 'en' })!.audience).toEqual({ type: 'language', language: 'en' });
      expect(announcementRequest({ ...FORM, linkType: 'article' })).toBeNull();
      expect(announcementRequest({ ...FORM, linkType: 'path', pathId: 'p1' })!.link).toEqual({ type: 'path', id: 'p1' });
    });

    it('preview, test, then send after a dialog with the recipient count; a change asks for a new preview', async () => {
      setup(['notifications.broadcast']);
      const t = renderAdmin(AdminAnnouncementsPage);
      http.expectOne(`${TEST_API}/admin/announcements`).flush({ canSend: true, nextAllowedAt: null, items: [] });
      http.expectOne(`${TEST_API}/fields`).flush([]);
      http.expectOne(`${TEST_API}/paths`).flush([]);
      await t.stable();

      const send = t.$<HTMLButtonElement>('[data-ann-send]')!;
      t.type('[data-ann-title-ar]', FORM.titleAr);
      t.type('[data-ann-title-en]', FORM.titleEn);
      t.type('[data-ann-body-ar]', FORM.bodyAr);
      t.type('[data-ann-body-en]', FORM.bodyEn);
      expect(send.disabled).toBe(true);

      t.$('[data-ann-preview-button]')!.click();
      http.expectOne({ method: 'POST', url: `${TEST_API}/admin/announcements/preview` }).flush({ recipientCount: 1200, pushCount: 900, canSend: true, nextAllowedAt: null });
      await t.stable();
      expect(t.$('[data-ann-reach]')!.textContent).toContain('1200');
      expect(send.disabled).toBe(false);

      t.$('[data-ann-test]')!.click();
      http.expectOne({ method: 'POST', url: `${TEST_API}/admin/announcements/test` }).flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();

      // Editing the text needs a new preview.
      t.type('[data-ann-body-en]', 'Try the learning paths');
      expect(send.disabled).toBe(true);
      t.$('[data-ann-preview-button]')!.click();
      http.expectOne(`${TEST_API}/admin/announcements/preview`).flush({ recipientCount: 1200, pushCount: 900, canSend: true, nextAllowedAt: null });
      await t.stable();

      send.click();
      await t.stable();
      expect(t.$('[data-admin-confirm]')!.textContent).toContain('1200');
      t.$('[data-confirm-ok]')!.click();
      const req = http.expectOne({ method: 'POST', url: `${TEST_API}/admin/announcements` });
      expect(req.request.body.bodyEn).toBe('Try the learning paths');
      req.flush(problem(429, 'announcement.limit'), { status: 429, statusText: 'Too Many Requests' });
      await t.stable();
      expect(t.$('[data-confirm-error]')!.textContent).toContain('إعلان واحد في اليوم');
    });
  });

  describe('Audit log', () => {
    it('labels codes (unknown ones as they are) and links targets', () => {
      setup(['audit.read']);
      const transloco = TestBed.inject(TranslocoService);
      expect(auditActionLabel(transloco, { source: 'audit', action: 'admin.pii_viewed' })).toBe('عرض رقم الهاتف');
      expect(auditActionLabel(transloco, { source: 'moderation', action: 'user.suspend' })).toBe('أوقف حسابًا');
      expect(auditActionLabel(transloco, { source: 'audit', action: 'auth.something_new' })).toBe('auth.something_new');
      expect(auditTargetLink({ type: 'user', id: 'u1', label: null })).toBe('/admin/users/u1');
      expect(auditTargetLink({ type: 'ticket', id: 't1', label: '#3' })).toBe('/admin/tickets/t1');
      expect(auditTargetLink({ type: 'tag', id: 'g1', label: 'x' })).toBeNull();
    });

    it('filters from the URL; entries show the IP only when the API sends it', async () => {
      setup(['audit.read', 'users.read.pii']);
      const t = renderAdmin(AdminAuditPage, { target: 'u-salma', action: 'admin.', source: 'audit', from: '2026-11-01' });
      const req = http.expectOne((r) => r.url === `${TEST_API}/admin/audit`);
      expect(params(req)).toEqual({ target: 'u-salma', action: 'admin.', source: 'audit', from: '2026-11-01', page: '1', pageSize: '50' });
      const entry: AuditEntryDto = {
        id: 'e1',
        source: 'audit',
        action: 'admin.pii_viewed',
        actor: { id: 'admin', displayName: 'Youssef', username: 'readin_admin', avatarUrl: null },
        targetUser: { id: 'u-salma', displayName: 'Salma', username: 'salma', avatarUrl: null },
        target: { type: 'user', id: 'u-salma', label: '@salma' },
        details: null,
        ip: '41.33.0.1',
        createdAt: '2026-11-07T10:00:00Z',
      };
      req.flush(testPage([entry, { ...entry, id: 'e2', ip: null, details: 'nameEn, isEnabled=false', action: 'admin.field_updated' }]));
      await t.stable();
      expect(t.$$('[data-audit-entry]').length).toBe(2);
      expect(t.$('[data-audit-entry="e1"] [data-audit-ip]')!.textContent).toBe('41.33.0.1');
      expect(t.$('[data-audit-entry="e2"] [data-audit-ip]')).toBeNull();
      expect(t.$('[data-audit-entry="e2"] [data-audit-details]')!.getAttribute('dir')).toBe('auto');
      expect(t.$('[data-prefix="admin."]')!.getAttribute('aria-pressed')).toBe('true');
    });
  });

  describe('System', () => {
    const SYSTEM: AdminSystemDto = {
      api: { version: '1.4.0+abc', startedAt: '2026-11-07T06:00:00Z', environment: 'Production' },
      updatePolicy: { ios: { minimumVersion: null, storeUrl: null }, android: { minimumVersion: '1.2.0', storeUrl: 'https://play.google.com/store/apps/details?id=x' } },
      database: { reachable: true, latencyMs: 12 },
      firebase: { messagingConfigured: true, realtimeConfigured: true, realtimeReachable: false },
      jobs: [
        { id: 'daily-article', schedule: '*/5 * * * *', lastRunAt: '2026-11-07T11:55:00Z', lastSucceeded: true, lastDurationMs: 1400, lastError: null, runs24h: 288, failures24h: 0 },
        // As built: a job that ran but isn't registered any more has an empty schedule.
        { id: 'tags-cleanup', schedule: '', lastRunAt: null, lastSucceeded: null, lastDurationMs: null, lastError: null, runs24h: 0, failures24h: 0 },
      ],
      push: { sent: 340, failed: 2, invalidTokens: 1, since: '2026-11-06T12:00:00Z' },
      storage: { uploadsBytes: 52_428_800, uploadsFiles: 410, privateBytes: 1_048_576, privateFiles: 3, measuredAt: '2026-11-07T11:50:00Z' },
    };

    it('shows the health, jobs and storage, and rebuilds the counters after a dialog', async () => {
      setup(['system.settings']);
      expect([formatDuration(1400), formatDuration(340), formatDuration(null)]).toEqual(['1.4 s', '340 ms', '—']);
      const t = renderAdmin(AdminSystemPage);
      http.expectOne(`${TEST_API}/admin/system`).flush(SYSTEM);
      await t.stable();
      expect(t.$$('[data-job]').map((j) => j.getAttribute('data-job'))).toEqual(['daily-article', 'tags-cleanup']);
      expect(t.$('[data-job="tags-cleanup"] [data-job-unregistered]')).not.toBeNull();
      expect(t.$('[data-health="realtime"]')!.textContent).toContain('غير متاحة');
      expect(t.$('[data-system-storage]')!.textContent).toContain('50.0');

      t.$('[data-rebuild-counters]')!.click();
      await t.stable();
      t.$('[data-confirm-ok]')!.click();
      http.expectOne({ method: 'POST', url: `${TEST_API}/admin/realtime/rebuild-counters` }).flush({ articles: 300 });
      await t.stable();
      expect(t.$('[data-admin-confirm]')).toBeNull();
    });
  });
});
