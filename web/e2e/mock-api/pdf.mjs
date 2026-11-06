/**
 * Download article PDF (F33) for the mock API: `GET /articles/{id}/pdf?lang=` answers any published article a signed-in
 * member can open as a tiny one-page PDF named `{slug}-{lang}.pdf` (RFC 5987 `filename*`, `readin-article.pdf`
 * fallback), with the API's headers: an article you published in the editor (editor.mjs), or any reader fixture,
 * whoever wrote it. A `lang` the article isn't published in prints the source language, like the API. A draft, someone
 * else's editor article and an unknown id are `404 article.not_found`; no token is `401`. An article hidden by
 * moderators (F22, `hiddenFor`: moderation.mjs, as the viewer sees it) answers like the API: `409 article.pdf_hidden`
 * to its author, `404 article.not_found` to everyone else. The e2e specs fake the busy, limit, failed and hidden
 * answers with `page.route` (e2e/article-pdf.e2e.ts, e2e/article-pdf-members.e2e.ts), so this server stays stateless
 * for them.
 */

const API = '/api/v1';

/**
 * @param {{ problem: Function, viewerOf: (req: any) => string | null, editor: { publishedOf: (viewer: string) => any[] },
 *   articles: () => any[], hiddenFor?: (article: any, viewer: string) => boolean, pdf: Buffer }} deps `articles`: the
 *   reader fixtures (`ArticleDetailsDto`s); `hiddenFor`: hidden by moderators, as the viewer sees it (without it,
 *   nothing is hidden).
 */
export function createPdf({ problem, viewerOf, editor, articles, hiddenFor = () => false, pdf }) {
  /**
   * The published article with that id the viewer can open, as readers get it (source language), and whether the
   * viewer wrote it; null when there is none.
   */
  function openableArticle(viewer, id) {
    const mine = editor.publishedOf(viewer).find((a) => a.id === id);
    if (mine) return { article: mine, own: true };
    const article = articles().find((a) => a.id === id);
    return article ? { article, own: article.author?.id === viewer } : null;
  }

  const routes = [
    [
      'GET',
      new RegExp(`^${API}/articles/([^/]+)/pdf$`),
      (q, [, id], _body, req) => {
        const viewer = viewerOf(req);
        if (!viewer) return [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
        const found = openableArticle(viewer, decodeURIComponent(id));
        const notFound = [404, problem(404, 'article.not_found', 'Article not found')];
        if (!found) return notFound;
        const { article, own } = found;
        // Like the API: a hidden article is the author's only, and has no file (it carries the ReadIn logo).
        if (hiddenFor(article, viewer)) {
          return own ? [409, problem(409, 'article.pdf_hidden', "Moderators hid this article, so it can't be downloaded as a PDF.")] : notFound;
        }
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
