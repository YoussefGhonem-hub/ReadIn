import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { Router, provideRouter } from '@angular/router';
import { Editor } from '@tiptap/core';
import { of } from 'rxjs';
import { FakeArticlesApi, TEST_EDITOR_FIELDS, editDto, testChecks } from '../../../testing/editor-testing';
import { testMe } from '../../../testing/auth-testing';
import { translocoTesting } from '../../../testing/transloco-testing';
import { ArticlesApi } from '../../core/api/articles.api';
import { CommentsApi } from '../../core/api/comments.api';
import { MediaApi } from '../../core/api/media.api';
import { ArticleDraftDocument } from '../../core/api/models';
import { TagsApi } from '../../core/api/tags.api';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { SessionStore } from '../../core/auth/session.store';
import { BlurHashDecoder } from '../../shared/media/blurhash';
import { ImageCompressor } from '../../shared/media/image-compressor';
import { provideAppIcons } from '../../shared/ui/icons';
import { DraftBackupStore } from './draft-backup';
import { EditorPage } from './editor.page';
import { AUTOSAVE_MS, emptyDocument } from './editor.store';
import { BlockEditor } from './rdoc-editor/block-editor';

const PUBLISHED_DOC: ArticleDraftDocument = {
  ...emptyDocument('ar-EG'),
  fieldId: 'f-software',
  translations: [
    {
      language: 'ar-EG',
      title: 'يعني إيه Dependency Injection؟',
      subtitle: null,
      content: { version: 1, language: 'ar-EG', blocks: [{ id: 'p1', type: 'paragraph', content: [{ type: 'text', text: 'الـ DI بيسهّل الـ testing.' }] }] },
    },
  ],
};

