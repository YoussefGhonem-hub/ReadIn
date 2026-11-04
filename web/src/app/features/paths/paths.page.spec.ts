import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Title } from '@angular/platform-browser';
import { testPathCard, testProgress } from '../../../testing/paths-testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { PathCardDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { PathsPage } from './paths.page';
import { fieldsOf } from './paths.store';

const MEDICINE = { id: 'f2', slug: 'medicine', name: 'Medicine', nameAr: 'الطب', nameEn: 'Medicine' };

const ALL: PathCardDto[] = [
  testPathCard({ ...testProgress(2, { enrolled: true }) }),
  testPathCard({ id: 'p2', slug: 'ai', title: 'AI from scratch', description: null, ...testProgress(4, { completed: true }) }),
  testPathCard({ id: 'p3', slug: 'learn', title: 'اتعلم إزاي تتعلم', field: MEDICINE, articleCount: 3, readingTimeMinutes: 13 }),
];

describe('PathsPage (F09)', () => {
  let http: HttpTestingController;

  afterEach(() => http?.verify());

  async function render(options: { guest?: boolean; all?: PathCardDto[] } = {}) {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ guest: options.guest }));
    const fixture = TestBed.createComponent(PathsPage);
    fixture.detectChanges();
    http.expectOne(`${TEST_API}/paths`).flush(options.all ?? ALL);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      // Covers without an image ask for the fields' icons (once per app); SSR would wait for them.
      http.match(`${TEST_API}/fields`).forEach((r) => r.flush([]));
      await flushMicrotasks();
      fixture.detectChanges();
    };
    await stable();
    const cards = () => [...root.querySelectorAll('[data-path-card]')].map((c) => c.getAttribute('data-path-card'));
    return { fixture, root, stable, cards, $: <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector) };
  }

  it('fieldsOf: each field once, in the order of the list', () => {
    expect(fieldsOf(ALL).map((f) => f.slug)).toEqual(['software', 'medicine']);
    expect(fieldsOf([])).toEqual([]);
  });

  it('lists every path with its meta, your progress and the completion badge', async () => {
    const { root, cards } = await render();
    expect(cards()).toEqual(['aspnet-core-basics', 'ai', 'learn']);
    expect(TestBed.inject(Title).getTitle()).toBe('المسارات — ReadIn');
    const first = root.querySelector('[data-path-card="aspnet-core-basics"]')!;
    expect(first.getAttribute('href')).toBe('/paths/aspnet-core-basics');
    expect(first.querySelector('[data-path-meta]')!.textContent).toContain('4 مقالات · 22 دقيقة');
    expect(first.querySelector('[data-path-progress]')!.textContent).toContain('2/4');
    expect(first.querySelector('[data-path-completed]')).toBeNull();
    expect(root.querySelector('[data-path-card="ai"] [data-path-completed]')!.textContent).toContain('✓ خلصت المسار');
    // Not enrolled and no progress (e.g. a guest): no bar.
    expect(root.querySelector('[data-path-card="learn"] [data-path-progress]')).toBeNull();
    expect(root.querySelector('[data-path-card="learn"] [data-path-meta]')!.textContent).toContain('3 مقالات · 13 دقيقة');
  });

  it('filters by the fields present in the list, locally', async () => {
    const { root, cards, stable } = await render();
    const chips = [...root.querySelectorAll('[data-path-field-chip]')].map((c) => c.getAttribute('data-path-field-chip'));
    expect(chips).toEqual(['software', 'medicine']);
    (root.querySelector('[data-path-field-chip="medicine"]') as HTMLElement).click();
    await stable();
    expect(cards()).toEqual(['learn']);
    expect(root.querySelector('[data-path-field-chip="medicine"]')!.getAttribute('aria-pressed')).toBe('true');
    (root.querySelector('[data-path-field-chips] .rd-chip') as HTMLElement).click();
    await stable();
    expect(cards()).toHaveLength(3);
  });

  it('no chips with a single field', async () => {
    const { root } = await render({ all: [ALL[0], ALL[1]] });
    expect(root.querySelector('[data-path-field-chips]')).toBeNull();
  });

  it('My paths loads once opened; an empty list leads back to All paths', async () => {
    const { root, cards, stable } = await render();
    (root.querySelector('[data-paths-tab="mine"]') as HTMLElement).click();
    await stable();
    const mine = http.expectOne(`${TEST_API}/me/paths`);
    mine.flush([]);
    await stable();
    expect(root.querySelector('[data-paths-tab="mine"]')!.getAttribute('aria-selected')).toBe('true');
    expect(root.querySelector('[data-paths-mine-empty]')!.textContent).toContain('لسه مبدأتش أي مسار');
    (root.querySelector('[data-paths-mine-empty] button') as HTMLElement).click();
    await stable();
    expect(cards()).toHaveLength(3);
    // Opening it again doesn't reload.
    (root.querySelector('[data-paths-tab="mine"]') as HTMLElement).click();
    await stable();
    http.expectNone(`${TEST_API}/me/paths`);
  });

  it('My paths keeps the field filter only when the field is there', async () => {
    const { root, cards, stable } = await render();
    (root.querySelector('[data-path-field-chip="medicine"]') as HTMLElement).click();
    await stable();
    (root.querySelector('[data-paths-tab="mine"]') as HTMLElement).click();
    await stable();
    http.expectOne(`${TEST_API}/me/paths`).flush([ALL[0], ALL[1]]);
    await stable();
    expect(cards()).toEqual(['aspnet-core-basics', 'ai']);
  });

  it('a guest opening My paths gets the sign-in prompt and stays on All paths', async () => {
    const { root, stable } = await render({ guest: true });
    (root.querySelector('[data-paths-tab="mine"]') as HTMLElement).click();
    await stable();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
    expect(root.querySelector('[data-paths-tab="all"]')!.getAttribute('aria-selected')).toBe('true');
    http.expectNone(`${TEST_API}/me/paths`);
  });

  it('arrow keys move between the tabs, mirrored in RTL', async () => {
    const { root, stable } = await render();
    root.querySelector('[data-paths-tab="all"]')!.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true }));
    await stable();
    http.expectOne(`${TEST_API}/me/paths`).flush([]);
    await stable();
    expect(root.querySelector('[data-paths-tab="mine"]')!.getAttribute('aria-selected')).toBe('true');
  });

  it('signing out forgets My paths and reloads the list without progress', async () => {
    const { root, stable } = await render();
    (root.querySelector('[data-paths-tab="mine"]') as HTMLElement).click();
    await stable();
    http.expectOne(`${TEST_API}/me/paths`).flush([ALL[0]]);
    await stable();
    TestBed.inject(SessionStore).setGuest();
    await stable();
    http.expectOne(`${TEST_API}/paths`).flush(ALL.map((p) => ({ ...p, progress: null, enrollment: null })));
    await stable();
    expect(root.querySelector('[data-paths-tab="all"]')!.getAttribute('aria-selected')).toBe('true');
    expect(root.querySelectorAll('[data-path-progress]')).toHaveLength(0);
  });

  it('an empty catalog and a failed load', async () => {
    const empty = await render({ all: [] });
    expect(empty.$('[data-paths-empty]')!.textContent).toContain('لسه مفيش مسارات');

    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
    const fixture = TestBed.createComponent(PathsPage);
    fixture.detectChanges();
    http.expectOne(`${TEST_API}/paths`).flush(null, { status: 500, statusText: 'Error' });
    await flushMicrotasks();
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    expect(root.querySelector('rd-error-state')!.textContent).toContain('معرفناش نحمّل المسارات.');
    (root.querySelector('rd-error-state button') as HTMLElement).click();
    http.expectOne(`${TEST_API}/paths`).flush(ALL);
    await flushMicrotasks();
    fixture.detectChanges();
    expect(root.querySelectorAll('[data-path-card]')).toHaveLength(3);
    http.expectOne(`${TEST_API}/fields`).flush([]);
  });
});
