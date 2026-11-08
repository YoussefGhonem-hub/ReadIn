import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { CdkMenu, CdkMenuItem, CdkMenuTrigger } from '@angular/cdk/menu';
import { Router } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon, LucideIconData } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ModerationActionRequest, ProfileDto } from '../../core/api/models';
import { VerificationApi } from '../../core/api/verification.api';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { isolate } from '../../shared/directives/bidi';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { BlockStore, BlockedPersonRef } from '../../core/social/block.store';
import { MuteStore } from '../../core/social/mute.store';
import { BlockDialog } from '../../shared/blocks/block-dialog';
import { BLOCK_ICON } from '../../shared/blocks/block-icons';
import { MUTE_ICON } from '../../shared/mutes/mute-icons';
import { ModerationActionDraft, ModerationActionSheet } from '../../shared/moderation/moderation-action-sheet';
import { provideModerationIcons } from '../../shared/moderation/moderation-icons';
import { ReportSheet, ReportTarget } from '../../shared/moderation/report-sheet';

type ProfileMenuAction = 'muteUser' | 'blockUser' | 'report' | 'warn' | 'suspend' | 'unsuspend' | 'removeBadge' | 'openInConsole';

interface ProfileMenuItem {
  id: ProfileMenuAction;
  labelKey: string;
  icon: string | LucideIconData;
  danger?: boolean;
}

/**
 * The "⋯" on someone else's profile (F22): Mute user first (F28; not on the official account, which can't be muted),
 * then Report user, for everyone (guests get the sign-in prompt). Mute works like the article menu's Mute author: the
 * toast has Undo, which follows again when the mute ended your follow; the profile then shows the muted banner.
 * Moderators can also Warn (with a note the user sees) and, with `users.suspend`, Suspend the account (F23's form: 1, 3,
 * 7 or 30 days, a custom length or for good, optionally hiding all their content) or Unsuspend it; never staff
 * (`ProfileDto.admin.isStaff`, F23). With `verification.manage`, Remove verified badge (confirmed); with `users.read` and
 * the console, Open in console.
 */
