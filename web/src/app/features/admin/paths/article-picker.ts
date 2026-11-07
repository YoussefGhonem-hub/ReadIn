import { ChangeDetectionStrategy, Component, inject, input, output, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { firstValueFrom } from 'rxjs';
import { ArticleLanguage } from '../../../core/api/models';
import { SearchApi } from '../../../core/api/search.api';
import { BdiText } from '../../../shared/directives/bdi-text';

/** An article picked for a path or a link: its id and, once known, its title in its own language. */
export interface PickedArticle {
  id: string;
  title: string | null;
  language: ArticleLanguage | null;
  slug?: string;
}

/**
 * Finds an article to add (F23: a path's items, an announcement's link) with `GET /search?type=articles&q=` as you type;
 * a newer search wins over a slower older one. Articles already chosen (`exclude`) are left out.
 */
@Component({
  selector: 'rd-admin-article-picker',
  imports: [TranslocoPipe, BdiText],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col gap-1', 'data-article-picker': '' },
  template: `
    <label [for]="inputId()" class="rd-label m-0">{{ 'admin.picker.label' | transloco }}</label>
    <input
      [id]="inputId()"
      type="search"
      class="rd-input"
      dir="auto"
      maxlength="100"
      autocomplete="off"
      [placeholder]="'admin.picker.placeholder' | transloco"
      (input)="find($any($event.target).value)"
      data-picker-q
    />
    @if (searching()) {
      <p class="m-0 text-xs text-text-secondary" aria-live="polite">{{ 'common.loading' | transloco }}</p>
    }
    @if (results().length) {
      <ul class="m-0 flex max-h-56 list-none flex-col overflow-y-auto rounded-md border border-border p-1" data-picker-results>
        @for (r of results(); track r.id) {
          <li>
            <button type="button" class="flex min-h-11 w-full items-center gap-2 rounded-sm px-2 text-start text-sm hover:bg-surface-variant" (click)="pick(r)" [attr.data-picker-option]="r.id">
              <span class="min-w-0 flex-1 truncate" [attr.lang]="r.language"><rd-bdi-text [text]="r.title ?? ''" /></span>
            </button>
          </li>
        }
      </ul>
    }
  `,
})
export class ArticlePicker {
  private readonly search = inject(SearchApi);

  readonly exclude = input<string[]>([]);
  readonly inputId = input('admin-article-picker');
  readonly picked = output<PickedArticle>();

  protected readonly results = signal<PickedArticle[]>([]);
  protected readonly searching = signal(false);
  private run = 0;

  protected async find(q: string): Promise<void> {
    const run = ++this.run;
    const text = q.trim();
    if (text.length < 2) {
      this.results.set([]);
      this.searching.set(false);
      return;
    }
    this.searching.set(true);
    try {
      const page = await firstValueFrom(this.search.search(text, 'articles', { limit: 8 }));
      if (run !== this.run) return;
      const skip = new Set(this.exclude());
      this.results.set(
        page.items.filter((r) => !skip.has(r.article.id)).map((r) => ({ id: r.article.id, title: r.article.title, language: r.article.language, slug: r.article.slug })),
      );
    } catch {
      if (run === this.run) this.results.set([]);
    } finally {
      if (run === this.run) this.searching.set(false);
    }
  }

  protected pick(article: PickedArticle): void {
    this.picked.emit(article);
    this.results.update((list) => list.filter((r) => r.id !== article.id));
  }
}
