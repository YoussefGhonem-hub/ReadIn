import { TestBed } from '@angular/core/testing';
import { testMe } from '../../../testing/auth-testing';
import { setupSocialTesting } from '../../../testing/social-testing';
import { SessionStore } from '../auth/session.store';
import { ReportedStore } from './reported.store';

describe('ReportedStore (F22, store requirements)', () => {
  let store: ReportedStore;
  let session: SessionStore;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ session } = setupSocialTesting());
    store = TestBed.inject(ReportedStore);
  });

  it("starts from the API's reportedByMe flag; Show brings it back here (it stays reported)", () => {
    expect(store.isCollapsed('article', 'a1')).toBe(false);
    expect(store.isCollapsed('article', 'a1', true)).toBe(true);
    store.show('article', 'a1');
    expect(store.isCollapsed('article', 'a1', true)).toBe(false);
  });

  it('a report sent now collapses that target only, by type and id', () => {
    store.markReported('comment', 'c1');
    expect(store.isCollapsed('comment', 'c1')).toBe(true);
    expect(store.isCollapsed('comment', 'c2')).toBe(false);
    expect(store.isCollapsed('article', 'c1')).toBe(false);
    expect(store.isCollapsed('repost', 'c1')).toBe(false);
  });

  it('reporting again after Show collapses it again', () => {
    store.markReported('repost', 'r1');
    store.show('repost', 'r1');
    expect(store.isCollapsed('repost', 'r1')).toBe(false);
    store.markReported('repost', 'r1');
    expect(store.isCollapsed('repost', 'r1')).toBe(true);
  });

  it('a reported account stays visible (only a block hides people), and guests never see a collapse', () => {
    store.markReported('user', 'u1');
    expect(store.isCollapsed('user', 'u1', true)).toBe(false);
    session.setGuest();
    expect(store.isCollapsed('article', 'a1', true)).toBe(false);
  });

  it('forgets what was reported and shown when another account signs in', () => {
    store.markReported('article', 'a1');
    TestBed.tick();
    session.setMe(testMe({ id: 'someone-else' }));
    TestBed.tick();
    expect(store.isCollapsed('article', 'a1')).toBe(false);
  });
});
