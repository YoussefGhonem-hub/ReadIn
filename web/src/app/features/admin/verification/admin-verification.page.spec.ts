import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { testAdminRequest } from '../../../../testing/verification-testing';
import { AdminVerificationRequestDto } from '../../../core/api/models';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { AdminVerificationPage } from './admin-verification.page';
import { proofKind } from './proof-preview';

const LIST = `${TEST_API}/admin/verification-requests`;
const PNG = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]);

const PDF_REQUEST = testAdminRequest('vr-omar', {
  user: { id: 'u-omar', displayName: 'Omar Fathy', username: 'omar_dev', avatarUrl: null, isVerified: false },
  field: { id: 'f-medicine', slug: 'medicine', name: 'الطب' },
  jobTitle: 'Medical student, Kasr Al Ainy',
  proofUrl: null,
  proof: { fileName: 'syndicate-card.pdf', contentType: 'application/pdf', sizeBytes: 182_400 },
  note: null,
  submittedAt: '2026-11-03T07:30:00Z',
});

describe('AdminVerificationPage (F19)', () => {
  let http: HttpTestingController;
  let navigate: ReturnType<typeof vi.fn>;
  const created: string[] = [];
  const revoked: string[] = [];

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
    navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true) as unknown as ReturnType<typeof vi.fn>;
    created.length = 0;
    revoked.length = 0;
    URL.createObjectURL = vi.fn(() => {
      const url = `blob:http://localhost/proof-${created.length + 1}`;
      created.push(url);
      return url;
    });
    URL.revokeObjectURL = vi.fn((url: string) => void revoked.push(url));
  });

  afterEach(() => http.verify());

  const params = (req: TestRequest) => Object.fromEntries(req.request.params.keys().map((k) => [k, req.request.params.get(k)]));

  async function render(inputs: { status?: string; id?: string } = {}, items: AdminVerificationRequestDto[] = [testAdminRequest(), PDF_REQUEST]) {
    const fixture = TestBed.createComponent(AdminVerificationPage);
    if (inputs.status) fixture.componentRef.setInput('status', inputs.status);
    if (inputs.id) fixture.componentRef.setInput('id', inputs.id);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await flushMicrotasks();
      fixture.detectChanges();
    };
    const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
    const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
    expect($('[data-verification-list-loading]')).not.toBeNull();
    const list = http.expectOne((r) => r.url === LIST);
    expect(params(list)).toEqual({ status: inputs.status ?? 'pending', limit: '20' });
    list.flush({ items, nextCursor: null });
    await stable();
    /** Opens a request the way the router does: `?id=`. */
    const open = async (id: string | undefined) => {
      fixture.componentRef.setInput('id', id);
      await stable();
    };
    const proof = (id: string) => http.expectOne({ method: 'GET', url: `${LIST}/${id}/proof` });
    return { fixture, root, stable, $, $$, open, proof };
  }

  it('pending: one row per request (who, field, job title, when), oldest first; the tabs keep their URLs', async () => {
    const t = await render();
    expect(t.$('[data-verification-tab="pending"]')!.getAttribute('aria-current')).toBe('page');
    expect(t.$$('[data-verification-tab]').map((tab) => tab.textContent!.trim())).toEqual(['قيد المراجعة', 'مقبولة', 'مرفوضة']);
    expect(t.$('[data-verification-tab="approved"]')!.getAttribute('href')).toBe('/admin/verification?status=approved');
    expect(t.$('[data-verification-tab="pending"]')!.getAttribute('href')).toBe('/admin/verification');

    const rows = t.$$('[data-verification-row]');
    expect(rows.map((r) => r.getAttribute('data-verification-row'))).toEqual(['vr-salma', 'vr-omar']);
    expect(rows[0].getAttribute('href')).toBe('/admin/verification?id=vr-salma');
    expect(rows[0].textContent).toContain('سلمى إبراهيم');
    expect(rows[0].textContent).toContain('@salma');
    expect(rows[0].querySelector('[data-row-field]')!.textContent!.trim()).toBe('البرمجيات');
    expect(rows[0].querySelector('[data-row-job-title]')!.getAttribute('dir')).toBe('ltr');
    expect(rows[0].querySelector('[data-row-time]')!.textContent).toContain('أُرسل');
    expect(t.$('[data-verification-pick]')!.textContent).toContain('اختر طلبًا لمراجعته.');
  });

  it('a tab without requests says so; a failed list can be retried', async () => {
    const t = await render({ status: 'rejected' }, []);
    expect(t.$('[data-verification-empty]')!.textContent).toContain('لا توجد طلبات مرفوضة');

    t.fixture.componentRef.setInput('status', 'approved');
    await t.stable();
    http.expectOne((r) => r.url === LIST && r.params.get('status') === 'approved').flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await t.stable();
    expect(t.$('rd-error-state')!.textContent).toContain('تعذّر تحميل الطلبات.');
    t.$<HTMLButtonElement>('rd-error-state button')!.click();
    http.expectOne((r) => r.url === LIST && r.params.get('status') === 'approved').flush({ items: [], nextCursor: null });
    await t.stable();
    expect(t.$('[data-verification-empty]')!.textContent).toContain('لا توجد طلبات مقبولة بعد');
  });

  it('a request: the job title, note and proof link (new tab, no referrer); the image proof fetched with the session and shown inline', async () => {
    const t = await render();
    await t.open('vr-salma');
    const detail = t.$('[data-verification-detail="vr-salma"]')!;
    expect(t.$('[data-verification-row="vr-salma"]')!.getAttribute('aria-current')).toBe('true');
    expect(detail.querySelector('[data-detail-status]')!.textContent!.trim()).toBe('قيد المراجعة');
    expect(detail.querySelector('[data-detail-job-title]')!.textContent).toBe('ML engineer في Instabug');
    expect(detail.querySelector('[data-detail-note]')!.getAttribute('dir')).toBe('rtl');
    const link = detail.querySelector<HTMLAnchorElement>('[data-detail-proof-url]')!;
    expect(link.getAttribute('href')).toBe('https://www.linkedin.com/in/salma-ibrahim');
    expect(link.getAttribute('target')).toBe('_blank');
    expect(link.getAttribute('rel')).toBe('noopener noreferrer');

    // The file: never a link to the API, fetched as a blob.
    expect(detail.querySelector('[data-proof-loading]')).not.toBeNull();
    const req = t.proof('vr-salma');
    expect(req.request.responseType).toBe('blob');
    req.flush(new Blob([PNG], { type: 'image/png' }));
    await t.stable();
    const image = detail.querySelector<HTMLImageElement>('[data-proof-image]')!;
    expect(image.getAttribute('src')).toBe('blob:http://localhost/proof-1');
    expect(image.getAttribute('alt')).toBe('الإثبات: aws-ml-certificate.png');
    expect(detail.querySelector('[data-proof-open]')!.getAttribute('href')).toBe('blob:http://localhost/proof-1');
    expect(detail.querySelector('[data-proof-open]')!.getAttribute('rel')).toBe('noopener noreferrer');
    expect(t.$$('a[href*="verification-requests"]')).toEqual([]);

    // Another request: the old object URL is revoked; leaving revokes the new one.
    await t.open('vr-omar');
    expect(revoked).toEqual(['blob:http://localhost/proof-1']);
    t.proof('vr-omar').flush(new Blob(['%PDF-1.4'], { type: 'application/pdf' }));
    await t.stable();
    const pdf = t.$('[data-verification-detail="vr-omar"]')!;
    expect(pdf.querySelector('[data-proof-image]')).toBeNull();
    expect(pdf.querySelector('[data-proof-open]')!.getAttribute('href')).toBe('blob:http://localhost/proof-2');
    expect(pdf.querySelector('[data-proof-open]')!.getAttribute('target')).toBe('_blank');
    expect(pdf.querySelector('[data-proof-open]')!.textContent).toContain('فتح ملف PDF');
    expect(pdf.querySelector('[data-proof-name]')!.textContent).toBe('syndicate-card.pdf');
    // 182,400 bytes in the UI language (no "KB" literal, no forced LTR).
    expect(pdf.querySelector('[data-proof-size]')!.textContent).toBe('178 ك.ب');
    expect(pdf.querySelector('[data-proof-size]')!.hasAttribute('dir')).toBe(false);
    t.fixture.destroy();
    expect(revoked).toEqual(['blob:http://localhost/proof-1', 'blob:http://localhost/proof-2']);
  });

  it('a proof that is gone, failed or of another type: said so, never opened', async () => {
    const t = await render();
    await t.open('vr-salma');
    t.proof('vr-salma').flush(new Blob([JSON.stringify(problem(404, 'verification.proof_not_found'))], { type: 'application/problem+json' }), {
      status: 404,
      statusText: 'Not Found',
    });
    await t.stable();
    expect(t.$('[data-proof-gone]')!.textContent).toContain('لم يعد الملف موجودًا.');

    await t.open('vr-omar');
    t.proof('vr-omar').flush(new Blob(['x']), { status: 500, statusText: 'Error' });
    await t.stable();
    expect(t.$('[data-proof-error]')).not.toBeNull();
    t.$<HTMLButtonElement>('[data-proof-error] button')!.click();
    t.proof('vr-omar').flush(new Blob(['<script>alert(1)</script>'], { type: 'text/html' }));
    await t.stable();
    expect(t.$('[data-proof-open]')).toBeNull();
    expect(t.$('[data-proof-unsupported]')).not.toBeNull();
    expect(created).toEqual([]);

    expect(proofKind('image/webp')).toBe('image');
    expect(proofKind('image/svg+xml')).toBe('other');
    expect(proofKind('application/pdf')).toBe('pdf');
  });

  it('approve: asked first, off the list at once, then thanked', async () => {
    const t = await render();
    await t.open('vr-salma');
    t.proof('vr-salma').flush(new Blob([PNG], { type: 'image/png' }));
    await t.stable();

    t.$<HTMLButtonElement>('[data-detail-approve]')!.click();
    await t.stable();
    const sheet = t.$('[data-decision-sheet]')!;
    expect(sheet.getAttribute('data-decision')).toBe('approve');
    expect(sheet.textContent).toContain('هل تريد الموافقة على طلب ⁨سلمى إبراهيم⁩؟');
    http.expectNone(`${LIST}/vr-salma/approve`);
    t.$<HTMLButtonElement>('[data-decision-confirm]')!.click();
    await t.stable();

    expect(t.$('[data-decision-sheet]')).toBeNull();
    expect(t.$$('[data-verification-row]').map((r) => r.getAttribute('data-verification-row'))).toEqual(['vr-omar']);
    expect(t.$('[data-verification-detail]')).toBeNull();
    expect(navigate).toHaveBeenCalledWith(['/admin/verification'], { queryParams: { status: null }, replaceUrl: true });
    http.expectOne({ method: 'POST', url: `${LIST}/vr-salma/approve` }).flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'success', message: 'أصبح ⁨سلمى إبراهيم⁩ كاتبًا موثّقًا ✓' })]);
  });

  it('reject needs a reason of 5+ characters; a refusal brings the request back to its place', async () => {
    const t = await render();
    await t.open('vr-salma');
    t.proof('vr-salma').flush(new Blob([PNG], { type: 'image/png' }));
    await t.stable();

    t.$<HTMLButtonElement>('[data-detail-reject]')!.click();
    await t.stable();
    const confirm = () => t.$<HTMLButtonElement>('[data-decision-confirm]')!;
    expect(confirm().disabled).toBe(true);
    const reason = t.$<HTMLTextAreaElement>('[data-decision-reason]')!;
    reason.value = ' No. ';
    reason.dispatchEvent(new Event('input'));
    await t.stable();
    expect(confirm().disabled).toBe(true);
    reason.value = 'The certificate does not show your name.';
    reason.dispatchEvent(new Event('input'));
    await t.stable();
    expect(t.$('[data-decision-count]')!.textContent).toBe('40/500');
    expect(confirm().disabled).toBe(false);
    confirm().click();
    await t.stable();

    expect(t.$$('[data-verification-row]').map((r) => r.getAttribute('data-verification-row'))).toEqual(['vr-omar']);
    const req = http.expectOne({ method: 'POST', url: `${LIST}/vr-salma/reject` });
    expect(req.request.body).toEqual({ reason: 'The certificate does not show your name.' });
    req.flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await t.stable();
    expect(t.$$('[data-verification-row]').map((r) => r.getAttribute('data-verification-row'))).toEqual(['vr-salma', 'vr-omar']);
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'error' })]);
    expect(navigate).toHaveBeenLastCalledWith(['/admin/verification'], { queryParams: { status: null, id: 'vr-salma' }, replaceUrl: true });
  });

  it('decided by another admin first: the tab loads again and says so', async () => {
    const t = await render();
    await t.open('vr-omar');
    t.proof('vr-omar').flush(new Blob(['%PDF-1.4'], { type: 'application/pdf' }));
    await t.stable();
    t.$<HTMLButtonElement>('[data-detail-approve]')!.click();
    await t.stable();
    t.$<HTMLButtonElement>('[data-decision-confirm]')!.click();
    await t.stable();
    http.expectOne(`${LIST}/vr-omar/approve`).flush(problem(409, 'verification.already_decided'), { status: 409, statusText: 'Conflict' });
    await t.stable();
    http.expectOne((r) => r.url === LIST && r.params.get('status') === 'pending').flush({ items: [testAdminRequest()], nextCursor: null });
    await t.stable();
    expect(t.$$('[data-verification-row]').map((r) => r.getAttribute('data-verification-row'))).toEqual(['vr-salma']);
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'error', message: 'تم البتّ في هذا الطلب بالفعل.' })]);
  });

  it('a request that is not on the tab (a deep link) is loaded on its own; decided ones show who decided and why', async () => {
    const decided = testAdminRequest('vr-old', {
      status: 'rejected',
      proof: null,
      decidedAt: '2026-10-25T16:00:00Z',
      decidedBy: { id: 'u-admin', username: 'nour_admin' },
      rejectionReason: 'An Instagram page is not proof of a medical qualification.',
    });
    const t = await render({ id: 'vr-old' });
    expect(t.$('[data-verification-detail-loading]')).not.toBeNull();
    http.expectOne({ method: 'GET', url: `${LIST}/vr-old` }).flush(decided);
    await t.stable();
    const detail = t.$('[data-verification-detail="vr-old"]')!;
    expect(detail.querySelector('[data-detail-actions]')).toBeNull();
    expect(detail.querySelector('[data-detail-remove-badge]')).toBeNull();
    expect(detail.querySelector('[data-detail-decision]')!.textContent).toContain('رفضه ⁨@nour_admin⁩ في 25 أكتوبر 2026');
    expect(detail.querySelector('[data-detail-reason]')!.textContent).toBe('An Instagram page is not proof of a medical qualification.');
    expect(detail.querySelector('[data-detail-no-file]')!.textContent).toContain('يُحذف ملف الإثبات فور البت في الطلب.');

    await t.open('vr-gone');
    http.expectOne(`${LIST}/vr-gone`).flush(problem(404, 'verification.not_found'), { status: 404, statusText: 'Not Found' });
    await t.stable();
    expect(t.$('rd-error-state')!.textContent).toContain('هذا الطلب لم يعد موجودًا.');
  });

  describe('Remove badge (roles change: Verified is a badge, the SuperAdmin can take it away)', () => {
    const BADGE_URL = `${TEST_API}/admin/users/u-karim/verification`;
    const KARIM = { id: 'u-karim', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true };
    const decided = { proof: null, decidedAt: '2026-10-20T11:00:00Z', decidedBy: { id: 'u-admin', username: 'nour_admin' } };
    const APPROVED = testAdminRequest('vr-karim', { status: 'approved', user: KARIM, ...decided });
    /** Approved, but the badge was removed since. */
    const UNVERIFIED = testAdminRequest('vr-mona', { status: 'approved', user: { ...KARIM, id: 'u-mona', displayName: 'Mona Adel', username: 'mona', isVerified: false }, ...decided });

    async function confirmRemoval(t: Awaited<ReturnType<typeof render>>, detail: () => HTMLElement): Promise<TestRequest> {
      detail().querySelector<HTMLButtonElement>('[data-detail-remove-badge]')!.click();
      await t.stable();
      t.$<HTMLButtonElement>('[data-decision-confirm]')!.click();
      await t.stable();
      return http.expectOne({ method: 'DELETE', url: BADGE_URL });
    }

    it('only while the writer has the badge: asked first, gone at once (the request stays approved), then thanked', async () => {
      const t = await render({ status: 'approved', id: 'vr-karim' }, [APPROVED, UNVERIFIED]);
      const detail = () => t.$('[data-verification-detail="vr-karim"]')!;
      expect(detail().getAttribute('data-status')).toBe('approved');
      const button = detail().querySelector<HTMLButtonElement>('[data-detail-remove-badge]')!;
      expect(button.type).toBe('button');
      expect(button.textContent!.trim()).toBe('إزالة التوثيق');
      expect(t.$('[data-verification-row="vr-karim"] svg[aria-label="كاتب موثّق"]')).not.toBeNull();

      button.click();
      await t.stable();
      const sheet = t.$('[data-decision-sheet]')!;
      expect(sheet.getAttribute('data-decision')).toBe('removeBadge');
      expect(sheet.querySelector('#decision-title')!.textContent).toBe('هل تريد إزالة توثيق ⁨Karim Hassan⁩؟');
      expect(sheet.querySelector('#decision-body')!.textContent).toContain('يمكنه طلب التوثيق مرة أخرى');
      expect(t.$('[data-decision-confirm]')!.textContent!.trim()).toBe('إزالة التوثيق');
      expect(t.$('[data-decision-reason]')).toBeNull();
      http.expectNone(BADGE_URL);
      t.$<HTMLButtonElement>('[data-decision-confirm]')!.click();
      await t.stable();

      expect(t.$('[data-decision-sheet]')).toBeNull();
      expect(detail().querySelector('[data-detail-remove-badge]')).toBeNull();
      expect(detail().querySelector('[data-detail-badge-removed]')!.textContent).toContain('لم تعد لديه علامة التوثيق.');
      expect(t.$('[data-verification-row="vr-karim"] svg[aria-label]')).toBeNull();
      // The focus stays in the request, on the decision that now says the badge is gone.
      expect(document.activeElement).toBe(detail().querySelector('[data-detail-decision]'));
      const req = http.expectOne({ method: 'DELETE', url: BADGE_URL });
      expect(req.request.body).toBeNull();
      req.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'success', message: 'لم يعد ⁨Karim Hassan⁩ موثّقًا' })]);
      expect(t.$$('[data-verification-row]').map((r) => r.getAttribute('data-verification-row'))).toEqual(['vr-karim', 'vr-mona']);
      expect(detail().getAttribute('data-status')).toBe('approved');

      // Approved without the badge: nothing to remove, and it says why.
      await t.open('vr-mona');
      const mona = t.$('[data-verification-detail="vr-mona"]')!;
      expect(mona.querySelector('[data-detail-remove-badge]')).toBeNull();
      expect(mona.querySelector('[data-detail-badge-removed]')).not.toBeNull();
    });

    it('cancel sends nothing', async () => {
      const t = await render({ status: 'approved', id: 'vr-karim' }, [APPROVED]);
      t.$<HTMLButtonElement>('[data-detail-remove-badge]')!.click();
      await t.stable();
      [...t.$('[data-decision-sheet]')!.querySelectorAll('button')].find((b) => b.textContent!.trim() === 'إلغاء')!.click();
      await t.stable();
      expect(t.$('[data-decision-sheet]')).toBeNull();
      http.expectNone(BADGE_URL);
      expect(t.$('[data-detail-remove-badge]')).not.toBeNull();
    });

    it('someone removed it first (409 verification.not_verified): it stays gone and the toast says so', async () => {
      const t = await render({ status: 'approved', id: 'vr-karim' }, [APPROVED]);
      const detail = () => t.$('[data-verification-detail="vr-karim"]')!;
      (await confirmRemoval(t, detail)).flush(problem(409, 'verification.not_verified'), { status: 409, statusText: 'Conflict' });
      await t.stable();
      expect(detail().querySelector('[data-detail-remove-badge]')).toBeNull();
      expect(detail().querySelector('[data-detail-badge-removed]')).not.toBeNull();
      expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'error', message: 'هذا المستخدم غير موثّق.' })]);
    });

    it('a request opened by link: the same, and a refusal brings the action back with the error', async () => {
      const t = await render({ id: 'vr-karim' }, [testAdminRequest()]);
      http.expectOne({ method: 'GET', url: `${LIST}/vr-karim` }).flush(APPROVED);
      await t.stable();
      const detail = () => t.$('[data-verification-detail="vr-karim"]')!;
      const req = await confirmRemoval(t, detail);
      expect(detail().querySelector('[data-detail-remove-badge]')).toBeNull();
      req.flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
      await t.stable();
      expect(detail().querySelector('[data-detail-remove-badge]')).not.toBeNull();
      expect(detail().querySelector('[data-detail-badge-removed]')).toBeNull();
      expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'error', message: 'واجه الخادم مشكلة. حاول مرة أخرى بعد قليل.' })]);
    });
  });
});
