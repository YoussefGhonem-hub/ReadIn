import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, setupSocialTesting } from '../../../testing/social-testing';
import { RepostsApi } from './reposts.api';

/** F29: methods, paths and query parameters of the contract's Reposts endpoints. */
describe('RepostsApi', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
  });

  afterEach(() => http.verify());

  function expectCall(method: string, url: string) {
    const req = http.expectOne((r) => r.urlWithParams === url);
    expect(req.request.method).toBe(method);
    req.flush({});
  }

  it('repost, undo and a profile’s Reposts tab', () => {
    const api = TestBed.inject(RepostsApi);
    api.repost('a 1').subscribe();
    expectCall('PUT', `${TEST_API}/articles/a%201/repost`);
    api.unrepost('a1').subscribe();
    expectCall('DELETE', `${TEST_API}/articles/a1/repost`);
    api.userReposts('karim', { cursor: 'c2', limit: 10 }).subscribe();
    expectCall('GET', `${TEST_API}/users/karim/reposts?limit=10&cursor=c2`);
    api.userReposts('karim').subscribe();
    expectCall('GET', `${TEST_API}/users/karim/reposts?limit=20`);
  });
});
