import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { ReactionType, ReactorDto } from '../../core/api/models';
import { ReactorsSheet } from './reactors-sheet';

function reactor(i: number, type: ReactionType): ReactorDto {
  return { user: { id: `u${i}`, displayName: `Reader ${i}`, username: `reader${i}`, avatarUrl: null, isVerified: false }, type, reactedAt: '2026-11-03T08:00:00Z' };
}

describe('ReactorsSheet (F10 who reacted)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ guest: true }));
  });

  afterEach(() => http.verify());

  async function open() {
    const fixture = TestBed.createComponent(ReactorsSheet);
    fixture.componentRef.setInput('articleId', 'a1');
    fixture.componentRef.setInput('counts', { insightful: 21, love: 3, fire: 0, mindBlown: 1 });
    fixture.componentRef.setInput('total', 25);
    fixture.componentRef.setInput('open', true);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    return { fixture, root, stable };
  }

  it('lists everyone first, with a tab per used reaction and its count', async () => {
    const { root, stable } = await open();
    const req = http.expectOne((r) => r.url === `${TEST_API}/articles/a1/reactions`);
    expect(req.request.params.get('type')).toBeNull();
    expect(req.request.params.get('limit')).toBe('20');
    req.flush({ items: [reactor(1, 'love'), reactor(2, 'insightful')], nextCursor: null });
    await stable();

    const tabs = [...root.querySelectorAll('[role="tab"]')];
    expect(tabs.map((t) => t.getAttribute('data-reactors-tab'))).toEqual(['all', 'insightful', 'love', 'mindBlown']);
    expect(tabs[0].textContent).toContain('25');
    expect(tabs[0].getAttribute('aria-selected')).toBe('true');
    expect(root.querySelectorAll('[data-reactor]').length).toBe(2);
    expect(root.querySelector('[data-reactor] [role="img"]')!.getAttribute('aria-label')).toBe('حبيته');
    expect(root.querySelector('[data-reactors-more]')).toBeNull();
  });

  it('pages a type with "show more"', async () => {
    const { root, stable } = await open();
    http.expectOne((r) => r.url.endsWith('/reactions')).flush({ items: [], nextCursor: null });
    await stable();

    (root.querySelector('[data-reactors-tab="insightful"]') as HTMLElement).click();
    await stable();
    const first = http.expectOne((r) => r.url.endsWith('/reactions'));
    expect(first.request.params.get('type')).toBe('insightful');
    first.flush({ items: Array.from({ length: 20 }, (_, i) => reactor(i, 'insightful')), nextCursor: 'c20' });
    await stable();
    expect(root.querySelectorAll('[data-reactor]').length).toBe(20);

    (root.querySelector('[data-reactors-more]') as HTMLElement).click();
    const next = http.expectOne((r) => r.url.endsWith('/reactions'));
    expect(next.request.params.get('cursor')).toBe('c20');
    expect(next.request.params.get('type')).toBe('insightful');
    next.flush({ items: [reactor(20, 'insightful')], nextCursor: null });
    await stable();
    expect(root.querySelectorAll('[data-reactor]').length).toBe(21);
    expect(root.querySelector('[data-reactors-more]')).toBeNull();
  });

  it('shows an error with retry', async () => {
    const { root, stable } = await open();
    http.expectOne((r) => r.url.endsWith('/reactions')).flush(null, { status: 500, statusText: 'Error' });
    await stable();
    expect(root.querySelector('rd-error-state')).not.toBeNull();
    (root.querySelector('rd-error-state button') as HTMLElement).click();
    http.expectOne((r) => r.url.endsWith('/reactions')).flush({ items: [reactor(1, 'love')], nextCursor: null });
    await stable();
    expect(root.querySelectorAll('[data-reactor]').length).toBe(1);
  });
});
