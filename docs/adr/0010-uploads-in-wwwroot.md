# 0010 — Uploads stored on the API server (`wwwroot/uploads`)

- **Status:** Accepted
- **Date:** 2026-11-03
- **Supersedes:** "File storage: Firebase Storage" and "Uploads: signed URLs" in SPEC §3.1, §17.2 and §24 (v1.0)

## Context

SPEC v1.0 stored avatars, covers and article images in Firebase Storage, uploaded by clients through
API-issued signed URLs. Other cloud object stores were considered as alternatives. All of them put a second
storage service, its credentials, CORS rules and bucket permissions between the API and its own images, and
make server-side image processing harder: a signed upload goes straight to the bucket, so the API cannot
re-encode the image, strip EXIF data or reject a decompression bomb before the file is public.

ReadIn runs as a single API instance for the foreseeable future, and images are small after re-encoding
(an avatar is two WebP files of a few KB, a cover one file under ~200 KB).

## Decision

- All uploaded images are stored on the API server's disk, in `ReadIn.Api/wwwroot/uploads`, in every
  environment. No Firebase Storage and no other cloud storage.
- Application code depends only on `IFileStorage` (`SaveAsync`, `DeleteAsync`, `GetPublicUrl`). The single
  implementation is `WwwrootFileStorage` in Infrastructure. There is no provider switch.
- Configuration: `Storage:UploadsPath` (default `wwwroot/uploads`, relative to the content root, or an
  absolute path) and `Storage:PublicBaseUrl` (e.g. `https://api.readin.app`).
- Layout: `/uploads/{avatars|covers|articles}/{yyyy}/{MM}/{id}_{size}.webp`. `{id}` is a random GUID; the
  client's file name is never used. One file per size bucket: avatars 256 + 512 (square), covers 1200,
  article images 1600 (maximum width, never upscaled).
- **The database stores relative paths only** (`/uploads/covers/2026/11/{id}_1200.webp`; RDoc image blocks
  use `rdoc-asset://uploads/…`). The API turns them into absolute URLs with `GetPublicUrl` when it responds,
  so changing the domain or moving to a CDN never needs a data migration.
- `POST /api/v1/uploads` (multipart) validates and processes every image with SkiaSharp: at most 5 MB,
  JPEG/PNG/WebP detected by magic bytes, at most 8000 × 8000 pixels (checked from the header, before any
  pixel is decoded), EXIF orientation applied, all metadata dropped, re-encoded to WebP.
- `/uploads` is served by the static-files middleware with an allow-list of one type (`.webp` →
  `image/webp`), `X-Content-Type-Options: nosniff`, `Content-Security-Policy: default-src 'none'`,
  `Cache-Control: public, max-age=31536000, immutable`, and a GET-only CORS policy for the web origin.
  Anything else in the folder is a 404.
- Replacing or removing an avatar, cover or article image deletes its files once nothing else references
  them. A daily Hangfire job deletes files older than 24 hours that no user, article, draft or revision
  references.
- `wwwroot/uploads` is git-ignored (only `.gitkeep` is committed) and excluded from `dotnet publish`.

## Risks

| Risk | Mitigation |
|---|---|
| **A deployment wipes the uploads.** The folder sits inside the app folder, so "delete extra files at destination", replacing the whole folder, or rebuilding a container loses every image. | Excluded from publish output; deployment rules in [`docs/setup/deployment.md`](../setup/deployment.md); a named Docker volume; `Storage:UploadsPath` can point outside the app folder. Startup fails fast if the folder is missing or not writable. |
| **Single server only.** A second API instance would not see the first one's files, and the orphan job would only clean its own disk. | Accepted for now. Scaling out triggers the migration below. |
| **Backups.** Images are no longer in a managed, replicated bucket. The database references files by path, so restoring one without the other breaks images. | Back up `wwwroot/uploads` together with the SQL Server database, on the same schedule (deployment guide includes a script). |
| **Disk space and abuse.** | 5 MB limit, 20 uploads per minute per user, WebP re-encoding (usually 5–20× smaller than the original), orphan cleanup. |
| **The API serves static traffic.** | Immutable caching (one year) means each client fetches an image once; a CDN can sit in front of `/uploads` without code changes because URLs come from `PublicBaseUrl`. |

## Migration path

When ReadIn needs more than one API instance (or a CDN-backed bucket):

1. Implement `IFileStorage` for the target (shared volume or cloud object storage) in Infrastructure and
   register it instead of `WwwrootFileStorage`. Application code does not change.
2. Port the listing part of `OrphanedUploadsCleanupJob` (it enumerates the uploads folder).
3. Copy `wwwroot/uploads` to the new store, keeping the same relative paths.
4. Set `Storage:PublicBaseUrl` to the new public origin (or keep serving through the API). Stored paths stay
   valid, so no database migration is needed.

## Consequences

- No storage credentials or bucket rules to manage; images are processed before they become public.
- Operations own the uploads folder: it must be excluded from deploys, made writable for the app identity
  and backed up with the database.
- Firebase has no part in file storage (its remaining scope is set by SPEC v1.1 §4).
