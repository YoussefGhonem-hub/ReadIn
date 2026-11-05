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
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { translatePlural } from '../../shared/pipes/format.pipes';
import { Avatar } from '../../shared/ui/avatar';
import { COMMENT_COUNTER_FROM, COMMENT_MAX_LENGTH, MentionQuery, commentDir, insertMention, mentionAt } from './comment-text';
import { EmojiPicker } from './emoji-picker';

/** Wait this long after the last keystroke before asking for mention suggestions. */
export const MENTION_DEBOUNCE_MS = 250;
/** The field grows with its text up to this height, then scrolls. */
const MAX_HEIGHT_PX = 240;

let nextId = 0;

/**
 * The comment box (F11): new comments, replies and inline edits, the same in the reader and on feed cards. Your avatar,
 * then a rounded field with the emoji button and the send icon inside it (disabled until there is text; no "نشر" text
 * button), and for replies and edits an ✕ that cancels. Text and emoji only: there is no attachment button.
 *
 * The field grows with its text, keeps its own direction (`dir="auto"`), shows a counter for the last 200 of the 2000
 * characters, and suggests people while you type an `@handle` (`GET /users/mention-suggestions`, debounced). The list is
 * a listbox driven from the field (combobox): ↑/↓ move, Enter or Tab inserts `@username `, Escape closes. Ctrl/⌘ + Enter
 * sends. The emoji picker is its own lazy chunk, loaded the first time the emoji button is pressed; a picked emoji goes
 * in at the caret.
 */
@Component({
  selector: 'rd-comment-composer',
  imports: [TranslocoPipe, LucideDynamicIcon, Avatar, BdiText, EmojiPicker],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', '(document:pointerdown)': 'onDocumentPointer($event)' },
  styles: `
    .comment-field {
      border: 1px solid var(--rd-color-border);
      border-radius: 1.375rem;
      background: var(--rd-color-surface);
      color: var(--rd-color-text-primary);
    }
    .comment-field:focus-within {
      border-color: var(--rd-color-primary);
      box-shadow: 0 0 0 3px var(--rd-color-primary-container);
    }
    .comment-field.is-invalid {
      border-color: var(--rd-color-error);
    }
    .comment-input {
      resize: none;
      border: 0;
      background: transparent;
      color: inherit;
      font: inherit;
    }
    .comment-input:focus {
      outline: none;
    }
    .comment-input::placeholder {
      color: var(--rd-color-text-secondary);
      opacity: 0.8;
    }
  `,
  template: `
    <form class="flex flex-col gap-1.5" (submit)="submit($event)" data-comment-composer>
      <div class="flex items-start gap-2">
        @if (showAvatar() && me(); as me) {
          <rd-avatar class="mt-0.5 shrink-0" [name]="me.displayName" [src]="me.avatarUrl" [size]="avatarSize" aria-hidden="true" data-composer-avatar />
        }
        <div class="relative min-w-0 flex-1">
          <label [for]="inputId" class="sr-only">{{ label() }}</label>
          <div class="comment-field flex items-end gap-0.5 pe-1" [class.is-invalid]="!!error()" data-comment-field>
            <textarea
              #field
              [id]="inputId"
              [attr.dir]="textDir()"
              rows="1"
              class="comment-input block min-h-10 min-w-0 flex-1 py-2 ps-4 leading-relaxed"
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
            <button
              #emojiButton
              type="button"
              class="mb-0.5 grid h-9 w-9 shrink-0 place-items-center rounded-full text-text-secondary hover:bg-surface-variant hover:text-primary"
              [class.text-primary]="emojiOpen()"
              [attr.aria-label]="'commentBox.emoji' | transloco"
              aria-haspopup="dialog"
              [attr.aria-expanded]="emojiOpen()"
              data-comment-emoji
              (click)="toggleEmoji()"
            >
              <svg lucideIcon="FaceSlightlySmiling" [size]="20" aria-hidden="true"></svg>
            </button>
            <button
              type="submit"
              class="mb-0.5 grid h-9 w-9 shrink-0 place-items-center rounded-full disabled:cursor-default disabled:text-text-secondary disabled:opacity-50"
              [class]="canSend() ? 'text-primary hover:bg-primary-container' : ''"
              [disabled]="!canSend()"
              [attr.aria-busy]="busy()"
              [attr.aria-label]="submitLabel()"
              data-comment-send
            >
              @if (busy()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              } @else {
                <svg lucideIcon="SendHorizontal" [size]="19" class="rd-flip-rtl" aria-hidden="true"></svg>
              }
            </button>
          </div>

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

          <!-- The picker is its own chunk, fetched the first time the emoji button is pressed -->
          @if (emojiOpen()) {
            @defer (on immediate) {
              <rd-emoji-picker class="absolute end-0 top-full z-30 mt-1" (picked)="insertEmoji($event)" (closed)="closeEmoji(true)" />
            } @loading {
              <div class="rd-skeleton absolute end-0 top-full z-30 mt-1 h-48 w-64 rounded-card" aria-hidden="true"></div>
            }
          }
        </div>
        @if (cancelable()) {
          <button
            type="button"
            class="mt-0.5 grid h-10 w-10 shrink-0 place-items-center rounded-full text-text-secondary hover:bg-surface-variant"
            [disabled]="busy()"
            [attr.aria-label]="cancelLabel()"
            data-comment-cancel
            (click)="cancelled.emit()"
          >
            <svg lucideIcon="X" [size]="18" aria-hidden="true"></svg>
          </button>
        }
      </div>

      @if (showCounter() || error()) {
        <div class="flex flex-col gap-1.5" [style.padding-inline-start.px]="showAvatar() && me() ? avatarSize + 8 : 0">
          @if (showCounter()) {
            <span [id]="counterId" class="text-xs" [class]="remaining() < 20 ? 'text-error' : 'text-text-secondary'" data-comment-counter>{{ counterText() }}</span>
          }
          @if (error()) {
            <p [id]="errorId" class="rd-alert rd-alert-error m-0" role="alert" data-comment-error>{{ error() }}</p>
          }
        </div>
      }
    </form>
  `,
})
export class CommentComposer {
  private readonly api = inject(CommentsApi);
  private readonly session = inject(SessionStore);
  private readonly transloco = inject(TranslocoService);
  private readonly lang = inject(LanguageService).lang;
  private readonly injector = inject(Injector);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  /** The text (two-way), so the owner can clear it after sending and restore it when sending fails. */
  readonly text = model('');
  readonly label = input.required<string>();
  readonly placeholder = input('');
  /** The send icon's accessible name ("ابعت التعليق", "ابعت الرد", "احفظ"). */
  readonly submitLabel = input.required<string>();
  readonly error = input<string | null>(null);
  readonly busy = input(false);
  /** Replies and edits: an ✕ after the field cancels them. */
  readonly cancelable = input(false);
  /** The ✕'s accessible name. */
  readonly cancelLabel = input('');
  /** Your avatar before the field (not when editing in place: the comment's own avatar is right there). */
  readonly showAvatar = input(true);
  /** Focus the field when it appears (replies and edits open on request); the caret goes to the end. */
  readonly autofocus = input(false);
  readonly submitted = output<string>();
  readonly cancelled = output<void>();

