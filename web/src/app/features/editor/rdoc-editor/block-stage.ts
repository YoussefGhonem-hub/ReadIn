import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
  untracked,
} from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { Editor } from '@tiptap/core';
import { EditorView } from '@tiptap/pm/view';
import { blockIndexById, blockPositions, deleteBlockTr, moveBlockTr, selectedBlockIndex, setBlockMarks } from './block-moves';
import { placePopup } from './popup-place';

/** Space between the handle and the text, in px. */
const GAP = 6;
/** The handle is a small pill: its padding plus border around the buttons, in px. */
const PAD = 4;
/** The handle's buttons: small next to a mouse, 44 px on touch screens. */
const FINE = { width: 24, height: 24 };
const COARSE = { width: 44, height: 44 };
/** What a dragged block carries (not text: dropped anywhere else, it inserts nothing). */
const BLOCK_MIME = 'application/x-readin-block';

type BlockAction = 'up' | 'down' | 'delete';

interface HandleState {
  id: string;
  left: number;
  top: number;
  /** Grip and trash side by side (true) or stacked (a narrow gutter). */
  row: boolean;
}

interface MenuState {
  id: string;
  left: number;
  top: number;
  /** The button that opened the menu (the grip, the toolbar's block button). */
  anchor: HTMLElement;
  /** Where focus goes back to on Escape or after a keyboard action. */
  returnFocus: HTMLElement | null;
}

/**
 * The editor's stage: the editing surface (projected) and, over it, the block handle. Hovering a block, or putting
 * the cursor in it, shows a grip and a trash button at the block's start edge (the article direction's), outside the
 * text. Dragging the grip moves the whole block (a line shows where it will land); clicking or tapping it opens a menu
 * (move up, move down, delete); the trash button deletes the block. Every change is one transaction (undo, autosave).
 *
 * Where the start edge has no room (phones, narrow windows), the handle stays hidden and {@link gutterChange} tells the
 * editor to offer the same menu from its toolbar ({@link openMenu}) for the block holding the cursor.
 */
