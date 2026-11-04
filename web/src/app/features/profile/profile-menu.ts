import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { CdkMenu, CdkMenuItem, CdkMenuTrigger } from '@angular/cdk/menu';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ProfileDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { ModerationActionDraft, ModerationActionSheet } from '../../shared/moderation/moderation-action-sheet';
import { provideModerationIcons } from '../../shared/moderation/moderation-icons';
import { ReportSheet, ReportTarget } from '../../shared/moderation/report-sheet';

type ProfileMenuAction = 'report' | 'warn' | 'suspend';

interface ProfileMenuItem {
  id: ProfileMenuAction;
  labelKey: string;
  icon: string;
  danger?: boolean;
}

/**
 * The "⋯" on someone else's profile (F22): Report user for everyone (guests get the sign-in prompt). Moderators can
 * also Warn (with a note the user sees) and, with `users.suspend`, Suspend the account for 1, 7 or 30 days or for good.
 */
@Component({
  selector: 'rd-profile-menu',
  imports: [TranslocoPipe, LucideDynamicIcon, CdkMenu, CdkMenuItem, CdkMenuTrigger, ReportSheet, ModerationActionSheet],
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
    <rd-moderation-action-sheet [draft]="moderating()" (closed)="moderating.set(null)" />
  `,
})
export class ProfileMenu {
  private readonly session = inject(SessionStore);
  private readonly prompt = inject(AuthPromptService);

  readonly profile = input.required<ProfileDto>();

  protected readonly reporting = signal<ReportTarget | null>(null);
  protected readonly moderating = signal<ModerationActionDraft | null>(null);

  protected readonly items = computed<ProfileMenuItem[]>(() => {
    const permissions = this.session.permissions();
    const items: ProfileMenuItem[] = [];
    if (permissions.has('moderation.manage')) {
      items.push({ id: 'warn', labelKey: 'profile.menu.warn', icon: 'TriangleAlert' });
      if (permissions.has('users.suspend')) items.push({ id: 'suspend', labelKey: 'profile.menu.suspend', icon: 'Ban', danger: true });
    }
    items.push({ id: 'report', labelKey: 'profile.menu.report', icon: 'Flag', danger: true });
    return items;
  });

  protected run(action: ProfileMenuAction): void {
    if (!this.prompt.requireAuth()) return;
    const p = this.profile();
    if (action === 'report') this.reporting.set({ type: 'user', id: p.id });
    else this.moderating.set({ action, targetType: 'user', targetId: p.id, name: p.displayName });
  }
}
