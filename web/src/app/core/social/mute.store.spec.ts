import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { FieldRefDto, MutesDto } from '../api/models';
import { SessionStore } from '../auth/session.store';
import { MuteScope, MuteStore } from './mute.store';

const FEED: MuteScope = { applies: true };
const OWN_PAGE: MuteScope = { applies: false };
const DOTNET: FieldRefDto = { id: 't1', slug: 'dotnet', name: '.NET', nameAr: 'دوت نت', nameEn: '.NET' };

const MUTES: MutesDto = {
  users: [{ id: 'writer-2', displayName: 'Omar', username: 'omar', avatarUrl: null, isVerified: false, bio: null, isFollowing: false, followsYou: false }],
  fields: [{ id: 'f2', slug: 'health', name: 'Health', nameAr: 'الصحة', nameEn: 'Health', icon: 'heart-pulse', color: 'error' }],
  topics: [],
};

describe('MuteStore (F28)', () => {
  let http: HttpTestingController;
  let store: MuteStore;
  let session: SessionStore;

  beforeEach(() => {
    TestBed.resetTestingModule();
    const setup = setupSocialTesting();
    http = setup.http;
    session = setup.session;
    store = TestBed.inject(MuteStore);
  });
  afterEach(() => http.verify());

  it("starts from the API's flags: a card already muted (a field page's own field) leaves only where mutes apply", () => {
    const card = testCard({ topic: DOTNET, isFieldMuted: true });
    expect(store.hides(card, FEED)).toBe(true);
    expect(store.hides(card, OWN_PAGE)).toBe(false);
    expect(store.hides(card, { applies: true, shownFieldId: () => 'f1' })).toBe(false);
    expect(store.hides(testCard({ isAuthorMuted: true }), FEED)).toBe(true);
    expect(store.hides(testCard(), FEED)).toBe(false);
  });

  it('a field page keeps its own field and picked topic, and leaves out its other muted topics', () => {
    const shownTopic = signal<string | null>(null);
    const fieldPage: MuteScope = { applies: true, shownFieldId: () => 'f1', shownTopicId: shownTopic };
    const card = testCard({ topic: DOTNET, isTopicMuted: true });
    expect(store.hides(card, fieldPage)).toBe(true);
    shownTopic.set('t1');
    expect(store.hides(card, fieldPage)).toBe(false);
  });

  it('a list counts only the cards still shown, so one emptied by mutes shows its empty state', () => {
    const muted = testCard({ id: 'a1', isAuthorMuted: true });
    const other = testCard({ id: 'a2', author: { ...testCard().author!, id: 'writer-2' } });
    expect(store.anyShown([], FEED)).toBe(false);
    expect(store.anyShown([muted], FEED)).toBe(false);
    expect(store.anyShown([muted, other], FEED)).toBe(true);
    expect(store.anyShown([muted], OWN_PAGE)).toBe(true);
  });

  it('guests see everything', () => {
    session.setGuest();
    TestBed.tick();
    expect(store.hides(testCard({ isAuthorMuted: true }), FEED)).toBe(false);
  });

  it('a muted field hides its topics too; a topic mute stays when the field is unmuted', async () => {
    const card = testCard({ topic: DOTNET });
    void store.setFieldMuted('f1', true);
    http.expectOne(`${TEST_API}/me/mutes/fields/f1`).flush({ fieldIds: ['f1'], topicIds: ['t1'] });
    await flushMicrotasks();
    expect(store.isFieldMuted('f1')).toBe(true);
    expect(store.isTopicMuted('t1')).toBe(true);

    void store.setFieldMuted('f1', false);
    http.expectOne(`${TEST_API}/me/mutes/fields/f1`).flush({ fieldIds: [], topicIds: ['t1'] });
    await flushMicrotasks();
    expect(store.isFieldMuted('f1', true)).toBe(false);
    expect(store.hides(card, FEED)).toBe(true);
  });

  it('one request per item at a time: a second tap while the first runs is ignored', async () => {
    const first = store.setTopicMuted('t1', true);
    expect(await store.setTopicMuted('t1', false)).toBe(false);
    http.expectOne(`${TEST_API}/me/mutes/topics/t1`).flush({ fieldIds: [], topicIds: ['t1'] });
    expect(await first).toBe(true);
  });

  it('Show less only once per article until it is undone', async () => {
    const pending = store.showLess('a1');
    expect(await store.showLess('a1')).toBe(false);
    http.expectOne(`${TEST_API}/articles/a1/show-less`).flush(null, { status: 204, statusText: 'No Content' });
    expect(await pending).toBe(true);
    expect(await store.showLess('a1')).toBe(false);
  });

  it('a failed Show less brings the card back with the reason', async () => {
    const card = testCard();
    const pending = store.showLess('a1');
    expect(store.hides(card, FEED)).toBe(true);
    http.expectOne(`${TEST_API}/articles/a1/show-less`).flush(problem(400, 'mute.own_article'), { status: 400, statusText: 'Bad Request' });
    expect(await pending).toBe(false);
    expect(store.hides(card, FEED)).toBe(false);
  });

  it('Settings → Muted teaches it everything muted', () => {
    store.learn(MUTES);
    expect(store.isAuthorMuted('writer-2')).toBe(true);
    expect(store.isFieldMuted('f2')).toBe(true);
    expect(store.isFieldMuted('f1', true)).toBe(false);
  });

  it('signing in as someone else forgets the session changes', () => {
    TestBed.tick(); // the store notes who is signed in
    store.learn(MUTES);
    session.setMe(testMe({ id: 'user-2' }));
    TestBed.tick();
    expect(store.isAuthorMuted('writer-2')).toBe(false);
    expect(store.isFieldMuted('f2')).toBe(false);
  });
});
