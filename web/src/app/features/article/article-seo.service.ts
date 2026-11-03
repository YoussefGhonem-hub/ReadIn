import { DOCUMENT, Injectable, inject } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';
import { environment } from '../../../environments/environment';
import { ArticleDetailsDto, ArticleLanguage } from '../../core/api/models';
import { inlineText } from '../../shared/rdoc/rdoc.utils';
import { urlLangFor } from '../../shared/ui/article-link';

const MARK = 'data-rd-seo';
const OG_LOCALE: Record<ArticleLanguage, string> = { 'ar-EG': 'ar_EG', en: 'en_US' };
const HREFLANG: Record<ArticleLanguage, string> = { 'ar-EG': 'ar', en: 'en' };

/**
 * Article SEO (SPEC §23): title, description, canonical, hreflang alternates, Open Graph / Twitter cards and
 * schema.org Article JSON-LD. Rendered on the server for crawlers.
 */
@Injectable({ providedIn: 'root' })
export class ArticleSeoService {
  private readonly document = inject(DOCUMENT);
  private readonly title = inject(Title);
  private readonly meta = inject(Meta);

  apply(article: ArticleDetailsDto): void {
    this.clear();
    const url = this.articleUrl(article.slug, article.language);
    const description = this.description(article);

    this.title.setTitle(`${article.title} — ReadIn`);
    this.setMeta('name', 'description', description);
    this.setMeta('property', 'og:type', 'article');
    this.setMeta('property', 'og:site_name', 'ReadIn');
    this.setMeta('property', 'og:title', article.title);
    this.setMeta('property', 'og:description', description);
    this.setMeta('property', 'og:url', url);
    this.setMeta('property', 'og:locale', OG_LOCALE[article.language]);
    this.setMeta('property', 'article:published_time', article.publishedAt);
    if (article.lastReviewedAt) this.setMeta('property', 'article:modified_time', article.lastReviewedAt);
    if (article.coverUrl) this.setMeta('property', 'og:image', article.coverUrl);
    this.setMeta('name', 'twitter:card', article.coverUrl ? 'summary_large_image' : 'summary');
    this.setMeta('name', 'twitter:title', article.title);
    this.setMeta('name', 'twitter:description', description);

    this.addLink({ rel: 'canonical', href: url });
    const languages = article.availableLanguages.length ? article.availableLanguages : [article.language];
    for (const lang of languages) {
      this.addLink({ rel: 'alternate', hreflang: HREFLANG[lang], href: this.articleUrl(article.slug, lang) });
    }
    this.addLink({ rel: 'alternate', hreflang: 'x-default', href: this.articleUrl(article.slug, languages[0]) });

    this.addJsonLd(this.structuredData(article, url, description));
  }

  clear(): void {
    this.document.head.querySelectorAll(`[${MARK}]`).forEach((el) => el.remove());
    for (const selector of [
      'name="description"',
      'property="og:type"',
      'property="og:site_name"',
      'property="og:title"',
      'property="og:description"',
      'property="og:url"',
      'property="og:locale"',
      'property="og:image"',
      'property="article:published_time"',
      'property="article:modified_time"',
      'name="twitter:card"',
      'name="twitter:title"',
      'name="twitter:description"',
    ]) {
      this.meta.removeTag(selector);
    }
  }

  articleUrl(slug: string, language: ArticleLanguage): string {
    return `${environment.siteUrl}/${urlLangFor(language)}/a/${encodeURIComponent(slug)}`;
  }

  private description(article: ArticleDetailsDto): string {
    const firstParagraph = article.content?.blocks.find((b) => b.type === 'paragraph');
    const text = article.subtitle || article.summary || (firstParagraph?.type === 'paragraph' ? inlineText(firstParagraph.content, { includeCode: true }) : '');
    const clean = text.replace(/\s+/g, ' ').trim();
    return clean.length > 160 ? `${clean.slice(0, 157)}…` : clean;
  }

  private structuredData(article: ArticleDetailsDto, url: string, description: string): Record<string, unknown> {
    const { author } = article;
    return {
      '@context': 'https://schema.org',
      '@type': 'Article',
      headline: article.title,
      description,
      inLanguage: article.language,
      url,
      datePublished: article.publishedAt,
      dateModified: article.lastReviewedAt ?? article.publishedAt,
      ...(article.coverUrl ? { image: [article.coverUrl] } : {}),
      // A deleted account's articles stay up without an author (SPEC §9.6): nothing may point back to the person.
      ...(author ? { author: { '@type': 'Person', name: author.displayName, url: `${environment.siteUrl}/@${author.username}` } } : {}),
      publisher: { '@type': 'Organization', name: 'ReadIn', url: environment.siteUrl },
      keywords: article.tags.join(', '),
      isAccessibleForFree: true,
      mainEntityOfPage: {
        '@type': 'WebPage',
        '@id': url,
        ...(article.lastReviewedAt ? { lastReviewed: article.lastReviewedAt } : {}),
        ...(article.reviewedBy
          ? { reviewedBy: { '@type': 'Person', name: article.reviewedBy.displayName, url: `${environment.siteUrl}/@${article.reviewedBy.username}` } }
          : {}),
      },
    };
  }

  private setMeta(attr: 'name' | 'property', key: string, content: string): void {
    this.meta.updateTag({ [attr]: key, content }, `${attr}="${key}"`);
  }

  private addLink(attrs: Record<string, string>): void {
    const link = this.document.createElement('link');
    for (const [k, v] of Object.entries(attrs)) link.setAttribute(k, v);
    link.setAttribute(MARK, '');
    this.document.head.appendChild(link);
  }

  private addJsonLd(data: Record<string, unknown>): void {
    const script = this.document.createElement('script');
    script.setAttribute('type', 'application/ld+json');
    script.setAttribute(MARK, '');
    // Escape `<` so content can never close the script element.
    script.textContent = JSON.stringify(data).replace(/</g, '\\u003c');
    this.document.head.appendChild(script);
  }
}
