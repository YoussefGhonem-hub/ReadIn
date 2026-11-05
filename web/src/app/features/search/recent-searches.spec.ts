import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { MAX_RECENT_SEARCHES, RecentSearches } from './recent-searches';

const KEY = 'readin.recentSearches';

function create(platform: 'browser' | 'server' = 'browser'): RecentSearches {
  TestBed.resetTestingModule();
  TestBed.configureTestingModule({ providers: [{ provide: PLATFORM_ID, useValue: platform }] });
  return TestBed.inject(RecentSearches);
}

describe('RecentSearches (F16)', () => {
  afterEach(() => localStorage.removeItem(KEY));

  it('keeps the last 10 on the device, newest first', () => {
    const recent = create();
    for (let i = 1; i <= 12; i++) recent.add(`query ${i}`);
    expect(recent.items()).toHaveLength(MAX_RECENT_SEARCHES);
    expect(recent.items()[0]).toBe('query 12');
    expect(recent.items().at(-1)).toBe('query 3');
    expect(JSON.parse(localStorage.getItem(KEY)!)).toEqual(recent.items());
    // Another visit reads them back.
    expect(create().items()).toEqual(recent.items());
  });

  it('one entry per query: searching again moves it to the top, in its newest spelling', () => {
    const recent = create();
    recent.add('Docker');
    recent.add('مكتبة');
    recent.add('  docker ');
    recent.add('مكتبه');
    expect(recent.items()).toEqual(['مكتبه', 'docker']);
  });

  it('cleans what it keeps and ignores what the API would refuse', () => {
    const recent = create();
    recent.add('  #C#  ');
    recent.add('@mona');
    recent.add('!!');
    recent.add('   ');
    expect(recent.items()).toEqual(['mona', 'C#']);
  });

  it('removes one, or all', () => {
    const recent = create();
    recent.add('a');
    recent.add('b');
    recent.add('c');
    recent.remove('B');
    expect(recent.items()).toEqual(['c', 'a']);
    recent.clear();
    expect(recent.items()).toEqual([]);
    expect(localStorage.getItem(KEY)).toBeNull();
  });

  it('ignores a broken or tampered store', () => {
    localStorage.setItem(KEY, '{not json');
    expect(create().items()).toEqual([]);
    localStorage.setItem(KEY, JSON.stringify(['ok', 42, 'OK', '!!', 'two']));
    expect(create().items()).toEqual(['ok', 'two']);
  });

  it('has none on the server, and writes nothing there', () => {
    localStorage.setItem(KEY, JSON.stringify(['kept']));
    const recent = create('server');
    expect(recent.items()).toEqual([]);
    recent.add('docker');
    expect(recent.items()).toEqual(['docker']);
    expect(JSON.parse(localStorage.getItem(KEY)!)).toEqual(['kept']);
  });
});
