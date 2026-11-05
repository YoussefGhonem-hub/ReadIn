import { PRECONNECT_CHECK_BLOCKLIST } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { ApiError } from '../../core/api/api.config';
import { DocumentAttachmentDto } from '../../core/api/models';
import { flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { ToastService } from '../ui/toast/toast.service';
import { ArticleAttachments } from './article-attachments';
import { BlurHashDecoder } from './blurhash';
import { DocumentDownloader } from './document-download';

function doc(patch: Partial<DocumentAttachmentDto> = {}): DocumentAttachmentDto {
  return {
    assetId: 'd1',
    title: 'Kubernetes basics',
    pageCount: 2,
    allowDownload: true,
    canDownload: true,
    downloadUrl: 'https://api.test/documents/d1/download',
    pages: [1, 2].map((pageNo) => ({ pageNo, width: 1080, height: 1400, blurHash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj', thumbUrl: `https://api.test/p${pageNo}_400.webp`, viewUrl: `https://api.test/p${pageNo}_1080.webp` })),
    ...patch,
  };
}

/** The PDF's title strip (F26): "📄 title · N pages" and, when allowed (or for the owner), a download icon. */
describe('ArticleAttachments: PDF title strip download (F26)', () => {
  let download: ReturnType<typeof vi.fn>;

  async function render(document: DocumentAttachmentDto) {
    TestBed.resetTestingModule();
    download = vi.fn(async () => undefined);
    setupSocialTesting({
      providers: [
        { provide: DocumentDownloader, useValue: { download } },
        { provide: BlurHashDecoder, useValue: { toDataUrl: () => null } },
        { provide: PRECONNECT_CHECK_BLOCKLIST, useValue: 'https://api.test' },
      ],
    });
    const fixture = TestBed.createComponent(ArticleAttachments);
    fixture.componentRef.setInput('attachments', { kind: 'document', images: [], document });
    fixture.componentRef.setInput('article', { slug: 'k8s', language: 'en', title: 'Kubernetes' });
    fixture.detectChanges();
    await fixture.whenStable();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    return { root, stable, button: () => root.querySelector<HTMLButtonElement>('[data-document-header] [data-document-download]') };
  }

  it('shows a named download icon when the reader may download, and saves the file', async () => {
    const t = await render(doc());
    const button = t.button()!;
    expect(button.getAttribute('aria-label')).toContain('تحميل');
    expect(button.getAttribute('aria-label')).toContain('Kubernetes basics');
    button.click();
    await t.stable();
    expect(download).toHaveBeenCalledWith(expect.objectContaining({ title: 'Kubernetes basics', downloadUrl: 'https://api.test/documents/d1/download' }));
  });

  it('the owner (canDownload) gets it even when downloads are off; others don’t', async () => {
    expect((await render(doc({ allowDownload: false, canDownload: true }))).button()).not.toBeNull();
    expect((await render(doc({ allowDownload: false, canDownload: false }))).button()).toBeNull();
  });

  it('a failed download is a toast, and the button works again', async () => {
    const t = await render(doc());
    const error = vi.spyOn(TestBed.inject(ToastService), 'error');
    download.mockRejectedValueOnce(new ApiError(403, 'media.download_not_allowed', null));
    t.button()!.click();
    await t.stable();
    expect(error).toHaveBeenCalledOnce();
    expect(t.button()!.disabled).toBe(false);
  });
});
