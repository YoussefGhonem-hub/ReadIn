import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { ApiError } from '../../core/api/api.config';
import { MediaApi } from '../../core/api/media.api';
import { DocumentDownloader, documentFileName } from './document-download';

/** Saving a post's PDF (F26): the original, fetched with the session, saved under the document's title. */
describe('DocumentDownloader (F26)', () => {
  let download: ReturnType<typeof vi.fn>;
  let clicked: { href: string; download: string }[];

  beforeEach(() => {
    TestBed.resetTestingModule();
    download = vi.fn(() => of(new Blob(['%PDF-1.4'], { type: 'application/pdf' })));
    TestBed.configureTestingModule({ providers: [{ provide: MediaApi, useValue: { download } }] });
    clicked = [];
    vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function (this: HTMLAnchorElement) {
      clicked.push({ href: this.href, download: this.download });
    });
    URL.createObjectURL = vi.fn(() => 'blob:readin/1');
    URL.revokeObjectURL = vi.fn();
  });

  afterEach(() => vi.restoreAllMocks());

  it('downloads from downloadUrl and saves the file under the title', async () => {
    await TestBed.inject(DocumentDownloader).download({ title: 'Kubernetes basics', downloadUrl: 'https://api.test/documents/d1/download' });
    expect(download).toHaveBeenCalledWith('https://api.test/documents/d1/download');
    expect(clicked).toEqual([{ href: 'blob:readin/1', download: 'Kubernetes basics.pdf' }]);
    expect(document.body.querySelector('a[download]')).toBeNull(); // the temporary link is gone
  });

  it('a failure rejects with the API error and saves nothing', async () => {
    download.mockReturnValue(throwError(() => new ApiError(403, 'media.download_not_allowed', null)));
    await expect(TestBed.inject(DocumentDownloader).download({ title: 'x', downloadUrl: 'https://api.test/documents/d1/download' })).rejects.toMatchObject({
      code: 'media.download_not_allowed',
    });
    expect(clicked).toEqual([]);
  });

  it('names the file after the title, without characters file systems refuse', () => {
    expect(documentFileName('Clean Architecture')).toBe('Clean Architecture.pdf');
    expect(documentFileName('Slides.PDF')).toBe('Slides.pdf');
    expect(documentFileName('a/b:c*d?"e"<f>|g')).toBe('a b c d e f g.pdf');
    expect(documentFileName(`tab${String.fromCodePoint(9)}and${String.fromCodePoint(10)}line`)).toBe('tab and line.pdf');
    expect(documentFileName('   ')).toBe('document.pdf');
    expect(documentFileName('ملخص الـ Kubernetes')).toBe('ملخص الـ Kubernetes.pdf');
    expect(documentFileName('x'.repeat(200))).toBe(`${'x'.repeat(150)}.pdf`);
  });
});
