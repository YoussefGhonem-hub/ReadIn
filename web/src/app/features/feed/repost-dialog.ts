import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Injector,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { ArticleCardDto } from '../../core/api/models';
import { RepostsApi } from '../../core/api/reposts.api';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { AutoDir } from '../../shared/directives/auto-dir.directive';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { Avatar } from '../../shared/ui/avatar';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ToastService } from '../../shared/ui/toast/toast.service';

/** Your thoughts on a repost: at most this many characters after trimming (contract "Reposts → Caption"). */
export const REPOST_CAPTION_MAX_LENGTH = 500;

/** `new`: "أعد النشر مع رأيك" (not reposted yet). `edit`: "عدّل رأيك", prefilled from `GET /articles/{id}/repost`. */
export type RepostDialogMode = 'new' | 'edit';

/** What the dialog is open for. */
export interface RepostDialogRequest {
  article: ArticleCardDto;
  mode: RepostDialogMode;
}

type LoadStatus = 'ready' | 'loading' | 'error';

let nextDialogId = 0;

/** `field-sizing: content` grows the field in CSS; elsewhere (older Firefox) the dialog sets its height as you type. */
const SIZES_ITSELF = typeof CSS !== 'undefined' && typeof CSS.supports === 'function' && CSS.supports('field-sizing', 'content');

/**
 * "أعد النشر مع رأيك" / "عدّل رأيك" (F29): the caption dialog of the Repost menu, a centred dialog on wide screens and a
 * bottom sheet on phones (BottomSheet). The title "أعد نشر المقال", a compact preview of the article (title, the
 * writer's avatar and name), a field that grows with its text and never scrolls inside itself, the counter "n/500"
 * (red over the limit, which disables the button), then "انشر" (or "احفظ" when editing) and "إلغاء".
 *
 * Editing first loads your repost (`GET`): the field waits, read-only, and a failure offers Retry. Submitting sends
 * `PUT { caption }` (an empty field clears your thoughts). The dialog stays open on an error and shows it under the
 * field (`repost.caption_too_long`, `repost.own_article`, the rest from ErrorMessages); on success the button's state and
 * count change everywhere (ArticleSocialStore), a toast confirms and the dialog closes.
 */
