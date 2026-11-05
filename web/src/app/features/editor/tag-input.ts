import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  Injector,
  afterNextRender,
  computed,
  inject,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { TagDto } from '../../core/api/models';
import { TagsApi } from '../../core/api/tags.api';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { MAX_TAGS, TAG_MAX_LENGTH, TAG_MIN_LENGTH, TagNameProblem, cleanTagName, hasTag, normalizeTagName, tagNameProblem } from './tag-rules';

export { MAX_TAGS, TAG_MAX_LENGTH, addTag } from './tag-rules';

const SUGGEST_DEBOUNCE_MS = 250;
const SUGGESTIONS = 8;
/** Room for a pasted list ("a, b, c") and stray spaces; the rule's 30 characters are checked after cleaning. */
const INPUT_MAX_LENGTH = 100;
/** A comma adds the typed tag; the Arabic keyboard types "،". */
const COMMA = /[,،]/;

/** Why the last save was refused because of the tags: a contract code, and the name it is about (if one). */
export interface TagError {
  code: string;
  tag: string | null;
}

/** A row of the suggestion list: an existing tag, or "Create new tag: {name}". */
type TagOption = { key: string; tag: TagDto; create: null } | { key: string; tag: null; create: string };

let nextId = 0;

/**
 * The editor's tag field (F32): the chosen tags as removable chips, then an input with suggestions from `GET /tags?q=`
 * (debounced, most used first). Enter or a comma adds the typed name; when no suggestion is that exact tag, the list
 * ends with "Create new tag: {name}". A new name follows the server's rules (tag-rules.ts) with an inline message; a
 * picked suggestion is added as it is, since existing tags may predate the rules. Repeats of a chosen tag are ignored,
 * ignoring case and Arabic spelling variants. At 5 the input is disabled with a hint. Backspace in the empty input
 * removes the last chip. The suggestion list is a combobox listbox.
 */
