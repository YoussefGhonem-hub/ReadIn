import { DOCUMENT, Injectable, inject } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';
import { TranslocoService } from '@jsverse/transloco';
import { environment } from '../../../environments/environment';
import { WriterCategoryPageDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { translatePlural } from '../../shared/pipes/intl';
import { categoryPath } from './category-rules';

const MARK = 'data-rd-category-seo';
const META: readonly ['name' | 'property', string][] = [
  ['name', 'description'],
  ['name', 'robots'],
  ['property', 'og:type'],
  ['property', 'og:site_name'],
  ['property', 'og:title'],
  ['property', 'og:description'],
  ['property', 'og:url'],
  ['name', 'twitter:card'],
  ['name', 'twitter:title'],
  ['name', 'twitter:description'],
];

/** Public URL of a category page (`/@{username}/c/{slug}`). */
export function categoryPageUrl(username: string, slug: string): string {
  return `${environment.siteUrl}${categoryPath(username, slug)}`;
}

/**
 * Category page SEO (F31, SPEC §23): title "{name} · {writer} — ReadIn", description, canonical and Open Graph,
 * rendered on the server for crawlers. An empty category and a missing one are `noindex`.
 */
@Injectable({ providedIn: 'root' })
export class CategorySeoService {
  private readonly document = inject(DOCUMENT);
  private readonly title = inject(Title);
  private readonly meta = inject(Meta);
  private readonly transloco = inject(TranslocoService);
  private readonly language = inject(LanguageService);

  /** `name`: the category's name, or "مقالات تانية" for the uncategorized list. */
  category(category: WriterCategoryPageDto, name: string): void {
    const writer = category.author.displayName;
    const heading = `${name} · ${writer}`;
    const description = category.articleCount
      ? this.transloco.translate('categories.page.metaDescription', {
          name,
          writer,
          articles: translatePlural(this.transloco, 'reading.articles', category.articleCount, this.language.lang()),
        })
      : this.transloco.translate('categories.page.metaDescriptionEmpty', { name, writer });
    const url = categoryPageUrl(category.author.username, category.slug);
    this.clear();
    this.title.setTitle(`${heading} — ReadIn`);
    this.setMeta('name', 'description', description);
    if (!category.articleCount) this.setMeta('name', 'robots', 'noindex');
    this.setMeta('property', 'og:type', 'website');
    this.setMeta('property', 'og:site_name', 'ReadIn');
    this.setMeta('property', 'og:title', heading);
    this.setMeta('property', 'og:description', description);
    this.setMeta('property', 'og:url', url);
    this.setMeta('name', 'twitter:card', 'summary');
    this.setMeta('name', 'twitter:title', heading);
    this.setMeta('name', 'twitter:description', description);
    const canonical = this.document.createElement('link');
    canonical.setAttribute('rel', 'canonical');
    canonical.setAttribute('href', url);
    canonical.setAttribute(MARK, '');
    this.document.head.appendChild(canonical);
  }

  notFound(): void {
    this.clear();
    this.title.setTitle(`${this.transloco.translate('categories.page.notFoundTitle')} — ReadIn`);
    this.setMeta('name', 'robots', 'noindex');
  }

  clear(): void {
    this.document.head.querySelectorAll(`[${MARK}]`).forEach((el) => el.remove());
    for (const [attr, key] of META) this.meta.removeTag(`${attr}="${key}"`);
  }

  private setMeta(attr: 'name' | 'property', key: string, content: string): void {
    this.meta.updateTag({ [attr]: key, content }, `${attr}="${key}"`);
  }
}
