import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpEvent, HttpEventType, HttpResponse } from '@angular/common/http';
import { By } from '@angular/platform-browser';
import { Router, provideRouter } from '@angular/router';
import { Observable, Subject, of } from 'rxjs';
import { ApiError } from '../../core/api/api.config';
import { ArticlesApi } from '../../core/api/articles.api';
import { MediaApi } from '../../core/api/media.api';
import { FieldDto, MediaAssetDto, SetAttachmentsRequest } from '../../core/api/models';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { BlurHashDecoder } from '../../shared/media/blurhash';
import { ImageCompressor } from '../../shared/media/image-compressor';
import { provideAppIcons } from '../../shared/ui/icons';
import { translocoTesting } from '../../../testing/transloco-testing';
import { AttachmentBar } from './attachment-bar';
import { AttachmentDraft, POLL_INTERVAL_MS } from './attachment-draft';
import { ComposerPage } from './composer.page';
import { textToRDoc } from './composer.utils';

const FIELD: FieldDto = {
  id: 'field-software',
  slug: 'software',
  name: 'Software',
  nameAr: 'البرمجيات',
  nameEn: 'Software',
  icon: 'code',
  color: 'primary',
  isSensitive: false,
  requiresSources: false,
  topicCount: 0,
};

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

describe('ComposerPage (/write)', () => {
  let fixture: ComponentFixture<ComposerPage>;
  let media: FakeMediaApi;
  let articles: { create: ReturnType<typeof vi.fn>; setAttachments: ReturnType<typeof vi.fn>; publish: ReturnType<typeof vi.fn> };
  let navigate: ReturnType<typeof vi.spyOn>;

  const el = () => fixture.nativeElement as HTMLElement;
  const draft = () => fixture.debugElement.injector.get(AttachmentDraft);
  const bar = () => fixture.debugElement.query(By.directive(AttachmentBar)).componentInstance as AttachmentBar;
  const publishButton = () => el().querySelector('[data-publish]') as HTMLButtonElement;
  const blockers = () => el().querySelector('[data-blockers]')?.textContent ?? '';

  async function settle(): Promise<void> {
    for (let i = 0; i < 3; i++) await new Promise((resolve) => setTimeout(resolve));
    await fixture.whenStable();
  }

  function type(selector: string, value: string, event = 'input'): void {
    const input = el().querySelector(selector) as HTMLInputElement;
    input.value = value;
    input.dispatchEvent(new Event(event, { bubbles: true }));
  }

  async function fillForm(): Promise<void> {
    type('[data-field]', FIELD.id, 'change');
    type('[data-title]', 'Clean Architecture in 5 images');
    type('[data-body]', 'أول فقرة\n\nSecond paragraph');
    await settle();
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
    articles = {
      create: vi.fn(() => of({ id: 'article-1', slug: 'clean-architecture' })),
      setAttachments: vi.fn(() => of(undefined)),
      publish: vi.fn(() => of(undefined)),
    };
    TestBed.configureTestingModule({
      imports: [translocoTesting()],
      providers: [
        provideRouter([]),
        provideAppIcons(),
        { provide: MediaApi, useValue: media },
        { provide: ArticlesApi, useValue: articles },
        { provide: TaxonomyApi, useValue: { fields: () => of([FIELD]), topics: () => of([]) } },
        { provide: ImageCompressor, useValue: { compress: (file: File) => Promise.resolve(file) } },
        { provide: BlurHashDecoder, useValue: { toDataUrl: () => null } },
      ],
    });
    navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    fixture = TestBed.createComponent(ComposerPage);
    await settle();
  });

  afterEach(() => vi.useRealTimers());

  it('keeps Publish disabled until every image has alt text', async () => {
    await fillForm();
    expect(publishButton().disabled).toBe(false); // a text-only post is fine

    await addReadyImages(2);
    expect(publishButton().disabled).toBe(true);
    expect(blockers()).toContain('اكتب وصف لصورتين.');
    expect(el().querySelectorAll('[data-alt][aria-invalid="true"]').length).toBe(2);

    type('[data-image-item]:first-child [data-alt]', 'Whiteboard sketch');
    await settle();
    expect(publishButton().disabled).toBe(true);
    expect(blockers()).toContain('اكتب وصف لصورة واحدة.');

    type('[data-image-item]:last-child [data-alt]', '   ');
    await settle();
    expect(publishButton().disabled).toBe(true); // whitespace is not alt text

    type('[data-image-item]:last-child [data-alt]', 'Layer diagram');
    await settle();
    expect(publishButton().disabled).toBe(false);
  });

  it('keeps Publish disabled while an image uploads, with progress, cancel and retry', async () => {
    await fillForm();
    bar().addImages([image('photo.jpg')]);
    await settle();
    await setAllAltTexts();
    expect(publishButton().disabled).toBe(true);
    expect(blockers()).toContain('استنى لحد ما الرفع وتجهيز الصفحات يخلصوا.');

    media.imageUploads[0].next({ type: HttpEventType.UploadProgress, loaded: 5, total: 10 });
    await settle();
    expect(el().querySelector('[data-image-item] [role="progressbar"]')?.getAttribute('aria-valuenow')).toBe('50');

    (el().querySelector('[data-image-item] [data-cancel]') as HTMLButtonElement).click();
    await settle();
    expect(draft().images()[0].status).toBe('canceled');
    expect(media.imageUploads[0].observed).toBe(false); // unsubscribed = request aborted
    expect(publishButton().disabled).toBe(true);
    expect(blockers()).toContain('شيل المرفق اللي فشل أو جرّب ترفعه تاني.');

    (el().querySelector('[data-image-item] [data-retry]') as HTMLButtonElement).click();
    await settle();
    expect(media.uploadImage).toHaveBeenCalledTimes(2);
    respond(media.imageUploads[1], imageAsset('img-asset-1'));
    await settle();
    expect(publishButton().disabled).toBe(false);
  });

  it('keeps Publish disabled while a PDF uploads and while its pages are processing', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    await fillForm();
    bar().addDocument(pdf());
    await settle();
    expect(draft().document()?.title).toBe('Clean Architecture'); // pre-filled from the file name
    expect(draft().document()?.allowDownload).toBe(false); // off by default
    expect(publishButton().disabled).toBe(true);

    respond(media.documentUploads[0], documentAsset('doc-1', 'processing', 0));
    await settle();
    expect(el().querySelector('[data-processing]')?.textContent).toContain('بنجهز الصفحات…');
    expect(publishButton().disabled).toBe(true);

    media.polled = [documentAsset('doc-1', 'processing', 3), documentAsset('doc-1', 'ready', 12)];
    await vi.advanceTimersByTimeAsync(POLL_INTERVAL_MS);
    await settle();
    expect(media.get).toHaveBeenCalledWith('doc-1');
    expect(draft().document()?.status).toBe('processing');
    expect(el().querySelectorAll('[data-doc-preview] li').length).toBe(3);
    expect(publishButton().disabled).toBe(true);

    await vi.advanceTimersByTimeAsync(POLL_INTERVAL_MS);
    await settle();
    expect(draft().document()?.status).toBe('ready');
    expect(publishButton().disabled).toBe(false);

    await vi.advanceTimersByTimeAsync(POLL_INTERVAL_MS * 3);
    expect(media.get).toHaveBeenCalledTimes(2); // polling stopped once ready
  });

  it('shows a translated processing failure with remove and try again', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    await fillForm();
    bar().addDocument(pdf());
    await settle();
    respond(media.documentUploads[0], { ...documentAsset('doc-1', 'failed', 0), failureReason: 'media.pdf_encrypted' });
    await settle();
    expect(el().querySelector('[data-doc-error]')?.textContent).toContain('الملف ده عليه باسورد، ارفعه من غير باسورد.');
    expect(publishButton().disabled).toBe(true);

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

    const draft = bar().draft();
    expect(draft.images()[0].altText).toHaveLength(4000);
    expect(draft.images()[0].caption).toHaveLength(5000);
    const counters = [...el().querySelectorAll('[data-count]')].map((c) => c.textContent?.trim());
    // Only the caption is within 500 characters of its limit.
    expect(counters).toEqual(['5000/5000']);
    expect(el().querySelector('[data-alt]')?.tagName).toBe('TEXTAREA');
  });

  it("can't mix images and a PDF", async () => {
    await addReadyImages(1);
    const pdfButton = el().querySelector('[data-add-pdf]') as HTMLButtonElement;
    expect(pdfButton.disabled).toBe(true);
    expect(el().querySelector('[data-pdf-hint]')?.textContent).toContain('شيل الصور عشان تضيف ملف PDF.');
    expect(draft().setDocument(pdf())).toBe('attachments.pdfDisabled');
    expect(draft().document()).toBeNull();

    (el().querySelector('[data-remove-image]') as HTMLButtonElement).click();
    await settle();
    expect(media.delete).toHaveBeenCalledWith('img-asset-1');
    expect(pdfButton.disabled).toBe(false);

    bar().addDocument(pdf());
    await settle();
    expect((el().querySelector('[data-add-images]') as HTMLButtonElement).disabled).toBe(true);
    expect(el().querySelector('[data-images-hint]')?.textContent).toContain('شيل ملف الـ PDF عشان تضيف صور.');
    expect(draft().addImages([image('late.jpg')]).skipped).toBe(1);
    expect(draft().images()).toEqual([]);
  });

  it('caps images at 10', async () => {
    const result = draft().addImages(Array.from({ length: 12 }, (_, i) => image(`p${i}.jpg`)));
    await settle();
    expect(result).toEqual({ added: 10, unsupported: [], skipped: 2 });
    expect((el().querySelector('[data-add-images]') as HTMLButtonElement).disabled).toBe(true);
  });

  it('reorders images by drag and drop and by keyboard, and publishes in that order', async () => {
    await fillForm();
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
    expect((document.activeElement as HTMLElement | null)?.closest('[data-image-item]')?.getAttribute('data-image-id')).toBe(
      draft().images()[1].id,
    );
    expect((el().querySelector('[data-image-item]:first-child [data-move="earlier"]') as HTMLButtonElement).disabled).toBe(true);

    // Drag and drop (CDK drop list event): last → first.
    (bar() as unknown as { onDrop(e: { previousIndex: number; currentIndex: number }): void }).onDrop({ previousIndex: 2, currentIndex: 0 });
    await settle();
    expect(order()).toEqual(['img-asset-3', 'img-asset-2', 'img-asset-1']);

    publishButton().click();
    await settle();
    const body = articles.setAttachments.mock.calls[0][1] as SetAttachmentsRequest;
    expect(body.items.map((i) => [i.mediaAssetId, i.order, i.altText])).toEqual([
      ['img-asset-3', 0, 'Alt 3'],
      ['img-asset-2', 1, 'Alt 2'],
      ['img-asset-1', 2, 'Alt 1'],
    ]);
  });

  it('publishes: POST /articles → PUT attachments → POST publish → the article page', async () => {
    await fillForm();
    await addReadyImages(1);
    await setAllAltTexts();
    type('[data-caption]', 'On the whiteboard');
    await settle();

    publishButton().click();
    await settle();

    expect(articles.create).toHaveBeenCalledTimes(1);
    const request = articles.create.mock.calls[0][0];
    expect(request).toMatchObject({ fieldId: FIELD.id, language: 'ar-EG', title: 'Clean Architecture in 5 images', isAiAssisted: false });
    expect(request.content.blocks.map((b: { type: string; dir: string }) => [b.type, b.dir])).toEqual([
      ['paragraph', 'auto'],
      ['paragraph', 'auto'],
    ]);
    expect(articles.setAttachments).toHaveBeenCalledWith('article-1', {
      items: [{ mediaAssetId: 'img-asset-1', order: 0, caption: 'On the whiteboard', altText: 'Alt 1' }],
    });
    expect(articles.publish).toHaveBeenCalledWith('article-1');
    expect(navigate).toHaveBeenCalledWith(['/', 'ar', 'a', 'clean-architecture']);
  });

  it('requires a source when the field requires sources', async () => {
    TestBed.inject(TaxonomyApi).fields = () => of([{ ...FIELD, requiresSources: true }]);
    (fixture.componentInstance as unknown as { loadFields(): void }).loadFields();
    await fillForm();
    expect(publishButton().disabled).toBe(true);
    expect(blockers()).toContain('المجال ده محتاج مصدر واحد على الأقل بلينك صحيح.');
    type('[data-source-title]', 'Microsoft Docs');
    type('[data-source-url]', 'not a link');
    await settle();
    expect(blockers()).toContain('كمّل أو شيل المصادر الناقصة.');
    type('[data-source-url]', 'https://learn.microsoft.com/dotnet');
    await settle();
    expect(publishButton().disabled).toBe(false);
  });

  it('shows the translated API error when publishing fails', async () => {
    articles.publish.mockReturnValue(
      new Observable((subscriber) => subscriber.error(new ApiError(400, 'article.sources_required', { code: 'article.sources_required' }))),
    );
    await fillForm();
    publishButton().click();
    await settle();
    expect(el().querySelector('[data-publish-error]')?.textContent).toContain('ضيف مصدر واحد على الأقل قبل ما تنشر.');
    expect(navigate).not.toHaveBeenCalled();

    // Retrying with an unchanged form reuses the created draft.
    articles.publish.mockReturnValue(of(undefined));
    publishButton().click();
    await settle();
    expect(articles.create).toHaveBeenCalledTimes(1);
    expect(navigate).toHaveBeenCalled();
  });
});

describe('textToRDoc', () => {
  it('turns blank-line-separated paragraphs into dir="auto" paragraph blocks', () => {
    const doc = textToRDoc('First line\nsecond line\n\n  \n\nفقرة تانية فيها Dependency Injection\n\n', 'ar-EG');
    expect(doc).toEqual({
      version: 1,
      language: 'ar-EG',
      blocks: [
        {
          id: 'p1',
          type: 'paragraph',
          dir: 'auto',
          content: [{ type: 'text', text: 'First line' }, { type: 'hardBreak' }, { type: 'text', text: 'second line' }],
        },
        { id: 'p2', type: 'paragraph', dir: 'auto', content: [{ type: 'text', text: 'فقرة تانية فيها Dependency Injection' }] },
      ],
    });
    expect(textToRDoc('   ', 'en').blocks).toEqual([]);
  });
});