@Component({
  selector: 'rd-profile-menu',
  imports: [TranslocoPipe, LucideDynamicIcon, CdkMenu, CdkMenuItem, CdkMenuTrigger, ReportSheet, ModerationActionSheet, BottomSheet, BlockDialog],
  providers: [provideModerationIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents' },
  template: `
    <button
      type="button"
      class="rd-icon-btn h-11 w-11"
      [cdkMenuTriggerFor]="menu"
      [attr.aria-label]="'profile.menu.label' | transloco"
      data-profile-menu
    >
      <svg lucideIcon="Ellipsis" [size]="20" aria-hidden="true"></svg>
    </button>

    <ng-template #menu>
      <div cdkMenu class="min-w-52 rounded-md border border-border bg-surface-raised p-1 shadow-raised" data-profile-menu-panel>
        @for (item of items(); track item.id) {
          <button
            type="button"
            cdkMenuItem
            class="flex min-h-11 w-full items-center gap-2 rounded-sm px-3 text-start text-sm hover:bg-surface-variant"
            [class]="item.danger ? 'text-error' : 'text-text-primary'"
            [attr.data-menu-action]="item.id"
            (cdkMenuItemTriggered)="run(item.id)"
          >
            <svg [lucideIcon]="item.icon" [size]="16" aria-hidden="true"></svg>
            {{ item.labelKey | transloco }}
          </button>
        }
      </div>
    </ng-template>

    <rd-report-sheet [target]="reporting()" (closed)="reporting.set(null)" />
    <rd-block-dialog [person]="blocking()" (closed)="blocking.set(null)" />
    <rd-moderation-action-sheet [draft]="moderating()" (done)="onModerated($event)" (closed)="moderating.set(null)" />
    <!-- F23: removing the Verified badge asks first -->
    <rd-bottom-sheet [open]="removingBadge()" role="alertdialog" labelledBy="remove-badge-title" describedBy="remove-badge-body" [dismissible]="!badgeBusy()" (closed)="removingBadge.set(false)">
      @if (removingBadge()) {
        <div class="flex flex-col gap-3 pt-1" data-remove-badge-sheet>
          <h2 id="remove-badge-title" class="m-0 pe-10 text-xl font-semibold">{{ 'verification.admin.removeBadgeSheet.title' | transloco: { name: isolate(profile().displayName) } }}</h2>
          <p id="remove-badge-body" class="m-0 text-sm text-text-secondary">{{ 'verification.admin.removeBadgeSheet.body' | transloco }}</p>
          @if (badgeError()) {
            <p class="rd-alert rd-alert-error m-0" role="alert">{{ badgeError() }}</p>
          }
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="badgeBusy()" (click)="removingBadge.set(false)">{{ 'common.cancel' | transloco }}</button>
            <button type="button" class="rd-btn flex-1 bg-error text-on-error" [disabled]="badgeBusy()" (click)="removeBadge()" data-remove-badge-confirm>{{ 'admin.confirm.ok' | transloco }}</button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class ProfileMenu {
  private readonly session = inject(SessionStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly mutes = inject(MuteStore);
  private readonly blocks = inject(BlockStore);
  private readonly router = inject(Router);
  private readonly verification = inject(VerificationApi);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);

  readonly profile = input.required<ProfileDto>();

  protected readonly reporting = signal<ReportTarget | null>(null);
  protected readonly moderating = signal<ModerationActionDraft | null>(null);

  /** F23: the account is suspended now (`admin`, for users.read holders), or after an action here. */
  private readonly suspendedNow = signal<boolean | null>(null);
  private readonly suspended = computed(() => this.suspendedNow() ?? this.profile().admin?.isSuspended ?? false);
  private readonly verifiedNow = signal<boolean | null>(null);
  private readonly verified = computed(() => this.verifiedNow() ?? this.profile().isVerified);
  protected readonly removingBadge = signal(false);
  protected readonly badgeBusy = signal(false);
  protected readonly badgeError = signal<string | null>(null);
  protected readonly isolate = isolate;

  /** F36: you blocked them (in this session); the dialog is open for this person. */
  protected readonly blocked = computed(() => this.session.isAuthenticated() && this.blocks.isBlocked(this.profile().id));
  protected readonly blocking = signal<BlockedPersonRef | null>(null);

  /** You muted this user (false for guests). */
  private readonly muted = computed(() => {
    const p = this.profile();
    return this.session.isAuthenticated() && this.mutes.isAuthorMuted(p.id, p.isMuted ?? false);
  });

  protected readonly items = computed<ProfileMenuItem[]>(() => {
    const permissions = this.session.permissions();
    const p = this.profile();
    const items: ProfileMenuItem[] = [];
    if (!p.isMe && !p.isSystemAccount) {
      items.push(
        this.muted()
          ? { id: 'muteUser', labelKey: 'mute.menu.unmuteUser', icon: MUTE_ICON.Volume2 }
          : { id: 'muteUser', labelKey: 'mute.menu.muteUser', icon: MUTE_ICON.VolumeX },
      );
    }
    // F36: Block under Mute; the official account can be blocked too.
    if (!p.isMe) {
      items.push(
        this.blocked()
          ? { id: 'blockUser', labelKey: 'block.menu.unblock', icon: BLOCK_ICON.UserRoundCheck }
          : { id: 'blockUser', labelKey: 'block.menu.blockUser', icon: BLOCK_ICON.UserRoundX, danger: true },
      );
    }
    // F23: staff (admins, moderators, the official account) can't be warned or suspended; `admin` comes with users.read.
    const staff = p.admin?.isStaff ?? false;
    if (permissions.has('moderation.manage') && !staff) {
      items.push({ id: 'warn', labelKey: 'profile.menu.warn', icon: 'TriangleAlert' });
      if (permissions.has('users.suspend')) {
        items.push(
          this.suspended()
            ? { id: 'unsuspend', labelKey: 'profile.menu.unsuspend', icon: 'UserRoundCheck' }
            : { id: 'suspend', labelKey: 'profile.menu.suspend', icon: 'Ban', danger: true },
        );
      }
    }
    if (permissions.has('verification.manage') && this.verified() && !p.isSystemAccount) {
      items.push({ id: 'removeBadge', labelKey: 'profile.menu.removeBadge', icon: 'BadgeCheck', danger: true });
    }
    // The console needs admin.access too.
    if (permissions.has('users.read') && permissions.has('admin.access')) {
      items.push({ id: 'openInConsole', labelKey: 'profile.menu.openInConsole', icon: 'LayoutDashboard' });
    }
    items.push({ id: 'report', labelKey: 'profile.menu.report', icon: 'Flag', danger: true });
    return items;
  });

  protected run(action: ProfileMenuAction): void {
    if (!this.prompt.requireAuth()) return;
    const p = this.profile();
    const user = { id: p.id, displayName: p.displayName };
    if (action === 'muteUser') void (this.muted() ? this.mutes.unmuteAuthor(user) : this.mutes.muteAuthor(user));
    else if (action === 'report') this.reporting.set({ type: 'user', id: p.id, author: { id: p.id, displayName: p.displayName, username: p.username } });
    else if (action === 'blockUser') {
      const person = { id: p.id, displayName: p.displayName, username: p.username };
      if (this.blocked()) void this.blocks.unblock(person);
      else this.blocking.set(person);
    }
    else if (action === 'openInConsole') void this.router.navigate(['/admin/users', p.id]);
    else if (action === 'removeBadge') {
      this.badgeError.set(null);
      this.removingBadge.set(true);
    } else this.moderating.set({ action, targetType: 'user', targetId: p.id, name: p.displayName });
  }

  /** After a suspend or unsuspend (F23): the menu offers the other one. */
  protected onModerated(request: ModerationActionRequest): void {
    if (request.action === 'suspend' || request.action === 'unsuspend') this.suspendedNow.set(request.action === 'suspend');
  }

  /** Remove verified badge (F19, F23), after the dialog: nothing is sent to the user. */
  protected async removeBadge(): Promise<void> {
    const p = this.profile();
    if (this.badgeBusy()) return;
    this.badgeBusy.set(true);
    this.badgeError.set(null);
    try {
      await firstValueFrom(this.verification.removeBadge(p.id));
      this.verifiedNow.set(false);
      this.toasts.success(this.transloco.translate('verification.admin.badgeRemoved', { name: isolate(p.displayName) }));
      this.badgeBusy.set(false);
      this.removingBadge.set(false);
    } catch (error) {
      this.badgeError.set(this.errors.forError(error));
    } finally {
      this.badgeBusy.set(false);
    }
  }
}
