import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto } from '../api/models';
import { LiveArticleCounts, RealtimeService } from '../realtime/realtime.service';
import { ArticleSocialStore } from './article-social.store';
import { bindLiveCounters } from './live-article';

describe('bindLiveCounters (F27)', () => {
  const watchers = new Map<string, (counts: LiveArticleCounts) => void>();
  const stopped: string[] = [];

  beforeEach(() => {
    watchers.clear();
    stopped.length = 0;
    TestBed.resetTestingModule();
    setupSocialTesting({
      providers: [
        {
          provide: RealtimeService,
          useValue: {
            watchArticle: (id: string, next: (counts: LiveArticleCounts) => void) => {
              watchers.set(id, next);
              return () => {
                watchers.delete(id);
                stopped.push(id);
              };
            },
          },
        },
      ],
    });
  });

  it('feeds live counters into the store only while active', () => {
    const article = signal<ArticleCardDto | null>(testCard());
    const visible = signal(false);
    TestBed.runInInjectionContext(() => bindLiveCounters(article, visible));
    const store = TestBed.inject(ArticleSocialStore);
    TestBed.tick();
    expect(watchers.size).toBe(0); // e.g. a card off screen

    visible.set(true);
    TestBed.tick();
    watchers.get('a1')!({ reactions: { insightful: 9, love: 3, fire: 2, mindBlown: 1 }, reactionCount: 15, commentCount: 4, saveCount: null });
    expect(store.state(testCard())).toEqual(expect.objectContaining({ reactionCount: 15, commentCount: 4, saveCount: 4 }));

    visible.set(false);
    TestBed.tick();
    expect(stopped).toEqual(['a1']);
    expect(store.state(testCard()).reactionCount).toBe(15); // the last values stay
  });

  it('follows the article id and stops on a new one', () => {
    const article = signal<ArticleCardDto | null>(testCard());
    TestBed.runInInjectionContext(() => bindLiveCounters(article));
    TestBed.tick();
    article.set(testCard({ id: 'a2' }));
    TestBed.tick();
    expect(stopped).toEqual(['a1']);
    expect([...watchers.keys()]).toEqual(['a2']);

    article.set(testCard({ id: 'a2', commentCount: 7 })); // a refreshed copy of the same article
    TestBed.tick();
    expect(stopped).toEqual(['a1']);
  });
});
