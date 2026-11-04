import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  Injector,
  PLATFORM_ID,
  afterNextRender,
  computed,
  inject,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ArticleModerationDto, REACTION_TYPES, ReactionType } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { CompactNumberPipe, translatePlural } from '../../shared/pipes/format.pipes';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { ArticleMenu, MenuArticle } from './article-menu';
import { REACTION_EMOJI } from './reactions';
import { ReactorsSheet } from './reactors-sheet';

/** Hold this long on a touch screen to open the picker. */
const LONG_PRESS_MS = 450;
/** Hover this long with a mouse to open the picker; leaving closes it after `HOVER_CLOSE_MS`. */
const HOVER_OPEN_MS = 400;
const HOVER_CLOSE_MS = 300;

/**
 * Floating action bar of the reader (F04, F10, F11, F13): the reaction button, who reacted, comments (the count; a tap
 * takes you to them), save, share and the "⋯" menu (F22 report and moderation; F28 adds more). The reaction button reacts 💡 on a tap and removes your reaction when you have
 * one; holding it (touch), hovering it (mouse), its ⌃ button or ArrowUp open the picker with the four reactions and
 * their counts.
 * Guests get the soft sign-in prompt. Counts come from ArticleSocialStore (optimistic, live counters on top).
 */
@Component({
  selector: 'rd-article-action-bar',
  imports: [TranslocoPipe, CompactNumberPipe, LucideDynamicIcon, ReactorsSheet, ArticleMenu],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'fixed inset-x-0 bottom-0 z-30 block border-t border-border bg-surface pb-[env(safe-area-inset-bottom)] shadow-raised',
    '(document:pointerdown)': 'onDocumentPointer($event)',
  },
  template: `
    <div class="mx-auto flex h-16 max-w-[720px] items-center justify-between gap-1 px-3">
      <div class="relative flex min-w-0 items-center gap-1" data-reactions>
        <div class="flex items-center" (pointerenter)="hoverIn($event)" (pointerleave)="hoverOut($event)">
          <button
            #trigger
            type="button"
            data-react
            class="grid h-11 min-w-11 select-none place-items-center rounded-s-md px-2 text-[22px] leading-none [-webkit-touch-callout:none]"
            [class]="state().myReaction ? 'bg-primary-container' : 'hover:bg-surface-variant'"
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
            <span aria-hidden="true" [class.grayscale]="!state().myReaction" [class.opacity-70]="!state().myReaction">{{
              emoji[state().myReaction ?? 'insightful']
            }}</span>
          </button>
          <button
            type="button"
            data-reaction-picker-toggle
            class="grid h-11 w-7 place-items-center rounded-e-md text-text-secondary hover:bg-surface-variant"
            [class.bg-primary-container]="!!state().myReaction"
            [attr.aria-label]="'article.reactions.choose' | transloco"
            aria-haspopup="menu"
            [attr.aria-expanded]="pickerOpen()"
            [attr.aria-controls]="pickerOpen() ? 'reaction-picker' : null"
            (click)="togglePicker()"
          >
            <svg lucideIcon="ChevronUp" [size]="16" aria-hidden="true"></svg>
          </button>
        </div>

        @if (pickerOpen()) {
          <div
            id="reaction-picker"
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

        <button
          type="button"
          data-reactions-summary
          class="flex h-11 min-w-11 items-center gap-1.5 rounded-md px-2 text-sm text-text-secondary hover:bg-surface-variant disabled:cursor-default disabled:hover:bg-transparent"
          [disabled]="state().reactionCount === 0"
          [attr.aria-label]="summaryLabel()"
          (click)="whoOpen.set(true)"
        >
          @if (topTypes().length) {
            <span class="flex items-center" aria-hidden="true">
              @for (type of topTypes(); track type) {
                <span class="-ms-1 text-base leading-none first:ms-0">{{ emoji[type] }}</span>
              }
            </span>
          }
          <span aria-hidden="true" data-reaction-total>{{ state().reactionCount | rdCompactNumber: lang() }}</span>
        </button>
      </div>

      <div class="flex shrink-0 items-center gap-1">
        <button
          type="button"
          class="inline-flex min-h-11 items-center gap-1.5 rounded-md bg-primary-container px-3 text-sm font-semibold text-on-primary-container"
          aria-controls="comments"
          data-comment-count
          (click)="commentsOpen.emit()"
        >
          <svg lucideIcon="MessageCircle" [size]="16" aria-hidden="true"></svg>
          {{ state().commentCount | rdCompactNumber: lang() }}
          <span class="sr-only">{{ 'article.comments' | transloco }}</span>
        </button>
        <button
          type="button"
          class="rd-icon-btn h-11 w-11 border-0"
          [class.text-primary]="state().isSaved"
          data-save
          [attr.aria-pressed]="state().isSaved"
          [attr.aria-label]="'article.save' | transloco"
          (click)="toggleSave()"
        >
          <svg lucideIcon="Bookmark" [size]="20" [class.fill-current]="state().isSaved" aria-hidden="true"></svg>
        </button>
        <button type="button" class="rd-icon-btn h-11 w-11 border-0" [attr.aria-label]="'common.share' | transloco" (click)="share()">
          <svg lucideIcon="Share2" [size]="18" aria-hidden="true"></svg>
        </button>
        <rd-article-menu [article]="article()" (moderationChange)="moderationChange.emit($event)" />
      </div>
    </div>

    <rd-reactors-sheet
      [open]="whoOpen()"
      [articleId]="article().id"
      [counts]="state().reactions"
      [total]="state().reactionCount"
      (closed)="whoOpen.set(false)"
    />
  `,
})
export class ArticleActionBar {
  private readonly prompt = inject(AuthPromptService);
  private readonly social = inject(ArticleSocialStore);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly language = inject(LanguageService);
  private readonly injector = inject(Injector);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  protected readonly lang = this.language.lang;
  protected readonly emoji = REACTION_EMOJI;
  protected readonly reactionTypes = REACTION_TYPES;

