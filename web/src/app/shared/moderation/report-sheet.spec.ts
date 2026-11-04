import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { ToastService } from '../ui/toast/toast.service';
import { REPORT_DETAILS_MAX_LENGTH, ReportSheet, ReportTarget } from './report-sheet';

@Component({
  imports: [ReportSheet],
  template: `<rd-report-sheet [target]="target()" (closed)="onClosed()" (reported)="reported.push($event)" />`,
})
class Host {
  readonly target = signal<ReportTarget | null>(null);
  readonly reported: ReportTarget[] = [];
  closedCount = 0;
  onClosed(): void {
    this.closedCount++;
    this.target.set(null);
  }
}

async function render(options: { guest?: boolean } = {}) {
  const { http, toasts } = setupSocialTesting(options);
  const fixture = TestBed.createComponent(Host);
  fixture.detectChanges();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  const open = async (target: ReportTarget) => {
    fixture.componentInstance.target.set(target);
    await stable();
  };
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  return { fixture, root, http, toasts, stable, open, $, host: fixture.componentInstance };
}

function type(field: HTMLTextAreaElement, value: string): void {
  field.value = value;
  field.dispatchEvent(new Event('input'));
}

describe('ReportSheet (F22)', () => {
  let http: HttpTestingController;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http.verify());

  it('titles and asks per target: article, comment, user', async () => {
    const t = await render();
    http = t.http;
    const expected: [ReportTarget['type'], string, string][] = [
      ['article', 'الإبلاغ عن المقال', 'إيه المشكلة في المقال ده؟'],
      ['comment', 'الإبلاغ عن التعليق', 'إيه المشكلة في التعليق ده؟'],
      ['user', 'الإبلاغ عن المستخدم', 'إيه المشكلة في الحساب ده؟'],
    ];
    for (const [kind, title, body] of expected) {
      await t.open({ type: kind, id: `${kind}-1` });
      expect(t.$('[data-report-sheet]')!.getAttribute('data-report-target')).toBe(kind);
      expect(t.$('#report-sheet-title')!.textContent!.trim()).toBe(title);
      expect(t.$('legend')!.textContent!.trim()).toBe(body);
      expect([...t.root.querySelectorAll('[data-reason]')].map((r) => r.getAttribute('data-reason'))).toEqual([
        'spam',
        'misinformation',
        'harassment',
        'copyright',
        'other',
      ]);
      t.host.target.set(null);
      await t.stable();
      expect(t.$('[data-report-sheet]')).toBeNull();
    }
  });

  it('needs a reason; sends it with the trimmed details, thanks you and closes', async () => {
    const t = await render();
    http = t.http;
    await t.open({ type: 'article', id: 'a1' });
    const submit = t.$<HTMLButtonElement>('[data-report-submit]')!;
    expect(submit.disabled).toBe(true);

    t.$<HTMLInputElement>('[data-reason="misinformation"]')!.click();
    type(t.$<HTMLTextAreaElement>('[data-report-details]')!, '  The numbers are from 2009.  ');
    await t.stable();
    expect(t.$('[data-report-count]')!.textContent!.trim()).toBe(`30/${REPORT_DETAILS_MAX_LENGTH}`);
    expect(t.$('[data-report-details]')!.getAttribute('maxlength')).toBe('500');
    expect(submit.disabled).toBe(false);

    submit.click();
    await t.stable();
    expect(submit.disabled).toBe(true); // busy
    const req = t.http.expectOne(`${TEST_API}/reports`);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({ targetType: 'article', targetId: 'a1', reason: 'misinformation', details: 'The numbers are from 2009.' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();

    expect(t.$('[data-report-sheet]')).toBeNull();
    expect(t.host.reported).toEqual([{ type: 'article', id: 'a1' }]);
    expect(t.host.closedCount).toBe(1);
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['شكرًا، هنراجع البلاغ']);
  });

  it('leaves out empty details', async () => {
    const t = await render();
    http = t.http;
    await t.open({ type: 'user', id: 'writer-1' });
    t.$<HTMLInputElement>('[data-reason="harassment"]')!.click();
    type(t.$<HTMLTextAreaElement>('[data-report-details]')!, '   ');
    await t.stable();
    t.$('[data-report-submit]')!.click();
    const req = t.http.expectOne(`${TEST_API}/reports`);
    expect(req.request.body).toEqual({ targetType: 'user', targetId: 'writer-1', reason: 'harassment' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
  });

  it('stays open with the translated error: your own content, a gone target, a validation code', async () => {
    const t = await render();
    http = t.http;
    await t.open({ type: 'comment', id: 'c1' });
    t.$<HTMLInputElement>('[data-reason="spam"]')!.click();
    await t.stable();

    t.$('[data-report-submit]')!.click();
    t.http.expectOne(`${TEST_API}/reports`).flush(problem(400, 'report.own_content'), { status: 400, statusText: 'Bad Request' });
    await t.stable();
    expect(t.$('[data-report-sheet]')).not.toBeNull();
    expect(t.$('[data-report-error]')!.textContent!.trim()).toBe('مينفعش تبلّغ عن حاجة إنت كاتبها.');

    t.$('[data-report-submit]')!.click();
    t.http.expectOne(`${TEST_API}/reports`).flush(problem(404, 'report.target_not_found'), { status: 404, statusText: 'Not Found' });
    await t.stable();
    expect(t.$('[data-report-error]')!.textContent!.trim()).toBe('المحتوى ده مش موجود.');

    t.$('[data-report-submit]')!.click();
    t.http
      .expectOne(`${TEST_API}/reports`)
      .flush(problem(400, 'validation.failed', { reason: ['report.reason_invalid'] }), { status: 400, statusText: 'Bad Request' });
    await t.stable();
    expect(t.$('[data-report-error]')!.textContent!.trim()).toBe('اختار سبب البلاغ.');
    expect(t.toasts.toasts()).toEqual([]);

    // Picking another reason clears the error.
    t.$<HTMLInputElement>('[data-reason="other"]')!.click();
    await t.stable();
    expect(t.$('[data-report-error]')).toBeNull();
  });

  it('cancel closes without a request', async () => {
    const t = await render();
    http = t.http;
    await t.open({ type: 'article', id: 'a1' });
    (t.root.querySelector('[data-report-sheet] .rd-btn-outline') as HTMLElement).click();
    await t.stable();
    expect(t.$('[data-report-sheet]')).toBeNull();
    expect(t.host.closedCount).toBe(1);
  });

  it('guests get the sign-in prompt instead of the form', async () => {
    const t = await render({ guest: true });
    http = t.http;
    await t.open({ type: 'article', id: 'a1' });
    expect(t.$('[data-report-sheet]')).toBeNull();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
    expect(t.host.closedCount).toBe(1);
    expect(TestBed.inject(ToastService).toasts()).toEqual([]);
  });
});
