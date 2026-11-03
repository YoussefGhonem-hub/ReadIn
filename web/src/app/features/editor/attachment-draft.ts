import { HttpEventType } from '@angular/common/http';
import { Injectable, OnDestroy, computed, inject, signal } from '@angular/core';
import { EMPTY, Observable, Subscription, catchError, defer, switchMap, takeWhile, timer } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { MediaApi } from '../../core/api/media.api';
import { MediaAssetDto, SetAttachmentsRequest } from '../../core/api/models';
import { ImageCompressor } from '../../shared/media/image-compressor';

export const MAX_IMAGES = 10;
/** Server limit for one image upload (after client-side compression). */
export const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
export const MAX_DOCUMENT_BYTES = 20 * 1024 * 1024;
export const CAPTION_MAX = 120;
export const ALT_TEXT_MAX = 250;
export const DOCUMENT_TITLE_MAX = 150;
export const POLL_INTERVAL_MS = 2000;

const IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'];
const IMAGE_EXTENSIONS = /\.(jpe?g|png|webp|heic|heif)$/i;

/** `compressing` → `uploading` → `ready` for images; documents go `uploading` → `processing` → `ready`. */
export type UploadStatus = 'compressing' | 'uploading' | 'processing' | 'ready' | 'failed' | 'canceled';

interface DraftUpload {
  /** Local id (stable while the item is in the draft). */
  id: string;
  file: File;
  status: UploadStatus;
  /** Upload progress 0..1. */
  progress: number;
  asset: MediaAssetDto | null;
  /** Stable error code (API `code`, `failureReason`, or a local one). */
  errorCode: string | null;
}

export interface DraftImage extends DraftUpload {
  /** Local object URL shown until the server variant exists. */
  previewUrl: string | null;
  caption: string;
  altText: string;
}

export interface DraftDocument extends DraftUpload {
  title: string;
  allowDownload: boolean;
}

/** Why picked files were not added (translation keys under `attachments.*`). */
export interface AddImagesResult {
  added: number;
  unsupported: string[];
  skipped: number;
}

const BUSY: readonly UploadStatus[] = ['compressing', 'uploading', 'processing'];
const PROBLEM: readonly UploadStatus[] = ['failed', 'canceled'];

export function isImageFile(file: File): boolean {
  // HEIC often arrives without a MIME type, so the extension counts too.
  return IMAGE_TYPES.includes(file.type.toLowerCase()) || IMAGE_EXTENSIONS.test(file.name);
}

export function isPdfFile(file: File): boolean {
  return file.type === 'application/pdf' || /\.pdf$/i.test(file.name);
}

/** "Clean Architecture.pdf" → "Clean Architecture" (the editable default document title). */
export function titleFromFileName(name: string): string {
  return name.replace(/\.[^./\\]+$/, '').replace(/[_]+/g, ' ').trim().slice(0, DOCUMENT_TITLE_MAX);
}

/**
 * Attachment state for a post (F26): either up to 10 images or one PDF, never both. Owns the uploads (compress →
 * upload with progress → ready; PDFs then poll `GET /uploads/{id}` every 2 s while processing), cancel/retry/remove,
 * reordering, captions, alt text and the document settings. Hosts (the composer, later the block editor) provide it
 * and read `blockers`/`toRequest()` to gate and send `PUT /articles/{id}/attachments`.
 */
@Injectable()
export class AttachmentDraft implements OnDestroy {
  private readonly media = inject(MediaApi);
  private readonly compressor = inject(ImageCompressor);

  private readonly _images = signal<DraftImage[]>([]);
  private readonly _document = signal<DraftDocument | null>(null);
  readonly images = this._images.asReadonly();
  readonly document = this._document.asReadonly();

  readonly kind = computed<'images' | 'document' | null>(() => (this._images().length ? 'images' : this._document() ? 'document' : null));
  readonly isEmpty = computed(() => this.kind() === null);
  /** Images and a PDF can't be mixed; images stop at 10. */
  readonly canAddImages = computed(() => !this._document() && this._images().length < MAX_IMAGES);
  readonly canAddDocument = computed(() => !this._document() && this._images().length === 0);

  readonly isBusy = computed(() => this.uploads().some((u) => BUSY.includes(u.status)));
  readonly hasProblem = computed(() => this.uploads().some((u) => PROBLEM.includes(u.status)));
  readonly missingAltCount = computed(() => this._images().filter((i) => !i.altText.trim()).length);
  readonly documentTitleMissing = computed(() => {
    const doc = this._document();
    return !!doc && !doc.title.trim();
  });
  /** True when the attachments can be saved with the post. */
  readonly isComplete = computed(() => !this.isBusy() && !this.hasProblem() && this.missingAltCount() === 0 && !this.documentTitleMissing());

  private readonly uploads = computed<DraftUpload[]>(() => {
    const doc = this._document();
    return doc ? [...this._images(), doc] : this._images();
  });
  private readonly subscriptions = new Map<string, Subscription>();
  private nextId = 1;