@Component({
  selector: 'rd-tag-input',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  styles: `
    /* The suggestions open below the whole field (as wide as it, whatever row the input is on): it must not clip them. */
    .tags {
      position: relative;
      overflow: visible;
    }
    .suggestions {
      top: 100%;
      max-height: 16rem;
    }
  `,
  template: `
    <label class="rd-label" [for]="inputId">{{ 'editor.meta.tags' | transloco }}</label>
    <!-- At 5 only the input is disabled: the chips stay at full contrast, since they can still be removed. -->
    <div class="tags rd-field-group min-h-11 flex-wrap items-center gap-1.5 p-1.5" [class.is-invalid]="!!problem()" data-tags>
      @for (tag of tags(); track tag; let i = $index) {
        @let bad = isFlagged(tag);
        <span
          class="rd-tag inline-flex min-h-9 items-center gap-1 ps-3"
          [class.bg-callout-danger]="bad"
          [class.text-error]="bad"
          dir="auto"
          [attr.data-tag]="tag"
          [attr.data-flagged]="bad || null"
        >
          @if (bad) {
            <svg lucideIcon="CircleAlert" [size]="14" aria-hidden="true"></svg>
          }
          #{{ tag }}
          <button
            type="button"
            class="grid h-8 w-8 place-items-center rounded-chip"
            [attr.aria-label]="(bad ? 'editor.meta.removeFlaggedTag' : 'editor.meta.removeTag') | transloco: { tag }"
            data-tag-remove
            (click)="remove(i)"
          >
            <svg lucideIcon="X" [size]="14" aria-hidden="true"></svg>
          </button>
        </span>
      }
      <div class="min-w-32 flex-1">
        <input
          #field
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
          [attr.aria-describedby]="describedBy()"
          [attr.aria-invalid]="problem() ? true : null"
          [disabled]="full()"
          [maxLength]="inputMaxLength"
          [placeholder]="full() ? '' : ('editor.meta.tagPlaceholder' | transloco)"
          [value]="text()"
          data-tag-input
          (input)="onInput($event)"
          (keydown)="onKeydown($event)"
          (blur)="close()"
        />
        @if (open()) {
          <ul
            [id]="listId"
            role="listbox"
            [attr.aria-label]="'editor.meta.tagSuggestions' | transloco"
            class="suggestions absolute inset-x-0 z-20 m-0 mt-1 list-none overflow-y-auto rounded-md border border-border bg-surface-raised p-1 shadow-raised"
            data-tag-suggestions
          >
            @for (option of options(); track option.key; let i = $index) {
              <li
                [id]="listId + '-' + i"
                role="option"
                [attr.aria-selected]="i === active()"
                class="flex min-h-10 cursor-pointer items-center justify-between gap-2 rounded-sm px-2 text-sm"
                [class.bg-surface-variant]="i === active()"
                [attr.data-tag-option]="option.tag?.name ?? null"
                [attr.data-tag-create]="option.create"
                tabindex="-1"
                (mousedown)="$event.preventDefault()"
                (mousemove)="active.set(i)"
                (click)="choose(option)"
                (keydown.enter)="choose(option)"
              >
                @if (option.tag; as tag) {
                  <span dir="auto">#{{ tag.name }}</span>
                  <span class="text-xs text-text-secondary" dir="ltr">{{ tag.articleCount }}</span>
                } @else {
                  <span class="inline-flex min-w-0 items-center gap-1.5 py-1 text-primary">
                    <svg lucideIcon="Plus" [size]="16" class="shrink-0" aria-hidden="true"></svg>
                    <span class="min-w-0 break-words">
                      {{ 'editor.meta.createTag' | transloco }}
                      <bdi dir="auto" class="font-semibold">#{{ option.create }}</bdi>
                    </span>
                  </span>
                }
              </li>
            }
          </ul>
        }
      </div>
    </div>
    @if (problem(); as rule) {
      <p [id]="problemId" class="m-0 mt-1 text-xs text-error" role="alert" data-tag-problem [attr.data-rule]="rule">
        {{ 'editor.meta.tagRules.' + rule | transloco: limits }}
      </p>
    }
    @if (errors().length) {
      <ul [id]="errorsId" class="m-0 mt-1 flex list-none flex-col gap-0.5 p-0 text-xs text-error" role="alert" data-tag-errors>
        @for (error of errors(); track $index) {
          <li [attr.data-tag-error]="error.code">
            @if (error.tag) {
              <bdi dir="auto" class="font-semibold">#{{ error.tag }}</bdi>:
            }
            {{ errorText(error.code) }}
          </li>
        }
      </ul>
    }
    <p [id]="hintId" class="rd-field-hint" data-tags-hint>{{ (full() ? 'editor.meta.tagsFull' : 'editor.meta.tagsHint') | transloco }}</p>
  `,
})
export class TagInput {
  private readonly api = inject(TagsApi);
  private readonly messages = inject(ErrorMessages);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly injector = inject(Injector);
  private readonly field = viewChild.required<ElementRef<HTMLInputElement>>('field');

  readonly tags = input.required<string[]>();
  /** Names with a problem in the last checks or save (`tag.hidden`, `tag.limit`, `tag.invalid`): their chips are marked. */
  readonly flagged = input<readonly string[]>([]);
  /** Why the last save was refused because of the tags, listed under the field. */
  readonly errors = input<readonly TagError[]>([]);
  readonly tagsChange = output<string[]>();

  protected readonly inputId = `rd-tags-${++nextId}`;
  protected readonly listId = `${this.inputId}-list`;
  protected readonly hintId = `${this.inputId}-hint`;
  protected readonly problemId = `${this.inputId}-problem`;
  protected readonly errorsId = `${this.inputId}-errors`;
  protected readonly inputMaxLength = INPUT_MAX_LENGTH;
  protected readonly limits = { min: TAG_MIN_LENGTH, max: TAG_MAX_LENGTH };

