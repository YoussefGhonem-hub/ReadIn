import { Injectable, Injector, PLATFORM_ID, Signal, computed, effect, inject, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoService } from '@jsverse/transloco';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { HighlightDto, HighlightsApi, PopularHighlightDto } from '../../core/api/highlights.api';
import { ArticleLanguage } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { BlockMarks } from '../../shared/rdoc/rdoc-marks';
import { RDoc } from '../../shared/rdoc/rdoc.models';
import { HighlightRange } from '../../shared/rdoc/selection-offsets';
import { TextMark } from '../../shared/rdoc/text-marks';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { HighlightsPrefs } from './highlights-prefs';

/** The version on screen. */
export interface ReaderArticle {
  id: string;
  language: ArticleLanguage;
  content: RDoc | null;
}

/** A highlight being saved: drawn at once, replaced by the server's when it answers. */
const PENDING = 'pending-';
export const isPendingHighlight = (id: string) => id.startsWith(PENDING);

/**
 * The reader's highlights (F30) for the version on screen: yours (`mine`, document order) and the popular ones, from
 * `GET /articles/{id}/highlights?lang=` in the browser once the session is known (not while they are hidden). Create
 * and remove are optimistic and roll back on failure; `highlight.text_mismatch` reloads the article and its highlights
 * (the author updated it meanwhile). After a change only `mine` is updated: popular ranges refresh on the next open.
 * Provided by the reader page.
 */
@Injectable()
export class ArticleHighlightsStore {
  private readonly api = inject(HighlightsApi);
  private readonly session = inject(SessionStore);
  private readonly prefs = inject(HighlightsPrefs);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly injector = inject(Injector);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  readonly visible = this.prefs.visible;
  readonly mine = signal<HighlightDto[]>([]);
  readonly popular = signal<PopularHighlightDto[]>([]);
  private source: Signal<ReaderArticle | null> = signal(null);
  readonly article = computed(() => this.source());
  private reloadArticle: () => void = () => undefined;
  /** `articleId|language|viewer` of what is loaded (or loading); null to load again. */
  private loadedKey: string | null = null;
  /** `articleId|language` the lists belong to. */
  private version: string | null = null;
  private generation = 0;
  private pendingCount = 0;

  /** What the renderer draws: nothing while hidden. A range that is both yours and popular is drawn as yours. */
  readonly marks = computed<BlockMarks | null>(() => {
    if (!this.visible()) return null;
    const map = new Map<string, TextMark[]>();
    const add = (blockId: string, mark: TextMark) => map.set(blockId, [...(map.get(blockId) ?? []), mark]);
    for (const p of this.popular()) add(p.blockId, { start: p.startOffset, end: p.endOffset, mine: null, count: p.count });
    for (const h of this.mine()) add(h.blockId, { start: h.startOffset, end: h.endOffset, mine: h.id, count: null });
    for (const list of map.values()) list.sort((a, b) => a.start - b.start);
    return map.size ? map : null;
  });

  /** Follows the version on screen; `reloadArticle` fetches the article again (after `highlight.text_mismatch`). */
  connect(article: Signal<ReaderArticle | null>, reloadArticle: () => void): void {
    this.source = article;
    this.reloadArticle = reloadArticle;
    if (!this.isBrowser) return;
    effect(
      () => {
        const current = article();
        const visible = this.visible();
        const resolved = this.session.isResolved();
        const viewer = this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null;
        if (!current || !resolved || !visible) return;
        const key = `${current.id}|${current.language}|${viewer}`;
        if (key === this.loadedKey) return;
        untracked(() => void this.load(current, key));
      },
      { injector: this.injector },
    );
  }

  /**
   * The article changed under a selection (`highlight.text_mismatch`, or the quote card's `quote.text_mismatch`, F24):
   * loads the article and its highlights again.
   */
  textChanged(): void {
    this.reloadArticle();
    this.reload();
  }

