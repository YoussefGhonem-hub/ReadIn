# Media test fixtures (ADR 0011)

Small, generated files used by `ReadIn.Infrastructure.UnitTests` and `ReadIn.Api.IntegrationTests`. They are copied to
each test project's output (`fixtures/media`). Nothing here comes from a real person or device.

| File | What it is | Used to test |
|---|---|---|
| `exif-rotated.jpg` | 1200 × 800 JPEG, EXIF Orientation 6, camera tags (`ReadInTestCam`) and GPS coordinates; the stored top-left corner is red | orientation applied (red ends top-right), EXIF/GPS stripped |
| `small.png` | 200 × 150 PNG | never upscaled: one 200 px variant |
| `medium.webp` | 1000 × 700 WebP | variants stop at the image's own width (320, 640, 1000) |
| `sample.heic` | 640 × 480 **HEVC-coded** HEIC (brand `heic`) | HEIC detection and decoding |
| `normal-12-pages.pdf` | 12-page A4 PDF, one marker word per page (`readinmarker1` … `readinmarker12`), an Arabic line on page 1 | page rendering, page 1 first, text extraction |
| `encrypted.pdf` | 2 pages, user password `readin` | `media.pdf_encrypted` |
| `corrupted.pdf` | the first 600 bytes of a real PDF, then garbage (no xref, no trailer) | `media.pdf_corrupted` |
| `too-many-pages-101.pdf` | 101 tiny pages | `media.pdf_too_many_pages` |

## Regenerating

Generators live in [`tools/media-fixtures`](../../../../tools/media-fixtures):

- **PDFs** (pdfkit, MIT, supports encryption): `npm i pdfkit@0.17` in a scratch folder, then
  `node tools/media-fixtures/generate-pdfs.cjs <out-dir> mobile/assets/fonts/IBMPlexSansArabic-Regular.ttf`.
- **Images** (`tools/media-fixtures/heic`, SkiaSharp + Magick.NET): Magick.NET reads HEIC but cannot encode it, so the
  HEIC is built from a real HEVC frame. Encode one frame with ffmpeg
  (`ffmpeg -f lavfi -i "testsrc2=size=640x480:rate=1" -frames:v 1 -c:v libx265 -tag:v hvc1 frame.mp4`), then run
  `dotnet run --project tools/media-fixtures/heic -- <folder with frame.mp4> <out-dir>`. The tool copies the `hvcC`
  configuration and the sample from the MP4 into a minimal HEIF container (`ftyp`/`meta`/`mdat`) and checks that
  Magick.NET decodes it at 640 × 480.

Files are binary in `.gitattributes` (`*.pdf`, `*.heic`, images), so line-ending normalization never touches them.
