import { ChangeDetectionStrategy, Component, DestroyRef, PLATFORM_ID, computed, effect, inject, input, output, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { SupportAttachmentDto, SupportDeviceDto, SupportStatus, UiLanguage } from '../../core/api/models';
import { SupportApi } from '../../core/api/support.api';
import { LanguageService } from '../../core/i18n/language.service';
import { FileSizePipe } from '../../shared/pipes/format.pipes';
import { translatePlural } from '../../shared/pipes/intl';

/** Contract defaults (F35); `GET /support/config` repeats them. */
export const MAX_SCREENSHOTS = 3;
export const MAX_SCREENSHOT_BYTES = 5 * 1024 * 1024;
export const SUBJECT_MIN = 5;
export const SUBJECT_MAX = 120;
export const MESSAGE_MIN = 10;
export const MESSAGE_MAX = 2000;

export type ScreenshotProblem = 'type' | 'size' | 'empty';

/** What the file is by its first bytes (JPEG, PNG or WebP), never by its name or `type`; null for anything else. */
export function imageKind(bytes: Uint8Array): 'image/jpeg' | 'image/png' | 'image/webp' | null {
  const at = (i: number, ...values: number[]) => values.every((v, k) => bytes[i + k] === v);
  if (at(0, 0xff, 0xd8, 0xff)) return 'image/jpeg';
  if (at(0, 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)) return 'image/png';
  if (at(0, 0x52, 0x49, 0x46, 0x46) && at(8, 0x57, 0x45, 0x42, 0x50)) return 'image/webp';
  return null;
}

async function head(file: Blob, length: number): Promise<Uint8Array> {
  const part = file.slice(0, length);
  if (typeof part.arrayBuffer === 'function') return new Uint8Array(await part.arrayBuffer());
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(new Uint8Array(reader.result as ArrayBuffer));
    reader.onerror = () => reject(reader.error);
    reader.readAsArrayBuffer(part);
  });
}

/** Checks a screenshot in the browser the way the API does (F35): not empty, ≤ 5 MB, JPEG/PNG/WebP by its bytes. */
export async function checkScreenshot(file: File, maxBytes = MAX_SCREENSHOT_BYTES): Promise<ScreenshotProblem | null> {
  if (file.size === 0) return 'empty';
  if (file.size > maxBytes) return 'size';
  return imageKind(await head(file, 12)) ? null : 'type';
}

/** "Windows · Chrome 131", "Android 15 · Samsung Internet 27", "iOS 18.1 · Safari 18": no device identifier. */
export function browserSummary(ua: string): string {
  const android = /Android (\d+(?:\.\d+)?)/.exec(ua);
  const ios = /(?:iPhone|iPad|iPod).*? OS (\d+)[_.](\d+)/.exec(ua);
  const os = android
    ? `Android ${android[1]}`
    : ios
      ? `iOS ${ios[1]}.${ios[2]}`
      : /Windows/.test(ua)
        ? 'Windows'
        : /CrOS/.test(ua)
          ? 'ChromeOS'
          : /Mac OS X|Macintosh/.test(ua)
            ? 'macOS'
            : /Linux/.test(ua)
              ? 'Linux'
              : 'Other';
  const match = (re: RegExp) => re.exec(ua)?.[1];
  let browser: string;
  if (match(/Edg(?:e|A|iOS)?\/(\d+)/)) browser = `Edge ${match(/Edg(?:e|A|iOS)?\/(\d+)/)}`;
  else if (match(/OPR\/(\d+)/)) browser = `Opera ${match(/OPR\/(\d+)/)}`;
  else if (match(/SamsungBrowser\/(\d+)/)) browser = `Samsung Internet ${match(/SamsungBrowser\/(\d+)/)}`;
  else if (match(/(?:Firefox|FxiOS)\/(\d+)/)) browser = `Firefox ${match(/(?:Firefox|FxiOS)\/(\d+)/)}`;
  else if (match(/(?:Chrome|CriOS)\/(\d+)/)) browser = `Chrome ${match(/(?:Chrome|CriOS)\/(\d+)/)}`;
  else if (match(/Version\/(\d+(?:\.\d+)?).*Safari/)) browser = `Safari ${match(/Version\/(\d+(?:\.\d+)?).*Safari/)}`;
  else browser = 'Other';
  return `${os} · ${browser}`.slice(0, 60);
}

