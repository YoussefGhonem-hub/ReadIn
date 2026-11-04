import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { testVerificationRequest, testVerificationStatus } from '../../../testing/verification-testing';
import { FieldDto, VerificationStatusDto } from '../../core/api/models';
import { AuthService } from '../../core/auth/auth.service';
import { SessionStore } from '../../core/auth/session.store';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { VerificationPage } from './verification.page';

const STATUS = `${TEST_API}/me/verification`;
const SUBMIT = `${TEST_API}/verification-requests`;
const FIELDS = `${TEST_API}/fields`;

const FIELD_LIST: FieldDto[] = [
  { id: 'f-software', slug: 'software', name: 'البرمجيات', nameAr: 'البرمجيات', nameEn: 'Software', icon: 'code', color: 'primary', isSensitive: false, requiresSources: false, topicCount: 2 },
  { id: 'f-medicine', slug: 'medicine', name: 'الطب', nameAr: 'الطب', nameEn: 'Medicine', icon: 'stethoscope', color: 'primary', isSensitive: true, requiresSources: true, topicCount: 0 },
];

const status = testVerificationStatus;
const testRequest = testVerificationRequest;

describe('VerificationPage (F19)', () => {
  let http: HttpTestingController;
  const auth = { refreshMe: vi.fn(async () => null) };

  beforeEach(() => {
    TestBed.resetTestingModule();
    auth.refreshMe.mockClear();
    ({ http } = setupSocialTesting({ providers: [{ provide: AuthService, useValue: auth }] }));
  });

  afterEach(() => http.verify());

  async function render(loaded: VerificationStatusDto | 'error' = status()) {
    const fixture = TestBed.createComponent(VerificationPage);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await flushMicrotasks();
      fixture.detectChanges();
    };
    expect(root.querySelector('[data-verification-loading]')).not.toBeNull();
    const first = http.expectOne({ method: 'GET', url: STATUS });
    if (loaded === 'error') first.flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    else first.flush(loaded);
    await stable();
    const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
    const answerFields = async () => {
      for (const req of http.match(FIELDS)) req.flush(FIELD_LIST);
      await stable();
    };
    return { fixture, root, stable, $, answerFields };
  }

  function type(input: HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement, value: string, event = 'input'): void {
    input.value = value;
    input.dispatchEvent(new Event(event));
  }

  function pick(input: HTMLInputElement, file: File): void {
    Object.defineProperty(input, 'files', { value: [file], configurable: true });
    input.dispatchEvent(new Event('change'));
  }

  it('shows an error with a retry when the status cannot be read', async () => {
    const t = await render('error');
    expect(t.$('rd-error-state')!.textContent).toContain('معرفناش نجيب حالة التوثيق بتاعتك.');
    t.$<HTMLButtonElement>('rd-error-state button')!.click();
    http.expectOne(STATUS).flush(status({ isVerified: true, canRequest: false }));
    await t.stable();
    expect(t.$('[data-verification-status="verified"]')).not.toBeNull();
  });

  it('nothing yet: the form checks everything before sending, then sends it as multipart and shows it under review', async () => {
    const t = await render();
    await t.answerFields();
    expect(t.$('[data-verification-form]')!.textContent).toContain('اطلب التوثيق');
    const options = [...t.$<HTMLSelectElement>('[data-verification-field]')!.options].map((o) => o.textContent!.trim());
    expect(options).toEqual(['اختار مجالك', 'البرمجيات', 'الطب']);

    // Nothing is shown until the first try; then every problem, and focus on the first.
    expect(t.root.querySelectorAll('[data-error]:not(:empty)').length).toBe(0);
    t.$<HTMLButtonElement>('[data-verification-submit]')!.click();
    await t.stable();
    expect(t.$('[data-error="fieldId"]')!.textContent).toBe('اختار مجالك.');
    expect(t.$('[data-error="jobTitle"]')!.textContent).toBe('اكتب مسمى وظيفي من 2 لـ 100 حرف.');
    expect(t.$('[data-error="proof"]')!.textContent).toBe('ضيف لينك أو ملف كإثبات.');
    expect(t.$('[data-verification-field]')!.getAttribute('aria-invalid')).toBe('true');
    expect(document.activeElement).toBe(t.$('[data-verification-field]'));
    http.expectNone(SUBMIT);

    // Errors follow the inputs once shown.
    type(t.$<HTMLSelectElement>('[data-verification-field]')!, 'f-medicine', 'change');
    type(t.$<HTMLInputElement>('[data-verification-job-title]')!, '  طبيب امتياز  ');
    type(t.$<HTMLInputElement>('[data-verification-proof-url]')!, 'http://example.com');
    await t.stable();
    expect(t.$('[data-error="fieldId"]')).toBeNull();
    expect(t.$('[data-error="proofUrl"]')!.textContent).toBe('اكتب لينك كامل بيبدأ بـ https:// (لحد 500 حرف).');

    // A file of the wrong type or size never gets in.
    const fileInput = t.$<HTMLInputElement>('[data-verification-file-input]')!;
    expect(fileInput.accept).toBe('application/pdf,image/jpeg,image/png,image/webp,.pdf,.jpg,.jpeg,.png,.webp');
    pick(fileInput, new File(['gif'], 'card.gif', { type: 'image/gif' }));
    await t.stable();
    expect(t.$('[data-verification-file]')).toBeNull();
    expect(t.$('[data-error="proof"]')!.textContent).toBe('اختار ملف PDF أو JPEG أو PNG أو WebP.');
    const big = new File(['x'], 'card.pdf', { type: 'application/pdf' });
    Object.defineProperty(big, 'size', { value: 10 * 1024 * 1024 + 1 });
    pick(fileInput, big);
    await t.stable();
    expect(t.$('[data-error="proof"]')!.textContent).toBe('الملف أكبر من 10 ميجا.');

    const card = new File(['%PDF-1.4'], 'كارنيه النقابة.pdf', { type: 'application/pdf' });
    pick(fileInput, card);
    type(t.$<HTMLInputElement>('[data-verification-proof-url]')!, '');
    type(t.$<HTMLTextAreaElement>('[data-verification-note]')!, ' رقم القيد 12345 ');
    await t.stable();
    expect(t.$('[data-verification-file-name]')!.textContent).toBe('كارنيه النقابة.pdf');
    expect(t.$('[data-error="proof"]')).toBeNull();
    expect(t.root.textContent).toContain('17/500');

    t.$<HTMLButtonElement>('[data-verification-submit]')!.click();
    await t.stable();
    expect(t.$<HTMLButtonElement>('[data-verification-submit]')!.disabled).toBe(true);
    const sent = http.expectOne({ method: 'POST', url: SUBMIT });
    const body = sent.request.body as FormData;
    expect(body).toBeInstanceOf(FormData);
    expect(body.get('fieldId')).toBe('f-medicine');
    expect(body.get('jobTitle')).toBe('طبيب امتياز');
    expect(body.get('proofUrl')).toBeNull();
    expect(body.get('note')).toBe('رقم القيد 12345');
    expect((body.get('proof') as File).name).toBe('كارنيه النقابة.pdf');
    sent.flush(testRequest({ field: { id: 'f-medicine', slug: 'medicine', name: 'الطب' }, jobTitle: 'طبيب امتياز', proofUrl: null, note: 'رقم القيد 12345' }), {
      status: 201,
      statusText: 'Created',
    });
    await t.stable();

    expect(t.$('[data-verification-status="pending"]')).not.toBeNull();
    expect(t.$('[data-verification-submitted]')!.textContent).toContain('اتبعت يوم 2 نوفمبر 2026');
    expect(t.$('[data-summary-proof-file]')!.textContent).toBe('كارنيه النقابة.pdf');
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'success', message: 'اتبعت الطلب ✓' })]);
  });

  it("the API's refusals land on their inputs and stay until the input changes", async () => {
    const t = await render();
    await t.answerFields();
    type(t.$<HTMLSelectElement>('[data-verification-field]')!, 'f-software', 'change');
    type(t.$<HTMLInputElement>('[data-verification-job-title]')!, 'Backend engineer');
    pick(t.$<HTMLInputElement>('[data-verification-file-input]')!, new File(['not really a png'], 'card.png', { type: 'image/png' }));
    await t.stable();
    const submit = () => t.$<HTMLButtonElement>('[data-verification-submit]')!.click();

    submit();
    await t.stable();
    http.expectOne(SUBMIT).flush(problem(400, 'verification.proof_invalid'), { status: 400, statusText: 'Bad Request' });
    await t.stable();
    expect(t.$('[data-error="proof"]')!.textContent).toBe('ملف الإثبات لازم يكون PDF أو JPEG أو PNG أو WebP، ومايزيدش عن 10 ميجا.');
    t.$<HTMLButtonElement>('[data-verification-file-remove]')!.click();
    type(t.$<HTMLInputElement>('[data-verification-proof-url]')!, 'https://github.com/mona');
    await t.stable();
    expect(t.$('[data-error="proof"]')).toBeNull();

    submit();
    await t.stable();
    http.expectOne(SUBMIT).flush(problem(400, 'validation.failed', { JobTitle: ['validation.length'] }), { status: 400, statusText: 'Bad Request' });
    await t.stable();
    expect(t.$('[data-error="jobTitle"]')!.textContent).toBe('اكتب مسمى وظيفي من 2 لـ 100 حرف.');
    type(t.$<HTMLInputElement>('[data-verification-job-title]')!, 'Backend engineer at X');
    await t.stable();
    expect(t.$('[data-error="jobTitle"]')).toBeNull();

    // Anything else: one message for the form.
    submit();
    await t.stable();
    http.expectOne(SUBMIT).flush(problem(429, 'rate_limited'), { status: 429, statusText: 'Too Many Requests' });
    await t.stable();
    expect(t.$('[data-verification-form-error]')!.textContent).toBeTruthy();

    // Sent from another device meanwhile: where things stand now.
    submit();
    await t.stable();
    http.expectOne(SUBMIT).flush(problem(409, 'verification.already_pending'), { status: 409, statusText: 'Conflict' });
    await t.stable();
    expect(TestBed.inject(ToastService).toasts().at(-1)).toMatchObject({ kind: 'info', message: 'عندك طلب لسه بيتراجع.' });
    http.expectOne(STATUS).flush(status({ canRequest: false, request: testRequest() }));
    await t.stable();
    expect(t.$('[data-verification-status="pending"]')).not.toBeNull();
  });

  it('under review: what was sent; withdrawing asks first, shows the form at once and puts it back when refused', async () => {
    const t = await render(status({ canRequest: false, request: testRequest({ note: 'رقم القيد 12345' }) }));
    const card = t.$('[data-verification-status="pending"]')!;
    expect(card.textContent).toContain('طلبك بيتراجع');
    // Short values sit next to their label in the page direction; the text itself is isolated in its own direction.
    expect(t.$('[data-summary-job-title]')!.getAttribute('dir')).toBeNull();
    expect(t.$('[data-summary-job-title] rd-bdi-text')!.getAttribute('dir')).toBe('ltr');
    expect(t.$('[data-summary-proof-url]')!.textContent).toBe('https://www.linkedin.com/in/mona');
    expect(t.$('[data-summary-proof-url]')!.getAttribute('dir')).toBe('ltr');
    expect(card.textContent).toContain('رقم القيد 12345');

    t.$<HTMLButtonElement>('[data-verification-withdraw]')!.click();
    await t.stable();
    expect(t.$('[data-withdraw-sheet]')!.textContent).toContain('تسحب طلبك؟');
    http.expectNone({ method: 'DELETE', url: STATUS });
    t.$<HTMLButtonElement>('[data-withdraw-confirm]')!.click();
    await t.stable();
    expect(t.$('[data-verification-form]')).not.toBeNull();
    await t.answerFields();
    http.expectOne({ method: 'DELETE', url: STATUS }).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await t.stable();
    expect(t.$('[data-verification-status="pending"]')).not.toBeNull();
    expect(TestBed.inject(ToastService).toasts().at(-1)).toMatchObject({ kind: 'error' });

    t.$<HTMLButtonElement>('[data-verification-withdraw]')!.click();
    await t.stable();
    t.$<HTMLButtonElement>('[data-withdraw-confirm]')!.click();
    await t.stable();
    await t.answerFields();
    http.expectOne({ method: 'DELETE', url: STATUS }).flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.$('[data-verification-form]')).not.toBeNull();
    expect(TestBed.inject(ToastService).toasts().at(-1)).toMatchObject({ kind: 'success', message: 'اتسحب الطلب' });
  });

  it('not approved: the reason in its own direction, and "Request again" starts from the rejected request', async () => {
    const reason = 'The certificate does not show your name.';
    const t = await render(status({ request: testRequest({ status: 'rejected', decidedAt: '2026-11-03T12:00:00Z', rejectionReason: reason, proofFileName: null }) }));
    expect(t.$('[data-verification-status="rejected"]')!.textContent).toContain('طلبك ماتقبلش');
    expect(t.$('[data-verification-reason]')!.textContent).toBe(reason);
    expect(t.$('[data-verification-reason]')!.getAttribute('dir')).toBe('ltr');

    t.$<HTMLButtonElement>('[data-verification-again]')!.click();
    await t.stable();
    await t.answerFields();
    expect(t.$('[data-verification-form]')!.textContent).toContain('ابعت طلب جديد');
    expect(t.$<HTMLSelectElement>('[data-verification-field]')!.value).toBe('f-software');
    expect(t.$<HTMLInputElement>('[data-verification-job-title]')!.value).toBe('Backend engineer في Vodafone');
    expect(t.$<HTMLInputElement>('[data-verification-proof-url]')!.value).toBe('https://www.linkedin.com/in/mona');

    t.$<HTMLButtonElement>('[data-verification-cancel]')!.click();
    await t.stable();
    expect(t.$('[data-verification-status="rejected"]')).not.toBeNull();
  });

  it('verified: says so, and reads `me` again when the session does not know it yet (the badge)', async () => {
    const t = await render(status({ isVerified: true, canRequest: false, request: testRequest({ status: 'approved', decidedAt: '2026-11-03T12:00:00Z', proofFileName: null }) }));
    expect(t.$('[data-verification-status="verified"]')!.textContent).toContain('إنت كاتب موثّق ✓');
    expect(t.$('[data-verification-status="verified"]')!.textContent).toContain('اتقبل يوم 3 نوفمبر 2026');
    expect(auth.refreshMe).toHaveBeenCalledTimes(1);
  });

  it('verified and already known: no extra call', async () => {
    TestBed.inject(SessionStore).setMe(testMe({ isVerified: true }));
    await render(status({ isVerified: true, canRequest: false }));
    expect(auth.refreshMe).not.toHaveBeenCalled();
  });

  it("can't ask now (e.g. suspended): says so, no form", async () => {
    const t = await render(status({ canRequest: false }));
    expect(t.$('[data-verification-status="unavailable"]')!.textContent).toContain('مش هتقدر تطلب التوثيق دلوقتي');
    expect(t.$('[data-verification-form]')).toBeNull();
  });

  it('reads in English too', async () => {
    TestBed.inject(TranslocoService).setActiveLang('en');
    const t = await render(status({ canRequest: false, request: testRequest() }));
    expect(t.$('[data-verification-status="pending"]')!.textContent).toContain('Your request is under review');
    expect(t.$('[data-verification-withdraw]')!.textContent!.trim()).toBe('Withdraw request');
  });
});

