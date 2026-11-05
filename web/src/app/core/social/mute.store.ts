import { Injectable, InjectionToken, Provider, WritableSignal, computed, effect, inject, signal, untracked } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { Observable, firstValueFrom } from 'rxjs';
import { MutesApi } from '../api/mutes.api';
import { ArticleCardDto, ContentMutesDto, MutesDto } from '../api/models';
import { SessionStore } from '../auth/session.store';
import { ErrorMessages } from '../i18n/error-messages';
import { isolate } from '../../shared/directives/bidi';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { FollowStore } from './follow.store';

/**
 * How a list of post cards treats mutes (docs/api/contract-v1.md, "Where mutes apply"). Feeds, Related, tag and field
 * pages apply them: a card you muted (its writer, field or topic) or pressed "Show less" on leaves the list at once,
 * and comes back in place on Undo. The writer's own pages keep everything: you opened them on purpose.
 */
export interface MuteScope {
  /** False on the writer's own pages (profile tabs, category pages). */
  readonly applies: boolean;
  /** A field page's own field and the topic picked on it stay shown; its other muted topics leave. */
  readonly shownFieldId?: () => string | null;
  readonly shownTopicId?: () => string | null;
}

/** The scope of the post cards below; lists that provide none apply mutes. */
export const MUTE_SCOPE = new InjectionToken<MuteScope>('MUTE_SCOPE', { factory: () => ({ applies: true }) });

/** For the writer's own pages (profile tabs, category pages): muted writers, fields and topics stay listed. */
export function keepMutedContent(): Provider {
  return { provide: MUTE_SCOPE, useValue: { applies: false } satisfies MuteScope };
}

/** The writer whose mute changes: the toasts name them. */
export interface MutedAuthorRef {
  id: string;
  displayName: string;
}

/**
 * What the signed-in reader muted (F28), shared by every card, the reader, profiles, comments and Settings → Muted, so
 * a mute in one place shows everywhere at once. The API's viewer flags (`isAuthorMuted`, `isFieldMuted`,
 * `isTopicMuted`, `ProfileDto.isMuted`) are the starting point; the session's changes go on top. Changes are
 * optimistic: a failure puts the old state back and shows the translated error. Muting a writer ends your follow of
 * them (FollowStore learns it), its Undo follows again, and following a muted writer ends the mute.
 */
@Injectable({ providedIn: 'root' })
export class MuteStore {
  private readonly api = inject(MutesApi);
  private readonly follows = inject(FollowStore);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly session = inject(SessionStore);

  /** Writers muted (true) or unmuted (false) in this session. */
  private readonly authors = signal<ReadonlyMap<string, boolean>>(new Map());
  /** Fields and topics toggled in this session, until the API's list of them all arrives. */
  private readonly fieldChanges = signal<ReadonlyMap<string, boolean>>(new Map());
  private readonly topicChanges = signal<ReadonlyMap<string, boolean>>(new Map());
  /** Every muted field and topic, once an answer (`ContentMutesDto`, `GET /me/mutes`) listed them. */
  private readonly content = signal<{ fieldIds: ReadonlySet<string>; topicIds: ReadonlySet<string> } | null>(null);
  /** Articles marked "Show less" in this session. */
  private readonly less = signal<ReadonlySet<string>>(new Set());
  /** One request per writer, field, topic or article at a time. */
  private readonly inFlight = new Set<string>();

