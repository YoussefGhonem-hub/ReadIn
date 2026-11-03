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

@Component({
  selector: 'rd-hero-skeleton',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'rd-card block overflow-hidden', 'aria-hidden': 'true' },
  template: `
    <div class="rd-skeleton h-36 rounded-none"></div>
    <div class="flex flex-col gap-2 p-4">
      <div class="rd-skeleton h-3 w-24"></div>
      <div class="rd-skeleton h-5 w-full"></div>
      <div class="rd-skeleton h-5 w-3/4"></div>
    </div>
  `,
})
export class HeroSkeleton {}

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
