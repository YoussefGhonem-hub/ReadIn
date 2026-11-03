import { ChangeDetectionStrategy, Component, ElementRef, Injector, afterNextRender, computed, inject, input, signal, viewChild } from '@angular/core';
import { CdkDrag, CdkDragDrop, CdkDragHandle, CdkDropList } from '@angular/cdk/drag-drop';
import { Dir } from '@angular/cdk/bidi';
import { LiveAnnouncer } from '@angular/cdk/a11y';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { MediaImage } from '../../shared/media/media-image';
import { PAGE_THUMB_WIDTH } from '../../shared/media/media-slides';
import { PluralPipe } from '../../shared/pipes/format.pipes';
import { ALT_TEXT_MAX, AttachmentDraft, CAPTION_MAX, DOCUMENT_TITLE_MAX, DraftImage, MAX_IMAGES, UploadStatus } from './attachment-draft';

const IMAGE_ACCEPT = 'image/jpeg,image/png,image/webp,image/heic,image/heif,.heic,.heif';
const PREVIEW_PAGES = 4;

/**
 * Attachment bar (F26) for the composer and, later, the block editor: "📷 Images" (up to 10, reorder by drag or
 * keyboard, alt text required, optional caption) or "📄 PDF document" (title, allow download, processing preview).
 * Every upload shows progress with cancel and retry. State lives in the host-provided {@link AttachmentDraft}.
 */
