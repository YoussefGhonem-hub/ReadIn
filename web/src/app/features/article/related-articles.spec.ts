import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { WITH_SESSION } from '../../core/api/api.config';
import { RelatedArticles, RelatedArticlesRef } from './related-articles';

@Component({
  selector: 'rd-host',
  imports: [RelatedArticles],
  template: `<rd-related-articles [article]="article()" />`,
})
class Host {
  readonly article = signal<RelatedArticlesRef & { title?: string }>({ id: 'a1', language: 'en' });
}

/** jsdom has no IntersectionObserver: this one reports what the test says. */
class FakeObserver {
  static all: FakeObserver[] = [];
  readonly targets: Element[] = [];
  disconnected = false;

  constructor(
    private readonly callback: IntersectionObserverCallback,
    readonly options?: IntersectionObserverInit,
  ) {
    FakeObserver.all.push(this);
  }

  observe(target: Element): void {
    this.targets.push(target);
  }

  disconnect(): void {
    this.disconnected = true;
  }

  report(isIntersecting: boolean): void {
    this.callback(
      this.targets.map((target) => ({ isIntersecting, target }) as IntersectionObserverEntry),
      this as unknown as IntersectionObserver,
    );
  }
}

describe('RelatedArticles (F04)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    FakeObserver.all = [];
    vi.stubGlobal('IntersectionObserver', FakeObserver);
    ({ http } = setupSocialTesting());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    http.verify();
  });

  async function render() {
    const fixture = TestBed.createComponent(Host);
    const root = fixture.nativeElement as HTMLElement;
    // Not `whenStable()`: a request still on its way keeps the app unstable.
    const stable = async () => {
      for (let i = 0; i < 3; i++) {
        await flushMicrotasks();
        fixture.detectChanges();
      }
    };
    await stable();
    const section = root.querySelector('rd-related-articles')!;
    const observer = () => FakeObserver.all.find((o) => o.targets.includes(section))!;
    const near = async () => {
      observer().report(true);
      await stable();
    };
    return { fixture, root, stable, observer, near };
  }

  const related = () => http.expectOne((r) => r.url.startsWith(`${TEST_API}/articles/`) && r.url.includes('/related'));

  it('asks nothing until the section nears the viewport', async () => {
    const { observer, stable } = await render();
    expect(observer().options?.rootMargin).toBe('600px 0px');
    observer().report(false);
    await stable();
    http.expectNone((r) => r.url.includes('/related'));
  });

  it('loads up to four cards for the version being read, with your token, and shows them under a heading', async () => {
    const { root, near, stable, observer } = await render();
    await near();
    const req = related();
    expect(req.request.url).toBe(`${TEST_API}/articles/a1/related?lang=en&limit=4`);
    expect(req.request.context.get(WITH_SESSION)).toBe(true);
    expect(observer().disconnected).toBe(true);
    req.flush([1, 2, 3, 4, 5].map((i) => testCard({ id: `r${i}`, slug: `related-${i}`, title: `Related ${i}`, isSaved: i === 2 })));
    await stable();

    const section = root.querySelector('[data-related]')!;
    expect(section.getAttribute('aria-labelledby')).toBe('related-title');
    expect(section.querySelector('#related-title')!.textContent!.trim()).toBe('مقالات ذات صلة');
    const cards = [...section.querySelectorAll('rd-article-card')];
    expect(cards.length).toBe(4);
    expect(cards[0].querySelector('a')!.getAttribute('href')).toBe('/en/a/related-1');
    // Saves behave like on every feed card (F13).
    expect(cards[1].querySelector('[data-card-save]')!.getAttribute('aria-pressed')).toBe('true');
  });

  it('shows nothing when there are no related articles', async () => {
    const { root, near, stable } = await render();
    await near();
    related().flush([]);
    await stable();
    expect(root.querySelector('[data-related]')).toBeNull();
    expect(root.querySelector('rd-related-articles')!.textContent!.trim()).toBe('');
  });

  it('shows nothing when the request fails', async () => {
    const { root, near, stable } = await render();
    await near();
    related().flush(null, { status: 500, statusText: 'Error' });
    await stable();
    expect(root.querySelector('[data-related]')).toBeNull();
  });

  it('asks again for another version, not for a fresh copy of the same one', async () => {
    const { fixture, root, near, stable } = await render();
    await near();
    related().flush([testCard({ id: 'r1' })]);
    await stable();

    fixture.componentInstance.article.set({ id: 'a1', language: 'en', title: 'personalized copy' });
    await stable();
    http.expectNone((r) => r.url.includes('/related'));

    fixture.componentInstance.article.set({ id: 'a1', language: 'ar-EG' });
    await stable();
    const req = related();
    expect(req.request.url).toBe(`${TEST_API}/articles/a1/related?lang=ar-EG&limit=4`);
    req.flush([testCard({ id: 'r9', slug: 'related-ar', language: 'ar-EG', title: 'مقال' })]);
    await stable();
    expect(root.querySelector('rd-article-card a')!.getAttribute('href')).toBe('/ar/a/related-ar');
  });
});
