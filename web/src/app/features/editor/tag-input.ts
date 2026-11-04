import { ChangeDetectionStrategy, Component, DestroyRef, computed, inject, input, output, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { TagDto } from '../../core/api/models';
import { TagsApi } from '../../core/api/tags.api';

export const MAX_TAGS = 5;
export const TAG_MAX_LENGTH = 40;
const SUGGEST_DEBOUNCE_MS = 250;

/** Adds `name` to `tags` (trimmed, at most 40 characters, no duplicates ignoring case, at most 5). */
export function addTag(tags: readonly string[], name: string): string[] {
  const tag = name.trim().replace(/^#+/, '').replace(/\s+/g, ' ').trim().slice(0, TAG_MAX_LENGTH).trim();
  if (!tag || tags.length >= MAX_TAGS || tags.some((t) => t.toLowerCase() === tag.toLowerCase())) return [...tags];
  return [...tags, tag];
}

let nextId = 0;

/**
 * Tags (F05): up to 5, free text or picked from `GET /tags?q=` suggestions (most used first). Enter or comma adds the
 * typed tag; Backspace in the empty field removes the last one. The suggestion list is a combobox listbox.
 */
@Component({
  selector: 'rd-tag-input',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  styles: `
    /* The suggestions open below the field: the field group must not clip them. */
    .tags {
      overflow: visible;
    }
    .suggestions {
      top: 100%;
      max-height: 16rem;
    }
  `,
  template: `
    <label class="rd-label" [for]="inputId">{{ 'editor.meta.tags' | transloco }}</label>
    <div class="tags rd-field-group min-h-11 flex-wrap items-center gap-1.5 p-1.5" [class.is-disabled]="full()" data-tags>
      @for (tag of tags(); track tag; let i = $index) {
        <span class="rd-tag inline-flex min-h-9 items-center gap-1 ps-3" dir="auto" data-tag>
          #{{ tag }}
          <button type="button" class="grid h-8 w-8 place-items-center rounded-chip" [attr.aria-label]="'editor.meta.removeTag' | transloco: { tag }" (click)="remove(i)">
            <svg lucideIcon="X" [size]="14" aria-hidden="true"></svg>
          </button>
        </span>
      }
      @if (!full()) {
        <div class="relative min-w-32 flex-1">
          <input
            [id]="inputId"
            class="rd-field-input min-h-9 w-full"
            dir="auto"
            autocomplete="off"
            enterkeyhint="done"
            role="combobox"
            aria-autocomplete="list"
            [attr.aria-expanded]="open()"
            [attr.aria-controls]="open() ? listId : null"
            [attr.aria-activedescendant]="open() && active() >= 0 ? listId + '-' + active() : null"
            [attr.aria-describedby]="hintId"
            [maxLength]="maxLength"
            [placeholder]="'editor.meta.tagPlaceholder' | transloco"
            [value]="text()"
            data-tag-input
            (input)="onInput($event)"
            (keydown)="onKeydown($event)"
            (blur)="close()"
          />
          @if (open()) {
            <ul [id]="listId" role="listbox" [attr.aria-label]="'editor.meta.tagSuggestions' | transloco" class="suggestions absolute inset-x-0 z-20 m-0 mt-1 list-none overflow-y-auto rounded-md border border-border bg-surface-raised p-1 shadow-raised" data-tag-suggestions>
              @for (s of suggestions(); track s.slug; let i = $index) {
                <li
                  [id]="listId + '-' + i"
                  role="option"
                  [attr.aria-selected]="i === active()"
                  class="flex min-h-10 cursor-pointer items-center justify-between gap-2 rounded-sm px-2 text-sm"
                  [class.bg-surface-variant]="i === active()"
                  [attr.data-tag-option]="s.name"
                  tabindex="-1"
                  (mousedown)="$event.preventDefault()"
                  (mousemove)="active.set(i)"
                  (click)="pick(s)"
                  (keydown.enter)="pick(s)"
                >
                  <span dir="auto">#{{ s.name }}</span>
                  <span class="text-xs text-text-secondary" dir="ltr">{{ s.articleCount }}</span>
                </li>
              }
            </ul>
          }
        </div>
      }
    </div>
    <p [id]="hintId" class="rd-field-hint">{{ (full() ? 'editor.meta.tagsFull' : 'editor.meta.tagsHint') | transloco }}</p>
  `,
})
export class TagInput {
  private readonly api = inject(TagsApi);

  readonly tags = input.required<string[]>();
  readonly tagsChange = output<string[]>();

  protected readonly inputId = `rd-tags-${++nextId}`;
  protected readonly listId = `${this.inputId}-list`;
  protected readonly hintId = `${this.inputId}-hint`;
  protected readonly maxLength = TAG_MAX_LENGTH;
  protected readonly text = signal('');
  protected readonly suggestions = signal<TagDto[]>([]);
  protected readonly active = signal(-1);
  protected readonly open = computed(() => this.suggestions().length > 0);
  protected readonly full = computed(() => this.tags().length >= MAX_TAGS);

  private timer: ReturnType<typeof setTimeout> | null = null;
  private lookup = 0;

  constructor() {
    inject(DestroyRef).onDestroy(() => this.cancel());
  }

  protected onInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    if (value.includes(',')) {
      const parts = value.split(',');
      let tags = this.tags();
      for (const part of parts.slice(0, -1)) tags = addTag(tags, part);
      this.commit(tags);
      this.setText(parts[parts.length - 1], event.target as HTMLInputElement);
    } else {
      this.text.set(value);
    }
    this.suggest();
  }

  protected onKeydown(event: KeyboardEvent): void {
    const list = this.suggestions();
    switch (event.key) {
      case 'ArrowDown':
        if (!list.length) return;
        event.preventDefault();
        this.active.set((this.active() + 1) % list.length);
        return;
      case 'ArrowUp':
        if (!list.length) return;
        event.preventDefault();
        this.active.set((this.active() - 1 + list.length) % list.length);
        return;
      case 'Enter': {
        event.preventDefault();
        const picked = list[this.active()];
        if (picked) this.pick(picked);
        else this.addTyped(event.target as HTMLInputElement);
        return;
      }
      case 'Escape':
        if (list.length) {
          event.preventDefault();
          this.close();
        }
        return;
      case 'Backspace':
        if (!this.text() && this.tags().length) this.remove(this.tags().length - 1);
        return;
    }
  }

  protected pick(tag: TagDto): void {
    this.commit(addTag(this.tags(), tag.name));
    this.text.set('');
    this.close();
  }

  protected remove(index: number): void {
    this.commit(this.tags().filter((_, i) => i !== index));
  }

  protected close(): void {
    this.cancel();
    this.suggestions.set([]);
    this.active.set(-1);
  }

  private addTyped(input: HTMLInputElement): void {
    const next = addTag(this.tags(), this.text());
    this.commit(next);
    this.setText('', input);
    this.close();
  }

  private commit(tags: string[]): void {
    if (tags.length !== this.tags().length || tags.some((t, i) => t !== this.tags()[i])) this.tagsChange.emit(tags);
  }

  private setText(value: string, input: HTMLInputElement): void {
    this.text.set(value);
    input.value = value;
  }

  private suggest(): void {
    this.cancel();
    const query = this.text().replace(/^#+/, '').trim();
    if (!query) {
      this.suggestions.set([]);
      return;
    }
    const lookup = ++this.lookup;
    this.timer = setTimeout(async () => {
      this.timer = null;
      try {
        const found = await firstValueFrom(this.api.search(query, 8));
        if (lookup !== this.lookup) return;
        const taken = new Set(this.tags().map((t) => t.toLowerCase()));
        this.suggestions.set(found.filter((t) => !taken.has(t.name.toLowerCase())));
        this.active.set(-1);
      } catch {
        if (lookup === this.lookup) this.suggestions.set([]); // suggestions are optional
      }
    }, SUGGEST_DEBOUNCE_MS);
  }

  private cancel(): void {
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
    this.lookup++;
  }
}
