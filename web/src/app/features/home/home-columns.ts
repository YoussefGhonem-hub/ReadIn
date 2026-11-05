import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { HomeEndRail } from './home-end-rail';
import { HomeLayout } from './home-layout';
import { HomeStartRail } from './home-start-rail';

/**
 * Home's three columns (LinkedIn's proportions, ReadIn's cards): from `xl` the profile, reading and shortcut cards
 * (sticky under the header) | the feed | suggestions, a suggested path and the footer links. From `lg` to `xl` the
 * suggestions go under the start column's cards. Below `lg` the feed alone, in today's centered column. The page's own
 * content is projected into the middle column.
 */
@Component({
  selector: 'rd-home-columns',
  imports: [TranslocoPipe, HomeStartRail, HomeEndRail],
  providers: [HomeLayout],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[1160px] px-4 pt-5 lg:pt-8' },
  styles: `
    .home-grid {
      display: block;
    }
    .home-main {
      max-width: 608px;
      margin-inline: auto;
    }
    .home-start,
    .home-end {
      display: none;
    }
    @media (min-width: 64rem) {
      .home-grid {
        display: grid;
        grid-template-columns: 225px minmax(0, 640px);
        grid-template-rows: auto 1fr;
        grid-template-areas:
          'start main'
          'end main';
        justify-content: center;
        align-items: start;
        column-gap: 24px;
        row-gap: 8px;
      }
      .home-main {
        grid-area: main;
        max-width: none;
        margin-inline: 0;
      }
      .home-start {
        display: block;
        grid-area: start;
      }
      .home-end {
        display: block;
        grid-area: end;
      }
    }
    @media (min-width: 80rem) {
      .home-grid {
        grid-template-columns: 225px minmax(0, 1fr) 300px;
        grid-template-rows: auto;
        grid-template-areas: 'start main end';
      }
      /* Short enough for any desktop window: it stays under the header while the feed scrolls. */
      .home-start {
        position: sticky;
        top: 88px;
      }
    }
  `,
  template: `
    <div class="home-grid">
      @if (layout.wide()) {
        <aside class="home-start" [attr.aria-label]="'home.rails.start' | transloco" data-home-start>
          <rd-home-start-rail />
        </aside>
      }
      <div class="home-main min-w-0">
        <ng-content />
      </div>
      @if (layout.wide()) {
        <aside class="home-end" [attr.aria-label]="'home.rails.end' | transloco" data-home-end>
          <rd-home-end-rail />
        </aside>
      }
    </div>
  `,
})
export class HomeColumns {
  protected readonly layout = inject(HomeLayout);
}
