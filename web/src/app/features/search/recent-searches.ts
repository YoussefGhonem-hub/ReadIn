import { Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { cleanSearchQuery, isSearchable, searchKey } from './search-query';

/** Searches kept on the device. */
export const MAX_RECENT_SEARCHES = 10;
const STORAGE_KEY = 'readin.recentSearches';

function storage(): Storage | null {
  try {
    return typeof localStorage === 'undefined' ? null : localStorage;
  } catch {
    return null; // blocked storage, private mode…
  }
}

/**
 * Recent searches (F16), on this device for guests and signed-in users alike: the last 10, newest first. Searching
 * again moves a query to the top (one entry per query, ignoring case and Arabic spelling variants). Empty on the
 * server; the browser reads them on start.
 */
@Injectable({ providedIn: 'root' })
export class RecentSearches {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly list = signal<readonly string[]>(this.read());
  readonly items = this.list.asReadonly();

  add(raw: string): void {
    const query = cleanSearchQuery(raw);
    if (!isSearchable(query)) return;
    const key = searchKey(query);
    this.save([query, ...this.list().filter((q) => searchKey(q) !== key)].slice(0, MAX_RECENT_SEARCHES));
  }

  remove(query: string): void {
    const key = searchKey(query);
    this.save(this.list().filter((q) => searchKey(q) !== key));
  }

  clear(): void {
    this.save([]);
  }

  private save(list: readonly string[]): void {
    this.list.set(list);
    if (!this.isBrowser) return;
    try {
      if (list.length) storage()?.setItem(STORAGE_KEY, JSON.stringify(list));
      else storage()?.removeItem(STORAGE_KEY);
    } catch {
      /* storage full or blocked: keep them for this visit */
    }
  }

  private read(): readonly string[] {
    if (!this.isBrowser) return [];
    try {
      const stored: unknown = JSON.parse(storage()?.getItem(STORAGE_KEY) ?? '[]');
      if (!Array.isArray(stored)) return [];
      const seen = new Set<string>();
      const list: string[] = [];
      for (const value of stored) {
        if (typeof value !== 'string') continue;
        const query = cleanSearchQuery(value);
        const key = searchKey(query);
        if (!isSearchable(query) || seen.has(key)) continue;
        seen.add(key);
        list.push(query);
      }
      return list.slice(0, MAX_RECENT_SEARCHES);
    } catch {
      return [];
    }
  }
}