  protected readonly text = signal('');
  /** The last suggestions, as the API sent them. */
  private readonly results = signal<TagDto[]>([]);
  /** The cleaned text the results are for: until it equals the typed one, a lookup is pending. */
  private readonly lookedUp = signal<string | null>(null);
  /** The writer tried to add the typed name (Enter, a comma): every rule it breaks shows. */
  private readonly attempted = signal(false);
  private readonly listOpen = signal(false);
  protected readonly active = signal(-1);

  protected readonly full = computed(() => this.tags().length >= MAX_TAGS);
  private readonly cleaned = computed(() => cleanTagName(this.text()));
  private readonly settled = computed(() => this.lookedUp() === this.cleaned());
  /** The suggestion that is the typed tag itself (same normalized name). */
  private readonly exact = computed(() => {
    const key = normalizeTagName(this.cleaned());
    return key ? (this.results().find((t) => normalizeTagName(t.name) === key) ?? null) : null;
  });
  /**
   * The rule the typed name breaks: shown once the writer tries to add it, or as soon as its suggestions are in for
   * the ones more typing can't fix (a character, the length). Never for an existing tag's name.
   */
  protected readonly problem = computed<TagNameProblem | null>(() => {
    const name = this.cleaned();
    if (!name || this.exact() || hasTag(this.tags(), name)) return null;
    const rule = tagNameProblem(name);
    if (!rule) return null;
    return this.attempted() || (this.settled() && (rule === 'charset' || rule === 'tooLong')) ? rule : null;
  });
  protected readonly options = computed<TagOption[]>(() => {
    const tags = this.tags();
    const name = this.cleaned();
    const options: TagOption[] = this.results()
      .filter((t) => !hasTag(tags, t.name))
      .map((t) => ({ key: `tag:${t.slug}`, tag: t, create: null }));
    if (name && this.settled() && !this.exact() && !hasTag(tags, name) && !tagNameProblem(name)) options.push({ key: 'create', tag: null, create: name });
    return options;
  });
  protected readonly open = computed(() => this.listOpen() && !this.full() && this.options().length > 0);
  private readonly flaggedKeys = computed(() => new Set(this.flagged().map(normalizeTagName)));
  protected readonly describedBy = computed(() =>
    [this.hintId, this.problem() ? this.problemId : null, this.errors().length ? this.errorsId : null].filter(Boolean).join(' '),
  );

  private timer: ReturnType<typeof setTimeout> | null = null;
  private lookup = 0;

  constructor() {
    inject(DestroyRef).onDestroy(() => this.cancel());
  }

  protected isFlagged(tag: string): boolean {
    return this.flaggedKeys().has(normalizeTagName(tag));
  }

  protected errorText(code: string): string {
    return this.messages.forCode(code);
  }

