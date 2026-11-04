import { DestroyRef, Injectable, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { ArticlesApi } from '../../core/api/articles.api';
import {
  ArticleDraftDocument,
  ArticleEditDto,
  ArticleLanguage,
  ArticleStatus,
  DraftAttachment,
  DraftChecksDto,
  DraftProblemDto,
  DraftTranslation,
  MediaAssetDto,
  ProblemDetails,
  PublishedArticleDto,
} from '../../core/api/models';
import { RDoc } from '../../shared/rdoc/rdoc.models';
import { DraftBackup, DraftBackupStore, NEW_ARTICLE_KEY } from './draft-backup';

/** Autosave interval while there are unsaved changes (SPEC F05). */
export const AUTOSAVE_MS = 10_000;
/** While the last checks found problems, changes are checked sooner, so fixing one enables Publish quickly. */
export const RECHECK_MS = 2_000;
/** Local backups are written this long after the last change. */
export const BACKUP_DEBOUNCE_MS = 400;

export type LoadState = 'loading' | 'ready' | 'notFound' | 'error';
/** `idle`: nothing to save yet. `offline`: the change is kept on this device and sent when the API is back. */
export type SaveStatus = 'idle' | 'saving' | 'saved' | 'offline' | 'error' | 'conflict';
export type EditorAction = 'publishing' | 'discarding' | 'restoring' | 'deleting' | 'reloading';

export function emptyContent(language: ArticleLanguage): RDoc {
  return { version: 1, language, blocks: [] };
}

export function emptyTranslation(language: ArticleLanguage): DraftTranslation {
  return { language, title: '', subtitle: null, content: emptyContent(language) };
}

export function emptyDocument(language: ArticleLanguage): ArticleDraftDocument {
  return {
    sourceLanguage: language,
    translations: [emptyTranslation(language)],
    fieldId: null,
    topicId: null,
    tags: [],
    sources: [],
    coverUrl: null,
    versionBadge: null,
    isAiAssisted: false,
    attachments: [],
  };
}

/** A server document with every list present (defensive: the editor never handles `undefined`). */
export function normalizeDocument(document: ArticleDraftDocument): ArticleDraftDocument {
  const translations = (document.translations ?? []).map((t) => ({
    language: t.language,
    title: t.title ?? '',
    subtitle: t.subtitle ?? null,
    content: t.content?.blocks ? { ...t.content, language: t.language } : emptyContent(t.language),
  }));
  const sourceLanguage = translations.some((t) => t.language === document.sourceLanguage) ? document.sourceLanguage : (translations[0]?.language ?? 'ar-EG');
  return {
    sourceLanguage,
    translations: translations.length ? translations : [emptyTranslation(sourceLanguage)],
    fieldId: document.fieldId ?? null,
    topicId: document.topicId ?? null,
    tags: document.tags ?? [],
    sources: document.sources ?? [],
    coverUrl: document.coverUrl ?? null,
    versionBadge: document.versionBadge ?? null,
    isAiAssisted: !!document.isAiAssisted,
    attachments: document.attachments ?? [],
  };
}

/** Attachments compared by meaning: empty strings are null, `order` is the position. */
export function normalizeAttachments(attachments: readonly DraftAttachment[]): DraftAttachment[] {
  const text = (value: string | null | undefined) => (value?.trim() ? value.trim() : null);
  return [...attachments]
    .sort((a, b) => a.order - b.order)
    .map((a, order) => ({
      mediaAssetId: a.mediaAssetId,
      order,
      caption: text(a.caption),
      altText: text(a.altText),
      title: text(a.title),
      allowDownload: !!a.allowDownload,
    }));
}

function sameJson(a: unknown, b: unknown): boolean {
  return JSON.stringify(a) === JSON.stringify(b);
}

function errorCode(error: unknown): string {
  return isApiError(error) ? error.code : 'unknown';
}

function isConflict(error: unknown): boolean {
  return isApiError(error) && error.code === 'article.draft_conflict';
}

function isOffline(error: unknown): boolean {
  return isApiError(error) && error.status === 0;
}

/**
 * The article being written (F05): the working copy, autosave, the local backup, conflicts and the actions
 * (publish/update, discard changes, restore a revision, delete).
 *
 * - Every change bumps a counter; autosave (`PUT /articles/{id}/draft`, or `POST /articles` the first time) runs
 *   10 s after the first unsaved change and again while changes keep coming. Saves never overlap.
 * - The local document is never replaced by a save response (that would fight the writer's typing); only loading,
 *   reloading after a conflict, discarding and restoring replace it, and then `contentVersion` changes so the
 *   editor reloads its content.
 * - Every unsaved change is also written to a local backup (per user and article). It is removed once the server
 *   has everything, and offered back on open when it is newer than the server copy.
 */
@Injectable()
export class ArticleEditorStore {
  private readonly api = inject(ArticlesApi);
  private readonly backups = inject(DraftBackupStore);

  // ── Server state ──
  readonly articleId = signal<string | null>(null);
  readonly status = signal<ArticleStatus>('draft');
  readonly slug = signal<string | null>(null);
  readonly publishedAt = signal<string | null>(null);
  /** Working-copy version (null before the article exists on the server). */
  readonly version = signal<number | null>(null);
  readonly savedAt = signal<string | null>(null);
  readonly hasUnpublishedChanges = signal(false);
  readonly checks = signal<DraftChecksDto | null>(null);
  readonly media = signal<MediaAssetDto[]>([]);

  // ── Local state ──
  readonly document = signal<ArticleDraftDocument>(emptyDocument('ar-EG'));
  /** Changes whenever the document is replaced from outside the editor (load, reload, restore, discard). */
  readonly contentVersion = signal(0);
  readonly loadState = signal<LoadState>('loading');
  readonly loadError = signal<string | null>(null);
  readonly saveStatus = signal<SaveStatus>('idle');
  readonly saveError = signal<string | null>(null);
  readonly conflict = signal(false);
  readonly dirty = signal(false);
  readonly action = signal<EditorAction | null>(null);
  readonly actionError = signal<string | null>(null);
  /** A local backup newer than the server copy, waiting for the writer's choice. */
  readonly restoreOffer = signal<DraftBackup | null>(null);
  /** Image block and cover uploads in flight (attachments track their own). */
  readonly uploads = signal(0);
  /** True when the last local backup could not be written (storage blocked or full). */
  readonly backupFailed = signal(false);

  readonly problems = computed<DraftProblemDto[]>(() => this.checks()?.problems ?? []);
  readonly isPublished = computed(() => this.status() === 'published');
  /** Something readers don't see yet: a never-published draft, or unpublished changes of a published article. */
  readonly hasChangesToPublish = computed(() => !this.isPublished() || this.hasUnpublishedChanges() || this.dirty());

  private userId = 'anonymous';
  private changeSeq = 0;
  private autosaveTimer: ReturnType<typeof setTimeout> | null = null;
  private backupTimer: ReturnType<typeof setTimeout> | null = null;
  private inFlight: Promise<boolean> | null = null;
  private destroyed = false;
  /** Called once the first save created the article (the page puts the id in the URL). */
  onCreated: ((id: string) => void) | null = null;
  /** Called right before every save, so the editor can hand over typing it hasn't reported yet. */
  beforeSave: (() => void) | null = null;

  constructor() {
    inject(DestroyRef).onDestroy(() => {
      this.destroyed = true;
      this.clearTimers();
      // Leaving with unsaved changes: they are in the backup; try one last save without waiting.
      if (this.dirty() && !this.conflict() && this.loadState() === 'ready') {
        this.writeBackupNow();
        void this.save();
      }
    });
  }

  // ── Open ───────────────────────────────────────────────

  /** A new article (`/write/new`) in `language`; offers the backup of an unsaved new article, if any. */
  startNew(userId: string, language: ArticleLanguage): void {
    this.userId = userId;
    this.document.set(emptyDocument(language));
    this.contentVersion.update((v) => v + 1);
    this.loadState.set('ready');
    const backup = this.backups.read(userId, NEW_ARTICLE_KEY);
    if (backup && !backup.articleId) this.restoreOffer.set(backup);
  }

  /** `GET /articles/{id}/edit`, then offers a local backup that is newer than the server copy. */
  async open(userId: string, id: string): Promise<void> {
    this.userId = userId;
    this.loadState.set('loading');
    this.loadError.set(null);
    try {
      const dto = await firstValueFrom(this.api.edit(id));
      if (this.destroyed) return;
      this.applyServer(dto, true);
      this.loadState.set('ready');
      this.saveStatus.set('saved');
      const backup = this.backups.read(userId, dto.id);
      if (backup) {
        const newer = Date.parse(backup.updatedAt) > Date.parse(dto.savedAt);
        if (newer && !sameJson(normalizeDocument(backup.document), this.document())) this.restoreOffer.set(backup);
        else this.backups.clear(userId, dto.id); // the server already has it (or something newer)
      }
    } catch (error) {
      if (this.destroyed) return;
      const code = errorCode(error);
      this.loadError.set(code);
      this.loadState.set(code === 'article.not_found' ? 'notFound' : 'error');
    }
  }

  acceptRestore(): void {
    const backup = this.restoreOffer();
    if (!backup) return;
    this.restoreOffer.set(null);
    this.document.set(normalizeDocument(backup.document));
    this.contentVersion.update((v) => v + 1);
    this.changed();
  }

  dismissRestore(): void {
    if (!this.restoreOffer()) return;
    this.restoreOffer.set(null);
    this.backups.clear(this.userId, this.backupKey());
  }

  // ── Editing ────────────────────────────────────────────

  /** Applies a change to the document (no-op when nothing changes). */
  update(mutate: (document: ArticleDraftDocument) => ArticleDraftDocument): void {
    const before = this.document();
    const after = mutate(before);
    if (after === before || sameJson(after, before)) return;
    this.document.set(after);
    this.changed();
  }

  patch(patch: Partial<Omit<ArticleDraftDocument, 'translations' | 'sourceLanguage'>>): void {
    this.update((d) => ({ ...d, ...patch }));
  }

  updateTranslation(language: ArticleLanguage, patch: Partial<Omit<DraftTranslation, 'language'>>): void {
    this.update((d) => ({ ...d, translations: d.translations.map((t) => (t.language === language ? { ...t, ...patch } : t)) }));
  }

  setContent(language: ArticleLanguage, content: RDoc): void {
    this.updateTranslation(language, { content: { ...content, language } });
  }

  /** Ignores differences that mean the same (empty text vs null, order numbering). */
  setAttachments(attachments: DraftAttachment[]): void {
    if (sameJson(normalizeAttachments(attachments), normalizeAttachments(this.document().attachments))) return;
    this.patch({ attachments });
  }

  /** Adds the other language version (SPEC F05 "second language version"). */
  addTranslation(language: ArticleLanguage): void {
    this.update((d) =>
      d.translations.some((t) => t.language === language) || d.translations.length >= 2 ? d : { ...d, translations: [...d.translations, emptyTranslation(language)] },
    );
  }

  /** Removes the second language version (never the source). */
  removeTranslation(language: ArticleLanguage): void {
    this.update((d) => (language === d.sourceLanguage ? d : { ...d, translations: d.translations.filter((t) => t.language !== language) }));
  }

  /** Changes the article language while there is only one version. */
  setSourceLanguage(language: ArticleLanguage): void {
    this.update((d) => {
      if (d.translations.length !== 1 || d.sourceLanguage === language) return d;
      const [only] = d.translations;
      return { ...d, sourceLanguage: language, translations: [{ ...only, language, content: { ...only.content, language } }] };
    });
  }

  private changed(): void {
    this.changeSeq++;
    this.dirty.set(true);
    if (this.saveStatus() === 'saved' || this.saveStatus() === 'idle') this.saveStatus.set('idle');
    this.scheduleBackup();
    this.scheduleAutosave();
  }

  // ── Autosave ───────────────────────────────────────────

  private scheduleAutosave(): void {
    if (this.destroyed || this.conflict() || !this.dirty()) return;
    const delay = this.problems().length ? RECHECK_MS : AUTOSAVE_MS;
    if (this.autosaveTimer) return;
    this.autosaveTimer = setTimeout(() => {
      this.autosaveTimer = null;
      void this.save();
    }, delay);
  }

  /**
   * Saves the working copy now (creates the article on its first save). Resolves true when the server has every
   * change made before the call. Never runs two saves at once.
   */
  async save(): Promise<boolean> {
    if (this.inFlight) await this.inFlight;
    if (this.conflict()) return false;
    this.beforeSave?.();
    if (!this.dirty() && this.articleId()) return true;
    if (this.autosaveTimer) {
      clearTimeout(this.autosaveTimer);
      this.autosaveTimer = null;
    }
    const seq = this.changeSeq;
    const document = this.document();
    const run = this.send(seq, document);
    this.inFlight = run;
    try {
      return await run;
    } finally {
      if (this.inFlight === run) this.inFlight = null;
      if (this.dirty()) this.scheduleAutosave();
    }
  }

  private async send(seq: number, document: ArticleDraftDocument): Promise<boolean> {
    this.saveStatus.set('saving');
    try {
      const id = this.articleId();
      const version = this.version();
      const dto = id && version !== null ? await firstValueFrom(this.api.saveDraft(id, { baseVersion: version, document })) : await firstValueFrom(this.api.create(document));
      if (!id) {
        this.backups.clear(this.userId, NEW_ARTICLE_KEY);
        this.articleId.set(dto.id);
        if (seq !== this.changeSeq) this.writeBackupNow(); // the newer changes, now under the article id
        if (!this.destroyed) this.onCreated?.(dto.id);
      }
      this.applyServer(dto, false);
      if (seq === this.changeSeq) {
        this.dirty.set(false);
        this.cancelBackup();
        this.backups.clear(this.userId, dto.id);
      }
      this.saveStatus.set('saved');
      this.saveError.set(null);
      return seq === this.changeSeq;
    } catch (error) {
      if (isConflict(error)) {
        this.conflict.set(true);
        this.saveStatus.set('conflict');
      } else {
        this.saveStatus.set(isOffline(error) ? 'offline' : 'error');
        this.saveError.set(errorCode(error));
      }
      return false;
    }
  }

  /** Server fields from an `ArticleEditDto`; `replaceDocument` also takes its document (reload, restore, discard). */
  private applyServer(dto: ArticleEditDto, replaceDocument: boolean): void {
    this.articleId.set(dto.id);
    this.status.set(dto.status);
    this.slug.set(dto.slug);
    this.publishedAt.set(dto.publishedAt);
    this.version.set(dto.version);
    this.savedAt.set(dto.savedAt);
    this.hasUnpublishedChanges.set(dto.hasUnpublishedChanges);
    this.checks.set(dto.checks ?? null);
    this.media.set(dto.media ?? []);
    if (replaceDocument) {
      this.clearTimers();
      this.document.set(normalizeDocument(dto.document));
      this.contentVersion.update((v) => v + 1);
      this.changeSeq++;
      this.dirty.set(false);
      this.saveStatus.set('saved');
    }
  }

  // ── Conflict (409 article.draft_conflict) ──────────────

  /** "Reload": drop the local changes and continue from the server copy. */
  async reloadServerCopy(): Promise<boolean> {
    const id = this.articleId();
    if (!id) return false;
    return this.run('reloading', async () => {
      const dto = await firstValueFrom(this.api.edit(id));
      this.conflict.set(false);
      this.applyServer(dto, true);
      this.backups.clear(this.userId, id);
      return true;
    });
  }

  /** "Keep mine": save the local document on top of the latest server version. */
  async keepMine(): Promise<boolean> {
    const id = this.articleId();
    if (!id) return false;
    const ok = await this.run('reloading', async () => {
      const dto = await firstValueFrom(this.api.edit(id));
      this.applyServer(dto, false);
      this.conflict.set(false);
      return true;
    });
    if (!ok) return false;
    this.dirty.set(true);
    return this.save();
  }

  // ── Actions ────────────────────────────────────────────

  /**
   * Publish or Update: saves pending changes first, then `POST /articles/{id}/publish`. Returns the published
   * article, or null when it can't be published (problems, conflict, error: see `checks`, `conflict`, `actionError`).
   */
  async publish(): Promise<PublishedArticleDto | null> {
    if (this.action()) return null;
    this.actionError.set(null);
    // Changes typed while saving make `save()` resolve false although it succeeded: save those too (a few times at most).
    let saved = await this.save();
    for (let attempt = 0; !saved && attempt < 3 && this.dirty() && this.saveStatus() === 'saved'; attempt++) saved = await this.save();
    const id = this.articleId();
    const version = this.version();
    if (!saved || !id || version === null || this.problems().length) return null;
    let result: PublishedArticleDto | null = null;
    await this.run('publishing', async () => {
      try {
        result = await firstValueFrom(this.api.publish(id, version));
      } catch (error) {
        const problems = isApiError(error) ? (error.problem as (ProblemDetails & { problems?: DraftProblemDto[] }) | null)?.problems : undefined;
        if (problems?.length) {
          this.checks.update((checks) => ({ readingTime: checks?.readingTime ?? [], problems }));
          return false;
        }
        throw error;
      }
      this.status.set('published');
      this.slug.set(result.slug);
      this.publishedAt.set(result.publishedAt);
      this.hasUnpublishedChanges.set(false);
      this.backups.clear(this.userId, id);
      return true;
    });
    return result;
  }

  /** "Discard changes" of a published article: the working copy goes back to what readers see. */
  async discardChanges(): Promise<boolean> {
    const id = this.articleId();
    if (!id || !this.isPublished()) return false;
    await this.waitForSave();
    return this.run('discarding', async () => {
      const dto = await firstValueFrom(this.api.discardDraft(id));
      this.applyServer(dto, true);
      this.backups.clear(this.userId, id);
      return true;
    });
  }

  /** Copies a revision into the working copy (unsaved local changes are replaced). */
  async restoreRevision(revision: number): Promise<boolean> {
    const id = this.articleId();
    if (!id) return false;
    await this.waitForSave();
    const version = this.version();
    if (version === null) return false;
    return this.run('restoring', async () => {
      const dto = await firstValueFrom(this.api.restoreRevision(id, revision, version));
      this.applyServer(dto, true);
      this.backups.clear(this.userId, id);
      return true;
    });
  }

  /** Deletes the article (or just forgets an unsaved new one). */
  async deleteArticle(): Promise<boolean> {
    const id = this.articleId();
    this.clearTimers();
    await this.inFlight;
    const done = await this.run('deleting', async () => {
      if (id) await firstValueFrom(this.api.delete(id));
      return true;
    });
    if (done) {
      this.dirty.set(false);
      this.backups.clear(this.userId, NEW_ARTICLE_KEY);
      if (id) this.backups.clear(this.userId, id);
    }
    return done;
  }

  private async waitForSave(): Promise<void> {
    if (this.autosaveTimer) {
      clearTimeout(this.autosaveTimer);
      this.autosaveTimer = null;
    }
    if (this.inFlight) await this.inFlight;
  }

  private async run(action: EditorAction, task: () => Promise<boolean>): Promise<boolean> {
    this.action.set(action);
    this.actionError.set(null);
    try {
      return await task();
    } catch (error) {
      if (isConflict(error)) {
        this.conflict.set(true);
        this.saveStatus.set('conflict');
      } else {
        this.actionError.set(errorCode(error));
      }
      return false;
    } finally {
      this.action.set(null);
    }
  }

  // ── Local backup ───────────────────────────────────────

  private backupKey(): string {
    return this.articleId() ?? NEW_ARTICLE_KEY;
  }

  private scheduleBackup(): void {
    this.cancelBackup();
    this.backupTimer = setTimeout(() => {
      this.backupTimer = null;
      this.writeBackupNow();
    }, BACKUP_DEBOUNCE_MS);
  }

  private cancelBackup(): void {
    if (this.backupTimer) clearTimeout(this.backupTimer);
    this.backupTimer = null;
  }

  /** Writes the unsaved document to this device now. */
  writeBackupNow(): void {
    this.cancelBackup();
    if (!this.dirty()) return;
    const written = this.backups.write(this.userId, this.backupKey(), {
      articleId: this.articleId(),
      baseVersion: this.version(),
      updatedAt: new Date().toISOString(),
      document: this.document(),
    });
    this.backupFailed.set(!written);
  }

  private clearTimers(): void {
    if (this.autosaveTimer) clearTimeout(this.autosaveTimer);
    this.autosaveTimer = null;
    this.cancelBackup();
  }
}
