import { DOCUMENT, Injectable, inject } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';
import { TranslocoService } from '@jsverse/transloco';
import { environment } from '../../../environments/environment';
import { TagDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { translatePlural } from '../../shared/pipes/intl';

const MARK = 'data-rd-tag-seo';
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

/** Public URL of a tag page (`/tags/{slug}`, the slug percent-encoded: it may hold Arabic letters). */
export function tagPageUrl(slug: string): string {
  return `${environment.siteUrl}/tags/${encodeURIComponent(slug)}`;
}

/**
 * Tag page SEO (F32, SPEC §23): title "#name — ReadIn", description, canonical and Open Graph, rendered on the server
 * for crawlers. An empty tag and a missing one are `noindex`.
 */
@Injectable({ providedIn: 'root' })
export class TagSeoService {
  private readonly document = inject(DOCUMENT);
  private readonly title = inject(Title);
  private readonly meta = inject(Meta);
  private readonly transloco = inject(TranslocoService);
  private readonly language = inject(LanguageService);

  tag(tag: TagDto): void {
    const name = `#${tag.name}`;
    const description = tag.articleCount
      ? this.transloco.translate('tags.page.metaDescription', {
          name,
          articles: translatePlural(this.transloco, 'reading.articles', tag.articleCount, this.language.lang()),
        })
      : this.transloco.translate('tags.page.metaDescriptionEmpty', { name });
    this.clear();
    this.title.setTitle(`${name} — ReadIn`);
    this.setMeta('name', 'description', description);
    if (!tag.articleCount) this.setMeta('name', 'robots', 'noindex');
    this.setMeta('property', 'og:type', 'website');
    this.setMeta('property', 'og:site_name', 'ReadIn');
    this.setMeta('property', 'og:title', name);
    this.setMeta('property', 'og:description', description);
    this.setMeta('property', 'og:url', tagPageUrl(tag.slug));
    this.setMeta('name', 'twitter:card', 'summary');
    this.setMeta('name', 'twitter:title', name);
    this.setMeta('name', 'twitter:description', description);
    const canonical = this.document.createElement('link');
    canonical.setAttribute('rel', 'canonical');
    canonical.setAttribute('href', tagPageUrl(tag.slug));
    canonical.setAttribute(MARK, '');
    this.document.head.appendChild(canonical);
  }

  notFound(): void {
    this.clear();
    this.title.setTitle(`${this.transloco.translate('tags.page.notFoundTitle')} — ReadIn`);
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
