import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'rd-article-card-skeleton',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex gap-3 border-t border-border py-4 first:border-t-0', 'aria-hidden': 'true' },
  template: `
    <div class="rd-skeleton h-[72px] w-[72px] shrink-0 rounded-md"></div>
    <div class="flex flex-1 flex-col gap-2 pt-1">
      <div class="rd-skeleton h-3 w-16"></div>
      <div class="rd-skeleton h-4 w-full"></div>
      <div class="rd-skeleton h-4 w-2/3"></div>
      <div class="rd-skeleton h-3 w-1/3"></div>
    </div>
  `,
})
export class ArticleCardSkeleton {}

/** A post card (F34) while the feed loads: writer, title, text lines and the action bar. */
@Component({
  selector: 'rd-post-card-skeleton',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'rd-card block p-4 max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0', 'aria-hidden': 'true' },
  template: `
    <div class="flex items-center gap-3">
      <div class="rd-skeleton h-11 w-11 shrink-0 rounded-full"></div>
      <div class="flex flex-1 flex-col gap-2">
        <div class="rd-skeleton h-3 w-1/3"></div>
        <div class="rd-skeleton h-3 w-1/2"></div>
      </div>
    </div>
    <div class="rd-skeleton mt-4 h-5 w-4/5"></div>
    <div class="mt-3 flex flex-col gap-2">
      <div class="rd-skeleton h-4 w-full"></div>
      <div class="rd-skeleton h-4 w-full"></div>
      <div class="rd-skeleton h-4 w-2/3"></div>
    </div>
    <div class="mt-4 flex justify-around border-t border-border pt-3">
      <div class="rd-skeleton h-4 w-16"></div>
      <div class="rd-skeleton h-4 w-16"></div>
      <div class="rd-skeleton h-4 w-16"></div>
    </div>
  `,
})
export class PostCardSkeleton {}

@Component({
  selector: 'rd-lines-skeleton',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col gap-3', 'aria-hidden': 'true' },
  template: `
    @for (i of rows(); track i) {
      <div class="rd-skeleton h-4" [style.width.%]="i % 3 === 2 ? 60 : 100"></div>
    }
  `,
})
export class LinesSkeleton {
  readonly count = input(6);
  protected rows(): number[] {
    return Array.from({ length: this.count() }, (_, i) => i);
  }
}
