import { ChangeDetectionStrategy, Component, DestroyRef, inject, input, output, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { ImageUploader, largestVariant } from './image-upload';

const IMAGE_ACCEPT = 'image/jpeg,image/png,image/webp,image/heic,image/heif,.heic,.heif';

/**
 * Cover image (F05): compressed on the device, uploaded with `purpose=cover`, stored in the draft as the absolute URL
 * of its widest rendition. Shows progress with cancel; `uploadingChange` keeps Publish disabled meanwhile.
 */
@Component({
  selector: 'rd-cover-picker',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <span class="rd-label" id="rd-cover-label">{{ 'editor.meta.cover' | transloco }}</span>
    <div class="overflow-hidden rounded-md border border-border bg-surface" data-cover>
      @if (url(); as src) {
        <img [src]="src" alt="" class="rd-photo block w-full object-cover" style="aspect-ratio: 1200 / 630" data-cover-image />
      }
      @if (progress() !== null) {
        <div class="flex items-center gap-2 p-3 text-xs" data-cover-uploading>
          <span class="min-w-0 flex-1">{{ 'attachments.uploading' | transloco: { percent: percent() } }}</span>
          <button type="button" class="font-semibold text-primary underline" (click)="cancel()">{{ 'attachments.cancel' | transloco }}</button>
        </div>
        <span class="block h-1 bg-surface-variant" role="progressbar" aria-valuemin="0" aria-valuemax="100" [attr.aria-valuenow]="percent()" aria-labelledby="rd-cover-label">
          <span class="block h-full bg-primary" [style.width.%]="percent()"></span>
        </span>
      } @else {
        <div class="flex flex-wrap gap-2 p-2">
          <button type="button" class="rd-btn rd-btn-outline min-h-9 flex-1 px-3 text-sm" aria-describedby="rd-cover-hint" data-cover-choose (click)="coverInput.click()">
            <svg lucideIcon="Camera" [size]="16" aria-hidden="true"></svg>
            {{ (url() ? 'editor.meta.coverReplace' : 'editor.meta.coverChoose') | transloco }}
          </button>
          @if (url()) {
            <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm" data-cover-remove (click)="urlChange.emit(null)">{{ 'editor.meta.coverRemove' | transloco }}</button>
          }
        </div>
      }
    </div>
    <input #coverInput type="file" class="hidden" [accept]="accept" tabindex="-1" aria-hidden="true" data-cover-input (change)="onPicked($event)" />
    @if (error(); as message) {
      <p class="rd-field-error" role="alert">{{ message }}</p>
    }
    <p id="rd-cover-hint" class="rd-field-hint">{{ 'editor.meta.coverHint' | transloco }}</p>
  `,
})
export class CoverPicker {
  private readonly uploader = inject(ImageUploader);
  private readonly errors = inject(ErrorMessages);

  readonly url = input<string | null>(null);
  readonly urlChange = output<string | null>();
  readonly uploadingChange = output<boolean>();

  protected readonly accept = IMAGE_ACCEPT;
  protected readonly progress = signal<number | null>(null);
  protected readonly error = signal<string | null>(null);

  private controller: AbortController | null = null;

  constructor() {
    inject(DestroyRef).onDestroy(() => this.controller?.abort());
  }

  protected percent(): number {
    return Math.round((this.progress() ?? 0) * 100);
  }

  protected onPicked(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (file) void this.upload(file);
  }

  /** Uploads a picked file (also used by tests). */
  async upload(file: File): Promise<void> {
    this.controller?.abort();
    const controller = new AbortController();
    this.controller = controller;
    this.error.set(null);
    this.progress.set(0);
    this.uploadingChange.emit(true);
    try {
      const asset = await this.uploader.upload(file, 'cover', (p) => this.progress.set(p), controller.signal);
      if (this.controller === controller) this.urlChange.emit(largestVariant(asset)!.url);
    } catch (code) {
      if (this.controller === controller && !controller.signal.aborted) this.error.set(this.errors.forCode(String(code)));
    } finally {
      if (this.controller === controller) {
        this.controller = null;
        this.progress.set(null);
        this.uploadingChange.emit(false);
      }
    }
  }

  protected cancel(): void {
    const controller = this.controller;
    this.controller = null;
    controller?.abort();
    this.progress.set(null);
    this.uploadingChange.emit(false);
  }
}
