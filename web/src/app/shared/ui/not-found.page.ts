import { ChangeDetectionStrategy, Component, RESPONSE_INIT, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { EmptyState } from './states';

@Component({
  selector: 'rd-not-found-page',
  imports: [RouterLink, TranslocoPipe, EmptyState],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-empty-state class="py-24" [title]="'notFound.title' | transloco" [message]="'notFound.body' | transloco">
      <a routerLink="/" class="rd-btn rd-btn-primary mt-3">{{ 'comingSoon.backHome' | transloco }}</a>
    </rd-empty-state>
  `,
})
export class NotFoundPage {
  constructor() {
    const response = inject(RESPONSE_INIT, { optional: true });
    if (response) response.status = 404;
  }
}
