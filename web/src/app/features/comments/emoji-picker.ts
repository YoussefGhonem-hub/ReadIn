import { ChangeDetectionStrategy, Component, ElementRef, Injector, afterNextRender, computed, inject, output, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LanguageService } from '../../core/i18n/language.service';
import { EMOJI_CATEGORIES } from './emoji-data';

/** The grid's columns, for ArrowUp / ArrowDown. */
export const EMOJI_COLUMNS = 8;
const GRID_FOCUS = '[data-emoji-grid] button[tabindex="0"]';

let nextId = 0;

/**
 * The comment box's emoji picker (F11): category tabs, then that category's emoji in a grid. Loaded only when the
 * emoji button is pressed (`@defer` in the comment box), so neither it nor its emoji list are in any bundle before.
 * Picking an emoji emits it and keeps the picker open for more. Keyboard: the tabs and the grid are one Tab stop each
 * (roving focus); arrows follow the reading direction, ArrowUp/ArrowDown move a row, Home/End jump; Escape asks the
 * box to close it.
 */
@Component({
  selector: 'rd-emoji-picker',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <div
      role="dialog"
      tabindex="-1"
      [attr.aria-label]="'emojiPicker.label' | transloco"
      class="w-[min(20rem,calc(100vw-2rem))] overflow-hidden rounded-card border border-border bg-surface-raised shadow-raised"
      data-emoji-picker
      (keydown.escape)="onEscape($event)"
    >
      <div
        role="tablist"
        tabindex="-1"
        [attr.aria-label]="'emojiPicker.categories' | transloco"
        class="flex gap-0.5 overflow-x-auto border-b border-border p-1"
        (keydown)="onTabKey($event)"
      >
        @for (category of categories; track category.id; let i = $index) {
          <button
            type="button"
            role="tab"
            [id]="tabId(i)"
            [attr.aria-selected]="i === current()"
            [attr.aria-controls]="panelId"
            [attr.tabindex]="i === current() ? 0 : -1"
            [attr.aria-label]="'emojiPicker.' + category.id | transloco"
            [attr.title]="'emojiPicker.' + category.id | transloco"
            class="grid h-8 w-8 shrink-0 place-items-center rounded-md text-lg leading-none hover:bg-surface-variant"
            [class.bg-primary-container]="i === current()"
            [attr.data-emoji-category]="category.id"
            (click)="select(i)"
          >
            <span aria-hidden="true">{{ category.emoji[0] }}</span>
          </button>
        }
      </div>
      <div
        [id]="panelId"
        role="tabpanel"
        tabindex="-1"
        [attr.aria-labelledby]="tabId(current())"
        class="grid max-h-56 grid-cols-8 gap-0.5 overflow-y-auto p-1.5"
        data-emoji-grid
        (keydown)="onGridKey($event)"
      >
        @for (item of emoji(); track item; let i = $index) {
          <button
            type="button"
            class="grid aspect-square place-items-center rounded-md text-[22px] leading-none hover:bg-surface-variant focus-visible:bg-surface-variant"
            [attr.tabindex]="i === active() ? 0 : -1"
            [attr.data-emoji]="item"
            (click)="pick(item, i)"
          >
            {{ item }}
          </button>
        }
      </div>
    </div>
  `,
})
export class EmojiPicker {
  private readonly language = inject(LanguageService);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly injector = inject(Injector);
  private readonly uid = nextId++;

  /** An emoji was picked: the box inserts it at the caret. */
  readonly picked = output<string>();
  /** Escape: the box closes the picker and takes the focus back. */
  readonly closed = output<void>();

  protected readonly categories = EMOJI_CATEGORIES;
  protected readonly panelId = `emoji-panel-${this.uid}`;
  protected readonly current = signal(0);
  protected readonly active = signal(0);
  protected readonly emoji = computed(() => EMOJI_CATEGORIES[this.current()].emoji);

  constructor() {
    // Opened from the button: the first emoji takes the focus, so the keyboard can go on from there.
    afterNextRender(() => this.focusNow(GRID_FOCUS));
  }

  protected tabId(index: number): string {
    return `emoji-tab-${this.uid}-${index}`;
  }

  protected select(index: number): void {
    this.current.set(index);
    this.active.set(0);
  }

  protected pick(item: string, index: number): void {
    this.active.set(index);
    this.picked.emit(item);
  }

  protected onEscape(event: Event): void {
    event.preventDefault();
    event.stopPropagation();
    this.closed.emit();
  }

  protected onTabKey(event: KeyboardEvent): void {
    const next = this.step(event, this.current(), EMOJI_CATEGORIES.length, 1);
    if (next === null) return;
    event.preventDefault();
    this.select(next);
    this.focus(`#${this.tabId(next)}`);
  }

  protected onGridKey(event: KeyboardEvent): void {
    const next = this.step(event, this.active(), this.emoji().length, EMOJI_COLUMNS);
    if (next === null) return;
    event.preventDefault();
    this.active.set(next);
    this.focusEmoji();
  }

  /** The index the key moves to (clamped), or null when the key isn't a move. */
  private step(event: KeyboardEvent, index: number, count: number, row: number): number | null {
    const forward = this.language.dir() === 'rtl' ? 'ArrowLeft' : 'ArrowRight';
    const back = this.language.dir() === 'rtl' ? 'ArrowRight' : 'ArrowLeft';
    let next: number;
    switch (event.key) {
      case forward:
        next = index + 1;
        break;
      case back:
        next = index - 1;
        break;
      case 'ArrowDown':
        if (row === 1) return null;
        next = index + row;
        break;
      case 'ArrowUp':
        if (row === 1) return null;
        next = index - row;
        break;
      case 'Home':
        next = 0;
        break;
      case 'End':
        next = count - 1;
        break;
      default:
        return null;
    }
    return Math.min(count - 1, Math.max(0, next));
  }

  private focusEmoji(): void {
    this.focus(GRID_FOCUS);
  }

  private focus(selector: string): void {
    afterNextRender(() => this.focusNow(selector), { injector: this.injector });
  }

  private focusNow(selector: string): void {
    this.host.nativeElement.querySelector<HTMLElement>(selector)?.focus();
  }
}