  constructor() {
    const userId = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null));
    let previous: string | null | undefined;
    effect(() => {
      const current = userId();
      if (previous !== undefined && previous !== current) untracked(() => this.reset());
      previous = current;
    });
    // `PUT /users/{id}/follow` ends a mute of that writer (contract: the two never hold at once).
    this.follows.onFollowed((id) => this.setAuthor(id, false));
  }

  /** Whether you muted the writer; `fallback` is the API's flag on the card, details, comment or profile. */
  isAuthorMuted(userId: string, fallback = false): boolean {
    return this.authors().get(userId) ?? fallback;
  }

  isFieldMuted(fieldId: string, fallback = false): boolean {
    const changed = this.fieldChanges().get(fieldId);
    if (changed !== undefined) return changed;
    return this.content()?.fieldIds.has(fieldId) ?? fallback;
  }

  isTopicMuted(topicId: string, fallback = false): boolean {
    const changed = this.topicChanges().get(topicId);
    if (changed !== undefined) return changed;
    return this.content()?.topicIds.has(topicId) ?? fallback;
  }

  /** The card leaves a list in `scope`: its writer, field or topic is muted, or you pressed Show less on it. */
  hides(card: ArticleCardDto, scope: MuteScope): boolean {
    if (!scope.applies || !this.session.isAuthenticated()) return false;
    if (this.less().has(card.id)) return true;
    if (card.author && this.isAuthorMuted(card.author.id, card.isAuthorMuted)) return true;
    if (card.field.id !== scope.shownFieldId?.() && this.isFieldMuted(card.field.id, card.isFieldMuted)) return true;
    const topic = card.topic;
    return !!topic && topic.id !== scope.shownTopicId?.() && this.isTopicMuted(topic.id, card.isTopicMuted);
  }

  /**
   * Whether any of `cards` is still shown in `scope`. Muted cards stay in their list (so Undo puts them back in place),
   * so empty states and section headings count these instead: a list whose cards all left shows its empty state.
   */
  anyShown(cards: readonly ArticleCardDto[], scope: MuteScope): boolean {
    return cards.some((card) => !this.hides(card, scope));
  }

  /** Settings → Muted loaded `GET /me/mutes`: the truth for everything in it. */
  learn(mutes: MutesDto): void {
    this.authors.update((map) => {
      const next = new Map(map);
      for (const user of mutes.users) next.set(user.id, true);
      return next;
    });
    this.absorbContent({ fieldIds: mutes.fields.map((f) => f.id), topicIds: mutes.topics.map((t) => t.id) });
  }

  /**
   * "كتم الكاتب": the writer's cards leave the lists at once, then a toast with Undo (which follows them again when the
   * mute ended your follow). Resolves to whether the mute was saved.
   */
  async muteAuthor(author: MutedAuthorRef): Promise<boolean> {
    const key = `user:${author.id}`;
    if (this.inFlight.has(key)) return false;
    const before = this.authors().get(author.id);
    this.inFlight.add(key);
    this.setAuthor(author.id, true);
    try {
      const result = await firstValueFrom(this.api.muteUser(author.id));
      this.follows.learn(author.id, result.isFollowing);
      this.toasts.info(this.transloco.translate('mute.toast.muted', { name: isolate(author.displayName) }), null, {
        label: this.transloco.translate('mute.undo'),
        run: () => void this.unmuteAuthor(author, { restoreFollow: result.followRemoved, toast: false }),
      });
      return true;
    } catch (error) {
      this.restoreAuthor(author.id, before);
      this.toasts.error(this.errors.forError(error));
      return false;
    } finally {
      this.inFlight.delete(key);
    }
  }

  /**
   * "إلغاء الكتم" (the banner, Settings → Muted) or a mute's Undo (`restoreFollow` when the mute ended your follow).
   * Resolves to whether it was saved.
   */
  async unmuteAuthor(author: MutedAuthorRef, options: { restoreFollow?: boolean; toast?: boolean } = {}): Promise<boolean> {
    const key = `user:${author.id}`;
    if (this.inFlight.has(key)) return false;
    const before = this.authors().get(author.id);
    this.inFlight.add(key);
    this.setAuthor(author.id, false);
    try {
      const result = await firstValueFrom(this.api.unmuteUser(author.id, options.restoreFollow ?? false));
      this.follows.learn(author.id, result.isFollowing);
      if (options.toast !== false) this.toasts.success(this.transloco.translate('mute.toast.unmuted', { name: isolate(author.displayName) }));
      return true;
    } catch (error) {
      this.restoreAuthor(author.id, before);
      this.toasts.error(this.errors.forError(error));
      return false;
    } finally {
      this.inFlight.delete(key);
    }
  }

  /** "قلّل من النوع ده": the card leaves the lists at once, then a toast with Undo. */
  async showLess(articleId: string): Promise<boolean> {
    const key = `less:${articleId}`;
    if (this.inFlight.has(key) || this.less().has(articleId)) return false;
    this.inFlight.add(key);
    this.setLess(articleId, true);
    try {
      await firstValueFrom(this.api.showLess(articleId));
      this.toasts.info(this.transloco.translate('mute.toast.showLess'), null, {
        label: this.transloco.translate('mute.undo'),
        run: () => void this.undoShowLess(articleId),
      });
      return true;
    } catch (error) {
      this.setLess(articleId, false);
      this.toasts.error(this.errors.forError(error));
      return false;
    } finally {
      this.inFlight.delete(key);
    }
  }

  /** The Show less toast's Undo: the card comes back in place. */
  async undoShowLess(articleId: string): Promise<boolean> {
    const key = `less:${articleId}`;
    if (this.inFlight.has(key)) return false;
    this.inFlight.add(key);
    this.setLess(articleId, false);
    try {
      await firstValueFrom(this.api.undoShowLess(articleId));
      return true;
    } catch (error) {
      this.setLess(articleId, true);
      this.toasts.error(this.errors.forError(error));
      return false;
    } finally {
      this.inFlight.delete(key);
    }
  }

  /** A toggle of the "كتم المواضيع" sheet or Settings → Muted. Resolves to whether it was saved. */
  setFieldMuted(fieldId: string, muted: boolean): Promise<boolean> {
    return this.toggleContent(`field:${fieldId}`, this.fieldChanges, fieldId, muted, () => this.api.setFieldMuted(fieldId, muted));
  }

  setTopicMuted(topicId: string, muted: boolean): Promise<boolean> {
    return this.toggleContent(`topic:${topicId}`, this.topicChanges, topicId, muted, () => this.api.setTopicMuted(topicId, muted));
  }

  private async toggleContent(
    key: string,
    changes: WritableSignal<ReadonlyMap<string, boolean>>,
    id: string,
    muted: boolean,
    request: () => Observable<ContentMutesDto>,
  ): Promise<boolean> {
    if (this.inFlight.has(key)) return false;
    this.inFlight.add(key);
    changes.update((map) => new Map(map).set(id, muted));
    try {
      const saved = await firstValueFrom(request());
      changes.update((map) => {
        const next = new Map(map);
        next.delete(id);
        return next;
      });
      this.absorbContent(saved);
      return true;
    } catch (error) {
      changes.update((map) => {
        const next = new Map(map);
        next.delete(id);
        return next;
      });
      this.toasts.error(this.errors.forError(error));
      return false;
    } finally {
      this.inFlight.delete(key);
    }
  }

  private absorbContent(mutes: ContentMutesDto): void {
    this.content.set({ fieldIds: new Set(mutes.fieldIds), topicIds: new Set(mutes.topicIds) });
  }

  private setAuthor(id: string, muted: boolean): void {
    this.authors.update((map) => new Map(map).set(id, muted));
  }

  private restoreAuthor(id: string, before: boolean | undefined): void {
    this.authors.update((map) => {
      const next = new Map(map);
      if (before === undefined) next.delete(id);
      else next.set(id, before);
      return next;
    });
  }

  private setLess(articleId: string, on: boolean): void {
    this.less.update((ids) => {
      const next = new Set(ids);
      if (on) next.add(articleId);
      else next.delete(articleId);
      return next;
    });
  }

  private reset(): void {
    this.authors.set(new Map());
    this.fieldChanges.set(new Map());
    this.topicChanges.set(new Map());
    this.content.set(null);
    this.less.set(new Set());
  }
}
