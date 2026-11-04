import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, afterNextRender, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { HttpContext, httpResource } from '@angular/common/http';
import { TranslocoPipe } from '@jsverse/transloco';
import { SILENT_ERRORS, WITH_SESSION } from '../../core/api/api.config';
import { ContentApi } from '../../core/api/content.api';
import { ArticleCardDto, ArticleLanguage } from '../../core/api/models';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { ArticleCard } from '../../shared/ui/article-card';

/** Cards at the end of the reader (F04). */
export const RELATED_LIMIT = 4;

export interface RelatedArticlesRef {
  id: string;
  language: ArticleLanguage;
}

/**
 * "Related articles" at the end of the reader (F04): up to four feed cards from `GET /articles/{id}/related` for the
 * version being read, with saves and live counts like every feed card. Browser only and lazy: the request goes out
 * when the section nears the viewport, and again for another article or version. Nothing shows while it loads, when
 * there are no related articles or when the request fails.
 */
@Component({
  selector: 'rd-related-articles',
  imports: [TranslocoPipe, ArticleCard],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @if (cards().length) {
      <section class="mt-10" aria-labelledby="related-title" data-related>
        <h2 id="related-title" class="m-0 text-lg font-semibold">{{ 'article.related' | transloco }}</h2>
        <div class="mt-1">
          @for (card of cards(); track card.id) {
            <rd-article-card [article]="card" [showAttachments]="false" />
          }
        </div>
      </section>
    }
  `,
})
export class RelatedArticles {
  private readonly content = inject(ContentApi);

  readonly article = input.required<RelatedArticlesRef>();

  /** The article and version asked about; a fresh copy of the same one (e.g. personalized) asks nothing new. */
  private readonly target = computed(() => ({ id: this.article().id, language: this.article().language }), {
    equal: (a, b) => a.id === b.id && a.language === b.language,
  });
  /** Latched once the section nears the viewport (never during SSR). */
  private readonly near = signal(false);
  private readonly resource = httpResource<ArticleCardDto[]>(() => {
    if (!this.near()) return undefined;
    const { id, language } = this.target();
    // Never made during SSR, so never in its transfer cache: it carries your token (your own articles are left out).
    return { url: this.content.relatedUrl(id, language, RELATED_LIMIT), context: new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true) };
  });
  protected readonly cards = computed(() => (this.resource.hasValue() ? this.resource.value().slice(0, RELATED_LIMIT) : []));

  constructor() {
    const host = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;
    const destroyRef = inject(DestroyRef);
    afterNextRender(() => {
      if (typeof IntersectionObserver === 'undefined') return;
      const observer = new IntersectionObserver(
        (entries) => {
          if (!entries.some((e) => e.isIntersecting)) return;
          this.near.set(true);
          observer.disconnect();
        },
        { rootMargin: '600px 0px' },
      );
      observer.observe(host);
      destroyRef.onDestroy(() => observer.disconnect());
    });

    // The cards' reactions and saves are the truth for those articles, like a feed page's (F10, F13).
    const social = inject(ArticleSocialStore);
    effect(() => {
      const cards = this.cards();
      if (cards.length) untracked(() => social.absorb(cards));
    });
  }
}
