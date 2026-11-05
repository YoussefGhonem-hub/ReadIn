import { TestBed } from '@angular/core/testing';
import { Observable, Subject, of, throwError } from 'rxjs';
import { ApiError } from '../../core/api/api.config';
import { ArticlesApi } from '../../core/api/articles.api';
import { ArticleDraftDocument, ArticleEditDto, DraftProblemDto, PublishedArticleDto } from '../../core/api/models';
import { DraftBackupStore, NEW_ARTICLE_KEY } from './draft-backup';
import { AUTOSAVE_MS, ArticleEditorStore, BACKUP_DEBOUNCE_MS, RECHECK_MS, emptyDocument } from './editor.store';

const USER = 'u-writer';

function editDto(patch: Partial<ArticleEditDto> = {}): ArticleEditDto {
  return {
    id: 'a1',
    status: 'draft',
    slug: null,
    publishedAt: null,
    version: 1,
    savedAt: '2026-11-03T10:00:00Z',
    hasUnpublishedChanges: false,
    document: emptyDocument('ar-EG'),
    media: [],
    checks: { readingTime: [{ language: 'ar-EG', minutes: 1, words: 3 }], problems: [] },
    ...patch,
  };
}

const conflict = () => new ApiError(409, 'article.draft_conflict', { code: 'article.draft_conflict', status: 409 });
const offline = () => new ApiError(0, 'network', null);
const fail = (error: unknown) => throwError(() => error);

class FakeArticlesApi {
  /** What the server holds: every save bumps the version. */
  server = editDto();
  create = vi.fn((document: ArticleDraftDocument): Observable<ArticleEditDto> => {
    this.server = editDto({ document, version: 1 });
    return of(this.server);
  });
  saveDraft = vi.fn((_id: string, body: { baseVersion: number; document: ArticleDraftDocument }): Observable<ArticleEditDto> => {
    if (body.baseVersion !== this.server.version) return fail(conflict());
    this.server = { ...this.server, document: body.document, version: this.server.version + 1, hasUnpublishedChanges: this.server.status === 'published' };
    return of(this.server);
  });
  edit = vi.fn((): Observable<ArticleEditDto> => of(this.server));
  publish = vi.fn((_id: string, baseVersion: number): Observable<PublishedArticleDto> => {
    if (baseVersion !== this.server.version) return fail(conflict());
    this.server = { ...this.server, status: 'published', slug: 'my-article', hasUnpublishedChanges: false };
    return of({ id: 'a1', slug: 'my-article', publishedAt: '2026-11-03T11:00:00Z', revision: 1, firstPublish: true });
  });
  discardDraft = vi.fn((): Observable<ArticleEditDto> => {
    this.server = { ...this.server, document: editDto().document, version: this.server.version + 1, hasUnpublishedChanges: false };
    return of(this.server);
  });
  restoreRevision = vi.fn((_id: string, _revision: number, baseVersion: number): Observable<ArticleEditDto> => {
    if (baseVersion !== this.server.version) return fail(conflict());
    const document = { ...editDto().document, translations: [{ ...editDto().document.translations[0], title: 'Revision 1 title' }] };
    this.server = { ...this.server, document, version: this.server.version + 1, hasUnpublishedChanges: true };
    return of(this.server);
  });
  delete = vi.fn(() => of(undefined));
}

