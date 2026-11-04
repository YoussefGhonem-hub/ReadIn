import { ChangeDetectionStrategy, Component, DOCUMENT, DestroyRef, Injector, afterNextRender, inject } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { BdiText } from '../../shared/directives/bdi-text';
import { EmptyState, ErrorState } from '../../shared/ui/states';
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
  imports: [TranslocoPipe, BdiText, EmptyState, ErrorState, PathCard, PathCardSkeleton],
  providers: [PathsStore],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pt-5 lg:pt-8' },
  template: `
    <header class="mb-4">
      <h1 class="m-0 text-2xl font-bold">{{ 'paths.title' | transloco }}</h1>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'paths.sub' | transloco }}</p>
    </header>

    <div class="mb-3 flex gap-6 border-b border-border" role="tablist" [attr.aria-label]="'paths.tabs.label' | transloco">
      @for (tab of tabs; track tab) {
        <button
          type="button"
          role="tab"
          [id]="'paths-tab-' + tab"
          aria-controls="paths-panel"
          [attr.aria-selected]="store.tab() === tab"
          [attr.tabindex]="store.tab() === tab ? 0 : -1"
          [attr.data-paths-tab]="tab"
          class="-mb-px min-h-11 border-b-2 text-sm"
          [class]="store.tab() === tab ? 'border-primary font-bold text-primary' : 'border-transparent text-text-secondary'"
          (click)="selectTab(tab)"
          (keydown)="onTabKey($event)"
        >
          {{ 'paths.tabs.' + tab | transloco }}
        </button>
      }
    </div>

    @if (store.fields().length > 1) {
      <div class="-mx-4 mb-3 flex gap-2 overflow-x-auto px-4 pb-1" role="toolbar" [attr.aria-label]="'paths.filterByField' | transloco" data-path-field-chips>
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
      </div>
    }

    <section id="paths-panel" role="tabpanel" [attr.aria-labelledby]="'paths-tab-' + store.tab()" aria-live="polite" data-paths-list>
      @switch (store.status()) {
        @case ('error') {
          <rd-error-state [message]="'paths.loadError' | transloco" (retry)="store.retry()" />
        }
        @case ('loaded') {
          <ul class="m-0 flex list-none flex-col gap-3 p-0">
            @for (path of store.visible(); track path.id) {
              <li><rd-path-card [path]="path" /></li>
            }
          </ul>
          @if (!store.visible().length) {
            @if (store.tab() === 'mine') {
              <rd-empty-state [title]="'paths.mineEmpty.title' | transloco" [message]="'paths.mineEmpty.body' | transloco" data-paths-mine-empty>
                <button type="button" class="rd-btn rd-btn-primary mt-3" (click)="selectTab('all')">{{ 'paths.mineEmpty.browse' | transloco }}</button>
              </rd-empty-state>
            } @else {
              <rd-empty-state [title]="'paths.empty.title' | transloco" [message]="'paths.empty.body' | transloco" data-paths-empty />
            }
          }
        }
        @default {
          <div class="flex flex-col gap-3" aria-busy="true">
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