  // ── Images ───────────────────────────────────────────────

  addImages(files: readonly File[]): AddImagesResult {
    const result: AddImagesResult = { added: 0, unsupported: [], skipped: 0 };
    if (this._document()) {
      result.skipped = files.length;
      return result;
    }
    const room = MAX_IMAGES - this._images().length;
    const accepted: DraftImage[] = [];
    for (const file of files) {
      if (!isImageFile(file)) {
        result.unsupported.push(file.name);
      } else if (accepted.length >= room) {
        result.skipped++;
      } else {
        accepted.push({
          id: `img-${this.nextId++}`,
          file,
          status: 'compressing',
          progress: 0,
          asset: null,
          errorCode: null,
          previewUrl: objectUrl(file),
          caption: '',
          altText: '',
        });
      }
    }
    if (accepted.length) {
      this._images.update((list) => [...list, ...accepted]);
      accepted.forEach((image) => this.startImage(image.id));
    }
    result.added = accepted.length;
    return result;
  }

  removeImage(id: string): void {
    const image = this._images().find((i) => i.id === id);
    if (!image) return;
    this.stop(id);
    revoke(image.previewUrl);
    this._images.update((list) => list.filter((i) => i.id !== id));
    this.deleteAsset(image.asset);
  }

  /** Moves an image from one position to another (drag and drop, or the keyboard move buttons). */
  moveImage(from: number, to: number): void {
    const list = [...this._images()];
    if (from < 0 || from >= list.length) return;
    const target = Math.max(0, Math.min(list.length - 1, to));
    if (target === from) return;
    const [item] = list.splice(from, 1);
    list.splice(target, 0, item);
    this._images.set(list);
  }

  setCaption(id: string, caption: string): void {
    this.patchImage(id, { caption: caption.slice(0, CAPTION_MAX) });
  }

  setAltText(id: string, altText: string): void {
    this.patchImage(id, { altText: altText.slice(0, ALT_TEXT_MAX) });
  }

  cancelImage(id: string): void {
    const image = this._images().find((i) => i.id === id);
    if (!image || !BUSY.includes(image.status)) return;
    this.stop(id);
    this.patchImage(id, { status: 'canceled', progress: 0 });
  }

  retryImage(id: string): void {
    const image = this._images().find((i) => i.id === id);
    if (!image || !PROBLEM.includes(image.status)) return;
    this.startImage(id);
  }

  private startImage(id: string): void {
    this.stop(id);
    this.patchImage(id, { status: 'compressing', progress: 0, errorCode: null });
    const image = this._images().find((i) => i.id === id);
    if (!image) return;

    const subscription = compressWithAbort(this.compressor, image.file)
      .pipe(
        switchMap((blob) => {
          if (blob.size > MAX_IMAGE_BYTES) throw { code: 'media.too_large' };
          this.patchImage(id, { status: 'uploading' });
          return this.media.uploadImage(blob, image.file.name);
        }),
      )
      .subscribe({
        next: (event) => {
          if (event.type === HttpEventType.UploadProgress) {
            this.patchImage(id, { progress: event.total ? event.loaded / event.total : 0 });
          } else if (event.type === HttpEventType.Response && event.body) {
            const asset = event.body;
            this.patchImage(
              id,
              asset.status === 'failed'
                ? { status: 'failed', asset, errorCode: asset.failureReason ?? 'media.processing_failed' }
                : { status: 'ready', asset, progress: 1 },
            );
          }
        },
        error: (error: unknown) => this.patchImage(id, { status: 'failed', errorCode: errorCode(error) }),
        complete: () => this.subscriptions.delete(id),
      });
    this.subscriptions.set(id, subscription);
  }

  private patchImage(id: string, patch: Partial<DraftImage>): void {
    this._images.update((list) => list.map((i) => (i.id === id ? { ...i, ...patch } : i)));
  }

  // ── Document ─────────────────────────────────────────────

  /** Starts uploading a PDF. Returns a translation key when the file is refused locally (the server checks pages). */
  setDocument(file: File): string | null {
    if (!this.canAddDocument()) return 'attachments.pdfDisabled';
    if (!isPdfFile(file)) return 'attachments.notPdf';
    if (file.size > MAX_DOCUMENT_BYTES) return 'attachments.pdfTooLarge';
    this._document.set({
      id: `doc-${this.nextId++}`,
      file,
      status: 'uploading',
      progress: 0,
      asset: null,
      errorCode: null,
      title: titleFromFileName(file.name),
      allowDownload: false,
    });
    this.startDocument();
    return null;
  }

  removeDocument(): void {
    const doc = this._document();
    if (!doc) return;
    this.stop(doc.id);
    this._document.set(null);
    this.deleteAsset(doc.asset);
  }

  setDocumentTitle(title: string): void {
    this.patchDocument({ title: title.slice(0, DOCUMENT_TITLE_MAX) });
  }

  setAllowDownload(allowDownload: boolean): void {
    this.patchDocument({ allowDownload });
  }

