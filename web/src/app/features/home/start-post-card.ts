import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { SessionStore } from '../../core/auth/session.store';
import { Avatar } from '../../shared/ui/avatar';

interface StartAction {
  id: 'photo' | 'pdf' | 'article';
  labelKey: string;
  icon: string;
  /** A token color for the icon. */
  tone: string;
}

/**
 * "Start a post" on Home (signed in, with `articles.create`): your avatar and a rounded "Start a post…" that opens the
 * editor, and Photo / PDF / Article under it. The editor has no way yet to open on its image or PDF picker, so all three
 * open a new article (the attachments are one click away there). Nothing for guests.
 */
@Component({
  selector: 'rd-start-post-card',
  imports: [RouterLink, TranslocoPipe, LucideDynamicIcon, Avatar],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { '[class]': "visible() ? 'block' : 'hidden'" },
  template: `
    @if (visible()) {
      <section class="rd-card px-4 pb-2 pt-3 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [attr.aria-label]="'home.startPost.label' | transloco" data-start-post>
        <div class="flex items-center gap-3">
          <rd-avatar [name]="session.displayName()" [src]="session.avatarUrl()" [size]="48" />
          <a
            routerLink="/write/new"
            class="flex min-h-12 min-w-0 flex-1 items-center rounded-chip border border-border px-4 text-sm font-semibold text-text-secondary no-underline transition-colors hover:bg-surface-variant hover:text-text-primary"
            data-start-post-prompt
            ><span class="truncate">{{ 'home.startPost.prompt' | transloco }}</span></a
          >
        </div>
        <div class="mt-1 flex items-center justify-around gap-1">
          @for (action of actions; track action.id) {
            <a
              routerLink="/write/new"
              class="flex min-h-11 items-center gap-2 rounded-md px-3 text-sm font-semibold text-text-secondary no-underline transition-colors hover:bg-surface-variant hover:text-text-primary"
              [attr.data-start-post-action]="action.id"
            >
              <svg [lucideIcon]="action.icon" [size]="20" [class]="action.tone" aria-hidden="true"></svg>
              {{ action.labelKey | transloco }}
            </a>
          }
        </div>
      </section>
    }
  `,
})
export class StartPostCard {
  protected readonly session = inject(SessionStore);
  protected readonly visible = computed(() => this.session.isAuthenticated() && this.session.hasPermission('articles.create'));
  protected readonly actions: readonly StartAction[] = [
    { id: 'photo', labelKey: 'home.startPost.photo', icon: 'Images', tone: 'text-callout-info-accent' },
    { id: 'pdf', labelKey: 'home.startPost.pdf', icon: 'FileText', tone: 'text-callout-danger-accent' },
    { id: 'article', labelKey: 'home.startPost.article', icon: 'SquarePen', tone: 'text-callout-tip-accent' },
  ];
}
