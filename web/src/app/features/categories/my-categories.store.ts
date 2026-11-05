import { Injectable, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { WriterCategoriesApi } from '../../core/api/categories.api';
import { WriterCategoryDto, WriterCategoryListDto } from '../../core/api/models';

export type MyCategoriesStatus = 'loading' | 'loaded' | 'error';

/**
 * The code to show for a failed category request: the name's or the order's validation code (`category.name_invalid`,
 * `category.limit`), else the error's own code (`category.name_taken`, `category.limit`, `network`, …).
 */
export function categoryErrorCode(error: unknown): string {
  if (!isApiError(error)) return 'unknown';
  if (error.code === 'validation.failed') {
    const errors = error.validationErrors;
    const first = [...(errors['name'] ?? []), ...(errors['categoryIds'] ?? []), ...Object.values(errors).flat()][0];
    if (first) return first;
  }
  return error.code;
}

/**
 * The signed-in writer's own categories (F31, `GET /me/categories`): all of them in their order, empty ones included,
 * with the uncategorized count. The profile's manage view and the editor's picker each provide their own. Writes
 * update the list from the server's answer; a reorder shows at once and goes back if the server refuses it.
 */
@Injectable()
export class MyCategoriesStore {
  private readonly api = inject(WriterCategoriesApi);

  readonly status = signal<MyCategoriesStatus>('loading');
  readonly items = signal<WriterCategoryDto[]>([]);
  readonly uncategorizedCount = signal(0);
  private generation = 0;

  async load(): Promise<void> {
    const generation = ++this.generation;
    if (this.status() !== 'loaded') this.status.set('loading');
    try {
      const list = await firstValueFrom(this.api.mine());
      if (generation !== this.generation) return;
      this.apply(list);
      this.status.set('loaded');
    } catch {
      if (generation === this.generation && this.status() !== 'loaded') this.status.set('error');
    }
  }

  /** `POST /me/categories`: added last. Rejects with the API error (name taken or invalid, the limit). */
  async create(name: string): Promise<WriterCategoryDto> {
    const created = await firstValueFrom(this.api.create(name));
    this.generation++;
    this.items.update((items) => [...items.filter((c) => c.id !== created.id), created]);
    return created;
  }

  /** `PATCH /me/categories/{id}`: the new name; the slug (and every link to it) stays. */
  async rename(id: string, name: string): Promise<WriterCategoryDto> {
    const renamed = await firstValueFrom(this.api.rename(id, name));
    this.generation++;
    this.items.update((items) => items.map((c) => (c.id === id ? renamed : c)));
    return renamed;
  }

  /** `DELETE /me/categories/{id}`: its articles become uncategorized ("مقالات تانية"). */
  async remove(id: string): Promise<void> {
    await firstValueFrom(this.api.delete(id));
    this.generation++;
    const removed = this.items().find((c) => c.id === id);
    this.items.update((items) => items.filter((c) => c.id !== id));
    if (removed) this.uncategorizedCount.update((n) => n + removed.articleCount);
  }

  /**
   * Moves a category from one position to another (drag, or the move buttons) and sends the whole order
   * (`PUT /me/categories/order`). Resolves false, with the old order back, when the server refused it.
   */
  async move(from: number, to: number): Promise<boolean> {
    const before = this.items();
    if (from === to || from < 0 || to < 0 || from >= before.length || to >= before.length) return true;
    const after = [...before];
    const [moved] = after.splice(from, 1);
    after.splice(to, 0, moved);
    const generation = ++this.generation;
    this.items.set(after);
    try {
      const list = await firstValueFrom(this.api.reorder(after.map((c) => c.id)));
      if (generation === this.generation) this.apply(list);
      return true;
    } catch {
      if (generation === this.generation) this.items.set(before);
      return false;
    }
  }

  private apply(list: WriterCategoryListDto): void {
    this.items.set(list.items ?? []);
    this.uncategorizedCount.set(list.uncategorizedCount ?? 0);
  }
}
