import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import type { HighlighterCore } from 'shiki/core';

type LangLoader = () => Promise<unknown>;

/** Grammars are code-split and loaded on first use. */
const LANGS: Record<string, LangLoader> = {
  csharp: () => import('shiki/langs/csharp.mjs'),
  typescript: () => import('shiki/langs/typescript.mjs'),
  tsx: () => import('shiki/langs/tsx.mjs'),
  javascript: () => import('shiki/langs/javascript.mjs'),
  jsx: () => import('shiki/langs/jsx.mjs'),
  dart: () => import('shiki/langs/dart.mjs'),
  json: () => import('shiki/langs/json.mjs'),
  bash: () => import('shiki/langs/bash.mjs'),
  powershell: () => import('shiki/langs/powershell.mjs'),
  sql: () => import('shiki/langs/sql.mjs'),
  html: () => import('shiki/langs/html.mjs'),
  css: () => import('shiki/langs/css.mjs'),
  scss: () => import('shiki/langs/scss.mjs'),
  yaml: () => import('shiki/langs/yaml.mjs'),
  python: () => import('shiki/langs/python.mjs'),
  kotlin: () => import('shiki/langs/kotlin.mjs'),
  swift: () => import('shiki/langs/swift.mjs'),
  xml: () => import('shiki/langs/xml.mjs'),
  dockerfile: () => import('shiki/langs/dockerfile.mjs'),
  java: () => import('shiki/langs/java.mjs'),
  go: () => import('shiki/langs/go.mjs'),
  rust: () => import('shiki/langs/rust.mjs'),
  markdown: () => import('shiki/langs/markdown.mjs'),
  razor: () => import('shiki/langs/razor.mjs'),
};

const ALIASES: Record<string, string> = {
  cs: 'csharp',
  'c#': 'csharp',
  ts: 'typescript',
  js: 'javascript',
  sh: 'bash',
  shell: 'bash',
  zsh: 'bash',
  ps1: 'powershell',
  yml: 'yaml',
  py: 'python',
  kt: 'kotlin',
  md: 'markdown',
  docker: 'dockerfile',
};

/**
 * Code blocks sit on `color.code.bg`, which is dark in both app themes (SPEC §15.2), so both Shiki themes are dark
 * variants: the "light" one is tuned for the light app theme's code background, the "dark" one for the dark theme.
 */
const THEMES = { light: 'github-dark', dark: 'github-dark-default' } as const;

/** Shiki syntax highlighting — browser only, lazy-loaded; the server renders plain `<pre>` (SPEC §3.2, §15.5 rule 6). */
@Injectable({ providedIn: 'root' })
export class HighlighterService {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private highlighter: Promise<HighlighterCore> | null = null;
  private readonly loadedLangs = new Map<string, Promise<boolean>>();

  /** Returns highlighted HTML (one `<span class="line">` per line), or null when unsupported / on the server. */
  async highlight(code: string, lang: string, highlightLines: readonly number[] = []): Promise<string | null> {
    if (!this.isBrowser) return null;
    const id = ALIASES[lang.toLowerCase()] ?? lang.toLowerCase();
    if (!LANGS[id]) return null;
    try {
      const highlighter = await this.getHighlighter();
      if (!(await this.ensureLang(highlighter, id))) return null;
      const marked = new Set(highlightLines);
      const html = highlighter.codeToHtml(code, {
        lang: id,
        themes: THEMES,
        defaultColor: false,
        transformers: [
          {
            line(node, line) {
              if (marked.has(line)) this.addClassToHast(node, 'highlighted');
            },
          },
        ],
      });
      // Lines are display:block; drop the newline text nodes between them so they don't render as blank lines.
      return html.replace(/<\/span>\n<span class="line/g, '</span><span class="line');
    } catch {
      return null;
    }
  }

  private getHighlighter(): Promise<HighlighterCore> {
    this.highlighter ??= (async () => {
      const [{ createHighlighterCore }, { createJavaScriptRegexEngine }] = await Promise.all([
        import('shiki/core'),
        import('shiki/engine/javascript'),
      ]);
      return createHighlighterCore({
        themes: [import('shiki/themes/github-dark.mjs'), import('shiki/themes/github-dark-default.mjs')],
        langs: [],
        engine: createJavaScriptRegexEngine(),
      });
    })();
    return this.highlighter;
  }

  private ensureLang(highlighter: HighlighterCore, id: string): Promise<boolean> {
    let loaded = this.loadedLangs.get(id);
    if (!loaded) {
      loaded = LANGS[id]()
        .then((mod) => highlighter.loadLanguage((mod as { default: Parameters<HighlighterCore['loadLanguage']>[0] }).default))
        .then(() => true)
        .catch(() => false);
      this.loadedLangs.set(id, loaded);
    }
    return loaded;
  }
}
