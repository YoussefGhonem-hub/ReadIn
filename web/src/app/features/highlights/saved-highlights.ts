import { ChangeDetectionStrategy, Component, ElementRef, inject, signal, viewChild } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { firstValueFrom } from 'rxjs';
import { HighlightGroupDto, HighlightsApi } from '../../core/api/highlights.api';
import { BdiText } from '../../shared/directives/bdi-text';
import { languageDir } from '../../shared/rdoc/rdoc.utils';
import { articleLink } from '../../shared/ui/article-link';
import { LinesSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { loadMoreNearEnd } from '../profile/infinite-scroll';

const PAGE_SIZE = 20;

/** One group per article version. */
const keyOf = (group: HighlightGroupDto) => `${group.article.id}|${group.article.language}`;

/**
 * Saved tab → Highlights (F14, F30): your highlights from `GET /me/highlights`, one group per article version (its
 * title in that version, its writer or "Deleted user"), groups by their newest highlight and highlights newest first,
 * with cursor paging (a group already shown is dropped when a later page brings it again). Each highlight opens the
 * article in that language at its block (`#b-{blockId}`). Only you see it (own profile).
 */
@Component({
  selector: 'rd-saved-highlights',
  imports: [RouterLink, TranslocoPipe, BdiText, EmptyState, ErrorState, LinesSkeleton],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-saved-highlights': '' },
  styles: `
    .quote {
      display: block;
      padding: 6px 12px;
      border-inline-start: 3px solid var(--rd-color-accent);
      border-start-end-radius: var(--rd-radius-sm);
      border-end-end-radius: var(--rd-radius-sm);
      background: color-mix(in srgb, var(--rd-color-accent) 12%, transparent);
      color: var(--rd-color-text-primary);
      line-height: 1.7;
      white-space: pre-line;
    }
    a:hover .quote {
      background: color-mix(in srgb, var(--rd-color-accent) 20%, transparent);
    }
  `,
  template: `
    @switch (status()) {
      @case ('error') {
        <rd-error-state [message]="'highlights.saved.loadError' | transloco" (retry)="load()" />
      }
      @case ('loaded') {
        @for (group of groups(); track key(group)) {
          <section class="rd-card mb-3 p-4 shadow-none" [attr.data-highlight-group]="key(group)" [attr.aria-label]="group.article.title">
            <a [routerLink]="link(group)" class="block font-semibold text-text-primary no-underline hover:underline" [attr.lang]="group.article.language" data-group-title>
              <rd-bdi-text [text]="group.article.title" />
            </a>
            <p class="m-0 mt-1 flex flex-wrap items-center gap-1.5 text-xs text-text-secondary" data-group-meta>
              @if (group.article.author; as author) {
                <rd-bdi-text [text]="author.displayName" />
              } @else {
                <span>{{ 'common.deletedUser' | transloco }}</span>
              }
              <span aria-hidden="true">·</span>
              <span>{{ (group.article.language === 'en' ? 'highlights.saved.versionEn' : 'highlights.saved.versionAr') | transloco }}</span>
            </p>
            <ul class="m-0 mt-3 flex list-none flex-col gap-2 p-0">
              @for (highlight of group.highlights; track highlight.id) {
                <li>
                  <a
                    [routerLink]="link(group)"
                    [fragment]="'b-' + highlight.blockId"
                    class="block text-sm no-underline"
                    [attr.lang]="group.article.language"
                    [attr.data-saved-highlight]="highlight.id"
                  >
                    <span class="quote" [attr.dir]="dir(group)"><rd-bdi-text [text]="highlight.text" [baseDir]="dir(group)" /></span>
                  </a>
                </li>
              }
            </ul>
          </section>
        } @empty {
          <rd-empty-state [title]="'highlights.saved.emptyTitle' | transloco" [message]="'highlights.saved.emptyBody' | transloco" data-highlights-empty />
        }
        @if (loadingMore()) {
          <rd-lines-skeleton class="block py-3" [count]="3" />
        }
        @if (loadMoreFailed()) {
          <div class="py-4 text-center">
            <button type="button" class="rd-btn rd-btn-outline" (click)="loadMore()">{{ 'common.retry' | transloco }}</button>
          </div>
        }
      }
      @default {
        <div class="flex flex-col gap-3" aria-busy="true">
          @for (i of [1, 2]; track i) {
            <div class="rd-card p-4 shadow-none"><rd-lines-skeleton [count]="3" /></div>
          }
        </div>
      }
    }
    <div #sentinel class="h-px" aria-hidden="true"></div>
  `,
})
export class SavedHighlights {
  private readonly api = inject(HighlightsApi);
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');

  protected readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly groups = signal<HighlightGroupDto[]>([]);
  protected readonly loadingMore = signal(false);
  protected readonly loadMoreFailed = signal(false);
  private nextCursor: string | null = null;
  private generation = 0;
  protected readonly key = keyOf;

  constructor() {
    void this.load();
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => void this.loadMore(),
    );
  }

  protected link(group: HighlightGroupDto): string[] {
    return articleLink(group.article);
  }

  /** The version's direction: the text is laid out as the reader shows it, other-direction runs isolated. */
  protected dir(group: HighlightGroupDto) {
    return languageDir(group.article.language);
  }

  protected async load(): Promise<void> {
    const generation = ++this.generation;
    this.status.set('loading');
    this.loadMoreFailed.set(false);
    try {
      const page = await firstValueFrom(this.api.mine({ limit: PAGE_SIZE }));
      if (generation !== this.generation) return;
      this.groups.set(page.items);
      this.nextCursor = page.nextCursor;
      this.status.set('loaded');
    } catch {
      if (generation === this.generation) this.status.set('error');
    }
  }

  protected async loadMore(): Promise<void> {
    const cursor = this.nextCursor;
    if (!cursor || this.loadingMore() || this.status() !== 'loaded') return;
    const generation = this.generation;
    this.loadingMore.set(true);
    this.loadMoreFailed.set(false);
    try {
      const page = await firstValueFrom(this.api.mine({ cursor, limit: PAGE_SIZE }));
      if (generation !== this.generation) return;
      const shown = new Set(this.groups().map(keyOf));
      this.groups.update((groups) => [...groups, ...page.items.filter((g) => !shown.has(keyOf(g)))]);
      this.nextCursor = page.nextCursor;
    } catch {
      if (generation === this.generation) this.loadMoreFailed.set(true);
    } finally {
      if (generation === this.generation) this.loadingMore.set(false);
    }
  }
}
