import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { TranslocoService } from '@jsverse/transloco';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { GlossaryArticleDto, GlossaryTermDto, UiLanguage } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { OpenTerm, TermSheetService } from './rdoc-context';
import { TermSheet } from './term-sheet';

const FIELD = { id: 'f1', slug: 'software', name: 'Software', nameAr: 'البرمجيات', nameEn: 'Software' };

function glossaryArticle(i: number, patch: Partial<GlossaryArticleDto> = {}): GlossaryArticleDto {
  return { id: `a${i}`, slug: `article-${i}`, language: 'ar-EG', title: `مقال ${i} عن الـ DI`, readingTimeMinutes: i + 2, field: FIELD, ...patch };
}

function term(patch: Partial<GlossaryTermDto> = {}): GlossaryTermDto {
  return {
    slug: 'dependency-injection',
    term: 'Dependency Injection',
    definitionEn: 'A technique where an object receives the objects it depends on.',
    explanationAr: 'إنك تدّي الـ class اللي محتاجه من بره بدل ما يعمله بنفسه.',
    articles: [1, 2, 3, 4, 5, 6].map((i) => glossaryArticle(i)),
    ...patch,
  };
}

const AR_TERM: OpenTerm = { termId: 'dependency-injection', text: 'Dependency Injection', language: 'ar-EG', articleId: 'a2' };
const EN_TERM: OpenTerm = { ...AR_TERM, language: 'en' };

