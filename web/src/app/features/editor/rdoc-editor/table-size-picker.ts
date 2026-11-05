import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, afterNextRender, inject, input, output, signal, viewChild } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { TABLE_PICKER, TableSize } from './block-commands';
import { PopupAnchor, placePopup } from './popup-place';

let nextPickerId = 0;

/**
 * Insert → Table: a grid to pick the size (columns × rows under the header row), with the pointer or the arrow keys.
 * Enter or a click inserts, Escape cancels. The grid grows from the start side of the article's direction, like the
 * table will.
 */
@Component({
  selector: 'rd-table-size-picker',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'rd-ed-tablepick',
    '[style.left.px]': 'left() ?? anchor().left',
    '[style.top.px]': 'top() ?? anchor().bottom + 6',
    'data-table-picker': '',
  },
  styles: `
    :host {
      position: fixed;
      z-index: 60;
      padding: 10px;
      border: 1px solid var(--rd-color-border);
      border-radius: var(--rd-radius-md);
      background: var(--rd-color-surface-raised);
      box-shadow: var(--rd-elevation-raised);
    }
    .grid {
      display: grid;
      gap: 4px;
      border-radius: var(--rd-radius-sm);
      outline: none;
    }
    .grid:focus-visible {
      outline: 2px solid var(--rd-color-primary);
      outline-offset: 4px;
    }
    .row {
      display: flex;
      gap: 4px;
    }
    .cell {
      width: 22px;
      height: 22px;
      border: 1px solid var(--rd-color-border);
      border-radius: 4px;
      background: var(--rd-color-surface);
      cursor: pointer;
    }
    .head {
      background: var(--rd-color-surface-variant);
    }
    .on {
      border-color: var(--rd-color-primary);
      background: var(--rd-color-primary-container);
    }
    .head.on {
      background: var(--rd-color-primary);
    }
    .size {
      margin: 8px 0 0;
      font-weight: 600;
      text-align: center;
      font-variant-numeric: tabular-nums;
    }
    .hint {
      width: 0;
      min-width: 100%;
      margin: 2px 0 0;
      color: var(--rd-color-text-secondary);
      font-size: var(--rd-text-caption-size);
      text-align: center;
    }
    @media (pointer: coarse) {
      .cell {
        width: 36px;
        height: 36px;
      }
    }
  `,
  template: `
    <div
      #grid
      class="grid"
      role="grid"
      tabindex="0"
      [attr.dir]="dir()"
      [attr.aria-label]="'editor.table.size' | transloco"
      [attr.aria-describedby]="id + '-hint'"
      [attr.aria-activedescendant]="cellId(cols(), rows())"
      (keydown)="onKey($event)"
      (pointerover)="onPointer($event, false)"
      (click)="onPointer($event, true)"
    >
      <div class="row" aria-hidden="true">
        @for (c of colNumbers; track c) {
          <div class="cell head" [class.on]="c <= cols()" [attr.data-head]="c"></div>
        }
      </div>
      @for (r of rowNumbers; track r) {
        <div class="row" role="row">
          @for (c of colNumbers; track c) {
            <div
              role="gridcell"
              class="cell"
              [id]="cellId(c, r)"
              [class.on]="c <= cols() && r <= rows()"
              [attr.aria-selected]="c === cols() && r === rows()"
              [attr.aria-label]="c + ' × ' + r"
              [attr.data-cell]="c + 'x' + r"
            ></div>
          }
        </div>
      }
    </div>
    <p class="size" data-table-size>{{ cols() }} × {{ rows() }}</p>
    <p class="hint" [id]="id + '-hint'">{{ 'editor.table.sizeHint' | transloco }}</p>
  `,
})
export class TableSizePicker {
  private readonly hostEl = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;
  private readonly grid = viewChild.required<ElementRef<HTMLElement>>('grid');

  /** Where the picker opens: under the anchor, or above it when there is no room below. */
  readonly anchor = input.required<PopupAnchor>();
  /** The article's direction: columns are added from its start side. */
  readonly dir = input<'rtl' | 'ltr'>('rtl');
  readonly picked = output<TableSize>();
  readonly cancelled = output<void>();

  protected readonly id = `rd-table-picker-${++nextPickerId}`;
  protected readonly colNumbers = range(1, TABLE_PICKER.maxCols);
  protected readonly rowNumbers = range(1, TABLE_PICKER.maxRows);
  readonly cols = signal<number>(TABLE_PICKER.initial.cols);
  readonly rows = signal<number>(TABLE_PICKER.initial.rows);
  /** Set once the picker has measured itself (the anchor's corner until then). */
  protected readonly left = signal<number | null>(null);
  protected readonly top = signal<number | null>(null);

  constructor() {
    const onOutside = (event: Event) => {
      if (!this.hostEl.contains(event.target as Node)) this.cancelled.emit();
    };
    afterNextRender(() => {
      this.place();
      this.grid().nativeElement.focus({ preventScroll: true });
      document.addEventListener('mousedown', onOutside, true);
    });
    inject(DestroyRef).onDestroy(() => document.removeEventListener('mousedown', onOutside, true));
  }

  protected cellId(cols: number, rows: number): string {
    return `${this.id}-${cols}x${rows}`;
  }

  /** Hovering a cell previews its size, clicking it inserts that size (a header cell: one row). */
  protected onPointer(event: Event, pick: boolean): void {
    const cell = (event.target as Element | null)?.closest<HTMLElement>('[data-cell], [data-head]');
    if (!cell) return;
    const [cols, rows] = cell.dataset['head'] ? [Number(cell.dataset['head']), 1] : (cell.dataset['cell'] ?? '').split('x').map(Number);
    this.set(cols, rows);
    if (pick) this.picked.emit({ cols: this.cols(), rows: this.rows() });
  }

  protected onKey(event: KeyboardEvent): void {
    const rtl = this.dir() === 'rtl';
    const cols = this.cols();
    const rows = this.rows();
    switch (event.key) {
      case 'ArrowRight':
        this.set(cols + (rtl ? -1 : 1), rows);
        break;
      case 'ArrowLeft':
        this.set(cols + (rtl ? 1 : -1), rows);
        break;
      case 'ArrowDown':
        this.set(cols, rows + 1);
        break;
      case 'ArrowUp':
        this.set(cols, rows - 1);
        break;
      case 'Home':
        this.set(TABLE_PICKER.minCols, rows);
        break;
      case 'End':
        this.set(TABLE_PICKER.maxCols, rows);
        break;
      case 'PageUp':
        this.set(cols, TABLE_PICKER.minRows);
        break;
      case 'PageDown':
        this.set(cols, TABLE_PICKER.maxRows);
        break;
      case 'Enter':
      case ' ':
        this.picked.emit({ cols, rows });
        break;
      case 'Escape':
        this.cancelled.emit();
        break;
      case 'Tab':
        break; // the grid is the picker's only stop
      default:
        return;
    }
    event.preventDefault();
    event.stopPropagation();
  }

  private set(cols: number, rows: number): void {
    this.cols.set(Math.min(TABLE_PICKER.maxCols, Math.max(TABLE_PICKER.minCols, cols)));
    this.rows.set(Math.min(TABLE_PICKER.maxRows, Math.max(TABLE_PICKER.minRows, rows)));
  }

  private place(): void {
    const { left, top } = placePopup(this.anchor(), this.hostEl.getBoundingClientRect());
    this.left.set(left);
    this.top.set(top);
  }
}

function range(from: number, to: number): number[] {
  return Array.from({ length: to - from + 1 }, (_, i) => from + i);
}
