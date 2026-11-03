import { ChangeDetectionStrategy, Component, DestroyRef, computed, inject, linkedSignal, signal } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { Router } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { Subscription, firstValueFrom } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { ArticlesApi } from '../../core/api/articles.api';
import { ArticleLanguage, CreateArticleRequest, FieldDto, TopicDto } from '../../core/api/models';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { translatePlural } from '../../shared/pipes/format.pipes';
import { articleLink } from '../../shared/ui/article-link';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { AttachmentBar } from './attachment-bar';
import { AttachmentDraft } from './attachment-draft';
import {
  SourceRow,
  TITLE_MAX,
  isBlankSource,
  isCompleteSource,
  isTitleValid,
  isValidSourceUrl,
  sourcesForRequest,
  textToRDoc,
} from './composer.utils';

interface PublishError {
  message: string;
  details: string[];
}

/** The draft created by a publish attempt that failed later (attachments/publish), reused while the form is unchanged. */
interface CreatedDraft {
  id: string;
  slug: string;
  language: ArticleLanguage;
  snapshot: string;
}

/**
 * Minimal post composer (`/write`, permission `articles.create`) until the block editor (F05) lands: field, topic,
 * article language, title, plain-text body (→ RDoc paragraphs), sources, AI label and the attachment bar (F26).
 * Publish = `POST /articles` → `PUT /articles/{id}/attachments` → `POST /articles/{id}/publish` → the article.
 */
