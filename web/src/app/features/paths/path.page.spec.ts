import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Meta, Title } from '@angular/platform-browser';
import { Router } from '@angular/router';
import { testPathCard, testPathDetails, testProgress } from '../../../testing/paths-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { PathDetailsDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { PathPage, pathAction } from './path.page';

const isPath = (slug: string) => (r: { url: string }) => r.url === `${TEST_API}/paths/${slug}`;

describe('PathPage (F09)', () => {
  let http: HttpTestingController;

  afterEach(() => {
    http?.verify();
    document.body.querySelectorAll('.cdk-overlay-container').forEach((el) => el.remove());
  });

  async function render(path: PathDetailsDto | { status: number; code: string }, options: { guest?: boolean } = {}) {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ guest: options.guest }));
    const fixture = TestBed.createComponent(PathPage);
    fixture.componentRef.setInput('slug', 'aspnet-core-basics');
    fixture.detectChanges();
    const req = http.expectOne(isPath('aspnet-core-basics'));
    if ('status' in path) req.flush(problem(path.status, path.code), { status: path.status, statusText: 'Error' });
    else req.flush(path);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      // Covers without an image ask for the fields' icons (once per app); SSR would wait for them.
      http.match(`${TEST_API}/fields`).forEach((r) => r.flush([]));
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    await stable();
    return { fixture, root, stable, $: <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector) };
  }

  it('picks the primary action: start (guests, not enrolled), continue, read again', () => {
    expect(pathAction(testPathDetails(), false)).toBe('start');
    expect(pathAction(testPathDetails(testProgress(2)), true)).toBe('start');
    expect(pathAction(testPathDetails(testProgress(2, { enrolled: true })), true)).toBe('continue');
    expect(pathAction(testPathDetails(testProgress(4, { enrolled: true })), true)).toBe('again');
    // Completed, then the path grew: continue with the new article, the badge stays.
    expect(pathAction(testPathDetails({ ...testProgress(3, { completed: true }) }), true)).toBe('continue');
  });

  it('a guest sees the path, its articles and "N articles · M min"; Start asks to sign in', async () => {
    const { $, root, stable } = await render(testPathDetails(), { guest: true });
    expect($('[data-path-title]')!.textContent).toContain('أساسيات ASP.NET Core');
    expect($('[data-path-title]')!.getAttribute('dir')).toBe('rtl');
    expect($('[data-path-meta]')!.textContent).toContain('4 مقالات');
    expect($('[data-path-meta]')!.textContent).toContain('22 دقيقة');
    expect($('[data-path-progress]')).toBeNull();
    expect($('[data-path-menu]')).toBeNull();
    expect(root.querySelectorAll('[data-path-item]')).toHaveLength(4);
    expect(root.querySelectorAll('[data-read-tick]')).toHaveLength(0);
    expect(root.querySelector('[data-path-item="1"] a')!.getAttribute('href')).toBe('/en/a/article-1');
    expect(TestBed.inject(Title).getTitle()).toBe('أساسيات ASP.NET Core — ReadIn');
    expect(TestBed.inject(Meta).getTag('name="description"')!.content).toContain('الـ middleware');

    $('[data-path-start]')!.click();
    await stable();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
  });

  it('not enrolled: Start enrolls, then opens the first unread article', async () => {
    const { $, stable } = await render(testPathDetails(testProgress(1), 1));
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    expect($('[data-path-progress]')!.textContent).toContain('1/4');
    expect($('[data-path-progress] [role="progressbar"]')!.getAttribute('aria-valuenow')).toBe('25');
    expect($('[data-path-progress] [role="progressbar"]')!.getAttribute('aria-label')).toBe('تمت قراءة 1 من 4');

    $('[data-path-start]')!.click();
    await stable();
    const req = http.expectOne(`${TEST_API}/me/paths/p1`);
    expect(req.request.method).toBe('PUT');
    req.flush({ ...testPathCard(), ...testProgress(1, { enrolled: true }) });
    await stable();
    expect(navigate).toHaveBeenCalledWith(['/', 'en', 'a', 'article-2']);
    // Enrolled now: Continue and the ⋯ menu.
    expect($('[data-path-continue]')).not.toBeNull();
    expect($('[data-path-menu]')).not.toBeNull();
    // The articles are still there (the PUT answers a card, without items).
    expect(document.querySelectorAll('[data-path-item]').length).toBe(4);
  });

  it('enrolled: Continue opens the next one, read articles get a ✓ and the next one is highlighted', async () => {
    const { $, root } = await render(testPathDetails(testProgress(2, { enrolled: true }), 2));
    const cont = $<HTMLAnchorElement>('[data-path-continue]')!;
    expect(cont.getAttribute('href')).toBe('/en/a/article-3');
    expect(cont.textContent).toContain('متابعة القراءة:');
    expect(cont.textContent).toContain('Article 3');
    expect(root.querySelectorAll('[data-read-tick]')).toHaveLength(2);
    expect(root.querySelector('[data-next]')!.getAttribute('data-path-item')).toBe('3');
    expect(root.querySelector('[data-next] a')!.getAttribute('aria-current')).toBe('step');
    expect($('[data-path-completed]')).toBeNull();
    expect($('[data-path-celebration]')).toBeNull();
  });

  it('all read: the completion badge, a celebration and Read again from the first article', async () => {
    const { $ } = await render(testPathDetails(testProgress(4, { completed: true }), 4));
    expect($('[data-path-completed]')!.textContent).toContain('مكتمل');
    expect($('[data-path-celebration]')!.textContent).toContain('اكتمل المسار 🎉');
    expect($<HTMLAnchorElement>('[data-path-again]')!.getAttribute('href')).toBe('/en/a/article-1');
    expect($('[data-path-progress] rd-progress-bar span')!.className).toContain('bg-success');
  });

  it('Leave path asks first, then keeps the progress and offers Start again', async () => {
    const { $, stable } = await render(testPathDetails(testProgress(2, { enrolled: true }), 2));
    $('[data-path-menu]')!.click();
    await stable();
    (document.querySelector('[data-path-leave]') as HTMLElement).click();
    await stable();
    const sheet = document.querySelector('[data-leave-path]')!;
    expect(sheet.textContent).toContain('هل تريد مغادرة «أساسيات ASP.NET Core»؟');
    (sheet.querySelector('[data-confirm-leave]') as HTMLElement).click();
    await stable();
    const req = http.expectOne(`${TEST_API}/me/paths/p1`);
    expect(req.request.method).toBe('DELETE');
    req.flush(null, { status: 204, statusText: 'No Content' });
    await stable();
    expect(document.querySelector('[data-leave-path]')).toBeNull();
    expect($('[data-path-start]')).not.toBeNull();
    expect($('[data-path-menu]')).toBeNull();
    expect($('[data-path-progress]')!.textContent).toContain('2/4');
    expect(TestBed.inject(ToastService).toasts().map((t) => t.message)).toContain('غادرت المسار');
  });

  it('a failed enroll shows the error and stays', async () => {
    const { $, stable } = await render(testPathDetails(testProgress(0)));
    $('[data-path-start]')!.click();
    await stable();
    http.expectOne(`${TEST_API}/me/paths/p1`).flush(problem(404, 'path.not_found'), { status: 404, statusText: 'Not Found' });
    await stable();
    expect(TestBed.inject(ToastService).toasts().map((t) => t.message)).toContain('هذا المسار غير موجود.');
    expect(($('[data-path-start]') as HTMLButtonElement).disabled).toBe(false);
  });

  it('an unknown path is a not-found state', async () => {
    const { $ } = await render({ status: 404, code: 'path.not_found' });
    expect($('[data-path-not-found]')!.textContent).toContain('هذا المسار غير موجود');
    expect($('[data-path-not-found] a')!.getAttribute('href')).toBe('/paths');
    expect(TestBed.inject(Title).getTitle()).toBe('هذا المسار غير موجود — ReadIn');
  });

  it('a failed load offers a retry', async () => {
    const { $, stable } = await render({ status: 500, code: 'server.error' });
    ($('rd-error-state button') as HTMLElement).click();
    await flushMicrotasks();
    TestBed.tick();
    http.expectOne(isPath('aspnet-core-basics')).flush(testPathDetails());
    await stable();
    expect($('[data-path-title]')).not.toBeNull();
  });
});
