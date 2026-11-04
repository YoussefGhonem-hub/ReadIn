import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { PushService } from '../../../core/push/push.service';

/**
 * Web push in this browser (SPEC §21.1): its state, and "Turn on" while the browser hasn't been asked yet. The
 * permission is only ever requested from here, in context.
 */
@Component({
  selector: 'rd-push-permission-row',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex items-center justify-between gap-3 text-sm', '[attr.data-push-permission]': 'push.permission()' },
  template: `
    <div class="min-w-0">
      <div class="font-semibold">{{ 'settings.push.title' | transloco }}</div>
      <div class="text-text-secondary">{{ 'settings.push.' + push.permission() | transloco }}</div>
    </div>
    @if (push.permission() === 'default') {
      <button type="button" class="rd-btn rd-btn-outline min-h-9 shrink-0 px-3 text-sm" (click)="push.enable()" data-push-enable>
        {{ 'settings.push.enable' | transloco }}
      </button>
    }
  `,
})
export class PushPermissionRow {
  protected readonly push = inject(PushService);
}
