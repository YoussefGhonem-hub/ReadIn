import { Injectable, PendingTasks, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { FieldDto } from '../../core/api/models';
import { TaxonomyApi } from '../../core/api/taxonomy.api';

/**
 * The fields' icons and colors for path covers without an image (F09): a path card only carries a `FieldRefDto`.
 * `GET /fields` is loaded once, on the first cover that needs it (SSR waits for it, the browser reuses that answer).
 */
@Injectable({ providedIn: 'root' })
export class FieldCatalog {
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly tasks = inject(PendingTasks);
  private readonly fields = signal<FieldDto[]>([]);
  private loading: Promise<void> | null = null;

  readonly byId = computed(() => new Map(this.fields().map((f) => [f.id, f])));

  load(): Promise<void> {
    this.loading ??= (async () => {
      // SSR waits for the icons, like for the rest of the page.
      const done = this.tasks.add();
      try {
        this.fields.set(await firstValueFrom(this.taxonomy.fields()));
      } catch {
        this.loading = null; // covers fall back to the path icon; the next cover tries again
      } finally {
        done();
      }
    })();
    return this.loading;
  }
}
