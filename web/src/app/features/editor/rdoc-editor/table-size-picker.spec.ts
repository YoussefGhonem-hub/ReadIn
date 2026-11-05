import { ComponentFixture, TestBed } from '@angular/core/testing';
import { translocoTesting } from '../../../../testing/transloco-testing';
import { TableSize } from './block-commands';
import { TableSizePicker } from './table-size-picker';

describe('table size picker (Insert → Table)', () => {
  let fixture: ComponentFixture<TableSizePicker>;
  let picked: TableSize[];
  let cancelled: number;

  async function open(dir: 'rtl' | 'ltr'): Promise<void> {
    TestBed.configureTestingModule({ imports: [translocoTesting()] });
    fixture = TestBed.createComponent(TableSizePicker);
    fixture.componentRef.setInput('anchor', { left: 100, right: 300, top: 100, bottom: 120 });
    fixture.componentRef.setInput('dir', dir);
    picked = [];
    cancelled = 0;
    fixture.componentInstance.picked.subscribe((size) => picked.push(size));
    fixture.componentInstance.cancelled.subscribe(() => cancelled++);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
  }

  const el = () => fixture.nativeElement as HTMLElement;
  const grid = () => el().querySelector<HTMLElement>('[role="grid"]')!;
  const label = () => el().querySelector('[data-table-size]')!.textContent!.trim();
  const key = (name: string) => {
    grid().dispatchEvent(new KeyboardEvent('keydown', { key: name, bubbles: true, cancelable: true }));
    fixture.detectChanges();
  };

  afterEach(() => fixture?.destroy());

  it('opens on 2 × 2 with focus in the grid, which explains itself', async () => {
    await open('rtl');
    expect(label()).toBe('2 × 2');
    expect(document.activeElement).toBe(grid());
    expect(grid().getAttribute('aria-label')).toBe('حجم الجدول');
    expect(el().querySelector(`#${grid().getAttribute('aria-describedby')}`)?.textContent).toContain('أعمدة × صفوف');
    // 6 columns × 8 rows to pick from, under a header row; the picked cell is the active one.
    expect(el().querySelectorAll('[role="gridcell"]')).toHaveLength(48);
    const active = el().querySelector(`#${grid().getAttribute('aria-activedescendant')}`);
    expect(active?.getAttribute('aria-label')).toBe('2 × 2');
    expect(active?.getAttribute('aria-selected')).toBe('true');
    expect(el().querySelectorAll('.cell.on')).toHaveLength(2 + 4); // the header cells and the body cells
  });

  it('arrow keys grow and shrink it from the article start side (RTL: ← adds a column), within 2–6 × 1–8', async () => {
    await open('rtl');
    key('ArrowLeft');
    key('ArrowLeft');
    key('ArrowDown');
    expect(label()).toBe('4 × 3');
    key('ArrowRight');
    expect(label()).toBe('3 × 3');
    key('End');
    key('PageDown');
    expect(label()).toBe('6 × 8');
    key('ArrowLeft');
    key('ArrowDown');
    expect(label()).toBe('6 × 8');
    key('Home');
    key('PageUp');
    key('ArrowRight');
    key('ArrowUp');
    expect(label()).toBe('2 × 1');
    key('Enter');
    expect(picked).toEqual([{ cols: 2, rows: 1 }]);
  });

  it('in an LTR article → adds a column; Escape cancels', async () => {
    await open('ltr');
    key('ArrowRight');
    expect(label()).toBe('3 × 2');
    key('Escape');
    expect(cancelled).toBe(1);
    expect(picked).toEqual([]);
  });

  it('hovering previews a size and a click inserts it; a click outside cancels', async () => {
    await open('rtl');
    const cell = el().querySelector<HTMLElement>('[data-cell="5x4"]')!;
    cell.dispatchEvent(new MouseEvent('pointerover', { bubbles: true }));
    fixture.detectChanges();
    expect(label()).toBe('5 × 4');
    cell.click();
    expect(picked).toEqual([{ cols: 5, rows: 4 }]);
    // A header cell picks its columns with one row; a first-column cell still makes two columns.
    el().querySelector<HTMLElement>('[data-head="3"]')!.click();
    el().querySelector<HTMLElement>('[data-cell="1x2"]')!.click();
    expect(picked.slice(1)).toEqual([
      { cols: 3, rows: 1 },
      { cols: 2, rows: 2 },
    ]);
    document.body.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
    expect(cancelled).toBe(1);
  });
});
