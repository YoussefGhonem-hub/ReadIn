import { Injectable, PendingTasks, computed, inject, signal } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { Observable, firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { ExploreApi } from '../../core/api/explore.api';
import { FollowsApi } from '../../core/api/follows.api';
import { FieldPageDto, FieldPageTopicDto, InterestsDto, UserSummaryDto } from '../../core/api/models';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { CardPages } from './card-pages';

export type FieldPageStatus = 'loading' | 'loaded' | 'notFound' | 'error';
export type WritersStatus = 'loading' | 'loaded' | 'error';

export const FIELD_PAGE_SIZE = 20;
export const TOP_WRITERS = 10;

const sameSlug = (a: string | null, b: string | null) => (a ?? '').toLowerCase() === (b ?? '').toLowerCase();

/**
 * A field page (F15): the header with its topic chips (`GET /fields/{slug}`), "Top writers in this field"
 * (`/fields/{slug}/writers`) and the field's articles, or one topic's (`/fields/{slug}/articles?topic=`), newest
 * first in cursor pages. All three load together and are server-rendered. Choosing a topic loads only the articles.
 * Following the field or a topic shows at once (the follower count moves by 1) and is saved with the F12 interests
 * endpoints; a refusal undoes it and says why (`user.interests.min_three`: at least 3 interests stay, so the toggle
 * stays on).
 */
@Injectable()
export class FieldPageStore {
  private readonly api = inject(ExploreApi);
  private readonly follows = inject(FollowsApi);
  private readonly session = inject(SessionStore);
  private readonly tasks = inject(PendingTasks);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);

  readonly status = signal<FieldPageStatus>('loading');
  readonly field = signal<FieldPageDto | null>(null);
  readonly writers = signal<UserSummaryDto[]>([]);
  readonly writersStatus = signal<WritersStatus>('loading');
  /** The topic slug the URL asks for (null: the whole field). */
  readonly topic = signal<string | null>(null);
  readonly articles = new CardPages();
  /** Follow taps on their way to the API (`field`, or a topic id); another tap on one waits until it is done. */
  readonly busy = signal<ReadonlySet<string>>(new Set());

  /** The chosen topic's chip, once the header is here (null for the whole field, or a topic that isn't the field's). */
  readonly selectedTopic = computed(() => {
    const topic = this.topic();
    return topic ? (this.field()?.topics.find((t) => sameSlug(t.slug, topic)) ?? null) : null;
  });
  /** The URL names a topic this field doesn't have (`404 topic.not_found`). */
  readonly topicNotFound = computed(() => {
    const error = this.articles.error();
    return this.articles.status() === 'error' && isApiError(error) && error.code === 'topic.not_found';
  });

  private slug: string | null = null;
  private generation = 0;

  /** Shows `/f/{slug}?topic=`: everything for another field, only the articles for another topic of this one. */
  open(slug: string, topic: string | null): Promise<void> {
    if (this.slug !== null && sameSlug(this.slug, slug) && this.status() === 'loaded') {
      if (sameSlug(this.topic(), topic)) return Promise.resolve();
      this.topic.set(topic);
      return this.loadArticles();
    }
    return this.load(slug, topic);
  }

  /** The header, the writers and the first page of articles (also the retry). */
  async load(slug: string | null = this.slug, topic: string | null = this.topic()): Promise<void> {
    if (!slug) return;
    this.slug = slug;
    this.topic.set(topic);
    const generation = ++this.generation;
    this.status.set('loading');
    this.field.set(null);
    this.writers.set([]);
    this.busy.set(new Set());
    const done = this.tasks.add();
    try {
      const [field] = await Promise.allSettled([firstValueFrom(this.api.field(slug)), this.loadArticles(), this.loadWriters()]);
      if (generation !== this.generation) return;
      if (field.status === 'rejected') {
        this.status.set(isApiError(field.reason) && field.reason.status === 404 ? 'notFound' : 'error');
        return;
      }
      this.field.set(field.value);
      this.status.set('loaded');
    } finally {
      done();
    }
  }

  /** The articles of the chosen topic (or the whole field), from the first page. */
  loadArticles(): Promise<void> {
    const slug = this.slug;
    const topic = this.topic();
    if (!slug) return Promise.resolve();
    return this.articles.load((cursor) => this.api.fieldArticles(slug, { topic, cursor, limit: FIELD_PAGE_SIZE }));
  }

  /** "Top writers in this field" (also its retry). */
  async loadWriters(): Promise<void> {
    const slug = this.slug;
    if (!slug) return;
    const generation = this.generation;
    this.writersStatus.set('loading');
    const done = this.tasks.add();
    try {
      const writers = await firstValueFrom(this.api.fieldWriters(slug, TOP_WRITERS));
      if (generation !== this.generation) return;
      this.writers.set(writers);
      this.writersStatus.set('loaded');
    } catch {
      if (generation === this.generation) this.writersStatus.set('error');
    } finally {
      done();
    }
  }

  /**
   * Everything again with your token (after hydration, or signing in or out), keeping the page on screen until each
   * part answers; a page that had failed loads from scratch.
   */
  async refresh(): Promise<void> {
    const slug = this.slug;
    if (!slug) return;
    if (this.status() !== 'loaded') return this.load(slug);
    const generation = ++this.generation;
    this.busy.set(new Set());
    await Promise.all([
      firstValueFrom(this.api.field(slug)).then(
        (field) => generation === this.generation && this.field.set(field),
        () => undefined, // keep what is shown
      ),
      firstValueFrom(this.api.fieldWriters(slug, TOP_WRITERS)).then(
        (writers) => {
          if (generation !== this.generation) return;
          this.writers.set(writers);
          this.writersStatus.set('loaded');
        },
        () => undefined,
      ),
      this.articles.refresh(),
    ]);
  }

  /** Follow or unfollow the field; `followerCount` moves with it. */
  toggleField(): Promise<void> {
    const field = this.field();
    if (!field) return Promise.resolve();
    const follow = !field.isFollowing;
    return this.save(
      'field',
      follow,
      (on) => this.patchField((f) => ({ ...f, isFollowing: on, followerCount: Math.max(0, f.followerCount + (on === f.isFollowing ? 0 : on ? 1 : -1)) })),
      () => (follow ? this.follows.followField(field.id) : this.follows.unfollowField(field.id)),
    );
  }

  /** Follow or unfollow one of the field's topics. */
  toggleTopic(topic: FieldPageTopicDto): Promise<void> {
    const current = this.field()?.topics.find((t) => t.id === topic.id);
    if (!current) return Promise.resolve();
    const follow = !current.isFollowing;
    return this.save(
      topic.id,
      follow,
      (on) => this.patchField((f) => ({ ...f, topics: f.topics.map((t) => (t.id === topic.id ? { ...t, isFollowing: on } : t)) })),
      () => (follow ? this.follows.followTopic(topic.id) : this.follows.unfollowTopic(topic.id)),
    );
  }

  /** Shows the change at once; the API's answer becomes the session's interests, a refusal undoes the change. */
  private async save(key: string, follow: boolean, show: (on: boolean) => void, request: () => Observable<InterestsDto>): Promise<void> {
    if (this.busy().has(key)) return;
    const generation = this.generation;
    this.busy.update((keys) => new Set(keys).add(key));
    show(follow);
    try {
      const saved = await firstValueFrom(request());
      // Home's For you and the suggested writers follow your interests.
      this.session.patchMe({ interests: { fieldIds: [...saved.fieldIds], topicIds: [...saved.topicIds] } });
    } catch (error) {
      if (generation === this.generation) show(!follow);
      this.toasts.error(
        isApiError(error) && error.code === 'user.interests.min_three' ? this.transloco.translate('fields.page.minThree') : this.errors.forError(error),
      );
    } finally {
      if (generation === this.generation) {
        this.busy.update((keys) => {
          const next = new Set(keys);
          next.delete(key);
          return next;
        });
      }
    }
  }

  private patchField(change: (field: FieldPageDto) => FieldPageDto): void {
    const field = this.field();
    if (field) this.field.set(change(field));
  }
}
