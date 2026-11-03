import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { PRECONNECT_CHECK_BLOCKLIST } from '@angular/common';
import { LanguageService, UiLanguage } from '../../core/i18n/language.service';
import { translocoTesting } from '../../../testing/transloco-testing';
import { provideAppIcons } from '../ui/icons';
import { BlurHashDecoder } from './blurhash';
import { MediaCarousel } from './media-carousel';
import { MediaSlide } from './media-slides';

function imageSlides(count: number): MediaSlide[] {
  return Array.from({ length: count }, (_, i) => ({
    key: `asset-${i + 1}`,
    kind: 'image' as const,
    variants: [320, 640, 1080].map((width) => ({ width, url: `https://api.test/uploads/${i + 1}/${width}.webp` })),
    viewVariants: [{ width: 1600, url: `https://api.test/uploads/${i + 1}/1600.webp` }],
    blurHash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
    alt: `Photo ${i + 1}`,
    caption: i === 0 ? 'First caption' : null,
    ratio: 1,
  }));
}

async function render(slides: MediaSlide[], lang: UiLanguage = 'en', inputs: Record<string, unknown> = {}): Promise<ComponentFixture<MediaCarousel>> {
  TestBed.configureTestingModule({
    imports: [translocoTesting()],
    providers: [
      provideAppIcons(),
      { provide: LanguageService, useValue: { lang: signal(lang), dir: signal(lang === 'ar' ? 'rtl' : 'ltr') } },
      { provide: BlurHashDecoder, useValue: { toDataUrl: () => null } }, // no canvas in jsdom
      { provide: PRECONNECT_CHECK_BLOCKLIST, useValue: 'https://api.test' },
    ],
  });
  const fixture = TestBed.createComponent(MediaCarousel);
  fixture.componentRef.setInput('slides', slides);
  fixture.componentRef.setInput('label', 'Post images');
  for (const [name, value] of Object.entries(inputs)) fixture.componentRef.setInput(name, value);
  await fixture.whenStable();
  return fixture;
}

const el = (fixture: ComponentFixture<MediaCarousel>) => fixture.nativeElement as HTMLElement;
const counter = (fixture: ComponentFixture<MediaCarousel>) => el(fixture).querySelector('[data-counter]')?.textContent?.trim();
const track = (fixture: ComponentFixture<MediaCarousel>) => el(fixture).querySelector('[data-track]') as HTMLElement;

async function press(fixture: ComponentFixture<MediaCarousel>, key: string): Promise<void> {
  const target = track(fixture).querySelector('[data-slide] > button[tabindex="0"]') ?? track(fixture);
  target.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true }));
  await fixture.whenStable();
}

