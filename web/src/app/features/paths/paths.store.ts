import { Injectable, PendingTasks, computed, effect, inject, signal, untracked } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ActivatedRoute } from '@angular/router';
import { firstValueFrom, map } from 'rxjs';
import { FieldRefDto, PathCardDto } from '../../core/api/models';
import { PathsApi } from '../../core/api/paths.api';
import { SessionStore } from '../../core/auth/session.store';

export type PathsTab = 'all' | 'mine';
export type PathsStatus = 'idle' | 'loading' | 'loaded' | 'error';

interface PathList {
  items: PathCardDto[];
  status: PathsStatus;
}

/** The fields present in a list, in the order they first appear (the field chips). */
export function fieldsOf(paths: readonly PathCardDto[]): FieldRefDto[] {
  const seen = new Map<string, FieldRefDto>();
  for (const path of paths) if (!seen.has(path.field.id)) seen.set(path.field.id, path.field);
  return [...seen.values()];
}

/**
 * The paths list (F09): All paths (`GET /paths`, server-rendered for guests) and My paths (`GET /me/paths`, signed in
 * only), with a field filter applied locally on whichever list is open. A reload keeps the cards on screen; an answer
 * for an older request is dropped.
 */
@Injectable()
export class PathsStore {
  private readonly api = inject(PathsApi);
  private readonly tasks = inject(PendingTasks);
  private readonly lists = { all: signal<PathList>({ items: [], status: 'idle' }), mine: signal<PathList>({ items: [], status: 'idle' }) };
  private readonly generations = { all: 0, mine: 0 };

  readonly tab = signal<PathsTab>('all');
  /** Field slug; ignored when the open list has no path in that field. */
  readonly field = signal<string | null>(null);

  private readonly current = computed(() => this.lists[this.tab()]());
  readonly status = computed(() => this.current().status);
  readonly fields = computed(() => fieldsOf(this.current().items));
  readonly selectedField = computed(() => {
    const slug = this.field();
    return slug && this.fields().some((f) => f.slug === slug) ? slug : null;
  });
  readonly visible = computed(() => {
    const slug = this.selectedField();
    const items = this.current().items;
    return slug ? items.filter((p) => p.field.slug === slug) : items;
  });

  constructor() {
    // `/paths?tab=mine` (the top bar's Me menu → "My paths") opens My paths once you are signed in.
    const route = inject(ActivatedRoute, { optional: true });
    if (!route) return;
    const session = inject(SessionStore);
    const wantsMine = toSignal(route.queryParamMap.pipe(map((params) => params.get('tab') === 'mine')), { initialValue: false });
    effect(() => {
      if (wantsMine() && session.isAuthenticated()) untracked(() => this.setTab('mine'));
    });
  }

  loadAll(): Promise<void> {
    return this.load('all', () => this.api.list());
  }

  loadMine(): Promise<void> {
    return this.load('mine', () => this.api.mine());
  }

  /** Opens a tab; My paths loads the first time (callers check the session first). */
  setTab(tab: PathsTab): void {
    this.tab.set(tab);
    if (this.lists[tab]().status === 'idle') void (tab === 'all' ? this.loadAll() : this.loadMine());
  }

  setField(slug: string | null): void {
    this.field.set(slug);
  }

  /** Signing out forgets My paths. */
  forgetMine(): void {
    this.generations.mine++;
    this.lists.mine.set({ items: [], status: 'idle' });
    if (this.tab() === 'mine') this.tab.set('all');
  }

  retry(): Promise<void> {
    return this.tab() === 'all' ? this.loadAll() : this.loadMine();
  }

  private async load(tab: PathsTab, request: () => ReturnType<PathsApi['list']>): Promise<void> {
    const generation = ++this.generations[tab];
    const list = this.lists[tab];
    // A reload (e.g. personalized after hydration) keeps the cards; only the first load shows the skeletons.
    if (list().status !== 'loaded') list.set({ items: [], status: 'loading' });
    // SSR waits until the list is in state, not just until the HTTP call ends.
    const done = this.tasks.add();
    try {
      const items = await firstValueFrom(request());
      if (generation === this.generations[tab]) list.set({ items, status: 'loaded' });
    } catch {
      if (generation === this.generations[tab]) list.set({ items: [], status: 'error' });
    } finally {
      done();
    }
  }
}
