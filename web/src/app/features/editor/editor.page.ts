import { ChangeDetectionStrategy, Component, effect, inject, input, signal, untracked } from '@angular/core';
import { Router } from '@angular/router';
import { ArticleEditor } from './article-editor';
import { provideEditorIcons } from './editor-icons';

/**
 * `/write/new` and `/write/:id` (F05). The editor lives in an inner component keyed by the article, so opening another
 * article (or another new one) starts from a clean state, while a new article that just got its id on the first
 * autosave keeps going: the URL becomes `/write/{id}` and nothing reloads.
 */
@Component({
  selector: 'rd-editor-page',
  imports: [ArticleEditor],
  providers: [provideEditorIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @if (instanceKey(); as key) {
      @for (k of [key]; track k) {
        <rd-article-editor [articleId]="k.startsWith('new#') ? null : k" (created)="onCreated($event)" />
      }
    }
  `,
})
export class EditorPage {
  private readonly router = inject(Router);

  /** Route param: `new` or an article id. */
  readonly id = input.required<string>();
  protected readonly instanceKey = signal<string | null>(null);
  /** The id the open new article got, so its own URL change keeps the same editor. */
  private createdId: string | null = null;
  private newCount = 0;

  constructor() {
    effect(() => {
      const id = this.id();
      untracked(() => {
        if (id !== 'new' && id === this.createdId) return;
        this.createdId = null;
        this.instanceKey.set(id === 'new' ? `new#${++this.newCount}` : id);
      });
    });
  }

  protected onCreated(id: string): void {
    this.createdId = id;
    void this.router.navigate(['/write', id], { replaceUrl: true });
  }
}
