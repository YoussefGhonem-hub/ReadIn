import { ChangeDetectionStrategy, Component, computed, effect, inject, signal, untracked } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { LanguageService } from '../../core/i18n/language.service';
import { ModerationNotices } from '../../core/moderation/moderation-notices';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir, isolate } from '../../shared/directives/bidi';
import { ModerationErrors } from '../../shared/moderation/moderation-errors';
import { LocalizedDatePipe } from '../../shared/pipes/format.pipes';
import { BottomSheet } from '../../shared/ui/bottom-sheet';

/**
 * A moderation notice (F22), one at a time, oldest first: "وصلك تحذير من فريق الإشراف" or "مقالك «…» اتخفى", the
 * team's note, and "فهمت", which acknowledges it (`POST /me/moderation-notices/{id}/acknowledge`). It can't be dismissed
 * any other way: the point is that you read it. Loaded and rendered by the app root only when there are notices.
 */
@Component({
  selector: 'rd-moderation-notice-dialog',
  imports: [TranslocoPipe, LucideDynamicIcon, BdiText, LocalizedDatePipe, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet
      [open]="!!notices.current()"
      role="alertdialog"
      labelledBy="moderation-notice-title"
      describedBy="moderation-notice-body"
      [dismissible]="false"
    >
      @if (notices.current(); as notice) {
        <div class="flex flex-col gap-3 pt-1" data-moderation-notice [attr.data-notice-kind]="notice.kind">
          <span
            class="grid h-12 w-12 place-items-center rounded-card"
            [class]="notice.kind === 'warning' ? 'bg-callout-warning text-callout-warning-accent' : 'bg-callout-danger text-error'"
            aria-hidden="true"
          >
            <svg [lucideIcon]="notice.kind === 'warning' ? 'TriangleAlert' : 'EyeOff'" [size]="24"></svg>
          </span>
          <h2 id="moderation-notice-title" class="m-0 text-xl font-semibold" data-notice-title>
            @if (notice.kind === 'warning') {
              {{ 'moderation.notice.warning' | transloco }}
            } @else {
              {{ 'moderation.notice.articleHidden' | transloco: { title: isolate(notice.article?.title) } }}
            }
          </h2>
          <div id="moderation-notice-body" class="flex flex-col gap-3 text-sm">
            @if (notice.kind === 'article_hidden') {
              <p class="m-0 text-text-secondary">{{ 'moderation.notice.articleHiddenBody' | transloco }}</p>
            }
            @if (notice.note) {
              <div class="rounded-md border border-border bg-surface p-3" data-notice-note>
                <span class="block text-xs font-semibold text-text-secondary">{{ 'moderation.notice.note' | transloco }}</span>
                <p class="m-0 mt-1 whitespace-pre-line [overflow-wrap:anywhere]" [attr.dir]="noteDir()"><rd-bdi-text [text]="notice.note" /></p>
              </div>
            }
            @if (notice.kind === 'warning') {
              <p class="m-0 text-text-secondary">{{ 'moderation.notice.rules' | transloco }}</p>
            }
            <p class="m-0 text-xs text-text-secondary">
              <time [attr.datetime]="notice.createdAt">{{ notice.createdAt | rdDate: lang() : 'long' }}</time>
            </p>
          </div>
          @if (error()) {
            <p class="rd-alert rd-alert-error m-0" role="alert">{{ error() }}</p>
          }
          <button type="button" class="rd-btn rd-btn-primary mt-1 w-full" [disabled]="busy()" [attr.aria-busy]="busy()" data-notice-ack (click)="acknowledge(notice.id)">
            @if (busy()) {
              <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
            }
            {{ 'moderation.notice.gotIt' | transloco }}
          </button>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class ModerationNoticeDialog {
  protected readonly notices = inject(ModerationNotices);
  protected readonly lang = inject(LanguageService).lang;
  /** The note's own direction (`dir="auto"` would skip the <rd-bdi-text> inside). */
  protected readonly isolate = isolate;
  protected readonly noteDir = computed(() => detectDir(this.notices.current()?.note) ?? 'auto');
  private readonly errors = inject(ModerationErrors);

  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);

  constructor() {
    effect(() => {
      this.notices.current();
      untracked(() => this.error.set(null));
    });
  }

  protected async acknowledge(id: string): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    this.error.set(null);
    try {
      await this.notices.acknowledge(id);
    } catch (error) {
      this.error.set(this.errors.message(error));
    } finally {
      this.busy.set(false);
    }
  }
}
