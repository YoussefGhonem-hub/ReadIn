import { RESPONSE_INIT } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { Meta, Title } from '@angular/platform-browser';
import { TEST_API, WARM_UP_TIMEOUT_MS, flushMicrotasks, problem, setupSocialTesting, testCard, warmUpPostCards } from '../../../testing/social-testing';
import { ArticleCardDto, CursorPage, FieldPageDto, UserSummaryDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { testMe } from '../../../testing/auth-testing';
import { FieldPageStore } from './field-page.store';
import { FieldPage } from './field.page';

const SOFTWARE: FieldPageDto = {
  id: 'f-software',
  slug: 'software',
  name: 'البرمجيات',
  nameAr: 'البرمجيات',
  nameEn: 'Software',
  icon: 'code',
  color: 'primary',
  isSensitive: false,
  articleCount: 32,
  followerCount: 86,
  isFollowing: false,
  topics: [
    { id: 't-dotnet', slug: 'dotnet', name: '.NET', nameAr: '.NET', nameEn: '.NET', articleCount: 2, isFollowing: false },
    { id: 't-arch', slug: 'architecture', name: 'المعمارية', nameAr: 'المعمارية', nameEn: 'Architecture', articleCount: 0, isFollowing: true },
  ],
};
const writer = (id: string, patch: Partial<UserSummaryDto> = {}): UserSummaryDto => ({
  id,
  displayName: `Writer ${id}`,
  username: `writer_${id}`,
  avatarUrl: null,
  isVerified: false,
  bio: null,
  isFollowing: false,
  followsYou: false,
  ...patch,
});
const card = (n: number): ArticleCardDto => testCard({ id: `a${n}`, slug: `article-${n}`, title: `Article ${n}` });
const page = (from: number, count: number, nextCursor: string | null): CursorPage<ArticleCardDto> => ({
  items: Array.from({ length: count }, (_, i) => card(from + i)),
  nextCursor,
});

type Answer<T> = T | { status: number; code: string };

function answer<T extends object>(req: TestRequest, body: Answer<T>): void {
  if (body && typeof body === 'object' && 'status' in body && 'code' in body) req.flush(problem(body.status, body.code), { status: body.status, statusText: 'Error' });
  else req.flush(body);
}

describe('FieldPage (F15)', () => {
  let http: HttpTestingController;

  // The cards prefetch their preview chunk: load it once here, not inside the first test (see warmUpPostCards).
  beforeAll(warmUpPostCards, WARM_UP_TIMEOUT_MS);
  let response: { status?: number };
  const url = `${TEST_API}/fields/software`;
  const articlesOf = (topic: string | null, cursor: string | null = null) => (r: { url: string; params: { get(name: string): string | null; has(name: string): boolean } }) =>
    r.url === `${url}/articles` && r.params.get('topic') === topic && r.params.get('cursor') === cursor && r.params.get('limit') === '20';

  afterEach(() => {
    http?.verify();
    document.head.querySelectorAll('[data-rd-field-seo]').forEach((el) => el.remove());
  });

  async function render(
    options: {
      slug?: string;
      topic?: string;
      field?: Answer<FieldPageDto>;
      list?: Answer<CursorPage<ArticleCardDto>>;
      writers?: Answer<UserSummaryDto[]>;
      guest?: boolean;
    } = {},
  ) {
    TestBed.resetTestingModule();
    response = {};
    ({ http } = setupSocialTesting({ guest: options.guest ?? true, providers: [{ provide: RESPONSE_INIT, useValue: response }] }));
    const fixture = TestBed.createComponent(FieldPage);
    fixture.componentRef.setInput('slug', options.slug ?? 'software');
    if (options.topic) fixture.componentRef.setInput('topic', options.topic);
    fixture.detectChanges();
    const base = `${TEST_API}/fields/${options.slug ?? 'software'}`;
    answer(http.expectOne(base), options.field ?? SOFTWARE);
    answer(http.expectOne((r) => r.url === `${base}/articles` && r.params.get('topic') === (options.topic ?? null) && !r.params.has('cursor')), options.list ?? page(1, 20, '20'));
    answer(http.expectOne((r) => r.url === `${base}/writers` && r.params.get('limit') === '10'), options.writers ?? [writer('1'), writer('2', { isFollowing: true })]);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
      fixture.detectChanges();
    };
    await stable();
    const store = fixture.debugElement.injector.get(FieldPageStore);
    return { fixture, root, stable, store, $: <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector) };
  }

  const robots = () => TestBed.inject(Meta).getTag('name="robots"')?.content ?? null;
  const canonical = () => document.head.querySelector('link[rel="canonical"][data-rd-field-seo]')?.getAttribute('href') ?? null;
  const text = (el: Element | null) => el?.textContent?.replace(/\s+/g, ' ').trim() ?? null;

  it('shows the field (name, articles, followers, Follow), its topics, top writers and its articles; title, description and canonical', async () => {
    const { $, root } = await render();
    expect(text($('[data-field-name]'))).toBe('البرمجيات');
    expect($('[data-field-name]')!.getAttribute('dir')).toBe('auto');
    expect(text($('[data-field-count]'))).toBe('32 مقالًا');
    expect(text($('[data-field-followers]'))).toBe('86 متابعًا');
    expect($('[data-follow-field]')!.getAttribute('aria-pressed')).toBe('false');
    expect(text($('[data-follow-field]'))).toContain('متابعة المجال');
    // "All" first, then every topic (an empty one too); a followed topic has a check.
    const chips = [...root.querySelectorAll('[data-topic-chip]')];
    expect(chips.map((c) => c.getAttribute('data-topic-chip'))).toEqual(['', 'dotnet', 'architecture']);
    expect(chips[0].getAttribute('aria-current')).toBe('page');
    expect(chips[1].getAttribute('href')).toBe('/?topic=dotnet');
    expect(chips[2].querySelector('svg[data-topic-following]')).not.toBeNull();
    expect(chips[1].querySelector('svg[data-topic-following]')).toBeNull();
    // The check is decoration; screen readers hear the words, as part of the chip's name.
    expect(chips[2].querySelector('svg[data-topic-following]')!.getAttribute('aria-hidden')).toBe('true');
    expect(text(chips[2].querySelector('.sr-only'))).toBe('· تتابعه');
    expect(chips[1].querySelector('.sr-only')).toBeNull();
    expect($('[data-topic-bar]')).toBeNull();
    expect(root.querySelectorAll('[data-field-writers] [data-writer]')).toHaveLength(2);
    expect(root.querySelectorAll('[data-field-articles] rd-post-card')).toHaveLength(20);
    expect($('[data-health-disclaimer]')).toBeNull();
    expect(TestBed.inject(Title).getTitle()).toBe('البرمجيات — ReadIn');
    expect(TestBed.inject(Meta).getTag('name="description"')!.content).toBe('32 مقالًا عن البرمجيات على ReadIn.');
    expect(canonical()).toMatch(/\/f\/software$/);
    expect(robots()).toBeNull();
    expect(response.status).toBeUndefined();
  });

  it('?topic= selects its chip and loads its articles; another topic reloads only the articles', async () => {
    const { $, root, fixture, stable } = await render({ topic: 'dotnet', list: page(1, 2, null) });
    expect(root.querySelector('[data-topic-chip="dotnet"]')!.getAttribute('aria-current')).toBe('page');
    expect(root.querySelector('[data-topic-chip=""]')!.getAttribute('aria-current')).toBeNull();
    expect($('[data-topic-bar]')!.getAttribute('data-topic')).toBe('dotnet');
    expect(text($('[data-topic-bar]'))).toContain('مقالان');
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(2);
    expect(text($('[data-list-end]'))).toBe('اطّلعت على كل مقالات هذا الموضوع.');
    expect(TestBed.inject(Title).getTitle()).toBe('.NET · البرمجيات — ReadIn');
    expect(canonical()).toMatch(/\/f\/software\?topic=dotnet$/);

    // An empty topic: its empty state, noindex. Neither the header nor the writers load again.
    fixture.componentRef.setInput('topic', 'architecture');
    fixture.detectChanges();
    answer(http.expectOne(articlesOf('architecture')), page(1, 0, null));
    await stable();
    expect(text($('[data-list-empty] h3'))).toBe('لا توجد مقالات في هذا الموضوع بعد');
    expect(robots()).toBe('noindex');
    expect(text($('[data-follow-topic]'))).toContain('تتابعه');

    // Back to the whole field.
    fixture.componentRef.setInput('topic', undefined);
    fixture.detectChanges();
    answer(http.expectOne(articlesOf(null)), page(1, 20, '20'));
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(20);
    expect($('[data-topic-bar]')).toBeNull();
  });

  it('loads the next page with the cursor, then says that was all', async () => {
    const { root, store, stable, $ } = await render();
    const more = store.articles.loadMore();
    answer(http.expectOne(articlesOf(null, '20')), { items: [card(20), ...page(21, 11, null).items], nextCursor: null });
    await more;
    await stable();
    // Article 20 was already shown: no second card.
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(31);
    expect(text($('[data-list-end]'))).toBe('اطّلعت على كل مقالات هذا المجال.');
  });

  it('a sensitive field shows the health note', async () => {
    const medicine = { ...SOFTWARE, id: 'f-med', slug: 'medicine', nameAr: 'الطب', nameEn: 'Medicine', isSensitive: true, topics: [] };
    const { $, root } = await render({ slug: 'medicine', field: medicine, list: page(1, 1, null), writers: [] });
    expect($('[data-health-disclaimer]')).not.toBeNull();
    expect(root.querySelector('[data-field-topics]')).toBeNull();
    // No writers: the section is left out.
    expect(root.querySelector('[data-field-writers]')).toBeNull();
  });

  it('an empty field shows its empty state and is noindex', async () => {
    const { $ } = await render({ field: { ...SOFTWARE, articleCount: 0, followerCount: 1 }, list: page(1, 0, null), writers: [] });
    expect(text($('[data-field-count]'))).toBe('0 مقال');
    expect(text($('[data-field-followers]'))).toBe('متابع واحد');
    expect(text($('[data-list-empty] h3'))).toBe('لا توجد مقالات في هذا المجال بعد');
    expect(robots()).toBe('noindex');
    expect(TestBed.inject(Meta).getTag('name="description"')!.content).toBe('لا توجد بعد مقالات عن البرمجيات على ReadIn.');
  });

  it('an unknown field is a 404 page, noindex', async () => {
    const notFound = { status: 404, code: 'field.not_found' };
    const { $ } = await render({ slug: 'nope', field: notFound, list: notFound, writers: notFound });
    expect(text($('[data-field-not-found] h3'))).toBe('هذا المجال غير موجود');
    expect($('[data-field-header]')).toBeNull();
    expect(response.status).toBe(404);
    expect(robots()).toBe('noindex');
    expect(TestBed.inject(Title).getTitle()).toBe('هذا المجال غير موجود — ReadIn');
    expect(canonical()).toBeNull();
  });

  it('a topic the field does not have keeps the header and is a 404, noindex', async () => {
    const { $ } = await render({ topic: 'cobol', list: { status: 404, code: 'topic.not_found' } });
    expect($('[data-field-header]')).not.toBeNull();
    expect(text($('[data-topic-not-found] h3'))).toBe('هذا الموضوع غير موجود');
    expect(text($('[data-topic-not-found]'))).toContain('البرمجيات');
    expect(response.status).toBe(404);
    expect(robots()).toBe('noindex');
    expect(canonical()).toBeNull();
  });

  it('a failure shows an error with Retry, which loads the page again', async () => {
    const { $, stable, root } = await render({ field: { status: 503, code: 'server.error' } });
    expect($('rd-error-state')).not.toBeNull();
    $<HTMLButtonElement>('rd-error-state button')!.click();
    answer(http.expectOne(url), SOFTWARE);
    answer(http.expectOne(articlesOf(null)), page(1, 2, null));
    answer(http.expectOne(`${url}/writers?limit=10`), []);
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(2);
  });

  it('writers that fail to load offer Retry; the rest of the page stays', async () => {
    const { $, root, stable } = await render({ writers: { status: 503, code: 'server.error' } });
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(20);
    $<HTMLButtonElement>('[data-field-writers-error] button')!.click();
    answer(http.expectOne(`${url}/writers?limit=10`), [writer('1')]);
    await stable();
    expect(root.querySelectorAll('[data-field-writers] [data-writer]')).toHaveLength(1);
  });

  it('a guest who taps Follow gets the sign-in prompt, and nothing is sent', async () => {
    const { $ } = await render();
    $<HTMLButtonElement>('[data-follow-field]')!.click();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
  });

  describe('signed in', () => {
    it('Follow shows at once, moves the follower count and saves your interests', async () => {
      const { $, stable } = await render({ guest: false });
      $<HTMLButtonElement>('[data-follow-field]')!.click();
      await stable();
      expect($('[data-follow-field]')!.getAttribute('aria-pressed')).toBe('true');
      expect(text($('[data-follow-field]'))).toContain('تتابعه');
      expect(text($('[data-field-followers]'))).toBe('87 متابعًا');
      const req = http.expectOne(`${TEST_API}/me/interests/fields/f-software`);
      expect(req.request.method).toBe('PUT');
      req.flush({ fieldIds: ['f-software'], topicIds: ['t-arch'] });
      await stable();
      expect(TestBed.inject(SessionStore).me()!.interests).toEqual({ fieldIds: ['f-software'], topicIds: ['t-arch'] });
      expect(text($('[data-field-followers]'))).toBe('87 متابعًا');
    });

    it('unfollowing your last interests is refused: the toggle stays on, with the message', async () => {
      const { $, stable } = await render({ guest: false, field: { ...SOFTWARE, isFollowing: true, followerCount: 87 } });
      TestBed.inject(SessionStore).setMe(testMe({ interests: { fieldIds: ['f-software'], topicIds: ['t-dotnet', 't-arch'] } }));
      $<HTMLButtonElement>('[data-follow-field]')!.click();
      await stable();
      expect(text($('[data-field-followers]'))).toBe('86 متابعًا');
      const req = http.expectOne(`${TEST_API}/me/interests/fields/f-software`);
      expect(req.request.method).toBe('DELETE');
      req.flush(problem(400, 'user.interests.min_three'), { status: 400, statusText: 'Bad Request' });
      await stable();
      expect($('[data-follow-field]')!.getAttribute('aria-pressed')).toBe('true');
      expect(text($('[data-field-followers]'))).toBe('87 متابعًا');
      expect(TestBed.inject(ToastService).toasts().map((t) => t.message)).toEqual(['يجب أن تتابع 3 اهتمامات على الأقل. تابع مجالًا أو موضوعًا آخر أولًا.']);
    });

    it('the chosen topic can be followed; a failure undoes it and says why', async () => {
      const { $, stable } = await render({ guest: false, topic: 'dotnet', list: page(1, 2, null) });
      $<HTMLButtonElement>('[data-follow-topic]')!.click();
      await stable();
      expect($('[data-follow-topic]')!.getAttribute('aria-pressed')).toBe('true');
      // Another tap while it is saved waits.
      $<HTMLButtonElement>('[data-follow-topic]')!.click();
      http.expectOne(`${TEST_API}/me/interests/topics/t-dotnet`).flush(problem(503, 'server.error'), { status: 503, statusText: 'Unavailable' });
      await stable();
      expect($('[data-follow-topic]')!.getAttribute('aria-pressed')).toBe('false');
      expect(TestBed.inject(ToastService).toasts()).toHaveLength(1);
    });
  });
});