@Component({
  selector: 'rd-composer-page',
  imports: [TranslocoPipe, LucideDynamicIcon, Segmented, AttachmentBar],
  providers: [AttachmentDraft],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[720px] px-4 pb-16 pt-5 lg:pt-8' },
  template: `
    <h1 class="m-0 text-2xl font-semibold">{{ 'editor.title' | transloco }}</h1>
    <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'editor.subtitle' | transloco }}</p>

    <form class="mt-6 flex flex-col gap-5" novalidate (submit)="onSubmit($event)">
      <div class="grid gap-4 sm:grid-cols-2">
        <div>
          <label class="rd-label" for="rd-field">{{ 'editor.field' | transloco }} *</label>
          <select id="rd-field" class="rd-input" required data-field [value]="fieldId()" (change)="selectField(valueOf($event))">
            <option value="" disabled [selected]="!fieldId()">{{ 'editor.fieldPlaceholder' | transloco }}</option>
            @for (field of fields(); track field.id) {
              <option [value]="field.id" [selected]="field.id === fieldId()">{{ lang() === 'ar' ? field.nameAr : field.nameEn }}</option>
            }
          </select>
          @if (fieldsFailed()) {
            <p class="m-0 mt-1 text-xs text-error" role="alert">
              {{ 'editor.fieldsError' | transloco }}
              <button type="button" class="font-semibold underline" (click)="loadFields()">{{ 'common.retry' | transloco }}</button>
            </p>
          }
        </div>
        <div>
          <label class="rd-label" for="rd-topic">{{ 'editor.topic' | transloco }}</label>
          <select id="rd-topic" class="rd-input" data-topic [disabled]="!topics().length" (change)="topicId.set(valueOf($event) || null)">
            <option value="" [selected]="!topicId()">{{ 'editor.topicNone' | transloco }}</option>
            @for (topic of topics(); track topic.id) {
              <option [value]="topic.id" [selected]="topic.id === topicId()">{{ lang() === 'ar' ? topic.nameAr : topic.nameEn }}</option>
            }
          </select>
        </div>
      </div>

      <div>
        <span class="rd-label">{{ 'editor.language' | transloco }}</span>
        <rd-segmented [options]="languageOptions()" [(value)]="language" [label]="'editor.language' | transloco" />
      </div>

      <div>
        <label class="rd-label" for="rd-title">{{ 'editor.titleLabel' | transloco }} *</label>
        <input
          id="rd-title"
          class="rd-input"
          dir="auto"
          required
          [maxLength]="titleMax"
          [value]="title()"
          [placeholder]="'editor.titlePlaceholder' | transloco"
          [attr.aria-invalid]="title() && !titleValid() ? 'true' : null"
          aria-describedby="rd-title-count"
          data-title
          (input)="title.set(valueOf($event))"
        />
        <p id="rd-title-count" class="m-0 mt-1 text-end text-xs text-text-secondary tabular-nums" dir="ltr">{{ title().trim().length }}/{{ titleMax }}</p>
      </div>

      <div>
        <label class="rd-label" for="rd-body">{{ 'editor.body' | transloco }}</label>
        <textarea
          id="rd-body"
          class="rd-input min-h-48 py-3 leading-relaxed"
          dir="auto"
          rows="8"
          [value]="body()"
          [placeholder]="'editor.bodyPlaceholder' | transloco"
          data-body
          (input)="body.set(valueOf($event))"
        ></textarea>
      </div>

      <rd-attachment-bar [draft]="attachments" />

      <fieldset class="m-0 min-w-0 border-0 p-0" data-sources>
        <legend class="rd-label mb-1">
          📚 {{ 'editor.sources' | transloco }}
          <span class="ms-1 font-normal text-text-secondary">
            · {{ (sourcesRequired() ? 'editor.sourcesRequiredNote' : 'editor.sourcesOptionalNote') | transloco }}
          </span>
        </legend>
        <div class="flex flex-col gap-3">
          @for (row of sources(); track row.id; let i = $index) {
            <div class="grid gap-2 sm:grid-cols-[1fr_1.4fr_auto]" data-source-row>
              <input
                class="rd-input"
                dir="auto"
                [value]="row.title"
                [placeholder]="'editor.sourceTitle' | transloco"
                [attr.aria-label]="('editor.sourceTitle' | transloco) + ' ' + (i + 1)"
                data-source-title
                (input)="updateSource(row.id, { title: valueOf($event) })"
              />
              <input
                class="rd-input"
                type="url"
                dir="ltr"
                inputmode="url"
                placeholder="https://"
                [value]="row.url"
                [attr.aria-label]="('editor.sourceUrl' | transloco) + ' ' + (i + 1)"
                [attr.aria-invalid]="sourceInvalid(row) ? 'true' : null"
                data-source-url
                (input)="updateSource(row.id, { url: valueOf($event) })"
              />
              <button type="button" class="rd-icon-btn h-11 w-11" [attr.aria-label]="'editor.removeSource' | transloco: { position: i + 1 }" (click)="removeSource(row.id)">
                <svg lucideIcon="Trash2" [size]="16" aria-hidden="true"></svg>
              </button>
            </div>
            @if (sourceInvalid(row)) {
              <p class="-mt-2 m-0 text-xs text-error">{{ 'editor.invalidUrl' | transloco }}</p>
            }
          }
          <button type="button" class="rd-btn rd-btn-ghost min-h-9 self-start px-2 text-sm text-primary" data-add-source (click)="addSource()">
            <svg lucideIcon="Plus" [size]="16" aria-hidden="true"></svg>
            {{ 'editor.addSource' | transloco }}
          </button>
        </div>
      </fieldset>

      <label class="flex cursor-pointer items-start gap-3">
        <input type="checkbox" class="mt-1 h-4 w-4 accent-primary" [checked]="aiAssisted()" (change)="aiAssisted.set(checkedOf($event))" />
        <span>
          <span class="block text-sm font-semibold">{{ 'editor.aiAssisted' | transloco }}</span>
          <span class="block text-xs text-text-secondary">{{ 'editor.aiAssistedHint' | transloco }}</span>
        </span>
      </label>

      @if (error(); as failure) {
        <div class="rounded-md bg-callout-danger p-3 text-sm" role="alert" data-publish-error>
          <p class="m-0 font-semibold" dir="auto">{{ failure.message }}</p>
          @if (failure.details.length) {
            <ul class="m-0 mt-1 ps-5">
              @for (detail of failure.details; track detail) {
                <li dir="auto">{{ detail }}</li>
              }
            </ul>
          }
        </div>
      }

      @if (blockers().length) {
        <div class="rounded-md bg-surface-variant p-3 text-sm" id="rd-publish-blockers" aria-live="polite" data-blockers>
          <p class="m-0 font-semibold">{{ 'editor.blockers.title' | transloco }}</p>
          <ul class="m-0 mt-1 ps-5 text-text-secondary">
            @for (blocker of blockers(); track blocker) {
              <li>{{ blocker }}</li>
            }
          </ul>
        </div>
      }

      <div class="flex justify-end">
        <button
          type="submit"
          class="rd-btn rd-btn-primary min-w-32"
          [disabled]="!canPublish()"
          [attr.aria-describedby]="blockers().length ? 'rd-publish-blockers' : null"
          data-publish
        >
          @if (publishing()) {
            <svg lucideIcon="LoaderCircle" [size]="16" class="animate-spin" aria-hidden="true"></svg>
          }
          {{ (publishing() ? 'editor.publishing' : 'editor.publish') | transloco }}
        </button>
      </div>
    </form>
  `,
})
export class ComposerPage {
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly articles = inject(ArticlesApi);
  private readonly session = inject(SessionStore);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  private readonly toasts = inject(ToastService);
  private readonly router = inject(Router);
  protected readonly lang = inject(LanguageService).lang;
  protected readonly attachments = inject(AttachmentDraft);

