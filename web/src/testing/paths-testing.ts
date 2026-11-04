import {
  ArticlePathDto,
  ContinueReadingDto,
  PathArticleRefDto,
  PathCardDto,
  PathDetailsDto,
  PathItemDto,
} from '../app/core/api/models';
import { testCard } from './social-testing';

const SOFTWARE = { id: 'f1', slug: 'software', name: 'Software', nameAr: 'البرمجيات', nameEn: 'Software' };

/** A 4-article path as a guest sees it (no progress, not enrolled). */
export function testPathCard(patch: Partial<PathCardDto> = {}): PathCardDto {
  return {
    id: 'p1',
    slug: 'aspnet-core-basics',
    title: 'أساسيات ASP.NET Core',
    description: 'من أول الـ middleware لحد الـ deployment، خطوة بخطوة.',
    field: SOFTWARE,
    articleCount: 4,
    readingTimeMinutes: 22,
    coverUrl: null,
    progress: null,
    enrollment: null,
    ...patch,
  };
}

export function testArticleRef(position: number, patch: Partial<PathArticleRefDto> = {}): PathArticleRefDto {
  return { id: `a${position}`, slug: `article-${position}`, title: `Article ${position}`, language: 'en', position, readingTimeMinutes: 5, ...patch };
}

/** Signed in: `readCount` of 4 read, the next one is the first unread; `enrolled` adds the enrollment. */
export function testProgress(readCount: number, options: { enrolled?: boolean; completed?: boolean; total?: number } = {}): Partial<PathCardDto> {
  const total = options.total ?? 4;
  return {
    progress: { readCount, total, percent: Math.floor((readCount * 100) / total), next: readCount < total ? testArticleRef(readCount + 1) : null },
    enrollment: options.enrolled || options.completed ? { enrolledAt: '2026-10-20T09:00:00Z', completedAt: options.completed ? '2026-11-01T09:00:00Z' : null } : null,
  };
}

export function testPathItem(position: number, isRead = false): PathItemDto {
  return { position, isRead, article: testCard({ id: `a${position}`, slug: `article-${position}`, title: `Article ${position}`, readingTimeMinutes: 5 }) };
}

export function testPathDetails(patch: Partial<PathDetailsDto> = {}, readCount = 0): PathDetailsDto {
  return { ...testPathCard(), items: [1, 2, 3, 4].map((p) => testPathItem(p, p <= readCount)), ...patch };
}

export function testArticlePath(patch: Partial<ArticlePathDto> = {}): ArticlePathDto {
  return {
    path: testPathCard(),
    position: 2,
    total: 4,
    previous: testArticleRef(1),
    next: testCard({ id: 'a3', slug: 'article-3', title: 'Article 3' }),
    ...patch,
  };
}

export function testContinueReading(id: string, percent = 40, patch: Partial<ContinueReadingDto> = {}): ContinueReadingDto {
  return {
    article: testCard({ id, slug: `slug-${id}`, title: `Reading ${id}`, language: 'ar-EG' }),
    percent,
    language: 'ar-EG',
    updatedAt: '2026-11-03T08:00:00Z',
    ...patch,
  };
}