  cancelDocument(): void {
    const doc = this._document();
    if (!doc || !BUSY.includes(doc.status)) return;
    this.stop(doc.id);
    this.patchDocument({ status: 'canceled', progress: 0 });
  }

  /** Uploads the same file again (a failed processing run leaves a failed asset behind, which is deleted). */
  retryDocument(): void {
    const doc = this._document();
    if (!doc || !PROBLEM.includes(doc.status)) return;
    this.deleteAsset(doc.asset);
    this.patchDocument({ asset: null });
    this.startDocument();
  }

  private startDocument(): void {
    const doc = this._document();
    if (!doc) return;
    this.stop(doc.id);
    this.patchDocument({ status: 'uploading', progress: 0, errorCode: null });
    const subscription = this.media.uploadDocument(doc.file, doc.file.name, doc.title.trim() || titleFromFileName(doc.file.name), doc.allowDownload).subscribe({
      next: (event) => {
        if (event.type === HttpEventType.UploadProgress) {
          this.patchDocument({ progress: event.total ? event.loaded / event.total : 0 });
        } else if (event.type === HttpEventType.Response && event.body) {
          this.applyDocumentAsset(event.body);
          if (event.body.status === 'processing') this.poll(event.body.id);
        }
      },
      error: (error: unknown) => this.patchDocument({ status: 'failed', errorCode: errorCode(error) }),
    });
    this.subscriptions.set(doc.id, subscription);
  }

  /** `GET /uploads/{id}` every 2 s while processing; stops on ready/failed, removal, cancel or destroy. */
  private poll(assetId: string): void {
    const doc = this._document();
    if (!doc) return;
    const subscription = timer(POLL_INTERVAL_MS, POLL_INTERVAL_MS)
      .pipe(
        switchMap(() => this.media.get(assetId).pipe(catchError(() => EMPTY))), // a network blip just skips a tick
        takeWhile((asset) => asset.status === 'processing', true),
      )
      .subscribe((asset) => this.applyDocumentAsset(asset));
    this.subscriptions.set(doc.id, subscription);
  }

  private applyDocumentAsset(asset: MediaAssetDto): void {
    if (asset.status === 'failed') {
      this.patchDocument({ asset, status: 'failed', errorCode: asset.failureReason ?? 'media.processing_failed' });
    } else if (asset.status === 'ready') {
      this.patchDocument({ asset, status: 'ready', progress: 1 });
    } else {
      this.patchDocument({ asset, status: 'processing', progress: 1 });
    }
  }

  private patchDocument(patch: Partial<DraftDocument>): void {
    this._document.update((doc) => (doc ? { ...doc, ...patch } : doc));
  }

  // ── Output ───────────────────────────────────────────────

  /** `SetAttachmentsRequest` for the ready attachments, in display order. */
  toRequest(): SetAttachmentsRequest {
    const doc = this._document();
    if (doc?.asset) {
      return { items: [{ mediaAssetId: doc.asset.id, order: 0, title: doc.title.trim(), allowDownload: doc.allowDownload }] };
    }
    return {
      items: this._images()
        .filter((i) => i.asset)
        .map((image, order) => ({
          mediaAssetId: image.asset!.id,
          order,
          caption: image.caption.trim() || null,
          altText: image.altText.trim(),
        })),
    };
  }

  ngOnDestroy(): void {
    this.subscriptions.forEach((s) => s.unsubscribe());
    this.subscriptions.clear();
    this._images().forEach((i) => revoke(i.previewUrl));
  }

  private stop(id: string): void {
    this.subscriptions.get(id)?.unsubscribe();
    this.subscriptions.delete(id);
  }

  /** Removing an uploaded asset frees the user's quota; failures (e.g. already gone) are ignored. */
  private deleteAsset(asset: MediaAssetDto | null): void {
    if (asset) this.media.delete(asset.id).subscribe({ error: () => undefined });
  }
}

/** Compression that is aborted when the subscriber unsubscribes (cancel). */
function compressWithAbort(compressor: ImageCompressor, file: File): Observable<Blob> {
  return defer(() => {
    const controller = typeof AbortController === 'function' ? new AbortController() : null;
    return new Observable<Blob>((subscriber) => {
      compressor.compress(file, controller?.signal).then(
        (blob) => {
          subscriber.next(blob);
          subscriber.complete();
        },
        (error: unknown) => subscriber.error(error),
      );
      return () => controller?.abort();
    });
  });
}

function errorCode(error: unknown): string {
  if (isApiError(error)) return error.code;
  const code = (error as { code?: unknown } | null)?.code;
  return typeof code === 'string' ? code : 'unknown';
}

function objectUrl(file: File): string | null {
  return typeof URL !== 'undefined' && typeof URL.createObjectURL === 'function' ? URL.createObjectURL(file) : null;
}

function revoke(url: string | null): void {
  if (url && typeof URL.revokeObjectURL === 'function') URL.revokeObjectURL(url);
}
