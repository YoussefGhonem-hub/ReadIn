import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, setupSocialTesting } from '../../../testing/social-testing';
import { testPathCard } from '../../../testing/paths-testing';
import { SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ContinueReadingApi } from './continue-reading.api';
import { ArticlePathDto, PathCardDto } from './models';
import { PathsApi } from './paths.api';

/** The F09 and F03 "continue reading" endpoints: methods, paths, query parameters and bodies. Every call is silent. */
describe('PathsApi (F09) and ContinueReadingApi (F03)', () => {
  let http: HttpTestingController;
  let api: PathsApi;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
    api = TestBed.inject(PathsApi);
  });

  afterEach(() => http.verify());

  function expectCall(method: string, url: string, options: { body?: unknown; personal?: boolean; status?: number; response?: unknown } = {}) {
    const req = http.expectOne((r) => r.urlWithParams === url);
    expect(req.request.method).toBe(method);
    expect(req.request.body).toEqual(options.body ?? null);
    expect(req.request.context.get(SILENT_ERRORS)).toBe(true);
    expect(req.request.context.get(WITH_SESSION)).toBe(options.personal ?? false);
    req.flush(options.response ?? null, { status: options.status ?? 200, statusText: 'OK' });
  }

  it('browsing: the list (optionally by field), a path, the paths of a user', () => {
    api.list().subscribe();
    expectCall('GET', `${TEST_API}/paths`);
    api.list('software').subscribe();
    expectCall('GET', `${TEST_API}/paths?field=software`);
    expect(api.pathUrl('aspnet core')).toBe(`${TEST_API}/paths/aspnet%20core`);
    api.path('aspnet-core').subscribe();
    expectCall('GET', `${TEST_API}/paths/aspnet-core`);
    api.userPaths('@mona').subscribe();
    expectCall('GET', `${TEST_API}/users/mona/paths`);
  });

  it("an article's path, or null on 204", () => {
    const block = { path: testPathCard(), position: 2, total: 4, previous: null, next: null } satisfies ArticlePathDto;
    let result: ArticlePathDto | null | undefined;
    api.articlePath('a 1').subscribe((r) => (result = r));
    expectCall('GET', `${TEST_API}/articles/a%201/path`, { personal: true, response: block });
    expect(result).toEqual(block);
    api.articlePath('a2').subscribe((r) => (result = r));
    expectCall('GET', `${TEST_API}/articles/a2/path`, { personal: true, status: 204 });
    expect(result).toBeNull();
  });

  it('my paths, the active one (null on 204), enroll and leave', () => {
    api.mine().subscribe();
    expectCall('GET', `${TEST_API}/me/paths`, { personal: true });
    let active: PathCardDto | null | undefined;
    api.active().subscribe((r) => (active = r));
    expectCall('GET', `${TEST_API}/me/paths/active`, { personal: true, response: testPathCard() });
    expect(active?.id).toBe('p1');
    api.active().subscribe((r) => (active = r));
    expectCall('GET', `${TEST_API}/me/paths/active`, { personal: true, status: 204 });
    expect(active).toBeNull();
    api.enroll('p1').subscribe();
    expectCall('PUT', `${TEST_API}/me/paths/p1`);
    api.leave('p1').subscribe();
    expectCall('DELETE', `${TEST_API}/me/paths/p1`);
  });

  it('continue reading: three by default', () => {
    const continueReading = TestBed.inject(ContinueReadingApi);
    continueReading.list().subscribe();
    expectCall('GET', `${TEST_API}/me/continue-reading?limit=3`, { personal: true });
    continueReading.list(10).subscribe();
    expectCall('GET', `${TEST_API}/me/continue-reading?limit=10`, { personal: true });
  });
});