  readonly article = input.required<MenuArticle>();
  readonly url = input.required<string>();
  /** The comment count was pressed: the reader scrolls to the comments (F11). */
  readonly commentsOpen = output<void>();
  /** A moderator hid the article (its new state) or made it visible again (null), from the "⋯" menu (F22). */
  readonly moderationChange = output<ArticleModerationDto | null>();

  protected readonly state = computed(() => this.social.state(this.article()));
  protected readonly pickerOpen = signal(false);
  protected readonly activeIndex = signal(0);
  protected readonly whoOpen = signal(false);
  private readonly trigger = viewChild.required<ElementRef<HTMLButtonElement>>('trigger');

  /** The most used reactions first, for the "who reacted" button. */
  protected readonly topTypes = computed(() => {
    const { reactions } = this.state();
    return REACTION_TYPES.filter((t) => reactions[t] > 0)
      .sort((a, b) => reactions[b] - reactions[a])
      .slice(0, 3);
  });

  protected readonly reactLabel = computed(() => {
    this.lang();
    const mine = this.state().myReaction;
    const name = (type: ReactionType) => this.transloco.translate(`article.reactions.${type}`);
    return mine
      ? this.transloco.translate('article.reactions.remove', { type: name(mine) })
      : this.transloco.translate('article.reactions.reactWith', { type: name('insightful') });
  });

  protected readonly summaryLabel = computed(() => {
    const lang = this.lang();
    const count = translatePlural(this.transloco, 'article.reactions.count', this.state().reactionCount, lang);
    return this.transloco.translate('article.reactions.summary', { count });
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

  protected toggleSave(): void {
    if (!this.prompt.requireAuth()) return;
    void this.social.toggleSave(this.article());
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

  /** Web Share API when available, otherwise copy the link (F24 basics). */
  protected async share(): Promise<void> {
    if (!this.isBrowser) return;
    const data = { title: this.article().title, url: this.url() };
    try {
      if (navigator.share) {
        await navigator.share(data);
        return;
      }
      await navigator.clipboard.writeText(data.url);
      this.toasts.success(this.transloco.translate('common.linkCopied'));
    } catch {
      /* share sheet dismissed */
    }
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
