import { ChangeDetectionStrategy, Component, computed, effect, inject, input, output, signal, untracked } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { ModerationApi } from '../../core/api/moderation.api';
import { isolate } from '../directives/bidi';
import { ModerationAction, ModerationActionRequest, ModerationTargetType } from '../../core/api/models';
import { BottomSheet } from '../ui/bottom-sheet';
import { ToastService } from '../ui/toast/toast.service';
import { ModerationErrors } from './moderation-errors';

/** A moderator's note (contract: ≤ 500). */
export const MODERATION_NOTE_MAX_LENGTH = 500;
/** Suspend for 1, 3, 7 or 30 days, a custom number of days (1–365), or permanently (null) (SPEC F23). */
export const SUSPEND_DURATIONS: readonly (number | 'custom' | null)[] = [1, 3, 7, 30, 'custom', null];
const DEFAULT_SUSPEND_DAYS = 7;
/** A custom suspension: 1–365 days. */
export const MAX_SUSPEND_DAYS = 365;
/** The reason of a suspension: 5–500 characters (SPEC F23). */
export const SUSPEND_NOTE_MIN_LENGTH = 5;

/** An action to confirm: what, on which target, and the name to show for a user (warn, suspend, unsuspend). */
export interface ModerationActionDraft {
  action: ModerationAction;
  targetType: ModerationTargetType;
  targetId: string;
  /**
   * The user's display name, for "Warn {name}" / "Suspend {name}" / "Clear {name}'s links"; the category's name for
   * `clear_category`.
   */
  name?: string | null;
  resolveReportsOf?: ModerationActionRequest['resolveReportsOf'];
  /** `clear_category` (F31): the user's category whose name is cleared. */
  categoryId?: string;
}

interface SheetCopy {
  /** `moderation.sheet.title.*` / `moderation.sheet.body.*`. */
  key: string;
  confirm: string;
  note: 'required' | 'optional';
  danger: boolean;
  duration: boolean;
}

/** How each action is confirmed: hide/delete/suspend in the error color; warn and suspend need a note for the user. */
export function sheetCopy(draft: Pick<ModerationActionDraft, 'action' | 'targetType'>): SheetCopy {
  const on = draft.targetType === 'article' ? 'Article' : 'Comment';
  switch (draft.action) {
    case 'hide':
      return { key: `hide${on}`, confirm: `moderation.actions.hide.${draft.targetType}`, note: 'optional', danger: true, duration: false };
    case 'unhide':
      return { key: `unhide${on}`, confirm: `moderation.actions.unhide.${draft.targetType}`, note: 'optional', danger: false, duration: false };
    case 'delete':
      return { key: 'delete', confirm: 'moderation.actions.delete', note: 'optional', danger: true, duration: false };
    case 'warn':
      return { key: 'warn', confirm: 'moderation.actions.warn', note: 'required', danger: false, duration: false };
    case 'suspend':
      return { key: 'suspend', confirm: 'moderation.actions.suspend', note: 'required', danger: true, duration: true };
    case 'unsuspend':
      return { key: 'unsuspend', confirm: 'moderation.actions.unsuspend', note: 'optional', danger: false, duration: false };
    case 'clear_category':
      return { key: 'clearCategory', confirm: 'moderation.actions.clearCategory', note: 'optional', danger: true, duration: false };
    case 'clear_links':
      return { key: 'clearLinks', confirm: 'moderation.actions.clearLinks', note: 'optional', danger: true, duration: false };
    case 'clear_headline':
      return { key: 'clearHeadline', confirm: 'moderation.actions.clearHeadline', note: 'optional', danger: true, duration: false };
    case 'dismiss':
      return { key: 'dismiss', confirm: 'moderation.actions.dismiss', note: 'optional', danger: false, duration: false };
    case 'hide_content':
      return { key: 'hideContent', confirm: 'moderation.actions.hideContent', note: 'optional', danger: true, duration: false };
    case 'unhide_content':
      return { key: 'unhideContent', confirm: 'moderation.actions.unhideContent', note: 'optional', danger: false, duration: false };
  }
}

/**
 * Confirms one moderation action (F22) with a note and, for a suspension (F23's form), its length (1, 3, 7 or 30 days, a
 * custom 1–365, or permanent), a reason of 5–500 characters and "Also hide all of their articles and comments"
 * (`hideContent`). The note is required for warn and suspend (the user sees it) and optional otherwise; hiding and
 * restoring all of a user's content (F23) are confirmed like the other actions; clearing a writer category's name
 * (F31) carries the category's id; clearing a user's links or title (F14) is confirmed like the other content actions.
 * Sends `POST /moderation/actions`,
 * thanks with a toast and emits `done`; a failure stays in the sheet with its translated message.
 */
