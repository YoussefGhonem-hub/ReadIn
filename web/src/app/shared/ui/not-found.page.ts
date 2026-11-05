import { ChangeDetectionStrategy, Component, RESPONSE_INIT, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { EmptyState } from './states';

@Component({
  selector: 'rd-not-found-page',
  imports: [RouterLink, TranslocoPipe, EmptyState],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pb-10 pt-5 lg:pt-8' },
  template: `
    <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0">
      <rd-empty-state class="py-16" [title]="'notFound.title' | transloco" [message]="'notFound.body' | transloco">
        <a routerLink="/" class="rd-btn rd-btn-primary mt-3">{{ 'comingSoon.backHome' | transloco }}</a>
      </rd-empty-state>
    </div>
  `,
})
export class NotFoundPage {
  constructor() {
    const response = inject(RESPONSE_INIT, { optional: true });
    if (response) response.status = 404;
  }
}
