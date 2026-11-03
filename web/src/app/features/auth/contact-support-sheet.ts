import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { environment } from '../../../environments/environment';
import { BottomSheet } from '../../shared/ui/bottom-sheet';

/**
 * "Forgot the PIN too?" (SPEC §9.1, ADR 0009): the last fallback is support. An Admin checks it's the owner and resets
 * the account; the user then signs in with a temporary password, changes it and sets a new PIN.
 */
@Component({
  selector: 'rd-contact-support-sheet',
  imports: [BottomSheet, TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="open()" labelledBy="support-title" (closed)="closed.emit()">
      <div class="flex flex-col gap-4 pt-1" data-support>
        <span class="grid h-12 w-12 place-items-center rounded-card bg-primary-container text-on-primary-container" aria-hidden="true">
          <svg lucideIcon="LifeBuoy" [size]="24"></svg>
        </span>
        <h2 id="support-title" class="m-0 pe-10 text-xl font-semibold">{{ 'auth.support.title' | transloco }}</h2>
        <p class="m-0 text-sm text-text-secondary">{{ 'auth.support.body' | transloco }}</p>
        <ol class="m-0 flex flex-col gap-2 ps-5 text-sm">
          <li>{{ 'auth.support.step1' | transloco }}</li>
          <li>{{ 'auth.support.step2' | transloco }}</li>
          <li>{{ 'auth.support.step3' | transloco }}</li>
        </ol>
        <div class="rounded-md bg-surface-variant p-3 text-sm">
          <span class="block text-xs text-text-secondary">{{ 'auth.support.emailLabel' | transloco }}</span>
          <a class="font-latin font-semibold text-primary" dir="ltr" [href]="mailto">{{ email }}</a>
        </div>
        <button type="button" class="rd-btn rd-btn-primary w-full" (click)="closed.emit()">{{ 'auth.support.done' | transloco }}</button>
      </div>
    </rd-bottom-sheet>
  `,
})
export class ContactSupportSheet {
  readonly open = input(false);
  readonly closed = output<void>();

  protected readonly email = environment.supportEmail;
  protected readonly mailto = `mailto:${environment.supportEmail}?subject=${encodeURIComponent('ReadIn: forgot password and PIN')}`;
}
