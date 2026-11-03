import { ChangeDetectionStrategy, Component, input, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';

/** A seeded local user (SPEC §18.3). Fictional numbers from the reserved +1 202 555 01XX range. */
export interface DevSeedUser {
  phone: string;
  name: string;
  roles: string;
  hasPin: boolean;
}

export const DEV_SEED_USERS: readonly DevSeedUser[] = [
  { phone: '+12025550101', name: 'Super Admin', roles: 'SuperAdmin', hasPin: true },
  { phone: '+12025550102', name: 'Admin User', roles: 'Admin', hasPin: true },
  { phone: '+12025550103', name: 'Moderator User', roles: 'Moderator', hasPin: true },
  { phone: '+12025550104', name: '.NET Reviewer', roles: 'Reviewer · VerifiedWriter', hasPin: true },
  { phone: '+12025550105', name: 'AI Reviewer', roles: 'Reviewer · VerifiedWriter', hasPin: true },
  { phone: '+12025550106', name: 'Verified Writer', roles: 'VerifiedWriter', hasPin: true },
  ...[1, 2, 3].map((n) => ({ phone: `+120255501${String(6 + n).padStart(2, '0')}`, name: `Writer ${n}`, roles: 'Member', hasPin: true })),
  ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => ({ phone: `+120255501${String(9 + n).padStart(2, '0')}`, name: `Reader ${n}`, roles: 'Member', hasPin: true })),
  { phone: '+12025550119', name: 'Reader 10', roles: 'Member', hasPin: false },
  { phone: '+12025550120', name: 'Suspended User', roles: 'Member (suspended)', hasPin: false },
];

/** The developer's `Seed:DemoPassword`, kept in this browser only (development builds only). */
const DEMO_PASSWORD_KEY = 'readin.dev.demoPassword';

function readDemoPassword(): string {
  try {
    return localStorage.getItem(DEMO_PASSWORD_KEY) ?? '';
  } catch {
    return '';
  }
}

/**
 * Dev login panel (SPEC §18.3), compiled into development builds only. Lists the seed users with a PIN ✅/❌
 * indicator. Picking one fills the number and signs in when a demo password is saved here, otherwise it focuses the
 * password field.
 */
@Component({
  selector: 'rd-dev-login-panel',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mt-6 block', 'data-dev-login': '' },
  template: `
    <details class="rounded-md border border-dashed border-border p-3 text-sm">
      <summary class="cursor-pointer font-semibold">
        <svg lucideIcon="Wrench" [size]="14" class="me-1 inline align-[-2px]" aria-hidden="true"></svg>{{ 'auth.dev.title' | transloco }}
      </summary>
      <p class="m-0 mt-2 text-xs text-text-secondary">{{ 'auth.dev.hint' | transloco }}</p>
      <label class="rd-label mt-3" for="dev-demo-password">{{ 'auth.dev.demoPassword' | transloco }}</label>
      <input
        id="dev-demo-password"
        class="rd-input"
        type="password"
        dir="ltr"
        autocomplete="off"
        [value]="demoPassword()"
        (change)="saveDemoPassword($event)"
      />
      <ul class="m-0 mt-3 grid list-none gap-1 p-0">
        @for (user of users; track user.phone) {
          <li>
            <button type="button" class="flex w-full items-center gap-2 rounded-sm px-2 py-1.5 text-start hover:bg-surface-variant" (click)="choose(user)" [attr.data-dev-user]="user.phone">
              <span class="min-w-0 flex-1">
                <span class="block truncate font-semibold"><bdi>{{ user.name }}</bdi></span>
                <span class="block truncate text-xs text-text-secondary"><bdi>{{ user.roles }}</bdi></span>
              </span>
              <span class="font-latin text-xs text-text-secondary" dir="ltr">{{ user.phone }}</span>
              <span class="w-14 text-end text-xs" [attr.aria-label]="(user.hasPin ? 'auth.dev.pin' : 'auth.dev.noPin') | transloco">
                PIN {{ user.hasPin ? '✅' : '❌' }}
              </span>
            </button>
          </li>
        }
      </ul>
    </details>
  `,
})
export class DevLoginPanel {
  /** Called with the seed user's number and the saved demo password (null when none is saved). */
  readonly pick = input.required<(phone: string, password: string | null) => void>();

  protected readonly users = DEV_SEED_USERS;
  protected readonly demoPassword = signal(readDemoPassword());

  protected saveDemoPassword(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.demoPassword.set(value);
    try {
      if (value) localStorage.setItem(DEMO_PASSWORD_KEY, value);
      else localStorage.removeItem(DEMO_PASSWORD_KEY);
    } catch {
      /* storage blocked: keep it for this page only */
    }
  }

  protected choose(user: DevSeedUser): void {
    this.pick()(user.phone, this.demoPassword() || null);
  }
}
