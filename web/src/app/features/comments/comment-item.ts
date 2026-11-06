import { ChangeDetectionStrategy, Component, ElementRef, Injector, afterNextRender, computed, inject, input, linkedSignal, signal, untracked } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CdkMenu, CdkMenuItem, CdkMenuTrigger } from '@angular/cdk/menu';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon, LucideIconData } from '@lucide/angular';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { LanguageService } from '../../core/i18n/language.service';
import { FollowStore } from '../../core/social/follow.store';
import { MuteStore } from '../../core/social/mute.store';
import { BdiText } from '../../shared/directives/bdi-text';
import { MUTE_ICON } from '../../shared/mutes/mute-icons';
import { CompactNumberPipe, LocalizedDatePipe, RelativeTimePipe } from '../../shared/pipes/format.pipes';
import { FollowButton } from '../../shared/social/follow-button';
import { Avatar } from '../../shared/ui/avatar';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { ProfileCardTrigger } from '../../shared/profile-card/profile-card.directive';
import { CommentComposer } from './comment-composer';
import { CommentErrors } from './comment-errors';
import { commentDir, commentSegments, isPlaceholder } from './comment-text';
import { CommentView, CommentsStore } from './comments.store';

type MenuAction = 'edit' | 'delete' | 'pin' | 'unpin' | 'muteCommenter' | 'report' | 'hide' | 'unhide' | 'moderatorDelete';

interface MenuItem {
  action: MenuAction;
  label: string;
  icon: string | LucideIconData;
  danger?: boolean;
}

/**
 * One comment or reply (F11), compact like LinkedIn and Facebook: the avatar at the start (32 px, 24 for replies), then a
 * bubble with the full remaining width. Its header has the name with the verified and "الكاتب" badges and the pinned
 * label, then "· متابعة" as text (when you don't follow them and it isn't you; guests get the sign-in prompt); at its
 * end the relative time, "· edited" and "⋯" with what the viewer may do (`can*`). Under the name, the writer's title
 * (F14) on one line with "…" (never the @username). Then the text with its own direction and only the resolved
 * @mentions as links. Under the bubble one row of text actions: Like (with a heart and the count when there are likes)
 * and Reply, or "Sending…" while it posts. The avatar and the name open the profile, and a pointer resting on them (or
 * on a mention) opens the person's card. A comment that just arrived highlights its bubble. Deleted or hidden-for-you
 * comments are compact placeholders; a deleted account shows as "Deleted user" without a profile link. A comment by a
 * writer you muted collapses to "تعليق من شخص كتمته" with "عرض", which shows it here only (F28); replies under it stay.
 */