@Component({
  selector: 'rd-block-stage',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'rd-ed-stage',
    '(focusin)': 'refresh()',
    '(focusout)': 'focusLeft()',
    '(window:resize)': 'refresh()',
  },
  styles: `
    :host {
      display: block;
      position: relative;
    }
    /* A small floating pill at the block's start edge: the grip and the trash, on the raised surface. */
    .handle {
      position: absolute;
      z-index: 5;
      display: flex;
      flex-direction: column;
      gap: 2px;
      padding: ${PAD - 1}px;
      border: 1px solid var(--rd-color-border);
      border-radius: 10px;
      background: var(--rd-color-surface-raised);
      box-shadow:
        0 1px 2px rgb(0 0 0 / 0.06),
        0 4px 12px rgb(0 0 0 / 0.07);
      visibility: hidden;
      opacity: 0;
      transform: scale(0.96);
      transition:
        opacity 120ms ease,
        transform 120ms ease,
        visibility 0s linear 120ms;
    }
    .handle.shown {
      visibility: visible;
      opacity: 1;
      transform: none;
      transition:
        opacity 120ms ease,
        transform 120ms ease;
    }
    @media (prefers-reduced-motion: reduce) {
      .handle,
      .handle.shown {
        transform: none;
        transition: none;
      }
    }
    /* Side by side, the grip next to the text: on its left in an RTL article, on its right in an LTR one. */
    .handle.row {
      flex-direction: row;
    }
    .handle.reverse {
      flex-direction: row-reverse;
    }
    .btn {
      display: grid;
      place-items: center;
      width: ${FINE.width}px;
      height: ${FINE.height}px;
      padding: 0;
      border: 0;
      border-radius: 7px;
      background: transparent;
      color: var(--rd-color-text-secondary);
      cursor: pointer;
      touch-action: manipulation;
      transition:
        background-color 120ms ease,
        color 120ms ease;
    }
    .coarse .btn {
      width: ${COARSE.width}px;
      height: ${COARSE.height}px;
    }
    .grip {
      cursor: grab;
    }
    .btn:hover,
    .btn:focus-visible,
    .grip[aria-expanded='true'] {
      background: var(--rd-color-surface-variant);
      color: var(--rd-color-text-primary);
    }
    .btn:focus-visible {
      outline: 2px solid var(--rd-color-primary);
      outline-offset: 1px;
    }
    /* Delete stays quiet until you point at it: then the error colour on a soft tint of it. */
    .trash:hover,
    .trash:focus-visible {
      background: color-mix(in srgb, var(--rd-color-error) 12%, transparent);
      color: var(--rd-color-error);
    }
    .trash:active {
      background: color-mix(in srgb, var(--rd-color-error) 20%, transparent);
    }
    .trash:focus-visible {
      outline-color: var(--rd-color-error);
    }
    .bridge {
      position: absolute;
      top: 0;
      bottom: 0;
    }
    .dropline {
      position: absolute;
      z-index: 5;
      height: 3px;
      border-radius: 2px;
      background: var(--rd-color-primary);
      pointer-events: none;
    }
    .menu {
      position: fixed;
      z-index: 60;
      width: 240px;
      padding: 4px;
      border: 1px solid var(--rd-color-border);
      border-radius: var(--rd-radius-md);
      background: var(--rd-color-surface-raised);
      box-shadow: var(--rd-elevation-raised);
    }
    .item {
      display: flex;
      align-items: center;
      gap: 10px;
      width: 100%;
      min-height: 40px;
      padding: 0 10px;
      border: 0;
      border-radius: var(--rd-radius-sm);
      background: transparent;
      color: var(--rd-color-text-primary);
      font: inherit;
      font-size: var(--rd-text-meta-size);
      text-align: start;
      cursor: pointer;
    }
    .item:hover:not(:disabled),
    .item:focus-visible {
      background: var(--rd-color-surface-variant);
      outline: none;
    }
    .item:disabled {
      opacity: 0.45;
      cursor: not-allowed;
    }
    .danger {
      color: var(--rd-color-error);
    }
    kbd {
      margin-inline-start: auto;
      color: var(--rd-color-text-secondary);
      font-family: inherit;
      font-size: var(--rd-text-caption-size);
    }
    @media (pointer: coarse) {
      .item {
        min-height: 44px;
      }
      kbd {
        display: none;
      }
    }
  `,
  template: `
    <ng-content />
    @if (bridge(); as b) {
      <div class="bridge" aria-hidden="true" [style.left.px]="b.left" [style.width.px]="b.width"></div>
    }
    <div
      class="handle"
      dir="ltr"
      [class.shown]="!!handle()"
      [class.coarse]="coarse"
      [class.row]="!!handle()?.row"
      [class.reverse]="!!handle()?.row && dir() === 'ltr'"
      [style.left.px]="handle()?.left ?? 0"
      [style.top.px]="handle()?.top ?? 0"
      [attr.data-for]="handle()?.id"
      data-block-handle
      (mouseenter)="handleHovered.set(true); syncMarks()"
      (mouseleave)="handleHovered.set(false); syncMarks()"
    >
      <div
        #grip
        class="btn grip"
        role="button"
        tabindex="0"
        draggable="true"
        aria-haspopup="menu"
        [attr.aria-expanded]="menuOpen()"
        [attr.aria-label]="'editor.blockHandle.options' | transloco"
        [attr.title]="'editor.blockHandle.hint' | transloco"
        data-block-grip
        (click)="toggleMenu(grip, false)"
        (keydown)="gripKey($event, grip)"
        (dragstart)="dragStart($event)"
        (dragend)="endDrag()"
      >
        <svg lucideIcon="GripVertical" [size]="16" aria-hidden="true"></svg>
      </div>
      <button
        type="button"
        class="btn trash"
        [attr.aria-label]="'editor.blockHandle.delete' | transloco"
        [title]="'editor.blockHandle.delete' | transloco"
        data-block-delete
        (mousedown)="$event.preventDefault()"
        (click)="act('delete', $event.detail === 0, handle()?.id)"
      >
        <svg lucideIcon="Trash2" [size]="16" aria-hidden="true"></svg>
      </button>
    </div>
    @if (dropLine(); as line) {
      <div class="dropline" aria-hidden="true" [style.top.px]="line.top" [style.left.px]="line.left" [style.width.px]="line.width" data-drop-indicator></div>
    }
    @if (menu(); as m) {
      <div
        class="menu"
        role="menu"
        tabindex="-1"
        [attr.aria-label]="'editor.blockHandle.options' | transloco"
        [attr.dir]="uiDir()"
        [style.left.px]="m.left"
        [style.top.px]="m.top"
        data-block-menu
        (keydown)="menuKey($event)"
      >
        <button type="button" role="menuitem" class="item" [disabled]="!menuInfo().canUp" data-block-action="up" (mousedown)="$event.preventDefault()" (click)="act('up', $event.detail === 0, m.id)">
          <svg lucideIcon="ChevronUp" [size]="16" aria-hidden="true"></svg>
          {{ 'editor.blockHandle.moveUp' | transloco }}
          <kbd dir="ltr">Alt+Shift+↑</kbd>
        </button>
        <button type="button" role="menuitem" class="item" [disabled]="!menuInfo().canDown" data-block-action="down" (mousedown)="$event.preventDefault()" (click)="act('down', $event.detail === 0, m.id)">
          <svg lucideIcon="ChevronDown" [size]="16" aria-hidden="true"></svg>
          {{ 'editor.blockHandle.moveDown' | transloco }}
          <kbd dir="ltr">Alt+Shift+↓</kbd>
        </button>
        <button type="button" role="menuitem" class="item danger" data-block-action="delete" (mousedown)="$event.preventDefault()" (click)="act('delete', $event.detail === 0, m.id)">
          <svg lucideIcon="Trash2" [size]="16" aria-hidden="true"></svg>
          {{ 'editor.blockHandle.delete' | transloco }}
        </button>
      </div>
    }
    <p class="sr-only" aria-live="polite" data-block-status>{{ status() }}</p>
  `,
})
export class BlockStage {
  private readonly transloco = inject(TranslocoService);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;

