import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import {
  ArticleLanguage,
  MODERATION_TARGET_TYPES,
  ModerationActionDto,
  ModerationQueueItemDto,
  ModerationTargetType,
  REPORT_REASONS,
  ReportReason,
  ReportStatus,
} from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir, isolate } from '../../shared/directives/bidi';
import { LocalizedDatePipe, RelativeTimePipe, translatePlural } from '../../shared/pipes/format.pipes';
import { urlLangFor } from '../../shared/ui/article-link';
import { Avatar } from '../../shared/ui/avatar';

export type ModerationTab = ReportStatus | 'log';

/**
 * The paragraph direction of user text (notes, report details) from its first strong character. `dir="auto"` can't do
 * it: the browser skips the <rd-bdi-text> inside, which carries its own `dir`.
 */
export function textDir(text: string | null | undefined): 'rtl' | 'ltr' | 'auto' {
  return detectDir(text) ?? 'auto';
}

export function isTargetType(value: string | null | undefined): value is ModerationTargetType {
  return MODERATION_TARGET_TYPES.includes(value as ModerationTargetType);
}

/** Where the reported content lives: the article, the article with the comment, or the profile. */
export function targetLink(item: Pick<ModerationQueueItemDto, 'targetType' | 'target'>, uiLang: 'ar' | 'en'): string | null {
  const t = item.target;
  if (t.state === 'deleted') return null;
  switch (item.targetType) {
    case 'article':
      return t.slug ? `/${urlLangFor((t.language as ArticleLanguage) ?? 'ar-EG')}/a/${t.slug}` : null;
    case 'comment':
      return t.articleSlug ? `/${uiLang}/a/${t.articleSlug}` : null;
    case 'user':
      return t.author ? `/@${t.author.username}` : null;
  }
}

/**
 * The moderation page's title and its tabs: Open / Resolved / Dismissed (the queue, `?status=`) and Log. The top of the
 * page's card: the tabs run edge to edge.
 */