@Component({
  selector: 'rd-repost-dialog',
  imports: [TranslocoPipe, LucideDynamicIcon, AutoDir, BdiText, Avatar, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: `
    /* Grows with its text (field-sizing) and never scrolls inside itself: no scrollbar or arrows in the field, the
       sheet scrolls instead. Three lines tall at first; the padding leaves room for Arabic glyphs below the last line. */
    .caption {
      field-sizing: content;
      resize: none;
      overflow: hidden;
      min-height: calc(3lh + 1.5rem);
      padding-block: 0.75rem;
      line-height: 1.7;
    }
    .caption::placeholder {
      color: var(--rd-color-text-secondary);
      opacity: 0.8;
    }
  `,
  template: `
    <rd-bottom-sheet [open]="!!request()" [labelledBy]="titleId" [dismissible]="!busy()" (closed)="close()">
      @if (request(); as r) {
        <form
          class="flex flex-col gap-3 pt-1"
          data-repost-dialog
          [attr.data-mode]="mode()"
          [attr.data-state]="status()"
          [attr.aria-busy]="status() === 'loading' || busy()"
          (submit)="submit($event)"
        >
          <h2 [id]="titleId" class="m-0 pe-10 text-xl font-semibold">{{ 'repostDialog.title' | transloco }}</h2>

          <!-- The article: its title, and the writer's avatar and name -->
          <div class="flex items-center gap-3 rounded-md border border-border bg-surface p-3" data-repost-preview>
            @if (r.article.author; as author) {
              <rd-avatar [name]="author.displayName" [src]="author.avatarUrl" [size]="40" class="shrink-0" />
            } @else {
              <rd-avatar [generic]="true" [size]="40" class="shrink-0" />
            }
            <div class="min-w-0">
              <p class="m-0 line-clamp-2 text-sm font-semibold leading-snug text-text-primary" [attr.dir]="titleDir()" data-repost-preview-title>
                <rd-bdi-text [text]="r.article.title" />
              </p>
              <p class="m-0 mt-0.5 truncate text-xs text-text-secondary" data-repost-preview-author>
                @if (r.article.author; as author) {
                  <span dir="auto">{{ author.displayName }}</span>
                } @else {
                  {{ 'common.deletedUser' | transloco }}
                }
              </p>
            </div>
          </div>

          <div>
            <label [for]="fieldId" class="sr-only">{{ 'repostDialog.fieldLabel' | transloco }}</label>
            <textarea
              #field
              [id]="fieldId"
              rows="3"
              class="caption rd-input block text-base"
              [rdAutoDir]="text()"
              [rdAutoDirFallback]="uiDir()"
              [value]="text()"
              [placeholder]="'repostDialog.placeholder' | transloco"
              [readOnly]="status() !== 'ready' || busy()"
              [attr.aria-invalid]="tooLong() ? true : null"
              [attr.aria-describedby]="countId"
              data-initial-focus
              data-repost-caption
              (input)="onInput($event)"
            ></textarea>
            <div class="mt-1 flex min-h-5 items-center gap-2 text-xs">
              @if (status() === 'loading') {
                <span class="flex items-center gap-1.5 text-text-secondary" data-repost-loading>
                  <svg lucideIcon="LoaderCircle" [size]="14" class="animate-spin" aria-hidden="true"></svg>
                  {{ 'repostDialog.loading' | transloco }}
                </span>
              }
              <p
                [id]="countId"
                class="m-0 ms-auto tabular-nums"
                [class.text-error]="tooLong()"
                [class.font-semibold]="tooLong()"
                [class.text-text-secondary]="!tooLong()"
                dir="ltr"
                data-repost-count
                [attr.data-over]="tooLong() ? true : null"
              >
                {{ length() }}/{{ max }}
              </p>
            </div>
          </div>

          @if (error(); as message) {
            <div class="rd-alert rd-alert-error m-0 flex items-center gap-2" role="alert" data-repost-error>
              <span class="min-w-0 flex-1">{{ message }}</span>
              @if (status() === 'error') {
                <button type="button" class="rd-btn rd-btn-outline min-h-9 shrink-0 px-3 text-sm" data-repost-retry (click)="load()">
                  {{ 'common.retry' | transloco }}
                </button>
              }
            </div>
          }

          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" data-repost-cancel (click)="close()">
              {{ 'common.cancel' | transloco }}
            </button>
            <button type="submit" class="rd-btn rd-btn-primary flex-1" [disabled]="!canSubmit()" [attr.aria-busy]="busy()" data-repost-submit>
              @if (busy()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ (mode() === 'edit' ? 'repostDialog.save' : 'repostDialog.submit') | transloco }}
            </button>
          </div>
        </form>
      }
    </rd-bottom-sheet>
  `,
})
export class RepostDialog {
  private readonly api = inject(RepostsApi);
  private readonly social = inject(ArticleSocialStore);
  private readonly errors = inject(ErrorMessages);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly injector = inject(Injector);
  protected readonly uiDir = inject(LanguageService).dir;

  /** Opens the dialog for this article; null closes it. */
  readonly request = input<RepostDialogRequest | null>(null);
  /** Cancelled, dismissed, or saved. */
  readonly closed = output<void>();

  private readonly uid = nextDialogId++;
  protected readonly titleId = `repost-dialog-title-${this.uid}`;
  protected readonly fieldId = `repost-dialog-field-${this.uid}`;
  protected readonly countId = `repost-dialog-count-${this.uid}`;
  protected readonly max = REPOST_CAPTION_MAX_LENGTH;

  protected readonly text = signal('');
  /** `edit` once `GET` says you reposted it; `new` when it says you haven't (an undo elsewhere). */
  protected readonly mode = signal<RepostDialogMode>('new');
  protected readonly status = signal<LoadStatus>('ready');
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);

  /** The server trims the caption and counts what is left. */
  protected readonly length = computed(() => this.text().trim().length);
  protected readonly tooLong = computed(() => this.length() > this.max);
  protected readonly canSubmit = computed(() => this.status() === 'ready' && !this.busy() && !this.tooLong());
  protected readonly titleDir = computed(() => detectDir(this.request()?.article.title) ?? 'auto');

  private readonly field = viewChild<ElementRef<HTMLTextAreaElement>>('field');
  /** Ignores a `GET` answer that arrives after the dialog closed or opened for another article. */
  private loadToken = 0;

  constructor() {
    // Each opening starts empty; editing loads your repost first.
    effect(() => {
      const request = this.request();
      untracked(() => {
        this.loadToken++;
        this.text.set('');
        this.error.set(null);
        this.busy.set(false);
        this.mode.set(request?.mode ?? 'new');
        this.status.set('ready');
        if (request?.mode === 'edit') void this.load();
      });
    });
  }

  /** `GET /articles/{id}/repost`: prefills the field with your thoughts (also the Retry after a failure). */
  async load(): Promise<void> {
    const request = this.request();
    if (!request) return;
    const token = ++this.loadToken;
    this.status.set('loading');
    this.error.set(null);
    try {
      const state = await firstValueFrom(this.api.state(request.article.id));
      if (token !== this.loadToken) return;
      this.social.applyRepost(request.article, state);
      this.mode.set(state.isReposted ? 'edit' : 'new');
      this.text.set(state.caption ?? '');
      this.status.set('ready');
      afterNextRender(() => this.afterPrefill(), { injector: this.injector });
    } catch (error) {
      if (token !== this.loadToken) return;
      this.status.set('error');
      this.error.set(this.errors.forError(error));
    }
  }

  protected onInput(event: Event): void {
    const field = event.target as HTMLTextAreaElement;
    this.text.set(field.value);
    this.grow(field);
  }

  protected async submit(event: Event): Promise<void> {
    event.preventDefault();
    const request = this.request();
    if (!request || !this.canSubmit()) return;
    const mode = this.mode();
    this.busy.set(true);
    this.error.set(null);
    try {
      await this.social.repostWithCaption(request.article, this.text());
      this.busy.set(false);
      this.toasts.success(this.transloco.translate(mode === 'edit' ? 'repostDialog.saved' : 'repostDialog.reposted'));
      this.closed.emit();
    } catch (error) {
      this.busy.set(false);
      this.error.set(this.message(error));
    }
  }

  protected close(): void {
    if (!this.busy()) this.closed.emit();
  }

  /** `repost.caption_too_long` comes in a validation failure's `errors.caption`; the rest are problem codes. */
  private message(error: unknown): string {
    if (isApiError(error) && error.code === 'validation.failed') {
      const codes = error.validationErrors['caption'] ?? [];
      if (codes.includes('repost.caption_too_long')) return this.errors.forCode('repost.caption_too_long');
    }
    return this.errors.forError(error);
  }

  /** The prefilled field: its height, and the caret after your thoughts. */
  private afterPrefill(): void {
    const field = this.field()?.nativeElement;
    if (!field) return;
    this.grow(field);
    if (field.ownerDocument.activeElement === field) field.setSelectionRange(field.value.length, field.value.length);
  }

  /** Without `field-sizing`, the field takes its content's height (it never scrolls inside itself). */
  private grow(field: HTMLTextAreaElement): void {
    if (SIZES_ITSELF) return;
    field.style.height = 'auto';
    if (field.scrollHeight > 0) field.style.height = `${field.scrollHeight + field.offsetHeight - field.clientHeight}px`;
  }
}