  readonly editor = input<Editor | null>(null);
  /** Bumped on every editor transaction. */
  readonly tick = input(0);
  /** The article's direction: the handle sits on its start side. */
  readonly dir = input<'rtl' | 'ltr'>('rtl');
  /** Whether the handle fits at the start edge; when it doesn't, the editor offers the menu from its toolbar. */
  readonly gutterChange = output<boolean>();

  protected readonly coarse = typeof matchMedia === 'function' && matchMedia('(pointer: coarse)').matches;
  private readonly size = this.coarse ? COARSE : FINE;

  protected readonly handle = signal<HandleState | null>(null);
  protected readonly bridge = signal<{ left: number; width: number } | null>(null);
  protected readonly dropLine = signal<{ top: number; left: number; width: number } | null>(null);
  protected readonly menu = signal<MenuState | null>(null);
  protected readonly status = signal('');
  protected readonly handleHovered = signal(false);
  readonly menuOpen = computed(() => !!this.menu());
  protected readonly menuInfo = computed(() => {
    this.tick();
    const doc = this.editor()?.state.doc;
    const id = this.menu()?.id;
    const index = doc && id ? blockIndexById(doc, id) : -1;
    return { canUp: index > 0, canDown: !!doc && index >= 0 && index < doc.childCount - 1 };
  });
  protected readonly uiDir = () => (typeof document !== 'undefined' && document.documentElement.dir === 'rtl' ? 'rtl' : 'ltr');

  /** The block under the pointer. */
  private hoverId: string | null = null;
  /** Kept while the handle has keyboard focus, so the handle stays on its block when that block moves. */
  private pinnedId: string | null = null;
  private drag: { id: string } | null = null;
  private gutter: boolean | null = null;
  private frame: number | null = null;
  private pointerY = 0;

