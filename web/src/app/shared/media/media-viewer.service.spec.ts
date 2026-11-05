import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Location, PlatformLocation } from '@angular/common';
import { Dialog } from '@angular/cdk/dialog';
import { provideRouter } from '@angular/router';
import { Subject } from 'rxjs';
import type { Mock } from 'vitest';
import { translocoTesting } from '../../../testing/transloco-testing';
import { MediaViewerData } from './media-viewer';
import { MEDIA_VIEWER_HISTORY_KEY, MediaViewerService } from './media-viewer.service';
import { MediaViewerHistory, ViewerAwarePlatformLocation, provideMediaViewerHistory } from './viewer-history';

/** A dialog that only records being opened and closed. */
class FakeDialog {
  readonly refs: { close: Mock<() => void>; closed: Subject<void> }[] = [];
  open() {
    const closed = new Subject<void>();
    const ref = {
      closed,
      close: vi.fn<() => void>(() => {
        closed.next();
        closed.complete();
      }),
    };
    this.refs.push(ref);
    return ref;
  }
}

const DATA: MediaViewerData = {
  kind: 'images',
  title: 'A post',
  items: signal([]),
  total: 1,
  startIndex: 0,
  document: null,
  share: { title: 'A post', url: 'https://readin.app/en/a/post' },
};

/**
 * Coming back from the full-screen viewer (SPEC F26, pre-production step H). The viewer's history entry has the page's
 * own URL: moving into or out of it must never reach Angular's Location (and so the router, whose scroller would answer
 * that same-URL popstate by scrolling the page to the top).
 */
describe('MediaViewerService: history and the router (F26)', () => {
  let service: MediaViewerService;
  let dialog: FakeDialog;
  /** What the router hears: Angular's Location's popstate events. */
  let routerHeard: Mock<(event: unknown) => void>;

  beforeEach(() => {
    TestBed.resetTestingModule();
    window.history.replaceState(null, '', '/');
    dialog = new FakeDialog();
    TestBed.configureTestingModule({
      imports: [translocoTesting()],
      providers: [provideRouter([]), { provide: Dialog, useValue: dialog }, provideMediaViewerHistory()],
    });
    service = TestBed.inject(MediaViewerService);
    routerHeard = vi.fn<(event: unknown) => void>();
    TestBed.inject(Location).subscribe((event) => routerHeard(event));
  });

  afterEach(() => vi.restoreAllMocks());

  const popTo = (state: unknown) => window.dispatchEvent(new PopStateEvent('popstate', { state }));

  it('the app’s PlatformLocation is the viewer-aware one in the browser', () => {
    expect(TestBed.inject(PlatformLocation)).toBeInstanceOf(ViewerAwarePlatformLocation);
  });

  it('pushes an entry of its own on the same URL', () => {
    const before = window.location.href;
    service.open(DATA);
    expect(service.isOpen).toBe(true);
    expect(window.history.state[MEDIA_VIEWER_HISTORY_KEY]).toBeTruthy();
    expect(window.location.href).toBe(before);
  });

  it('the browser Back closes the viewer, and the router never hears that popstate', () => {
    service.open(DATA);
    const back = vi.spyOn(window.history, 'back');
    popTo(null); // back to the page's own entry, same URL
    expect(dialog.refs[0].close).toHaveBeenCalledOnce();
    expect(service.isOpen).toBe(false);
    expect(routerHeard).not.toHaveBeenCalled();
    expect(back).not.toHaveBeenCalled(); // the entry is already gone
  });

  it('✕ / Esc go back over the viewer’s entry, and the router never hears that popstate either', () => {
    service.open(DATA);
    const back = vi.spyOn(window.history, 'back').mockImplementation(() => undefined);
    dialog.refs[0].close();
    expect(back).toHaveBeenCalledOnce();
    // The browser then fires the popstate of that Back.
    popTo(null);
    expect(routerHeard).not.toHaveBeenCalled();
  });

  it('Forward onto an old viewer entry and Back off it again stay away from the router too', () => {
    service.open(DATA);
    vi.spyOn(window.history, 'back').mockImplementation(() => undefined);
    dialog.refs[0].close();
    popTo(null);
    popTo({ [MEDIA_VIEWER_HISTORY_KEY]: 'old' }); // Forward
    popTo(null); // Back again
    expect(routerHeard).not.toHaveBeenCalled();
    expect(service.isOpen).toBe(false);
  });

  it('a Back to another page is a real navigation: the router hears it (and an open viewer closes)', () => {
    service.open(DATA);
    // The browser is now on another URL than the one the viewer was opened on.
    window.history.replaceState(null, '', '/somewhere-else');
    popTo(null);
    expect(routerHeard).toHaveBeenCalledOnce();
    expect(dialog.refs[0].close).toHaveBeenCalledOnce();
  });

  it('once the viewer is closed, popstates that have nothing to do with it reach the router as before', () => {
    service.open(DATA);
    vi.spyOn(window.history, 'back').mockImplementation(() => undefined);
    dialog.refs[0].close();
    popTo(null);
    expect(routerHeard).not.toHaveBeenCalled();
    // A router navigation, then Back to the page before it.
    TestBed.inject(Location).go('/next');
    window.history.replaceState({ navigationId: 3 }, '', '/');
    popTo({ navigationId: 3 });
    expect(routerHeard).toHaveBeenCalledOnce();
  });

  it('opens one viewer at a time', () => {
    expect(service.open(DATA)).not.toBeNull();
    expect(service.open(DATA)).toBeNull();
    expect(dialog.refs).toHaveLength(1);
  });
});

describe('MediaViewerHistory', () => {
  it('only a same-URL move into or out of a viewer entry is the viewer’s; leaving it closes the viewer', () => {
    const history = new MediaViewerHistory();
    const leave = vi.fn();
    history.start(null, 'https://readin.app/');
    expect(history.popped(null, 'https://readin.app/x')).toBe(false); // a plain Back
    history.navigated('https://readin.app/');
    history.pushed('https://readin.app/');
    history.onLeave(leave);
    expect(history.popped(null, 'https://readin.app/')).toBe(true); // Back off the viewer
    expect(leave).toHaveBeenCalledOnce();
    history.onLeave(null);
    expect(history.popped({ [MEDIA_VIEWER_HISTORY_KEY]: 'm' }, 'https://readin.app/')).toBe(true); // Forward onto it
    expect(history.popped({ [MEDIA_VIEWER_HISTORY_KEY]: 'm' }, 'https://readin.app/other')).toBe(false); // another page's
    // A reload on a viewer entry starts there.
    history.start({ [MEDIA_VIEWER_HISTORY_KEY]: 'm' }, 'https://readin.app/');
    expect(history.popped({ navigationId: 1 }, 'https://readin.app/')).toBe(true);
  });
});
