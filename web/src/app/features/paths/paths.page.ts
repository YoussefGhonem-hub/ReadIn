import { ChangeDetectionStrategy, Component, DOCUMENT, DestroyRef, Injector, afterNextRender, inject } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ScrollRow } from '../../shared/ui/scroll-row';
import { PathCard, PathCardSkeleton } from './path-card';
import { PathSeoService } from './path-seo.service';
import { PathsStore, PathsTab } from './paths.store';
import { reloadOnSessionChange } from './session-change';

/**
 * Learning paths (F09), `/paths`: All paths (server-rendered, guests welcome) and My paths (signed in; a guest gets the
 * sign-in prompt), with field chips built from the paths in the open list. Signed in, cards show your progress.
 */
@Component({
  selector: 'rd-paths-page',
  imports: [TranslocoPipe, BdiText, EmptyState, ErrorState, PathCard, PathCardSkeleton, ScrollRow],
  providers: [PathsStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto flex max-w-[720px] flex-col gap-2 px-4 pt-5 lg:pt-8' },
  template: `
    <!-- The header card: title, the tabs edge to edge, then the field chips. Under the chips the tab row has a line;
         without them the active tab's line is the card's edge. The path cards follow, 8px apart. -->
    <div class="rd-card p-0 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" data-paths-header>
      <header class="px-4 pb-1 pt-4 lg:px-5 lg:pt-5">
        <h1 class="m-0 text-xl font-bold lg:text-2xl">{{ 'paths.title' | transloco }}</h1>
        <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'paths.sub' | transloco }}</p>
      </header>

      <div
        class="flex gap-6 px-4 lg:px-5"
        [class]="store.fields().length > 1 ? 'border-b border-border' : ''"
        role="tablist"
        [attr.aria-label]="'paths.tabs.label' | transloco"
      >
        @for (tab of tabs; track tab) {
          <button
            type="button"
            role="tab"
            [id]="'paths-tab-' + tab"
            aria-controls="paths-panel"
            [attr.aria-selected]="store.tab() === tab"
            [attr.tabindex]="store.tab() === tab ? 0 : -1"
            [attr.data-paths-tab]="tab"
            class="-mb-px min-h-12 border-b-2 text-sm"
            [class]="store.tab() === tab ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary'"
            (click)="selectTab(tab)"
            (keydown)="onTabKey($event)"
          >
            {{ 'paths.tabs.' + tab | transloco }}
          </button>
        }
      </div>

      @if (store.fields().length > 1) {
        <div class="px-4 py-2 lg:px-5">
          <rd-scroll-row [label]="'paths.filterByField' | transloco" data-path-field-chips>
            <button type="button" class="rd-chip" [attr.aria-pressed]="!store.selectedField()" (click)="store.setField(null)">{{ 'paths.allFields' | transloco }}</button>
            @for (field of store.fields(); track field.id) {
              <button
                type="button"
                class="rd-chip"
                [attr.aria-pressed]="store.selectedField() === field.slug"
                [attr.data-path-field-chip]="field.slug"
                (click)="store.setField(field.slug)"
              >
                <rd-bdi-text [text]="lang() === 'ar' ? field.nameAr : field.nameEn" />
              </button>
            }
          </rd-scroll-row>
        </div>
      }
    </div>

    <section id="paths-panel" role="tabpanel" [attr.aria-labelledby]="'paths-tab-' + store.tab()" aria-live="polite" data-paths-list>
      @switch (store.status()) {
        @case ('error') {
          <rd-error-state class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" [message]="'paths.loadError' | transloco" (retry)="store.retry()" />
        }
        @case ('loaded') {
          <ul class="m-0 flex list-none flex-col gap-2 p-0">
            @for (path of store.visible(); track path.id) {
              <li><rd-path-card [path]="path" /></li>
            }
          </ul>
          @if (!store.visible().length) {
            @if (store.tab() === 'mine') {
              <rd-empty-state
                class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0"
                [title]="'paths.mineEmpty.title' | transloco"
                [message]="'paths.mineEmpty.body' | transloco"
                data-paths-mine-empty
              >
                <button type="button" class="rd-btn rd-btn-primary mt-3" (click)="selectTab('all')">{{ 'paths.mineEmpty.browse' | transloco }}</button>
              </rd-empty-state>
            } @else {
              <rd-empty-state
                class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0"
                [title]="'paths.empty.title' | transloco"
                [message]="'paths.empty.body' | transloco"
                data-paths-empty
              />
            }
          }
        }
        @default {
          <div class="flex flex-col gap-2" aria-busy="true">
            @for (i of [1, 2, 3]; track i) {
              <rd-path-card-skeleton />
            }
          </div>
        }
      }
    </section>
  `,
})
export class PathsPage {
  protected readonly store = inject(PathsStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly language = inject(LanguageService);
  private readonly document = inject(DOCUMENT);
  private readonly injector = inject(Injector);
  protected readonly lang = this.language.lang;
  protected readonly tabs: PathsTab[] = ['all', 'mine'];

  constructor() {
    const seo = inject(PathSeoService);
    seo.list();
    inject(DestroyRef).onDestroy(() => seo.clear());
    void this.store.loadAll();
    // Your progress once signed in; signing out forgets My paths.
    reloadOnSessionChange((signedIn) => {
      if (!signedIn) this.store.forgetMine();
      void this.store.loadAll();
      if (signedIn && this.store.tab() === 'mine') void this.store.loadMine();
    });
  }

  protected selectTab(tab: PathsTab): void {
    if (tab === 'mine' && !this.prompt.requireAuth()) return;
    this.store.setTab(tab);
  }

  /** Arrow keys move between the tabs (mirrored in RTL). */
  protected onTabKey(event: KeyboardEvent): void {
    const rtl = this.language.dir() === 'rtl';
    const step = { ArrowRight: rtl ? -1 : 1, ArrowLeft: rtl ? 1 : -1 }[event.key];
    if (!step) return;
    event.preventDefault();
    const index = (this.tabs.indexOf(this.store.tab()) + step + this.tabs.length) % this.tabs.length;
    const tab = this.tabs[index];
    this.selectTab(tab);
    if (this.store.tab() === tab) afterNextRender(() => this.document.getElementById(`paths-tab-${tab}`)?.focus(), { injector: this.injector });
  }
}
