import { ChangeDetectionStrategy, Component, effect, input, output, signal, untracked } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleSourceDto } from '../../core/api/models';
import { safeHttpUrl } from '../../shared/rdoc/rdoc.utils';

export const MAX_SOURCES = 30;
export const SOURCE_TITLE_MAX = 200;
export const SOURCE_URL_MAX = 2048;

export interface SourceRow {
  id: number;
  title: string;
  url: string;
}

export function isValidSourceUrl(url: string): boolean {
  return !!safeHttpUrl(url.trim());
}

/** A row is saved once it has a title and an http(s) link; anything else would make the whole save invalid. */
export function isCompleteSource(row: SourceRow): boolean {
  return !!row.title.trim() && isValidSourceUrl(row.url);
}

export function completeSources(rows: readonly SourceRow[]): ArticleSourceDto[] {
  return rows.filter(isCompleteSource).map((row) => ({ title: row.title.trim(), url: row.url.trim() }));
}

let nextRowId = 1;

/**
 * Sources (title + link, SPEC §20; required in fields that ask for them). Rows being typed stay here until they are
 * complete; only complete ones go into the draft.
 */
@Component({
  selector: 'rd-sources-editor',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <fieldset class="m-0 min-w-0 border-0 p-0" data-sources>
      <legend class="rd-label mb-1">
        📚 {{ 'editor.sources' | transloco }}
        <span class="ms-1 font-normal text-text-secondary">· {{ (required() ? 'editor.sourcesRequiredNote' : 'editor.sourcesOptionalNote') | transloco }}</span>
      </legend>
      <div class="flex flex-col gap-3">
        @for (row of rows(); track row.id; let i = $index) {
          <div class="grid gap-2" data-source-row>
            <input
              class="rd-input"
              dir="auto"
              [maxLength]="titleMax"
              [value]="row.title"
              [placeholder]="'editor.sourceTitle' | transloco"
              [attr.aria-label]="('editor.sourceTitle' | transloco) + ' ' + (i + 1)"
              data-source-title
              (input)="update(row.id, { title: valueOf($event) })"
            />
            <div class="flex gap-2">
              <input
                class="rd-input"
                type="url"
                dir="ltr"
                inputmode="url"
                placeholder="https://"
                [maxLength]="urlMax"
                [value]="row.url"
                [attr.aria-label]="('editor.sourceUrl' | transloco) + ' ' + (i + 1)"
                [attr.aria-invalid]="invalid(row) ? 'true' : null"
                data-source-url
                (input)="update(row.id, { url: valueOf($event) })"
              />
              <button type="button" class="rd-icon-btn h-11 w-11 shrink-0" [attr.aria-label]="'editor.removeSource' | transloco: { position: i + 1 }" (click)="remove(row.id)">
                <svg lucideIcon="Trash2" [size]="16" aria-hidden="true"></svg>
              </button>
            </div>
            @if (invalid(row)) {
              <p class="m-0 text-xs text-error">{{ 'editor.invalidUrl' | transloco }}</p>
            } @else if (incomplete(row)) {
              <p class="m-0 text-xs text-text-secondary">{{ 'editor.sourceIncomplete' | transloco }}</p>
            }
          </div>
        }
        @if (rows().length < maxSources) {
          <button type="button" class="rd-btn rd-btn-ghost min-h-9 self-start px-2 text-sm text-primary" data-add-source (click)="add()">
            <svg lucideIcon="Plus" [size]="16" aria-hidden="true"></svg>
            {{ 'editor.addSource' | transloco }}
          </button>
        }
      </div>
    </fieldset>
  `,
})
export class SourcesEditor {
  /** The saved sources; rows are rebuilt when they change from outside (load, restore). */
  readonly sources = input.required<ArticleSourceDto[]>();
  readonly required = input(false);
  readonly sourcesChange = output<ArticleSourceDto[]>();

  protected readonly titleMax = SOURCE_TITLE_MAX;
  protected readonly urlMax = SOURCE_URL_MAX;
  protected readonly maxSources = MAX_SOURCES;
  protected readonly rows = signal<SourceRow[]>([]);
  private lastEmitted = '';

  constructor() {
    effect(() => {
      const sources = this.sources();
      untracked(() => {
        if (JSON.stringify(sources) === this.lastEmitted && this.rows().length) return; // our own change coming back
        this.lastEmitted = JSON.stringify(sources);
        this.rows.set(sources.length ? sources.map((s) => ({ id: nextRowId++, title: s.title, url: s.url })) : []);
      });
    });
  }

  protected add(): void {
    this.rows.update((rows) => [...rows, { id: nextRowId++, title: '', url: '' }]);
  }

  protected remove(id: number): void {
    this.rows.update((rows) => rows.filter((r) => r.id !== id));
    this.emit();
  }

  protected update(id: number, patch: Partial<SourceRow>): void {
    this.rows.update((rows) => rows.map((r) => (r.id === id ? { ...r, ...patch } : r)));
    this.emit();
  }

  protected invalid(row: SourceRow): boolean {
    return !!row.url.trim() && !isValidSourceUrl(row.url);
  }

  protected incomplete(row: SourceRow): boolean {
    return (!!row.title.trim() || !!row.url.trim()) && !isCompleteSource(row);
  }

  private emit(): void {
    const sources = completeSources(this.rows());
    const json = JSON.stringify(sources);
    if (json === this.lastEmitted) return;
    this.lastEmitted = json;
    this.sourcesChange.emit(sources);
  }

  protected valueOf(event: Event): string {
    return (event.target as HTMLInputElement).value;
  }
}
