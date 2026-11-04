import { ChangeDetectionStrategy, Component, ElementRef, PLATFORM_ID, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ArticlePathDto } from '../../core/api/models';
import { PathsApi } from '../../core/api/paths.api';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { BdiText } from '../../shared/directives/bdi-text';
import { ArticleCard } from '../../shared/ui/article-card';
import { ProgressBar } from '../../shared/ui/progress-bar';
import { ToastService } from '../../shared/ui/toast/toast.service';

/** Start loading this far before the block scrolls into view (like the comments). */
const NEAR_VIEWPORT = '600px 0px';

/**
 * "Next in path" at the end of the reader (F04, F09): the path this article is in, "{position} of {total}" with your
 * progress, then the next article, or "the last article" with a 🎉 once the path is done; Join path when you're not
 * enrolled (guests get the sign-in prompt). `GET /articles/{id}/path` goes out when the block nears the viewport, in
 * the browser only; no path (204) or an error renders nothing.
 */
@Component({
  selector: 'rd-next-in-path',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, ArticleCard, ProgressBar],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block', 'data-next-in-path': '' },
  template: `
    @if (block(); as b) {
      <section class="rd-card mt-10 p-4 shadow-none" aria-labelledby="next-in-path-title" data-next-in-path-block>
        <div class="flex items-start gap-3">
          <span class="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-primary-container text-on-primary-container" aria-hidden="true">
            <svg lucideIcon="Route" [size]="20"></svg>
          </span>
          <div class="min-w-0 flex-1">
            <h2 id="next-in-path-title" class="m-0 text-base font-semibold">
              <span class="text-text-secondary">{{ 'paths.next.fromPath' | transloco }}</span>
              {{ ' ' }}<a [routerLink]="['/paths', b.path.slug]" class="text-primary no-underline hover:underline" data-next-path-link><rd-bdi-text [text]="b.path.title" /></a>
            </h2>
            <p class="m-0 mt-0.5 text-xs text-text-secondary" data-next-position>{{ 'paths.next.position' | transloco: { position: b.position, total: b.total } }}</p>
          </div>
          @if (!b.path.enrollment) {
            <button type="button" class="rd-btn rd-btn-outline min-h-11 shrink-0 px-3 text-sm" [disabled]="joining()" [attr.aria-busy]="joining()" data-join-path (click)="join(b)">
              @if (joining()) {
                <svg lucideIcon="LoaderCircle" [size]="16" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ 'paths.next.join' | transloco }}
            </button>
          }
        </div>
        @if (b.path.progress; as progress) {
          <div class="mt-3 flex items-center gap-3" data-next-progress>
            <rd-progress-bar
              class="flex-1"
              [value]="progress.percent"
              [tone]="completed() ? 'success' : 'primary'"
              [label]="'paths.progressLabel' | transloco: { read: progress.readCount, total: progress.total }"
            />
            <span class="text-xs font-semibold text-text-secondary" dir="ltr" aria-hidden="true">{{
              'paths.progress' | transloco: { read: progress.readCount, total: progress.total }
            }}</span>
          </div>
        }
        @if (b.next; as next) {
          <h3 class="m-0 mt-4 text-sm font-semibold text-text-secondary">{{ 'paths.next.title' | transloco }}</h3>
          <rd-article-card [article]="next" data-next-article />
        } @else {
          <p class="m-0 mt-4 text-sm" data-next-last>{{ 'paths.next.last' | transloco }}</p>
          @if (completed()) {
            <p class="m-0 mt-2 inline-flex rounded-md bg-success/15 px-3 py-1.5 text-sm font-semibold text-success" role="status" data-next-completed>
              {{ 'paths.next.completed' | transloco }}
            </p>
          }
        }
      </section>
    }
  `,
})
export class NextInPath {
  private readonly api = inject(PathsApi);
  private readonly prompt = inject(AuthPromptService);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  readonly articleId = input.required<string>();

  protected readonly block = signal<ArticlePathDto | null>(null);
  protected readonly joining = signal(false);
  /** Done: finished while enrolled, or every article read. */
  protected readonly completed = computed(() => {
    const path = this.block()?.path;
    return !!path?.enrollment?.completedAt || (!!path?.progress && path.progress.readCount >= path.progress.total);
  });
  private generation = 0;

  constructor() {
    const isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
    // A new article (the reader is reused between articles) starts over, and loads once the block nears the viewport.
    effect((onCleanup) => {
      const id = this.articleId();
      untracked(() => this.block.set(null));
      if (!isBrowser || typeof IntersectionObserver === 'undefined') return;
      const observer = new IntersectionObserver(
        (entries) => {
          if (!entries.some((e) => e.isIntersecting)) return;
          observer.disconnect();
          void this.load(id);
        },
        { rootMargin: NEAR_VIEWPORT },
      );
      observer.observe(this.host.nativeElement);
      onCleanup(() => observer.disconnect());
    });
  }

  /** Join path (`PUT /me/paths/{id}`), then the block again with your progress. Guests get the sign-in prompt. */
  protected async join(block: ArticlePathDto): Promise<void> {
    if (this.joining() || !this.prompt.requireAuth()) return;
    this.joining.set(true);
    try {
      await firstValueFrom(this.api.enroll(block.path.id));
      this.toasts.success(this.transloco.translate('paths.joined'));
      await this.load(this.articleId());
    } catch (error) {
      this.toasts.error(this.errors.forError(error));
    } finally {
      this.joining.set(false);
    }
  }

  private async load(articleId: string): Promise<void> {
    const generation = ++this.generation;
    try {
      const block = await firstValueFrom(this.api.articlePath(articleId));
      if (generation === this.generation && articleId === this.articleId()) this.block.set(block);
    } catch {
      // Optional block: nothing to show.
    }
  }
}
