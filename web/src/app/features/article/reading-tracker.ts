import { DOCUMENT, Injector, PLATFORM_ID, Signal, afterNextRender, computed, effect, inject, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { ArticleLanguage, ReadingProgressRequest, ReadingProgressResultDto } from '../../core/api/models';
import { ReadingApi } from '../../core/api/reading.api';
import { SessionStore } from '../../core/auth/session.store';
import { ReadingSheetsService } from '../reading/reading-sheets.service';
import { StreakStore } from '../reading/streak.store';

/** A report every 15 s while the reader is active (ADR 0013). */
export const REPORT_INTERVAL_MS = 15_000;
/** The reader counts as active for this long after their last scroll, wheel, pointer, key or touch. */
export const ACTIVE_WINDOW_MS = 60_000;
/** The API accepts up to this many seconds per report; the rest waits for the next one. */
const MAX_DELTA_SECONDS = 3600;
const INTERACTIONS = ['scroll', 'wheel', 'pointerdown', 'pointermove', 'keydown', 'touchstart'] as const;

export interface TrackedArticle {
  id: string;
  language: ArticleLanguage;
}

interface ReadingSessionEnv {
  window: Window;
  document: Document;
  send(articleId: string, body: ReadingProgressRequest, keepalive: boolean): Promise<ReadingProgressResultDto>;
  onResult(result: ReadingProgressResultDto): void;
}

/** How far the reader has scrolled through `el` (0..1), like the reader's progress bar: 1 when it fits the viewport. */
export function scrollFraction(el: HTMLElement, viewportHeight: number): number {
  const rect = el.getBoundingClientRect();
  const total = rect.height - viewportHeight;
  return total <= 0 ? 1 : Math.min(1, Math.max(0, -rect.top / total));
}

/**
 * Reports reading progress for the "read" rule and streaks (SPEC F04, F08, ADR 0013) while the reader shows an
 * article: once when it is loaded (`activeSecondsDelta: 0`, the server credits no time on the first report), every
 * 15 s, when the tab is hidden and when the reader closes. Browser only, signed-in users only.
 *
 * Must run in the reader's injection context. `progress` is the reader's scroll fraction (0..1); `element` is the
 * article, measured once when a session starts because `progress` can still describe the loading skeleton. While
 * `hold` returns true no session starts: the reader is still putting you back where you left off (F04 resume), and
 * a first report from the top would save that over your position.
 */
export function injectReadingTracker(
  article: () => TrackedArticle | null,
  progress: Signal<number>,
  element?: () => HTMLElement | undefined,
  hold?: () => boolean,
): void {
  if (!isPlatformBrowser(inject(PLATFORM_ID))) return;
  const window = inject(DOCUMENT).defaultView;
  if (!window) return;
  const api = inject(ReadingApi);
  const session = inject(SessionStore);
  const streaks = inject(StreakStore);
  const sheets = inject(ReadingSheetsService);
  const injector = inject(Injector);

  const env: ReadingSessionEnv = {
    window,
    document: window.document,
    send: (articleId, body, keepalive) => firstValueFrom(api.progress(articleId, body, { keepalive })),
    onResult: (result) => {
      streaks.applyProgress(result);
      if (result.milestone) sheets.celebrate(result.milestone);
    },
  };

  // Another article or language starts a new session; guests have none.
  const target = computed<TrackedArticle | null>(
    () => {
      const current = article();
      return current && session.isAuthenticated() && !hold?.() ? { id: current.id, language: current.language } : null;
    },
    { equal: (a, b) => a?.id === b?.id && a?.language === b?.language },
  );
  let active: ReadingSession | null = null;

  effect((onCleanup) => {
    const tracked = target();
    if (!tracked) return;
    let reading: ReadingSession | null = null;
    const started = afterNextRender(
      () => {
        const el = element?.();
        reading = active = new ReadingSession(tracked, env, el ? scrollFraction(el, window.innerHeight) : progress());
        reading.start();
      },
      { injector },
    );
    onCleanup(() => {
      started.destroy();
      if (active === reading) active = null;
      // After a sign out the last report would be anonymous, so it is dropped.
      reading?.stop(untracked(() => session.isAuthenticated()));
    });
  });

  effect(() => {
    const fraction = progress();
    untracked(() => active?.setProgress(fraction));
  });
}

/** One article read once: counts active seconds and sends them with the scroll progress. */
class ReadingSession {
  private maxProgress: number;
  private position: number;
  /** The user counts as active right after opening. */
  private lastInteraction: number;
  /** Active time is counted up to here. */
  private countedUntil: number;
  private visible: boolean;
  private unsentMs = 0;
  private lastSent: ReadingProgressRequest | null = null;
  private inFlight = false;
  /** A flush that waits for the report in flight. */
  private flushQueued = false;
  private timer: ReturnType<typeof setInterval> | null = null;
  private listening = false;
  /** 401/404: this article is not reported again. */
  private ended = false;

  constructor(
    private readonly article: TrackedArticle,
    private readonly env: ReadingSessionEnv,
    progress: number,
  ) {
    this.maxProgress = this.position = clamp(progress);
    this.lastInteraction = this.countedUntil = Date.now();
    this.visible = this.isVisible();
  }

  start(): void {
    const { window, document } = this.env;
    for (const type of INTERACTIONS) window.addEventListener(type, this.onInteraction, { capture: true, passive: true });
    document.addEventListener('visibilitychange', this.onVisibilityChange);
    this.listening = true;
    this.timer = setInterval(() => this.report(), REPORT_INTERVAL_MS);
    this.report();
  }

  setProgress(fraction: number): void {
    this.position = clamp(fraction);
    this.maxProgress = Math.max(this.maxProgress, this.position);
  }

  /** The reader closed: report what is left (unless `flush` is off) and stop counting. */
  stop(flush: boolean): void {
    if (!this.listening) return;
    this.count();
    this.visible = false; // nothing counts from here on
    this.detach();
    if (flush) this.report({ flush: true });
  }

  private readonly onInteraction = (): void => {
    const now = Date.now();
    this.count(now);
    this.lastInteraction = now;
  };

  private readonly onVisibilityChange = (): void => {
    this.count();
    this.visible = this.isVisible();
    // The tab may be closing: send what was read so far, and let the request outlive the page.
    if (!this.visible) this.report({ flush: true, keepalive: true });
  };

  private isVisible(): boolean {
    return this.env.document.visibilityState === 'visible';
  }

  /** Adds the time since the last count while the tab was visible and the user active in the last 60 s. */
  private count(now = Date.now()): void {
    if (this.visible) {
      const activeUntil = Math.min(now, this.lastInteraction + ACTIVE_WINDOW_MS);
      if (activeUntil > this.countedUntil) this.unsentMs += activeUntil - this.countedUntil;
    }
    this.countedUntil = now;
  }

  /** Sends the unsent seconds and the progress, unless nothing changed. One report at a time. */
  private report(options: { flush?: boolean; keepalive?: boolean } = {}): void {
    if (this.ended) return;
    if (this.inFlight) {
      if (options.flush) this.flushQueued = true; // ticks just wait for the next interval
      return;
    }
    this.count();
    const seconds = Math.min(Math.floor(this.unsentMs / 1000), MAX_DELTA_SECONDS);
    const body: ReadingProgressRequest = {
      language: this.article.language,
      percent: Math.round(this.maxProgress * 100),
      lastPosition: this.position.toFixed(4),
      activeSecondsDelta: seconds,
    };
    const last = this.lastSent;
    if (last && seconds === 0 && body.percent === last.percent && body.lastPosition === last.lastPosition) return;

    this.unsentMs -= seconds * 1000;
    this.inFlight = true;
    this.env
      .send(this.article.id, body, options.keepalive ?? false)
      .then(
        (result) => {
          this.lastSent = body;
          this.env.onResult(result);
        },
        (error: unknown) => {
          this.unsentMs += seconds * 1000; // a failed report keeps its seconds for the next one
          // Signed out, or the article isn't published (any more): stop. Network, 5xx, 409 and 429: try again later.
          if (isApiError(error) && (error.status === 401 || error.status === 404)) this.end();
        },
      )
      .finally(() => {
        this.inFlight = false;
        if (this.flushQueued) {
          this.flushQueued = false;
          this.report({ flush: true });
        }
      });
  }

  private end(): void {
    this.ended = true;
    this.flushQueued = false;
    this.detach();
  }

  private detach(): void {
    if (!this.listening) return;
    this.listening = false;
    const { window, document } = this.env;
    for (const type of INTERACTIONS) window.removeEventListener(type, this.onInteraction, { capture: true });
    document.removeEventListener('visibilitychange', this.onVisibilityChange);
    if (this.timer !== null) clearInterval(this.timer);
    this.timer = null;
  }
}

function clamp(fraction: number): number {
  return Number.isFinite(fraction) ? Math.min(1, Math.max(0, fraction)) : 0;
}