describe('TermSheet (F21 glossary)', () => {
  let http: HttpTestingController;
  const uiLang = signal<UiLanguage>('ar');
  const useEnglishUi = () => {
    uiLang.set('en');
    TestBed.inject(TranslocoService).setActiveLang('en');
  };

  beforeEach(() => {
    TestBed.resetTestingModule();
    uiLang.set('ar');
    ({ http } = setupSocialTesting({ guest: true, providers: [{ provide: LanguageService, useValue: { lang: uiLang } }] }));
  });

  afterEach(() => http.verify());

  function render() {
    const fixture = TestBed.createComponent(TermSheet);
    const root = fixture.nativeElement as HTMLElement;
    const terms = TestBed.inject(TermSheetService);
    // Not `whenStable()`: a lookup still on its way keeps the app unstable.
    const stable = async () => {
      for (let i = 0; i < 3; i++) {
        await flushMicrotasks();
        fixture.detectChanges();
      }
    };
    const open = async (value: OpenTerm) => {
      terms.open(value);
      await stable();
    };
    const sheet = () => root.querySelector<HTMLElement>('[data-term-sheet]');
    return { fixture, root, terms, stable, open, sheet };
  }

  const lookup = (slug = 'dependency-injection') => http.expectOne((r) => r.url === `${TEST_API}/glossary/${slug}`);

  it('looks the term up in the version being read and shows a skeleton meanwhile', async () => {
    const { root, open, sheet } = render();
    await open(AR_TERM);
    const req = lookup();
    expect(req.request.params.get('lang')).toBe('ar-EG');
    expect(sheet()!.getAttribute('data-state')).toBe('loading');
    expect(root.querySelector('[data-term-loading]')!.getAttribute('aria-busy')).toBe('true');
    // The dialog is named by the term; until it is known, by the text that was tapped.
    const dialog = root.querySelector('[role="dialog"]')!;
    expect(dialog.getAttribute('aria-modal')).toBe('true');
    expect(dialog.getAttribute('aria-labelledby')).toBe('term-sheet-title');
    expect(root.querySelector('#term-sheet-title')!.textContent!.trim()).toBe('Dependency Injection');
    req.flush(term());
  });

  it('ar-EG version: the Arabic explanation first, then the English definition; the English term LTR', async () => {
    const { root, open, stable, sheet } = render();
    await open(AR_TERM);
    lookup().flush(term({ term: 'DI (Dependency Injection)' }));
    await stable();

    expect(sheet()!.getAttribute('data-state')).toBe('ready');
    const title = root.querySelector('#term-sheet-title bdi')!;
    expect(title.getAttribute('dir')).toBe('ltr');
    expect(title.textContent).toBe('DI (Dependency Injection)');
    expect(root.querySelector('[data-term-sheet]')!.textContent).toContain('قاموس المصطلحات');

    const explanation = root.querySelector('[data-term-explanation]')!;
    const definition = root.querySelector('[data-term-definition]')!;
    expect(explanation.getAttribute('dir')).toBe('rtl');
    expect(explanation.getAttribute('lang')).toBe('ar-EG');
    // English runs inside the Arabic explanation are isolated (SPEC §14.2 rule 2).
    expect([...explanation.querySelectorAll('bdi')].map((b) => b.textContent)).toEqual(['class']);
    expect(definition.getAttribute('dir')).toBe('ltr');
    expect(definition.textContent!.trim()).toBe('A technique where an object receives the objects it depends on.');
    expect(explanation.compareDocumentPosition(definition) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(definition.parentElement!.textContent).toContain('بالإنجليزية');
  });

  it('en version: the English definition, plus the Arabic explanation only in the Arabic UI', async () => {
    const { root, open, stable, terms } = render();
    await open(EN_TERM);
    lookup().flush(term());
    await stable();
    const definition = root.querySelector('[data-term-definition]')!;
    const explanation = root.querySelector('[data-term-explanation]')!;
    expect(definition.getAttribute('dir')).toBe('ltr');
    expect(definition.compareDocumentPosition(explanation) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(explanation.parentElement!.textContent).toContain('بالعربية');

    terms.close();
    await stable();
    useEnglishUi();
    await open(EN_TERM); // answered from memory
    expect(root.querySelector('[data-term-definition]')).not.toBeNull();
    expect(root.querySelector('[data-term-explanation]')).toBeNull();
  });

  it('lists up to five other articles that use the term and opens one', async () => {
    const { root, open, stable, terms } = render();
    await open(AR_TERM);
    lookup().flush(term({ articles: [glossaryArticle(1), glossaryArticle(2), glossaryArticle(3, { language: 'en', title: 'DI in .NET' }), ...[4, 5, 6, 7].map((i) => glossaryArticle(i))] }));
    await stable();

    const section = root.querySelector('[data-term-articles]')!;
    expect(section.textContent).toContain('مقالات تستخدم هذا المصطلح');
    const rows = [...root.querySelectorAll<HTMLAnchorElement>('[data-term-article]')];
    // a2 is the article being read.
    expect(rows.map((r) => r.getAttribute('href'))).toEqual(['/ar/a/article-1', '/en/a/article-3', '/ar/a/article-4', '/ar/a/article-5', '/ar/a/article-6']);
    const english = rows[1].querySelector('[lang]')!;
    expect(english.getAttribute('dir')).toBe('ltr');
    expect(english.getAttribute('lang')).toBe('en');
    expect(rows[0].querySelector('[lang]')!.getAttribute('dir')).toBe('rtl');
    expect(rows[0].textContent).toContain('البرمجيات');
    expect(rows[0].textContent).toContain('3 دقائق');

    const navigate = vi.spyOn(TestBed.inject(Router), 'navigateByUrl').mockResolvedValue(true);
    rows[1].click();
    await stable();
    expect(navigate.mock.calls[0][0].toString()).toBe('/en/a/article-3');
    expect(terms.openTerm()).toBeNull();
  });

  it('hides the article list when no other article uses the term', async () => {
    const { root, open, stable } = render();
    await open(AR_TERM);
    lookup().flush(term({ articles: [glossaryArticle(2)] }));
    await stable();
    expect(root.querySelector('[data-term-explanation]')).not.toBeNull();
    expect(root.querySelector('[data-term-articles]')).toBeNull();
  });

  it('asks once per session: tapping the same term again answers from memory', async () => {
    const { root, open, stable, terms } = render();
    await open(AR_TERM);
    lookup().flush(term());
    await stable();
    terms.close();
    await stable();

    await open(AR_TERM);
    http.expectNone((r) => r.url.includes('/glossary/'));
    expect(root.querySelector('[data-term-sheet]')!.getAttribute('data-state')).toBe('ready');

    // Another version asks again: its article titles differ.
    terms.close();
    await stable();
    await open(EN_TERM);
    expect(lookup().request.params.get('lang')).toBe('en');
  });

  it("says when the term isn't in the glossary yet, titled by the tapped text, and remembers it", async () => {
    const { root, open, stable, terms } = render();
    await open({ ...AR_TERM, termId: 'zygote', text: 'الـ zygote' });
    lookup('zygote').flush(problem(404, 'glossary.term_not_found'), { status: 404, statusText: 'Not Found' });
    await stable();

    expect(root.querySelector('[data-term-sheet]')!.getAttribute('data-state')).toBe('missing');
    expect(root.querySelector('#term-sheet-title')!.textContent!.trim()).toBe('الـ zygote');
    expect(root.querySelector('[data-term-missing]')!.textContent).toContain('لم يُضف هذا المصطلح إلى القاموس بعد');

    terms.close();
    await stable();
    await open({ ...AR_TERM, termId: 'zygote', text: 'الـ zygote' });
    http.expectNone((r) => r.url.includes('/glossary/'));
    expect(root.querySelector('[data-term-missing]')).not.toBeNull();
  });

  it('shows a network error with a retry that asks again', async () => {
    const { root, open, stable } = render();
    await open(AR_TERM);
    lookup().error(new ProgressEvent('error'));
    await stable();
    expect(root.querySelector('[data-term-sheet]')!.getAttribute('data-state')).toBe('error');
    expect(root.querySelector('rd-error-state')!.textContent).toContain('تعذّر تحميل التعريف.');

    (root.querySelector('rd-error-state button') as HTMLButtonElement).click();
    await stable();
    lookup().flush(term());
    await stable();
    expect(root.querySelector('[data-term-sheet]')!.getAttribute('data-state')).toBe('ready');
  });

  it('closes on Escape and gives focus back to the term', async () => {
    const { root, open, stable, terms } = render();
    const button = document.createElement('button');
    button.textContent = 'Dependency Injection';
    document.body.appendChild(button);
    button.focus();

    await open(AR_TERM);
    lookup().flush(term());
    await stable();
    const dialog = root.querySelector<HTMLElement>('[role="dialog"]')!;
    expect(dialog.contains(document.activeElement)).toBe(true);

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await stable();
    expect(terms.openTerm()).toBeNull();
    expect(root.querySelector('[role="dialog"]')).toBeNull();
    expect(document.activeElement).toBe(button);
    button.remove();
  });

  it('closes when the page changes', async () => {
    const { open, stable, terms } = render();
    await open(AR_TERM);
    lookup().flush(term());
    await stable();
    await TestBed.inject(Router).navigateByUrl('/');
    await stable();
    expect(terms.openTerm()).toBeNull();
  });

  it('translates its labels in English', async () => {
    useEnglishUi();
    expect(TestBed.inject(TranslocoService).translate('rdoc.term.missing')).toBe("This term isn't in the glossary yet");
    const { root, open, stable } = render();
    await open(AR_TERM);
    lookup().flush(term());
    await stable();
    expect(root.querySelector('[data-term-sheet]')!.textContent).toContain('Glossary');
    expect(root.querySelector('[data-term-sheet]')!.textContent).toContain('In English');
    expect(root.querySelector('[data-term-articles]')!.textContent).toContain('Articles that use this term');
  });
});
