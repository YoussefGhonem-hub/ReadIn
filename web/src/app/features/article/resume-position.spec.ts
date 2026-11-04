import { EnvironmentInjector, PLATFORM_ID, createEnvironmentInjector, runInInjectionContext, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { testMe } from '../../../testing/auth-testing';
import { flushMicrotasks } from '../../../testing/social-testing';
import { translocoTesting } from '../../../testing/transloco-testing';
import { MyProgressDto, ReadingProgressRequest } from '../../core/api/models';
import { ReadingApi } from '../../core/api/reading.api';
import { SessionStore } from '../../core/auth/session.store';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { ReadingSheetsService } from '../reading/reading-sheets.service';
import { injectReadingTracker, scrollFraction } from './reading-tracker';
import { ResumableArticle, injectResumePosition, resumeFraction, scrollTopFor } from './resume-position';

/** The article starts 120 px down the page, is 5000 px tall, and the viewport is 800 px: 4200 px of scrollable range. */
const ARTICLE_TOP = 120;
const ARTICLE_HEIGHT = 5000;
const VIEWPORT = 800;

let scrollY = 0;

function articleElement(height = ARTICLE_HEIGHT): HTMLElement {
  const el = document.createElement('article');
  el.getBoundingClientRect = () => ({ top: ARTICLE_TOP - scrollY, height, bottom: ARTICLE_TOP - scrollY + height, left: 0, right: 0, width: 0, x: 0, y: 0, toJSON: () => ({}) });
  return el;
}

function progress(patch: Partial<MyProgressDto> = {}): MyProgressDto {
  return { language: 'ar-EG', percent: 52, lastPosition: '0.4523', completedAt: null, ...patch };
}

const article = (patch: Partial<ResumableArticle> = {}): ResumableArticle => ({ id: 'a1', language: 'ar-EG', myProgress: progress(), ...patch });

describe('resumeFraction (contract "Resume (F04)")', () => {
  it('resumes progress on the version shown, not read yet, without an anchor, from 5% to 95%', () => {
    expect(resumeFraction(article(), false)).toBe(0.4523);
    expect(resumeFraction(article({ myProgress: progress({ lastPosition: '0.0500' }) }), false)).toBe(0.05);
    expect(resumeFraction(article({ myProgress: progress({ lastPosition: '0.9500' }) }), false)).toBe(0.95);
  });

  it.each<[string, ResumableArticle, boolean]>([
    ['no progress (a guest, or never opened)', article({ myProgress: null }), false],
    ['no position', article({ myProgress: progress({ lastPosition: null }) }), false],
    ['already read', article({ myProgress: progress({ completedAt: '2026-11-03T10:00:00Z' }) }), false],
    ['recorded on the other version', article({ language: 'en' }), false],
    ['a block anchor in the link', article(), true],
    ['near the top', article({ myProgress: progress({ lastPosition: '0.0499' }) }), false],
    ['near the end', article({ myProgress: progress({ lastPosition: '0.9501' }) }), false],
    ['not a number', article({ myProgress: progress({ lastPosition: 'block-p4' }) }), false],
  ])('does not resume: %s', (_, value, hasAnchor) => {
    expect(resumeFraction(value, hasAnchor)).toBeNull();
  });
});

describe('scrollTopFor', () => {
  beforeEach(() => (scrollY = 0));

  it("lands where the reading tracker measured: its scrollFraction reads the same four decimals", () => {
    const el = articleElement();
    for (const fraction of [0.05, 0.3333, 0.4523, 0.95]) {
      scrollY = 0;
      scrollY = scrollTopFor(fraction, el, scrollY, VIEWPORT)!;
      expect(scrollFraction(el, VIEWPORT).toFixed(4)).toBe(fraction.toFixed(4));
    }
  });

  it('gives the same page offset from anywhere on the page', () => {
    const el = articleElement();
    scrollY = 300;
    expect(scrollTopFor(0.5, el, scrollY, VIEWPORT)).toBe(ARTICLE_TOP + 0.5 * (ARTICLE_HEIGHT - VIEWPORT));
  });

  it('is null when the article fits the viewport', () => {
    expect(scrollTopFor(0.5, articleElement(600), 0, VIEWPORT)).toBeNull();
  });
});

describe('injectResumePosition', () => {
  let scrollTo: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    TestBed.resetTestingModule();
    scrollY = 0;
    scrollTo = vi.fn((options: ScrollToOptions) => (scrollY = options.top ?? scrollY));
    Object.defineProperty(window, 'scrollY', { configurable: true, get: () => scrollY });
    Object.defineProperty(window, 'innerHeight', { configurable: true, value: VIEWPORT });
    vi.stubGlobal('scrollTo', scrollTo);
    // Frames run right away; jsdom loads no web fonts.
    vi.stubGlobal('requestAnimationFrame', (callback: FrameRequestCallback) => {
      void Promise.resolve().then(() => callback(0));
      return 0;
    });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    delete (window as { scrollY?: unknown }).scrollY;
    delete (window as { innerHeight?: unknown }).innerHeight;
    window.location.hash = '';
    TestBed.resetTestingModule();
  });

  function setup(options: { value?: ResumableArticle | null; ownCopy?: boolean; track?: boolean } = {}) {
    const reports = vi.fn((_id: string, body: ReadingProgressRequest) => of({ percent: body.percent, completed: false, completedNow: false, streak: null, milestone: null }));
    TestBed.configureTestingModule({
      imports: [translocoTesting()],
      providers: [
        { provide: PLATFORM_ID, useValue: 'browser' },
        { provide: ReadingApi, useValue: { progress: reports, stats: vi.fn(() => of(null)) } },
        { provide: ReadingSheetsService, useValue: { celebrate: vi.fn() } },
      ],
    });
    if (options.track) TestBed.inject(SessionStore).setMe(testMe());
    const current = signal<ResumableArticle | null>(options.value === undefined ? article() : options.value);
    const ownCopy = signal(options.ownCopy ?? true);
    const el = articleElement();
    // The reader's own injector: destroying it is leaving the article. The tracker runs there as on the page.
    const reader = createEnvironmentInjector([], TestBed.inject(EnvironmentInjector));
    const resume = runInInjectionContext(reader, () => {
      const position = injectResumePosition(current, () => el, ownCopy);
      if (options.track) injectReadingTracker(current, signal(0), () => el, position.pending);
      return position;
    });
    return { current, ownCopy, el, reader, resume, reports, toasts: TestBed.inject(ToastService) };
  }

  /** Renders, lets the fonts and frames settle, and the restore finish. */
  async function settle(): Promise<void> {
    for (let i = 0; i < 6; i++) {
      TestBed.tick();
      await flushMicrotasks();
    }
  }

  it('scrolls back once the layout settled, then offers "Start over" in a toast', async () => {
    const { el, resume, toasts } = setup();
    TestBed.tick();
    expect(resume.pending()).toBe(true);
    expect(scrollTo).not.toHaveBeenCalled(); // not before the article rendered

    await settle();
    expect(scrollTo).toHaveBeenCalledExactlyOnceWith({ top: ARTICLE_TOP + 0.4523 * (ARTICLE_HEIGHT - VIEWPORT), behavior: 'instant' });
    expect(scrollFraction(el, VIEWPORT).toFixed(4)).toBe('0.4523');
    expect(resume.pending()).toBe(false);

    const [toast] = toasts.toasts();
    expect(toast.message).toBe('كمّلنا من مكان ما وقفت');
    expect(toast.action?.label).toBe('من الأول');
    toast.action!.run();
    expect(scrollTo).toHaveBeenLastCalledWith({ top: 0, behavior: 'smooth' });
  });

  it('is placed at once when there is nothing to resume', async () => {
    const { resume, toasts } = setup({ value: article({ myProgress: progress({ completedAt: '2026-11-03T10:00:00Z' }) }) });
    TestBed.tick();
    expect(resume.pending()).toBe(false);
    await settle();
    expect(scrollTo).not.toHaveBeenCalled();
    expect(toasts.toasts()).toEqual([]);
  });

  it('waits for your own copy: the anonymous one from SSR has no progress', async () => {
    const { current, ownCopy, resume } = setup({ value: article({ myProgress: null }), ownCopy: false });
    await settle();
    expect(resume.pending()).toBe(true);
    expect(scrollTo).not.toHaveBeenCalled();

    current.set(article());
    ownCopy.set(true);
    await settle();
    expect(scrollTo).toHaveBeenCalledOnce();
    expect(resume.pending()).toBe(false);
  });

  it.each([
    ['the wheel', () => window.dispatchEvent(new Event('wheel'))],
    ['a touch drag', () => window.dispatchEvent(new Event('touchmove'))],
    ['Page Down', () => window.dispatchEvent(new KeyboardEvent('keydown', { key: 'PageDown' }))],
    ['the space bar', () => window.dispatchEvent(new KeyboardEvent('keydown', { key: ' ' }))],
    ['a restored or dragged scroll position', () => (scrollY = 640)],
  ])('never moves a reader who already scrolled (%s)', async (_, scroll) => {
    const { resume, toasts } = setup();
    TestBed.tick();
    scroll();
    await settle();
    expect(scrollTo).not.toHaveBeenCalled();
    expect(toasts.toasts()).toEqual([]);
    expect(resume.pending()).toBe(false);
  });

  it('still resumes after keys that do not scroll the page', async () => {
    setup();
    TestBed.tick();
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
    const button = document.body.appendChild(document.createElement('button'));
    button.dispatchEvent(new KeyboardEvent('keydown', { key: ' ', bubbles: true })); // presses the button
    button.remove();
    await settle();
    expect(scrollTo).toHaveBeenCalledOnce();
  });

  it('never resumes with an anchor in the link', async () => {
    window.location.hash = '#comments';
    const { resume } = setup();
    await settle();
    expect(scrollTo).not.toHaveBeenCalled();
    expect(resume.pending()).toBe(false);
  });

  it('treats another article as a new open: scrolling the previous one does not count', async () => {
    const { current, resume } = setup({ value: article({ myProgress: null }) });
    await settle();
    window.dispatchEvent(new Event('wheel'));

    current.set(null); // loading the next one
    await settle();
    current.set(article({ id: 'a2', myProgress: progress({ lastPosition: '0.2500' }) }));
    TestBed.tick();
    expect(resume.pending()).toBe(true);
    await settle();
    expect(scrollTo).toHaveBeenCalledExactlyOnceWith({ top: ARTICLE_TOP + 0.25 * (ARTICLE_HEIGHT - VIEWPORT), behavior: 'instant' });
  });

  it('does nothing during SSR', () => {
    TestBed.configureTestingModule({ imports: [translocoTesting()], providers: [{ provide: PLATFORM_ID, useValue: 'server' }] });
    const resume = TestBed.runInInjectionContext(() => injectResumePosition(() => article(), () => articleElement(), () => true));
    TestBed.tick();
    expect(resume.pending()).toBe(false);
    expect(scrollTo).not.toHaveBeenCalled();
  });

  it('holds the reading tracker until you are placed, so its first report keeps your position', async () => {
    const { reader, reports } = setup({ track: true });
    TestBed.tick();
    await flushMicrotasks();
    expect(reports).not.toHaveBeenCalled();

    await settle();
    expect(reports).toHaveBeenCalledOnce();
    expect(reports.mock.calls[0][1]).toEqual({ language: 'ar-EG', percent: 45, lastPosition: '0.4523', activeSecondsDelta: 0 });
    reader.destroy();
  });
});
