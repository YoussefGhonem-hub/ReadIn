import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  PLATFORM_ID,
  afterRenderEffect,
  computed,
  inject,
  input,
  signal,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { HighlighterService } from '../highlighter.service';
import { codeLanguageLabel } from '../rdoc.utils';

/**
 * Code body + header with filename and copy button. Always LTR (SPEC §14.2 rule 3).
 * The server and first client render show plain lines (hydration-safe); Shiki swaps in highlighted HTML afterwards.
 */
@Component({
  selector: 'rd-code-view',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'rd-code', dir: 'ltr', '[attr.data-lang]': 'lang()' },
  template: `
    @if (showHeader()) {
      <div class="rd-code-head">
        <span>
          {{ label() }}
          @if (filename()) {
            <span aria-hidden="true"> · </span><span>{{ filename() }}</span>
          }
        </span>
        <button type="button" class="rd-code-copy" (click)="copy()" [attr.aria-label]="'rdoc.copyCode' | transloco">
          @if (copied()) {
            <svg lucideIcon="Check" [size]="14"></svg> {{ 'rdoc.copied' | transloco }}
          } @else {
            <svg lucideIcon="Copy" [size]="14"></svg> {{ 'rdoc.copy' | transloco }}
          }
        </button>
      </div>
    }
    @if (html(); as highlighted) {
      <div [innerHTML]="highlighted"></div>
    } @else {
      <pre><code>@for (line of lines(); track $index) {<span class="line" [class.highlighted]="isHighlighted($index + 1)">{{ line }}</span>}</code></pre>
    }
  `,
})
export class CodeView {
  private readonly highlighter = inject(HighlighterService);
  private readonly sanitizer = inject(DomSanitizer);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  readonly code = input.required<string>();
  readonly lang = input.required<string>();
  readonly filename = input<string | undefined>();
  readonly highlightLines = input<number[] | undefined>();
  readonly showHeader = input(true);

  protected readonly label = computed(() => codeLanguageLabel(this.lang()));
  protected readonly lines = computed(() => this.code().replace(/\r\n/g, '\n').split('\n'));
  protected readonly html = signal<SafeHtml | null>(null);
  protected readonly copied = signal(false);
  private readonly marked = computed(() => new Set(this.highlightLines() ?? []));

  constructor() {
    let version = 0;
    afterRenderEffect(() => {
      const code = this.code();
      const lang = this.lang();
      const lines = this.highlightLines() ?? [];
      const current = ++version;
      void this.highlighter.highlight(code, lang, lines).then((result) => {
        // Shiki escapes the source text; the markup is generated, never user HTML.
        if (current === version) this.html.set(result ? this.sanitizer.bypassSecurityTrustHtml(result) : null);
      });
    });
    inject(DestroyRef).onDestroy(() => clearTimeout(this.copyTimer));
  }

  private copyTimer: ReturnType<typeof setTimeout> | undefined;

  protected isHighlighted(line: number): boolean {
    return this.marked().has(line);
  }

  protected async copy(): Promise<void> {
    if (!this.isBrowser) return;
    try {
      await navigator.clipboard.writeText(this.code());
      this.copied.set(true);
      clearTimeout(this.copyTimer);
      this.copyTimer = setTimeout(() => this.copied.set(false), 2000);
    } catch {
      /* clipboard blocked: nothing to do */
    }
  }
}
