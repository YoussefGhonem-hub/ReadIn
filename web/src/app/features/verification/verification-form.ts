import { ChangeDetectionStrategy, Component, ElementRef, Injector, OnInit, afterNextRender, computed, inject, input, output, signal } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { FieldDto, MyVerificationRequestDto } from '../../core/api/models';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import {
  DraftErrors,
  FormErrorKey,
  JOB_TITLE_MAX,
  NOTE_MAX,
  PROOF_ACCEPT,
  PROOF_URL_MAX,
  VerificationDraft,
  draftErrors,
  fileError,
  fileSize,
} from './verification-rules';
import { VerificationStore } from './verification.store';

type Input = keyof DraftErrors;
const INPUTS: readonly Input[] = ['fieldId', 'jobTitle', 'proofUrl', 'proof', 'note'];

/** Validation keys from the API (`errors.jobTitle`, `errors.JobTitle`, …) → the input they are about. */
const SERVER_INPUTS: Record<string, Input> = { fieldid: 'fieldId', jobtitle: 'jobTitle', proofurl: 'proofUrl', proof: 'proof', note: 'note' };
const SERVER_MESSAGES: Record<Input, FormErrorKey> = { fieldId: 'fieldRequired', jobTitle: 'jobTitleLength', proofUrl: 'proofUrlInvalid', proof: 'fileType', note: 'noteTooLong' };

/** The API's refusals (translated), by input, and the draft they were about: each stays until its input changes. */
interface ServerErrors {
  messages: Partial<Record<Input, string>>;
  draft: VerificationDraft;
}

/**
 * The verification request form (F19): field, job title, proof (a link, a PDF/JPEG/PNG/WebP file of up to 10 MB, or
 * both) and an optional note. Everything is checked before sending (errors show after the first try, then live) and
 * sent as multipart through the page's VerificationStore; the API's refusals land on their inputs. "Request again"
 * starts from the rejected request (the file has to be picked again: it was deleted with the decision).
 */