  protected readonly titleMax = TITLE_MAX;
  protected readonly fields = signal<FieldDto[]>([]);
  protected readonly fieldsFailed = signal(false);
  protected readonly topics = signal<TopicDto[]>([]);
  protected readonly fieldId = signal('');
  protected readonly topicId = signal<string | null>(null);
  /** Defaults to the user's article-language preference, then follows the user's choice. */
  protected readonly language = linkedSignal<ArticleLanguage>(() => this.session.me()?.articleLanguage ?? (this.lang() === 'ar' ? 'ar-EG' : 'en'));
  protected readonly title = signal('');
  protected readonly body = signal('');
  protected readonly sources = signal<SourceRow[]>([{ id: 1, title: '', url: '' }]);
  protected readonly aiAssisted = signal(false);
  protected readonly publishing = signal(false);
  protected readonly error = signal<PublishError | null>(null);

  private nextSourceId = 2;
  private created: CreatedDraft | null = null;
  private topicsRequest: Subscription | null = null;

  protected readonly selectedField = computed(() => this.fields().find((f) => f.id === this.fieldId()) ?? null);
  protected readonly sourcesRequired = computed(() => !!this.selectedField()?.requiresSources);
  protected readonly titleValid = computed(() => isTitleValid(this.title()));
  protected readonly languageOptions = computed<SegmentOption<ArticleLanguage>[]>(() => {
    this.lang(); // re-translate on UI language change
    return [
      { value: 'ar-EG', label: this.transloco.translate('onboarding.prefs.arEG') },
      { value: 'en', label: this.transloco.translate('onboarding.prefs.en'), ltr: true },
    ];
  });

