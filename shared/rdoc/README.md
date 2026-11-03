# RDoc — ReadIn Document Format

The canonical JSON format for article content, shared by the backend (validation), web (Tiptap) and mobile (AppFlowy editor).

- `rdoc.schema.json` — JSON Schema (draft 2020-12). Unknown block types and attributes are rejected. The backend embeds this file at build time, so it is the single contract.
- `examples/kitchen-sink.ar-EG.json` — every block type, mark and inline node with tricky mixed Arabic/English text. Rendered by the backend, web and mobile tests.
- `../bidi/fixtures.json` — mixed-direction strings with their expected base direction and Arabic search normalization.

Server-side processing on every save: sanitize (strip bidi override/isolate controls), validate, allow-list embeds, extract plain/search text, headings, terms and code languages, and compute reading time. See [ADR 0002](../../docs/adr/0002-rdoc-content-format.md).

See [SPEC §13](../../docs/SPEC.md#13-article-content-format-rdoc).