describe('MediaCarousel', () => {
  it('starts on the first slide: counter "1 / N", no previous arrow, a next arrow', async () => {
    const fixture = await render(imageSlides(3));
    expect(counter(fixture)).toBe('1 / 3');
    expect(el(fixture).querySelector('[data-counter]')?.getAttribute('dir')).toBe('ltr'); // "3 / 12" in Arabic too
    expect(el(fixture).querySelector('[data-prev]')).toBeNull();
    expect(el(fixture).querySelector('[data-next]')).not.toBeNull();
  });

  it('hides the next arrow on the last slide and shows the previous one', async () => {
    const fixture = await render(imageSlides(3));
    (el(fixture).querySelector('[data-next]') as HTMLButtonElement).click();
    await fixture.whenStable();
    expect(counter(fixture)).toBe('2 / 3');
    expect(el(fixture).querySelector('[data-prev]')).not.toBeNull();

    (el(fixture).querySelector('[data-next]') as HTMLButtonElement).click();
    await fixture.whenStable();
    expect(counter(fixture)).toBe('3 / 3');
    expect(el(fixture).querySelector('[data-next]')).toBeNull();
    expect(el(fixture).querySelector('[data-prev]')).not.toBeNull();
  });

  it('moves with the arrow keys in LTR (→ next, ← previous) and stops at the ends', async () => {
    const fixture = await render(imageSlides(3));
    await press(fixture, 'ArrowLeft');
    expect(counter(fixture)).toBe('1 / 3');
    await press(fixture, 'ArrowRight');
    expect(counter(fixture)).toBe('2 / 3');
    await press(fixture, 'ArrowRight');
    await press(fixture, 'ArrowRight');
    expect(counter(fixture)).toBe('3 / 3');
    await press(fixture, 'ArrowLeft');
    expect(counter(fixture)).toBe('2 / 3');
    await press(fixture, 'Home');
    expect(counter(fixture)).toBe('1 / 3');
    await press(fixture, 'End');
    expect(counter(fixture)).toBe('3 / 3');
  });

  it('mirrors in RTL: starts from the right, ← is next, → is previous', async () => {
    const fixture = await render(imageSlides(3), 'ar');
    const slides = [...track(fixture).querySelectorAll('[data-slide]')];
    expect(track(fixture).getAttribute('dir')).toBe('rtl');
    // DOM order is the reading order; with dir="rtl" the first slide sits at the right edge.
    expect(slides.map((s) => s.getAttribute('aria-label'))).toEqual(['صورة 1 من 3', 'صورة 2 من 3', 'صورة 3 من 3']);

    await press(fixture, 'ArrowRight');
    expect(counter(fixture)).toBe('1 / 3');
    await press(fixture, 'ArrowLeft');
    expect(counter(fixture)).toBe('2 / 3');
    await press(fixture, 'ArrowRight');
    expect(counter(fixture)).toBe('1 / 3');
    // The previous arrow sits at the inline start (the right in RTL) and its chevron is mirrored.
    await press(fixture, 'ArrowLeft');
    const prev = el(fixture).querySelector('[data-prev]')!;
    expect(prev.classList.contains('start-2')).toBe(true);
    expect(prev.querySelector('svg')?.classList.contains('rd-flip-rtl')).toBe(true);
  });

  it('keeps one tab stop: only the current slide is focusable', async () => {
    const fixture = await render(imageSlides(4));
    const tabbable = () => [...track(fixture).querySelectorAll('[data-slide] > button')].map((b) => b.getAttribute('tabindex'));
    expect(tabbable()).toEqual(['0', '-1', '-1', '-1']);
    await press(fixture, 'ArrowRight');
    expect(tabbable()).toEqual(['-1', '0', '-1', '-1']);
  });

  it('renders real images only around the current slide (placeholders elsewhere)', async () => {
    const fixture = await render(imageSlides(6));
    const rendered = () =>
      [...track(fixture).querySelectorAll('[data-slide]')].map((slide) => (slide.querySelector('rd-media-image img') ? 'img' : 'placeholder'));
    expect(rendered()).toEqual(['img', 'img', 'placeholder', 'placeholder', 'placeholder', 'placeholder']);
    fixture.componentInstance.goTo(3);
    await fixture.whenStable();
    expect(rendered()).toEqual(['placeholder', 'placeholder', 'img', 'img', 'img', 'placeholder']);
    // Placeholders carry the BlurHash average color, so nothing jumps while scrolling.
    expect((track(fixture).querySelector('[data-placeholder]') as HTMLElement).style.backgroundColor).toBe('rgb(151, 150, 149)');
  });

  it('requests only existing variant widths through srcset, eager for the priority slide only', async () => {
    const fixture = await render(imageSlides(2), 'en', { aspectRatio: 1, priority: true });
    const img = track(fixture).querySelector('img')!;
    expect(img.getAttribute('srcset')).toBe(
      'https://api.test/uploads/1/320.webp 320w, https://api.test/uploads/1/640.webp 640w, https://api.test/uploads/1/1080.webp 1080w',
    );
    expect(img.getAttribute('loading')).toBe('eager'); // priority: the first visible image
    expect((track(fixture).querySelectorAll('img')[1] as HTMLImageElement).getAttribute('loading')).toBe('lazy');
  });

  it('shows captions with dir="auto" and emits the slide index when opened', async () => {
    const fixture = await render(imageSlides(3));
    const caption = track(fixture).querySelector('[data-slide] [dir="auto"]');
    expect(caption?.textContent?.trim()).toBe('First caption');
    const opened: number[] = [];
    fixture.componentInstance.opened.subscribe((i) => opened.push(i));
    (track(fixture).querySelectorAll('[data-slide] > button')[1] as HTMLButtonElement).click();
    await fixture.whenStable();
    expect(opened).toEqual([1]);
    expect(counter(fixture)).toBe('2 / 3');
  });

  it('counts a PDF by its page count and ends with a "+N pages" card', async () => {
    const pages: MediaSlide[] = imageSlides(10).map((s, i) => ({ ...s, key: `page-${i + 1}`, kind: 'page' as const, caption: null }));
    pages.push({ ...pages[9], key: 'more', kind: 'more', variants: [], moreCount: 2 });
    const fixture = await render(pages, 'en', { total: 12 });
    expect(counter(fixture)).toBe('1 / 12');
    expect(track(fixture).querySelector('[data-slide]')?.getAttribute('aria-label')).toBe('Page 1 of 12');
    expect(track(fixture).querySelector('[data-more]')?.textContent?.trim()).toBe('+2 pages, open document');
  });
});
