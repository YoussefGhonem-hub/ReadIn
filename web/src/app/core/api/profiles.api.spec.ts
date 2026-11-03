import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, setupSocialTesting } from '../../../testing/social-testing';
import { SILENT_ERRORS } from './api.config';
import { ProfilesApi } from './profiles.api';

/** The F14 endpoints: methods, paths, query parameters and bodies of the contract. Every call is silent. */
describe('ProfilesApi (F14)', () => {
  let http: HttpTestingController;
  let api: ProfilesApi;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
    api = TestBed.inject(ProfilesApi);
  });

  afterEach(() => http.verify());

  function expectCall(method: string, url: string, body: unknown = null) {
    const req = http.expectOne((r) => r.urlWithParams === url);
    expect(req.request.method).toBe(method);
    expect(req.request.body).toEqual(body);
    expect(req.request.context.get(SILENT_ERRORS)).toBe(true);
    req.flush(null);
  }

  it('profile, articles and public reading stats by username (a leading @ is dropped)', () => {
    expect(api.profileUrl('@mona')).toBe(`${TEST_API}/users/mona`);
    api.profile('mona adel').subscribe();
    expectCall('GET', `${TEST_API}/users/mona%20adel`);
    api.articles('mona').subscribe();
    expectCall('GET', `${TEST_API}/users/mona/articles?limit=20`);
    api.articles('mona', { cursor: 'c2', limit: 10 }).subscribe();
    expectCall('GET', `${TEST_API}/users/mona/articles?limit=10&cursor=c2`);
    api.stats('mona').subscribe();
    expectCall('GET', `${TEST_API}/users/mona/stats`);
    api.heatmap('mona').subscribe();
    expectCall('GET', `${TEST_API}/users/mona/stats/heatmap?days=365`);
  });

  it('edit profile and privacy', () => {
    const body = { displayName: 'Mona', username: 'mona', bio: null, links: { github: null }, expertiseFieldIds: ['f1'], avatarAssetId: null };
    api.updateProfile(body).subscribe();
    expectCall('PATCH', `${TEST_API}/me`, body);
    api.updatePrivacy({ publicReadingStats: true }).subscribe();
    expectCall('PUT', `${TEST_API}/me/privacy`, { publicReadingStats: true });
  });
});
