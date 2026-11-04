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
    expect(t.$$('[data-verification-tab]').map((tab) => tab.textContent!.trim())).toEqual(['مستنية', 'اتقبلت', 'اترفضت']);
    expect(t.$('[data-verification-tab="approved"]')!.getAttribute('href')).toBe('/admin/verification?status=approved');
    expect(t.$('[data-verification-tab="pending"]')!.getAttribute('href')).toBe('/admin/verification');

    const rows = t.$$('[data-verification-row]');
    expect(rows.map((r) => r.getAttribute('data-verification-row'))).toEqual(['vr-salma', 'vr-omar']);
    expect(rows[0].getAttribute('href')).toBe('/admin/verification?id=vr-salma');
    expect(rows[0].textContent).toContain('سلمى إبراهيم');
    expect(rows[0].textContent).toContain('@salma');
    expect(rows[0].querySelector('[data-row-field]')!.textContent!.trim()).toBe('البرمجيات');
    expect(rows[0].querySelector('[data-row-job-title]')!.getAttribute('dir')).toBe('ltr');
    expect(rows[0].querySelector('[data-row-time]')!.textContent).toContain('اتبعت');
    expect(t.$('[data-verification-pick]')!.textContent).toContain('اختار طلب عشان تراجعه.');
  });

  it('a tab without requests says so; a failed list can be retried', async () => {
    const t = await render({ status: 'rejected' }, []);
    expect(t.$('[data-verification-empty]')!.textContent).toContain('مفيش طلبات اترفضت');

    t.fixture.componentRef.setInput('status', 'approved');
    await t.stable();
    http.expectOne((r) => r.url === LIST && r.params.get('status') === 'approved').flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await t.stable();
    expect(t.$('rd-error-state')!.textContent).toContain('معرفناش نجيب الطلبات.');
    t.$<HTMLButtonElement>('rd-error-state button')!.click();
    http.expectOne((r) => r.url === LIST && r.params.get('status') === 'approved').flush({ items: [], nextCursor: null });
    await t.stable();
    expect(t.$('[data-verification-empty]')!.textContent).toContain('لسه مفيش طلبات اتقبلت');
  });

  it('a request: the job title, note and proof link (new tab, no referrer); the image proof fetched with the session and shown inline', async () => {
    const t = await render();
    await t.open('vr-salma');
    const detail = t.$('[data-verification-detail="vr-salma"]')!;
    expect(t.$('[data-verification-row="vr-salma"]')!.getAttribute('aria-current')).toBe('true');
    expect(detail.querySelector('[data-detail-status]')!.textContent!.trim()).toBe('مستني');
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
    expect(pdf.querySelector('[data-proof-open]')!.textContent).toContain('افتح الـ PDF');
    expect(pdf.querySelector('[data-proof-name]')!.textContent).toBe('syndicate-card.pdf');
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
    expect(t.$('[data-proof-gone]')!.textContent).toContain('الملف مبقاش موجود.');

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
    expect(sheet.textContent).toContain('توافق على ⁨سلمى إبراهيم⁩؟');
    http.expectNone(`${LIST}/vr-salma/approve`);
    t.$<HTMLButtonElement>('[data-decision-confirm]')!.click();
    await t.stable();

    expect(t.$('[data-decision-sheet]')).toBeNull();
    expect(t.$$('[data-verification-row]').map((r) => r.getAttribute('data-verification-row'))).toEqual(['vr-omar']);
    expect(t.$('[data-verification-detail]')).toBeNull();
    expect(navigate).toHaveBeenCalledWith(['/admin/verification'], { queryParams: { status: null }, replaceUrl: true });
    http.expectOne({ method: 'POST', url: `${LIST}/vr-salma/approve` }).flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'success', message: '⁨سلمى إبراهيم⁩ بقى كاتب موثّق ✓' })]);
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
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'error', message: 'الطلب ده اتاخد فيه قرار خلاص.' })]);
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
    expect(detail.querySelector('[data-detail-decision]')!.textContent).toContain('رفضه ⁨@nour_admin⁩ يوم 25 أكتوبر 2026');
    expect(detail.querySelector('[data-detail-reason]')!.textContent).toBe('An Instagram page is not proof of a medical qualification.');
    expect(detail.querySelector('[data-detail-no-file]')!.textContent).toContain('ملف الإثبات بيتمسح أول ما الطلب يتاخد فيه قرار.');

    await t.open('vr-gone');
    http.expectOne(`${LIST}/vr-gone`).flush(problem(404, 'verification.not_found'), { status: 404, statusText: 'Not Found' });
    await t.stable();
    expect(t.$('rd-error-state')!.textContent).toContain('الطلب ده مبقاش موجود.');
  });
});