  protected onInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.attempted.set(false);
    this.listOpen.set(true);
    if (COMMA.test(input.value)) this.addParts(input);
    else this.text.set(input.value);
    this.suggest();
  }

  protected onKeydown(event: KeyboardEvent): void {
    const options = this.options();
    switch (event.key) {
      case 'ArrowDown':
        if (!options.length || this.full()) return;
        event.preventDefault();
        if (!this.open()) this.listOpen.set(true); // closed with Escape: opens again
        this.active.set((this.active() + 1) % options.length);
        return;
      case 'ArrowUp':
        if (!this.open()) return;
        event.preventDefault();
        this.active.set((this.active() - 1 + options.length) % options.length);
        return;
      case 'Enter': {
        if (event.isComposing) return;
        event.preventDefault();
        const option = this.open() ? options[this.active()] : undefined;
        if (option) this.choose(option);
        else this.addTyped();
        return;
      }
      case 'Escape':
        if (this.open()) {
          event.preventDefault();
          this.close();
        }
        return;
      case 'Backspace':
        if (!this.text() && this.tags().length) this.remove(this.tags().length - 1, false);
        return;
    }
  }

  protected choose(option: TagOption): void {
    if (option.tag) this.addExisting(option.tag.name);
    else this.addTyped();
  }

  /** Removes a chip; focus goes to the input (enabled again if the article had 5). */
  protected remove(index: number, refocus = true): void {
    this.commit(this.tags().filter((_, i) => i !== index));
    if (refocus) this.afterRender(() => this.field().nativeElement.focus());
  }

  protected close(): void {
    this.listOpen.set(false);
    this.active.set(-1);
  }

  /** The typed name: the existing tag it matches, else a new one if it follows the rules (else its message shows). */
  private addTyped(): void {
    const name = this.cleaned();
    if (!name) return;
    const known = this.exact();
    if (known) return this.addExisting(known.name);
    if (hasTag(this.tags(), name)) return this.reset(); // already there: ignored
    if (tagNameProblem(name)) {
      this.attempted.set(true);
      this.close();
      return;
    }
    this.add(name);
  }

  /** An existing tag is added as it is: it may predate the rules (e.g. `CI/CD`). */
  private addExisting(name: string): void {
    if (!hasTag(this.tags(), name)) this.add(name);
    else this.reset();
  }

  private add(name: string): void {
    if (this.full()) return;
    const tags = [...this.tags(), name];
    this.commit(tags);
    this.reset();
    this.focusAfterAdding(tags);
  }

  /**
   * A comma (or a pasted list): adds every finished name before it. The first one that breaks a rule stays in the
   * input with its message; otherwise the text after the last comma does.
   */
  private addParts(input: HTMLInputElement): void {
    const parts = input.value.split(COMMA);
    const last = parts.pop() ?? '';
    let tags = this.tags();
    let failed: string | null = null;
    for (const part of parts) {
      const name = cleanTagName(part);
      if (!name || hasTag(tags, name)) continue;
      const known = this.results().find((t) => normalizeTagName(t.name) === normalizeTagName(name));
      if (!known && tagNameProblem(name)) {
        failed = part.trim();
        break;
      }
      if (tags.length < MAX_TAGS) tags = [...tags, known?.name ?? name];
    }
    this.commit(tags);
    const rest = failed ?? last;
    this.text.set(rest);
    input.value = rest;
    this.attempted.set(failed !== null);
    if (!rest.trim()) this.results.set([]);
    this.focusAfterAdding(tags);
  }

  private commit(tags: string[]): void {
    if (tags.length !== this.tags().length || tags.some((t, i) => t !== this.tags()[i])) this.tagsChange.emit(tags);
  }

  /** The 5th tag disables the input: keyboard focus moves to the last chip's remove button instead of the page. */
  private focusAfterAdding(tags: readonly string[]): void {
    if (tags.length < MAX_TAGS) return;
    this.afterRender(() => {
      const buttons = this.host.nativeElement.querySelectorAll<HTMLElement>('[data-tag-remove]');
      buttons[buttons.length - 1]?.focus();
    });
  }

  private reset(): void {
    this.cancel();
    this.text.set('');
    this.field().nativeElement.value = '';
    this.results.set([]);
    this.lookedUp.set(null);
    this.attempted.set(false);
    this.close();
  }

  private suggest(): void {
    this.cancel();
    const query = this.cleaned();
    this.active.set(-1);
    if (!query) {
      this.results.set([]);
      this.lookedUp.set(null);
      return;
    }
    if (query.length > TAG_MAX_LENGTH) {
      // The API matches nothing that long.
      this.results.set([]);
      this.lookedUp.set(query);
      return;
    }
    const lookup = ++this.lookup;
    this.timer = setTimeout(async () => {
      this.timer = null;
      let found: TagDto[] = [];
      try {
        found = await firstValueFrom(this.api.search(query, SUGGESTIONS));
      } catch {
        // Suggestions are optional: creating the tag still works.
      }
      if (lookup !== this.lookup) return;
      this.results.set(found);
      this.lookedUp.set(query);
      this.active.set(-1);
    }, SUGGEST_DEBOUNCE_MS);
  }

  private cancel(): void {
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
    this.lookup++;
  }

  private afterRender(action: () => void): void {
    afterNextRender(action, { injector: this.injector });
  }
}