  /** Loads the version on screen again. */
  reload(): void {
    this.loadedKey = null;
    const current = this.source();
    if (current && this.visible()) void this.load(current, `${current.id}|${current.language}|${this.session.me()?.id ?? null}`);
  }

  /** Your highlight holding the whole range (selecting inside it offers Remove). */
  mineContaining(range: HighlightRange): HighlightDto | null {
    return (
      this.mine().find(
        (h) => !isPendingHighlight(h.id) && h.blockId === range.blockId && h.startOffset <= range.startOffset && range.endOffset <= h.endOffset,
      ) ?? null
    );
  }

  /** How many readers marked a popular range holding the whole range, or null. */
  popularCount(range: HighlightRange): number | null {
    const counts = this.popular()
      .filter((p) => p.blockId === range.blockId && p.startOffset <= range.startOffset && range.endOffset <= p.endOffset)
      .map((p) => p.count);
    return counts.length ? Math.max(...counts) : null;
  }

  /** Resolves true once the server has it. */
  async create(range: HighlightRange): Promise<boolean> {
    const article = this.source();
    if (!article) return false;
    const version = this.version;
    const temp: HighlightDto = { id: `${PENDING}${++this.pendingCount}`, ...range, createdAt: new Date().toISOString() };
    this.mine.update((list) => this.ordered([...list, temp]));
    try {
      const { highlight, replacedIds } = await firstValueFrom(this.api.create(article.id, { language: article.language, ...range }));
      if (version !== this.version) return true;
      const dropped = new Set([temp.id, highlight.id, ...replacedIds]);
      this.mine.update((list) => this.ordered([...list.filter((h) => !dropped.has(h.id)), highlight]));
      return true;
    } catch (error) {
      this.mine.update((list) => list.filter((h) => h.id !== temp.id));
      this.toasts.error(this.errors.forError(error));
      if (isApiError(error) && error.code === 'highlight.text_mismatch') this.textChanged();
      return false;
    }
  }

  /** Resolves true once it is gone (also when the server says it already was). */
  async remove(id: string): Promise<boolean> {
    const removed = this.mine().find((h) => h.id === id);
    if (!removed || isPendingHighlight(id)) return false;
    const version = this.version;
    this.mine.update((list) => list.filter((h) => h.id !== id));
    try {
      await firstValueFrom(this.api.remove(id));
      return true;
    } catch (error) {
      if (isApiError(error) && (error.code === 'highlight.not_found' || error.status === 404)) return true;
      if (version === this.version) this.mine.update((list) => this.ordered([...list, removed]));
      this.toasts.error(this.errors.forError(error));
      return false;
    }
  }

  /** "N readers highlighted this". */
  countLabel(count: number): string {
    return this.transloco.translate('highlights.popular', { count });
  }

  private async load(article: ReaderArticle, key: string): Promise<void> {
    const generation = ++this.generation;
    this.loadedKey = key;
    const version = `${article.id}|${article.language}`;
    if (this.version !== version) {
      // Another version's offsets mean nothing here.
      this.version = version;
      this.mine.set([]);
      this.popular.set([]);
    }
    try {
      const result = await firstValueFrom(this.api.forArticle(article.id, article.language));
      if (generation !== this.generation) return;
      const matches = result.language === article.language;
      this.mine.set(matches ? this.ordered(result.mine) : []);
      this.popular.set(matches ? result.popular : []);
    } catch {
      // Highlights are extra: the article reads fine without them. The next open (or showing them) tries again.
      if (generation === this.generation) this.loadedKey = null;
    }
  }

  /** Document order: by block, then by start. */
  private ordered(list: HighlightDto[]): HighlightDto[] {
    const blocks = new Map((this.source()?.content?.blocks ?? []).map((b, i) => [b.id, i]));
    const index = (id: string) => blocks.get(id) ?? Number.MAX_SAFE_INTEGER;
    return [...list].sort((a, b) => index(a.blockId) - index(b.blockId) || a.startOffset - b.startOffset);
  }
}
