import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { environment } from '../../../environments/environment';
import { ContentApi } from '../../core/api/content.api';
import { ArticleAttachmentsDto, ArticleLanguage, DocumentAttachmentDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { PluralPipe } from '../pipes/format.pipes';
import { urlLangFor } from '../ui/article-link';
import { MediaCarousel } from './media-carousel';
import { MediaImage } from './media-image';
import { MediaSlide, clampImageRatio, documentRatio, documentSlides, imageSlides } from './media-slides';
import { MediaViewerService } from './media-viewer.service';

export interface AttachmentsArticleRef {
  slug: string;
  language: ArticleLanguage;
  title: string;
}

/** Feed cards and the article column are at most 720px wide (688px of content). */
const FULL_WIDTH_SIZES = '(min-width: 768px) 688px, 100vw';
const SLIDE_SIZES = '(min-width: 768px) 600px, 85vw';

/**
 * Post attachments (F26) for feed cards and the article page: one image full width, two or more images in the
 * carousel, a PDF as a page carousel under a "📄 title · N pages" strip. Tapping opens the full-screen viewer.
 */
@Component({
  selector: 'rd-article-attachments',
  imports: [TranslocoPipe, PluralPipe, MediaCarousel, MediaImage],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', '[attr.data-attachments]': 'attachments().kind' },
  template: `
    @if (attachments().kind === 'images') {
      @if (images().length === 1) {
        @let image = images()[0];
        <button
          type="button"
          class="block w-full cursor-zoom-in overflow-hidden rounded-md border border-border bg-surface p-0 text-start"
          [attr.aria-label]="'media.open' | transloco: { label: image.alt }"
          data-single-image
          (click)="openImages(0)"
        >
          <span class="relative block w-full" [style.aspect-ratio]="singleRatio()">
            <rd-media-image
              class="absolute inset-0"
              [variants]="image.variants"
              [alt]="image.alt"
              [sizes]="fullWidthSizes"
              [blurHash]="image.blurHash"
              [ratio]="singleRatio()"
              [priority]="priority()"
            />
          </span>
          @if (image.caption) {
            <span class="block truncate px-3 py-2 text-sm font-semibold text-text-primary" dir="auto">{{ image.caption }}</span>
          }
        </button>
      } @else if (images().length > 1) {
        <rd-media-carousel
          [slides]="images()"
          [aspectRatio]="1"
          [sizes]="slideSizes"
          [label]="'media.imagesLabel' | transloco"
          [priority]="priority()"
          (opened)="openImages($event)"
        />
      }
    } @else if (attachments().document; as doc) {
      <div class="mb-2 flex min-w-0 items-center gap-1.5 text-sm" data-document-header>
        <span aria-hidden="true">📄</span>
        <span class="min-w-0 truncate font-semibold text-text-primary" dir="auto">{{ doc.title }}</span>
        <span class="shrink-0 text-text-secondary">· {{ doc.pageCount | rdPlural: 'media.pageCount' : lang() }}</span>
      </div>
      @if (pages().length) {
        <rd-media-carousel
          [slides]="pages()"
          [aspectRatio]="pageRatio()"
          [total]="doc.pageCount"
          [label]="'media.documentLabel' | transloco: { title: doc.title }"
          [priority]="priority()"
          (opened)="openDocument(doc, $event)"
        />
      }
    }
  `,
})
export class ArticleAttachments {
  private readonly viewer = inject(MediaViewerService);
  private readonly content = inject(ContentApi);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  readonly attachments = input.required<ArticleAttachmentsDto>();
  readonly article = input.required<AttachmentsArticleRef>();
  /** The first visible image of the page loads eagerly. */
  readonly priority = input(false);

  protected readonly fullWidthSizes = FULL_WIDTH_SIZES;
  protected readonly slideSizes = SLIDE_SIZES;

  protected readonly images = computed(() => imageSlides(this.attachments().images ?? []));
  protected readonly singleRatio = computed(() => {
    const first = [...(this.attachments().images ?? [])].sort((a, b) => a.order - b.order)[0];
    return clampImageRatio(first?.width, first?.height);
  });
  protected readonly pages = computed(() => {
    const doc = this.attachments().document;
    return doc ? documentSlides(doc, (pageNo) => this.pageAlt(doc, pageNo)) : [];
  });
  protected readonly pageRatio = computed(() => documentRatio(this.attachments().document?.pages ?? []));

  protected openImages(index: number): void {
    const items = this.images();
    this.viewer.open({
      kind: 'images',
      title: this.article().title,
      items: signal(items),
      total: items.length,
      startIndex: index,
      document: null,
      share: this.shareTarget(),
    });
  }

  /** Feed cards carry the first 10 pages; the viewer loads the rest from the article when the document is longer. */
  protected openDocument(doc: DocumentAttachmentDto, index: number): void {
    const items = signal<MediaSlide[]>(this.pages().filter((s) => s.kind === 'page'));
    this.viewer.open({
      kind: 'document',
      title: doc.title,
      items,
      total: doc.pageCount,
      startIndex: index,
      document: { title: doc.title, canDownload: doc.canDownload, downloadUrl: doc.downloadUrl },
      share: this.shareTarget(),
    });
    if (items().length >= doc.pageCount) return;
    const { slug, language } = this.article();
    this.content.article(slug, language).subscribe({
      next: (full) => {
        const fullDoc = full.attachments?.document;
        if (fullDoc?.assetId === doc.assetId) {
          items.set(documentSlides(fullDoc, (pageNo) => this.pageAlt(fullDoc, pageNo)).filter((s) => s.kind === 'page'));
        }
      },
      error: () => undefined, // the loaded pages stay usable
    });
  }

  private pageAlt(doc: DocumentAttachmentDto, pageNo: number): string {
    const page = this.transloco.translate('media.pageOf', { current: pageNo, total: doc.pageCount }, this.lang());
    return `${doc.title}, ${page}`;
  }

  private shareTarget(): { title: string; url: string } {
    const { slug, language, title } = this.article();
    return { title, url: `${environment.siteUrl}/${urlLangFor(language)}/a/${encodeURIComponent(slug)}` };
  }
}
