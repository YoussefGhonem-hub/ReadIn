# 0019 — Quote cards are drawn by the server, from a checked F30 range

- **Status:** Accepted
- **Date:** 2026-11-06
- **Relates to:** SPEC F24 (quote card), F30 (selection offsets), F33 (headless Chromium), §14 (BiDi), §15 (tokens),
  §24 (security, rate limits); contract-v1 "Quote card (F24)".

## Context

F24 lets a reader select text in an article and share it as an image for social media, in light or dark. The image
carries the ReadIn logo, the article's title and its writer's name, so it speaks for ReadIn and for the writer. Three
things are hard:

1. **Arabic and mixed text.** Letters must join, and English words, numbers and punctuation inside Arabic must sit in the
   right place (§14.2). Two client renderers (Angular canvas, Flutter) would each have to prove that, and would still
   give two different images.
2. **Trust.** A card made on the device can show any words under any article's title. A screenshot can too, but a card
   that ReadIn makes should only ever show what the article says.
3. **Fit.** A quote can be 3 or 400 characters long, with line breaks, emoji and long English words, in two formats;
   it must never overflow or be cut.

The API already runs headless Chromium for article PDFs (SPEC F33 "How it's built"): one sandboxed
browser per instance, JavaScript off, every request blocked, the fonts and logo inlined, at most 2 builds at a time.

## Decision

- **The server draws the card** with the F33 Chromium: `POST /articles/{id}/quote-card` with the F30 range
  `{ language, blockId, startOffset, endOffset, text }`, a `theme` (light, dark) and a `format` (square 1080 × 1080,
  landscape 1200 × 630) answers a PNG. Web and mobile only show it, share it and save it.
- **The range is checked like a highlight.** The handler reuses F30's `RDocBlockText` / `HighlightRanges` on the
  version's current text (the shared, cached version): the block must be one a highlight may use, `text` must be exactly
  the text at the offsets, and the trimmed range must be 3–400 UTF-16 code units. The card shows that trimmed text and
  nothing else the client sends; the title, the writer and the link come from the database.
- **Visibility is the reader's.** Anyone who can open the article may make a card, guests included; a hidden article
  makes none (`409 quote.hidden` for its author and moderators, 404 for others), because the card carries the logo.
- **Fit without page JavaScript.** The page has no script and a CSP that allows none. The renderer waits for
  `document.fonts.ready` through the DevTools protocol (as PuppeteerSharp does before printing a PDF; the page's own
  scripts stay off), then measures the quote through the DevTools protocol's DOM domain (`DOM.setAttributeValue` + `DOM.getBoxModel`): it tries font sizes from the
  largest down to a readable minimum and keeps the largest that fits its box; if none fits it tries again with the line
  breaks as spaces, then below the readable minimum (only text nobody selects to share needs that, such as 400 wide
  letters without a space), and only then refuses (`quote.too_long`, which the 400 limit makes unreachable in
  practice). The title is clamped to 2 lines with CSS (1 in landscape).
- **Shared limits.** Cards and PDFs share one browser and its build slots (`ArticlePdf:MaxConcurrentBuilds`, 2), so a
  burst of cards can never start more Chromium work than PDFs alone. A card waits at most 10 s for a slot
  (`503 quote.busy`) and has 20 s to draw (`500 quote.failed`): it is a live preview, so it gives up sooner than a PDF.
  30 cards per hour per user, guests per IP (`429 quote.limit`).
- **Nothing stored.** The PNG is built in the request and streamed (`Cache-Control: private, max-age=600`); clients keep
  the images of the open sheet in memory. There is no table, no file and nothing new in §9.6.
- **The logo is the approved lockup**, unchanged: `lockup.png` on light cards, `lockup-dark.png` on dark ones, both
  copied from `docs/design/app-store/logo/` into the API's resources.

## Consequences

- One image everywhere, with Chromium's Arabic shaping and BiDi; the backend tests compare an Arabic light square card
  and an English dark landscape card with approved images (Windows and Linux each have their own, like the PDF pages).
- A card costs a Chromium page (about 0.3–1 s and some memory) instead of nothing on the device; the shared slots and
  the hourly limit bound it. A guest's card needs the network, so it doesn't work offline.
- Fonts are embedded per page as `data:` URLs, like the PDF; the emoji and symbol fonts only when the text needs them.
- If the author updates the article, an old range stops matching and the card is refused with `quote.text_mismatch`
  until the reader reloads. A card already shared is a picture: it doesn't change.
- Adding a format or theme is a CSS and a test change; the endpoint takes only the values it knows.
