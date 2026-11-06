import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { ArticleLanguage } from '../../core/api/models';
import { PdfDownload } from './pdf-download';

@Component({
  imports: [PdfDownload],
  template: `<div class="flex"><rd-pdf-download [articleId]="id()" [languages]="languages()" /></div>`,
})
class Host {
  readonly id = signal('a1');
  readonly languages = signal<readonly ArticleLanguage[]>(['en']);
}

describe('PdfDownload (F33)', () => {
  let http: HttpTestingController;
  let clicks: string[];

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
    clicks = [];
    URL.createObjectURL = vi.fn(() => 'blob:http://localhost/pdf');
    URL.revokeObjectURL = vi.fn();
    vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function (this: HTMLAnchorElement) {
      clicks.push(this.download);
    });
  });

  afterEach(() => {
    http.verify();
    vi.restoreAllMocks();
  });

  function render(languages: readonly ArticleLanguage[]) {
    const fixture = TestBed.createComponent(Host);
    fixture.componentInstance.languages.set(languages);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const button = () => root.querySelector<HTMLButtonElement>('[data-pdf-download]')!;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
    };
    return { fixture, root, button, stable };
  }

  const pdfRequests = () => http.match((r) => r.url === `${TEST_API}/articles/a1/pdf`);

  it('one language: downloads it at once; "بنجهز الـ PDF…", disabled, while it is built', async () => {
    const t = render(['en']);
    expect(t.button().textContent?.trim()).toBe('تنزيل PDF');
    expect(t.button().getAttribute('aria-disabled')).toBeNull();
    expect(t.button().getAttribute('data-state')).toBe('idle');

    t.button().click();
    t.fixture.detectChanges();
    const [req] = pdfRequests();
    expect(req.request.params.get('lang')).toBe('en');
    expect(t.root.querySelector('[data-pdf-languages]')).toBeNull(); // no question
    expect(t.button().textContent?.trim()).toBe('جارٍ تجهيز ملف PDF…');
    expect(t.button().getAttribute('aria-disabled')).toBe('true');
    expect(t.button().getAttribute('data-state')).toBe('building');
    expect(t.button().querySelector('svg.animate-spin')).not.toBeNull();
    expect(t.root.querySelector('[role="status"]')?.textContent?.trim()).toBe('جارٍ تجهيز ملف PDF…');

    // A second press does nothing.
    t.button().click();
    t.fixture.detectChanges();
    expect(pdfRequests()).toEqual([]);

    req.flush(new Blob(['%PDF']), { headers: { 'Content-Disposition': "attachment; filename*=UTF-8''clean-code-en.pdf" } });
    await t.stable();
    expect(clicks).toEqual(['clean-code-en.pdf']);
    expect(t.button().textContent?.trim()).toBe('تنزيل PDF');
    expect(t.button().getAttribute('aria-disabled')).toBeNull();
  });

  it('two languages: asks "أنهي نسخة؟" with both, source first, then downloads the one picked', async () => {
    const t = render(['ar-EG', 'en']);
    t.button().click();
    t.fixture.detectChanges();
    expect(pdfRequests()).toEqual([]);
    const sheet = t.root.querySelector<HTMLElement>('[data-pdf-languages]')!;
    expect(sheet).not.toBeNull();
    const dialog = sheet.closest('section')!;
    expect(dialog.getAttribute('role')).toBe('dialog');
    expect(document.getElementById(dialog.getAttribute('aria-labelledby')!)?.textContent?.trim()).toBe('أي نسخة تريد؟');
    const options = [...sheet.querySelectorAll<HTMLButtonElement>('[data-pdf-language]')];
    expect(options.map((o) => [o.dataset['pdfLanguage'], o.textContent?.trim()])).toEqual([
      ['ar-EG', 'العربية'],
      ['en', 'الإنجليزية'],
    ]);
    expect(options[0].hasAttribute('data-initial-focus')).toBe(true);

    options[1].click();
    t.fixture.detectChanges();
    expect(t.root.querySelector('[data-pdf-languages]')).toBeNull();
    const [req] = pdfRequests();
    expect(req.request.params.get('lang')).toBe('en');
    expect(t.button().getAttribute('data-state')).toBe('building');
    req.flush(new Blob(['%PDF']));
    await t.stable();
    expect(clicks).toEqual(['readin-article.pdf']);
  });

  it('closing the question downloads nothing', () => {
    const t = render(['ar-EG', 'en']);
    t.button().click();
    t.fixture.detectChanges();
    t.root.querySelector<HTMLButtonElement>('rd-bottom-sheet button[aria-label]')!.click();
    t.fixture.detectChanges();
    expect(t.root.querySelector('[data-pdf-languages]')).toBeNull();
    expect(pdfRequests()).toEqual([]);
  });

  it('labels the versions in English in the English UI', () => {
    TestBed.inject(TranslocoService).setActiveLang('en');
    const t = render(['en', 'ar-EG']);
    expect(t.button().textContent?.trim()).toBe('Download PDF');
    t.button().click();
    t.fixture.detectChanges();
    expect([...t.root.querySelectorAll('[data-pdf-language]')].map((o) => o.textContent?.trim())).toEqual(['English', 'Arabic']);
  });
});
