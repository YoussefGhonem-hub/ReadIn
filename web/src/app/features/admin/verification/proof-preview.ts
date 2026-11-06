import { ChangeDetectionStrategy, Component, DestroyRef, effect, inject, input, signal, untracked } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { Subscription } from 'rxjs';
import { isApiError } from '../../../core/api/api.config';
import { VerificationProofDto } from '../../../core/api/models';
import { VerificationApi } from '../../../core/api/verification.api';
import { LanguageService } from '../../../core/i18n/language.service';
import { FileSizePipe } from '../../../shared/pipes/format.pipes';

type ProofState = 'loading' | 'ready' | 'error' | 'gone';

/** How a proof is shown: images inline, PDFs in a new tab. */
export function proofKind(contentType: string): 'image' | 'pdf' | 'other' {
  const type = contentType.toLowerCase();
  if (type === 'image/jpeg' || type === 'image/png' || type === 'image/webp') return 'image';
  return type === 'application/pdf' ? 'pdf' : 'other';
}

/**
 * A request's proof file (F19) for the reviewing admin. The file has no public URL: it is fetched with the session
 * (`GET /admin/verification-requests/{id}/proof`) into an object URL, shown inline when it is an image and opened in a
 * new tab when it is a PDF. The object URL is revoked when the request changes and when the preview goes away.
 */
@Component({
  selector: 'rd-proof-preview',
  imports: [TranslocoPipe, LucideDynamicIcon, FileSizePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', '[attr.data-proof-state]': 'state()' },
  template: `
    @let p = proof();
    @switch (state()) {
      @case ('ready') {
        @if (kind() === 'image') {
          <a [href]="url()" target="_blank" rel="noopener noreferrer" class="block w-fit max-w-full" [attr.aria-label]="'verification.admin.proof.openImage' | transloco">
            <img [src]="url()" [alt]="'verification.admin.proof.alt' | transloco: { name: p.fileName }" class="block max-h-[420px] w-auto max-w-full rounded-md border border-border bg-surface-variant object-contain" data-proof-image />
          </a>
        }
        <div class="mt-2 flex items-center gap-3 rounded-md border border-border bg-surface px-3 py-2">
          <svg [lucideIcon]="kind() === 'image' ? 'Images' : 'FileText'" [size]="20" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
          <span class="min-w-0 flex-1">
            <bdi dir="auto" class="block truncate text-sm" data-proof-name>{{ p.fileName }}</bdi>
            <!-- "178 ك.ب" / "178 KB": Western digits, the unit in the UI language (and its direction) -->
            <span class="block text-xs text-text-secondary" data-proof-size>{{ p.sizeBytes | rdFileSize: lang() }}</span>
          </span>
          @if (url()) {
            <a [href]="url()" target="_blank" rel="noopener noreferrer" class="rd-btn rd-btn-outline min-h-10 shrink-0 gap-1.5 px-3 text-sm" data-proof-open>
              <svg lucideIcon="ExternalLink" [size]="16" aria-hidden="true"></svg>
              {{ (kind() === 'pdf' ? 'verification.admin.proof.openPdf' : 'verification.admin.proof.open') | transloco }}
            </a>
          } @else {
            <span class="shrink-0 text-xs text-text-secondary" data-proof-unsupported>{{ 'verification.admin.proof.unsupported' | transloco }}</span>
          }
        </div>
      }
      @case ('error') {
        <div class="flex flex-wrap items-center gap-3 rounded-md bg-callout-danger px-3 py-2 text-sm" role="alert" data-proof-error>
          <span class="flex-1">{{ 'verification.admin.proof.error' | transloco }}</span>
          <button type="button" class="font-semibold underline" (click)="load()">{{ 'common.retry' | transloco }}</button>
        </div>
      }
      @case ('gone') {
        <p class="m-0 rounded-md bg-surface-variant px-3 py-2 text-sm text-text-secondary" data-proof-gone>{{ 'verification.admin.proof.gone' | transloco }}</p>
      }
      @default {
        <div class="rd-skeleton h-40 w-full max-w-sm rounded-md" aria-busy="true" data-proof-loading>
          <span class="sr-only">{{ 'verification.admin.proof.loading' | transloco }}</span>
        </div>
      }
    }
  `,
})
export class ProofPreview {
  private readonly api = inject(VerificationApi);

  readonly requestId = input.required<string>();
  readonly proof = input.required<VerificationProofDto>();

  protected readonly state = signal<ProofState>('loading');
  protected readonly url = signal<string | null>(null);
  /** From the type the file was served with: anything but an image or a PDF is never opened (an object URL runs as this origin). */
  protected readonly kind = signal<'image' | 'pdf' | 'other'>('other');
  protected readonly lang = inject(LanguageService).lang;
  private subscription: Subscription | null = null;

  constructor() {
    effect(() => {
      this.requestId();
      untracked(() => this.load());
    });
    inject(DestroyRef).onDestroy(() => this.reset());
  }

  protected load(): void {
    this.reset();
    this.state.set('loading');
    this.subscription = this.api.proof(this.requestId(), this.proof().contentType).subscribe({
      next: (blob) => {
        const kind = proofKind(blob.type || this.proof().contentType);
        this.kind.set(kind);
        if (kind !== 'other') this.url.set(URL.createObjectURL(blob));
        this.state.set('ready');
      },
      error: (error: unknown) => this.state.set(isApiError(error) && error.status === 404 ? 'gone' : 'error'),
    });
  }

  private reset(): void {
    this.subscription?.unsubscribe();
    this.subscription = null;
    const url = this.url();
    if (url) URL.revokeObjectURL(url);
    this.url.set(null);
  }
}
