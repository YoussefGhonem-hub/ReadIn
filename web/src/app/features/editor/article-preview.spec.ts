import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { TranslocoService } from '@jsverse/transloco';
import { TEST_EDITOR_FIELDS } from '../../../testing/editor-testing';
import { translocoTesting } from '../../../testing/transloco-testing';
import { FieldDto } from '../../core/api/models';
import { provideAppIcons } from '../../shared/ui/icons';
import { ArticlePreview } from './article-preview';
import { emptyDocument } from './editor.store';

describe('ArticlePreview health disclaimer (F05, SPEC F04)', () => {
  beforeEach(() => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ imports: [translocoTesting()], providers: [provideRouter([]), provideAppIcons()] });
  });

  function render(field: FieldDto | null, lang: 'ar' | 'en' = 'ar') {
    TestBed.inject(TranslocoService).setActiveLang(lang);
    const fixture = TestBed.createComponent(ArticlePreview);
    const document = { ...emptyDocument('ar-EG'), fieldId: field?.id ?? null };
    document.translations = document.translations.map((t) => ({ ...t, title: 'النوم والذاكرة' }));
    fixture.componentRef.setInput('document', document);
    fixture.componentRef.setInput('language', 'ar-EG');
    fixture.componentRef.setInput('field', field);
    fixture.componentRef.setInput('author', { displayName: 'Omar Fathy', username: 'omar_dev', avatarUrl: null, isVerified: false });
    fixture.componentRef.setInput('uiLang', lang);
    fixture.detectChanges();
    return fixture.nativeElement as HTMLElement;
  }

  it('shows the disclaimer once the chosen field is sensitive, as the reader will', () => {
    const [software, medicine] = TEST_EDITOR_FIELDS;
    expect(render(software).querySelector('[data-health-disclaimer]')).toBeNull();
    expect(render(null).querySelector('[data-health-disclaimer]')).toBeNull();

    const root = render(medicine);
    const notice = root.querySelector('[data-health-disclaimer]')!;
    expect(notice.textContent!.trim()).toBe('هذه المعلومات للتوعية فقط، ولا تُغني عن استشارة الطبيب.');
    expect(!!(root.querySelector('[data-trust-row]')!.compareDocumentPosition(notice) & Node.DOCUMENT_POSITION_FOLLOWING)).toBe(true);
    expect(!!(notice.compareDocumentPosition(root.querySelector('rd-rdoc')!) & Node.DOCUMENT_POSITION_FOLLOWING)).toBe(true);
  });
});