@Component({
  selector: 'rd-comment-item',
  imports: [
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    CdkMenu,
    CdkMenuItem,
    CdkMenuTrigger,
    Avatar,
    BdiText,
    CompactNumberPipe,
    LocalizedDatePipe,
    RelativeTimePipe,
    CommentComposer,
    FollowButton,
    ProfileCardTrigger,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'block',
    '[attr.data-comment]': 'comment().id',
    '[attr.data-pending]': 'comment().pending ? true : null',
  },
  // A bubble: radius 12 with the top-start corner 4. Line breaks are kept; long words and URLs wrap instead of widening
  // the page.
  styles: `
    .bubble {
      border-radius: 12px;
      border-start-start-radius: 4px;
    }
    .comment-body {
      white-space: pre-wrap;
      overflow-wrap: anywhere;
    }
  `,
  template: `
    @let c = comment();
    @if (placeholder()) {
      <div class="flex items-start gap-2 py-1.5" data-comment-placeholder>
        <span
          class="grid shrink-0 place-items-center rounded-full bg-surface-variant text-text-secondary"
          [style.width.px]="avatarSize()"
          [style.height.px]="avatarSize()"
          aria-hidden="true"
        >
          <svg lucideIcon="MessageCircle" [size]="iconSize()"></svg>
        </span>
        <p class="bubble m-0 min-w-0 flex-1 bg-surface-variant px-3 py-2 text-sm italic text-text-secondary">
          {{ (c.isDeleted ? 'comments.deleted' : 'comments.hidden') | transloco }}
        </p>
      </div>
    } @else if (mutedCollapsed()) {
      <div class="flex items-start gap-2 py-1.5" data-comment-muted>
        <span
          class="grid shrink-0 place-items-center rounded-full bg-surface-variant text-text-secondary"
          [style.width.px]="avatarSize()"
          [style.height.px]="avatarSize()"
          aria-hidden="true"
        >
          <svg lucideIcon="MessageCircle" [size]="iconSize()"></svg>
        </span>
        <div class="bubble flex min-w-0 flex-1 flex-wrap items-center gap-x-2 bg-surface-variant px-3 py-2 text-sm text-text-secondary">
          <span class="italic">{{ 'mute.comment.collapsed' | transloco }}</span>
          <button
            type="button"
            class="-my-1.5 -ms-1 inline-flex min-h-8 items-center rounded-md px-1 font-semibold text-primary hover:underline"
            data-comment-reveal
            (click)="reveal()"
          >
            {{ 'mute.comment.show' | transloco }}
          </button>
        </div>
      </div>
    } @else {
      <div class="flex items-start gap-2 py-1.5" [class.opacity-70]="c.pending">
        @if (c.author; as author) {
          <a [routerLink]="'/@' + author.username" [rdProfileCard]="author.username" class="shrink-0 rounded-full" tabindex="-1" aria-hidden="true">
            <rd-avatar [name]="author.displayName" [src]="author.avatarUrl" [size]="avatarSize()" />
          </a>
        } @else {
          <span
            class="grid shrink-0 place-items-center rounded-full bg-surface-variant text-text-secondary"
            [style.width.px]="avatarSize()"
            [style.height.px]="avatarSize()"
            aria-hidden="true"
            data-deleted-user-avatar
          >
            <svg lucideIcon="UserRound" [size]="iconSize()"></svg>
          </span>
        }

        <div class="min-w-0 flex-1">
          <div
            class="bubble px-3 py-2 transition-colors duration-500"
            [class.bg-surface-variant]="!highlighted()"
            [class.bg-highlight]="highlighted()"
            [attr.data-highlighted]="highlighted() || null"
            data-comment-bubble
          >
            <div class="flex items-start gap-2">
              <!-- The name and its badges, and under them the writer's title; the time and "⋯" stand beside both -->
              <div class="min-w-0 flex-1" data-comment-heading>
                <div class="flex flex-wrap items-center gap-x-1.5 gap-y-0.5 text-sm">
                  @if (c.author; as author) {
                    <a
                      [routerLink]="'/@' + author.username"
                      [rdProfileCard]="author.username"
                      class="inline-flex min-w-0 max-w-full items-center gap-1 font-semibold text-text-primary no-underline hover:underline"
                      data-comment-author
                    >
                      <rd-bdi-text class="truncate" [text]="author.displayName" />
                      @if (author.isVerified) {
                        <svg lucideIcon="BadgeCheck" [size]="14" class="shrink-0 text-primary" role="img" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
                      }
                    </a>
                  } @else {
                    <span class="font-semibold text-text-secondary" data-comment-author>{{ 'comments.deletedUser' | transloco }}</span>
                  }
                  @if (c.isArticleAuthor) {
                    <span class="rd-tag" data-writer-badge>{{ 'comments.writer' | transloco }}</span>
                  }
                  @if (c.isPinned) {
                    <span class="inline-flex items-center gap-0.5 text-xs font-semibold text-primary" data-pinned>
                      <svg lucideIcon="Pin" [size]="12" aria-hidden="true"></svg>{{ 'comments.pinned' | transloco }}
                    </span>
                  }
                  @if (showFollow() && c.author; as author) {
                    <span class="text-text-secondary" aria-hidden="true">·</span>
                    <span class="contents" data-comment-follow><rd-follow-button [user]="author" [initial]="c.isFollowingAuthor ?? false" [inline]="true" /></span>
                  }
                </div>
                <!-- The writer's title (F14) on one line with "…", never the @username: on the UI's start side, laid out and
                     cut in its own direction -->
                @if (headline(); as headline) {
                  <p class="m-0 flex text-xs leading-snug text-text-secondary" [attr.title]="headline" data-comment-headline>
                    <bdi dir="auto" class="min-w-0 truncate">{{ headline }}</bdi>
                  </p>
                }
              </div>
              <!-- The time, "edited" and "⋯" at the end; the 32 px menu button sits in the bubble's top-end corner without
                   making the row taller -->
              <div class="flex shrink-0 items-center gap-1 text-xs leading-5 text-text-secondary" data-comment-meta>
                @if (!c.pending) {
                  <time [attr.datetime]="c.createdAt" [title]="c.createdAt | rdDate: lang() : 'long'">{{ c.createdAt | rdRelativeTime: lang() }}</time>
                }
                @if (c.editedAt) {
                  <span aria-hidden="true">·</span>
                  <span data-edited>{{ 'comments.edited' | transloco }}</span>
                }
                @if (!c.pending && menuItems().length) {
                  <button
                    type="button"
                    class="-my-1.5 -me-2 grid h-8 w-8 place-items-center rounded-md text-text-secondary hover:bg-surface hover:text-text-primary"
                    [cdkMenuTriggerFor]="menu"
                    [attr.aria-label]="'comments.actions' | transloco"
                    data-comment-menu
                  >
                    <svg lucideIcon="EllipsisVertical" [size]="16" aria-hidden="true"></svg>
                  </button>
                }
              </div>
            </div>

            @if (c.isHidden) {
              <p class="m-0 mt-1.5 inline-flex items-center gap-1 rounded-sm bg-callout-warning px-2 py-1 text-xs" data-hidden-notice>
                <svg lucideIcon="EyeOff" [size]="13" aria-hidden="true"></svg>{{ 'comments.hiddenNotice' | transloco }}
              </p>
            }

            @if (editing()) {
              <rd-comment-composer
                class="mt-2"
                [(text)]="draft"
                [label]="'comments.composer.editLabel' | transloco"
                [submitLabel]="'comments.composer.save' | transloco"
                [error]="editError()"
                [busy]="saving()"
                [cancelable]="true"
                [cancelLabel]="'commentBox.cancelEdit' | transloco"
                [showAvatar]="false"
                [autofocus]="true"
                (submitted)="saveEdit($event)"
                (cancelled)="store.closeComposer()"
              />
            } @else {
              <p class="comment-body m-0 mt-1 text-sm leading-relaxed" [attr.dir]="bodyDir()" data-comment-body>
                @for (segment of segments(); track $index) {
                  @if (segment.kind === 'mention') {
                    <a
                      [routerLink]="'/@' + segment.username"
                      [rdProfileCard]="segment.username"
                      class="font-semibold text-link no-underline hover:underline"
                      dir="ltr"
                      data-mention
                      >{{ segment.text }}</a
                    >
                  } @else {
                    <rd-bdi-text [text]="segment.text" [baseDir]="bodyDir()" />
                  }
                }
              </p>
            }
          </div>

          @if (c.pending) {
            <p class="m-0 ps-1 text-xs leading-8 text-text-secondary" data-comment-actions>
              <span data-sending>{{ 'comments.sending' | transloco }}</span>
            </p>
          } @else if (!editing()) {
            <!-- Text actions under the bubble, from its start: Like (♥ and the count when liked by anyone) · Reply -->
            <div class="flex items-center gap-0.5 text-[13px] font-semibold text-text-secondary" data-comment-actions>
              <button
                type="button"
                class="inline-flex min-h-8 items-center gap-1.5 rounded-md px-1 hover:bg-surface-variant"
                [class.text-primary]="c.likedByMe"
                [attr.aria-pressed]="c.likedByMe"
                data-like
                (click)="like()"
              >
                {{ 'comments.like' | transloco }}
                @if (c.likeCount > 0) {
                  <span class="inline-flex items-center gap-0.5 font-normal text-text-secondary" data-like-count>
                    <svg lucideIcon="Heart" [size]="12" class="fill-current text-primary" aria-hidden="true"></svg>{{
                      c.likeCount | rdCompactNumber: lang()
                    }}
                  </span>
                }
              </button>
              @if (!c.isHidden) {
                <span aria-hidden="true">·</span>
                <button type="button" class="inline-flex min-h-8 items-center rounded-md px-1 hover:bg-surface-variant hover:text-text-primary" data-reply (click)="reply()">
                  {{ 'comments.reply' | transloco }}
                </button>
              }
            </div>
          }
        </div>
      </div>
    }

    <ng-template #menu>
      <div cdkMenu class="rounded-md border border-border bg-surface-raised p-1 shadow-raised" data-comment-menu-panel>
        @for (item of menuItems(); track item.action) {
          <button
            type="button"
            cdkMenuItem
            class="flex min-h-11 w-full items-center gap-2 rounded-sm px-3 text-start text-sm hover:bg-surface-variant"
            [class]="item.danger ? 'text-error' : 'text-text-primary'"
            [attr.data-menu-action]="item.action"
            (cdkMenuItemTriggered)="run(item.action)"
          >
            <svg [lucideIcon]="item.icon" [size]="16" aria-hidden="true"></svg>
            {{ item.label | transloco }}
          </button>
        }
      </div>
    </ng-template>
  `,
})
export class CommentItem {
  protected readonly store = inject(CommentsStore);
  private readonly session = inject(SessionStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(CommentErrors);
  private readonly mutes = inject(MuteStore);
  private readonly follows = inject(FollowStore);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly injector = inject(Injector);
  protected readonly lang = inject(LanguageService).lang;

  readonly comment = input.required<CommentView>();
  /** The thread's top-level comment (itself for a top-level comment). */
  readonly threadId = input.required<string>();

  protected readonly draft = signal('');
  protected readonly saving = signal(false);
  protected readonly editError = signal<string | null>(null);

  protected readonly placeholder = computed(() => isPlaceholder(this.comment()));
  /** "عرض" was pressed on this collapsed comment (F28): it stays open here only. */
  private readonly revealed = signal(false);
  /** By a writer you muted (the API's flag, or a mute or unmute since the page loaded): collapsed until "عرض". */
  protected readonly mutedCollapsed = computed(() => {
    const c = this.comment();
    if (this.revealed() || c.pending || !c.author || !this.session.isAuthenticated()) return false;
    return this.mutes.isAuthorMuted(c.author.id, c.isAuthorMuted ?? false);
  });
  /** You (signed in), for the commenter's Mute item. */
  private readonly myId = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null));
  /** You muted the commenter (false for guests), whether or not "عرض" opened this comment. */
  private readonly commenterMuted = computed(() => {
    const c = this.comment();
    return !!c.author && this.session.isAuthenticated() && this.mutes.isAuthorMuted(c.author.id, c.isAuthorMuted ?? false);
  });
  /** 32 px for a top-level comment, 24 for a reply. */
  protected readonly avatarSize = computed(() => (this.comment().parentId ? 24 : 32));
  /** The icon inside an avatar-sized circle (placeholders, a deleted account). */
  protected readonly iconSize = computed(() => Math.round(this.avatarSize() * 0.5));
  /** The writer's title (F14), hidden when empty. */
  protected readonly headline = computed(() => this.comment().author?.headline?.trim() || null);
  /** Who wrote it and who is looking: Follow is decided again only when one of them changes. */
  private readonly followKey = computed(() => {
    const c = this.comment();
    return `${c.id}|${c.author?.id ?? ''}|${this.myId() ?? ''}`;
  });
  /**
   * "متابعة" shows when you don't follow the writer (the API's `isFollowingAuthor`, or a follow since) and it isn't
   * you; guests see it too and get the sign-in prompt. Decided when the comment arrives, so the button stays to show
   * "بتتابعه" after a tap, and to undo; every button of that writer changes together (FollowStore, F12).
   */
  protected readonly showFollow = linkedSignal({
    source: this.followKey,
    computation: () =>
      untracked(() => {
        const c = this.comment();
        const viewer = this.myId();
        if (c.pending || !c.author || isPlaceholder(c) || c.author.id === viewer) return false;
        return !viewer || !this.follows.isFollowing(c.author.id, c.isFollowingAuthor ?? false);
      }),
  });
  protected readonly highlighted = computed(() => this.store.highlighted().has(this.comment().id));
  protected readonly segments = computed(() => commentSegments(this.comment().body, this.comment().mentions));
  protected readonly bodyDir = computed(() => commentDir(this.comment().body) ?? 'ltr');
  protected readonly editing = computed(() => {
    const target = this.store.composer();
    return target?.kind === 'edit' && target.commentId === this.comment().id;
  });

  protected readonly menuItems = computed<MenuItem[]>(() => {
    const c = this.comment();
    if (c.pending || isPlaceholder(c)) return [];
    const items: MenuItem[] = [];
    if (c.canEdit) items.push({ action: 'edit', label: 'comments.edit', icon: 'Pencil' });
    if (c.canPin) items.push(c.isPinned ? { action: 'unpin', label: 'comments.unpin', icon: 'PinOff' } : { action: 'pin', label: 'comments.pin', icon: 'Pin' });
    // F28: mute the commenter (not yourself, not a deleted account), right before Report; guests get the sign-in prompt.
    if (c.author && c.author.id !== this.myId()) {
      items.push(
        this.commenterMuted()
          ? { action: 'muteCommenter', label: 'mute.menu.unmuteCommenter', icon: MUTE_ICON.Volume2 }
          : { action: 'muteCommenter', label: 'mute.menu.muteCommenter', icon: MUTE_ICON.VolumeX },
      );
    }
    // Guests may report too: they get the sign-in prompt first.
    if (c.canReport || !this.session.isAuthenticated()) items.push({ action: 'report', label: 'comments.report', icon: 'Flag' });
    if (c.canModerate) {
      items.push(c.isHidden ? { action: 'unhide', label: 'comments.moderation.unhide', icon: 'Eye' } : { action: 'hide', label: 'comments.moderation.hide', icon: 'EyeOff' });
    }
    if (c.canDelete) items.push({ action: 'delete', label: 'comments.delete', icon: 'Trash2', danger: true });
    else if (c.canModerate) items.push({ action: 'moderatorDelete', label: 'comments.moderation.delete', icon: 'Trash2', danger: true });
    return items;
  });

  /** Shows the collapsed comment, and moves focus to its writer's name (the button is gone). */
  protected reveal(): void {
    this.revealed.set(true);
    afterNextRender(() => this.host.nativeElement.querySelector<HTMLElement>('[data-comment-author]')?.focus(), { injector: this.injector });
  }

  protected like(): void {
    if (this.prompt.requireAuth()) void this.store.toggleLike(this.comment().id);
  }

  protected reply(): void {
    if (this.prompt.requireAuth()) this.store.openReply(this.threadId(), this.comment());
  }

  protected run(action: MenuAction): void {
    const c = this.comment();
    switch (action) {
      case 'edit':
        this.draft.set(c.body ?? '');
        this.editError.set(null);
        this.store.openEdit(c.id);
        return;
      case 'delete':
      case 'moderatorDelete':
        this.store.openDialog({ kind: action, comment: c });
        return;
      case 'muteCommenter':
        if (!this.prompt.requireAuth() || !c.author) return;
        void (this.commenterMuted()
          ? this.mutes.unmuteAuthor({ id: c.author.id, displayName: c.author.displayName })
          : this.mutes.muteAuthor({ id: c.author.id, displayName: c.author.displayName }));
        return;
      case 'report':
        if (this.prompt.requireAuth()) this.store.openDialog({ kind: 'report', comment: c });
        return;
      case 'pin':
      case 'unpin':
        this.store.togglePin(c.id).catch((error: unknown) => this.toasts.error(this.errors.message(error)));
        return;
      case 'hide':
      case 'unhide':
        this.store
          .moderate(c.id, action)
          .then(() => this.toasts.success(this.transloco.translate(action === 'hide' ? 'comments.moderation.hidden' : 'comments.moderation.unhidden')))
          .catch((error: unknown) => this.toasts.error(this.errors.message(error)));
        return;
    }
  }

  protected async saveEdit(body: string): Promise<void> {
    if (this.saving()) return;
    if (body.trim() === (this.comment().body ?? '').trim()) {
      this.store.closeComposer();
      return;
    }
    this.saving.set(true);
    this.editError.set(null);
    try {
      await this.store.edit(this.comment().id, body);
      this.store.closeComposer();
    } catch (error) {
      this.editError.set(this.errors.message(error));
    } finally {
      this.saving.set(false);
    }
  }
}