@Component({
  selector: 'rd-attachment-bar',
  imports: [TranslocoPipe, LucideDynamicIcon, CdkDropList, CdkDrag, CdkDragHandle, Dir, MediaImage, PluralPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <section [attr.aria-label]="'attachments.label' | transloco">
      <div class="flex flex-wrap items-center gap-2">
        <button
          type="button"
          class="rd-btn rd-btn-outline min-h-10 px-3 text-sm text-text-primary"
          [disabled]="!draft().canAddImages()"
          [attr.aria-describedby]="imagesHint() ? 'rd-attach-images-hint' : null"
          data-add-images
          (click)="imageInput.click()"
        >
          <span aria-hidden="true">📷</span> {{ 'attachments.images' | transloco }}
        </button>
        <button
          type="button"
          class="rd-btn rd-btn-outline min-h-10 px-3 text-sm text-text-primary"
          [disabled]="!draft().canAddDocument()"
          [attr.aria-describedby]="pdfHint() ? 'rd-attach-pdf-hint' : null"
          data-add-pdf
          (click)="pdfInput.click()"
        >
          <span aria-hidden="true">📄</span> {{ 'attachments.pdf' | transloco }}
        </button>
        @if (draft().images().length) {
          <span class="text-xs text-text-secondary" data-image-count>{{ 'attachments.imageCount' | transloco: { count: draft().images().length } }}</span>
        }
        <input
          #imageInput
          type="file"
          class="hidden"
          multiple
          [accept]="imageAccept"
          tabindex="-1"
          aria-hidden="true"
          data-image-input
          (change)="onImagesPicked($event)"
        />
        <input #pdfInput type="file" class="hidden" accept="application/pdf,.pdf" tabindex="-1" aria-hidden="true" data-pdf-input (change)="onPdfPicked($event)" />
      </div>
      @if (imagesHint(); as hint) {
        <p id="rd-attach-images-hint" class="m-0 mt-1 text-xs text-text-secondary" data-images-hint>{{ hint | transloco }}</p>
      }
      @if (pdfHint(); as hint) {
        <p id="rd-attach-pdf-hint" class="m-0 mt-1 text-xs text-text-secondary" data-pdf-hint>{{ hint | transloco }}</p>
      }
      @if (message(); as text) {
        <p class="m-0 mt-2 rounded-md bg-callout-warning p-2 text-sm" role="alert" dir="auto">{{ text }}</p>
      }

      @if (draft().images().length) {
        <p class="m-0 mt-3 text-xs text-text-secondary">{{ 'attachments.dragHint' | transloco }}</p>
        <ol
          cdkDropList
          cdkDropListOrientation="mixed"
          [dir]="dir()"
          class="mt-2 grid list-none grid-cols-2 gap-3 p-0 sm:grid-cols-3"
          data-image-list
          (cdkDropListDropped)="onDrop($event)"
        >
          @for (image of draft().images(); track image.id; let i = $index; let last = $last) {
            <li cdkDrag [cdkDragData]="image.id" class="flex flex-col overflow-hidden rounded-md border border-border bg-surface" [attr.data-image-id]="image.id" data-image-item>
              <div class="relative aspect-square cursor-grab bg-surface-variant" cdkDragHandle>
                @if (image.asset?.variants?.length) {
                  <rd-media-image class="absolute inset-0" [variants]="image.asset!.variants" sizes="220px" [blurHash]="image.asset!.blurHash" />
                } @else if (image.previewUrl) {
                  <img [src]="image.previewUrl" alt="" class="absolute inset-0 h-full w-full object-cover" draggable="false" />
                }
                <span class="absolute start-2 top-2 rounded-chip bg-code-bg/80 px-2 text-xs font-semibold text-code-text" dir="ltr">{{ i + 1 }}</span>
                <button
                  type="button"
                  class="absolute end-1.5 top-1.5 grid h-8 w-8 place-items-center rounded-chip bg-code-bg/80 text-code-text"
                  [attr.aria-label]="'attachments.removeImage' | transloco: { position: i + 1 }"
                  data-remove-image
                  (click)="draft().removeImage(image.id)"
                >
                  <svg lucideIcon="X" [size]="16" aria-hidden="true"></svg>
                </button>
                @if (image.status !== 'ready') {
                  <div class="absolute inset-x-0 bottom-0 flex flex-col gap-1 bg-code-bg/85 p-2 text-xs text-code-text" [attr.data-status]="image.status">
                    @switch (image.status) {
                      @case ('failed') {
                        <span class="font-semibold" role="alert">{{ 'attachments.failed' | transloco }}: {{ errorText(image.errorCode) }}</span>
                      }
                      @case ('canceled') {
                        <span class="font-semibold">{{ 'attachments.canceled' | transloco }}</span>
                      }
                      @default {
                        <span>{{ statusText(image.status, image.progress) }}</span>
                        <span
                          class="block h-1 overflow-hidden rounded-chip bg-code-text/25"
                          role="progressbar"
                          aria-valuemin="0"
                          aria-valuemax="100"
                          [attr.aria-valuenow]="image.status === 'compressing' ? null : percent(image.progress)"
                          [attr.aria-label]="'attachments.image' | transloco: { position: i + 1 }"
                        >
                          <span class="block h-full bg-primary" [style.width.%]="image.status === 'compressing' ? 15 : percent(image.progress)"></span>
                        </span>
                      }
                    }
                    <span class="flex gap-2">
                      @if (image.status === 'compressing' || image.status === 'uploading') {
                        <button type="button" class="font-semibold underline underline-offset-2" data-cancel (click)="draft().cancelImage(image.id)">
                          {{ 'attachments.cancel' | transloco }}
                        </button>
                      } @else {
                        <button type="button" class="font-semibold underline underline-offset-2" data-retry (click)="draft().retryImage(image.id)">
                          {{ 'attachments.retry' | transloco }}
                        </button>
                      }
                    </span>
                  </div>
                }
              </div>
              <div class="flex flex-col gap-2 p-2">
                <div>
                  <label class="mb-1 block text-xs font-semibold" [attr.for]="'rd-alt-' + image.id">{{ 'attachments.altLabel' | transloco }} *</label>
                  <input
                    class="rd-input min-h-9 text-sm"
                    [id]="'rd-alt-' + image.id"
                    dir="auto"
                    required
                    [maxLength]="altMax"
                    [value]="image.altText"
                    [placeholder]="'attachments.altPlaceholder' | transloco"
                    [attr.aria-invalid]="!image.altText.trim()"
                    [attr.aria-describedby]="!image.altText.trim() ? 'rd-alt-error-' + image.id : null"
                    data-alt
                    (input)="draft().setAltText(image.id, valueOf($event))"
                  />
                  @if (!image.altText.trim()) {
                    <p class="m-0 mt-1 text-xs text-error" [id]="'rd-alt-error-' + image.id">{{ 'attachments.altRequired' | transloco }}</p>
                  }
                </div>
                <div>
                  <label class="mb-1 block text-xs font-semibold" [attr.for]="'rd-caption-' + image.id">{{ 'attachments.captionLabel' | transloco }}</label>
                  <input
                    class="rd-input min-h-9 text-sm"
                    [id]="'rd-caption-' + image.id"
                    dir="auto"
                    [maxLength]="captionMax"
                    [value]="image.caption"
                    [attr.aria-describedby]="'rd-caption-count-' + image.id"
                    data-caption
                    (input)="draft().setCaption(image.id, valueOf($event))"
                  />
                  <p class="m-0 mt-1 text-end text-xs text-text-secondary tabular-nums" [id]="'rd-caption-count-' + image.id" dir="ltr">
                    {{ image.caption.length }}/{{ captionMax }}
                  </p>
                </div>
                <div class="flex justify-between gap-2">
                  <button
                    type="button"
                    class="rd-icon-btn h-8 w-8"
                    [disabled]="i === 0"
                    [attr.aria-label]="'attachments.moveEarlier' | transloco: { position: i + 1 }"
                    data-move="earlier"
                    (click)="move(image, i, i - 1)"
                  >
                    <svg lucideIcon="ChevronLeft" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
                  </button>
                  <button
                    type="button"
                    class="rd-icon-btn h-8 w-8"
                    [disabled]="last"
                    [attr.aria-label]="'attachments.moveLater' | transloco: { position: i + 1 }"
                    data-move="later"
                    (click)="move(image, i, i + 1)"
                  >
                    <svg lucideIcon="ChevronRight" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
                  </button>
                </div>
              </div>
            </li>
          }
        </ol>
      }

      @if (draft().document(); as doc) {
        <div class="mt-3 rounded-md border border-border bg-surface p-3" data-document [attr.data-status]="doc.status">
          <div class="flex items-start gap-3">
            <span class="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-primary-container text-on-primary-container" aria-hidden="true">
              <svg lucideIcon="FileText" [size]="20"></svg>
            </span>
            <div class="min-w-0 flex-1">
              <label class="mb-1 block text-xs font-semibold" for="rd-doc-title">{{ 'attachments.docTitle' | transloco }} *</label>
              <input
                id="rd-doc-title"
                class="rd-input min-h-9 text-sm"
                dir="auto"
                required
                [maxLength]="docTitleMax"
                [value]="doc.title"
                [attr.aria-invalid]="!doc.title.trim()"
                data-doc-title
                (input)="draft().setDocumentTitle(valueOf($event))"
              />
              <p class="m-0 mt-1 truncate text-xs text-text-secondary" dir="ltr">{{ doc.file.name }} · {{ fileSize(doc.file.size) }}</p>
            </div>
            <button type="button" class="rd-icon-btn h-9 w-9 shrink-0" [attr.aria-label]="'attachments.removeDocument' | transloco" data-remove-document (click)="draft().removeDocument()">
              <svg lucideIcon="X" [size]="16" aria-hidden="true"></svg>
            </button>
          </div>

          <div class="mt-3" aria-live="polite">
            @switch (doc.status) {
              @case ('uploading') {
                <div class="flex items-center gap-3 text-sm">
                  <span class="min-w-0 flex-1">{{ statusText('uploading', doc.progress) }}</span>
                  <button type="button" class="font-semibold text-primary underline underline-offset-2" data-cancel (click)="draft().cancelDocument()">
                    {{ 'attachments.cancel' | transloco }}
                  </button>
                </div>
                <span class="mt-2 block h-1.5 overflow-hidden rounded-chip bg-surface-variant" role="progressbar" aria-valuemin="0" aria-valuemax="100" [attr.aria-valuenow]="percent(doc.progress)">
                  <span class="block h-full bg-primary" [style.width.%]="percent(doc.progress)"></span>
                </span>
              }
              @case ('processing') {
                <p class="m-0 inline-flex items-center gap-2 text-sm font-semibold" data-processing>
                  <svg lucideIcon="LoaderCircle" [size]="16" class="animate-spin text-primary" aria-hidden="true"></svg>
                  {{ 'attachments.processing' | transloco }}
                </p>
                @if (doc.asset?.pageCount; as total) {
                  <p class="m-0 mt-1 text-xs text-text-secondary">{{ 'attachments.processingProgress' | transloco: { ready: doc.asset!.pagesReady, total: total } }}</p>
                  <span class="mt-2 block h-1.5 overflow-hidden rounded-chip bg-surface-variant" role="progressbar" aria-valuemin="0" [attr.aria-valuemax]="total" [attr.aria-valuenow]="doc.asset!.pagesReady">
                    <span class="block h-full bg-primary" [style.width.%]="(doc.asset!.pagesReady / total) * 100"></span>
                  </span>
                }
              }
              @case ('ready') {
                <p class="m-0 text-sm text-text-secondary" data-ready>
                  <svg lucideIcon="CircleCheck" [size]="14" class="inline text-success" aria-hidden="true"></svg>
                  {{ doc.asset?.pageCount ?? 0 | rdPlural: 'media.pageCount' : lang() }}
                </p>
              }
              @default {
                <p class="m-0 text-sm text-error" role="alert" data-doc-error>
                  {{ doc.status === 'canceled' ? ('attachments.canceled' | transloco) : errorText(doc.errorCode) }}
                </p>
                <div class="mt-2 flex gap-2">
                  <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" (click)="draft().removeDocument()">{{ 'common.remove' | transloco }}</button>
                  <button type="button" class="rd-btn rd-btn-primary min-h-9 px-3 text-sm" data-retry (click)="draft().retryDocument()">
                    {{ 'attachments.retry' | transloco }}
                  </button>
                </div>
              }
            }
          </div>

          @if (previewPages().length) {
            <ul class="mt-3 flex list-none gap-2 overflow-x-auto p-0" [attr.aria-label]="'attachments.docPreview' | transloco" data-doc-preview>
              @for (page of previewPages(); track page.pageNo) {
                <li class="w-20 shrink-0 overflow-hidden rounded-sm border border-border" [style.aspect-ratio]="page.width + ' / ' + page.height">
                  <rd-media-image class="h-full w-full" [variants]="[{ width: thumbWidth, url: page.thumbUrl }]" sizes="80px" [blurHash]="page.blurHash" [ratio]="page.width / page.height" [alt]="'media.pageOf' | transloco: { current: page.pageNo, total: doc.asset?.pageCount ?? 0 }" />
                </li>
              }
            </ul>
          }

          <label class="mt-3 flex cursor-pointer items-start gap-3 border-t border-border pt-3">
            <input type="checkbox" role="switch" class="mt-1 h-4 w-4 accent-primary" [checked]="doc.allowDownload" data-allow-download (change)="draft().setAllowDownload(checkedOf($event))" />
            <span>
              <span class="block text-sm font-semibold">{{ 'attachments.allowDownload' | transloco }}</span>
              <span class="block text-xs text-text-secondary">{{ 'attachments.allowDownloadHint' | transloco }}</span>
            </span>
          </label>
        </div>
      }
    </section>
  `,
})
export class AttachmentBar {
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);
  private readonly announcer = inject(LiveAnnouncer);
  private readonly injector = inject(Injector);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly language = inject(LanguageService);
  protected readonly lang = this.language.lang;
  protected readonly dir = this.language.dir;

  readonly draft = input.required<AttachmentDraft>();

  protected readonly imageAccept = IMAGE_ACCEPT;
  protected readonly altMax = ALT_TEXT_MAX;
  protected readonly captionMax = CAPTION_MAX;
  protected readonly docTitleMax = DOCUMENT_TITLE_MAX;
  protected readonly thumbWidth = PAGE_THUMB_WIDTH;
  protected readonly message = signal<string | null>(null);

  private readonly imageInput = viewChild.required<ElementRef<HTMLInputElement>>('imageInput');

  /** Why "Images" is disabled (a PDF is attached, or 10 images already). */
  protected readonly imagesHint = computed(() => {
    const draft = this.draft();
    if (draft.document()) return 'attachments.imagesDisabled';
    return draft.images().length >= MAX_IMAGES ? 'attachments.imagesFull' : null;
  });
  /** Why "PDF document" is disabled (images are attached). */
  protected readonly pdfHint = computed(() => (this.draft().images().length ? 'attachments.pdfDisabled' : null));
  protected readonly previewPages = computed(() => (this.draft().document()?.asset?.pages ?? []).slice(0, PREVIEW_PAGES));

  /** Adds picked images (also used by tests and drag-and-drop from the desktop). */
  addImages(files: readonly File[]): void {
    const result = this.draft().addImages(files);
    const notes: string[] = [];
    if (result.unsupported.length) notes.push(this.transloco.translate('attachments.unsupportedImage', { name: result.unsupported.join(', ') }));
    if (result.skipped) notes.push(this.transloco.translate('attachments.tooManyImages', { count: result.skipped }));
    this.message.set(notes.length ? notes.join(' ') : null);
  }

  addDocument(file: File): void {
    const refusal = this.draft().setDocument(file);
    this.message.set(refusal ? this.transloco.translate(refusal) : null);
  }

  protected onImagesPicked(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.addImages(Array.from(input.files ?? []));
    input.value = ''; // picking the same file again still fires `change`
  }

  protected onPdfPicked(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (file) this.addDocument(file);
    input.value = '';
  }

  protected onDrop(event: CdkDragDrop<unknown>): void {
    if (event.previousIndex === event.currentIndex) return;
    this.draft().moveImage(event.previousIndex, event.currentIndex);
    this.announceMove(event.currentIndex);
  }

  /** Keyboard reorder: moves the image and keeps focus on the same control of the moved card. */
  protected move(image: DraftImage, from: number, to: number): void {
    this.draft().moveImage(from, to);
    this.announceMove(to);
    const direction = to < from ? 'earlier' : 'later';
    afterNextRender(
      () => {
        const card = this.host.nativeElement.querySelector(`[data-image-id="${image.id}"]`);
        const same = card?.querySelector<HTMLButtonElement>(`[data-move="${direction}"]`);
        const other = card?.querySelector<HTMLButtonElement>(`[data-move="${direction === 'earlier' ? 'later' : 'earlier'}"]`);
        (same && !same.disabled ? same : other)?.focus();
      },
      { injector: this.injector },
    );
  }

  protected statusText(status: UploadStatus, progress: number): string {
    return status === 'compressing'
      ? this.transloco.translate('attachments.preparing')
      : this.transloco.translate('attachments.uploading', { percent: this.percent(progress) });
  }

  protected errorText(code: string | null): string {
    return this.errors.forCode(code ?? 'unknown');
  }

  protected percent(progress: number): number {
    return Math.round(Math.max(0, Math.min(1, progress)) * 100);
  }

  protected fileSize(bytes: number): string {
    return bytes < 1024 * 1024 ? `${Math.max(1, Math.round(bytes / 1024))} KB` : `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }

  protected valueOf(event: Event): string {
    return (event.target as HTMLInputElement).value;
  }

  protected checkedOf(event: Event): boolean {
    return (event.target as HTMLInputElement).checked;
  }

  /** Opens the image picker (hosts can call it from a toolbar). */
  pickImages(): void {
    this.imageInput().nativeElement.click();
  }

  private announceMove(index: number): void {
    const total = this.draft().images().length;
    void this.announcer.announce(this.transloco.translate('attachments.moved', { position: index + 1, total }), 'polite');
  }
}