describe('ArticleEditorStore (autosave, local backup, conflicts)', () => {
  let store: ArticleEditorStore;
  let api: FakeArticlesApi;
  let backups: DraftBackupStore;

  const typeTitle = (title: string) => store.updateTranslation('ar-EG', { title });

  beforeEach(() => {
    localStorage.clear();
    vi.useFakeTimers();
    api = new FakeArticlesApi();
    TestBed.configureTestingModule({ providers: [ArticleEditorStore, { provide: ArticlesApi, useValue: api }] });
    store = TestBed.inject(ArticleEditorStore);
    backups = TestBed.inject(DraftBackupStore);
  });

  afterEach(() => {
    vi.useRealTimers();
    localStorage.clear();
  });

  describe('a new article', () => {
    it('is created on its first autosave, 10 s after the first change, and keeps saving every 10 s while changed', async () => {
      const created = vi.fn();
      store.onCreated = created;
      store.startNew(USER, 'ar-EG');
      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS * 2);
      expect(api.create).not.toHaveBeenCalled(); // nothing typed: nothing saved

      typeTitle('Clean');
      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS - 1);
      expect(api.create).not.toHaveBeenCalled();
      typeTitle('Clean Architecture'); // more typing does not push the save back
      await vi.advanceTimersByTimeAsync(1);
      expect(api.create).toHaveBeenCalledTimes(1);
      expect(api.create.mock.calls[0][0].translations[0].title).toBe('Clean Architecture');
      expect(created).toHaveBeenCalledWith('a1');
      expect(store.articleId()).toBe('a1');
      expect(store.dirty()).toBe(false);
      expect(store.saveStatus()).toBe('saved');

      typeTitle('Clean Architecture in 5 images');
      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS);
      expect(api.saveDraft).toHaveBeenCalledWith('a1', { baseVersion: 1, document: store.document() });
      expect(store.version()).toBe(2);
    });

    it('keeps every unsaved change in a local backup until the server has it', async () => {
      store.startNew(USER, 'ar-EG');
      typeTitle('Draft title');
      await vi.advanceTimersByTimeAsync(BACKUP_DEBOUNCE_MS);
      expect(backups.read(USER, NEW_ARTICLE_KEY)?.document.translations[0].title).toBe('Draft title');

      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS);
      expect(backups.read(USER, NEW_ARTICLE_KEY)).toBeNull(); // created: nothing left to keep
      expect(backups.read(USER, 'a1')).toBeNull();
    });

    it('offers the backup of an unsaved new article when writing again', async () => {
      backups.write(USER, NEW_ARTICLE_KEY, { articleId: null, baseVersion: null, updatedAt: new Date().toISOString(), document: { ...emptyDocument('en'), fieldId: 'f-software' } });
      store.startNew(USER, 'ar-EG');
      expect(store.restoreOffer()?.document.fieldId).toBe('f-software');
      const before = store.contentVersion();
      store.acceptRestore();
      expect(store.document().fieldId).toBe('f-software');
      expect(store.document().sourceLanguage).toBe('en');
      expect(store.contentVersion()).toBe(before + 1); // the editor reloads its content
      expect(store.dirty()).toBe(true);
      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS);
      expect(api.create).toHaveBeenCalled();
    });
  });

  describe('an existing article', () => {
    beforeEach(async () => {
      api.server = editDto({ version: 4, savedAt: '2026-11-03T10:00:00Z' });
      await store.open(USER, 'a1');
    });

    it('loads the working copy', () => {
      expect(api.edit).toHaveBeenCalledWith('a1');
      expect(store.loadState()).toBe('ready');
      expect(store.version()).toBe(4);
      expect(store.dirty()).toBe(false);
    });

    it('never runs two saves at once: a save waits for the one in flight and uses its version', async () => {
      const first = new Subject<ArticleEditDto>();
      api.saveDraft.mockImplementationOnce(() => first);
      typeTitle('One');
      const saving = store.save();
      expect(store.saveStatus()).toBe('saving');
      typeTitle('Two');
      const again = store.save();
      expect(api.saveDraft).toHaveBeenCalledTimes(1);
      api.server = editDto({ version: 5 });
      first.next(api.server);
      first.complete();
      expect(await saving).toBe(false); // "Two" came in while saving
      expect(await again).toBe(true);
      expect(api.saveDraft).toHaveBeenCalledTimes(2);
      expect(api.saveDraft.mock.calls[1][1].baseVersion).toBe(5);
      expect(api.saveDraft.mock.calls[1][1].document.translations[0].title).toBe('Two');
    });

    it('a save refused because of the tags (F32) says which ones, until a save goes through', async () => {
      const refused = new ApiError(400, 'validation.failed', {
        code: 'validation.failed',
        status: 400,
        errors: { 'document.tags[1]': ['tag.invalid'], 'document.tags': ['article.too_many_tags'], 'document.title': ['validation.required'] },
      });
      api.saveDraft.mockImplementationOnce(() => fail(refused));
      store.patch({ tags: ['C#', 'CI/CD'] });
      expect(await store.save()).toBe(false);
      expect(store.saveStatus()).toBe('error');
      expect(store.tagErrors()).toEqual([
        { code: 'tag.invalid', tag: 'CI/CD' },
        { code: 'article.too_many_tags', tag: null },
      ]);

      store.patch({ tags: ['C#'] });
      expect(await store.save()).toBe(true);
      expect(store.tagErrors()).toEqual([]);
    });

    it('offline: keeps the change on this device, says so, and retries', async () => {
      api.saveDraft.mockImplementationOnce(() => fail(offline()));
      typeTitle('Written on the train');
      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS);
      expect(store.saveStatus()).toBe('offline');
      expect(store.dirty()).toBe(true);
      expect(backups.read(USER, 'a1')?.document.translations[0].title).toBe('Written on the train');
      expect(backups.read(USER, 'a1')?.baseVersion).toBe(4);

      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS); // back online
      expect(store.saveStatus()).toBe('saved');
      expect(backups.read(USER, 'a1')).toBeNull();
    });

    it('409 article.draft_conflict stops autosave until the writer chooses; "reload" takes the server copy', async () => {
      api.server = { ...api.server, version: 6, document: { ...api.server.document, fieldId: 'f-medicine' } }; // saved from another device
      typeTitle('Mine');
      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS);
      expect(store.conflict()).toBe(true);
      expect(store.saveStatus()).toBe('conflict');
      typeTitle('Mine, still typing');
      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS * 3);
      expect(api.saveDraft).toHaveBeenCalledTimes(1);

      const before = store.contentVersion();
      expect(await store.reloadServerCopy()).toBe(true);
      expect(store.conflict()).toBe(false);
      expect(store.document().fieldId).toBe('f-medicine');
      expect(store.document().translations[0].title).toBe('');
      expect(store.version()).toBe(6);
      expect(store.dirty()).toBe(false);
      expect(store.contentVersion()).toBe(before + 1);
      expect(backups.read(USER, 'a1')).toBeNull();
    });

    it('409: "keep mine" saves the local document on top of the latest version', async () => {
      api.server = { ...api.server, version: 6 };
      typeTitle('Mine');
      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS);
      expect(store.conflict()).toBe(true);
      expect(await store.keepMine()).toBe(true);
      expect(store.conflict()).toBe(false);
      const last = api.saveDraft.mock.calls.at(-1)!;
      expect(last[1].baseVersion).toBe(6);
      expect(last[1].document.translations[0].title).toBe('Mine');
      expect(store.version()).toBe(7);
      expect(store.dirty()).toBe(false);
    });

    it('rechecks sooner while the last checks found problems', async () => {
      const problem: DraftProblemDto = { code: 'article.title_length', language: 'ar-EG', blockId: null, mediaAssetId: null };
      api.saveDraft.mockImplementationOnce((_id, body) => {
        api.server = { ...api.server, version: 5, document: body.document, checks: { readingTime: [], problems: [problem] } };
        return of(api.server);
      });
      typeTitle('Abc');
      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS);
      expect(store.problems()).toEqual([problem]);
      api.server = { ...api.server, checks: { readingTime: [], problems: [] } }; // the next save fixes it
      typeTitle('Abcdef');
      await vi.advanceTimersByTimeAsync(RECHECK_MS);
      expect(api.saveDraft).toHaveBeenCalledTimes(2);
      expect(store.problems()).toEqual([]);
    });
  });

  describe('local backup on open', () => {
    it('offers a backup newer than the server copy, and "dismiss" deletes it', async () => {
      api.server = editDto({ version: 3, savedAt: '2026-11-03T10:00:00Z' });
      const document = { ...emptyDocument('ar-EG'), tags: ['dotnet'] };
      backups.write(USER, 'a1', { articleId: 'a1', baseVersion: 3, updatedAt: '2026-11-03T10:05:00Z', document });
      await store.open(USER, 'a1');
      expect(store.restoreOffer()?.document.tags).toEqual(['dotnet']);
      store.dismissRestore();
      expect(store.restoreOffer()).toBeNull();
      expect(backups.read(USER, 'a1')).toBeNull();
      expect(store.document().tags).toEqual([]);
    });

    it('drops a backup that is older than the server copy, or the same as it', async () => {
      api.server = editDto({ version: 3, savedAt: '2026-11-03T10:00:00Z' });
      backups.write(USER, 'a1', { articleId: 'a1', baseVersion: 2, updatedAt: '2026-11-03T09:00:00Z', document: { ...emptyDocument('ar-EG'), tags: ['old'] } });
      await store.open(USER, 'a1');
      expect(store.restoreOffer()).toBeNull();
      expect(backups.read(USER, 'a1')).toBeNull();

      backups.write(USER, 'a1', { articleId: 'a1', baseVersion: 3, updatedAt: '2026-11-03T11:00:00Z', document: api.server.document });
      await store.open(USER, 'a1');
      expect(store.restoreOffer()).toBeNull();
    });

    it('keeps backups per user', () => {
      backups.write('someone-else', NEW_ARTICLE_KEY, { articleId: null, baseVersion: null, updatedAt: new Date().toISOString(), document: emptyDocument('en') });
      store.startNew(USER, 'ar-EG');
      expect(store.restoreOffer()).toBeNull();
    });

    it('works without storage', () => {
      const setItem = vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
        throw new Error('QuotaExceededError');
      });
      store.startNew(USER, 'ar-EG');
      typeTitle('x');
      store.writeBackupNow();
      expect(store.backupFailed()).toBe(true);
      setItem.mockRestore();
    });
  });

  describe('actions', () => {
    beforeEach(async () => {
      api.server = editDto({ version: 2 });
      await store.open(USER, 'a1');
    });

    it('Publish saves pending changes first, then publishes that version', async () => {
      typeTitle('Ready to publish');
      const published = await store.publish();
      expect(api.saveDraft).toHaveBeenCalledTimes(1);
      expect(api.publish).toHaveBeenCalledWith('a1', 3);
      expect(published?.slug).toBe('my-article');
      expect(store.status()).toBe('published');
      expect(store.hasUnpublishedChanges()).toBe(false);
    });

    it('does not publish while the checks have problems; a 400 from publish shows its problems', async () => {
      const problems: DraftProblemDto[] = [{ code: 'article.field_required', language: null, blockId: null, mediaAssetId: null }];
      api.server = { ...api.server, checks: { readingTime: [], problems } };
      typeTitle('x');
      expect(await store.publish()).toBeNull();
      expect(api.publish).not.toHaveBeenCalled();

      api.server = { ...api.server, checks: { readingTime: [], problems: [] } };
      typeTitle('y');
      api.publish.mockImplementationOnce(() => fail(new ApiError(400, 'article.sources_required', { code: 'article.sources_required', problems: [{ code: 'article.sources_required', language: null, blockId: null, mediaAssetId: null }] } as never)));
      expect(await store.publish()).toBeNull();
      expect(store.problems().map((p) => p.code)).toEqual(['article.sources_required']);
    });

    it('a stale version on publish is a conflict', async () => {
      api.publish.mockImplementationOnce(() => fail(conflict()));
      expect(await store.publish()).toBeNull();
      expect(store.conflict()).toBe(true);
    });

    it('Discard changes resets the working copy to the published version', async () => {
      store.status.set('published');
      typeTitle('Not for readers yet');
      const before = store.contentVersion();
      expect(await store.discardChanges()).toBe(true);
      expect(api.discardDraft).toHaveBeenCalledWith('a1');
      expect(store.document().translations[0].title).toBe('');
      expect(store.contentVersion()).toBe(before + 1);
      expect(store.dirty()).toBe(false);
    });

    it('restores a revision into the working copy (not live until Update)', async () => {
      expect(await store.restoreRevision(1)).toBe(true);
      expect(api.restoreRevision).toHaveBeenCalledWith('a1', 1, 2);
      expect(store.document().translations[0].title).toBe('Revision 1 title');
      expect(store.hasUnpublishedChanges()).toBe(true);
    });

    it('deletes the article and its backup', async () => {
      typeTitle('Delete me');
      store.writeBackupNow();
      expect(await store.deleteArticle()).toBe(true);
      expect(api.delete).toHaveBeenCalledWith('a1');
      expect(backups.read(USER, 'a1')).toBeNull();
      await vi.advanceTimersByTimeAsync(AUTOSAVE_MS);
      expect(api.saveDraft).not.toHaveBeenCalled();
    });
  });

  describe('language versions', () => {
    beforeEach(() => store.startNew(USER, 'ar-EG'));

    it('adds and removes the other language, never the source', () => {
      store.addTranslation('en');
      expect(store.document().translations.map((t) => t.language)).toEqual(['ar-EG', 'en']);
      expect(store.document().translations[1].content.language).toBe('en');
      store.addTranslation('en');
      expect(store.document().translations).toHaveLength(2);
      store.removeTranslation('ar-EG');
      expect(store.document().translations).toHaveLength(2);
      store.removeTranslation('en');
      expect(store.document().translations.map((t) => t.language)).toEqual(['ar-EG']);
    });

    it('changes the article language while it has one version, keeping content.language in step', () => {
      store.setContent('ar-EG', { version: 1, language: 'ar-EG', blocks: [{ id: 'p', type: 'paragraph', content: [] }] });
      store.setSourceLanguage('en');
      const [only] = store.document().translations;
      expect(store.document().sourceLanguage).toBe('en');
      expect(only.language).toBe('en');
      expect(only.content.language).toBe('en');
    });
  });
});
