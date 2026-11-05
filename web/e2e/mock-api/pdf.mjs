/**
 * Download article PDF (F33) for the mock API: `GET /articles/{id}/pdf?lang=` answers your own published article as a
 * tiny one-page PDF named `{slug}-{lang}.pdf` (RFC 5987 `filename*`, `readin-article.pdf` fallback), with the API's
 * headers. "Your own": an article you published in the editor (editor.mjs), or a reader fixture whose author you are.
 * A `lang` the article isn't published in prints the source language, like the API. Anyone else's article, a draft or
 * an unknown id is `404 article.not_found`; no token is `401`. Busy, limit, hidden and failed answers are tested with
 * `page.route` (e2e/article-pdf.e2e.ts), so this server stays stateless for them.
 */

const API = '/api/v1';

/**
 * @param {{ problem: Function, viewerOf: (req: any) => string | null, editor: { publishedOf: (viewer: string) => any[] },
 *   articles: () => any[], pdf: Buffer }} deps `articles`: the reader fixtures (`ArticleDetailsDto`s).
 */
export function createPdf({ problem, viewerOf, editor, articles, pdf }) {
  /** The viewer's published article with that id, as readers get it (source language), or null. */
  function ownArticle(viewer, id) {
    return editor.publishedOf(viewer).find((a) => a.id === id) ?? articles().find((a) => a.id === id && a.author?.id === viewer) ?? null;
  }

  const routes = [
    [
      'GET',
      new RegExp(`^${API}/articles/([^/]+)/pdf$`),
      (q, [, id], _body, req) => {
        const viewer = viewerOf(req);
        if (!viewer) return [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
        const article = ownArticle(viewer, decodeURIComponent(id));
        if (!article) return [404, problem(404, 'article.not_found', 'Article not found')];
        const languages = article.availableLanguages ?? [article.language];
        const lang = languages.includes(q.get('lang')) ? q.get('lang') : article.language;
        const name = `${article.slug}-${lang}.pdf`;
        return [
          200,
          pdf,
          {
            'content-type': 'application/pdf',
            'content-length': String(pdf.length),
            'content-disposition': `attachment; filename="readin-article.pdf"; filename*=UTF-8''${encodeURIComponent(name)}`,
            'cache-control': 'private, no-store',
            'x-content-type-options': 'nosniff',
          },
        ];
      },
    ],
  ];

  return { routes };
}
