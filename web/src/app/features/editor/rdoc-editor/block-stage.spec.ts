import { Component, ElementRef, signal, viewChild } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Editor } from '@tiptap/core';
import { closeHistory } from '@tiptap/pm/history';
import { TextSelection } from '@tiptap/pm/state';
import { translocoTesting } from '../../../../testing/transloco-testing';
import { provideAppIcons } from '../../../shared/ui/icons';
import { RDoc } from '../../../shared/rdoc/rdoc.models';
import { blockPositions } from './block-moves';
import { BlockStage } from './block-stage';
import { RDocEditorHost } from './editor-host';
import { rdocToEditor } from './rdoc-convert';
import { rdocExtensions } from './rdoc-schema';

const host: RDocEditorHost = {
  t: (key) => key,
  uploadImage: () => Promise.reject('unknown'),
  uploadsChanged: () => undefined,
  resolveAsset: (src) => src,
  fallbackDir: () => 'rtl',
};

const text = (value: string) => [{ type: 'text' as const, text: value }];
const DOC: RDoc = {
  version: 1,
  language: 'ar-EG',
  blocks: [
    { id: 'p1', type: 'paragraph', content: text('أول') },
    { id: 'p2', type: 'paragraph', content: text('تاني') },
    { id: 't1', type: 'table', header: [text('A'), text('B'), text('C')], rows: [[text('1'), text('2'), text('3')]] },
  ],
};

@Component({
  imports: [BlockStage],
  template: `
    <button type="button" #anchor data-anchor>blocks</button>
    <rd-block-stage [editor]="editor()" [tick]="tick()" dir="rtl" (gutterChange)="gutter.push($event)">
      <div #surface></div>
    </rd-block-stage>
  `,
})
class StageHost {
  readonly editor = signal<Editor | null>(null);
  readonly tick = signal(0);
  readonly gutter: boolean[] = [];
  readonly stage = viewChild.required(BlockStage);
  readonly surface = viewChild.required<ElementRef<HTMLElement>>('surface');
  readonly anchor = viewChild.required<ElementRef<HTMLButtonElement>>('anchor');
}

