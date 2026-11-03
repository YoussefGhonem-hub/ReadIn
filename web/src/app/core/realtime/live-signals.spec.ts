import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { injectLiveCounts, injectNewArticles } from './live-signals';
import { LiveArticleCounts, RealtimeService } from './realtime.service';

const counts = (commentCount: number): LiveArticleCounts => ({ reactions: null, reactionCount: null, commentCount, saveCount: null });

describe('live signals', () => {
  let latest: ((publishedAt: number | null) => void) | null;
  const watchers = new Map<string, (value: LiveArticleCounts) => void>();
  const stops: string[] = [];

  beforeEach(() => {
    latest = null;
    watchers.clear();
    stops.length = 0;
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      providers: [
        {
          provide: RealtimeService,
          useValue: {
            watchLatestPublished: (next: (publishedAt: number | null) => void) => {
              latest = next;
              return () => (latest = null);
            },
            watchArticle: (id: string, next: (value: LiveArticleCounts) => void) => {
              watchers.set(id, next);
              return () => {
                watchers.delete(id);
                stops.push(id);
              };
            },
          },
        },
      ],
    });
  });

  describe('injectNewArticles', () => {
    it('treats the first value as what the feed already has', () => {
      const banner = TestBed.runInInjectionContext(() => injectNewArticles());
      latest!(1000);
      expect(banner.available()).toBe(false);

      latest!(2000);
      expect(banner.available()).toBe(true);

      banner.acknowledge();
      expect(banner.available()).toBe(false);
    });

    it('shows the banner for the very first article when nothing was published before', () => {
      const banner = TestBed.runInInjectionContext(() => injectNewArticles());
      latest!(null);
      latest!(5000);
      expect(banner.available()).toBe(true);
    });
  });

  describe('injectLiveCounts', () => {
    it('pauses without losing the last values and resets for another article', () => {
      const id = signal<string | null>('a1');
      const live = TestBed.runInInjectionContext(() => injectLiveCounts(id));
      TestBed.tick();
      watchers.get('a1')!(counts(3));
      expect(live()?.commentCount).toBe(3);

      id.set(null); // e.g. the card scrolled out of view
      TestBed.tick();
      expect(stops).toEqual(['a1']);
      expect(live()?.commentCount).toBe(3);

      id.set('a2');
      TestBed.tick();
      expect(live()).toBeNull();
      watchers.get('a2')!(counts(9));
      expect(live()?.commentCount).toBe(9);
    });
  });
});
