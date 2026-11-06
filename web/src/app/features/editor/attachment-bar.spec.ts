import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpEvent, HttpEventType, HttpResponse } from '@angular/common/http';
import { By } from '@angular/platform-browser';
import { Observable, Subject, of } from 'rxjs';
import { MediaApi } from '../../core/api/media.api';
import { MediaAssetDto } from '../../core/api/models';
import { BlurHashDecoder } from '../../shared/media/blurhash';
import { ImageCompressor } from '../../shared/media/image-compressor';
import { provideAppIcons } from '../../shared/ui/icons';
import { translocoTesting } from '../../../testing/transloco-testing';
import { AttachmentBar } from './attachment-bar';
import { AttachmentDraft, POLL_INTERVAL_MS } from './attachment-draft';

function imageAsset(id: string): MediaAssetDto {
  return {
    id,
    kind: 'image',
    purpose: 'image',
    status: 'ready',
    failureReason: null,
    width: 1600,
    height: 1200,
    blurHash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
    sizeBytes: 120_000,
    variants: [320, 640].map((width) => ({ width, height: width * 0.75, url: `https://api.test/uploads/${id}/${width}.webp`, bytes: 1000 })),
    title: null,
    pageCount: null,
    pagesReady: 0,
    pages: [],
    allowDownload: false,
    createdAt: '2026-11-03T08:00:00Z',
  };
}

function documentAsset(id: string, status: MediaAssetDto['status'], pagesReady: number): MediaAssetDto {
  return {
    ...imageAsset(id),
    kind: 'document',
    purpose: 'document',
    status,
    variants: [],
    title: 'Clean Architecture',
    pageCount: 12,
    pagesReady,
    pages: Array.from({ length: pagesReady }, (_, i) => ({
      pageNo: i + 1,
      width: 1080,
      height: 1527,
      blurHash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
      thumbUrl: `https://api.test/uploads/${id}/p${i + 1}-400.webp`,
      viewUrl: `https://api.test/uploads/${id}/p${i + 1}-1080.webp`,
    })),
  };
}

/** Uploads stay open until the test answers them, so "uploading" and "processing" states can be asserted. */
class FakeMediaApi {
  readonly imageUploads: Subject<HttpEvent<MediaAssetDto>>[] = [];
  readonly documentUploads: Subject<HttpEvent<MediaAssetDto>>[] = [];
  polled: MediaAssetDto[] = [];
  uploadImage = vi.fn((): Observable<HttpEvent<MediaAssetDto>> => {
    const upload = new Subject<HttpEvent<MediaAssetDto>>();
    this.imageUploads.push(upload);
    return upload;
  });
  uploadDocument = vi.fn((): Observable<HttpEvent<MediaAssetDto>> => {
    const upload = new Subject<HttpEvent<MediaAssetDto>>();
    this.documentUploads.push(upload);
    return upload;
  });
  get = vi.fn(() => of(this.polled.shift() ?? documentAsset('doc-1', 'processing', 1)));
  delete = vi.fn(() => of(undefined));
}

function respond(upload: Subject<HttpEvent<MediaAssetDto>>, asset: MediaAssetDto): void {
  upload.next({ type: HttpEventType.UploadProgress, loaded: 10, total: 10 });
  upload.next(new HttpResponse({ status: asset.status === 'ready' ? 201 : 202, body: asset }));
  upload.complete();
}

function image(name: string): File {
  return new File([new Uint8Array([1, 2, 3])], name, { type: 'image/jpeg' });
}

const pdf = () => new File([new Uint8Array([0x25, 0x50, 0x44, 0x46])], 'Clean_Architecture.pdf', { type: 'application/pdf' });

