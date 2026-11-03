import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, setupSocialTesting } from '../../../testing/social-testing';
import { ContentApi } from './content.api';
import { FollowsApi } from './follows.api';
import { ReactionsApi } from './reactions.api';
import { SavedApi } from './saved.api';

/** The wave 1 endpoints (F10, F12, F13): methods, paths and query parameters of the contract. */
describe('social API clients', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
  });

  afterEach(() => http.verify());

  function expectCall(method: string, url: string, body: unknown = null) {
    const req = http.expectOne((r) => r.urlWithParams === url);
    expect(req.request.method).toBe(method);
    if (body !== undefined) expect(req.request.body).toEqual(body);
    req.flush({});
  }

  it('reactions', () => {
    const api = TestBed.inject(ReactionsApi);
    api.react('a 1', 'mindBlown').subscribe();
    expectCall('PUT', `${TEST_API}/articles/a%201/reaction`, { type: 'mindBlown' });
    api.unreact('a1').subscribe();
    expectCall('DELETE', `${TEST_API}/articles/a1/reaction`);
    api.reactors('a1', { type: 'fire', cursor: 'c2', limit: 10 }).subscribe();
    expectCall('GET', `${TEST_API}/articles/a1/reactions?limit=10&type=fire&cursor=c2`);
    api.reactors('a1').subscribe();
    expectCall('GET', `${TEST_API}/articles/a1/reactions?limit=20`);
  });

  it('saved and collections', () => {
    const api = TestBed.inject(SavedApi);
    api.save('a1').subscribe();
    expectCall('PUT', `${TEST_API}/me/saved/a1`);
    api.unsave('a1').subscribe();
    expectCall('DELETE', `${TEST_API}/me/saved/a1`);
    api.list({ field: 'software', q: 'ريأكت', collection: 'c1', cursor: 'x' }).subscribe();
    expectCall('GET', `${TEST_API}/me/saved?limit=20&field=software&q=${encodeURIComponent('ريأكت')}&collection=c1&cursor=x`);
    api.collections().subscribe();
    expectCall('GET', `${TEST_API}/me/collections`);
    api.createCollection('Interview prep').subscribe();
    expectCall('POST', `${TEST_API}/me/collections`, { name: 'Interview prep' });
    api.renameCollection('c1', 'Interviews').subscribe();
    expectCall('PATCH', `${TEST_API}/me/collections/c1`, { name: 'Interviews' });
    api.deleteCollection('c1').subscribe();
    expectCall('DELETE', `${TEST_API}/me/collections/c1`);
    api.addToCollection('c1', 'a1').subscribe();
    expectCall('PUT', `${TEST_API}/me/collections/c1/articles/a1`);
    api.removeFromCollection('c1', 'a1').subscribe();
    expectCall('DELETE', `${TEST_API}/me/collections/c1/articles/a1`);
  });

  it('follow, people, suggestions, interests and the Following feed', () => {
    const api = TestBed.inject(FollowsApi);
    api.follow('u1').subscribe();
    expectCall('PUT', `${TEST_API}/users/u1/follow`);
    api.unfollow('u1').subscribe();
    expectCall('DELETE', `${TEST_API}/users/u1/follow`);
    api.followers('u1', { q: '@mona' }).subscribe();
    expectCall('GET', `${TEST_API}/users/u1/followers?limit=20&q=@mona`);
    api.following('u1', { cursor: 'c' }).subscribe();
    expectCall('GET', `${TEST_API}/users/u1/following?limit=20&cursor=c`);
    api.suggested().subscribe();
    expectCall('GET', `${TEST_API}/users/suggested?limit=10`);
    api.followField('f1').subscribe();
    expectCall('PUT', `${TEST_API}/me/interests/fields/f1`);
    api.unfollowField('f1').subscribe();
    expectCall('DELETE', `${TEST_API}/me/interests/fields/f1`);
    api.followTopic('t1').subscribe();
    expectCall('PUT', `${TEST_API}/me/interests/topics/t1`);
    api.unfollowTopic('t1').subscribe();
    expectCall('DELETE', `${TEST_API}/me/interests/topics/t1`);

    TestBed.inject(ContentApi).following({ cursor: 'n' }).subscribe();
    expectCall('GET', `${TEST_API}/feed/following?limit=20&cursor=n`);
  });
});
