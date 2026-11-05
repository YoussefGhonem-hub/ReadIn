import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { HighlightGroupDto } from '../../core/api/highlights.api';
import { SavedHighlights } from './saved-highlights';

const AUTHOR = { id: 'u-mona', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: true };

function group(id: string, language: 'ar-EG' | 'en', title: string, highlights: [string, string, string][], author: typeof AUTHOR | null = AUTHOR): HighlightGroupDto {
  return {
    article: { id, slug: id.replace(/^a-/, ''), language, title, author },
    highlights: highlights.map(([hid, blockId, text]) => ({ id: hid, blockId, startOffset: 0, endOffset: text.length, text, createdAt: '2026-11-05T10:00:00Z' })),
    latestAt: '2026-11-05T10:00:00Z',
  };
}

async function render() {
  const { http } = setupSocialTesting();
  const fixture = TestBed.createComponent(SavedHighlights);
  fixture.detectChanges();
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  return { fixture, http, stable, root: fixture.nativeElement as HTMLElement };
}

describe('Saved → Highlights (F14, F30)', () => {
  let http: HttpTestingController;
  afterEach(() => http.verify());

  it('one group per article version, each highlight a link to its block in that version', async () => {
    const t = await render();
    http = t.http;
    const req = t.http.expectOne((r) => r.url === `${TEST_API}/me/highlights`);
    expect(req.request.params.get('limit')).toBe('20');
    req.flush({
      items: [
        group('a-lab', 'ar-EG', 'تجربة الـ Highlights', [
          ['h2', 'p3', 'مُهِمّ جداً'],
          ['h1', 'p1', 'ASP.NET Core، أكيد شفت الـ Dependency Injection'],
        ]),
        group('a-lab', 'en', 'Highlights lab', [['h3', 'e1', 'Injection (الحقن) everywhere']], null),
      ],
      nextCursor: 'c2',
    });
    await t.stable();
    const groups = t.root.querySelectorAll('[data-highlight-group]');
    expect([...groups].map((g) => g.getAttribute('data-highlight-group'))).toEqual(['a-lab|ar-EG', 'a-lab|en']);
    expect(groups[0].querySelector('[data-group-title]')!.getAttribute('href')).toBe('/ar/a/lab');
    expect(groups[0].querySelector('[data-group-meta]')!.textContent).toContain('Mona Adel');
    expect(groups[0].querySelector('[data-group-meta]')!.textContent).toContain('النسخة العربي');
    expect(groups[1].querySelector('[data-group-meta]')!.textContent).toContain('مستخدم محذوف');
    expect(groups[1].querySelector('[data-group-meta]')!.textContent).toContain('النسخة الإنجليزي');
    const links = [...t.root.querySelectorAll<HTMLAnchorElement>('[data-saved-highlight]')];
    expect(links.map((a) => a.getAttribute('href'))).toEqual(['/ar/a/lab#b-p3', '/ar/a/lab#b-p1', '/en/a/lab#b-e1']);
    // The text keeps the version's direction, other-direction runs isolated.
    expect(links[1].querySelector('rd-bdi-text')!.getAttribute('dir')).toBe('rtl');
    expect(links[1].querySelector('bdi')!.textContent).toBe('ASP.NET Core');
    expect(links[2].querySelector('rd-bdi-text')!.getAttribute('dir')).toBe('ltr');

    // The next page: a group already shown (it moved up meanwhile) is dropped.
    (t.fixture.componentInstance as unknown as { loadMore(): Promise<void> }).loadMore();
    const next = t.http.expectOne((r) => r.url === `${TEST_API}/me/highlights` && r.params.get('cursor') === 'c2');
    next.flush({ items: [group('a-lab', 'en', 'Highlights lab', [['h3', 'e1', 'x']]), group('a-di', 'ar-EG', 'يعني إيه DI', [['h4', 'p1', 'كلام']])], nextCursor: null });
    await t.stable();
    expect([...t.root.querySelectorAll('[data-highlight-group]')].map((g) => g.getAttribute('data-highlight-group'))).toEqual([
      'a-lab|ar-EG',
      'a-lab|en',
      'a-di|ar-EG',
    ]);
  });

  it('none yet: the empty state', async () => {
    const t = await render();
    http = t.http;
    t.http.expectOne((r) => r.url === `${TEST_API}/me/highlights`).flush({ items: [], nextCursor: null });
    await t.stable();
    expect(t.root.querySelector('[data-highlights-empty]')!.textContent).toContain('لسه مفيش Highlights');
  });
});