  constructor() {
    const destroyRef = inject(DestroyRef);
    // A new editor (another language version, a restored revision): nothing carries over.
    effect(() => {
      this.editor();
      untracked(() => {
        this.hoverId = this.pinnedId = null;
        this.drag = null;
        this.menu.set(null);
        this.dropLine.set(null);
      });
    });
    effect(() => {
      this.tick();
      this.editor();
      untracked(() => this.refresh());
    });

    afterNextRender(() => {
      const listeners: [EventTarget, string, EventListener, boolean][] = [
        [this.host, 'mousemove', ((event: MouseEvent) => this.pointerMoved(event.clientY)) as EventListener, false],
        [this.host, 'mouseleave', () => this.pointerLeft(), false],
        // Capture: a block being dragged never reaches ProseMirror's own drop handling (or the drop cursor).
        [this.host, 'dragenter', ((event: DragEvent) => this.dragOver(event)) as EventListener, true],
        [this.host, 'dragover', ((event: DragEvent) => this.dragOver(event)) as EventListener, true],
        [this.host, 'dragleave', ((event: DragEvent) => this.dragLeft(event)) as EventListener, true],
        [this.host, 'drop', ((event: DragEvent) => this.drop(event)) as EventListener, true],
        [document, 'mousedown', ((event: MouseEvent) => this.outsideMenu(event)) as EventListener, true],
        [document, 'keydown', ((event: KeyboardEvent) => this.escapeMenu(event)) as EventListener, true],
      ];
      for (const [target, type, listener, capture] of listeners) target.addEventListener(type, listener, capture);
      const resize = typeof ResizeObserver === 'function' ? new ResizeObserver(() => this.refresh()) : null;
      resize?.observe(this.host);
      destroyRef.onDestroy(() => {
        for (const [target, type, listener, capture] of listeners) target.removeEventListener(type, listener, capture);
        resize?.disconnect();
        if (this.frame !== null) cancelAnimationFrame(this.frame);
      });
      this.refresh();
    });
  }

  /** Opens the block menu under `anchor` for the block holding the cursor (the toolbar's block button). */
  openMenu(anchor: HTMLElement, viaKeyboard: boolean, id?: string): void {
    const view = this.view();
    const blockId = id ?? (view ? this.selectedId(view) : null);
    if (!view || !blockId) return;
    const active = document.activeElement;
    const { left, top } = placePopup(anchor.getBoundingClientRect(), { width: 240, height: 140 });
    this.menu.set({ id: blockId, left, top, anchor, returnFocus: active instanceof HTMLElement ? active : null });
    this.syncMarks();
    this.refresh();
    // From the keyboard, focus goes into the menu; a click or tap leaves it where it is (on a phone, the keyboard stays).
    if (viaKeyboard) setTimeout(() => this.menuItems()[0]?.focus(), 0);
  }

  protected toggleMenu(grip: HTMLElement, viaKeyboard: boolean): void {
    if (this.menu()) this.closeMenu(viaKeyboard);
    else if (this.handle()) this.openMenu(grip, viaKeyboard, this.handle()!.id);
  }

  /** Closes the block menu; `restoreFocus` puts focus back where it was when the menu opened. */
  closeMenu(restoreFocus: boolean): void {
    const menu = this.menu();
    if (!menu) return;
    this.menu.set(null);
    this.syncMarks();
    if (restoreFocus) this.restoreFocus(menu.returnFocus);
  }

  private restoreFocus(element: HTMLElement | null): void {
    const view = this.view();
    if (view && (!element || element === view.dom || !element.isConnected)) view.focus();
    else element?.focus();
  }

