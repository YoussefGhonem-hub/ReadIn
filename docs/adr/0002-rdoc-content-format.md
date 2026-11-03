# 0002 — RDoc: structured JSON blocks as the only article format

- **Status:** Accepted
- **Date:** 2026-11-02

## Context

Articles mix Arabic and English in one paragraph, contain code that must stay LTR, and are edited with Tiptap on web and AppFlowy Editor on mobile. Storing HTML would make BiDi rules, sanitization and cross-platform rendering fragile and is a standing XSS risk.

## Decision

- Article bodies are stored as **RDoc** JSON (`shared/rdoc/rdoc.schema.json`, JSON Schema 2020-12): 14 block types, inline nodes (`text`, `term`, `mention`, `hardBreak`) and marks. Unknown types and attributes are rejected (`additionalProperties: false`).
- The schema file is the single contract. The backend embeds it from `shared/` at build time; both clients and the content pipeline validate against the same file.
- On every save, `IRDocProcessor`:
  - strips bidi embedding/override/isolate controls (U+202A–E, U+2066–9; "Trojan Source" in code) and control characters,
  - validates against the schema and checks embeds against an allow-list (YouTube, GitHub Gist, https only),
  - extracts plain text, normalized search text, headings, terms and code languages, and computes reading time (Arabic 180 wpm, English 230 wpm, 4 s per code line).
- Stored JSON keeps Arabic unescaped (about 6× smaller than `\uXXXX`), while HTML-sensitive characters stay escaped.
- `ArticleTranslations.ContentJson` has an `ISJSON` check constraint.

## Consequences

- Renderers are plain components/widgets per block type; no HTML sanitizer on the client.
- Schema changes are versioned (`"version": 1`) and need converters in both editors.
- `shared/rdoc/examples/kitchen-sink.ar-EG.json` covers every block type and is used by backend, web and mobile tests.