describe('block stage (handle, menu, drag and drop)', () => {
  let fixture: ComponentFixture<StageHost>;
  let editor: Editor;

  // jsdom has no layout: ProseMirror scrolls the selection into view.
  beforeAll(() => {
    const rects = () => Object.assign([], { item: () => null }) as unknown as DOMRectList;
    const rect = () => ({ x: 0, y: 0, top: 0, left: 0, right: 0, bottom: 0, width: 0, height: 0, toJSON: () => ({}) }) as DOMRect;
    for (const proto of [Element.prototype, Range.prototype] as { getClientRects?: unknown; getBoundingClientRect?: unknown }[]) {
      proto.getClientRects ??= rects;
      proto.getBoundingClientRect ??= rect;
    }
  });

  beforeEach(async () => {
    TestBed.configureTestingModule({ imports: [translocoTesting()], providers: [provideAppIcons()] });
    fixture = TestBed.createComponent(StageHost);
    fixture.detectChanges();
    const app = fixture.componentInstance;
    editor = new Editor({
      element: app.surface().nativeElement,
      extensions: rdocExtensions(host),
      content: rdocToEditor(DOC) as never,
      onTransaction: () => app.tick.update((n) => n + 1),
    });
    app.editor.set(editor);
    await settle();
  });

  afterEach(() => {
    editor.destroy();
    fixture.destroy();
  });

  async function settle(ms = 0): Promise<void> {
    fixture.detectChanges();
    await new Promise((resolve) => setTimeout(resolve, ms));
    fixture.detectChanges();
  }

  const el = () => fixture.nativeElement as HTMLElement;
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => el().querySelector<T>(selector);
  const ids = () => {
    const list: string[] = [];
    editor.state.doc.forEach((node) => list.push(String(node.attrs['id'])));
    return list;
  };
  const menuItems = () => [...el().querySelectorAll<HTMLButtonElement>('[data-block-menu] [role="menuitem"]')];
  const keydown = (target: Element, key: string, init: KeyboardEventInit = {}) => target.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true, ...init }));
  const cursorIn = (index: number) => {
    editor.view.dispatch(editor.state.tr.setSelection(TextSelection.near(editor.state.doc.resolve(blockPositions(editor.state.doc)[index] + 1))));
  };

  /** Lays the blocks out 40 px apart in a 600 px column with room for the handle on its right (RTL start). */
  function layout(): void {
    const box = (left: number, top: number, width: number, height: number) =>
      ({ left, top, width, height, right: left + width, bottom: top + height, x: left, y: top, toJSON: () => ({}) }) as DOMRect;
    const stage = el().querySelector<HTMLElement>('rd-block-stage')!;
    stage.getBoundingClientRect = () => box(200, 0, 600, 400);
    editor.view.dom.getBoundingClientRect = () => box(200, 0, 600, 400);
    editor.state.doc.forEach((_node, pos, index) => {
      (editor.view.nodeDOM(pos) as HTMLElement).getBoundingClientRect = () => box(200, index * 40, 600, 30);
    });
  }

  it('without room beside the text (here: no layout), the handle stays hidden and the editor is told', () => {
    expect(fixture.componentInstance.gutter.at(-1)).toBe(false);
    expect($('[data-block-handle]')!.classList).not.toContain('shown');
  });

  it('the toolbar opens the menu for the block holding the cursor; keyboard focus moves through it, Escape returns it', async () => {
    const anchor = fixture.componentInstance.anchor().nativeElement;
    cursorIn(0);
    anchor.focus();
    fixture.componentInstance.stage().openMenu(anchor, true);
    await settle(10);
    const menu = $('[data-block-menu]')!;
    expect(menu.getAttribute('role')).toBe('menu');
    expect(menuItems().map((b) => [b.dataset['blockAction'], b.disabled])).toEqual([
      ['up', true], // the first block can't go up
      ['down', false],
      ['delete', false],
    ]);
    expect(menuItems()[0].textContent).toContain('نقل لأعلى');
    expect(document.activeElement).toBe(menuItems()[1]); // the first item that can be used
    expect(el().querySelector('[data-block-id="p1"]')?.classList).toContain('rd-ed-handle-target');

    keydown(menu, 'ArrowDown');
    expect(document.activeElement).toBe(menuItems()[2]);
    keydown(menu, 'ArrowDown');
    expect(document.activeElement).toBe(menuItems()[1]); // wraps, skipping the disabled item
    keydown(menu, 'Escape');
    await settle();
    expect($('[data-block-menu]')).toBeNull();
    expect(document.activeElement).toBe(anchor);
    expect(el().querySelector('.rd-ed-handle-target')).toBeNull();
  });

  it('Move down and Delete from the menu: one change each, announced', async () => {
    const anchor = fixture.componentInstance.anchor().nativeElement;
    cursorIn(0);
    fixture.componentInstance.stage().openMenu(anchor, false);
    await settle();
    expect(document.activeElement).not.toBe(menuItems()[1]); // a click or tap leaves focus where it was
    menuItems()[1].dispatchEvent(new MouseEvent('click', { bubbles: true, detail: 1 }));
    await settle(80);
    expect(ids()).toEqual(['p2', 'p1', 't1']);
    expect($('[data-block-menu]')).toBeNull();
    expect($('[data-block-status]')!.textContent).toContain('تم نقل العنصر');

    cursorIn(2); // the table
    editor.view.dispatch(closeHistory(editor.state.tr)); // its own undo step (the history joins quick changes)
    fixture.componentInstance.stage().openMenu(anchor, true);
    await settle(10);
    expect(menuItems().map((b) => b.disabled)).toEqual([false, true, false]); // the last block can't go down
    menuItems()[2].click(); // from the keyboard (no pointer detail)
    await settle(80);
    expect(ids()).toEqual(['p2', 'p1']);
    expect(editor.view.hasFocus()).toBe(true);
    expect($('[data-block-status]')!.textContent).toContain('تم حذف العنصر');
    editor.commands.undo();
    expect(ids()).toEqual(['p2', 'p1', 't1']);
  });

  it('hovering a block shows its grip and trash at the start edge; the trash deletes the block', async () => {
    layout();
    window.dispatchEvent(new Event('resize'));
    await settle();
    expect(fixture.componentInstance.gutter.at(-1)).toBe(true);
    const stage = $('rd-block-stage')!;
    stage.dispatchEvent(new MouseEvent('mousemove', { clientY: 45, bubbles: true }));
    await settle(40);
    const handle = $('[data-block-handle]')!;
    expect(handle.classList).toContain('shown');
    expect(handle.dataset['for']).toBe('p2');
    expect(handle.style.left).toBe('602px'); // right of the column (RTL start), 2 px away
    expect($('[data-block-grip]')!.getAttribute('aria-label')).toBe('خيارات العنصر');
    expect($('[data-block-delete]')!.getAttribute('aria-label')).toBe('حذف العنصر');

    $('[data-block-delete]')!.dispatchEvent(new MouseEvent('click', { bubbles: true, detail: 1 }));
    await settle();
    expect(ids()).toEqual(['p1', 't1']);

    // Leaving the stage hides it (the editor has no focus).
    stage.dispatchEvent(new MouseEvent('mouseleave'));
    await settle();
    expect($('[data-block-handle]')!.classList).not.toContain('shown');
  });

  it('the grip: Enter opens the menu, Alt+Shift+↑ moves its block and the grip stays with it', async () => {
    layout();
    cursorIn(2);
    editor.view.focus();
    await settle(10);
    const grip = $('[data-block-grip]')!;
    expect($('[data-block-handle]')!.dataset['for']).toBe('t1'); // the cursor's block, while the editor has focus
    grip.focus();
    keydown(grip, 'ArrowUp', { altKey: true, shiftKey: true });
    await settle(10);
    expect(ids()).toEqual(['p1', 't1', 'p2']);
    layout();
    window.dispatchEvent(new Event('resize'));
    await settle();
    expect($('[data-block-handle]')!.dataset['for']).toBe('t1');
    keydown(grip, 'Enter');
    await settle(10);
    expect($('[data-block-menu]')).not.toBeNull();
    expect(document.activeElement).toBe(menuItems()[0]);
    keydown($('[data-block-menu]')!, 'Escape');
    await settle();
    expect(document.activeElement).toBe(grip);
  });

  it('dragging the grip shows where the block will land and moves it there in one change', async () => {
    layout();
    const stage = $('rd-block-stage')!;
    stage.dispatchEvent(new MouseEvent('mousemove', { clientY: 85, bubbles: true }));
    await settle(40);
    expect($('[data-block-handle]')!.dataset['for']).toBe('t1');

    const transfer = { effectAllowed: '', dropEffect: '', data: {} as Record<string, string>, setData(type: string, value: string) { this.data[type] = value; }, setDragImage: vi.fn() };
    const dragEvent = (type: string, clientY = 0) => {
      const event = new MouseEvent(type, { bubbles: true, cancelable: true, clientY });
      Object.defineProperty(event, 'dataTransfer', { value: transfer });
      return event;
    };
    $('[data-block-grip]')!.dispatchEvent(dragEvent('dragstart'));
    expect(transfer.data['application/x-readin-block']).toBe('t1');
    expect(transfer.effectAllowed).toBe('move');
    expect(transfer.setDragImage).toHaveBeenCalled();
    await settle(10);
    expect(el().querySelector('[data-block-id="t1"]')?.classList).toContain('rd-ed-dragging');

    // Over the top half of the first block: the line goes above it.
    const paragraph = el().querySelector('[data-block-id="p1"]')!;
    const over = dragEvent('dragover', 5);
    paragraph.dispatchEvent(over);
    await settle();
    expect(over.defaultPrevented).toBe(true);
    expect($('[data-drop-indicator]')).not.toBeNull();
    // Over its own place, nothing would move: no line.
    paragraph.dispatchEvent(dragEvent('dragover', 70));
    await settle();
    expect($('[data-drop-indicator]')).toBeNull();

    const drop = dragEvent('drop', 5);
    paragraph.dispatchEvent(drop);
    $('[data-block-grip]')!.dispatchEvent(dragEvent('dragend'));
    await settle();
    expect(drop.defaultPrevented).toBe(true);
    expect(ids()).toEqual(['t1', 'p1', 'p2']);
    expect(el().querySelector('.rd-ed-dragging')).toBeNull();
    editor.commands.undo();
    expect(ids()).toEqual(['p1', 'p2', 't1']);
  });
});
