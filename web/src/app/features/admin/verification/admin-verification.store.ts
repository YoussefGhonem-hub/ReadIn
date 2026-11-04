import { Injectable, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../../core/api/api.config';
import { AdminVerificationRequestDto, VerificationStatus } from '../../../core/api/models';
import { VerificationApi } from '../../../core/api/verification.api';

export const ADMIN_VERIFICATION_PAGE_SIZE = 20;

/** Approve, or reject with the reviewer's reason. */
export type VerificationDecision = { kind: 'approve' } | { kind: 'reject'; reason: string };

/**
 * The admins' review list (F19), one tab at a time: `GET /admin/verification-requests?status=` in cursor pages (a newer
 * load wins over a slower older one; a failed page can be retried). A decision takes the request off the list at once
 * and puts it back where it was when the API refuses. Provided by the page.
 */
@Injectable()
export class AdminVerificationStore {
  private readonly api = inject(VerificationApi);

  readonly tab = signal<VerificationStatus>('pending');
  readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  readonly items = signal<AdminVerificationRequestDto[]>([]);
  readonly nextCursor = signal<string | null>(null);
  readonly loadingMore = signal(false);
  readonly moreFailed = signal(false);
  private generation = 0;

  async load(tab: VerificationStatus = this.tab()): Promise<void> {
    const generation = ++this.generation;
    this.tab.set(tab);
    this.status.set('loading');
    this.items.set([]);
    this.nextCursor.set(null);
    this.loadingMore.set(false);
    this.moreFailed.set(false);
    try {
      const page = await firstValueFrom(this.api.list({ status: tab, limit: ADMIN_VERIFICATION_PAGE_SIZE }));
      if (generation !== this.generation) return;
      this.items.set(page.items ?? []);
      this.nextCursor.set(page.nextCursor ?? null);
      this.status.set('loaded');
    } catch {
      if (generation === this.generation) this.status.set('error');
    }
  }

  async loadMore(): Promise<void> {
    const cursor = this.nextCursor();
    if (!cursor || this.loadingMore() || this.status() !== 'loaded') return;
    const generation = this.generation;
    this.loadingMore.set(true);
    this.moreFailed.set(false);
    try {
      const page = await firstValueFrom(this.api.list({ status: this.tab(), cursor, limit: ADMIN_VERIFICATION_PAGE_SIZE }));
      if (generation !== this.generation) return;
      const seen = new Set(this.items().map((item) => item.id));
      this.items.update((items) => [...items, ...(page.items ?? []).filter((item) => !seen.has(item.id))]);
      this.nextCursor.set(page.nextCursor ?? null);
    } catch {
      if (generation === this.generation) this.moreFailed.set(true);
    } finally {
      if (generation === this.generation) this.loadingMore.set(false);
    }
  }

  find(id: string | null | undefined): AdminVerificationRequestDto | null {
    return id ? (this.items().find((item) => item.id === id) ?? null) : null;
  }

  /**
   * Approves or rejects `item`: off the list at once, then the API. A refusal puts it back at its place and is
   * rethrown; when someone else decided it first (`409 verification.already_decided`) or it is gone (`404`), the tab
   * loads again instead.
   */
  async decide(item: AdminVerificationRequestDto, decision: VerificationDecision): Promise<void> {
    const index = this.items().findIndex((i) => i.id === item.id);
    const generation = this.generation;
    if (index >= 0) this.items.update((items) => items.filter((i) => i.id !== item.id));
    try {
      await firstValueFrom(decision.kind === 'approve' ? this.api.approve(item.id) : this.api.reject(item.id, decision.reason));
    } catch (error) {
      if (isApiError(error) && (error.code === 'verification.already_decided' || error.code === 'verification.not_found')) {
        void this.load();
      } else if (index >= 0 && generation === this.generation && !this.find(item.id)) {
        this.items.update((items) => [...items.slice(0, index), item, ...items.slice(index)]);
      }
      throw error;
    }
  }
}
