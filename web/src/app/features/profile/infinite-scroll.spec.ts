import { Component, ElementRef, signal, viewChild } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { loadMoreNearEnd } from './infinite-scroll';

/** Fake IntersectionObserver: the tests send the reports. */
class FakeObserver {
  static instances: FakeObserver[] = [];
  observed: Element[] = [];
  constructor(readonly callback: (entries: IntersectionObserverEntry[]) => void) {
    FakeObserver.instances.push(this);
  }
  observe(el: Element): void {
    this.observed.push(el);
  }
  disconnect(): void {
    this.observed = [];
  }
  report(target: Element, isIntersecting = true): void {
    this.callback([{ target, isIntersecting } as IntersectionObserverEntry]);
  }
}

/** A list whose sentinel shows only under a loaded page with a next cursor, as the app's lists render it. */
@Component({
  template: `
    @if (loaded()) {
      <p>Page 1</p>
      @if (cursor()) {
        <div #sentinel data-sentinel></div>
      }
    } @else {
      <p>Loading…</p>
    }
  `,
})
class List {
  readonly loaded = signal(false);
  readonly cursor = signal<string | null>(null);
  readonly loads: number[] = [];
  private readonly sentinel = viewChild<ElementRef<HTMLElement>>('sentinel');

  constructor() {
    loadMoreNearEnd(
      () => this.sentinel()?.nativeElement,
      () => this.loads.push(Date.now()),
    );
  }
}

describe('loadMoreNearEnd (infinite scroll)', () => {
  const original = globalThis.IntersectionObserver;
  beforeEach(() => {
    FakeObserver.instances = [];
    globalThis.IntersectionObserver = FakeObserver as unknown as typeof IntersectionObserver;
  });
  afterEach(() => {
    globalThis.IntersectionObserver = original;
  });

  async function render() {
    TestBed.resetTestingModule();
    const fixture = TestBed.createComponent(List);
    await fixture.whenStable();
    const list = fixture.componentInstance;
    const stable = async () => {
      fixture.detectChanges();
      await fixture.whenStable();
    };
    const sentinel = () => (fixture.nativeElement as HTMLElement).querySelector('[data-sentinel]');
    return { fixture, list, stable, sentinel, observer: () => FakeObserver.instances[0] };
  }

  it('observes nothing while the first page loads, then the sentinel under the list once there is a next page', async () => {
    const t = await render();
    expect(t.observer()?.observed ?? []).toEqual([]);
    t.list.loaded.set(true);
    t.list.cursor.set('p2');
    await t.stable();
    expect(t.observer().observed).toEqual([t.sentinel()]);
    t.observer().report(t.sentinel()!);
    expect(t.list.loads).toHaveLength(1);
    // Far from the viewport: nothing.
    t.observer().report(t.sentinel()!, false);
    expect(t.list.loads).toHaveLength(1);
  });

  it('ignores a late report about a sentinel that was replaced or removed (it would load a page nobody is near)', async () => {
    const t = await render();
    t.list.loaded.set(true);
    t.list.cursor.set('p2');
    await t.stable();
    const first = t.sentinel()!;

    // The list reloads (skeletons) and comes back: a new sentinel.
    t.list.loaded.set(false);
    await t.stable();
    expect(t.observer().observed).toEqual([]);
    t.observer().report(first);
    expect(t.list.loads).toHaveLength(0);

    t.list.loaded.set(true);
    await t.stable();
    const second = t.sentinel()!;
    expect(second).not.toBe(first);
    expect(t.observer().observed).toEqual([second]);
    t.observer().report(first);
    expect(t.list.loads).toHaveLength(0);
    t.observer().report(second);
    expect(t.list.loads).toHaveLength(1);

    // The last page: no sentinel, nothing more.
    t.list.cursor.set(null);
    await t.stable();
    expect(t.observer().observed).toEqual([]);
    t.observer().report(second);
    expect(t.list.loads).toHaveLength(1);
  });

  it('disconnects when the list goes', async () => {
    const t = await render();
    t.list.loaded.set(true);
    t.list.cursor.set('p2');
    await t.stable();
    t.fixture.destroy();
    expect(t.observer().observed).toEqual([]);
  });
});