/** The editor hosts the bar the same way: it provides the draft and passes it in. */
@Component({
  selector: 'rd-test-host',
  imports: [AttachmentBar],
  providers: [AttachmentDraft],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<rd-attachment-bar [draft]="draft" />`,
})
class Host {
  readonly draft = inject(AttachmentDraft);
}

describe('AttachmentBar + AttachmentDraft (F26 in the editor)', () => {
  let fixture: ComponentFixture<Host>;
  let media: FakeMediaApi;

  const el = () => fixture.nativeElement as HTMLElement;
  const draft = () => fixture.componentInstance.draft;
  const bar = () => fixture.debugElement.query(By.directive(AttachmentBar)).componentInstance as AttachmentBar;

  async function settle(): Promise<void> {
    for (let i = 0; i < 3; i++) await new Promise((resolve) => setTimeout(resolve));
    await fixture.whenStable();
  }

  function type(selector: string, value: string): void {
    const input = el().querySelector(selector) as HTMLInputElement;
    input.value = value;
    input.dispatchEvent(new Event('input', { bubbles: true }));
  }

  async function addReadyImages(count: number): Promise<void> {
    bar().addImages(Array.from({ length: count }, (_, i) => image(`photo-${i + 1}.jpg`)));
    await settle();
    media.imageUploads.slice(-count).forEach((upload, i) => respond(upload, imageAsset(`img-asset-${i + 1}`)));
    await settle();
  }

  async function setAllAltTexts(): Promise<void> {
    el()
      .querySelectorAll<HTMLInputElement>('[data-alt]')
      .forEach((input, i) => {
        input.value = `Alt ${i + 1}`;
        input.dispatchEvent(new Event('input', { bubbles: true }));
      });
    await settle();
  }

  beforeEach(async () => {
    media = new FakeMediaApi();
    TestBed.configureTestingModule({
      imports: [translocoTesting()],
      providers: [
        provideAppIcons(),
        { provide: MediaApi, useValue: media },
        { provide: ImageCompressor, useValue: { compress: (file: File) => Promise.resolve(file) } },
        { provide: BlurHashDecoder, useValue: { toDataUrl: () => null } },
      ],
    });
    fixture = TestBed.createComponent(Host);
    await settle();
  });

  afterEach(() => vi.useRealTimers());

  it('marks every image without alt text until it has one (whitespace is not alt text)', async () => {
    await addReadyImages(2);
    expect(draft().missingAltCount()).toBe(2);
    expect(el().querySelectorAll('[data-alt][aria-invalid="true"]').length).toBe(2);

    type('[data-image-item]:first-child [data-alt]', 'Whiteboard sketch');
    await settle();
    expect(draft().missingAltCount()).toBe(1);

    type('[data-image-item]:last-child [data-alt]', '   ');
    await settle();
    expect(draft().missingAltCount()).toBe(1);

    type('[data-image-item]:last-child [data-alt]', 'Layer diagram');
    await settle();
    expect(draft().missingAltCount()).toBe(0);
    expect(draft().isComplete()).toBe(true);
  });

  it('shows image upload progress, with cancel and retry, and is busy until the upload is done', async () => {
    bar().addImages([image('photo.jpg')]);
    await settle();
    expect(draft().isBusy()).toBe(true);
    expect(draft().draftAttachments()).toEqual([]); // nothing to save before the upload is done

    media.imageUploads[0].next({ type: HttpEventType.UploadProgress, loaded: 5, total: 10 });
    await settle();
    expect(el().querySelector('[data-image-item] [role="progressbar"]')?.getAttribute('aria-valuenow')).toBe('50');

    (el().querySelector('[data-image-item] [data-cancel]') as HTMLButtonElement).click();
    await settle();
    expect(draft().images()[0].status).toBe('canceled');
    expect(media.imageUploads[0].observed).toBe(false); // unsubscribed = request aborted
    expect(draft().hasProblem()).toBe(true);

    (el().querySelector('[data-image-item] [data-retry]') as HTMLButtonElement).click();
    await settle();
    expect(media.uploadImage).toHaveBeenCalledTimes(2);
    respond(media.imageUploads[1], imageAsset('img-asset-1'));
    await settle();
    expect(draft().isBusy()).toBe(false);
    expect(draft().hasProblem()).toBe(false);
    expect(draft().draftAttachments()).toEqual([{ mediaAssetId: 'img-asset-1', order: 0, caption: null, altText: '' }]);
  });

  it('polls a PDF while its pages are being prepared, and stops once ready', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    bar().addDocument(pdf());
    await settle();
    expect(draft().document()?.title).toBe('Clean Architecture'); // pre-filled from the file name
    // "Allow download" starts on (SPEC F26) and is sent explicitly with the upload.
    expect(draft().document()?.allowDownload).toBe(true);
    expect(media.uploadDocument).toHaveBeenCalledWith(expect.any(File), 'Clean_Architecture.pdf', 'Clean Architecture', true);
    expect(draft().isBusy()).toBe(true);

    respond(media.documentUploads[0], documentAsset('doc-1', 'processing', 0));
    await settle();
    expect(el().querySelector('[data-processing]')?.textContent).toContain('جارٍ تجهيز الصفحات…');
    expect(el().querySelector<HTMLInputElement>('[data-allow-download]')!.checked).toBe(true);
    expect(draft().isBusy()).toBe(true);
    // The draft already names the PDF: the server reports it as not ready until the pages are done.
    expect(draft().draftAttachments()).toEqual([{ mediaAssetId: 'doc-1', order: 0, title: 'Clean Architecture', allowDownload: true }]);
    // The writer can turn it off; the draft carries the change.
    const toggle = el().querySelector<HTMLInputElement>('[data-allow-download]')!;
    toggle.checked = false;
    toggle.dispatchEvent(new Event('change'));
    await settle();
    expect(draft().draftAttachments()).toEqual([{ mediaAssetId: 'doc-1', order: 0, title: 'Clean Architecture', allowDownload: false }]);

    media.polled = [documentAsset('doc-1', 'processing', 3), documentAsset('doc-1', 'ready', 12)];
    await vi.advanceTimersByTimeAsync(POLL_INTERVAL_MS);
    await settle();
    expect(media.get).toHaveBeenCalledWith('doc-1');
    expect(el().querySelectorAll('[data-doc-preview] li').length).toBe(3);

    await vi.advanceTimersByTimeAsync(POLL_INTERVAL_MS);
    await settle();
    expect(draft().document()?.status).toBe('ready');
    expect(draft().isBusy()).toBe(false);

    await vi.advanceTimersByTimeAsync(POLL_INTERVAL_MS * 3);
    expect(media.get).toHaveBeenCalledTimes(2); // polling stopped once ready
  });

  it('shows a translated processing failure with remove and try again', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    bar().addDocument(pdf());
    await settle();
    respond(media.documentUploads[0], { ...documentAsset('doc-1', 'failed', 0), failureReason: 'media.pdf_encrypted' });
    await settle();
    expect(el().querySelector('[data-doc-error]')?.textContent).toContain('هذا الملف محمي بكلمة مرور. ارفعه دون كلمة مرور.');
    expect(draft().hasProblem()).toBe(true);

    (el().querySelector('[data-document] [data-retry]') as HTMLButtonElement).click();
    await settle();
    expect(media.delete).toHaveBeenCalledWith('doc-1'); // the failed asset is cleaned up
    expect(media.uploadDocument).toHaveBeenCalledTimes(2);
  });

  it('accepts alt text and captions up to 5000 characters, with a counter only near the limit', async () => {
    await addReadyImages(1);

    type('[data-alt]', 'A'.repeat(4000));
    type('[data-caption]', 'C'.repeat(6000));
    await settle();

    expect(draft().images()[0].altText).toHaveLength(4000);
    expect(draft().images()[0].caption).toHaveLength(5000);
    const counters = [...el().querySelectorAll('[data-count]')].map((c) => c.textContent?.trim());
    // Only the caption is within 500 characters of its limit.
    expect(counters).toEqual(['5000/5000']);
    expect(el().querySelector('[data-alt]')?.tagName).toBe('TEXTAREA');
  });

  it("can't mix images and a PDF", async () => {
    await addReadyImages(1);
    const pdfButton = el().querySelector('[data-add-pdf]') as HTMLButtonElement;
    expect(pdfButton.disabled).toBe(true);
    expect(el().querySelector('[data-pdf-hint]')?.textContent).toContain('أزل الصور لإضافة ملف PDF.');
    expect(draft().setDocument(pdf())).toBe('attachments.pdfDisabled');
    expect(draft().document()).toBeNull();

    (el().querySelector('[data-remove-image]') as HTMLButtonElement).click();
    await settle();
    expect(media.delete).toHaveBeenCalledWith('img-asset-1');
    expect(pdfButton.disabled).toBe(false);

    bar().addDocument(pdf());
    await settle();
    expect((el().querySelector('[data-add-images]') as HTMLButtonElement).disabled).toBe(true);
    expect(el().querySelector('[data-images-hint]')?.textContent).toContain('أزل ملف PDF لإضافة صور.');
    expect(draft().addImages([image('late.jpg')]).skipped).toBe(1);
    expect(draft().images()).toEqual([]);
  });

  it('caps images at 10', async () => {
    const result = draft().addImages(Array.from({ length: 12 }, (_, i) => image(`p${i}.jpg`)));
    await settle();
    expect(result).toEqual({ added: 10, unsupported: [], skipped: 2 });
    expect((el().querySelector('[data-add-images]') as HTMLButtonElement).disabled).toBe(true);
  });

  it('reorders images by drag and drop and by keyboard, and the draft keeps that order', async () => {
    await addReadyImages(3);
    await setAllAltTexts(); // Alt 1..3 in the original order
    const order = () => draft().images().map((i) => i.asset!.id);
    expect(order()).toEqual(['img-asset-1', 'img-asset-2', 'img-asset-3']);

    // Keyboard: "move later" on the first card; focus stays on the moved card.
    const later = el().querySelector('[data-image-item]:first-child [data-move="later"]') as HTMLButtonElement;
    later.focus();
    later.click();
    await settle();
    expect(order()).toEqual(['img-asset-2', 'img-asset-1', 'img-asset-3']);
    expect((document.activeElement as HTMLElement | null)?.closest('[data-image-item]')?.getAttribute('data-image-id')).toBe(draft().images()[1].id);
    expect((el().querySelector('[data-image-item]:first-child [data-move="earlier"]') as HTMLButtonElement).disabled).toBe(true);

    // Drag and drop (CDK drop list event): last → first.
    (bar() as unknown as { onDrop(e: { previousIndex: number; currentIndex: number }): void }).onDrop({ previousIndex: 2, currentIndex: 0 });
    await settle();
    expect(order()).toEqual(['img-asset-3', 'img-asset-2', 'img-asset-1']);

    type('[data-image-item]:first-child [data-caption]', '  On the whiteboard ');
    await settle();
    expect(draft().draftAttachments()).toEqual([
      { mediaAssetId: 'img-asset-3', order: 0, caption: 'On the whiteboard', altText: 'Alt 3' },
      { mediaAssetId: 'img-asset-2', order: 1, caption: null, altText: 'Alt 2' },
      { mediaAssetId: 'img-asset-1', order: 2, caption: null, altText: 'Alt 1' },
    ]);
  });

  it('loads the attachments of a saved article; removing one does not delete its file (it may still be live)', async () => {
    draft().load(
      [
        { mediaAssetId: 'b', order: 1, caption: null, altText: 'Second' },
        { mediaAssetId: 'a', order: 0, caption: 'First caption', altText: 'First' },
        { mediaAssetId: 'gone', order: 2, altText: 'No asset' },
      ],
      [imageAsset('a'), imageAsset('b')],
    );
    await settle();
    expect(draft().images().map((i) => [i.asset?.id, i.altText, i.caption, i.status, i.file])).toEqual([
      ['a', 'First', 'First caption', 'ready', null],
      ['b', 'Second', '', 'ready', null],
    ]);
    expect(el().querySelectorAll('[data-image-item] [data-retry]').length).toBe(0);
    expect(draft().localIdOf('b')).toBe(draft().images()[1].id);

    (el().querySelector('[data-remove-image]') as HTMLButtonElement).click();
    await settle();
    expect(media.delete).not.toHaveBeenCalled();
    expect(draft().draftAttachments()).toEqual([{ mediaAssetId: 'b', order: 0, caption: null, altText: 'Second' }]);
  });

  it('asks the server for attachments the saved media list does not know (a restored local backup)', async () => {
    media.get.mockImplementation(((id: string) => of(imageAsset(id))) as never);
    await draft().loadResolving(
      [
        { mediaAssetId: 'known', order: 0, altText: 'Known' },
        { mediaAssetId: 'newer', order: 1, altText: 'Uploaded after the last save' },
      ],
      [imageAsset('known')],
    );
    expect(media.get).toHaveBeenCalledWith('newer');
    expect(draft().draftAttachments().map((a) => a.mediaAssetId)).toEqual(['known', 'newer']);
  });

  it('loads a saved PDF that is still being prepared and keeps polling it', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    draft().load([{ mediaAssetId: 'doc-1', order: 0, title: 'Slides', allowDownload: true }], [documentAsset('doc-1', 'processing', 2)]);
    await settle();
    expect(draft().document()).toMatchObject({ title: 'Slides', allowDownload: true, status: 'processing', file: null });
    expect(el().querySelector('[data-document]')?.textContent).toContain('PDF');
    media.polled = [documentAsset('doc-1', 'ready', 12)];
    await vi.advanceTimersByTimeAsync(POLL_INTERVAL_MS);
    await settle();
    expect(draft().document()?.status).toBe('ready');
    expect(draft().draftAttachments()).toEqual([{ mediaAssetId: 'doc-1', order: 0, title: 'Slides', allowDownload: true }]);
  });
});