  /** Everything that keeps Publish disabled, as translated sentences (also announced to screen readers). */
  protected readonly blockers = computed(() => {
    const lang = this.lang();
    const t = (key: string) => this.transloco.translate(key, {}, lang);
    const list: string[] = [];
    if (!this.fieldId()) list.push(t('editor.blockers.field'));
    if (!this.titleValid()) list.push(t('editor.blockers.titleLength'));
    if (!this.body().trim() && this.attachments.isEmpty()) list.push(t('editor.blockers.body'));
    const rows = this.sources();
    if (rows.some((r) => !isBlankSource(r) && !isCompleteSource(r))) list.push(t('editor.blockers.invalidSources'));
    else if (this.sourcesRequired() && !rows.some(isCompleteSource)) list.push(t('editor.blockers.sources'));
    if (this.attachments.isBusy()) list.push(t('editor.blockers.uploading'));
    if (this.attachments.hasProblem()) list.push(t('editor.blockers.attachmentProblem'));
    const missingAlt = this.attachments.missingAltCount();
    if (missingAlt) list.push(translatePlural(this.transloco, 'editor.blockers.altMissing', missingAlt, lang));
    if (this.attachments.documentTitleMissing()) list.push(t('editor.blockers.documentTitle'));
    return list;
  });
  protected readonly canPublish = computed(() => !this.publishing() && this.blockers().length === 0);

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('editor.title')} — ReadIn`);
    inject(DestroyRef).onDestroy(() => this.topicsRequest?.unsubscribe());
    this.loadFields();
  }

  loadFields(): void {
    this.fieldsFailed.set(false);
    this.taxonomy.fields().subscribe({
      next: (fields) => this.fields.set(fields),
      error: () => this.fieldsFailed.set(true),
    });
  }

  protected selectField(id: string): void {
    this.fieldId.set(id);
    this.topicId.set(null);
    this.topics.set([]);
    this.topicsRequest?.unsubscribe();
    const field = this.fields().find((f) => f.id === id);
    if (!field?.topicCount) return;
    this.topicsRequest = this.taxonomy.topics(field.slug).subscribe({
      next: (topics) => this.topics.set(topics),
      error: () => this.topics.set([]), // topic is optional
    });
  }

  protected addSource(): void {
    this.sources.update((rows) => [...rows, { id: this.nextSourceId++, title: '', url: '' }]);
  }

  protected removeSource(id: number): void {
    this.sources.update((rows) => rows.filter((r) => r.id !== id));
  }

  protected updateSource(id: number, patch: Partial<SourceRow>): void {
    this.sources.update((rows) => rows.map((r) => (r.id === id ? { ...r, ...patch } : r)));
  }

  protected sourceInvalid(row: SourceRow): boolean {
    return !!row.url.trim() && !isValidSourceUrl(row.url);
  }

  protected onSubmit(event: Event): void {
    event.preventDefault();
    void this.publish();
  }

  async publish(): Promise<void> {
    if (!this.canPublish()) return;
    this.publishing.set(true);
    this.error.set(null);
    try {
      const request = this.request();
      const snapshot = JSON.stringify(request);
      if (this.created?.snapshot !== snapshot) {
        const { id, slug } = await firstValueFrom(this.articles.create(request));
        this.created = { id, slug, language: request.language, snapshot };
      }
      const draft = this.created!;
      const attachments = this.attachments.toRequest();
      if (attachments.items.length) await firstValueFrom(this.articles.setAttachments(draft.id, attachments));
      await firstValueFrom(this.articles.publish(draft.id));
      this.toasts.success(this.transloco.translate('editor.published'));
      await this.router.navigate(articleLink({ slug: draft.slug, language: draft.language }));
    } catch (error) {
      this.error.set(this.describe(error));
    } finally {
      this.publishing.set(false);
    }
  }

  private request(): CreateArticleRequest {
    const language = this.language();
    return {
      fieldId: this.fieldId(),
      topicId: this.topicId(),
      language,
      title: this.title().trim(),
      subtitle: null,
      content: textToRDoc(this.body(), language),
      tags: [],
      sources: sourcesForRequest(this.sources()),
      isAiAssisted: this.aiAssisted(),
    };
  }

  /** Translated message for the ProblemDetails `code` plus every validation code we know. */
  private describe(error: unknown): PublishError {
    if (!isApiError(error)) return { message: this.errors.forError(error), details: [] };
    const message = this.errors.forCode(error.code, error.problem?.detail ?? error.problem?.title);
    const details = Object.values(error.validationErrors)
      .flat()
      .filter((code) => code !== error.code && this.transloco.translate(`errors.${code}`) !== `errors.${code}`)
      .map((code) => this.errors.forCode(code));
    return { message, details: [...new Set(details)] };
  }

  protected valueOf(event: Event): string {
    return (event.target as HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement).value;
  }

  protected checkedOf(event: Event): boolean {
    return (event.target as HTMLInputElement).checked;
  }
}
