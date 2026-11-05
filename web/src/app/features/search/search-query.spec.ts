import {
  cleanSearchQuery,
  filtersOf,
  hasFilters,
  isSearchable,
  sameSearch,
  searchKey,
  searchQueryParams,
  searchRequestOf,
  topicRoute,
} from './search-query';

describe('Search query (F16)', () => {
  it('cleans the query like the API: invisible characters, Arabic-Indic digits, spaces, a leading # and @', () => {
    expect(cleanSearchQuery('  ‏docker‎  ')).toBe('docker');
    expect(cleanSearchQuery('#C#')).toBe('C#');
    expect(cleanSearchQuery('@mona')).toBe('mona');
    expect(cleanSearchQuery('@@mona')).toBe('@mona'); // only one @
    expect(cleanSearchQuery('دوت  نت   ٢٠٢٦')).toBe('دوت نت 2026');
    expect(cleanSearchQuery(null)).toBe('');
  });

  it('needs 1–100 characters with a letter or digit (tatweel alone is not one)', () => {
    expect(isSearchable('a')).toBe(true);
    expect(isSearchable('C#')).toBe(true);
    expect(isSearchable('')).toBe(false);
    expect(isSearchable('!!')).toBe(false);
    expect(isSearchable('ـــ')).toBe(false);
    expect(isSearchable('x'.repeat(100))).toBe(true);
    expect(isSearchable('x'.repeat(101))).toBe(false);
  });

  it('one key for the same search: case, diacritics and Arabic letter forms aside', () => {
    expect(searchKey('Docker')).toBe(searchKey('docker'));
    expect(searchKey('أحمد')).toBe(searchKey('احمد'));
    expect(searchKey('مكتبة')).toBe(searchKey('مكتبه'));
    expect(searchKey('#AI')).toBe(searchKey('ai'));
    expect(searchKey('docker')).not.toBe(searchKey('dockers'));
  });

  it('reads the URL: no query is no search; unknown values fall back to Articles and no filter', () => {
    expect(searchRequestOf({ q: '  ' })).toBeNull();
    expect(searchRequestOf({ q: 'docker' })).toEqual({ q: 'docker', type: 'articles', field: null, lang: null, time: null });
    expect(searchRequestOf({ q: '@mona', type: 'users' })).toEqual({ q: 'mona', type: 'users', field: null, lang: null, time: null });
    expect(searchRequestOf({ q: 'x', type: 'nope', lang: 'fr', time: 'forever', field: 'software' })).toEqual({
      q: 'x',
      type: 'articles',
      field: 'software',
      lang: null,
      time: null,
    });
  });

  it('sends the reading-time chips as minute ranges, and filters only on Articles', () => {
    const base = { q: 'x', type: 'articles' as const, field: 'software', lang: 'ar-EG' as const };
    expect(filtersOf({ ...base, time: 'short' })).toEqual({ field: 'software', lang: 'ar-EG', maxMinutes: 5 });
    expect(filtersOf({ ...base, time: 'medium' })).toEqual({ field: 'software', lang: 'ar-EG', minMinutes: 6, maxMinutes: 10 });
    expect(filtersOf({ ...base, time: 'long' })).toEqual({ field: 'software', lang: 'ar-EG', minMinutes: 11 });
    expect(filtersOf({ ...base, type: 'users', time: 'long' })).toEqual({});
    expect(hasFilters({ ...base, time: null })).toBe(true);
    expect(hasFilters({ ...base, type: 'tags', time: null })).toBe(false);
    expect(hasFilters(null)).toBe(false);
  });

  it('the same search: filters only count on Articles', () => {
    const a = { q: 'x', type: 'users' as const, field: null, lang: null, time: null };
    expect(sameSearch(a, { ...a, lang: 'en' })).toBe(true);
    expect(sameSearch({ ...a, type: 'articles' }, { ...a, type: 'articles', lang: 'en' })).toBe(false);
    expect(sameSearch(a, { ...a, q: 'y' })).toBe(false);
    expect(sameSearch(null, null)).toBe(true);
    expect(sameSearch(a, null)).toBe(false);
  });

  it('leaves the defaults out of the URL', () => {
    expect(searchQueryParams({ q: 'docker', type: 'articles' })).toEqual({ q: 'docker', type: null, field: null, lang: null, time: null });
    expect(searchQueryParams({ q: 'mona', type: 'users', lang: 'en', time: 'short' })).toEqual({ q: 'mona', type: 'users', field: null, lang: 'en', time: 'short' });
    expect(searchQueryParams({ q: null, type: 'tags' })).toEqual({ q: null, type: 'tags', field: null, lang: null, time: null });
  });

  it('a field opens its page; a topic opens it with ?topic=', () => {
    expect(topicRoute({ fieldSlug: 'software', topicSlug: null })).toEqual({ commands: ['/f', 'software'], queryParams: {} });
    expect(topicRoute({ fieldSlug: 'software', topicSlug: 'dotnet' })).toEqual({ commands: ['/f', 'software'], queryParams: { topic: 'dotnet' } });
  });
});
