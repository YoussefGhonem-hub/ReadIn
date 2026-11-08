import { Injectable, computed, effect, inject, signal, untracked } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { firstValueFrom } from 'rxjs';
import { BlocksApi } from '../api/blocks.api';
import { SessionStore } from '../auth/session.store';
import { ErrorMessages } from '../i18n/error-messages';
import { isolate } from '../../shared/directives/bidi';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { FollowStore } from './follow.store';

/** The person a block concerns: the dialog and the toasts name them. */
export interface BlockedPersonRef {
  id: string;
  displayName: string;
  username: string;
}

/**
 * Who the signed-in member blocked in this session (F36), shared by every card, the reader, profiles, comments, the
 * report sheet ("Also block") and Settings → Blocked accounts, so a block in one place shows everywhere at once. The API
 * already leaves people blocked before out of every list; this only covers what changes now. Blocking ends your follow
 * (FollowStore learns it), and its toast's Undo unblocks and follows again. Changes are optimistic: a failure puts the
 * old state back with the translated error.
 */
@Injectable({ providedIn: 'root' })
export class BlockStore {
  private readonly api = inject(BlocksApi);
  private readonly follows = inject(FollowStore);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly session = inject(SessionStore);

  /** People blocked (true) or unblocked (false) in this session. */
  private readonly changes = signal<ReadonlyMap<string, boolean>>(new Map());
  private readonly inFlight = new Set<string>();

  constructor() {
    const userId = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null));
    let previous: string | null | undefined;
    effect(() => {
      const current = userId();
      if (previous !== undefined && previous !== current) untracked(() => this.changes.set(new Map()));
      previous = current;
    });
  }

  /** Whether you blocked them; `fallback` is what the page knows (a `403 block.blocked`, the Settings list). */
  isBlocked(userId: string, fallback = false): boolean {
    return this.changes().get(userId) ?? fallback;
  }

  /** The report sheet blocked them together with the report ("Also block", F22): the API did it, so only learn it. */
  learnBlocked(userId: string): void {
    this.set(userId, true);
    this.follows.learn(userId, false);
  }

  /**
   * "حظر" after the dialog: their content leaves the lists at once, then a toast with Undo (which unblocks and follows
   * again when the block ended your follow). Resolves to whether the block was saved.
   */
  async block(person: BlockedPersonRef): Promise<boolean> {
    if (this.inFlight.has(person.id)) return false;
    const before = this.changes().get(person.id);
    this.inFlight.add(person.id);
    this.set(person.id, true);
    try {
      const result = await firstValueFrom(this.api.block(person.id));
      this.follows.learn(person.id, false);
      this.toasts.info(this.transloco.translate('block.toast.blocked', { name: isolate(person.displayName) }), null, {
        label: this.transloco.translate('block.undo'),
        run: () => void this.unblock(person, { restoreFollow: result.followRemoved, toast: false }),
      });
      return true;
    } catch (error) {
      this.restore(person.id, before);
      this.toasts.error(this.errors.forError(error));
      return false;
    } finally {
      this.inFlight.delete(person.id);
    }
  }

  /** "إلغاء الحظر" (an unavailable page, Settings → Blocked accounts) or a block's Undo. Resolves to whether it was saved. */
  async unblock(person: BlockedPersonRef, options: { restoreFollow?: boolean; toast?: boolean } = {}): Promise<boolean> {
    if (this.inFlight.has(person.id)) return false;
    const before = this.changes().get(person.id);
    this.inFlight.add(person.id);
    this.set(person.id, false);
    try {
      await firstValueFrom(this.api.unblock(person.id, options.restoreFollow ?? false));
      if (options.restoreFollow) this.follows.learn(person.id, true);
      if (options.toast !== false) this.toasts.success(this.transloco.translate('block.toast.unblocked', { name: isolate(person.displayName) }));
      return true;
    } catch (error) {
      this.restore(person.id, before);
      this.toasts.error(this.errors.forError(error));
      return false;
    } finally {
      this.inFlight.delete(person.id);
    }
  }

  private set(id: string, blocked: boolean): void {
    this.changes.update((map) => new Map(map).set(id, blocked));
  }

  private restore(id: string, before: boolean | undefined): void {
    this.changes.update((map) => {
      const next = new Map(map);
      if (before === undefined) next.delete(id);
      else next.set(id, before);
      return next;
    });
  }
}
