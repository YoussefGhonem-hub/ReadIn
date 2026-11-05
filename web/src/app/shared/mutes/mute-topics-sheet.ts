import { ChangeDetectionStrategy, Component, computed, inject, input, output, signal } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { FieldRefDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { MuteStore } from '../../core/social/mute.store';
import { isolate } from '../directives/bidi';
import { BottomSheet } from '../ui/bottom-sheet';
import { Switch } from '../ui/switch';

/** The article whose field and topic the sheet offers to mute. */
export interface MuteTopicsTarget {
  field: FieldRefDto;
  topic?: FieldRefDto | null;
  isFieldMuted?: boolean;
  isTopicMuted?: boolean;
}

/**
 * "كتم المواضيع" (F28): a sheet with one toggle for the article's field and one for its topic (none without a topic).
 * Each toggle saves at once (`PUT` on, `DELETE` off) through MuteStore, so the cards in it leave the lists behind the
 * sheet, and toggling back is the Undo. A refusal puts the toggle back with the error toast.
 */
@Component({
  selector: 'rd-mute-topics-sheet',
  imports: [TranslocoPipe, BottomSheet, Switch],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="!!article()" labelledBy="mute-topics-title" describedBy="mute-topics-body" (closed)="closed.emit()">
      @if (article(); as a) {
        <div class="flex flex-col pt-1" data-mute-topics-sheet>
          <h2 id="mute-topics-title" class="m-0 pe-10 text-xl font-semibold">{{ 'mute.topics.title' | transloco }}</h2>
          <p id="mute-topics-body" class="m-0 mt-1 text-sm text-text-secondary">{{ 'mute.topics.body' | transloco }}</p>
          <ul class="m-0 mt-3 list-none divide-y divide-border p-0">
            <li class="py-2">
              <rd-switch
                [checked]="fieldMuted()"
                [label]="nameOf(a.field)"
                [hint]="'mute.topics.fieldHint' | transloco"
                [disabled]="busy().has('field')"
                [busy]="busy().has('field')"
                [attr.data-mute-field]="a.field.id"
                (changed)="toggle('field', $event)"
              />
            </li>
            @if (a.topic; as topic) {
              <li class="py-2">
                <rd-switch
                  [checked]="topicMuted()"
                  [label]="nameOf(topic)"
                  [hint]="'mute.topics.topicHint' | transloco"
                  [disabled]="busy().has('topic')"
                  [busy]="busy().has('topic')"
                  [attr.data-mute-topic]="topic.id"
                  (changed)="toggle('topic', $event)"
                />
              </li>
            }
          </ul>
          <button type="button" class="rd-btn rd-btn-primary mt-4 min-h-11" data-mute-topics-done (click)="closed.emit()">
            {{ 'mute.topics.done' | transloco }}
          </button>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class MuteTopicsSheet {
  private readonly mutes = inject(MuteStore);
  private readonly lang = inject(LanguageService).lang;

  /** Open while set. */
  readonly article = input<MuteTopicsTarget | null>(null);
  readonly closed = output<void>();

  protected readonly busy = signal<ReadonlySet<'field' | 'topic'>>(new Set());

  protected readonly fieldMuted = computed(() => {
    const a = this.article();
    return !!a && this.mutes.isFieldMuted(a.field.id, a.isFieldMuted ?? false);
  });
  protected readonly topicMuted = computed(() => {
    const a = this.article();
    return !!a?.topic && this.mutes.isTopicMuted(a.topic.id, a.isTopicMuted ?? false);
  });

  /** The name in the UI language (both come with the article), isolated: ".NET" stays ".NET" in an Arabic line. */
  protected nameOf(ref: FieldRefDto): string {
    return isolate(this.lang() === 'ar' ? ref.nameAr : ref.nameEn);
  }

  protected async toggle(kind: 'field' | 'topic', muted: boolean): Promise<void> {
    const a = this.article();
    const id = kind === 'field' ? a?.field.id : a?.topic?.id;
    if (!id || this.busy().has(kind)) return;
    this.busy.update((set) => new Set(set).add(kind));
    try {
      await (kind === 'field' ? this.mutes.setFieldMuted(id, muted) : this.mutes.setTopicMuted(id, muted));
    } finally {
      this.busy.update((set) => {
        const next = new Set(set);
        next.delete(kind);
        return next;
      });
    }
  }
}
