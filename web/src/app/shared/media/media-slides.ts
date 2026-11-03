import { DocumentAttachmentDto, ImageAttachmentDto, MediaPageDto } from '../../core/api/models';
import { ImageVariant } from './variant-loader';

/** Single images keep their own shape within these bounds (portrait 4:5 … landscape 1.91:1), like LinkedIn. */
export const MIN_IMAGE_RATIO = 4 / 5;
export const MAX_IMAGE_RATIO = 1.91;
/** PDF page thumbnails (MediaPageDto.thumbUrl) are rendered 400 px wide. */
export const PAGE_THUMB_WIDTH = 400;
const PAGE_VIEW_WIDTH = 1080;

/** One carousel / viewer item, built from an image attachment or a rendered PDF page. */
export interface MediaSlide {
  key: string;
  kind: 'image' | 'page' | 'more';
  /** Files available for the carousel (smallest that fits is loaded). */
  variants: ImageVariant[];
  /** Files available for the full-screen viewer (the largest is loaded). */
  viewVariants: ImageVariant[];
  blurHash: string | null;
  alt: string;
  caption: string | null;
  /** The item's own width / height. */
  ratio: number;
  /** `more` slide: pages that are not in the DTO (feed cards carry the first 10). */
  moreCount?: number;
}

function ratioOf(width: number | null | undefined, height: number | null | undefined, fallback: number): number {
  return width && height && width > 0 && height > 0 ? width / height : fallback;
}

export function clampImageRatio(width: number | null | undefined, height: number | null | undefined): number {
  return Math.min(MAX_IMAGE_RATIO, Math.max(MIN_IMAGE_RATIO, ratioOf(width, height, 1)));
}

/** The document carousel takes the first page's shape (A4 portrait when unknown), within sane bounds. */
export function documentRatio(pages: readonly MediaPageDto[]): number {
  const first = pages[0];
  return Math.min(2, Math.max(0.5, ratioOf(first?.width, first?.height, 1 / Math.SQRT2)));
}

export function imageSlides(images: readonly ImageAttachmentDto[]): MediaSlide[] {
  return [...images]
    .sort((a, b) => a.order - b.order)
    .map((image) => ({
      key: image.assetId,
      kind: 'image' as const,
      variants: image.variants.map(({ width, url }) => ({ width, url })),
      viewVariants: image.variants.map(({ width, url }) => ({ width, url })),
      blurHash: image.blurHash,
      alt: image.altText,
      caption: image.caption?.trim() || null,
      ratio: ratioOf(image.width, image.height, 1),
    }));
}

export function pageSlide(page: MediaPageDto, alt: string): MediaSlide {
  const thumb = { width: PAGE_THUMB_WIDTH, url: page.thumbUrl };
  return {
    key: `page-${page.pageNo}`,
    kind: 'page',
    variants: [thumb],
    viewVariants: [thumb, { width: page.width > PAGE_THUMB_WIDTH ? page.width : PAGE_VIEW_WIDTH, url: page.viewUrl }],
    blurHash: page.blurHash,
    alt,
    caption: null,
    ratio: ratioOf(page.width, page.height, 1 / Math.SQRT2),
  };
}

/** Page slides plus a trailing "+N pages" card when the DTO carries fewer pages than the document has. */
export function documentSlides(document: DocumentAttachmentDto, pageAlt: (pageNo: number) => string): MediaSlide[] {
  const pages = [...document.pages].sort((a, b) => a.pageNo - b.pageNo);
  const slides = pages.map((page) => pageSlide(page, pageAlt(page.pageNo)));
  const more = document.pageCount - pages.length;
  if (more > 0) {
    slides.push({
      key: 'more',
      kind: 'more',
      variants: [],
      viewVariants: [],
      blurHash: pages.at(-1)?.blurHash ?? null,
      alt: '',
      caption: null,
      ratio: documentRatio(pages),
      moreCount: more,
    });
  }
  return slides;
}
