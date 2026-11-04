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
  signal,
  viewChild,
} from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleCardDto, REACTION_TYPES, ReactionType } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { CompactNumberPipe } from '../../shared/pipes/format.pipes';
import { REACTION_EMOJI } from './reactions';

/** Hold this long on a touch screen to open the picker. */
const LONG_PRESS_MS = 450;
/** Hover this long with a mouse to open the picker; leaving closes it after `HOVER_CLOSE_MS`. */
const HOVER_OPEN_MS = 400;
const HOVER_CLOSE_MS = 300;

let nextPickerId = 0;

/**
 * The reaction button (F10) of the reader's action bar and of the post card (F34). A tap reacts 💡, or removes your
 * reaction when you have one; holding it (touch), hovering it (mouse) or ArrowUp open the picker with the four
 * reactions and their counts. The reader's bar (`bar`) adds a ⌃ button that opens the picker too; the card's
 * (`card`) shows its name ("تفاعل", or your reaction's) next to the emoji. Guests get the soft sign-in prompt.
 * Optimistic through ArticleSocialStore, which rolls back on failure. The host is `display: contents`, so the picker
 * opens above the nearest positioned ancestor's start: the container decides where.
 */
@Component({
  selector: 'rd-reaction-button',
  imports: [TranslocoPipe, CompactNumberPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents', '(document:pointerdown)': 'onDocumentPointer($event)' },
  template: `
    <div class="flex items-center" [class.flex-1]="variant() === 'card'" (pointerenter)="hoverIn($event)" (pointerleave)="hoverOut($event)">
      <button
        #trigger
        type="button"
        data-react
        [class]="triggerClass()"
        [attr.data-my-reaction]="state().myReaction"
        [attr.aria-label]="reactLabel()"
        aria-keyshortcuts="ArrowUp"
        (click)="tap()"
        (pointerdown)="pressStart($event)"
        (pointerup)="pressEnd()"
        (pointercancel)="pressEnd()"
        (contextmenu)="onContextMenu($event)"
        (keydown.arrowup)="openFromKeyboard($event)"
      >
        @if (variant() === 'card') {
          <span
            class="text-lg leading-none"
            aria-hidden="true"
            [class.grayscale]="!state().myReaction"
            [class.opacity-70]="!state().myReaction"
            >{{ emoji[state().myReaction ?? 'insightful'] }}</span
          >
          <span aria-hidden="true">{{ (state().myReaction ? 'article.reactions.' + state().myReaction : 'feedCard.react') | transloco }}</span>
        } @else {
          <span aria-hidden="true" [class.grayscale]="!state().myReaction" [class.opacity-70]="!state().myReaction">{{
            emoji[state().myReaction ?? 'insightful']
          }}</span>
        }
      </button>
      @if (variant() === 'bar') {
        <button
          type="button"
          data-reaction-picker-toggle
          class="grid h-11 w-7 place-items-center rounded-e-md text-text-secondary hover:bg-surface-variant"
          [class.bg-primary-container]="!!state().myReaction"
          [attr.aria-label]="'article.reactions.choose' | transloco"
          aria-haspopup="menu"
          [attr.aria-expanded]="pickerOpen()"
          [attr.aria-controls]="pickerOpen() ? pickerId : null"
          (click)="togglePicker()"
        >
          <svg lucideIcon="ChevronUp" [size]="16" aria-hidden="true"></svg>
        </button>
      }
    </div>

    @if (pickerOpen()) {
      <div
        [id]="pickerId"
        role="menu"
        aria-orientation="horizontal"
        data-reaction-picker
        tabindex="-1"
        [attr.aria-label]="'article.reactions.label' | transloco"
        class="absolute bottom-full start-0 z-10 mb-2 flex gap-1 rounded-card border border-border bg-surface-raised p-1.5 shadow-raised"
        (pointerenter)="hoverIn($event)"
        (pointerleave)="hoverOut($event)"
        (keydown)="onPickerKey($event)"
      >
        @for (reaction of reactionTypes; track reaction; let i = $index) {
          <button
            type="button"
            role="menuitemradio"
            [attr.aria-checked]="state().myReaction === reaction"
            [attr.data-reaction]="reaction"
            [attr.tabindex]="i === activeIndex() ? 0 : -1"
            [attr.aria-label]="optionLabel(reaction)"
            class="flex min-h-12 min-w-12 flex-col items-center justify-center gap-0.5 rounded-md px-1.5 text-[11px] text-text-secondary transition-transform hover:-translate-y-0.5 hover:bg-surface-variant motion-reduce:hover:translate-y-0"
            [class.bg-primary-container]="state().myReaction === reaction"
            [class.text-on-primary-container]="state().myReaction === reaction"
            (click)="pick(reaction)"
          >
            <span class="text-2xl leading-none" aria-hidden="true">{{ emoji[reaction] }}</span>
            <span aria-hidden="true" [attr.data-reaction-count]="reaction">{{ state().reactions[reaction] | rdCompactNumber: lang() }}</span>
          </button>
        }
      </div>
    }
  `,
})
export class ReactionButton {
  private readonly prompt = inject(AuthPromptService);
  private readonly social = inject(ArticleSocialStore);
  private readonly transloco = inject(TranslocoService);
  private readonly language = inject(LanguageService);
  private readonly injector = inject(Injector);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  protected readonly lang = this.language.lang;
  protected readonly emoji = REACTION_EMOJI;
  protected readonly reactionTypes = REACTION_TYPES;
  protected readonly pickerId = `reaction-picker-${nextPickerId++}`;

  readonly article = input.required<ArticleCardDto>();
  /** `bar`: the reader's split button (emoji + ⌃). `card`: the post card's action, emoji and name. */
  readonly variant = input<'bar' | 'card'>('bar');

  protected readonly state = computed(() => this.social.state(this.article()));
  protected readonly pickerOpen = signal(false);
  protected readonly activeIndex = signal(0);
  private readonly trigger = viewChild.required<ElementRef<HTMLButtonElement>>('trigger');

  protected readonly triggerClass = computed(() => {
    const mine = !!this.state().myReaction;
    if (this.variant() === 'card') {
      return (
        'flex min-h-11 w-full select-none items-center justify-center gap-1.5 rounded-md px-2 text-sm font-semibold [-webkit-touch-callout:none] hover:bg-surface-variant ' +
        (mine ? 'text-primary' : 'text-text-secondary')
      );
    }
    return (
      'grid h-11 min-w-11 select-none place-items-center rounded-s-md px-2 text-[22px] leading-none [-webkit-touch-callout:none] ' +
      (mine ? 'bg-primary-container' : 'hover:bg-surface-variant')
    );
  });

  protected readonly reactLabel = computed(() => {
    this.lang();
    const mine = this.state().myReaction;
    const name = (type: ReactionType) => this.transloco.translate(`article.reactions.${type}`);
    return mine
      ? this.transloco.translate('article.reactions.remove', { type: name(mine) })
      : this.transloco.translate('article.reactions.reactWith', { type: name('insightful') });
  });

  private openedBy: 'hover' | 'other' = 'other';
  private longPressed = false;
  private pressTimer: ReturnType<typeof setTimeout> | null = null;
  private hoverTimer: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    inject(DestroyRef).onDestroy(() => {
      this.clearPress();
      this.clearHover();
    });
  }

  protected optionLabel(type: ReactionType): string {
    this.lang();
    return `${this.transloco.translate(`article.reactions.${type}`)} (${this.state().reactions[type]})`;
  }

  protected tap(): void {
    if (this.longPressed) {
      this.longPressed = false; // the hold opened the picker; its click is not a tap
      return;
    }
    if (!this.prompt.requireAuth()) return;
    this.closePicker(false);
    void this.social.tap(this.article());
  }

  protected pick(type: ReactionType): void {
    this.closePicker(true);
    if (!this.prompt.requireAuth()) return;
    void this.social.pick(this.article(), type);
  }

  protected togglePicker(): void {
    if (this.pickerOpen()) this.closePicker(false);
    else this.openPicker('other', true);
  }

  protected openFromKeyboard(event: Event): void {
    event.preventDefault();
    this.openPicker('other', true);
  }

  // ── Touch: hold to open ──

  protected pressStart(event: PointerEvent): void {
    if (event.pointerType === 'mouse') return;
    this.clearPress();
    this.longPressed = false;
    this.pressTimer = setTimeout(() => {
      this.longPressed = true;
      this.openPicker('other', false);
    }, LONG_PRESS_MS);
  }

  protected pressEnd(): void {
    this.clearPress();
  }

  /** A long press must not open the browser's context menu on the button. */
  protected onContextMenu(event: Event): void {
    if ((event as PointerEvent).pointerType !== 'mouse') event.preventDefault();
  }

  // ── Mouse: hover to open ──

  protected hoverIn(event: PointerEvent): void {
    if (event.pointerType !== 'mouse') return;
    this.clearHover();
    if (!this.pickerOpen()) this.hoverTimer = setTimeout(() => this.openPicker('hover', false), HOVER_OPEN_MS);
  }

  protected hoverOut(event: PointerEvent): void {
    if (event.pointerType !== 'mouse') return;
    this.clearHover();
    if (this.pickerOpen() && this.openedBy === 'hover') this.hoverTimer = setTimeout(() => this.closePicker(false), HOVER_CLOSE_MS);
  }

  protected onDocumentPointer(event: Event): void {
    if (this.pickerOpen() && !this.host.nativeElement.contains(event.target as Node)) this.closePicker(false);
  }

  /** Roving focus in the picker: arrows follow the reading direction, Home/End jump, Escape closes, Tab leaves. */
  protected onPickerKey(event: KeyboardEvent): void {
    const rtl = this.language.dir() === 'rtl';
    const index = this.activeIndex();
    let next: number;
    switch (event.key) {
      case 'ArrowRight':
        next = rtl ? index - 1 : index + 1;
        break;
      case 'ArrowLeft':
        next = rtl ? index + 1 : index - 1;
        break;
      case 'Home':
        next = 0;
        break;
      case 'End':
        next = REACTION_TYPES.length - 1;
        break;
      case 'Escape':
        event.preventDefault();
        event.stopPropagation();
        this.closePicker(true);
        return;
      case 'Tab':
        this.closePicker(false);
        return;
      default:
        return;
    }
    event.preventDefault();
    this.activeIndex.set((next + REACTION_TYPES.length) % REACTION_TYPES.length);
    this.focusActive();
  }

  private openPicker(by: 'hover' | 'other', focus: boolean): void {
    this.clearHover();
    this.openedBy = by;
    const mine = this.state().myReaction;
    this.activeIndex.set(mine ? REACTION_TYPES.indexOf(mine) : 0);
    this.pickerOpen.set(true);
    if (focus) this.focusActive();
  }

  private closePicker(restoreFocus: boolean): void {
    this.clearHover();
    if (!this.pickerOpen()) return;
    this.pickerOpen.set(false);
    if (restoreFocus) this.trigger().nativeElement.focus();
  }

  private focusActive(): void {
    afterNextRender(
      () => this.host.nativeElement.querySelector<HTMLElement>(`[data-reaction-picker] [data-reaction="${REACTION_TYPES[this.activeIndex()]}"]`)?.focus(),
      { injector: this.injector },
    );
  }

  private clearPress(): void {
    if (this.pressTimer) clearTimeout(this.pressTimer);
    this.pressTimer = null;
  }

  private clearHover(): void {
    if (this.hoverTimer) clearTimeout(this.hoverTimer);
    this.hoverTimer = null;
  }
}
