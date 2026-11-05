import { DOCUMENT, Injectable, inject } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { MediaApi } from '../../core/api/media.api';

/** What a download needs from a document attachment (`DocumentAttachmentDto` / the viewer's document). */
export interface DownloadableDocument {
  title: string;
  /** `GET /documents/{assetId}/download` (absolute), answered with `Content-Disposition: attachment`. */
  downloadUrl: string;
}

/** `"Clean Architecture.pdf"` from the document title, without characters file systems reject. */
export function documentFileName(title: string): string {
  // Control characters and the ones Windows refuses in a file name.
  const unsafe = /[\\/:*?"<>|]/g;
  const base =
    [...title]
      .map((char) => ((char.codePointAt(0) ?? 0) < 0x20 ? ' ' : char))
      .join('')
      .replace(unsafe, ' ')
      .replace(/\s+/g, ' ')
      .trim()
      .replace(/\.pdf$/i, '') || 'document';
  return `${base.slice(0, 150)}.pdf`;
}

/**
 * Saves a post's PDF (F26) for the reader: downloads the original through HttpClient (so the bearer token goes along:
 * owners and moderators may download when the writer turned downloads off) and saves it under the document's title.
 * Used by the download icon in the PDF's title strip on cards and the article page, and by the full-screen viewer.
 * Browser only; a failure rejects with the API error (the caller shows it).
 */
@Injectable({ providedIn: 'root' })
export class DocumentDownloader {
  private readonly media = inject(MediaApi);
  private readonly document = inject(DOCUMENT);

  async download(doc: DownloadableDocument): Promise<void> {
    const blob = await firstValueFrom(this.media.download(doc.downloadUrl));
    this.save(blob, documentFileName(doc.title));
  }

  private save(blob: Blob, fileName: string): void {
    const url = URL.createObjectURL(blob);
    const link = this.document.createElement('a');
    link.href = url;
    link.download = fileName;
    link.rel = 'noopener';
    link.style.display = 'none';
    this.document.body.appendChild(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 10_000);
  }
}