/**
 * What the web adds to a ticket (contract decision 10): `platform: "web"`, the browser and OS, the UI language and the
 * screen it came from. The web has no build number, so `appVersion` stays empty. No device identifier.
 */
export function webDevice(language: UiLanguage, screen: string | null, ua = typeof navigator === 'undefined' ? '' : navigator.userAgent): Partial<SupportDeviceDto> {
  return { platform: 'web', osVersion: browserSummary(ua), language, screen: screen ? screen.split(/[?#]/)[0].slice(0, 100) : null };
}

/** Open / Answered / Closed as a small tag. */
@Component({
  selector: 'rd-ticket-status',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'inline-flex', '[attr.data-ticket-status]': 'status()' },
  template: `
    <span class="rd-tag" [class]="tone()">{{ 'support.statuses.' + status() | transloco }}</span>
  `,
})
export class TicketStatus {
  readonly status = input.required<SupportStatus>();
  protected readonly tone = computed(() => {
    switch (this.status()) {
      case 'open':
        return 'bg-callout-warning text-text-primary';
      case 'answered':
        return 'rd-tag-accent';
      default:
        return 'rd-tag-neutral';
    }
  });
}

/**
 * Up to 3 screenshots for a ticket or a reply (F35): JPEG, PNG or WebP of 5 MB at most, checked here by their bytes as
 * the API does, so a wrong file is named before anything is sent. Each picked file can be removed.
 */
@Component({
  selector: 'rd-screenshot-picker',
  imports: [TranslocoPipe, LucideDynamicIcon, FileSizePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col gap-2', 'data-screenshot-picker': '' },
  template: `
    @if (files().length) {
      <ul class="m-0 flex list-none flex-col gap-1 p-0" data-screenshots>
        @for (file of files(); track $index) {
          <li class="flex items-center gap-2 rounded-md bg-surface-variant px-3 py-1.5 text-sm" [attr.data-screenshot]="$index">
            <svg lucideIcon="Images" [size]="16" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
            <bdi dir="auto" class="min-w-0 flex-1 truncate">{{ file.name }}</bdi>
            <span class="shrink-0 text-xs text-text-secondary">{{ file.size | rdFileSize: lang() }}</span>
            <button type="button" class="rd-icon-btn h-9 w-9" [disabled]="disabled()" [attr.aria-label]="'support.removeScreenshot' | transloco: { name: file.name }" (click)="remove($index)" data-screenshot-remove>
              <svg lucideIcon="X" [size]="14" aria-hidden="true"></svg>
            </button>
          </li>
        }
      </ul>
    }
    @if (files().length < max()) {
      <label class="rd-btn rd-btn-outline min-h-11 w-fit cursor-pointer gap-1.5 px-4 text-sm has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-focus-ring" [class.opacity-55]="disabled()">
        <svg lucideIcon="Camera" [size]="16" aria-hidden="true"></svg>
        {{ 'support.addScreenshots' | transloco }}
        <input type="file" class="sr-only" accept="image/jpeg,image/png,image/webp" multiple [disabled]="disabled()" (change)="pick($any($event.target))" data-screenshot-input />
      </label>
    }
    <p class="m-0 text-xs text-text-secondary">{{ hint() }}</p>
    @if (problem()) {
      <p class="rd-field-error m-0" role="alert" data-screenshot-error>{{ problem() }}</p>
    }
  `,
})
export class ScreenshotPicker {
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  readonly max = input(MAX_SCREENSHOTS);
  readonly maxBytes = input(MAX_SCREENSHOT_BYTES);
  readonly disabled = input(false);
  /** The picked files; the parent clears them by setting `[]` after a send. */
  readonly files = input<File[]>([]);
  readonly filesChange = output<File[]>();

  protected readonly problem = signal<string | null>(null);
  protected readonly hint = computed(() => {
    this.lang();
    return this.transloco.translate('support.screenshotsHint', { count: this.max(), size: Math.round(this.maxBytes() / (1024 * 1024)) });
  });

  protected async pick(input: HTMLInputElement): Promise<void> {
    const picked = Array.from(input.files ?? []);
    input.value = '';
    this.problem.set(null);
    const accepted: File[] = [];
    for (const file of picked) {
      if (this.files().length + accepted.length >= this.max()) {
        this.problem.set(translatePlural(this.transloco, 'support.tooManyScreenshots', this.max(), this.lang()));
        break;
      }
      const problem = await checkScreenshot(file, this.maxBytes());
      if (problem) {
        this.problem.set(this.transloco.translate(`support.screenshotProblem.${problem}`, { name: file.name }));
        continue;
      }
      accepted.push(file);
    }
    if (accepted.length) this.filesChange.emit([...this.files(), ...accepted]);
  }

  protected remove(index: number): void {
    this.problem.set(null);
    this.filesChange.emit(this.files().filter((_, i) => i !== index));
  }
}

/**
 * A message's screenshots (F35), fetched with the session as blobs (`GET /support/attachments/{id}`, never a public URL)
 * and shown as thumbnails that open the full image. The object URLs are revoked when the message leaves the screen.
 */
@Component({
  selector: 'rd-support-attachments',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-wrap gap-2', 'data-support-attachments': '' },
  template: `
    @for (a of attachments(); track a.id; let i = $index) {
      @let url = urls()[a.id];
      @if (url) {
        <a [href]="url" target="_blank" rel="noopener" class="block overflow-hidden rounded-md border border-border" [attr.data-attachment]="a.id">
          <img [src]="url" [alt]="'support.screenshotAlt' | transloco: { n: i + 1 }" class="block h-24 w-24 object-cover" />
        </a>
      } @else if (failed().has(a.id)) {
        <span class="grid h-24 w-24 place-items-center rounded-md border border-border text-xs text-text-secondary" [attr.data-attachment-failed]="a.id">
          {{ 'support.screenshotFailed' | transloco }}
        </span>
      } @else {
        <span class="rd-skeleton block h-24 w-24 rounded-md" aria-hidden="true"></span>
      }
    }
    @if (failed().size) {
      <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-xs" (click)="load()">
        <svg lucideIcon="RefreshCw" [size]="14" aria-hidden="true"></svg>{{ 'common.retry' | transloco }}
      </button>
    }
  `,
})
export class SupportAttachments {
  private readonly api = inject(SupportApi);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  readonly attachments = input.required<SupportAttachmentDto[]>();
  protected readonly urls = signal<Record<string, string>>({});
  protected readonly failed = signal<ReadonlySet<string>>(new Set());

  constructor() {
    effect(() => {
      this.attachments();
      untracked(() => void this.load());
    });
    inject(DestroyRef).onDestroy(() => {
      for (const url of Object.values(this.urls())) URL.revokeObjectURL(url);
    });
  }

  async load(): Promise<void> {
    if (!this.isBrowser) return;
    this.failed.set(new Set());
    await Promise.all(
      this.attachments()
        .filter((a) => !this.urls()[a.id])
        .map(async (a) => {
          try {
            const blob = await firstValueFrom(this.api.attachment(a.id, a.contentType));
            this.urls.update((urls) => ({ ...urls, [a.id]: URL.createObjectURL(blob) }));
          } catch {
            this.failed.update((set) => new Set([...set, a.id]));
          }
        }),
    );
  }
}
