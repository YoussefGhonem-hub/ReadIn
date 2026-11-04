import { Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

/** A guest's tap on a post card that needs an account, kept until they come back signed in (F34). */
export interface CardReturn {
  articleId: string;
  /** They pressed Comment: the comments open again once they are back. */
  comments: boolean;
  at: number;
}

/** A sign-in that takes longer than this no longer brings you back to the card. */
const RETURN_TTL_MS = 15 * 60_000;
const DRAFTS_KEY = 'rdCommentDrafts';
/** Drafts kept per tab; the oldest go first. */
const MAX_DRAFTS = 30;

/**
 * What survives a post card (F34) between pages and refreshes: unsent comment text per article and account (kept for
 * the tab in sessionStorage, so even a reload keeps it), and the card a guest was on when the sign-in prompt opened,
 * so the feed brings them back to it after signing in. Expanded cards and open comments live in the cards themselves:
 * Home is kept alive while you read (feed-route-reuse.ts), and a refresh builds new cards.
 */
@Injectable({ providedIn: 'root' })
export class FeedMemory {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly drafts = new Map<string, string>(this.readDrafts());
  private readonly _return = signal<CardReturn | null>(null);

  /** The card to bring a guest back to; null once used or expired. */
  readonly pendingReturn = this._return.asReadonly();

  draft(key: string): string {
    return this.drafts.get(key) ?? '';
  }

  setDraft(key: string, text: string): void {
    if ((this.drafts.get(key) ?? '') === text) return;
    this.drafts.delete(key);
    if (text.trim()) this.drafts.set(key, text);
    while (this.drafts.size > MAX_DRAFTS) this.drafts.delete(this.drafts.keys().next().value!);
    this.writeDrafts();
  }

  rememberReturn(articleId: string, comments: boolean): void {
    this._return.set({ articleId, comments, at: Date.now() });
  }

  /** The pending return for this article, used once. */
  takeReturn(articleId: string): CardReturn | null {
    const pending = this._return();
    if (!pending) return null;
    if (Date.now() - pending.at > RETURN_TTL_MS) {
      this._return.set(null);
      return null;
    }
    if (pending.articleId !== articleId) return null;
    this._return.set(null);
    return pending;
  }

  private readDrafts(): [string, string][] {
    if (!this.isBrowser) return [];
    try {
      const raw = sessionStorage.getItem(DRAFTS_KEY);
      const parsed: unknown = raw ? JSON.parse(raw) : [];
      return Array.isArray(parsed) ? parsed.filter((e): e is [string, string] => Array.isArray(e) && typeof e[0] === 'string' && typeof e[1] === 'string') : [];
    } catch {
      return [];
    }
  }

  private writeDrafts(): void {
    if (!this.isBrowser) return;
    try {
      sessionStorage.setItem(DRAFTS_KEY, JSON.stringify([...this.drafts]));
    } catch {
      /* storage full or blocked: drafts stay in memory */
    }
  }
}
