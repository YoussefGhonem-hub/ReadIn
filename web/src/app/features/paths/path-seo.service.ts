import { DOCUMENT, Injectable, inject } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';
import { TranslocoService } from '@jsverse/transloco';
import { environment } from '../../../environments/environment';
import { PathCardDto } from '../../core/api/models';
import { translatePlural } from '../../shared/pipes/intl';
import { LanguageService } from '../../core/i18n/language.service';

const MARK = 'data-rd-path-seo';
const META: readonly ['name' | 'property', string][] = [
  ['name', 'description'],
  ['property', 'og:type'],
  ['property', 'og:site_name'],
  ['property', 'og:title'],
  ['property', 'og:description'],
  ['property', 'og:url'],
  ['property', 'og:image'],
  ['name', 'twitter:card'],
  ['name', 'twitter:title'],
  ['name', 'twitter:description'],
];

/** Public URL of the paths list, or of one path (`/paths/{slug}`). */
export function pathsUrl(slug?: string): string {
  return `${environment.siteUrl}/paths${slug ? `/${encodeURIComponent(slug)}` : ''}`;
}

/** Paths SEO (SPEC §7.2, §23): title, description, canonical and Open Graph, rendered on the server for crawlers. */
@Injectable({ providedIn: 'root' })
export class PathSeoService {
  private readonly document = inject(DOCUMENT);
  private readonly title = inject(Title);
  private readonly meta = inject(Meta);
  private readonly transloco = inject(TranslocoService);
  private readonly language = inject(LanguageService);

  list(): void {
    const title = this.transloco.translate('paths.title');
    this.apply(title, this.transloco.translate('paths.sub'), pathsUrl(), null);
  }

  path(path: PathCardDto): void {
    const lang = this.language.lang();
    const fallback = this.transloco.translate('paths.detail.metaDescription', {
      articles: translatePlural(this.transloco, 'reading.articles', path.articleCount, lang),
      field: lang === 'ar' ? path.field.nameAr : path.field.nameEn,
    });
    const text = (path.description ?? '').replace(/\s+/g, ' ').trim() || fallback;
    this.apply(path.title, text.length > 160 ? `${text.slice(0, 157)}…` : text, pathsUrl(path.slug), path.coverUrl);
  }

  notFound(): void {
    this.clear();
    this.title.setTitle(`${this.transloco.translate('paths.detail.notFoundTitle')} — ReadIn`);
  }

  clear(): void {
    this.document.head.querySelectorAll(`[${MARK}]`).forEach((el) => el.remove());
    for (const [attr, key] of META) this.meta.removeTag(`${attr}="${key}"`);
  }

  private apply(title: string, description: string, url: string, image: string | null): void {
    this.clear();
    this.title.setTitle(`${title} — ReadIn`);
    this.setMeta('name', 'description', description);
    this.setMeta('property', 'og:type', 'website');
    this.setMeta('property', 'og:site_name', 'ReadIn');
    this.setMeta('property', 'og:title', title);
    this.setMeta('property', 'og:description', description);
    this.setMeta('property', 'og:url', url);
    if (image) this.setMeta('property', 'og:image', image);
    this.setMeta('name', 'twitter:card', image ? 'summary_large_image' : 'summary');
    this.setMeta('name', 'twitter:title', title);
    this.setMeta('name', 'twitter:description', description);
    const canonical = this.document.createElement('link');
    canonical.setAttribute('rel', 'canonical');
    canonical.setAttribute('href', url);
    canonical.setAttribute(MARK, '');
    this.document.head.appendChild(canonical);
  }

  private setMeta(attr: 'name' | 'property', key: string, content: string): void {
    this.meta.updateTag({ [attr]: key, content }, `${attr}="${key}"`);
  }
}
