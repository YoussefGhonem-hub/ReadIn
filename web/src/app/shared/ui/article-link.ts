import { ArticleLanguage } from '../../core/api/models';

/** SEO URL of an article version: `/ar/a/{slug}` for `ar-EG`, `/en/a/{slug}` for `en` (SPEC §23). */
export function articleLink(article: { slug: string; language: ArticleLanguage }): string[] {
  return ['/', urlLangFor(article.language), 'a', article.slug];
}

export function urlLangFor(language: ArticleLanguage): 'ar' | 'en' {
  return language === 'en' ? 'en' : 'ar';
}

export function articleLanguageForUrl(urlLang: string): ArticleLanguage {
  return urlLang === 'en' ? 'en' : 'ar-EG';
}
