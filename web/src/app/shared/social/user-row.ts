import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { BdiText } from '../directives/bdi-text';
import { Avatar } from '../ui/avatar';

export interface UserRowData {
  displayName: string;
  username: string;
  avatarUrl: string | null;
  isVerified: boolean;
}

/** A person in a list (who reacted, suggested writers): avatar, name, verified badge, @handle, optional bio, actions. */
@Component({
  selector: 'rd-user-row',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, BdiText, Avatar],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex items-center gap-3 py-2' },
  template: `
    <a [routerLink]="'/@' + user().username" class="flex min-w-0 flex-1 items-center gap-3 rounded-md text-inherit no-underline">
      <rd-avatar [name]="user().displayName" [src]="user().avatarUrl" [size]="40" />
      <span class="min-w-0 flex-1">
        <span class="flex items-center gap-1 font-semibold text-text-primary">
          <rd-bdi-text class="truncate" [text]="user().displayName" />
          @if (user().isVerified) {
            <svg lucideIcon="BadgeCheck" [size]="15" class="shrink-0 text-primary" [attr.aria-label]="'article.verifiedWriter' | transloco"></svg>
          }
        </span>
        <span class="block text-xs text-text-secondary"
          ><bdi dir="ltr">&#64;{{ user().username }}</bdi>
          @if (note()) {
            <span> · {{ note() }}</span>
          }
        </span>
        @if (bio()) {
          <!-- A bio is mixed text: its own paragraph direction (SPEC §14.2). -->
          <span class="mt-0.5 line-clamp-2 block text-sm text-text-secondary" dir="auto"><rd-bdi-text [text]="bio()!" /></span>
        }
      </span>
    </a>
    <ng-content />
  `,
})
export class UserRow {
  readonly user = input.required<UserRowData>();
  readonly bio = input<string | null>(null);
  /** A short note after the @handle (e.g. "Follows you"). */
  readonly note = input<string | null>(null);
}
