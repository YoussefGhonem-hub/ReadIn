import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SessionStore } from '../../core/auth/session.store';
import { PublicStatsSwitch } from '../profile/public-stats-switch';

/** Settings → Profile (edit / view your profile) and Privacy (F14, F18): public reading stats on or off. */
@Component({
  selector: 'rd-profile-settings',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, PublicStatsSwitch],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    @if (session.isAuthenticated()) {
      <section class="rd-card mb-5 p-5 shadow-none" aria-labelledby="settings-profile" data-settings-profile>
        <h2 id="settings-profile" class="m-0 mb-2 text-base font-semibold">{{ 'settings.profile.title' | transloco }}</h2>
        <ul class="m-0 list-none divide-y divide-border p-0">
          <li>
            <a routerLink="/settings/profile" class="flex min-h-12 items-center gap-3 text-sm text-text-primary no-underline" data-settings-edit-profile>
              <svg lucideIcon="Pencil" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
              <span class="flex-1">{{ 'settings.profile.edit' | transloco }}</span>
              <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
            </a>
          </li>
          <li>
            <a [routerLink]="'/@' + session.username()" class="flex min-h-12 items-center gap-3 text-sm text-text-primary no-underline">
              <svg lucideIcon="UserRound" [size]="18" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
              <span class="flex-1">{{ 'settings.profile.view' | transloco }}</span>
              <bdi dir="ltr" class="text-xs text-text-secondary">&#64;{{ session.username() }}</bdi>
              <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl shrink-0 text-text-secondary" aria-hidden="true"></svg>
            </a>
          </li>
        </ul>
      </section>
    }

    <section class="rd-card mb-5 p-5 shadow-none" aria-labelledby="settings-privacy" data-settings-privacy>
      <h2 id="settings-privacy" class="m-0 mb-3 text-base font-semibold">{{ 'settings.privacy.title' | transloco }}</h2>
      @if (session.isAuthenticated()) {
        <rd-public-stats-switch labelKey="settings.privacy.publicStats" hintKey="settings.privacy.publicStatsHint" />
      } @else {
        <p class="m-0 text-sm text-text-secondary">{{ 'settings.privacy.signIn' | transloco }}</p>
      }
    </section>
  `,
})
export class ProfileSettings {
  protected readonly session = inject(SessionStore);
}