  protected readonly maxLength = COMMENT_MAX_LENGTH;
  protected readonly avatarSize = 36;
  protected readonly inputId = `comment-input-${++nextId}`;
  protected readonly listId = `${this.inputId}-mentions`;
  protected readonly counterId = `${this.inputId}-counter`;
  protected readonly errorId = `${this.inputId}-error`;

  /** You (signed in), for the avatar. */
  protected readonly me = computed(() => (this.session.isAuthenticated() ? this.session.me() : null));
  protected readonly suggestions = signal<MentionCandidateDto[]>([]);
  protected readonly active = signal(0);
  protected readonly open = computed(() => this.suggestions().length > 0);
  protected readonly emojiOpen = signal(false);
  /** Like the posted comment (`commentDir`): a leading @handle doesn't make an Arabic comment LTR. */
  protected readonly textDir = computed(() => commentDir(this.text()) ?? 'auto');
  protected readonly remaining = computed(() => COMMENT_MAX_LENGTH - this.text().length);
  protected readonly showCounter = computed(() => this.text().length > COMMENT_COUNTER_FROM);
  protected readonly counterText = computed(() => translatePlural(this.transloco, 'comments.composer.remaining', Math.max(0, this.remaining()), this.lang()));
  protected readonly canSend = computed(() => !this.busy() && this.text().trim().length > 0 && this.text().length <= COMMENT_MAX_LENGTH);
  protected readonly describedBy = computed(() => [this.showCounter() ? this.counterId : null, this.error() ? this.errorId : null].filter(Boolean).join(' ') || null);

  private readonly field = viewChild.required<ElementRef<HTMLTextAreaElement>>('field');
  private readonly emojiButton = viewChild.required<ElementRef<HTMLButtonElement>>('emojiButton');
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

  /** Puts the caret at the end of the text (after a pre-filled `@handle `). */
  focus(): void {
    const el = this.field().nativeElement;
    el.value = this.text();
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

  // ── Emoji ──

  protected toggleEmoji(): void {
    if (this.emojiOpen()) this.closeEmoji(false);
    else {
      this.closeSuggestions();
      this.emojiOpen.set(true);
    }
  }

  /** Escape in the picker gives the focus back to the emoji button. */
  closeEmoji(restoreFocus: boolean): void {
    if (!this.emojiOpen()) return;
    this.emojiOpen.set(false);
    if (restoreFocus) this.emojiButton().nativeElement.focus();
  }

  /** Puts the emoji at the caret (or over the selection), within the length limit; the picker stays open for more. */
  protected insertEmoji(emoji: string): void {
    const el = this.field().nativeElement;
    const value = this.text();
    if (value.length + emoji.length > COMMENT_MAX_LENGTH) return;
    const start = Math.min(el.selectionStart ?? value.length, value.length);
    const end = Math.max(start, Math.min(el.selectionEnd ?? start, value.length));
    const text = value.slice(0, start) + emoji + value.slice(end);
    const caret = start + emoji.length;
    this.text.set(text);
    el.value = text;
    el.setSelectionRange(caret, caret);
  }

  protected onDocumentPointer(event: Event): void {
    if (this.emojiOpen() && !this.host.nativeElement.contains(event.target as Node)) this.closeEmoji(false);
  }

  private send(): void {
    if (!this.canSend()) return;
    this.closeSuggestions();
    this.closeEmoji(false);
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
