# 0011 — Media pipeline: responsive images and PDF attachments with page previews

- **Status:** Accepted
- **Date:** 2026-11-03
- **Amends:** [0010 — Uploads stored on the API server](0010-uploads-in-wwwroot.md) (size buckets, limits, layout, endpoint)

## Context

Posts and articles need LinkedIn-style attachments: a carousel of 1–10 photos, or one PDF shown as swipeable page
previews. Feed images must be light (a typical feed image ≤ 150 KB, avatars ≤ 30 KB) and must not shift the layout
while loading. ADR 0010 stored one or two WebP sizes per image and served only `.webp` from `/uploads`; it had no
record of an upload in the database, so nothing could track processing, ownership, quotas or which post an image
belongs to. PDFs can be large, slow to render and hostile (encrypted, damaged, or crafted to exhaust memory).

## Decision

**One record per upload.** Every upload is a `MediaAssets` row (owner, kind `Image | Document`, purpose, status
`Uploading | Processing | Ready | Failed`, failure reason, original path and size, upright width/height, BlurHash,
variants as JSON keyed by width, page count, title, `AllowDownload`, extracted text). PDF pages are
`MediaAssetPages` rows. `ArticleAttachments` links an article to either 1–10 images (each with required alt text
and an optional caption ≤ 120) or exactly one document; the rule lives in `Article.SetAttachments`.

**Images** (`POST /api/v1/uploads/images`, processed in the request, ≤ 10 MB):
- Accepted by magic bytes: JPEG, PNG, WebP and **HEIC**. SkiaSharp has no HEIF codec on Windows/Linux, so HEIC is
  decoded by Magick.NET (libheif + libde265), called only for HEIF magic bytes with the format forced, under
  ImageMagick resource limits, and then handed to the same Skia pipeline.
- ≤ 8000 × 8000 (from the header, before decoding), EXIF orientation applied, converted to sRGB, every metadata
  block dropped (EXIF, GPS, XMP, ICC), WebP quality 78.
- Responsive widths, never upscaled, one file per real width (`{id}_{width}.webp`):

  | Purpose | Widths |
  |---|---|
  | avatar | 64, 128, 256, 512 (square, center crop) |
  | cover | 400, 800, 1200 |
  | image (posts, RDoc image blocks) | 320, 640, 1080, 1600 |

  An image narrower than the largest bucket keeps its own width as its last variant (a 1000 px photo gets 320, 640
  and 1000), so there are never two files of the same width.
- A BlurHash (4×3 components, 3×4 for portrait) is stored for every image and every PDF page. The encoder follows
  the reference C implementation; any BlurHash decoder (web `blurhash`, mobile `flutter_blurhash`) reads it.

**Documents** (`POST /api/v1/uploads/documents`, ≤ 20 MB, ≤ 100 pages):
- The request only validates: `%PDF-` magic bytes, opened with PdfPig to reject encrypted (`media.pdf_encrypted`,
  "الملف ده عليه باسورد، ارفعه من غير باسورد") and damaged files, page count. It stores the original and returns
  `202` with status `processing`.
- A Hangfire job on a dedicated `media` queue renders the pages with PDFtoImage (PDFium + SkiaSharp): **page 1
  first** (400 px thumb + 1080 px view + BlurHash, saved immediately so the preview appears fast), then the rest,
  then the text (PdfPig, Arabic-normalized into `ExtractedText` for search). Status `Ready`, or `Failed` with a
  stable reason.
- Safety: the `media` Hangfire server has **2 workers** (`Media:MaxConcurrentDocumentJobs`), each job stops after
  **2 minutes** (`media.processing_timeout`), PDFium calls are serialized, and render sizes are capped (≤ 200 DPI,
  ≤ 1080 px wide, ≤ 4320 px tall) so a page with an absurd size can't exhaust memory.
- Clients poll `GET /uploads/{id}` every 2 s. The API also writes `{ status, pagesReady, pageCount }` to the
  Firebase Realtime Database at `/live/users/{userId}/media/{assetId}` (REST API, best effort, SPEC §21.2). The
  custom token from `POST /realtime/token` carries the ReadIn user id as `auth.uid`, and `firebase/database.rules.json`
  lets only that user read it and nobody write. Clients don't subscribe to it yet; polling is the contract.

**Storage layout** (amends ADR 0010):

```text
wwwroot/uploads/
  images/{yyyy}/{MM}/{id}_{width}.webp
  avatars/{yyyy}/{MM}/{id}_{width}.webp
  covers/{yyyy}/{MM}/{id}_{width}.webp
  documents/{yyyy}/{MM}/{id}/original.pdf
  documents/{yyyy}/{MM}/{id}/pages/{pageNo}_{400|1080}.webp
```

`{id}` is a random GUID, never the asset's database id, so page URLs of unpublished documents can't be guessed.

**Serving.** `/uploads` keeps ADR 0010's rules: `.webp` only (at any depth), `nosniff`, immutable caching, every
other file 404. **A PDF is never served from `/uploads`.** The original is only available through
`GET /api/v1/documents/{assetId}/download`: allowed when the article is published and the author turned on
`AllowDownload`, or for the owner and moderators; it answers `Content-Disposition: attachment`,
`X-Content-Type-Options: nosniff` and `Content-Security-Policy: sandbox`. DTOs carry `allowDownload` and
`canDownload`; the cached article details are personalized after the cache (`IPersonalizedQuery`) so the author and
moderators see `canDownload: true` without per-user cache entries.

**Lifecycle and quotas.** Feed cards carry at most the first 10 page thumbs; the reader gets all pages. Deleting an
article deletes its attachments with their files. The daily orphan job (ADR 0010) first deletes `MediaAssets` rows
older than 24 hours that no article, avatar, cover or RDoc content uses (with their files and pages), then sweeps
unreferenced files. Each user may start 50 uploads per rolling day and keep 200 MB (`Media:*`, configurable); both
count assets that still exist.

**Clients compress first, the server never trusts it.** Web (`browser-image-compression`) and mobile
(`flutter_image_compress`) resize to ≤ 2048 px at quality 0.85 with orientation fixed before uploading; the server
re-processes every image regardless.

## Alternatives considered

- **Serving PDFs from `/uploads` with `Content-Disposition`.** Rejected: static files can't check publication or
  the author's download switch, and inline PDF rendering in the API origin is an XSS surface.
- **Rendering pages in the browser/app (pdf.js, pdfx).** Rejected: every reader would download the whole PDF; the
  feed needs small thumbs and BlurHash placeholders that only a server render provides.
- **ImageSharp.** Rejected for licensing (Six Labors Split License) and because SkiaSharp is already used.
- **Rejecting HEIC.** Rejected: iPhones upload HEIC by default from the web; Magick.NET is used only as a decoder.

## Consequences

- New packages: PDFtoImage (MIT, PDFium BSD-3), PdfPig (Apache-2.0), Magick.NET-Q8-AnyCPU (Apache-2.0, native
  libraries add ~25 MB per runtime to the publish output).
- The uploads folder now also holds original PDFs, so the backup in `docs/setup/deployment.md` covers documents.
- `IFileStorage` gains `OpenReadAsync` (the job and the download read the original back).
- Variants are named by real width, so code that needs every file of an upload uses the asset row
  (`MediaAsset.StoredPaths()`) rather than guessing bucket names.
- Error codes are `media.*` and `attachments.*` (see `docs/api/contract-v1.md`); ADR 0010's `upload.*` codes are
  replaced before any client shipped them.
