import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  Injector,
  afterNextRender,
  afterRenderEffect,
  computed,
  inject,
  input,
  model,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { CommentsApi } from '../../core/api/comments.api';
import { MentionCandidateDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { translatePlural } from '../../shared/pipes/format.pipes';
import { Avatar } from '../../shared/ui/avatar';
import { COMMENT_COUNTER_FROM, COMMENT_MAX_LENGTH, MentionQuery, commentDir, insertMention, mentionAt } from './comment-text';

/** Wait this long after the last keystroke before asking for mention suggestions. */
export const MENTION_DEBOUNCE_MS = 250;
/** The field grows with its text up to this height, then scrolls. */
const MAX_HEIGHT_PX = 240;

let nextId = 0;

/**
 * The comment field (F11): new comments, replies and inline edits. It grows with its text, keeps its own direction
 * (`dir="auto"`), shows a counter for the last 200 of the 2000 characters, and suggests people while you type an
 * `@handle` (`GET /users/mention-suggestions`, debounced). The list is a listbox driven from the field (combobox):
 * ↑/↓ move, Enter or Tab inserts `@username `, Escape closes. Ctrl/⌘ + Enter sends.
 */
@Component({
  selector: 'rd-comment-composer',
  imports: [TranslocoPipe, LucideDynamicIcon, Avatar, BdiText],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <form class="flex flex-col gap-2" (submit)="submit($event)" data-comment-composer>
      <div class="relative">
        <label [for]="inputId" class="sr-only">{{ label() }}</label>
        <textarea
          #field
          [id]="inputId"
          [attr.dir]="textDir()"
          rows="1"
          class="rd-input rd-autogrow block min-h-11 leading-relaxed"
          [value]="text()"
          [attr.maxlength]="maxLength"
          [placeholder]="placeholder()"
          role="combobox"
          aria-autocomplete="list"
          aria-haspopup="listbox"
          [attr.aria-expanded]="open()"
          [attr.aria-controls]="open() ? listId : null"
          [attr.aria-activedescendant]="open() ? optionId(active()) : null"
          [attr.aria-invalid]="error() ? true : null"
          [attr.aria-describedby]="describedBy()"
          (input)="onInput($event)"
          (keydown)="onKeydown($event)"
          (click)="lookForMention()"
          (keyup)="onKeyup($event)"
          (blur)="closeSuggestions()"
          data-comment-input
        ></textarea>

        @if (open()) {
          <ul
            [id]="listId"
            role="listbox"
            [attr.aria-label]="'comments.composer.suggestions' | transloco"
            class="absolute inset-x-0 bottom-full z-20 m-0 mb-1 max-h-[420px] list-none overflow-y-auto rounded-md border border-border bg-surface-raised p-1 shadow-raised"
            data-mention-list
          >
            @for (person of suggestions(); track person.id; let i = $index) {
              <li
                [id]="optionId(i)"
                role="option"
                tabindex="-1"
                [attr.aria-selected]="i === active()"
                class="flex min-h-11 cursor-pointer items-center gap-2 rounded-sm px-2 py-1"
                [class.bg-surface-variant]="i === active()"
                [attr.data-mention-option]="person.username"
                (mousedown)="$event.preventDefault()"
                (mousemove)="active.set(i)"
                (click)="pick(person)"
                (keydown.enter)="pick(person)"
              >
                <rd-avatar [name]="person.displayName" [src]="person.avatarUrl" [size]="28" />
                <span class="min-w-0 flex-1">
                  <span class="flex items-center gap-1 text-sm font-semibold">
                    <rd-bdi-text class="truncate" [text]="person.displayName" />
                    @if (person.isVerified) {
                      <svg lucideIcon="BadgeCheck" [size]="14" class="shrink-0 text-primary" aria-hidden="true"></svg>
                      <span class="sr-only">{{ 'comments.composer.verified' | transloco }}</span>
                    }
                  </span>
                  <bdi dir="ltr" class="block text-xs text-text-secondary">&#64;{{ person.username }}</bdi>
                </span>
              </li>
            }
          </ul>
        }
      </div>

      <div class="flex flex-wrap items-center justify-end gap-2">
        @if (showCounter()) {
          <span [id]="counterId" class="flex-1 text-xs" [class]="remaining() < 20 ? 'text-error' : 'text-text-secondary'" data-comment-counter>{{
            counterText()
          }}</span>
        }
        @if (cancelable()) {
          <button type="button" class="rd-btn rd-btn-ghost min-h-10 px-3 text-sm" [disabled]="busy()" (click)="cancelled.emit()">
            {{ 'common.cancel' | transloco }}
          </button>
        }
        <button type="submit" class="rd-btn rd-btn-primary min-h-10 px-4 text-sm" [disabled]="!canSend()" [attr.aria-busy]="busy()" data-comment-send>
          @if (busy()) {
            <svg lucideIcon="LoaderCircle" [size]="16" class="animate-spin" aria-hidden="true"></svg>
          } @else {
            <svg lucideIcon="Send" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
          }
          {{ submitLabel() }}
        </button>
      </div>

      @if (error()) {
        <p [id]="errorId" class="rd-alert rd-alert-error m-0" role="alert" data-comment-error>{{ error() }}</p>
      }
    </form>
  `,
})
export class CommentComposer {
  private readonly api = inject(CommentsApi);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;
  private readonly injector = inject(Injector);

  /** The text (two-way), so the owner can clear it after sending and restore it when sending fails. */
  readonly text = model('');
  readonly label = input.required<string>();
  readonly placeholder = input('');
  readonly submitLabel = input.required<string>();
  readonly error = input<string | null>(null);
  readonly busy = input(false);
  readonly cancelable = input(false);
  /** Focus the field when it appears (replies and edits open on request). */
  readonly autofocus = input(false);
  readonly submitted = output<string>();
  readonly cancelled = output<void>();

  protected readonly maxLength = COMMENT_MAX_LENGTH;
  protected readonly inputId = `comment-input-${++nextId}`;
  protected readonly listId = `${this.inputId}-mentions`;
  protected readonly counterId = `${this.inputId}-counter`;
  protected readonly errorId = `${this.inputId}-error`;

  protected readonly suggestions = signal<MentionCandidateDto[]>([]);
  protected readonly active = signal(0);
  protected readonly open = computed(() => this.suggestions().length > 0);
  /** Like the posted comment (`commentDir`): a leading @handle doesn't make an Arabic comment LTR. */
  protected readonly textDir = computed(() => commentDir(this.text()) ?? 'auto');
  protected readonly remaining = computed(() => COMMENT_MAX_LENGTH - this.text().length);
  protected readonly showCounter = computed(() => this.text().length > COMMENT_COUNTER_FROM);
  protected readonly counterText = computed(() => translatePlural(this.transloco, 'comments.composer.remaining', Math.max(0, this.remaining()), this.lang()));
  protected readonly canSend = computed(() => !this.busy() && this.text().trim().length > 0 && this.text().length <= COMMENT_MAX_LENGTH);
  protected readonly describedBy = computed(() => [this.showCounter() ? this.counterId : null, this.error() ? this.errorId : null].filter(Boolean).join(' ') || null);

  private readonly field = viewChild.required<ElementRef<HTMLTextAreaElement>>('field');
  /** The handle being typed, while suggestions are asked for or shown. */
  private mention: MentionQuery | null = null;
  private timer: ReturnType<typeof setTimeout> | null = null;
  private lookup = 0;

  constructor() {
    // Grow with the text, also when the owner sets it (a pre-filled @handle, a restored draft).
    afterRenderEffect(() => {
      this.text();
      this.resize();
    });
    afterNextRender(() => {
      if (this.autofocus()) this.focus();
    });
    inject(DestroyRef).onDestroy(() => this.cancelLookup());
  }

  /** Puts the caret at the end of the text. */
  focus(): void {
    const el = this.field().nativeElement;
    el.focus();
    el.setSelectionRange(el.value.length, el.value.length);
  }

  protected optionId(index: number): string {
    return `${this.listId}-${index}`;
  }

  protected onInput(event: Event): void {
    this.text.set((event.target as HTMLTextAreaElement).value);
    this.lookForMention();
  }

  protected onKeyup(event: KeyboardEvent): void {
    // The caret moved without typing: the handle under it may have changed.
    if (['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) this.lookForMention();
  }

  protected onKeydown(event: KeyboardEvent): void {
    if (this.open()) {
      const count = this.suggestions().length;
      switch (event.key) {
        case 'ArrowDown':
          event.preventDefault();
          this.active.set((this.active() + 1) % count);
          return;
        case 'ArrowUp':
          event.preventDefault();
          this.active.set((this.active() - 1 + count) % count);
          return;
        case 'Enter':
        case 'Tab':
          event.preventDefault();
          this.pick(this.suggestions()[this.active()]);
          return;
        case 'Escape':
          event.preventDefault();
          event.stopPropagation();
          this.closeSuggestions();
          return;
      }
    }
    if (event.key === 'Enter' && (event.ctrlKey || event.metaKey)) {
      event.preventDefault();
      this.send();
    }
  }

  protected pick(person: MentionCandidateDto): void {
    const at = this.mention;
    if (!at) return;
    const { text, caret } = insertMention(this.text(), at, person.username);
    this.text.set(text);
    this.closeSuggestions();
    const el = this.field().nativeElement;
    el.value = text;
    el.focus();
    el.setSelectionRange(caret, caret);
  }

  protected submit(event: Event): void {
    event.preventDefault();
    this.send();
  }

  /** Finds the `@handle` at the caret and asks for suggestions once typing pauses. */
  protected lookForMention(): void {
    const el = this.field().nativeElement;
    const at = el.selectionStart === el.selectionEnd ? mentionAt(el.value, el.selectionStart ?? el.value.length) : null;
    this.cancelLookup();
    this.mention = at;
    if (!at || !at.query) {
      this.suggestions.set([]);
      return;
    }
    const lookup = ++this.lookup;
    this.timer = setTimeout(async () => {
      this.timer = null;
      try {
        const people = await firstValueFrom(this.api.mentionSuggestions(at.query));
        if (lookup !== this.lookup) return;
        this.active.set(0);
        this.suggestions.set(people);
      } catch {
        if (lookup === this.lookup) this.suggestions.set([]); // suggestions are a nicety: typing goes on
      }
    }, MENTION_DEBOUNCE_MS);
  }

  protected closeSuggestions(): void {
    this.cancelLookup();
    this.suggestions.set([]);
  }

  private send(): void {
    if (!this.canSend()) return;
    this.closeSuggestions();
    this.submitted.emit(this.text());
  }

  private cancelLookup(): void {
    this.lookup++;
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
  }

  private resize(): void {
    const el = this.field().nativeElement;
    el.style.height = 'auto';
    el.style.height = `${Math.min(el.scrollHeight, MAX_HEIGHT_PX)}px`;
  }
}
