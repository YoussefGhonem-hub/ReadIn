import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testArticlePath, testPathCard, testProgress } from '../../../testing/paths-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { RealtimeService } from '../../core/realtime/realtime.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { NextInPath } from './next-in-path';

@Component({
  selector: 'rd-host',
  imports: [NextInPath],
  template: `<rd-next-in-path [articleId]="articleId()" />`,
})
class Host {
  readonly articleId = signal('a2');
}

/** Fake IntersectionObserver: tests decide when the block nears the viewport. */
class FakeObserver {
  static instances: FakeObserver[] = [];
  readonly observed: Element[] = [];
  disconnected = false;
  constructor(private readonly callback: (entries: Partial<IntersectionObserverEntry>[]) => void) {
    FakeObserver.instances.push(this);
  }
  observe(el: Element): void {
    this.observed.push(el);
  }
  disconnect(): void {
    this.disconnected = true;
  }
  static nearViewport(): void {
    for (const o of FakeObserver.instances.filter((i) => !i.disconnected)) o.callback([{ isIntersecting: true }]);
  }
}

const isBlock = (id: string) => (r: { url: string }) => r.url === `${TEST_API}/articles/${id}/path`;

describe('NextInPath (F04, F09)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    FakeObserver.instances = [];
    vi.stubGlobal('IntersectionObserver', FakeObserver);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    http.verify();
  });

  async function render(options: { guest?: boolean } = {}) {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({
      guest: options.guest,
      // The next article's card follows live counters while on screen; not in these tests.
      providers: [{ provide: RealtimeService, useValue: { watchArticle: () => () => undefined } }],
    }));
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    await stable();
    return { fixture, root, stable, $: <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector) };
  }

  it('loads only when it nears the viewport: the path, the position, your progress and the next article', async () => {
    const { $, stable } = await render();
    http.expectNone(isBlock('a2'));
    expect(FakeObserver.instances[0].observed[0].tagName).toBe('RD-NEXT-IN-PATH');
    FakeObserver.nearViewport();
    http.expectOne(isBlock('a2')).flush(testArticlePath({ path: testPathCard({ ...testProgress(1, { enrolled: true }) }) }));
    await stable();
    expect(FakeObserver.instances[0].disconnected).toBe(true);
    expect($('#next-in-path-title')!.textContent).toContain('من مسار:');
    expect($('[data-next-path-link]')!.getAttribute('href')).toBe('/paths/aspnet-core-basics');
    expect($('[data-next-position]')!.textContent).toContain('2 من 4');
    expect($('[data-next-progress]')!.textContent).toContain('1/4');
    expect($('[data-next-in-path-block]')!.textContent).toContain('التالي في المسار');
    expect($('[data-next-article] h3')!.textContent).toContain('Article 3');
    expect($('[data-join-path]')).toBeNull();
    expect($('[data-next-last]')).toBeNull();
  });

  it('nothing for an article in no path (204) or on an error', async () => {
    const none = await render();
    FakeObserver.nearViewport();
    http.expectOne(isBlock('a2')).flush(null, { status: 204, statusText: 'No Content' });
    await none.stable();
    expect(none.$('[data-next-in-path-block]')).toBeNull();

    FakeObserver.instances = [];
    const failed = await render();
    FakeObserver.nearViewport();
    http.expectOne(isBlock('a2')).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await failed.stable();
    expect(failed.$('[data-next-in-path-block]')).toBeNull();
  });

  it('the last article: "the last one", and 🎉 once the path is done', async () => {
    const { $, stable } = await render();
    FakeObserver.nearViewport();
    http.expectOne(isBlock('a2')).flush(testArticlePath({ position: 4, next: null, path: testPathCard({ ...testProgress(4, { completed: true }) }) }));
    await stable();
    expect($('[data-next-last]')!.textContent).toContain('هذا آخر مقال في المسار');
    expect($('[data-next-completed]')!.textContent).toContain('🎉 اكتمل المسار');
    expect($('[data-next-article]')).toBeNull();
  });

  it('the last article of a path not finished yet: no celebration', async () => {
    const { $, stable } = await render();
    FakeObserver.nearViewport();
    http.expectOne(isBlock('a2')).flush(testArticlePath({ position: 4, next: null, path: testPathCard({ ...testProgress(3, { enrolled: true }) }) }));
    await stable();
    expect($('[data-next-last]')).not.toBeNull();
    expect($('[data-next-completed]')).toBeNull();
  });

  it('signed in, not enrolled: Join path enrolls, then shows the block again', async () => {
    const { $, stable } = await render();
    FakeObserver.nearViewport();
    http.expectOne(isBlock('a2')).flush(testArticlePath({ path: testPathCard({ ...testProgress(1) }) }));
    await stable();
    $('[data-join-path]')!.click();
    await stable();
    const put = http.expectOne(`${TEST_API}/me/paths/p1`);
    expect(put.request.method).toBe('PUT');
    put.flush(testPathCard({ ...testProgress(1, { enrolled: true }) }));
    await stable();
    http.expectOne(isBlock('a2')).flush(testArticlePath({ path: testPathCard({ ...testProgress(1, { enrolled: true }) }) }));
    await stable();
    expect($('[data-join-path]')).toBeNull();
    expect(TestBed.inject(ToastService).toasts().map((t) => t.message)).toContain('انضممت إلى المسار ✓');
  });

  it('a guest gets the sign-in prompt from Join path', async () => {
    const { $, stable } = await render({ guest: true });
    FakeObserver.nearViewport();
    http.expectOne(isBlock('a2')).flush(testArticlePath());
    await stable();
    expect($('[data-next-progress]')).toBeNull();
    $('[data-join-path]')!.click();
    await stable();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
    http.expectNone(`${TEST_API}/me/paths/p1`);
  });

  it('another article starts over and waits for the viewport again', async () => {
    const { fixture, $, stable } = await render();
    FakeObserver.nearViewport();
    http.expectOne(isBlock('a2')).flush(testArticlePath());
    await stable();
    expect($('[data-next-in-path-block]')).not.toBeNull();
    fixture.componentInstance.articleId.set('a3');
    await stable();
    expect($('[data-next-in-path-block]')).toBeNull();
    http.expectNone(isBlock('a3'));
    FakeObserver.nearViewport();
    http.expectOne(isBlock('a3')).flush(testArticlePath({ position: 3 }));
    await stable();
    expect($('[data-next-position]')!.textContent).toContain('3 من 4');
  });
});
