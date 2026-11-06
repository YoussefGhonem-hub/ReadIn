import {
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
  DestroyRef,
  Injector,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { Title } from '@angular/platform-browser';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { Subscription } from 'rxjs';
import { ArticleLanguage, FieldDto, TopicDto } from '../../core/api/models';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { ThemeService } from '../../core/theme/theme.service';
import { AutoDir } from '../../shared/directives/auto-dir.directive';
import { RelativeTimePipe } from '../../shared/pipes/format.pipes';
import { articleLink } from '../../shared/ui/article-link';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { LinesSkeleton } from '../../shared/ui/skeletons';
import { EmptyState, ErrorState } from '../../shared/ui/states';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { ArticlePreview, PreviewAuthor } from './article-preview';
import { AttachmentBar } from './attachment-bar';
import { AttachmentDraft } from './attachment-draft';
import { CheckTarget, SUBTITLE_MAX, TITLE_MAX, TITLE_MIN, readingTimeOf, titleState } from './checks';
import { ChecksPanel } from './checks-panel';
import { ArticleEditorStore } from './editor.store';
import { DocumentPatch, MetadataPanel } from './metadata-panel';
import { BlockEditor, ContentChange } from './rdoc-editor/block-editor';
import { RevisionHistory } from './revision-history';

type Mode = 'edit' | 'preview' | 'history';
type Confirm = { kind: 'discard' } | { kind: 'delete' } | { kind: 'removeTranslation'; language: ArticleLanguage } | { kind: 'restore'; revision: number };

/**
 * The article editor (F05): language versions (title, subtitle, block content), article settings, attachments, live
 * checks, autosave with a local backup, preview, revision history and Publish / Update. State is in
 * {@link ArticleEditorStore}; attachments in {@link AttachmentDraft}.
 */
@Component({
  selector: 'rd-article-editor',
  imports: [
    RouterLink,
    TranslocoPipe,
    LucideDynamicIcon,
    AutoDir,
    RelativeTimePipe,
    Segmented,
    BottomSheet,
    LinesSkeleton,
    EmptyState,
    ErrorState,
    BlockEditor,
    AttachmentBar,
    MetadataPanel,
    ChecksPanel,
    ArticlePreview,
    RevisionHistory,
  ],
  providers: [ArticleEditorStore, AttachmentDraft],
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: `
    /* The title and subtitle grow with their text (field-sizing from .rd-autogrow) and never scroll: Arabic glyphs
       overflow a leading-snug line box by a pixel or two, which made the shared rule (overflow-y: auto) show a
       scrollbar inside the field. No max-height either: a 150-character title is many lines on a phone. */
    .title {
      resize: none;
      overflow: hidden;
      max-height: none;
    }
    /* Without field-sizing (older Firefox) the field can't grow: it scrolls instead of hiding text, and the title
       starts two lines tall so most titles fit. */
    @supports not (field-sizing: content) {
      .title {
        overflow-y: auto;
      }
      .title-main {
        min-height: 2lh;
      }
    }
    .title::placeholder {
      color: var(--rd-color-text-secondary);
      opacity: 0.7;
    }
    @media (min-width: 64rem) {
      .layout {
        grid-template-columns: minmax(0, 1fr) 288px;
      }
    }
    @media (min-width: 80rem) {
      .layout {
        grid-template-columns: minmax(0, 1fr) 320px;
      }
    }
  `,
  // The whole width of the window, with a small margin (not the page container): long lines of code and wide tables
  // fit, and the settings stay beside the text.
  host: { class: 'block w-full px-4 pb-16 pt-4 lg:px-6 lg:pt-6', '[attr.data-editor-state]': 'store.loadState()' },
  template: `
    @switch (store.loadState()) {
      @case ('loading') {
        <div class="rd-card flex flex-col gap-4 p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5" aria-busy="true">
          <div class="rd-skeleton h-10 w-2/3"></div>
          <rd-lines-skeleton [count]="8" />
        </div>
      }
      @case ('notFound') {
        <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0">
          <rd-empty-state [title]="'errors.article.not_found' | transloco" [message]="'editor.notFoundBody' | transloco">
            <a routerLink="/write" class="rd-btn rd-btn-primary mt-3">{{ 'editor.back' | transloco }}</a>
          </rd-empty-state>
        </div>
      }
      @case ('error') {
        <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0">
          <rd-error-state [message]="'editor.loadError' | transloco" (retry)="openArticle()" />
        </div>
      }
      @default {
        <!-- Header: back, save status, preview / history, Publish or Update -->
        <header class="mb-4 flex flex-wrap items-center gap-2" data-editor-header>
          <a routerLink="/write" class="rd-btn rd-btn-ghost min-h-10 px-2 text-sm" data-back>
            <svg lucideIcon="ArrowRight" [size]="18" class="ltr:rotate-180" aria-hidden="true"></svg>
            {{ 'editor.back' | transloco }}
          </a>
          <span class="inline-flex items-center gap-1.5 text-xs text-text-secondary" role="status" data-save-status [attr.data-state]="statusKey()">
            @switch (statusKey()) {
              @case ('saving') {
                <svg lucideIcon="CloudUpload" [size]="15" aria-hidden="true"></svg>
              }
              @case ('saved') {
                <svg lucideIcon="CloudCheck" [size]="15" class="text-success" aria-hidden="true"></svg>
              }
              @case ('offline') {
                <svg lucideIcon="CloudOff" [size]="15" class="text-error" aria-hidden="true"></svg>
              }
              @case ('error') {
                <svg lucideIcon="CircleAlert" [size]="15" class="text-error" aria-hidden="true"></svg>
              }
              @case ('conflict') {
                <svg lucideIcon="TriangleAlert" [size]="15" class="text-error" aria-hidden="true"></svg>
              }
            }
            @if (statusKey(); as key) {
              <span>{{ 'editor.status.' + key | transloco }}</span>
            }
            @if (statusKey() === 'error') {
              <button type="button" class="font-semibold text-primary underline" (click)="saveNow()">{{ 'editor.status.retry' | transloco }}</button>
            }
          </span>
          <span class="ms-auto flex flex-wrap items-center gap-2">
            @if (problemCount() && mode() === 'edit') {
              <button type="button" class="rd-btn rd-btn-ghost min-h-10 px-2 text-sm text-error lg:hidden" data-problem-count (click)="showChecks()">
                <svg lucideIcon="CircleAlert" [size]="16" aria-hidden="true"></svg>
                {{ problemCount() }}
              </button>
            }
            <button type="button" class="rd-btn rd-btn-outline min-h-10 px-3 text-sm" [attr.aria-pressed]="mode() === 'preview'" data-preview-toggle (click)="toggleMode('preview')">
              <svg [lucideIcon]="mode() === 'preview' ? 'Pencil' : 'Eye'" [size]="16" aria-hidden="true"></svg>
              {{ (mode() === 'preview' ? 'editor.actions.backToEditing' : 'editor.actions.preview') | transloco }}
            </button>
            @if (store.isPublished()) {
              <button type="button" class="rd-btn rd-btn-outline min-h-10 px-3 text-sm" [attr.aria-pressed]="mode() === 'history'" data-history-toggle (click)="toggleMode('history')">
                <svg lucideIcon="History" [size]="16" aria-hidden="true"></svg>
                <span class="hidden sm:inline">{{ 'editor.actions.history' | transloco }}</span>
                <span class="sr-only sm:hidden">{{ 'editor.actions.history' | transloco }}</span>
              </button>
            }
            <button
              type="button"
              class="rd-btn rd-btn-primary min-h-10 min-w-32 px-4 text-sm"
              [disabled]="!canPublish()"
              [attr.aria-describedby]="publishHint() ? 'ed-publish-hint' : null"
              data-publish
              (click)="publish()"
            >
              @if (store.action() === 'publishing') {
                <svg lucideIcon="LoaderCircle" [size]="16" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ publishLabel() | transloco }}
            </button>
          </span>
          @if (publishHint(); as hint) {
            <p id="ed-publish-hint" class="m-0 w-full text-end text-xs text-text-secondary" data-publish-hint>{{ hint | transloco }}</p>
          }
        </header>

        @if (store.restoreOffer(); as backup) {
          <div class="rd-alert rd-alert-info mb-4 flex flex-wrap items-center gap-3" role="alert" data-restore-offer>
            <span class="min-w-0 flex-1">
              <strong class="block">{{ 'editor.restore.title' | transloco }}</strong>
              {{ 'editor.restore.body' | transloco: { time: (backup.updatedAt | rdRelativeTime: lang()) } }}
            </span>
            <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm" data-restore-dismiss (click)="store.dismissRestore()">{{ 'editor.restore.dismiss' | transloco }}</button>
            <button type="button" class="rd-btn rd-btn-primary min-h-9 px-3 text-sm" data-restore-accept (click)="store.acceptRestore()">{{ 'editor.restore.restore' | transloco }}</button>
          </div>
        }

        @if (store.conflict()) {
          <div class="rd-alert rd-alert-error mb-4 flex flex-wrap items-center gap-3" role="alert" data-conflict>
            <span class="min-w-0 flex-1">
              <strong class="block">{{ 'editor.conflict.title' | transloco }}</strong>
              {{ 'editor.conflict.body' | transloco }}
            </span>
            <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" [disabled]="!!store.action()" data-conflict-reload (click)="reloadServerCopy()">
              {{ 'editor.conflict.reload' | transloco }}
            </button>
            <button type="button" class="rd-btn rd-btn-primary min-h-9 px-3 text-sm" [disabled]="!!store.action()" data-conflict-keep (click)="store.keepMine()">
              {{ 'editor.conflict.keepMine' | transloco }}
            </button>
          </div>
        }

        @if (store.actionError(); as code) {
          <p class="rd-alert rd-alert-error mb-4" role="alert" data-action-error>{{ errorText(code) }}</p>
        }

        @if (mode() === 'preview') {
          <!-- One card: the preview's controls, then the article as readers get it. -->
          <div class="rd-card shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0">
            <div class="flex flex-wrap items-center gap-3 border-b border-border px-4 py-3 lg:px-5" data-preview-controls>
              <p class="m-0 flex-1 text-sm text-text-secondary">{{ 'editor.preview.note' | transloco }}</p>
              <rd-segmented class="min-w-36" [options]="themeOptions()" [(value)]="previewTheme" [label]="'editor.preview.theme' | transloco" data-preview-theme />
              @if (languageOptions().length > 1) {
                <rd-segmented class="min-w-36" [options]="languageOptions()" [(value)]="previewLanguage" [label]="'editor.preview.version' | transloco" data-preview-language />
              }
            </div>
            <div class="px-4 py-6 lg:px-5">
              <rd-article-preview
                [document]="store.document()"
                [language]="previewLanguage()"
                [media]="store.media()"
                [field]="selectedField()"
                [topic]="selectedTopic()"
                [author]="author()"
                [minutes]="previewMinutes()"
                [publishedAt]="store.publishedAt()"
                [slug]="store.slug()"
                [uiLang]="lang()"
              />
            </div>
          </div>
        } @else if (mode() === 'history' && store.articleId(); as id) {
          <rd-revision-history [articleId]="id" [author]="author()" [fields]="fields()" [media]="store.media()" [busy]="!!store.action()" (restore)="confirm.set({ kind: 'restore', revision: $event })" />
        }

        <!-- Editing (kept alive while previewing, so uploads and undo history survive) -->
        <div class="layout grid items-start gap-2 lg:gap-6" [hidden]="mode() !== 'edit'" data-edit-area>
          <!-- The writing card: language versions, title, subtitle, the block editor and the attachments. -->
          <!-- Wide inline padding on large screens: the block handle (grip + trash) sits there, beside the text. -->
          <div class="rd-card min-w-0 p-4 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0 lg:p-5 lg:px-12">
            <div class="mb-4 flex flex-wrap items-center gap-2" data-languages>
              @if (store.document().translations.length === 1) {
                <span class="text-sm text-text-secondary" id="ed-language-label">{{ 'editor.language.label' | transloco }}</span>
                <rd-segmented
                  class="min-w-36"
                  [options]="sourceOptions()"
                  [value]="store.document().sourceLanguage"
                  (valueChange)="setSourceLanguage($event)"
                  [label]="'editor.language.label' | transloco"
                  data-source-language
                />
                <button type="button" class="rd-btn rd-btn-ghost min-h-10 px-2 text-sm text-primary" data-add-translation (click)="addTranslation()">
                  <svg lucideIcon="Plus" [size]="16" aria-hidden="true"></svg>
                  {{ 'editor.language.add' | transloco: { language: languageName(otherLanguage()) } }}
                </button>
              } @else {
                <div class="flex gap-1 rounded-md bg-surface-variant p-1" role="tablist" [attr.aria-label]="'editor.language.versions' | transloco">
                  @for (t of store.document().translations; track t.language) {
                    <button
                      type="button"
                      role="tab"
                      class="min-h-9 rounded-sm px-3 text-sm"
                      [class]="t.language === activeLanguage() ? 'bg-surface font-semibold text-primary shadow-card' : 'text-text-secondary'"
                      [attr.aria-selected]="t.language === activeLanguage()"
                      [attr.data-language-tab]="t.language"
                      (click)="switchLanguage(t.language)"
                    >
                      {{ languageName(t.language) }}
                      @if (t.language === store.document().sourceLanguage) {
                        <span class="text-xs font-normal text-text-secondary">· {{ 'editor.language.source' | transloco }}</span>
                      }
                    </button>
                  }
                </div>
                <button type="button" class="rd-btn rd-btn-ghost min-h-10 px-2 text-sm" data-remove-translation (click)="confirm.set({ kind: 'removeTranslation', language: otherLanguage() })">
                  <svg lucideIcon="Trash2" [size]="16" aria-hidden="true"></svg>
                  {{ 'editor.language.remove' | transloco: { language: languageName(otherLanguage()) } }}
                </button>
              }
            </div>

            @if (activeTranslation(); as t) {
              <label class="sr-only" for="ed-title">{{ 'editor.titleLabel' | transloco }}</label>
              <textarea
                id="ed-title"
                rows="1"
                class="title title-main rd-autogrow block w-full border-0 bg-transparent p-0 text-[28px] font-semibold leading-snug outline-none lg:text-[32px]"
                [rdAutoDir]="t.title"
                [attr.lang]="t.language"
                [maxLength]="titleMax"
                [value]="t.title"
                [placeholder]="'editor.titlePlaceholder' | transloco"
                [attr.aria-invalid]="titleInfo().state === 'short' ? 'true' : null"
                aria-describedby="ed-title-count"
                data-title
                (input)="setTitle(valueOf($event))"
                (keydown.enter)="$event.preventDefault()"
              ></textarea>
              <p id="ed-title-count" class="m-0 mt-1 flex justify-between gap-2 text-xs" [class]="titleInfo().state === 'short' ? 'text-error' : 'text-text-secondary'" data-title-count>
                <span>{{ titleInfo().state === 'short' || titleInfo().state === 'empty' ? ('editor.titleHint' | transloco: { min: titleMin, max: titleMax }) : '' }}</span>
                <span class="tabular-nums" dir="ltr">{{ titleInfo().length }}/{{ titleMax }}</span>
              </p>
              <label class="sr-only" for="ed-subtitle">{{ 'editor.subtitleLabel' | transloco }}</label>
              <textarea
                id="ed-subtitle"
                rows="1"
                class="title rd-autogrow mt-2 block w-full border-0 bg-transparent p-0 text-lg text-text-secondary outline-none"
                [rdAutoDir]="t.subtitle ?? ''"
                [attr.lang]="t.language"
                [maxLength]="subtitleMax"
                [value]="t.subtitle ?? ''"
                [placeholder]="'editor.subtitlePlaceholder' | transloco"
                data-subtitle
                (input)="setSubtitle(valueOf($event))"
                (keydown.enter)="$event.preventDefault()"
              ></textarea>

              <rd-block-editor
                class="mt-5"
                [content]="t.content"
                [language]="t.language"
                [contentKey]="store.contentVersion()"
                [label]="'editor.contentLabel' | transloco"
                (changed)="onContentChange($event)"
                (uploadsChange)="imageUploads.set($event)"
              />
            }

            <section
              id="ed-attachments"
              class="-mx-4 -mb-4 mt-8 border-t border-border px-4 pb-4 pt-5 lg:-mx-5 lg:-mb-5 lg:px-5 lg:pb-5"
              tabindex="-1"
              [attr.aria-labelledby]="'ed-attachments-title'"
            >
              <h2 id="ed-attachments-title" class="m-0 mb-3 text-sm font-semibold">{{ 'attachments.label' | transloco }}</h2>
              <rd-attachment-bar [draft]="attachments" />
            </section>
          </div>

          <!-- The side panel: a stack of cards (checks, details, cover, sources, labels, then delete). -->
          <aside class="flex flex-col gap-2" [attr.aria-label]="'editor.meta.title' | transloco">
            <rd-checks-panel
              id="ed-checks"
              tabindex="-1"
              [checks]="store.checks()"
              [sourceLanguage]="store.document().sourceLanguage"
              [languages]="languages()"
              [uploading]="uploading()"
              (jump)="jump($event)"
            />
            <rd-metadata-panel
              [document]="store.document()"
              [fields]="fields()"
              [topics]="topics()"
              [fieldsFailed]="fieldsFailed()"
              [tagFlags]="tagFlags()"
              [tagErrors]="store.tagErrors()"
              [categoryId]="store.categoryId()"
              [categorySaving]="store.categorySaving()"
              [categoryError]="store.categoryError()"
              (patch)="patchDocument($event)"
              (categoryChange)="store.setCategory($event)"
              (retryFields)="loadFields()"
              (coverUploading)="coverUploading.set($event)"
            />
            <div class="rd-card flex flex-col gap-1 p-2 shadow-none max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0" data-danger-zone>
              @if (store.isPublished() && store.hasUnpublishedChanges()) {
                <button type="button" class="rd-btn rd-btn-outline justify-start text-sm" [disabled]="!!store.action()" data-discard (click)="confirm.set({ kind: 'discard' })">
                  <svg lucideIcon="RotateCcw" [size]="16" aria-hidden="true"></svg>
                  {{ 'editor.actions.discard' | transloco }}
                </button>
              }
              <button type="button" class="rd-btn rd-btn-ghost justify-start text-sm text-error" [disabled]="!!store.action()" data-delete (click)="confirm.set({ kind: 'delete' })">
                <svg lucideIcon="Trash2" [size]="16" aria-hidden="true"></svg>
                {{ 'editor.actions.delete' | transloco }}
              </button>
            </div>
          </aside>
        </div>
      }
    }

    <rd-bottom-sheet [open]="!!confirm()" role="alertdialog" labelledBy="ed-confirm-title" describedBy="ed-confirm-body" [dismissible]="!store.action()" (closed)="confirm.set(null)">
      @if (confirm(); as c) {
        <div class="flex flex-col gap-3 pt-1" data-confirm-sheet [attr.data-confirm]="c.kind">
          <h2 id="ed-confirm-title" class="m-0 pe-10 text-xl font-semibold">{{ confirmTitle(c) }}</h2>
          <p id="ed-confirm-body" class="m-0 text-sm text-text-secondary">{{ confirmBody(c) }}</p>
          <div class="mt-2 flex gap-2">
            <button type="button" class="rd-btn rd-btn-outline flex-1" [disabled]="!!store.action()" (click)="confirm.set(null)">{{ 'common.cancel' | transloco }}</button>
            <button
              type="button"
              class="rd-btn flex-1"
              [class]="c.kind === 'restore' ? 'rd-btn-primary' : 'bg-error text-on-error'"
              [disabled]="!!store.action()"
              data-confirm-action
              (click)="runConfirmed(c)"
            >
              @if (store.action()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
              }
              {{ confirmAction(c) }}
            </button>
          </div>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class ArticleEditor {
  protected readonly store = inject(ArticleEditorStore);
  protected readonly attachments = inject(AttachmentDraft);
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly session = inject(SessionStore);
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);
  private readonly toasts = inject(ToastService);
  private readonly router = inject(Router);
  private readonly theme = inject(ThemeService);
  private readonly document = inject(DOCUMENT);
  private readonly injector = inject(Injector);
  private readonly titleService = inject(Title);
  protected readonly lang = inject(LanguageService).lang;

  /** Null for a new article. */
  readonly articleId = input<string | null>(null);
  readonly created = output<string>();

  protected readonly titleMin = TITLE_MIN;
  protected readonly titleMax = TITLE_MAX;
  protected readonly subtitleMax = SUBTITLE_MAX;

  protected readonly mode = signal<Mode>('edit');
  protected readonly confirm = signal<Confirm | null>(null);
  protected readonly activeLanguage = signal<ArticleLanguage>('ar-EG');
  protected readonly previewLanguage = signal<ArticleLanguage>('ar-EG');
  protected readonly previewTheme = signal<'light' | 'dark'>('light');
  protected readonly imageUploads = signal(0);
  protected readonly coverUploading = signal(false);
  protected readonly fields = signal<FieldDto[]>([]);
  protected readonly fieldsFailed = signal(false);
  protected readonly topics = signal<TopicDto[]>([]);
  private topicsRequest: Subscription | null = null;
  private topicsFor: string | null = null;

  private readonly blockEditor = viewChild(BlockEditor);

  protected readonly languages = computed(() => this.store.document().translations.map((t) => t.language));
  protected readonly activeTranslation = computed(() => {
    const translations = this.store.document().translations;
    return translations.find((t) => t.language === this.activeLanguage()) ?? translations[0];
  });
  protected readonly otherLanguage = computed<ArticleLanguage>(() => (this.store.document().sourceLanguage === 'en' ? 'ar-EG' : 'en'));
  protected readonly titleInfo = computed(() => titleState(this.activeTranslation()?.title ?? ''));
  protected readonly selectedField = computed(() => this.fields().find((f) => f.id === this.store.document().fieldId) ?? null);
  protected readonly selectedTopic = computed(() => this.topics().find((t) => t.id === this.store.document().topicId) ?? null);
  protected readonly uploading = computed(() => this.attachments.isBusy() || this.imageUploads() > 0 || this.coverUploading());
  protected readonly problemCount = computed(() => this.store.problems().length);
  /** Tags the last checks (`tag.hidden`, `tag.limit`) or a refused save (`tag.invalid`) are about (F32). */
  protected readonly tagFlags = computed(() => [
    ...this.store.problems().flatMap((p) => (p.tag ? [p.tag] : [])),
    ...this.store.tagErrors().flatMap((e) => (e.tag ? [e.tag] : [])),
  ]);
  protected readonly previewMinutes = computed(() => readingTimeOf(this.store.checks(), this.previewLanguage())?.minutes ?? null);
  protected readonly author = computed<PreviewAuthor>(() => {
    const me = this.session.me();
    return { displayName: me?.displayName ?? '', username: me?.username ?? '', avatarUrl: me?.avatarUrl ?? null, isVerified: !!me?.isVerified };
  });

  /** "Saving…" covers unsaved changes waiting for the next autosave too. */
  protected readonly statusKey = computed(() => {
    const status = this.store.saveStatus();
    if (status === 'conflict' || status === 'offline' || status === 'error' || status === 'saving') return status;
    if (this.store.dirty()) return 'saving';
    return this.store.articleId() ? 'saved' : null;
  });

  protected readonly canPublish = computed(
    () =>
      this.store.loadState() === 'ready' &&
      !this.store.action() &&
      !this.store.conflict() &&
      !this.uploading() &&
      this.attachments.isComplete() &&
      this.problemCount() === 0 &&
      this.store.hasChangesToPublish() &&
      (!!this.store.articleId() || this.store.dirty()),
  );
  protected readonly publishLabel = computed(() => {
    const updating = this.store.isPublished();
    if (this.store.action() === 'publishing') return updating ? 'editor.actions.updating' : 'editor.actions.publishing';
    return updating ? 'editor.actions.update' : 'editor.actions.publish';
  });
  /** Why Publish is disabled, when it isn't obvious from the checks panel. */
  protected readonly publishHint = computed(() => {
    if (this.uploading()) return 'editor.problems.uploading';
    // Attachment problems the bar already shows (the server reports them too, after the next save).
    if (this.attachments.hasProblem()) return 'editor.problems.attachmentFailed';
    if (this.attachments.missingAltCount()) return 'editor.problems.attachments_alt_text_required';
    if (this.attachments.documentTitleMissing()) return 'editor.problems.attachments_title_required';
    if (this.store.isPublished() && !this.store.hasChangesToPublish()) return 'editor.actions.noChanges';
    return null;
  });

  protected readonly sourceOptions = computed<SegmentOption<ArticleLanguage>[]>(() => {
    this.lang();
    return [
      { value: 'ar-EG', label: this.languageName('ar-EG') },
      { value: 'en', label: this.languageName('en'), ltr: true },
    ];
  });
  protected readonly languageOptions = computed<SegmentOption<ArticleLanguage>[]>(() => {
    this.lang();
    return this.languages().map((value) => ({ value, label: this.languageName(value), ltr: value === 'en' }));
  });
  protected readonly themeOptions = computed<SegmentOption<'light' | 'dark'>[]>(() => {
    this.lang();
    return [
      { value: 'light', label: this.transloco.translate('editor.preview.light') },
      { value: 'dark', label: this.transloco.translate('editor.preview.dark') },
    ];
  });

  constructor() {
    const store = this.store;
    store.onCreated = (id) => this.created.emit(id);
    store.beforeSave = () => this.blockEditor()?.flush();
    this.loadFields();

    // Open the article (or start a new one) once.
    effect(() => {
      const id = this.articleId();
      untracked(() => this.openArticle(id));
    });

    // The document was replaced (load, reload, restore, discard): attachments and the active language follow it.
    effect(() => {
      store.contentVersion();
      untracked(() => {
        const document = store.document();
        void this.attachments.loadResolving(document.attachments, store.media());
        if (!document.translations.some((t) => t.language === this.activeLanguage())) this.activeLanguage.set(document.sourceLanguage);
      });
    });
    effect(() => {
      // Ready attachments go into the draft (the store ignores changes that mean nothing).
      const list = this.attachments.draftAttachments();
      untracked(() => {
        if (store.loadState() === 'ready') store.setAttachments(list);
      });
    });

    // Topics of the chosen field.
    effect(() => {
      const field = this.selectedField();
      untracked(() => this.loadTopics(field));
    });

    // Tab title.
    effect(() => {
      const title = this.store.document().translations.find((t) => t.language === this.store.document().sourceLanguage)?.title.trim();
      const key = this.articleId() || this.store.articleId() ? 'editor.editTitle' : 'editor.newTitle';
      this.titleService.setTitle(`${title || this.transloco.translate(key)} — ReadIn`);
    });

    // Preview in the other theme without saving it as the user's preference.
    effect(() => {
      const theme = this.mode() === 'preview' ? this.previewTheme() : null;
      untracked(() => this.document.documentElement.setAttribute('data-theme', theme ?? this.theme.preference()));
    });

    inject(DestroyRef).onDestroy(() => {
      this.topicsRequest?.unsubscribe();
      this.document.documentElement.setAttribute('data-theme', this.theme.preference());
    });
  }

  protected openArticle(id: string | null = this.articleId()): void {
    const userId = this.session.me()?.id ?? 'anonymous';
    if (id) {
      void this.store.open(userId, id).then(() => this.activeLanguage.set(this.store.document().sourceLanguage));
    } else {
      const language = this.session.me()?.articleLanguage ?? (this.lang() === 'ar' ? 'ar-EG' : 'en');
      this.store.startNew(userId, language);
      this.activeLanguage.set(language);
    }
  }

  loadFields(): void {
    this.fieldsFailed.set(false);
    this.taxonomy.fields().subscribe({
      next: (fields) => this.fields.set(fields),
      error: () => this.fieldsFailed.set(true),
    });
  }

  private loadTopics(field: FieldDto | null): void {
    if (field?.slug === this.topicsFor) return;
    this.topicsFor = field?.slug ?? null;
    this.topicsRequest?.unsubscribe();
    this.topics.set([]);
    if (!field?.topicCount) return;
    this.topicsRequest = this.taxonomy.topics(field.slug).subscribe({
      next: (topics) => this.topics.set(topics),
      error: () => this.topics.set([]), // the topic is optional
    });
  }

  // ── Editing ────────────────────────────────────────────

  protected setTitle(title: string): void {
    this.store.updateTranslation(this.activeTranslation().language, { title });
  }

  protected setSubtitle(subtitle: string): void {
    this.store.updateTranslation(this.activeTranslation().language, { subtitle: subtitle.trim() ? subtitle : null });
  }

  protected onContentChange(change: ContentChange): void {
    if (this.store.document().translations.some((t) => t.language === change.language)) this.store.setContent(change.language, change.content);
  }

  protected patchDocument(patch: DocumentPatch): void {
    this.store.patch(patch);
  }

  protected switchLanguage(language: ArticleLanguage): void {
    if (language === this.activeLanguage()) return;
    this.blockEditor()?.flush();
    this.activeLanguage.set(language);
  }

  protected setSourceLanguage(language: ArticleLanguage): void {
    this.blockEditor()?.flush();
    this.store.setSourceLanguage(language);
    this.activeLanguage.set(language);
  }

  protected addTranslation(): void {
    const language = this.otherLanguage();
    this.store.addTranslation(language);
    this.switchLanguage(language);
    this.focus('#ed-title');
  }

  protected languageName(language: ArticleLanguage): string {
    this.lang();
    return this.transloco.translate(`editor.language.names.${language === 'en' ? 'en' : 'arEG'}`);
  }

  // ── Modes ──────────────────────────────────────────────

  protected toggleMode(mode: Exclude<Mode, 'edit'>): void {
    this.blockEditor()?.flush();
    if (mode === 'preview' && this.mode() !== 'preview') {
      this.previewLanguage.set(this.activeLanguage());
      this.previewTheme.set(this.theme.resolved());
    }
    this.mode.set(this.mode() === mode ? 'edit' : mode);
  }

  protected showChecks(): void {
    this.focus('#ed-checks');
  }

  /** A live check was picked: go to the field or block it is about. */
  protected jump(target: CheckTarget): void {
    this.mode.set('edit');
    switch (target.kind) {
      case 'field':
        this.focus('#ed-field');
        break;
      case 'sources':
        this.focus('#ed-sources [data-source-title], #ed-sources [data-add-source]');
        break;
      case 'title':
        this.switchLanguage(target.language);
        this.focus('#ed-title');
        break;
      case 'content':
        this.switchLanguage(target.language);
        this.afterRender(() => this.blockEditor()?.focusStart());
        break;
      case 'block':
        this.switchLanguage(target.language);
        this.afterRender(() => this.blockEditor()?.focusBlock(target.blockId));
        break;
      case 'attachment': {
        const local = this.attachments.localIdOf(target.mediaAssetId);
        const isDocument = !!this.attachments.document() && this.attachments.document()?.id === local;
        this.focus(local ? (isDocument ? '#rd-doc-title' : `#rd-alt-${local}`) : '#ed-attachments');
        break;
      }
      case 'tag':
        this.focusTag(target.tag);
        break;
    }
  }

  /** A tag problem: the chip's remove button (the usual fix), else the tag input. */
  private focusTag(tag: string | null): void {
    this.afterRender(() => {
      const field = this.document.querySelector<HTMLElement>('#ed-tags');
      const chip = [...(field?.querySelectorAll<HTMLElement>('[data-tag]') ?? [])].find((el) => el.getAttribute('data-tag') === tag);
      const element = chip?.querySelector<HTMLElement>('[data-tag-remove]') ?? field?.querySelector<HTMLElement>('[data-tag-input]:not(:disabled)') ?? null;
      field?.scrollIntoView?.({ block: 'center', behavior: 'smooth' });
      element?.focus({ preventScroll: true });
    });
  }

  private afterRender(action: () => void): void {
    afterNextRender(() => setTimeout(action), { injector: this.injector });
  }

  private focus(selector: string): void {
    this.afterRender(() => {
      const element = this.document.querySelector<HTMLElement>(selector);
      element?.scrollIntoView?.({ block: 'center', behavior: 'smooth' });
      element?.focus({ preventScroll: true });
    });
  }

  // ── Actions ────────────────────────────────────────────

  protected saveNow(): void {
    void this.store.save();
  }

  protected async publish(): Promise<void> {
    if (!this.canPublish()) return;
    this.blockEditor()?.flush();
    const wasPublished = this.store.isPublished();
    const result = await this.store.publish();
    if (result) {
      this.toasts.success(this.transloco.translate(wasPublished ? 'editor.actions.updated' : 'editor.actions.published'));
      await this.router.navigate(articleLink({ slug: result.slug, language: this.store.document().sourceLanguage }));
    } else if (this.problemCount()) {
      this.focus('#ed-checks');
    }
  }

  protected async reloadServerCopy(): Promise<void> {
    await this.store.reloadServerCopy();
  }

  protected confirmTitle(c: Confirm): string {
    switch (c.kind) {
      case 'discard':
        return this.transloco.translate('editor.actions.discardTitle');
      case 'delete':
        return this.transloco.translate('editor.myArticles.deleteTitle');
      case 'removeTranslation':
        return this.transloco.translate('editor.language.removeTitle', { language: this.languageName(c.language) });
      case 'restore':
        return this.transloco.translate('editor.revisions.restoreTitle', { number: c.revision });
    }
  }

  protected confirmBody(c: Confirm): string {
    switch (c.kind) {
      case 'discard':
        return this.transloco.translate('editor.actions.discardBody');
      case 'delete':
        return this.transloco.translate(this.store.isPublished() ? 'editor.myArticles.deletePublishedBody' : 'editor.myArticles.deleteDraftBody');
      case 'removeTranslation':
        return this.transloco.translate('editor.language.removeBody');
      case 'restore':
        return this.transloco.translate('editor.revisions.restoreBody');
    }
  }

  protected confirmAction(c: Confirm): string {
    switch (c.kind) {
      case 'discard':
        return this.transloco.translate('editor.actions.discardConfirm');
      case 'delete':
        return this.transloco.translate('editor.myArticles.deleteConfirm');
      case 'removeTranslation':
        return this.transloco.translate('editor.language.removeConfirm');
      case 'restore':
        return this.transloco.translate('editor.revisions.restore');
    }
  }

  protected async runConfirmed(c: Confirm): Promise<void> {
    switch (c.kind) {
      case 'removeTranslation':
        this.confirm.set(null);
        this.blockEditor()?.flush();
        this.store.removeTranslation(c.language);
        this.activeLanguage.set(this.store.document().sourceLanguage);
        return;
      case 'discard':
        if (await this.store.discardChanges()) {
          this.confirm.set(null);
          this.toasts.success(this.transloco.translate('editor.actions.discarded'));
        } else this.confirm.set(null);
        return;
      case 'restore':
        if (await this.store.restoreRevision(c.revision)) {
          this.confirm.set(null);
          this.mode.set('edit');
          this.toasts.success(this.transloco.translate('editor.revisions.restored', { number: c.revision }));
        } else this.confirm.set(null);
        return;
      case 'delete':
        if (await this.store.deleteArticle()) {
          this.confirm.set(null);
          this.toasts.success(this.transloco.translate('editor.myArticles.deleted'));
          await this.router.navigate(['/write']);
        } else this.confirm.set(null);
        return;
    }
  }

  protected errorText(code: string): string {
    return this.errors.forCode(code);
  }

  protected valueOf(event: Event): string {
    return (event.target as HTMLTextAreaElement).value;
  }
}