describe('Editor page (F05, /write/new and /write/:id)', () => {
  let fixture: ComponentFixture<EditorPage>;
  let api: FakeArticlesApi;
  let navigate: ReturnType<typeof vi.spyOn>;

  const el = () => fixture.nativeElement as HTMLElement;
  const $ = <T extends Element = HTMLElement>(selector: string) => el().querySelector<T>(selector);
  const publishButton = () => $<HTMLButtonElement>('[data-publish]')!;
  const tiptap = (): Editor => (fixture.debugElement.query(By.directive(BlockEditor)).componentInstance as unknown as { editor: Editor }).editor;

  async function settle(ms = 0): Promise<void> {
    await vi.advanceTimersByTimeAsync(ms);
    for (let i = 0; i < 4; i++) {
      fixture.detectChanges();
      await vi.advanceTimersByTimeAsync(0);
    }
  }

  async function open(id: string): Promise<void> {
    fixture = TestBed.createComponent(EditorPage);
    fixture.componentRef.setInput('id', id);
    await settle();
  }

  function typeInto(selector: string, value: string): void {
    const input = $<HTMLInputElement>(selector)!;
    input.value = value;
    input.dispatchEvent(new Event('input', { bubbles: true }));
  }

  beforeEach(() => {
    localStorage.clear();
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout', 'setInterval', 'clearInterval', 'Date'], now: new Date('2026-11-03T12:00:00Z') });
    api = new FakeArticlesApi();
    TestBed.configureTestingModule({
      imports: [translocoTesting()],
      providers: [
        provideRouter([]),
        provideAppIcons(),
        { provide: ArticlesApi, useValue: api },
        { provide: TaxonomyApi, useValue: { fields: () => of(TEST_EDITOR_FIELDS), topics: () => of([]) } },
        { provide: TagsApi, useValue: { search: () => of([{ slug: 'dotnet', name: 'dotnet', articleCount: 12 }]) } },
        { provide: CommentsApi, useValue: { mentionSuggestions: () => of([]) } },
        { provide: MediaApi, useValue: { uploadImage: vi.fn(), uploadDocument: vi.fn(), get: vi.fn(), delete: vi.fn(() => of(undefined)) } },
        { provide: ImageCompressor, useValue: { compress: (file: File) => Promise.resolve(file) } },
        { provide: BlurHashDecoder, useValue: { toDataUrl: () => null } },
      ],
    });
    TestBed.inject(SessionStore).setMe(testMe({ articleLanguage: 'ar-EG', isVerified: true }));
    navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
  });

  afterEach(() => {
    fixture?.destroy();
    vi.useRealTimers();
    localStorage.clear();
    document.documentElement.removeAttribute('data-theme');
  });

  it('a new article is created on its first autosave; the URL becomes /write/{id} without reloading the editor', async () => {
    await open('new');
    expect($('[data-editor]')?.getAttribute('contenteditable')).toBe('true');
    expect($('[data-save-status]')?.textContent?.trim()).toBe('');
    expect(publishButton().disabled).toBe(true); // nothing written yet

    typeInto('[data-title]', 'Clean Architecture');
    await settle();
    expect($('[data-save-status]')?.getAttribute('data-state')).toBe('saving');
    expect(api.create).not.toHaveBeenCalled();

    await settle(AUTOSAVE_MS);
    expect(api.create).toHaveBeenCalledTimes(1);
    expect(api.create.mock.calls[0][0].translations[0]).toMatchObject({ language: 'ar-EG', title: 'Clean Architecture' });
    expect(navigate).toHaveBeenCalledWith(['/write', 'a1'], { replaceUrl: true });
    expect($('[data-save-status]')?.textContent).toContain('تم الحفظ');

    // The router puts the new id in: same editor, nothing reloaded.
    const editor = tiptap();
    fixture.componentRef.setInput('id', 'a1');
    await settle();
    expect(tiptap()).toBe(editor);
    expect(api.edit).not.toHaveBeenCalled();
  });

  it('lists the live checks after a save, jumps to what needs fixing, and publishes once they pass', async () => {
    await open('new');
    typeInto('[data-title]', 'DI');
    await settle(AUTOSAVE_MS);
    const problems = () => [...el().querySelectorAll('[data-problems] [data-problem]')].map((p) => p.getAttribute('data-problem'));
    expect(problems()).toEqual(['article.field_required', 'article.title_length', 'article.content_empty']);
    expect($('[data-problems]')?.textContent).toContain('اختر المجال.');
    expect($('[data-title-count]')?.textContent).toContain('2/150');
    expect(publishButton().disabled).toBe(true);

    $<HTMLButtonElement>('[data-problem="article.field_required"]')!.click();
    await settle(10);
    expect(document.activeElement?.id).toBe('ed-field');

    // Fix everything: field, title, text.
    const field = $<HTMLSelectElement>('[data-field]')!;
    field.value = 'f-software';
    field.dispatchEvent(new Event('change'));
    typeInto('[data-title]', 'Dependency Injection in 5 minutes');
    tiptap().commands.insertContent('الـ DI بيخلّي الكود أسهل في الـ testing.');
    await settle(AUTOSAVE_MS);
    expect(problems()).toEqual([]);
    expect($('[data-checks-ready]')).not.toBeNull();
    expect($('[data-reading-time]')?.textContent).toContain('10 كلمات');
    expect(publishButton().disabled).toBe(false);

    publishButton().click();
    await settle();
    expect(api.publish).toHaveBeenCalledWith('a1', api.server.version);
    const saved = api.saveDraft.mock.calls.at(-1)![1].document;
    expect(saved.fieldId).toBe('f-software');
    expect(saved.translations[0].content.blocks[0]).toMatchObject({ type: 'paragraph', content: [{ type: 'text', text: 'الـ DI بيخلّي الكود أسهل في الـ testing.' }] });
    expect(navigate).toHaveBeenLastCalledWith(['/', 'ar', 'a', 'my-article']);
  });

  it('a published article: Update stays off without changes; changes enable it; Discard goes back to the live version', async () => {
    api.server = editDto({ status: 'published', slug: 'di', publishedAt: '2026-11-01T10:00:00Z', version: 3, document: PUBLISHED_DOC, checks: testChecks(PUBLISHED_DOC) });
    api.revisionDocs.set(1, PUBLISHED_DOC);
    api.revisionsList = [{ number: 1, createdAt: '2026-11-01T10:00:00Z', title: PUBLISHED_DOC.translations[0].title, languages: ['ar-EG'] }];
    await open('a1');
    expect(api.edit).toHaveBeenCalledWith('a1');
    expect(publishButton().textContent).toContain('تحديث');
    expect(publishButton().disabled).toBe(true);
    expect($('[data-publish-hint]')?.textContent).toContain('يرى القراء هذه النسخة بالفعل.');
    expect($('[data-discard]')).toBeNull();

    typeInto('[data-title]', 'يعني إيه Dependency Injection في .NET 10؟');
    await settle(AUTOSAVE_MS);
    expect(api.saveDraft).toHaveBeenCalledWith('a1', expect.objectContaining({ baseVersion: 3 }));
    expect(publishButton().disabled).toBe(false);

    $<HTMLButtonElement>('[data-discard]')!.click();
    await settle();
    expect($('[data-confirm-sheet]')?.getAttribute('data-confirm')).toBe('discard');
    $<HTMLButtonElement>('[data-confirm-action]')!.click();
    await settle();
    expect(api.discardDraft).toHaveBeenCalledWith('a1');
    expect($<HTMLTextAreaElement>('[data-title]')!.value).toBe('يعني إيه Dependency Injection؟');
    expect($('[data-discard]')).toBeNull();
  });

  it('409 article.draft_conflict: a choice in the page; "keep mine" saves on top of the latest version', async () => {
    api.server = editDto({ version: 2, document: PUBLISHED_DOC });
    await open('a1');
    api.server = { ...api.server, version: 5 }; // saved from another device meanwhile
    typeInto('[data-title]', 'My title from this tab');
    await settle(AUTOSAVE_MS);
    expect($('[data-conflict]')).not.toBeNull();
    expect($('[data-save-status]')?.getAttribute('data-state')).toBe('conflict');
    expect(publishButton().disabled).toBe(true);

    $<HTMLButtonElement>('[data-conflict-keep]')!.click();
    await settle();
    expect($('[data-conflict]')).toBeNull();
    const last = api.saveDraft.mock.calls.at(-1)!;
    expect(last[1].baseVersion).toBe(5);
    expect(last[1].document.translations[0].title).toBe('My title from this tab');
  });

  it('offers to restore a local backup that is newer than the server copy', async () => {
    api.server = editDto({ version: 2, savedAt: '2026-11-03T09:00:00Z', document: PUBLISHED_DOC });
    TestBed.inject(DraftBackupStore).write('user-1', 'a1', {
      articleId: 'a1',
      baseVersion: 2,
      updatedAt: '2026-11-03T11:00:00Z',
      document: { ...PUBLISHED_DOC, translations: [{ ...PUBLISHED_DOC.translations[0], title: 'Written offline' }] },
    });
    await open('a1');
    expect($('[data-restore-offer]')).not.toBeNull();
    $<HTMLButtonElement>('[data-restore-accept]')!.click();
    await settle();
    expect($<HTMLTextAreaElement>('[data-title]')!.value).toBe('Written offline');
    await settle(AUTOSAVE_MS);
    expect(api.saveDraft.mock.calls.at(-1)![1].document.translations[0].title).toBe('Written offline');
  });

  it('previews the article like the reader, in light or dark, without changing the saved theme', async () => {
    api.server = editDto({ version: 2, document: PUBLISHED_DOC, checks: testChecks(PUBLISHED_DOC) });
    await open('a1');
    $<HTMLButtonElement>('[data-preview-toggle]')!.click();
    await settle();
    const preview = $('rd-article-preview')!;
    expect(preview.querySelector('h1')?.textContent).toContain('يعني إيه Dependency Injection؟');
    expect(preview.querySelector('rd-rdoc [data-block-id="p1"]')).not.toBeNull();
    expect(preview.textContent).toContain('البرمجيات');
    expect(preview.textContent).toContain('كاتب موثّق');
    expect($('[data-edit-area]')?.hasAttribute('hidden')).toBe(true);

    const dark = [...el().querySelectorAll<HTMLButtonElement>('[data-preview-theme] button')].find((b) => b.textContent?.includes('داكن'))!;
    dark.click();
    await settle();
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');

    $<HTMLButtonElement>('[data-preview-toggle]')!.click();
    await settle();
    expect(document.documentElement.getAttribute('data-theme')).toBe('system');
  });

  it('restores a revision into the working copy', async () => {
    const v1 = { ...PUBLISHED_DOC, translations: [{ ...PUBLISHED_DOC.translations[0], title: 'First published title' }] };
    api.server = editDto({ status: 'published', slug: 'di', version: 4, document: PUBLISHED_DOC, checks: testChecks(PUBLISHED_DOC) });
    api.revisionDocs.set(1, v1);
    api.revisionDocs.set(2, PUBLISHED_DOC);
    api.revisionsList = [
      { number: 2, createdAt: '2026-11-02T10:00:00Z', title: PUBLISHED_DOC.translations[0].title, languages: ['ar-EG'] },
      { number: 1, createdAt: '2026-11-01T10:00:00Z', title: 'First published title', languages: ['ar-EG'] },
    ];
    await open('a1');
    $<HTMLButtonElement>('[data-history-toggle]')!.click();
    await settle();
    expect([...el().querySelectorAll('[data-revision]')].map((r) => r.getAttribute('data-revision'))).toEqual(['2', '1']);
    $<HTMLButtonElement>('[data-revision="1"]')!.click();
    await settle();
    expect($('[data-revisions] rd-article-preview h1')?.textContent).toContain('First published title');
    $<HTMLButtonElement>('[data-restore-revision]')!.click();
    await settle();
    $<HTMLButtonElement>('[data-confirm-action]')!.click();
    await settle();
    expect(api.restoreRevision).toHaveBeenCalledWith('a1', 1, 4);
    expect($('[data-edit-area]')?.hasAttribute('hidden')).toBe(false);
    expect($<HTMLTextAreaElement>('[data-title]')!.value).toBe('First published title');
    expect(tiptap().getText()).toContain('الـ DI بيسهّل الـ testing.');
  });

  it('adds the other language version as a second tab, and removes it again after confirming', async () => {
    await open('new');
    $<HTMLButtonElement>('[data-add-translation]')!.click();
    await settle(10);
    const tabs = () => [...el().querySelectorAll('[data-language-tab]')].map((t) => [t.getAttribute('data-language-tab'), t.getAttribute('aria-selected')]);
    expect(tabs()).toEqual([
      ['ar-EG', 'false'],
      ['en', 'true'],
    ]);
    typeInto('[data-title]', 'What is DI?');
    tiptap().commands.insertContent('English text');
    await settle(AUTOSAVE_MS);
    const saved = api.create.mock.calls[0][0];
    expect(saved.translations.map((t) => [t.language, t.title, t.content.language])).toEqual([
      ['ar-EG', '', 'ar-EG'],
      ['en', 'What is DI?', 'en'],
    ]);
    expect(saved.translations[1].content.blocks[0]).toMatchObject({ type: 'paragraph', content: [{ type: 'text', text: 'English text' }] });
    expect($('[data-editor-surface]')?.getAttribute('lang')).toBe('en');

    $<HTMLButtonElement>('[data-remove-translation]')!.click();
    await settle();
    $<HTMLButtonElement>('[data-confirm-action]')!.click();
    await settle();
    expect(el().querySelectorAll('[data-language-tab]').length).toBe(0);
    await settle(AUTOSAVE_MS);
    expect(api.saveDraft.mock.calls.at(-1)![1].document.translations.map((t) => t.language)).toEqual(['ar-EG']);
  });

  it('deletes the article after an in-page confirmation and goes back to My articles', async () => {
    api.server = editDto({ version: 2, document: PUBLISHED_DOC });
    await open('a1');
    $<HTMLButtonElement>('[data-delete]')!.click();
    await settle();
    expect($('[data-confirm-sheet]')?.getAttribute('data-confirm')).toBe('delete');
    $<HTMLButtonElement>('[data-confirm-action]')!.click();
    await settle();
    expect(api.delete).toHaveBeenCalledWith('a1');
    expect(navigate).toHaveBeenLastCalledWith(['/write']);
  });

  it('shows "not found" for an article that is not yours', async () => {
    const { ApiError } = await import('../../core/api/api.config');
    const { throwError } = await import('rxjs');
    api.edit.mockReturnValueOnce(throwError(() => new ApiError(404, 'article.not_found', { code: 'article.not_found' })));
    await open('someone-else');
    expect(el().textContent).toContain('هذا المقال غير موجود');
  });
});
