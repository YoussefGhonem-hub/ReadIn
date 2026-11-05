import { DOCUMENT, Injectable, inject } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';
import { TranslocoService } from '@jsverse/transloco';
import { environment } from '../../../environments/environment';
import { FieldPageDto, FieldPageTopicDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { translatePlural } from '../../shared/pipes/intl';

const MARK = 'data-rd-field-seo';
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

/** Public URL of a field page (`/f/{slug}`), or of one of its topics (`/f/{slug}?topic={topic}`). */
export function fieldPageUrl(slug: string, topic: string | null = null): string {
  const url = `${environment.siteUrl}/f/${encodeURIComponent(slug)}`;
  return topic ? `${url}?topic=${encodeURIComponent(topic)}` : url;
}

/**
 * Field page SEO (F15, SPEC §23): title "Field — ReadIn" (a topic: "Topic · Field — ReadIn"), description, canonical
 * and Open Graph, rendered on the server for crawlers. An empty field or topic, a missing field and a topic the field
 * doesn't have are `noindex`.
 */
@Injectable({ providedIn: 'root' })
export class FieldSeoService {
  private readonly document = inject(DOCUMENT);
  private readonly title = inject(Title);
  private readonly meta = inject(Meta);
  private readonly transloco = inject(TranslocoService);
  private readonly language = inject(LanguageService);

  field(field: FieldPageDto, topic: FieldPageTopicDto | null): void {
    const lang = this.language.lang();
    const fieldName = lang === 'ar' ? field.nameAr : field.nameEn;
    const name = topic ? (lang === 'ar' ? topic.nameAr : topic.nameEn) : fieldName;
    const title = topic ? `${name} · ${fieldName}` : name;
    const count = topic ? topic.articleCount : field.articleCount;
    const description = count
      ? this.transloco.translate('fields.page.metaDescription', { name, articles: translatePlural(this.transloco, 'reading.articles', count, lang) })
      : this.transloco.translate('fields.page.metaDescriptionEmpty', { name });
    const url = fieldPageUrl(field.slug, topic?.slug ?? null);
    this.clear();
    this.title.setTitle(`${title} — ReadIn`);
    this.setMeta('name', 'description', description);
    if (!count) this.setMeta('name', 'robots', 'noindex');
    this.setMeta('property', 'og:type', 'website');
    this.setMeta('property', 'og:site_name', 'ReadIn');
    this.setMeta('property', 'og:title', title);
    this.setMeta('property', 'og:description', description);
    this.setMeta('property', 'og:url', url);
    this.setMeta('name', 'twitter:card', 'summary');
    this.setMeta('name', 'twitter:title', title);
    this.setMeta('name', 'twitter:description', description);
    const canonical = this.document.createElement('link');
    canonical.setAttribute('rel', 'canonical');
    canonical.setAttribute('href', url);
    canonical.setAttribute(MARK, '');
    this.document.head.appendChild(canonical);
  }

  /** A missing field, or (`field` given) a topic it doesn't have. */
  notFound(field: FieldPageDto | null = null): void {
    this.clear();
    const name = field ? (this.language.lang() === 'ar' ? field.nameAr : field.nameEn) : null;
    const title = name ? this.transloco.translate('fields.page.topicNotFoundTitle') : this.transloco.translate('fields.page.notFoundTitle');
    this.title.setTitle(`${name ? `${title} · ${name}` : title} — ReadIn`);
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