@Component({
  selector: 'rd-moderation-header',
  imports: [RouterLink, TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <header class="px-4 pt-4 lg:px-5 lg:pt-5">
      <h1 class="m-0 text-xl font-bold lg:text-2xl">{{ 'moderation.title' | transloco }}</h1>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'moderation.subtitle' | transloco }}</p>
    </header>
    <nav class="mt-3 flex gap-5 overflow-x-auto border-b border-border px-4 lg:px-5" [attr.aria-label]="'moderation.tabs.label' | transloco" data-moderation-tabs>
      @for (tab of tabs; track tab) {
        <a
          [routerLink]="tab === 'log' ? '/admin/reports/log' : '/admin/reports'"
          [queryParams]="tab === 'log' ? {} : { status: tab === 'open' ? null : tab, type: type() }"
          class="-mb-px inline-flex min-h-11 shrink-0 items-center border-b-2 px-1 text-sm no-underline"
          [class]="active() === tab ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary hover:text-text-primary'"
          [attr.aria-current]="active() === tab ? 'page' : null"
          [attr.data-moderation-tab]="tab"
        >
          {{ 'moderation.tabs.' + tab | transloco }}
        </a>
      }
    </nav>
  `,
})
export class ModerationHeader {
  readonly active = input.required<ModerationTab>();
  /** The type filter carries over between the status tabs. */
  readonly type = input<ModerationTargetType | null>(null);
  protected readonly tabs: ModerationTab[] = ['open', 'resolved', 'dismissed', 'log'];
}

/** "سبام 3 · إساءة 1": how many reports gave each reason, most first. */
@Component({
  selector: 'rd-reason-chips',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-wrap gap-1.5' },
  template: `
    @for (entry of entries(); track entry.reason) {
      <span class="rd-tag rd-tag-neutral" [attr.data-reason-count]="entry.reason">
        {{ 'moderation.reasons.' + entry.reason | transloco }}
        <span class="tabular-nums" dir="ltr">{{ entry.count }}</span>
      </span>
    }
  `,
})
export class ReasonChips {
  readonly reasons = input.required<Partial<Record<ReportReason, number>>>();
  protected readonly entries = computed(() =>
    REPORT_REASONS.map((reason) => ({ reason, count: this.reasons()[reason] ?? 0 }))
      .filter((e) => e.count > 0)
      .sort((a, b) => b.count - a.count),
  );
}

/**
 * What a case is about (F22): its type and state, then the article's title and author, the comment's text and its
 * article, or the user with their warnings and suspension.
 */
@Component({
  selector: 'rd-target-preview',
  imports: [NgTemplateOutlet, TranslocoPipe, BdiText, Avatar, LocalizedDatePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block min-w-0' },
  styles: `
    .comment-body {
      white-space: pre-line;
      overflow-wrap: anywhere;
    }
  `,
  template: `
    @let t = item().target;
    <div class="mb-2 flex flex-wrap items-center gap-1.5">
      <span class="rd-tag rd-tag-neutral" data-target-type>{{ 'moderation.type.' + item().targetType | transloco }}</span>
      @if (t.state !== 'visible' && t.state !== 'active') {
        <span class="rd-tag text-text-primary" [class]="t.state === 'hidden' ? 'bg-callout-warning' : 'bg-callout-danger'" [attr.data-target-state]="t.state">
          {{ 'moderation.state.' + t.state | transloco }}
        </span>
      }
    </div>
    @switch (item().targetType) {
      @case ('article') {
        <p class="m-0 font-semibold leading-snug" [class.text-lg]="!compact()" [attr.dir]="dirOf(t.title)" [attr.lang]="t.language" data-target-title>
          <rd-bdi-text [text]="t.title ?? ''" />
        </p>
        <p class="m-0 mt-1 text-xs text-text-secondary">
          {{ 'moderation.case.author' | transloco }}: <ng-container *ngTemplateOutlet="author" />
        </p>
      }
      @case ('comment') {
        <p class="comment-body m-0 text-[15px] leading-relaxed" [class.line-clamp-3]="compact()" [attr.dir]="dirOf(t.body)" data-target-body>
          <rd-bdi-text [text]="t.body ?? ''" />
        </p>
        <p class="m-0 mt-1 text-xs text-text-secondary">
          <ng-container *ngTemplateOutlet="author" />
          @if (t.articleTitle) {
            · <span>{{ 'moderation.onArticle' | transloco: { title: isolate(t.articleTitle) } }}</span>
          }
        </p>
      }
      @case ('user') {
        <div class="flex items-center gap-3">
          <rd-avatar [name]="t.author?.displayName ?? '?'" [src]="t.author?.avatarUrl ?? null" [size]="compact() ? 36 : 48" />
          <div class="min-w-0">
            <p class="m-0 font-semibold" data-target-user><ng-container *ngTemplateOutlet="author" /></p>
            <p class="m-0 text-xs text-text-secondary">
              {{ warningsLabel() }}
              @if (t.state === 'suspended') {
                ·
                @if (t.suspendedUntil) {
                  {{ 'moderation.suspendedUntil' | transloco: { date: (t.suspendedUntil | rdDate: lang() : 'long') } }}
                } @else {
                  {{ 'moderation.suspendedPermanently' | transloco }}
                }
              }
            </p>
          </div>
        </div>
      }
    }

    <ng-template #author>
      @if (t.author; as a) {
        <span class="inline-flex min-w-0 items-center gap-1"><rd-bdi-text [text]="a.displayName" /> <bdi dir="ltr" class="font-normal text-text-secondary">&#64;{{ a.username }}</bdi></span>
      } @else {
        <span>{{ 'moderation.deletedUser' | transloco }}</span>
      }
    </ng-template>
  `,
})
export class TargetPreview {
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  readonly item = input.required<Pick<ModerationQueueItemDto, 'targetType' | 'target'>>();
  /** In the queue: smaller, the comment clamped to 3 lines. */
  readonly compact = input(false);

  protected readonly warningsLabel = computed(() =>
    translatePlural(this.transloco, 'moderation.warnings', this.item().target.warningCount ?? 0, this.lang()),
  );

  protected readonly dirOf = textDir;
  protected readonly isolate = isolate;
}

/**
 * One moderation log row: who did what to which target ("Mona hid an article · {title}"), the note, how long a
 * suspension lasts, how many reports it closed, and when. The target links to its case.
 */
@Component({
  selector: 'rd-moderation-log-entry',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, Avatar, LocalizedDatePipe, RelativeTimePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex gap-3 py-3', '[attr.data-log-entry]': 'entry().id', '[attr.data-log-action]': 'entry().action' },
  template: `
    @let e = entry();
    <span class="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-surface-variant text-text-secondary" aria-hidden="true">
      <svg [lucideIcon]="icon()" [size]="18"></svg>
    </span>
    <div class="min-w-0 flex-1 text-sm">
      <p class="m-0">
        @if (e.moderator; as m) {
          <span class="font-semibold"><rd-bdi-text [text]="m.displayName" /></span>
        } @else {
          <span class="font-semibold text-text-secondary">{{ 'moderation.log.deletedModerator' | transloco }}</span>
        }
        {{ 'moderation.log.action.' + e.action | transloco }}
        @if (e.action === 'user.suspend') {
          ·
          @if (e.suspendedUntil) {
            {{ 'moderation.log.until' | transloco: { date: (e.suspendedUntil | rdDate: lang() : 'long') } }}
          } @else {
            {{ 'moderation.log.permanent' | transloco }}
          }
        }
      </p>
      @if (e.targetLabel || e.targetUser) {
        <p class="m-0 mt-0.5 truncate text-text-secondary">
          @if (linkTarget()) {
            <a [routerLink]="['/admin/reports', e.targetType, e.targetId]" class="text-link no-underline hover:underline" data-log-target>
              <rd-bdi-text [text]="label()" />
            </a>
          } @else {
            <rd-bdi-text [text]="label()" />
          }
        </p>
      }
      @if (e.note) {
        <p class="m-0 mt-1 whitespace-pre-line rounded-md bg-surface-variant px-2 py-1 [overflow-wrap:anywhere]" [attr.dir]="textDir(e.note)" data-log-note>
          <rd-bdi-text [text]="e.note" />
        </p>
      }
      <p class="m-0 mt-1 text-xs text-text-secondary">
        <time [attr.datetime]="e.createdAt" [title]="e.createdAt | rdDate: lang() : 'long'">{{ e.createdAt | rdRelativeTime: lang() }}</time>
        @if (e.reportsClosed > 0) {
          · {{ closedLabel() }}
        }
      </p>
    </div>
    @if (e.targetUser; as u) {
      <rd-avatar class="self-start" [name]="u.displayName" [src]="u.avatarUrl" [size]="28" />
    }
  `,
})
export class ModerationLogEntry {
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  readonly entry = input.required<ModerationActionDto>();
  /** In the log: the target links to its case (not on the case's own history). */
  readonly linkTarget = input(true);

  protected readonly textDir = textDir;
  protected readonly label = computed(() => {
    const e = this.entry();
    return e.targetLabel ?? (e.targetUser ? `@${e.targetUser.username}` : '');
  });
  protected readonly closedLabel = computed(() => translatePlural(this.transloco, 'moderation.log.reportsClosed', this.entry().reportsClosed, this.lang()));
  protected readonly icon = computed(() => {
    switch (this.entry().action) {
      case 'comment.hide':
      case 'article.hide':
      case 'user.hide_content':
        return 'EyeOff';
      case 'comment.unhide':
      case 'article.unhide':
      case 'user.unhide_content':
        return 'Eye';
      case 'comment.delete':
        return 'Trash2';
      case 'user.warn':
        return 'TriangleAlert';
      case 'user.suspend':
        return 'Ban';
      case 'user.unsuspend':
        return 'UserRoundCheck';
      case 'user.clear_category':
      case 'user.clear_links':
      case 'user.clear_headline':
        return 'Eraser';
      default:
        return 'CircleX';
    }
  });
}
