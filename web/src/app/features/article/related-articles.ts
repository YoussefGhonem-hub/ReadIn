import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, afterNextRender, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { HttpContext, httpResource } from '@angular/common/http';
import { TranslocoPipe } from '@jsverse/transloco';
import { SILENT_ERRORS, WITH_SESSION } from '../../core/api/api.config';
import { ContentApi } from '../../core/api/content.api';
import { ArticleCardDto, ArticleLanguage } from '../../core/api/models';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { MUTE_SCOPE, MuteStore } from '../../core/social/mute.store';
import { PostCard } from '../feed/post-card';

/** Cards at the end of the reader (F04). */
export const RELATED_LIMIT = 4;

export interface RelatedArticlesRef {
  id: string;
  language: ArticleLanguage;
}

/**
 * "Related articles" at the end of the reader (F04): up to four post cards (F34) from `GET /articles/{id}/related` for
 * the version being read, with reactions, comments, saves and live counts like every feed card. Browser only and lazy: the request goes out
 * when the section nears the viewport, and again for another article or version. Nothing shows while it loads, when
 * there are no related articles or when the request fails, nor once every card was muted away (F28: Undo brings the
 * section back).
 */
@Component({
  selector: 'rd-related-articles',
  imports: [TranslocoPipe, PostCard],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <!-- One card: the title row, then the post cards as its rows (their own frame, rounding, shadow and phone bleed give
         way to a line between rows; the last one keeps the card's bottom corners) -->
    @if (anyShown()) {
      <section
        class="rd-card mt-2 p-0 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0"
        aria-labelledby="related-title"
        data-related
      >
        <h2 id="related-title" class="m-0 px-4 py-3 text-lg font-semibold lg:px-5 lg:py-4">{{ 'article.related' | transloco }}</h2>
        <div
          class="flex flex-col [&>rd-post-card]:mx-0 [&>rd-post-card]:rounded-none [&>rd-post-card]:border-x-0 [&>rd-post-card]:border-b-0 [&>rd-post-card]:shadow-none sm:[&>rd-post-card:last-child]:rounded-b-card"
        >
          @for (card of cards(); track card.id) {
            <rd-post-card [article]="card" />
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
  private readonly mutes = inject(MuteStore);
  private readonly muteScope = inject(MUTE_SCOPE);
  /** A card is still shown: the section (with its heading) goes once all were muted away (F28). */
  protected readonly anyShown = computed(() => this.mutes.anyShown(this.cards(), this.muteScope));

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