  protected gripKey(event: KeyboardEvent, grip: HTMLElement): void {
    const arrow = event.key === 'ArrowUp' || event.key === 'ArrowDown';
    if (arrow && event.altKey && event.shiftKey) {
      this.act(event.key === 'ArrowUp' ? 'up' : 'down', true, this.handle()?.id);
    } else if (event.key === 'Enter' || event.key === ' ' || (arrow && !this.menu())) {
      this.toggleMenu(grip, true);
    } else if (event.key === 'Escape') {
      if (this.menu()) this.closeMenu(true);
      else this.view()?.focus();
    } else {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
  }

  protected menuKey(event: KeyboardEvent): void {
    const items = this.menuItems();
    const index = items.indexOf(document.activeElement as HTMLButtonElement);
    const focus = (i: number) => items[(i + items.length) % items.length]?.focus();
    switch (event.key) {
      case 'ArrowDown':
        focus(index + 1);
        break;
      case 'ArrowUp':
        focus(index < 0 ? -1 : index - 1);
        break;
      case 'Home':
        focus(0);
        break;
      case 'End':
        focus(-1);
        break;
      case 'Escape':
      case 'Tab':
        this.closeMenu(true);
        break;
      default:
        return;
    }
    event.preventDefault();
    event.stopPropagation();
  }

  private menuItems(): HTMLButtonElement[] {
    return [...this.host.querySelectorAll<HTMLButtonElement>('[data-block-menu] [role="menuitem"]:not(:disabled)')];
  }

  /** Escape closes a menu opened with the pointer (focus stayed in the editor). */
  private escapeMenu(event: KeyboardEvent): void {
    if (event.key !== 'Escape' || !this.menu() || this.host.querySelector('[data-block-menu]')?.contains(document.activeElement)) return;
    event.preventDefault();
    event.stopPropagation();
    this.closeMenu(false);
  }

  private outsideMenu(event: MouseEvent): void {
    const menu = this.menu();
    const target = event.target as Node | null;
    if (!menu || !target) return;
    if (this.host.querySelector('[data-block-menu]')?.contains(target) || menu.anchor.contains(target)) return;
    this.closeMenu(false);
  }

  /** Moves the block up or down, or deletes it: one transaction. */
  protected act(action: BlockAction, viaKeyboard: boolean, id: string | null | undefined): void {
    const view = this.view();
    const menu = this.menu();
    if (!view || !id) return;
    const { state } = view;
    const index = blockIndexById(state.doc, id);
    if (index < 0) return;
    const tr = action === 'delete' ? deleteBlockTr(state, index) : moveBlockTr(state, index, action === 'up' ? index - 1 : index + 2);
    const focusWasHere = this.host.contains(document.activeElement);
    this.closeMenu(false);
    if (!tr) return;
    view.dispatch(tr);
    this.announce(action === 'delete' ? 'editor.blockHandle.deleted' : 'editor.blockHandle.moved');
    if (action === 'delete') {
      this.pinnedId = this.hoverId = null;
      if (viaKeyboard || focusWasHere) view.focus();
    } else {
      const moved = this.domOf(view, id);
      moved?.scrollIntoView?.({ block: 'nearest' });
      if (viaKeyboard) {
        // Back where the keyboard was: the grip follows the block, ready for another move.
        if (menu?.returnFocus) this.restoreFocus(menu.returnFocus);
        if (this.host.querySelector('[data-block-grip]') === document.activeElement) this.pinnedId = id;
      }
    }
    this.refresh();
  }

  private announce(key: string): void {
    // Cleared first, so the same message twice in a row is read twice.
    this.status.set('');
    setTimeout(() => this.status.set(this.transloco.translate(key)), 50);
  }

  // ── Where the handle goes ──────────────────────────────

  private view(): EditorView | null {
    const editor = this.editor();
    return editor && !editor.isDestroyed ? editor.view : null;
  }

  private selectedId(view: EditorView): string | null {
    const index = selectedBlockIndex(view.state);
    const id = index === null ? null : view.state.doc.child(index).attrs['id'];
    return typeof id === 'string' ? id : null;
  }

  private domOf(view: EditorView, id: string): HTMLElement | null {
    const index = blockIndexById(view.state.doc, id);
    if (index < 0) return null;
    const dom = view.nodeDOM(blockPositions(view.state.doc)[index]);
    return dom instanceof HTMLElement ? dom : null;
  }

  private rectAt(view: EditorView, index: number): DOMRect | null {
    const dom = view.nodeDOM(blockPositions(view.state.doc)[index]);
    return dom instanceof HTMLElement ? dom.getBoundingClientRect() : null;
  }

  /** The block whose area holds `y`: each block owns half of the space between it and its neighbours. */
  private blockIdAt(view: EditorView, y: number): string | null {
    const { doc } = view.state;
    if (!doc.childCount) return null;
    let low = 0;
    let high = doc.childCount - 1;
    while (low < high) {
      const mid = (low + high + 1) >> 1;
      const top = this.rectAt(view, mid)?.top;
      const previousBottom = this.rectAt(view, mid - 1)?.bottom;
      if (top !== undefined && previousBottom !== undefined && (previousBottom + top) / 2 <= y) low = mid;
      else high = mid - 1;
    }
    const id = doc.child(low).attrs['id'];
    return typeof id === 'string' ? id : null;
  }

  private pointerMoved(y: number): void {
    if (this.drag) return;
    this.pointerY = y;
    if (this.frame !== null) return;
    const run = () => {
      this.frame = null;
      const view = this.view();
      if (!view) return;
      if (!this.menu()) this.pinnedId = null;
      const id = this.blockIdAt(view, this.pointerY);
      if (id !== this.hoverId) {
        this.hoverId = id;
        this.refresh();
      }
    };
    if (typeof requestAnimationFrame === 'function') this.frame = requestAnimationFrame(run);
    else run();
  }

  private pointerLeft(): void {
    if (this.drag) return;
    this.hoverId = null;
    this.refresh();
  }

  protected focusLeft(): void {
    // Focus moves after `focusout`.
    setTimeout(() => this.refresh(), 0);
  }

  /** Places (or hides) the handle for the block it is about, and tells the editor whether it fits. */
  refresh(): void {
    const view = this.view();
    if (!view) {
      this.handle.set(null);
      return;
    }
    const { doc } = view.state;
    const focused = this.host.contains(document.activeElement);
    if (this.pinnedId && !focused) this.pinnedId = null;
    const menu = this.menu();
    if (menu && blockIndexById(doc, menu.id) < 0) this.closeMenu(false);
    const id = this.menu()?.id ?? this.pinnedId ?? this.hoverId ?? (focused ? this.selectedId(view) : null);

    const stage = this.host.getBoundingClientRect();
    const content = view.dom.getBoundingClientRect();
    const rtl = this.dir() === 'rtl';
    const viewportWidth = document.documentElement.clientWidth || window.innerWidth;
    const room = rtl ? viewportWidth - content.right : content.left;
    const fits = content.width > 0 && room >= this.size.width + 2 * PAD + GAP;
    if (fits !== this.gutter) {
      this.gutter = fits;
      this.gutterChange.emit(fits);
    }

    const dom = fits && id ? this.domOf(view, id) : null;
    const rect = dom?.getBoundingClientRect();
    const top = dom && rect ? rect.top - stage.top + firstLineOffset(dom, this.size.height) - PAD : 0;
    // Side by side (the grip next to the text) where the gutter is wide enough and nothing else is there (the settings
    // column beside the editor); stacked in a narrow gutter.
    const wide = this.size.width * 2 + 2 + 2 * PAD + GAP;
    const edge = rtl ? content.right : content.left;
    const row = room >= wide && this.free(rtl ? edge + wide - 1 : edge - wide + 1, stage.top + top + PAD + this.size.height / 2);
    const width = row ? wide : this.size.width + 2 * PAD + GAP;
    this.bridge.set(fits ? { left: rtl ? content.right - stage.left : content.left - stage.left - width, width } : null);

    if (!dom || !id) {
      this.handle.set(null);
      this.syncMarks();
      return;
    }
    const left = rtl ? content.right - stage.left + GAP : content.left - stage.left - width;
    const current = this.handle();
    if (!current || current.id !== id || current.left !== left || current.top !== top || current.row !== row) this.handle.set({ id, left, top, row });
    this.syncMarks();
  }

  /** Whether the point is empty page (the stage's own containers), not another element such as the settings column. */
  private free(x: number, y: number): boolean {
    if (typeof document.elementsFromPoint !== 'function' || y < 0 || y > window.innerHeight) return true;
    for (const element of document.elementsFromPoint(x, y)) {
      if (this.host.contains(element) && element !== this.host && element.closest('.handle, .bridge')) continue;
      return element.contains(this.host);
    }
    return true;
  }

  /** Tints the block the handle acts on while the pointer or focus is on the handle, or its menu is open. */
  syncMarks(): void {
    const view = this.view();
    if (!view) return;
    const onHandle = this.handleHovered() || !!this.host.querySelector('.handle')?.contains(document.activeElement);
    const target = this.menu()?.id ?? (onHandle ? (this.handle()?.id ?? null) : null);
    setBlockMarks(view, { target });
  }

  // ── Drag and drop ──────────────────────────────────────

  protected dragStart(event: DragEvent): void {
    const view = this.view();
    const id = this.handle()?.id;
    const dom = view && id ? this.domOf(view, id) : null;
    if (!view || !id || !dom || !event.dataTransfer) {
      event.preventDefault();
      return;
    }
    this.closeMenu(false);
    this.drag = { id };
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData(BLOCK_MIME, id);
    const rect = dom.getBoundingClientRect();
    event.dataTransfer.setDragImage(dom, this.dir() === 'rtl' ? Math.max(0, rect.width - 16) : 16, 16);
    // After the browser has taken the drag image: the block fades where it was.
    setTimeout(() => {
      if (this.drag?.id === id) setBlockMarks(view, { dragging: id, target: null });
    }, 0);
  }

  protected endDrag(): void {
    this.drag = null;
    this.dropLine.set(null);
    const view = this.view();
    if (view) setBlockMarks(view, { dragging: null });
  }

  /** The gap the block would land in: before the first block whose middle is below the pointer (or after the last). */
  private dropIndex(view: EditorView, y: number): number {
    let low = 0;
    let high = view.state.doc.childCount;
    while (low < high) {
      const mid = (low + high) >> 1;
      const rect = this.rectAt(view, mid);
      if (rect && rect.top + rect.height / 2 > y) high = mid;
      else low = mid + 1;
    }
    return low;
  }

  private dragOver(event: DragEvent): void {
    const view = this.view();
    if (!this.drag || !view) return;
    event.preventDefault();
    event.stopPropagation();
    if (event.dataTransfer) event.dataTransfer.dropEffect = 'move';
    const from = blockIndexById(view.state.doc, this.drag.id);
    const to = this.dropIndex(view, event.clientY);
    if (from < 0 || to === from || to === from + 1) {
      this.dropLine.set(null); // it would stay where it is
      return;
    }
    const count = view.state.doc.childCount;
    const before = to > 0 ? this.rectAt(view, to - 1) : null;
    const after = to < count ? this.rectAt(view, to) : null;
    const y = before && after ? (before.bottom + after.top) / 2 : before ? before.bottom + 6 : after ? after.top - 6 : null;
    if (y === null) return;
    const stage = this.host.getBoundingClientRect();
    const content = view.dom.getBoundingClientRect();
    const line = { top: Math.round(y - stage.top - 1.5), left: content.left - stage.left, width: content.width };
    const current = this.dropLine();
    if (!current || current.top !== line.top || current.left !== line.left || current.width !== line.width) this.dropLine.set(line);
  }

  private dragLeft(event: DragEvent): void {
    if (!this.drag) return;
    const next = event.relatedTarget as Node | null;
    if (!next || !this.host.contains(next)) this.dropLine.set(null);
  }

  private drop(event: DragEvent): void {
    const view = this.view();
    const drag = this.drag;
    if (!drag || !view) return;
    event.preventDefault();
    event.stopPropagation();
    const from = blockIndexById(view.state.doc, drag.id);
    const tr = from < 0 ? null : moveBlockTr(view.state, from, this.dropIndex(view, event.clientY));
    this.endDrag();
    if (tr) {
      view.dispatch(tr);
      this.announce('editor.blockHandle.moved');
      this.hoverId = drag.id;
    }
    this.refresh();
  }
}

/** How far down the block the grip goes so it sits centred on the block's first line. */
function firstLineOffset(dom: HTMLElement, height: number): number {
  const style = getComputedStyle(dom);
  const fontSize = parseFloat(style.fontSize) || 16;
  const line = parseFloat(style.lineHeight) || fontSize * 1.5;
  const inset = (parseFloat(style.paddingTop) || 0) + (parseFloat(style.borderTopWidth) || 0);
  return Math.round(inset + (Math.min(line, height * 2) - height) / 2);
}
