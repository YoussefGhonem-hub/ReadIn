import { Injectable, computed, effect, inject, signal, untracked } from '@angular/core';
import type { ModerationTargetType } from '../api/models';
import { SessionStore } from '../auth/session.store';

/**
 * "You reported this. It's hidden for you" (F22, store requirements): what the signed-in member reported in this session
 * and what they chose to show again ("عرض"). The API's `reportedByMe` flag on cards, the reader, comments and repost
 * labels is the starting point; a report sent now collapses its target at once, everywhere it is on screen. A reported
 * user stays visible (only a block hides people).
 */
@Injectable({ providedIn: 'root' })
export class ReportedStore {
  private readonly session = inject(SessionStore);
  private readonly reported = signal<ReadonlySet<string>>(new Set());
  private readonly shown = signal<ReadonlySet<string>>(new Set());

  constructor() {
    const userId = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null));
    let previous: string | null | undefined;
    effect(() => {
      const current = userId();
      if (previous !== undefined && previous !== current) {
        untracked(() => {
          this.reported.set(new Set());
          this.shown.set(new Set());
        });
      }
      previous = current;
    });
  }

  /** Collapsed for you: reported (the API's flag, or a report now) and not shown again with "عرض". */
  isCollapsed(type: ModerationTargetType, id: string, reportedByMe = false): boolean {
    if (!this.session.isAuthenticated() || type === 'user') return false;
    const key = `${type}:${id}`;
    return (reportedByMe || this.reported().has(key)) && !this.shown().has(key);
  }

  /** The report sheet sent a report. */
  markReported(type: ModerationTargetType, id: string): void {
    const key = `${type}:${id}`;
    this.reported.update((set) => new Set(set).add(key));
    this.shown.update((set) => {
      const next = new Set(set);
      next.delete(key);
      return next;
    });
  }

  /** "عرض": shows it here again (it stays reported). */
  show(type: ModerationTargetType, id: string): void {
    this.shown.update((set) => new Set(set).add(`${type}:${id}`));
  }
}
