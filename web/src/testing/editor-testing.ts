import { Observable, of, throwError } from 'rxjs';
import { ApiError } from '../app/core/api/api.config';
import {
  ArticleDraftDocument,
  ArticleEditDto,
  ArticleRevisionDetailsDto,
  ArticleRevisionDto,
  DraftChecksDto,
  FieldDto,
  PublishedArticleDto,
} from '../app/core/api/models';
import { emptyDocument } from '../app/features/editor/editor.store';

export const TEST_EDITOR_FIELDS: FieldDto[] = [
  { id: 'f-software', slug: 'software', name: 'Software', nameAr: 'البرمجيات', nameEn: 'Software', icon: 'code', color: 'primary', isSensitive: false, requiresSources: false, topicCount: 0 },
  { id: 'f-medicine', slug: 'medicine', name: 'Medicine', nameAr: 'الطب', nameEn: 'Medicine', icon: 'stethoscope', color: 'primary', isSensitive: true, requiresSources: true, topicCount: 0 },
];

export function editDto(patch: Partial<ArticleEditDto> = {}): ArticleEditDto {
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

export const conflictError = () => new ApiError(409, 'article.draft_conflict', { code: 'article.draft_conflict', status: 409 });

/** Checks like the server's, enough for the editor tests: field, title length and empty content. */
export function testChecks(document: ArticleDraftDocument): DraftChecksDto {
  const problems: DraftChecksDto['problems'] = [];
  if (!document.fieldId) problems.push({ code: 'article.field_required', language: null, blockId: null, mediaAssetId: null });
  for (const t of document.translations) {
    const length = t.title.trim().length;
    if (length < 5 || length > 150) problems.push({ code: 'article.title_length', language: t.language, blockId: null, mediaAssetId: null });
    const hasText = t.content.blocks.some((b) => 'content' in b && b.content.some((n) => n.type === 'text' && n.text.trim()));
    if (!hasText) problems.push({ code: 'article.content_empty', language: t.language, blockId: null, mediaAssetId: null });
  }
  return { readingTime: document.translations.map((t) => ({ language: t.language, minutes: 1, words: 10 })), problems };
}

const fail = (error: unknown) => throwError(() => error);

/** An in-memory ArticlesApi with the contract's versioning: every save bumps `version`, a stale `baseVersion` is a 409. */
export class FakeArticlesApi {
  server = editDto();
  revisionsList: ArticleRevisionDto[] = [];
  revisionDocs = new Map<number, ArticleDraftDocument>();

  create = vi.fn((document: ArticleDraftDocument): Observable<ArticleEditDto> => {
    this.server = editDto({ document, version: 1, checks: testChecks(document) });
    return of(this.server);
  });
  saveDraft = vi.fn((_id: string, body: { baseVersion: number; document: ArticleDraftDocument }): Observable<ArticleEditDto> => {
    if (body.baseVersion !== this.server.version) return fail(conflictError());
    this.server = {
      ...this.server,
      document: body.document,
      version: this.server.version + 1,
      savedAt: new Date().toISOString(),
      hasUnpublishedChanges: this.server.status === 'published',
      checks: testChecks(body.document),
    };
    return of(this.server);
  });
  edit = vi.fn((): Observable<ArticleEditDto> => of(this.server));
  publish = vi.fn((_id: string, baseVersion: number): Observable<PublishedArticleDto> => {
    if (baseVersion !== this.server.version) return fail(conflictError());
    const first = this.server.status === 'draft';
    const number = this.revisionsList.length + 1;
    this.revisionsList = [{ number, createdAt: '2026-11-03T11:00:00Z', title: this.server.document.translations[0].title, languages: this.server.document.translations.map((t) => t.language) }, ...this.revisionsList];
    this.revisionDocs.set(number, this.server.document);
    this.server = { ...this.server, status: 'published', slug: this.server.slug ?? 'my-article', publishedAt: '2026-11-03T11:00:00Z', hasUnpublishedChanges: false };
    return of({ id: this.server.id, slug: this.server.slug!, publishedAt: this.server.publishedAt!, revision: number, firstPublish: first });
  });
  discardDraft = vi.fn((): Observable<ArticleEditDto> => {
    const live = this.revisionDocs.get(this.revisionsList[0]?.number ?? 0) ?? this.server.document;
    this.server = { ...this.server, document: live, version: this.server.version + 1, hasUnpublishedChanges: false, checks: testChecks(live) };
    return of(this.server);
  });
  revisions = vi.fn((): Observable<ArticleRevisionDto[]> => of(this.revisionsList));
  revision = vi.fn((_id: string, number: number): Observable<ArticleRevisionDetailsDto> => {
    const head = this.revisionsList.find((r) => r.number === number)!;
    return of({ ...head, document: this.revisionDocs.get(number)!, media: [] });
  });
  restoreRevision = vi.fn((_id: string, number: number, baseVersion: number): Observable<ArticleEditDto> => {
    if (baseVersion !== this.server.version) return fail(conflictError());
    const document = this.revisionDocs.get(number)!;
    this.server = { ...this.server, document, version: this.server.version + 1, hasUnpublishedChanges: true, checks: testChecks(document) };
    return of(this.server);
  });
  delete = vi.fn(() => of(undefined));
  mine = vi.fn(() => of({ items: [], nextCursor: null }));
}