@Component({
  selector: 'rd-moderation-action-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet
      [open]="!!draft()"
      [role]="copy()?.danger ? 'alertdialog' : 'dialog'"
      labelledBy="moderation-sheet-title"
      describedBy="moderation-sheet-body"
      [dismissible]="!busy()"
      (closed)="close()"
    >
      @if (draft(); as d) {
        @let c = copy()!;
        <form class="flex flex-col gap-3 pt-1" (submit)="submit($event)" data-moderation-sheet [attr.data-moderation-action]="d.action">
          <h2 id="moderation-sheet-title" class="m-0 pe-10 text-xl font-semibold">
            {{ 'moderation.sheet.title.' + c.key | transloco: { name: isolate(d.name) } }}
          </h2>
          <p id="moderation-sheet-body" class="m-0 text-sm text-text-secondary">{{ 'moderation.sheet.body.' + c.key | transloco }}</p>

          @if (c.duration) {
            <fieldset class="m-0 border-0 p-0" data-suspend-duration>
              <legend class="rd-label p-0">{{ 'moderation.sheet.duration' | transloco }}</legend>
              <div class="grid grid-cols-3 gap-2">
                @for (days of durations; track $index) {
                  <label
                    class="flex min-h-11 cursor-pointer items-center justify-center gap-2 rounded-md border px-2 text-sm has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-focus-ring"
                    [class]="duration() === days ? 'border-primary bg-primary-container font-semibold text-on-primary-container' : 'border-border text-text-primary'"
                  >
                    <input
                      type="radio"
                      name="suspend-duration"
                      class="sr-only"
                      [checked]="duration() === days"
                      [disabled]="busy()"
                      [attr.data-duration]="days ?? 'permanent'"
                      (change)="duration.set(days)"
                    />
                    {{ 'moderation.sheet.durations.' + (days ?? 'permanent') | transloco }}
                  </label>
                }
              </div>
              @if (duration() === 'custom') {
                <div class="mt-2 flex items-center gap-2">
                  <label for="moderation-custom-days" class="text-sm">{{ 'moderation.sheet.customDays' | transloco }}</label>
                  <input
                    id="moderation-custom-days"
                    type="number"
                    inputmode="numeric"
                    min="1"
                    [attr.max]="maxDays"
                    class="rd-input w-24"
                    dir="ltr"
                    [value]="customDays()"
                    [disabled]="busy()"
                    [attr.aria-invalid]="customDays() !== '' && !customValid()"
                    aria-describedby="moderation-custom-days-hint"
                    (input)="customDays.set($any($event.target).value)"
                    data-custom-days
                  />
                  <span id="moderation-custom-days-hint" class="text-xs text-text-secondary">{{ 'moderation.sheet.customDaysHint' | transloco }}</span>
                </div>
              }
            </fieldset>
          }

          <div>
            <label for="moderation-note" class="rd-label">
              {{ (c.note === 'required' ? 'moderation.sheet.note' : 'moderation.sheet.noteOptional') | transloco }}
            </label>
            <textarea
              id="moderation-note"
              dir="auto"
              rows="3"
              class="rd-input rd-autogrow"
              [value]="note()"
              [attr.maxlength]="noteMax"
              [attr.aria-required]="c.note === 'required'"
              [placeholder]="'moderation.sheet.notePlaceholder' | transloco"
              [disabled]="busy()"
              aria-describedby="moderation-note-hint"
              (input)="note.set($any($event.target).value)"
              data-moderation-note
            ></textarea>
            <p id="moderation-note-hint" class="m-0 mt-1 flex justify-between gap-2 text-xs text-text-secondary">
              <span>{{
                d.action === 'suspend' ? ('moderation.sheet.reasonHint' | transloco) : c.note === 'required' ? ('moderation.sheet.noteForUser' | transloco) : ''
              }}</span>
              <span class="tabular-nums" dir="ltr">{{ note().length }}/{{ noteMax }}</span>
            </p>
          </div>

          @if (d.action === 'suspend') {
            <!-- F23: a spam account's articles and comments go with it (undone with "Restore their content"). -->
            <label class="flex min-h-11 cursor-pointer items-start gap-3 text-sm" data-hide-content>
              <input type="checkbox" class="mt-1 h-4 w-4 shrink-0" [checked]="hideContent()" [disabled]="busy()" (change)="hideContent.set($any($event.target).checked)" />
              <span>
                <span class="block font-semibold">{{ 'moderation.sheet.hideContent' | transloco }}</span>
                <span class="block text-xs text-text-secondary">{{ 'moderation.sheet.hideContentHint' | transloco }}</span>
              </span>
            </label>
          }

          @if (error()) {
            <p class="rd-alert rd-alert-error m-0" role="alert" data-moderation-error>{{ error() }}</p>
          }
          <div class="flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="busy()" (click)="close()">{{ 'common.cancel' | transloco }}</button>
            <button
              type="submit"
              class="rd-btn flex-1"
              [class]="c.danger ? 'bg-error text-on-error' : 'rd-btn-primary'"
              [disabled]="!canSubmit()"
              [attr.aria-busy]="busy()"
              data-moderation-confirm
            >
              @if (busy()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ c.confirm | transloco }}
            </button>
          </div>
        </form>
      }
    </rd-bottom-sheet>
  `,
})
export class ModerationActionSheet {
  private readonly api = inject(ModerationApi);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ModerationErrors);

  /** Opens the sheet for this action; null closes it. */
  readonly draft = input<ModerationActionDraft | null>(null);
  readonly closed = output<void>();
  /** The request the API accepted (204). */
  readonly done = output<ModerationActionRequest>();

  protected readonly isolate = isolate;
  protected readonly durations = SUSPEND_DURATIONS;
  protected readonly noteMax = MODERATION_NOTE_MAX_LENGTH;
  protected readonly maxDays = MAX_SUSPEND_DAYS;
  protected readonly copy = computed(() => {
    const draft = this.draft();
    return draft ? sheetCopy(draft) : null;
  });
  protected readonly note = signal('');
  protected readonly duration = signal<number | 'custom' | null>(DEFAULT_SUSPEND_DAYS);
  /** The custom length, as typed. */
  protected readonly customDays = signal('');
  protected readonly customValid = computed(() => {
    const days = Number(this.customDays());
    return Number.isInteger(days) && days >= 1 && days <= MAX_SUSPEND_DAYS;
  });
  /** F23: also hide all of the user's articles and comments. */
  protected readonly hideContent = signal(false);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly canSubmit = computed(() => {
    const copy = this.copy();
    if (!copy || this.busy() || this.note().length > this.noteMax) return false;
    if (this.draft()?.action === 'suspend') {
      if (this.duration() === 'custom' && !this.customValid()) return false;
      return this.note().trim().length >= SUSPEND_NOTE_MIN_LENGTH;
    }
    return copy.note === 'optional' || this.note().trim().length > 0;
  });

  constructor() {
    effect(() => {
      this.draft();
      untracked(() => {
        this.note.set('');
        this.duration.set(DEFAULT_SUSPEND_DAYS);
        this.customDays.set('');
        this.hideContent.set(false);
        this.error.set(null);
        this.busy.set(false);
      });
    });
  }

  protected close(): void {
    if (!this.busy()) this.closed.emit();
  }

  protected async submit(event: Event): Promise<void> {
    event.preventDefault();
    const draft = this.draft();
    if (!draft || !this.canSubmit()) return;
    const request: ModerationActionRequest = { action: draft.action, targetType: draft.targetType, targetId: draft.targetId };
    const note = this.note().trim();
    if (note) request.note = note;
    if (draft.action === 'suspend') {
      const duration = this.duration();
      request.durationDays = duration === 'custom' ? Number(this.customDays()) : duration;
      if (this.hideContent()) request.hideContent = true;
    }
    if (draft.resolveReportsOf) request.resolveReportsOf = draft.resolveReportsOf;
    if (draft.action === 'clear_category' && draft.categoryId) request.categoryId = draft.categoryId;
    this.busy.set(true);
    this.error.set(null);
    try {
      await firstValueFrom(this.api.act(request));
      this.busy.set(false);
      this.toasts.success(this.transloco.translate(`moderation.actions.done.${draft.action}`));
      this.done.emit(request);
      this.closed.emit();
    } catch (error) {
      this.error.set(this.errors.message(error));
    } finally {
      this.busy.set(false);
    }
  }
}
