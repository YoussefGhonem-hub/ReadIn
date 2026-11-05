import {
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
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
/** The picked reaction's short animation, before the bar closes (none with reduce motion). */
export const PICK_ANIMATION_MS = 300;
/** The reactions enter one after another, this far apart. */
export const STAGGER_MS = 50;
/** The React icon's "pop" once your reaction changed from the bar. */
const POP_MS = 320;

let nextPickerId = 0;

/**
 * The React button (F10) of the reader's action bar and of the post card (F34). A tap reacts 💡, or removes your
 * reaction when you have one; holding it (touch), hovering it (mouse) or ArrowUp open the floating reactions bar, like
 * LinkedIn's: the four reactions with no numbers or text (each has its name as its accessible name), entering one
 * after another; the one under the pointer (or keyboard focus) grows and lifts, and a pick plays a short animation
 * before the bar closes. CSS only; with "reduce motion" everything is instant. Arrows move between the reactions (in
 * the reading direction), Home/End jump, Escape closes, Tab leaves.
 *
 * `card`: icon only, with the reaction count beside it (no number at 0); the icon is your reaction's emoji, or the
 * 💡 line icon. `bar` (the reader): the emoji split button with a ⌃ that opens the bar too. Guests get the soft sign-in
 * prompt. Optimistic through ArticleSocialStore, which rolls back on failure. The host is `display: contents`, so the
 * bar opens above the nearest positioned ancestor's start: the container decides where.
 */
@Component({
  selector: 'rd-reaction-button',
  imports: [TranslocoPipe, CompactNumberPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents', '(document:pointerdown)': 'onDocumentPointer($event)' },
  styles: `
    .reaction-bar {
      transform-origin: 50% 100%;
      animation: reaction-bar-in 180ms cubic-bezier(0.2, 0.9, 0.3, 1.2) both;
    }
    /* Each reaction's animation-delay (one after another) is set on it: STAGGER_MS × its index. */
    .reaction {
      animation: reaction-in 280ms cubic-bezier(0.34, 1.56, 0.64, 1) both;
    }
    .reaction-emoji {
      display: block;
      transform-origin: 50% 85%;
      transition: transform 150ms cubic-bezier(0.34, 1.56, 0.64, 1);
    }
    .reaction:hover .reaction-emoji,
    .reaction:focus-visible .reaction-emoji {
      transform: translateY(-8px) scale(1.45);
    }
    .reaction.is-picked .reaction-emoji {
      animation: reaction-picked ${PICK_ANIMATION_MS}ms ease-in forwards;
    }
    .react-icon {
      display: inline-block;
    }
    .react-icon.is-popping {
      animation: react-pop ${POP_MS}ms cubic-bezier(0.34, 1.56, 0.64, 1);
    }
    @keyframes reaction-bar-in {
      from {
        opacity: 0;
        transform: translateY(8px) scale(0.9);
      }
    }
    @keyframes reaction-in {
      from {
        opacity: 0;
        transform: translateY(12px) scale(0.3);
      }
    }
    @keyframes reaction-picked {
      0% {
        transform: translateY(-8px) scale(1.45);
      }
      45% {
        transform: translateY(-18px) scale(1.9);
      }
      100% {
        transform: translateY(-30px) scale(0.8);
        opacity: 0;
      }
    }
    @keyframes react-pop {
      0% {
        transform: scale(0.4);
      }
      60% {
        transform: scale(1.35);
      }
      100% {
        transform: scale(1);
      }
    }
    @media (prefers-reduced-motion: reduce) {
      .reaction-bar,
      .reaction,
      .reaction-emoji,
      .react-icon,
      .reaction.is-picked .reaction-emoji,
      .react-icon.is-popping {
        animation: none !important;
        transition: none !important;
      }
      .reaction:hover .reaction-emoji,
      .reaction:focus-visible .reaction-emoji {
        transform: none;
      }
    }
  `,
  template: `
    <div class="flex items-center" (pointerenter)="hoverIn($event)" (pointerleave)="hoverOut($event)">
      <button
        #trigger
        type="button"
        data-react
        [class]="triggerClass()"
        [attr.data-my-reaction]="state().myReaction"
        [attr.aria-pressed]="!!state().myReaction"
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
          @if (state().myReaction; as mine) {
            <span class="react-icon text-[19px] leading-none" [class.is-popping]="popping()" aria-hidden="true" data-react-icon>{{ emoji[mine] }}</span>
          } @else {
            <svg lucideIcon="Lightbulb" [size]="20" aria-hidden="true" data-react-icon></svg>
          }
          @if (state().reactionCount > 0) {
            <span aria-hidden="true" data-react-count>{{ state().reactionCount | rdCompactNumber: lang() }}</span>
          }
        } @else {
          <span
            class="react-icon"
            aria-hidden="true"
            [class.is-popping]="popping()"
            [class.grayscale]="!state().myReaction"
            [class.opacity-70]="!state().myReaction"
            >{{ emoji[state().myReaction ?? 'insightful'] }}</span
          >
        }
      </button>
      @if (variant() === 'bar') {
        <button
          type="button"
          data-reaction-picker-toggle
          class="grid h-11 w-6 place-items-center rounded-e-md text-text-secondary hover:bg-surface-variant sm:w-7"
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
      <!-- The floating reactions bar: no numbers or text, the counts stay in "who reacted" (F10). -->
      <div
        [id]="pickerId"
        role="menu"
        aria-orientation="horizontal"
        data-reaction-picker
        tabindex="-1"
        [attr.aria-label]="'article.reactions.label' | transloco"
        [attr.data-picked]="picked()"
        class="reaction-bar absolute bottom-full start-0 z-10 mb-2 flex gap-0.5 rounded-full border border-border bg-surface-raised px-1.5 py-1 shadow-raised"
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
            [attr.aria-label]="'article.reactions.' + reaction | transloco"
            class="reaction grid h-12 w-12 place-items-center rounded-full outline-offset-2"
            [style.animation-delay.ms]="i * staggerMs"
            [class.bg-primary-container]="state().myReaction === reaction"
            [class.is-picked]="picked() === reaction"
            (click)="pick(reaction)"
          >
            <span class="reaction-emoji text-[28px] leading-none" aria-hidden="true">{{ emoji[reaction] }}</span>
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
  private readonly document = inject(DOCUMENT);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  protected readonly lang = this.language.lang;
  protected readonly emoji = REACTION_EMOJI;
  protected readonly reactionTypes = REACTION_TYPES;
  protected readonly staggerMs = STAGGER_MS;
  protected readonly pickerId = `reaction-picker-${nextPickerId++}`;

  readonly article = input.required<ArticleCardDto>();
  /** `bar`: the reader's split button (emoji + ⌃). `card`: the post card's icon with the count. */
  readonly variant = input<'bar' | 'card'>('bar');

  protected readonly state = computed(() => this.social.state(this.article()));
  protected readonly pickerOpen = signal(false);
  protected readonly activeIndex = signal(0);
  /** The reaction picked from the bar while its animation plays. */
  protected readonly picked = signal<ReactionType | null>(null);
  /** The React icon pops once after a pick. */
  protected readonly popping = signal(false);
  private readonly trigger = viewChild.required<ElementRef<HTMLButtonElement>>('trigger');

  protected readonly triggerClass = computed(() => {
    const mine = !!this.state().myReaction;
    if (this.variant() === 'card') {
      return (
        'flex min-h-11 min-w-11 select-none items-center justify-center gap-1.5 rounded-md px-2.5 text-sm font-semibold [-webkit-touch-callout:none] hover:bg-surface-variant ' +
        (mine ? 'text-primary' : 'text-text-secondary')
      );
    }
    return (
      'grid h-11 min-w-11 select-none place-items-center rounded-s-md px-2 text-[22px] leading-none [-webkit-touch-callout:none] ' +
      (mine ? 'bg-primary-container' : 'hover:bg-surface-variant')
    );
  });

  /** "تفاعل، 12" / "تفاعلت: مفيد، 12" (the count on the card only, when > 0); pressed when you reacted. */
  protected readonly reactLabel = computed(() => {
    this.lang();
    const { myReaction, reactionCount } = this.state();
    const count = this.variant() === 'card' && reactionCount > 0 ? reactionCount : null;
    if (myReaction) {
      const type = this.transloco.translate(`article.reactions.${myReaction}`);
      return this.transloco.translate(count === null ? 'postBar.reacted' : 'postBar.reactedCount', { type, count });
    }
    return this.transloco.translate(count === null ? 'postBar.react' : 'postBar.reactCount', { count });
  });

  private openedBy: 'hover' | 'other' = 'other';
  private longPressed = false;
  private pressTimer: ReturnType<typeof setTimeout> | null = null;
  private hoverTimer: ReturnType<typeof setTimeout> | null = null;
  private pickTimer: ReturnType<typeof setTimeout> | null = null;
  private popTimer: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    inject(DestroyRef).onDestroy(() => {
      this.clearPress();
      this.clearHover();
      this.clearTimer('pickTimer');
      this.clearTimer('popTimer');
    });
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

  /** Picks `type` at once (optimistic); the bar closes after the pick's animation, or right away with reduce motion. */
  protected pick(type: ReactionType): void {
    if (this.picked()) return; // the bar is already closing
    if (!this.prompt.requireAuth()) {
      this.closePicker(true);
      return;
    }
    void this.social.pick(this.article(), type);
    if (this.reducedMotion()) {
      this.closePicker(true);
      return;
    }
    this.clearHover();
    this.picked.set(type);
    this.pickTimer = setTimeout(() => {
      this.pickTimer = null;
      this.closePicker(true);
      this.pop();
    }, PICK_ANIMATION_MS);
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
    // A new press: a hold that opened the bar without a click after it (most phones) must not swallow this tap.
    this.longPressed = false;
    if (event.pointerType === 'mouse') return;
    this.clearPress();
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
    if (event.pointerType !== 'mouse' || this.picked()) return;
    this.clearHover();
    if (!this.pickerOpen()) this.hoverTimer = setTimeout(() => this.openPicker('hover', false), HOVER_OPEN_MS);
  }

  protected hoverOut(event: PointerEvent): void {
    if (event.pointerType !== 'mouse' || this.picked()) return;
    this.clearHover();
    if (this.pickerOpen() && this.openedBy === 'hover') this.hoverTimer = setTimeout(() => this.closePicker(false), HOVER_CLOSE_MS);
  }

  protected onDocumentPointer(event: Event): void {
    if (this.pickerOpen() && !this.picked() && !this.host.nativeElement.contains(event.target as Node)) this.closePicker(false);
  }

  /** Roving focus in the bar: arrows follow the reading direction, Home/End jump, Escape closes, Tab leaves. */
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
    this.clearTimer('pickTimer');
    this.picked.set(null);
    if (!this.pickerOpen()) return;
    this.pickerOpen.set(false);
    if (restoreFocus) this.trigger().nativeElement.focus();
  }

  /** The React icon's short pop after a pick from the bar. */
  private pop(): void {
    this.clearTimer('popTimer');
    this.popping.set(true);
    this.popTimer = setTimeout(() => {
      this.popTimer = null;
      this.popping.set(false);
    }, POP_MS);
  }

  private focusActive(): void {
    afterNextRender(
      () => this.host.nativeElement.querySelector<HTMLElement>(`[data-reaction-picker] [data-reaction="${REACTION_TYPES[this.activeIndex()]}"]`)?.focus(),
      { injector: this.injector },
    );
  }

  private reducedMotion(): boolean {
    return !!this.document.defaultView?.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  }

  private clearPress(): void {
    if (this.pressTimer) clearTimeout(this.pressTimer);
    this.pressTimer = null;
  }

  private clearHover(): void {
    if (this.hoverTimer) clearTimeout(this.hoverTimer);
    this.hoverTimer = null;
  }

  private clearTimer(name: 'pickTimer' | 'popTimer'): void {
    const timer = this[name];
    if (timer) clearTimeout(timer);
    this[name] = null;
  }
}