@Component({
  selector: 'rd-verification-form',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block' },
  template: `
    <form class="rd-card flex flex-col gap-5 p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" novalidate (submit)="submit($event)" data-verification-form [attr.aria-busy]="sending() || null">
      <h2 class="m-0 text-lg font-semibold">{{ (from() ? 'verification.form.againTitle' : 'verification.form.title') | transloco }}</h2>

      <!-- Field -->
      <div>
        <label class="rd-label" for="verification-field">{{ 'verification.form.field' | transloco }} *</label>
        <select
          id="verification-field"
          class="rd-input"
          [value]="fieldId()"
          [disabled]="sending()"
          [attr.aria-invalid]="shown().fieldId ? true : null"
          [attr.aria-describedby]="shown().fieldId ? 'verification-field-error' : null"
          (change)="fieldId.set(valueOf($event))"
          data-verification-field
        >
          <option value="" [selected]="!fieldId()">{{ 'verification.form.fieldPlaceholder' | transloco }}</option>
          @for (field of fields(); track field.id) {
            <option [value]="field.id" [selected]="field.id === fieldId()">{{ lang() === 'ar' ? field.nameAr : field.nameEn }}</option>
          }
        </select>
        @if (fieldsFailed()) {
          <p class="m-0 mt-1 text-xs text-error" role="alert" data-fields-error>
            {{ 'verification.form.fieldsError' | transloco }}
            <button type="button" class="font-semibold underline" (click)="loadFields()">{{ 'common.retry' | transloco }}</button>
          </p>
        }
        @if (shown().fieldId; as error) {
          <p id="verification-field-error" class="m-0 mt-1 text-xs text-error" data-error="fieldId">{{ error }}</p>
        }
      </div>

      <!-- Job title -->
      <div>
        <label class="rd-label" for="verification-job-title">{{ 'verification.form.jobTitle' | transloco }} *</label>
        <input
          id="verification-job-title"
          class="rd-input"
          dir="auto"
          autocomplete="organization-title"
          [value]="jobTitle()"
          [attr.maxlength]="jobTitleMax"
          [disabled]="sending()"
          [placeholder]="'verification.form.jobTitlePlaceholder' | transloco"
          [attr.aria-invalid]="shown().jobTitle ? true : null"
          [attr.aria-describedby]="shown().jobTitle ? 'verification-job-title-error' : null"
          (input)="jobTitle.set(valueOf($event))"
          data-verification-job-title
        />
        @if (shown().jobTitle; as error) {
          <p id="verification-job-title-error" class="m-0 mt-1 text-xs text-error" data-error="jobTitle">{{ error }}</p>
        }
      </div>

      <!-- Proof: a link, a file, or both -->
      <fieldset class="m-0 flex flex-col gap-4 border-0 p-0" aria-describedby="verification-proof-hint" [disabled]="sending()">
        <legend class="rd-label p-0">{{ 'verification.form.proof' | transloco }} *</legend>
        <p id="verification-proof-hint" class="-mt-2 mb-0 text-xs text-text-secondary">{{ 'verification.form.proofHint' | transloco }}</p>

        <div>
          <label class="rd-label font-normal" for="verification-proof-url">{{ 'verification.form.proofUrl' | transloco }}</label>
          <input
            id="verification-proof-url"
            type="url"
            inputmode="url"
            class="rd-input"
            dir="ltr"
            autocomplete="url"
            [value]="proofUrl()"
            [attr.maxlength]="proofUrlMax"
            placeholder="https://www.linkedin.com/in/…"
            [attr.aria-invalid]="shown().proofUrl ? true : null"
            [attr.aria-describedby]="shown().proofUrl ? 'verification-proof-url-error' : null"
            (input)="proofUrl.set(valueOf($event))"
            data-verification-proof-url
          />
          @if (shown().proofUrl; as error) {
            <p id="verification-proof-url-error" class="m-0 mt-1 text-xs text-error" data-error="proofUrl">{{ error }}</p>
          }
        </div>

        <div>
          <span class="rd-label font-normal" id="verification-file-label">{{ 'verification.form.file' | transloco }}</span>
          <input #fileInput type="file" class="sr-only" tabindex="-1" aria-hidden="true" [accept]="accept" (change)="pick($event)" data-verification-file-input />
          @if (file(); as f) {
            <div class="flex items-center gap-3 rounded-md border border-border bg-surface px-3 py-2" data-verification-file>
              <svg [lucideIcon]="f.type === 'application/pdf' || f.name.toLowerCase().endsWith('.pdf') ? 'FileText' : 'Images'" [size]="20" class="shrink-0 text-text-secondary" aria-hidden="true"></svg>
              <span class="min-w-0 flex-1">
                <bdi class="block truncate text-sm" dir="auto" data-verification-file-name>{{ f.name }}</bdi>
                <span class="block text-xs text-text-secondary" dir="ltr">{{ size(f.size) }}</span>
              </span>
              <button type="button" class="rd-icon-btn h-9 w-9" [attr.aria-label]="'verification.form.removeFile' | transloco" (click)="removeFile()" data-verification-file-remove>
                <svg lucideIcon="X" [size]="18"></svg>
              </button>
            </div>
          } @else {
            <button type="button" class="rd-btn rd-btn-outline w-full gap-2 sm:w-auto" aria-describedby="verification-file-label verification-file-hint" (click)="fileInput.click()" data-verification-attach>
              <svg lucideIcon="Paperclip" [size]="18" aria-hidden="true"></svg>
              {{ 'verification.form.attach' | transloco }}
            </button>
          }
          <p id="verification-file-hint" class="m-0 mt-1 text-xs text-text-secondary">{{ 'verification.form.fileHint' | transloco }}</p>
        </div>
        @if (shown().proof; as error) {
          <p class="m-0 text-sm text-error" role="alert" data-error="proof">{{ error }}</p>
        }
      </fieldset>

      <!-- Note -->
      <div>
        <label class="rd-label" for="verification-note">{{ 'verification.form.note' | transloco }}</label>
        <textarea
          id="verification-note"
          dir="auto"
          rows="3"
          class="rd-input rd-autogrow"
          [value]="note()"
          [attr.maxlength]="noteMax"
          [disabled]="sending()"
          [placeholder]="'verification.form.notePlaceholder' | transloco"
          aria-describedby="verification-note-count"
          (input)="note.set(valueOf($event))"
          data-verification-note
        ></textarea>
        <p id="verification-note-count" class="m-0 mt-1 flex justify-between gap-2 text-xs text-text-secondary">
          @if (shown().note; as error) {
            <span class="text-error" data-error="note">{{ error }}</span>
          } @else {
            <span></span>
          }
          <span class="tabular-nums" dir="ltr">{{ note().length }}/{{ noteMax }}</span>
        </p>
      </div>

      <p class="m-0 flex items-start gap-2 text-xs text-text-secondary">
        <svg lucideIcon="LockKeyhole" [size]="16" class="mt-px shrink-0" aria-hidden="true"></svg>
        <span>{{ 'verification.form.privacy' | transloco }}</span>
      </p>

      @if (formError(); as error) {
        <p class="rd-alert rd-alert-error m-0" role="alert" data-verification-form-error>{{ error }}</p>
      }

      <div class="flex flex-wrap gap-2">
        @if (from()) {
          <button type="button" class="rd-btn rd-btn-outline flex-1 sm:flex-none" [disabled]="sending()" (click)="cancelled.emit()" data-verification-cancel>
            {{ 'common.cancel' | transloco }}
          </button>
        }
        <button type="submit" class="rd-btn rd-btn-primary flex-1 sm:flex-none" [disabled]="sending()" [attr.aria-busy]="sending()" data-verification-submit>
          @if (sending()) {
            <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
          }
          {{ (sending() ? 'verification.form.sending' : 'verification.form.submit') | transloco }}
        </button>
      </div>
    </form>
  `,
})
export class VerificationForm implements OnInit {
  private readonly store = inject(VerificationStore);
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);
  private readonly toasts = inject(ToastService);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly injector = inject(Injector);
  protected readonly lang = inject(LanguageService).lang;

  /** "Request again": the rejected request the form starts from. */
  readonly from = input<MyVerificationRequestDto | null>(null);
  readonly cancelled = output<void>();

  protected readonly accept = PROOF_ACCEPT;
  protected readonly jobTitleMax = JOB_TITLE_MAX;
  protected readonly proofUrlMax = PROOF_URL_MAX;
  protected readonly noteMax = NOTE_MAX;
  protected readonly size = fileSize;

  protected readonly fields = signal<FieldDto[]>([]);
  protected readonly fieldsFailed = signal(false);
  protected readonly fieldId = signal('');
  protected readonly jobTitle = signal('');
  protected readonly proofUrl = signal('');
  protected readonly note = signal('');
  protected readonly file = signal<File | null>(null);
  protected readonly sending = signal(false);
  /** Errors show once the user tried to send (then they follow the inputs). */
  protected readonly tried = signal(false);
  private readonly serverErrors = signal<ServerErrors | null>(null);
  /** A picked file the browser already knows is wrong (type or size). */
  private readonly pickError = signal<FormErrorKey | null>(null);
  protected readonly formError = signal<string | null>(null);

  private readonly draft = computed<VerificationDraft>(() => ({
    fieldId: this.fieldId(),
    jobTitle: this.jobTitle(),
    proofUrl: this.proofUrl(),
    note: this.note(),
    file: this.file(),
  }));
  private readonly clientErrors = computed(() => draftErrors(this.draft()));
  /** The message under each input: the form's own checks (after the first try), else the API's refusal. */
  protected readonly shown = computed<Partial<Record<Input, string>>>(() => {
    this.lang();
    const draft = this.draft();
    const client: DraftErrors = this.tried() ? { ...this.clientErrors() } : {};
    const pick = this.pickError();
    if (pick) client.proof = pick;
    const server = this.serverErrors();
    const shown: Partial<Record<Input, string>> = {};
    for (const key of INPUTS) {
      const own = client[key];
      if (own) shown[key] = this.transloco.translate(`verification.form.errors.${own}`);
      else if (server?.messages[key] && unchanged(key, server.draft, draft)) shown[key] = server.messages[key];
    }
    return shown;
  });

  constructor() {
    void this.loadFields();
  }

  ngOnInit(): void {
    const from = this.from();
    if (!from) return;
    this.fieldId.set(from.field.id);
    this.jobTitle.set(from.jobTitle);
    this.proofUrl.set(from.proofUrl ?? '');
    this.note.set(from.note ?? '');
  }

  protected async loadFields(): Promise<void> {
    this.fieldsFailed.set(false);
    try {
      this.fields.set(await firstValueFrom(this.taxonomy.fields()));
    } catch {
      this.fieldsFailed.set(true);
    }
  }

  protected valueOf(event: Event): string {
    return (event.target as HTMLInputElement).value;
  }

  protected pick(event: Event): void {
    const input = event.target as HTMLInputElement;
    const picked = input.files?.[0] ?? null;
    input.value = ''; // picking the same file again still reports a change
    if (!picked) return;
    const error = fileError(picked);
    this.pickError.set(error);
    this.file.set(error ? null : picked);
  }

  /** The file goes; focus moves to "Attach a file", which takes the removed card's place. */
  protected removeFile(): void {
    this.file.set(null);
    this.pickError.set(null);
    afterNextRender(() => this.host.nativeElement.querySelector<HTMLElement>('[data-verification-attach]')?.focus(), { injector: this.injector });
  }

  protected async submit(event: Event): Promise<void> {
    event.preventDefault();
    if (this.sending()) return;
    this.tried.set(true);
    this.formError.set(null);
    this.serverErrors.set(null);
    if (this.pickError() || Object.keys(this.clientErrors()).length) {
      this.focusFirstError();
      return;
    }
    const draft = this.draft();
    this.sending.set(true);
    try {
      await this.store.submit({
        fieldId: draft.fieldId,
        jobTitle: draft.jobTitle.trim(),
        proofUrl: draft.proofUrl.trim() || null,
        note: draft.note.trim() || null,
        proof: draft.file,
      });
      this.toasts.success(this.transloco.translate('verification.sent'));
    } catch (error) {
      this.showServerError(error, draft);
    } finally {
      this.sending.set(false);
    }
  }

  private showServerError(error: unknown, draft: VerificationDraft): void {
    const on = (messages: Partial<Record<Input, string>>) => {
      this.serverErrors.set({ messages, draft });
      this.focusFirstError();
    };
    if (isApiError(error)) {
      switch (error.code) {
        case 'verification.already_pending':
        case 'verification.already_verified':
          // Sent from another tab or device meanwhile: show where things stand.
          this.toasts.info(this.errors.forError(error));
          void this.store.load();
          return;
        case 'verification.field_invalid':
          void this.loadFields();
          return on({ fieldId: this.errors.forError(error) });
        case 'verification.proof_invalid':
        case 'verification.proof_required':
          return on({ proof: this.errors.forError(error) });
        case 'validation.failed': {
          const messages: Partial<Record<Input, string>> = {};
          for (const key of Object.keys(error.validationErrors)) {
            const input = SERVER_INPUTS[key.toLowerCase()];
            if (input) messages[input] = this.transloco.translate(`verification.form.errors.${SERVER_MESSAGES[input]}`);
          }
          if (Object.keys(messages).length) return on(messages);
        }
      }
    }
    this.formError.set(this.errors.forError(error));
  }

  /** Focus goes to the first input with a problem (the file button for a missing proof), once they are marked. */
  private focusFirstError(): void {
    afterNextRender(() => {
      const root = this.host.nativeElement;
      const invalid = root.querySelector<HTMLElement>('[aria-invalid="true"]');
      const proof = this.shown().proof ? root.querySelector<HTMLElement>('[data-verification-attach], [data-verification-file-remove]') : null;
      (invalid ?? proof)?.focus();
    }, { injector: this.injector });
  }
}

/** Whether the input an API error was about still holds what was sent (the proof: the same link and file). */
function unchanged(key: Input, sent: VerificationDraft, now: VerificationDraft): boolean {
  return key === 'proof' ? sent.file === now.file && sent.proofUrl === now.proofUrl : sent[key] === now[key];
}

