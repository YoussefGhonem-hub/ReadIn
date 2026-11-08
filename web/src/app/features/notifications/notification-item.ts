import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { Router } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { NotificationDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { detectDir } from '../../shared/directives/bidi';
import { RelativeTimePipe } from '../../shared/pipes/format.pipes';
import { Avatar } from '../../shared/ui/avatar';
import { isActorType, notificationDetail, notificationIcon, notificationText, verificationOutcome } from './notification-view';

/**
 * One row of the notification center (F17): who (avatar with the type's icon, "Deleted user" for a gone account) or the
 * type's icon, the sentence with the actor's name in bold, the article title in its own direction, the comment
 * excerpt, when, and a dot while unread. Tapping it reports `opened` (the page marks it read) and opens its link; a
 * row without one (a moderation warning, whose dialog opens instead) is a button.
 */
@Component({
  selector: 'rd-notification-item',
  imports: [NgTemplateOutlet, TranslocoPipe, LucideDynamicIcon, BdiText, RelativeTimePipe, Avatar],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @let n = notification();
    <ng-template #content>
      <span class="relative mt-0.5 shrink-0">
        @if (actorBased()) {
          <!-- Unread rows share the avatar's soft color: a ring keeps its circle visible. -->
          <rd-avatar [name]="n.actor?.displayName ?? ''" [src]="n.actor?.avatarUrl ?? null" [generic]="!n.actor" [size]="44" [class]="n.isRead ? '' : 'ring-2 ring-surface'" />
          <span class="absolute -bottom-1 -end-1 grid h-6 w-6 place-items-center rounded-full border-2 border-surface bg-primary text-on-primary" aria-hidden="true">
            <svg [lucideIcon]="icon()" [size]="12"></svg>
          </span>
        } @else {
          <span class="grid h-11 w-11 place-items-center rounded-full" [class]="iconTone()" aria-hidden="true">
            <svg [lucideIcon]="icon()" [size]="20"></svg>
          </span>
        }
      </span>
      <span class="min-w-0 flex-1">
        <span class="block text-sm leading-6 text-text-primary" data-notification-text
          >{{ text().before }}@if (text().actor; as actor) {<strong class="font-semibold"><bdi>{{ actor }}</bdi></strong>}{{ text().after }}</span
        >
        @if (n.article; as article) {
          <!-- The title in its own language and direction, as on the article cards. -->
          <span class="line-clamp-2 block text-sm font-semibold text-text-primary" [attr.lang]="article.language" [attr.dir]="titleDir()" data-notification-article>
            <rd-bdi-text [text]="article.title" [baseDir]="titleDir()" />
          </span>
        }
        @if (n.comment; as comment) {
          <!-- A comment is mixed text: its own paragraph direction (SPEC §14.2). -->
          <span class="mt-1 line-clamp-2 block border-s-2 border-border ps-2 text-sm text-text-secondary" [attr.dir]="commentDir()" data-notification-comment>
            <rd-bdi-text [text]="comment.excerpt" />
          </span>
        }
        @if (n.type === 'report_new' && n.data.system) {
          <span class="mt-0.5 block text-sm text-text-secondary" data-notification-system>{{ 'notifications.text.report_new.system' | transloco }}{{
            n.data.targetLabel ? ' · ' : ''
          }}<bdi dir="auto">{{ n.data.targetLabel ?? '' }}</bdi></span>
        }
        @if (detail(); as line) {
          <!-- An announcement's text, or a ticket's "#12 · subject" (F23, F35): mixed text in its own direction. -->
          <span class="mt-0.5 line-clamp-2 block text-sm text-text-secondary" dir="auto" data-notification-detail>{{ line }}</span>
        }
        @if (n.type === 'security_alert') {
          <span class="mt-0.5 block text-sm text-text-secondary">{{ 'notifications.text.security_alert.hint' | transloco }}</span>
        }
        @if (rejected()) {
          <!-- The reason is on the verification page only, never in the notification. -->
          <span class="mt-0.5 block text-sm text-text-secondary" data-notification-hint>{{ 'notifications.text.verification_result.hint' | transloco }}</span>
        }
        <time class="mt-1 block text-xs text-text-secondary" [attr.datetime]="n.updatedAt">{{ n.updatedAt | rdRelativeTime: lang() }}</time>
      </span>
      @if (!n.isRead) {
        <span class="mt-2 h-2.5 w-2.5 shrink-0 rounded-full bg-primary" aria-hidden="true" data-unread-dot></span>
        <span class="sr-only">{{ 'notifications.unread' | transloco }}</span>
      }
    </ng-template>

    @if (path(); as p) {
      <a [href]="p" [class]="rowClass()" (click)="follow($event, p)" [attr.data-notification]="n.id" [attr.data-type]="n.type" [attr.data-unread]="!n.isRead || null">
        <ng-container [ngTemplateOutlet]="content" />
      </a>
    } @else {
      <button type="button" [class]="rowClass()" (click)="opened.emit()" [attr.data-notification]="n.id" [attr.data-type]="n.type" [attr.data-unread]="!n.isRead || null">
        <ng-container [ngTemplateOutlet]="content" />
      </button>
    }
  `,
})
export class NotificationItem {
  private readonly router = inject(Router);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  readonly notification = input.required<NotificationDto>();
  /** In-app path its link opens, or null. */
  readonly path = input<string | null>(null);
  /** Tapped (also with a modifier key, which opens the link in a new tab): the page marks it read. */
  readonly opened = output<void>();

  protected readonly actorBased = computed(() => isActorType(this.notification().type));
  /** A rejected verification request (F19): "Open it to see why". */
  protected readonly rejected = computed(() => this.notification().type === 'verification_result' && verificationOutcome(this.notification()) === 'rejected');
  protected readonly icon = computed(() => notificationIcon(this.notification()));
  protected readonly detail = computed(() => notificationDetail(this.notification()));
  protected readonly text = computed(() => notificationText(this.notification(), this.transloco, this.lang()));
  protected readonly titleDir = computed(() => (this.notification().article?.language === 'ar-EG' ? 'rtl' : 'ltr'));
  /** From the excerpt's first strong character: `dir="auto"` would skip the inner `rd-bdi-text`, which has its own `dir`. */
  protected readonly commentDir = computed(() => detectDir(this.notification().comment?.excerpt) ?? 'auto');
  protected readonly iconTone = computed(() => {
    switch (this.notification().type) {
      case 'streak_reminder':
      case 'daily_article':
      case 'announcement':
        return 'bg-accent-container text-text-primary';
      case 'security_alert':
      case 'moderation_notice':
      case 'report_new':
        return 'bg-callout-danger text-error';
      case 'verification_result':
        return this.rejected() ? 'bg-callout-warning text-text-primary' : 'bg-primary-container text-on-primary-container';
      default:
        return 'bg-primary-container text-on-primary-container';
    }
  });
  protected readonly rowClass = computed(
    () =>
      'flex w-full items-start gap-3 rounded-none px-4 py-3 text-start text-inherit no-underline focus-visible:-outline-offset-2 lg:px-5 ' +
      (this.notification().isRead ? 'hover:bg-surface-variant' : 'bg-primary-container'),
  );

  protected follow(event: MouseEvent, path: string): void {
    this.opened.emit();
    // Ctrl/⌘/Shift/middle click: the browser opens the link in a new tab or window.
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    void this.router.navigateByUrl(path);
  }
}
