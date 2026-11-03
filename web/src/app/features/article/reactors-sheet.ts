import { ChangeDetectionStrategy, Component, computed, effect, inject, input, output, signal, untracked } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { firstValueFrom } from 'rxjs';
import { REACTION_TYPES, ReactionCountsDto, ReactionType, ReactorDto } from '../../core/api/models';
import { ReactionsApi } from '../../core/api/reactions.api';
import { LanguageService } from '../../core/i18n/language.service';
import { CompactNumberPipe } from '../../shared/pipes/format.pipes';
import { UserRow } from '../../shared/social/user-row';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ErrorState } from '../../shared/ui/states';
import { REACTION_EMOJI } from './reactions';

const PAGE_SIZE = 20;

interface ReactorsTab {
  /** null = all reactions. */
  type: ReactionType | null;
  key: string;
  count: number;
}

interface TabState {
  items: ReactorDto[];
  nextCursor: string | null;
  status: 'loading' | 'loaded' | 'error';
  loadingMore: boolean;
  moreFailed: boolean;
}

/** "Who reacted" (F10): a tab per reaction type with its count, paged newest first. Open to guests too. */
@Component({
  selector: 'rd-reactors-sheet',
  imports: [TranslocoPipe, CompactNumberPipe, BottomSheet, ErrorState, UserRow],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" labelledBy="reactors-title" (closed)="closed.emit()">
      <div data-reactors-sheet>
        <h2 id="reactors-title" class="m-0 pe-10 text-xl font-semibold">{{ 'article.reactions.whoReacted' | transloco }}</h2>

        <div class="-mx-1 mt-3 flex gap-1 overflow-x-auto border-b border-border px-1" role="tablist" [attr.aria-label]="'article.reactions.label' | transloco">
          @for (tab of tabs(); track tab.key) {
            <button
              type="button"
              role="tab"
              [id]="'reactors-tab-' + tab.key"
              aria-controls="reactors-panel"
              [attr.aria-selected]="active() === tab.type"
              [attr.tabindex]="active() === tab.type ? 0 : -1"
              [attr.data-reactors-tab]="tab.key"
              class="-mb-px inline-flex min-h-11 shrink-0 items-center gap-1.5 border-b-2 px-3 text-sm"
              [class]="active() === tab.type ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary'"
              (click)="select(tab.type)"
              (keydown)="onTabKey($event)"
            >
              @if (tab.type) {
                <span class="text-base leading-none" aria-hidden="true">{{ emoji[tab.type] }}</span>
                <span class="sr-only">{{ 'article.reactions.' + tab.type | transloco }}</span>
              } @else {
                {{ 'article.reactions.all' | transloco }}
              }
              <span>{{ tab.count | rdCompactNumber: lang() }}</span>
            </button>
          }
        </div>

        <div id="reactors-panel" role="tabpanel" [attr.aria-labelledby]="'reactors-tab-' + activeKey()" class="min-h-56 pt-2" tabindex="-1">
          @switch (current()?.status) {
            @case ('error') {
              <rd-error-state [message]="'article.reactions.loadError' | transloco" (retry)="reload()" />
            }
            @case ('loaded') {
              <ul class="m-0 list-none p-0" data-reactors-list>
                @for (reactor of current()!.items; track reactor.user.id) {
                  <li data-reactor>
                    <rd-user-row [user]="reactor.user">
                      <span class="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-surface-variant text-lg leading-none" role="img" [attr.aria-label]="'article.reactions.' + reactor.type | transloco">
                        {{ emoji[reactor.type] }}
                      </span>
                    </rd-user-row>
                  </li>
                } @empty {
                  <li class="py-10 text-center text-sm text-text-secondary">{{ 'article.reactions.empty' | transloco }}</li>
                }
              </ul>
              @if (current()!.nextCursor || current()!.moreFailed) {
                <button type="button" class="rd-btn rd-btn-outline mt-2 w-full" [disabled]="current()!.loadingMore" [attr.aria-busy]="current()!.loadingMore" data-reactors-more (click)="more()">
                  {{ (current()!.moreFailed ? 'common.retry' : 'article.reactions.more') | transloco }}
                </button>
              }
            }
            @default {
              <div class="flex flex-col gap-3 py-2" aria-busy="true">
                @for (i of [1, 2, 3, 4]; track i) {
                  <div class="flex items-center gap-3" aria-hidden="true">
                    <div class="rd-skeleton h-10 w-10 rounded-full"></div>
                    <div class="flex flex-1 flex-col gap-2"><div class="rd-skeleton h-3 w-1/2"></div><div class="rd-skeleton h-3 w-1/3"></div></div>
                  </div>
                }
              </div>
            }
          }
        </div>
      </div>
    </rd-bottom-sheet>
  `,
})
export class ReactorsSheet {
  private readonly api = inject(ReactionsApi);
  private readonly language = inject(LanguageService);
  protected readonly lang = this.language.lang;
  protected readonly emoji = REACTION_EMOJI;

  readonly open = input(false);
  readonly articleId = input.required<string>();
  /** The counts the reader shows (they may be live). */
  readonly counts = input.required<ReactionCountsDto>();
  readonly total = input.required<number>();
  readonly closed = output<void>();

  protected readonly active = signal<ReactionType | null>(null);
  private readonly pages = signal<ReadonlyMap<string, TabState>>(new Map());
  private generation = 0;

  /** "All" plus every type someone used (and the open one, even if its count dropped to zero). */
  protected readonly tabs = computed<ReactorsTab[]>(() => {
    const counts = this.counts();
    const active = this.active();
    return [
      { type: null, key: 'all', count: this.total() },
      ...REACTION_TYPES.filter((type) => counts[type] > 0 || type === active).map((type) => ({ type, key: type, count: counts[type] })),
    ];
  });
  protected readonly activeKey = computed(() => this.active() ?? 'all');
  protected readonly current = computed(() => this.pages().get(this.activeKey()) ?? null);

  constructor() {
    effect(() => {
      const open = this.open();
      this.articleId();
      untracked(() => {
        this.generation++;
        this.pages.set(new Map());
        if (open) {
          this.active.set(null);
          void this.load(null);
        }
      });
    });
  }

  protected select(type: ReactionType | null): void {
    this.active.set(type);
    if (!this.pages().has(type ?? 'all')) void this.load(type);
  }

  protected reload(): void {
    void this.load(this.active());
  }

  /** Arrow keys move between tabs (mirrored in RTL), Home/End jump. */
  protected onTabKey(event: KeyboardEvent): void {
    const tabs = this.tabs();
    const index = tabs.findIndex((t) => t.type === this.active());
    const rtl = this.language.dir() === 'rtl';
    const forward = rtl ? 'ArrowLeft' : 'ArrowRight';
    const back = rtl ? 'ArrowRight' : 'ArrowLeft';
    let next = index;
    if (event.key === forward) next = (index + 1) % tabs.length;
    else if (event.key === back) next = (index - 1 + tabs.length) % tabs.length;
    else if (event.key === 'Home') next = 0;
    else if (event.key === 'End') next = tabs.length - 1;
    else return;
    event.preventDefault();
    this.select(tabs[next].type);
    queueMicrotask(() => (event.target as HTMLElement).parentElement?.querySelector<HTMLElement>(`#reactors-tab-${tabs[next].key}`)?.focus());
  }

  protected async more(): Promise<void> {
    const type = this.active();
    const key = type ?? 'all';
    const state = this.pages().get(key);
    if (!state || state.loadingMore || (!state.nextCursor && !state.moreFailed)) return;
    const generation = this.generation;
    this.patch(key, { loadingMore: true, moreFailed: false });
    try {
      const page = await firstValueFrom(this.api.reactors(this.articleId(), { type, cursor: state.nextCursor, limit: PAGE_SIZE }));
      if (generation !== this.generation) return;
      const seen = new Set(state.items.map((r) => r.user.id));
      this.patch(key, { items: [...state.items, ...page.items.filter((r) => !seen.has(r.user.id))], nextCursor: page.nextCursor, loadingMore: false });
    } catch {
      if (generation === this.generation) this.patch(key, { loadingMore: false, moreFailed: true });
    }
  }

  private async load(type: ReactionType | null): Promise<void> {
    const key = type ?? 'all';
    const generation = this.generation;
    this.pages.update((map) => new Map(map).set(key, { items: [], nextCursor: null, status: 'loading', loadingMore: false, moreFailed: false }));
    try {
      const page = await firstValueFrom(this.api.reactors(this.articleId(), { type, limit: PAGE_SIZE }));
      if (generation === this.generation) this.patch(key, { items: page.items, nextCursor: page.nextCursor, status: 'loaded' });
    } catch {
      if (generation === this.generation) this.patch(key, { status: 'error' });
    }
  }

  private patch(key: string, change: Partial<TabState>): void {
    const state = this.pages().get(key);
    if (state) this.pages.update((map) => new Map(map).set(key, { ...state, ...change }));
  }
}
