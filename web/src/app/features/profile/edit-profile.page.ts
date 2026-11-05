import { ChangeDetectionStrategy, Component, DOCUMENT, DestroyRef, ElementRef, Injector, afterNextRender, computed, effect, inject, signal, untracked, viewChild } from '@angular/core';
import { takeUntilDestroyed, toSignal } from '@angular/core/rxjs-interop';
import { HttpEventType } from '@angular/common/http';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { Title } from '@angular/platform-browser';
import { Router, RouterLink } from '@angular/router';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { Subscription, firstValueFrom, startWith } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { MeApi } from '../../core/api/me.api';
import { MediaApi } from '../../core/api/media.api';
import { FieldDto, ProfileDto, UpdateProfileRequest } from '../../core/api/models';
import { ProfilesApi } from '../../core/api/profiles.api';
import { TaxonomyApi } from '../../core/api/taxonomy.api';
import { AuthService } from '../../core/auth/auth.service';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { AVATAR_TYPES, avatarUrlOf } from '../../shared/media/avatar-variant';
import { ImageCompressor } from '../../shared/media/image-compressor';
import { ErrorState } from '../../shared/ui/states';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { UsernameStatus, normalizeUsername, usernameStatus } from '../../shared/utils/username';
import { ExpertisePicker, MAX_EXPERTISE } from './expertise-picker';
import { HeadlineField } from './headline-field';
import { LinkCode, checkLinks, headlineProblem, normalizeHeadline, normalizeLinkUrl, toLinkInputs } from './link-rules';
import { LinkRow, LinksEditor, linkRows } from './links-editor';
import { PROFILE_ICONS } from './profile-icons';
import { profileLinksOf } from './profile-links';

export const MAX_BIO = 300;

/** A form field a server error can point at (the links have their own, per link: see linkFieldErrors). */
export type ProfileField = 'displayName' | 'username' | 'headline' | 'bio' | 'avatar' | 'expertise';
/** Translation keys per field, plus `general` (an already translated message) for anything else. */
export type ProfileFieldErrors = Partial<Record<ProfileField, string>> & { general?: string };

/** Validation keys from the API (camelCase property paths) → form fields. */
const VALIDATION_FIELDS: Record<string, ProfileField> = {
  displayname: 'displayName',
  username: 'username',
  headline: 'headline',
  bio: 'bio',
  avatarassetid: 'avatar',
  avatarurl: 'avatar',
  expertisefieldids: 'expertise',
};
const FIELD_MESSAGES: Record<ProfileField, string> = {
  displayName: 'profile.edit.displayNameError',
  username: 'errors.user.username_invalid',
  headline: 'errors.profile.headline_invalid',
  bio: 'profile.edit.bioTooLong',
  avatar: 'errors.profile.avatar_invalid',
  expertise: 'errors.profile.expertise_invalid',
};

/** The input to focus for a field with an error (the photo and the picker have none). */
const INPUT_IDS: Partial<Record<ProfileField, string>> = {
  displayName: 'edit-name',
  username: 'edit-username',
  headline: 'edit-headline',
  bio: 'edit-bio',
};

/** The message of a link's validation code: the API's text, or "Paste the link" for an empty one. */
export function linkErrorKey(code: string, part: 'platform' | 'url' | 'label' | 'list'): string {
  if (code === 'validation.required') return part === 'url' ? 'profile.linksEditor.urlRequired' : 'errors.validation.required';
  if (code.startsWith('link.')) return `errors.${code}`;
  return part === 'url' ? 'errors.link.url_invalid' : 'errors.validation.failed';
}

const LINK_ERROR_KEY = /^links(?:\[(\d+)\]\.(platform|url|label))?$/;

/**
 * The link errors of a failed `PATCH /me` (`errors.links`, `errors["links[2].url"]`, …), keyed the same way (lower
 * case) with translation keys as values.
 */
export function linkFieldErrors(error: unknown): Record<string, string> {
  if (!isApiError(error)) return {};
  const result: Record<string, string> = {};
  for (const [key, codes] of Object.entries(error.validationErrors)) {
    const match = LINK_ERROR_KEY.exec(key.toLowerCase());
    if (!match || !codes.length) continue;
    const part = (match[2] ?? 'list') as 'platform' | 'url' | 'label' | 'list';
    result[match[1] === undefined ? 'links' : `links[${match[1]}].${part}`] = linkErrorKey(codes[0], part);
  }
  return result;
}

/** The local link errors (checkLinks), keyed like the API's. */
export function localLinkErrors(rows: readonly LinkRow[]): Record<string, string> {
  const checked = checkLinks(rows);
  const result: Record<string, string> = {};
  if (checked.list) result['links'] = linkErrorKey(checked.list, 'list');
  checked.items.forEach((item, i) => {
    for (const part of ['platform', 'url', 'label'] as const) {
      const code: LinkCode | null = item[part];
      if (code) result[`links[${i}].${part}`] = linkErrorKey(code, part);
    }
  });
  return result;
}

/** Maps a failed `PATCH /me` to the fields it is about (ProblemDetails `code`, or per-field validation codes). */
export function profileFieldErrors(error: unknown, translate: (error: unknown) => string): ProfileFieldErrors {
  if (!isApiError(error)) return { general: translate(error) };
  switch (error.code) {
    case 'user.username_taken':
    case 'user.username_invalid':
      return { username: `errors.${error.code}` };
    case 'profile.avatar_invalid':
      return { avatar: 'errors.profile.avatar_invalid' };
    case 'profile.expertise_invalid':
      return { expertise: 'errors.profile.expertise_invalid' };
  }
  const result: ProfileFieldErrors = {};
  for (const [key, codes] of Object.entries(error.validationErrors)) {
    // `expertiseFieldIds[5]` is about the list as a whole.
    const field = VALIDATION_FIELDS[key.toLowerCase().replace(/\[\d+\]$/, '')];
    if (!field) continue;
    if (field === 'username' && codes.includes('user.username_taken')) result[field] = 'errors.user.username_taken';
    else if (field === 'headline' && codes.includes('profile.headline_too_long')) result[field] = 'errors.profile.headline_too_long';
    else result[field] = FIELD_MESSAGES[field];
  }
  // Link errors are shown under their links (linkFieldErrors), not as a general message.
  const onLinks = Object.keys(linkFieldErrors(error)).length > 0;
  return Object.keys(result).length || onLinks ? result : { general: translate(error) };
}

/**
 * Edit profile (F14), `/settings/profile`: photo (uploaded with `purpose=avatar`, previewed from its 256 px variant,
 * removable), name, @username with the live availability check, the title (one line, ≤ 120), bio with a counter, the
 * social links (up to 8 of 14 platforms, in order; see LinksEditor) and up to 5 fields of expertise. Saving shows a spinner and can't be sent twice; server errors land on their fields.
 */
@Component({
  selector: 'rd-edit-profile-page',
  imports: [ReactiveFormsModule, RouterLink, TranslocoPipe, LucideDynamicIcon, ErrorState, ExpertisePicker, HeadlineField, LinksEditor],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'mx-auto block max-w-[640px] px-4 pt-6' },
  template: `
    <header class="mb-6">
      <h1 class="m-0 text-2xl font-bold">{{ 'profile.edit.title' | transloco }}</h1>
      <p class="m-0 mt-1 text-sm text-text-secondary">{{ 'profile.edit.subtitle' | transloco }}</p>
    </header>

    @switch (status()) {
      @case ('error') {
        <rd-error-state [message]="'profile.edit.loadError' | transloco" (retry)="load()" />
      }
      @case ('ready') {
        <form [formGroup]="form" (ngSubmit)="save()" class="flex flex-col gap-5 pb-10" novalidate data-edit-profile-form>
          <!-- Photo -->
          <section class="rd-card flex items-center gap-4 p-4 shadow-none" aria-labelledby="edit-avatar-title">
            <span class="rd-photo grid h-20 w-20 shrink-0 place-items-center overflow-hidden rounded-full bg-primary-container text-3xl font-bold text-on-primary-container" data-avatar-preview>
              @if (avatarUrl(); as src) {
                <img [src]="src" alt="" width="80" height="80" class="h-full w-full object-cover" referrerpolicy="no-referrer" />
              } @else {
                <span aria-hidden="true">{{ initial() }}</span>
              }
            </span>
            <div class="flex min-w-0 flex-1 flex-col items-start gap-2">
              <h2 id="edit-avatar-title" class="m-0 text-sm font-semibold">{{ 'profile.edit.avatar' | transloco }}</h2>
              <div class="flex flex-wrap gap-2">
                <button type="button" class="rd-btn rd-btn-outline min-h-11 gap-1.5 px-3 text-sm" [disabled]="uploading() || busy()" (click)="fileInput.click()" data-avatar-pick>
                  @if (uploading()) {
                    <svg lucideIcon="LoaderCircle" [size]="16" class="animate-spin" aria-hidden="true"></svg>
                    {{ 'profile.edit.avatarUploading' | transloco: { percent: progress() } }}
                  } @else {
                    <svg [lucideIcon]="icons.imagePlus" [size]="16" aria-hidden="true"></svg>
                    {{ (avatarUrl() ? 'profile.edit.avatarChange' : 'profile.edit.avatarAdd') | transloco }}
                  }
                </button>
                @if (avatarUrl() && !uploading()) {
                  <button type="button" class="rd-btn rd-btn-ghost min-h-11 gap-1.5 px-3 text-sm" [disabled]="busy()" (click)="removeAvatar()" data-avatar-remove>
                    <svg lucideIcon="Trash2" [size]="16" aria-hidden="true"></svg>
                    {{ 'profile.edit.avatarRemove' | transloco }}
                  </button>
                }
              </div>
              <span class="text-xs text-text-secondary">{{ 'profile.edit.avatarHint' | transloco }}</span>
              @if (avatarError(); as message) {
                <p class="rd-field-error" role="alert" data-avatar-error>{{ message }}</p>
              }
            </div>
            <input #fileInput type="file" class="hidden" [accept]="avatarTypes" (change)="pickAvatar($event)" tabindex="-1" aria-hidden="true" data-avatar-input />
          </section>

          <!-- Name -->
          <div>
            <label class="rd-label" for="edit-name">{{ 'profile.edit.displayName' | transloco }}</label>
            <input
              id="edit-name"
              class="rd-input"
              formControlName="displayName"
              autocomplete="name"
              maxlength="60"
              dir="auto"
              [attr.aria-invalid]="!!errorFor('displayName') || null"
              [attr.aria-describedby]="errorFor('displayName') ? 'edit-name-error' : null"
            />
            @if (errorFor('displayName'); as key) {
              <p id="edit-name-error" class="rd-field-error" data-field-error="displayName">{{ key | transloco }}</p>
            }
          </div>

          <!-- Username -->
          <div>
            <label class="rd-label" for="edit-username">{{ 'profile.edit.username' | transloco }}</label>
            <div class="rd-field-group" dir="ltr" [class.is-invalid]="!!usernameError()">
              <span class="rd-field-addon cursor-default border-0 border-e border-solid border-border" aria-hidden="true"><svg lucideIcon="AtSign" [size]="16"></svg></span>
              <input
                id="edit-username"
                class="rd-field-input"
                formControlName="username"
                dir="ltr"
                autocapitalize="off"
                autocorrect="off"
                spellcheck="false"
                autocomplete="username"
                maxlength="30"
                [attr.aria-invalid]="!!usernameError() || null"
                aria-describedby="edit-username-status"
                (input)="cleanUsername($event)"
              />
              <span class="grid w-10 place-items-center" aria-hidden="true">
                @switch (usernameStatus()) {
                  @case ('checking') {
                    <svg lucideIcon="LoaderCircle" [size]="16" class="animate-spin text-text-secondary"></svg>
                  }
                  @case ('available') {
                    <svg lucideIcon="CircleCheck" [size]="16" class="text-success"></svg>
                  }
                  @case ('taken') {
                    <svg lucideIcon="CircleX" [size]="16" class="text-error"></svg>
                  }
                  @case ('invalid') {
                    <svg lucideIcon="CircleX" [size]="16" class="text-error"></svg>
                  }
                }
              </span>
            </div>
            <p
              id="edit-username-status"
              class="m-0 mt-1 text-xs"
              [class]="usernameError() ? 'text-error' : usernameStatus() === 'available' && usernameChanged() ? 'text-success' : 'text-text-secondary'"
              aria-live="polite"
              data-username-status
            >
              {{ usernameMessage() | transloco }}
            </p>
          </div>

          <!-- Title (F14): optional, one line -->
          <rd-headline-field [control]="form.controls.headline" inputId="edit-headline" [error]="errorFor('headline')" />

          <!-- Bio -->
          <div>
            <label class="rd-label" for="edit-bio">{{ 'profile.edit.bio' | transloco }}</label>
            <textarea
              id="edit-bio"
              class="rd-input py-2 leading-relaxed"
              formControlName="bio"
              dir="auto"
              rows="4"
              [placeholder]="'profile.edit.bioPlaceholder' | transloco"
              [attr.aria-invalid]="!!errorFor('bio') || null"
              aria-describedby="edit-bio-count"
            ></textarea>
            <div class="mt-1 flex items-start justify-between gap-3">
              @if (errorFor('bio'); as key) {
                <p class="rd-field-error m-0" data-field-error="bio">{{ key | transloco: { max: maxBio } }}</p>
              } @else {
                <span></span>
              }
              <span id="edit-bio-count" class="shrink-0 text-xs" [class]="bioLength() > maxBio ? 'font-semibold text-error' : 'text-text-secondary'" dir="ltr" data-bio-count>
                {{ 'profile.edit.bioCount' | transloco: { count: bioLength(), max: maxBio } }}
              </span>
            </div>
          </div>

          <!-- Links (F14): up to 8, in the member's order -->
          <rd-links-editor [(rows)]="links" [errors]="linkErrors()" [disabled]="busy()" />

          <!-- Expertise -->
          <div>
            <h2 id="edit-expertise-title" class="rd-label m-0 mb-2">{{ 'profile.edit.expertise' | transloco }}</h2>
            @switch (fieldsStatus()) {
              @case ('error') {
                <div class="flex flex-wrap items-center gap-3 rounded-md bg-callout-danger p-3 text-sm" role="alert">
                  <span class="flex-1">{{ 'profile.edit.fieldsError' | transloco }}</span>
                  <button type="button" class="rd-btn rd-btn-outline min-h-11 px-3 text-sm" (click)="loadFields()">{{ 'common.retry' | transloco }}</button>
                </div>
              }
              @case ('ready') {
                <rd-expertise-picker [fields]="fields()" [selected]="pickedExpertise()" labelledBy="edit-expertise-title" (selectedChange)="setExpertise($event)" />
              }
              @default {
                <div class="flex flex-wrap gap-2" aria-busy="true">
                  @for (i of [1, 2, 3, 4]; track i) {
                    <div class="rd-skeleton h-11 w-24 rounded-chip"></div>
                  }
                </div>
              }
            }
            @if (errorFor('expertise'); as key) {
              <p class="rd-field-error" data-field-error="expertise">{{ key | transloco }}</p>
            }
          </div>

          @if (generalError(); as message) {
            <p class="rd-alert rd-alert-error" role="alert" data-error>{{ message }}</p>
          }

          <div class="flex flex-wrap items-center justify-end gap-2 border-t border-border pt-4">
            <a [routerLink]="profileLink()" class="rd-btn rd-btn-ghost">{{ 'common.cancel' | transloco }}</a>
            <button type="submit" class="rd-btn rd-btn-primary min-w-36" [disabled]="uploading()" [attr.aria-busy]="busy() || null" data-submit>
              @if (busy()) {
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
                {{ 'common.saving' | transloco }}
              } @else {
                {{ 'profile.edit.save' | transloco }}
              }
            </button>
          </div>
        </form>
      }
      @default {
        <div class="flex flex-col gap-5" aria-busy="true" data-edit-loading>
          <div class="rd-skeleton h-28 w-full rounded-card"></div>
          @for (i of [1, 2, 3]; track i) {
            <div class="flex flex-col gap-2"><div class="rd-skeleton h-3 w-24"></div><div class="rd-skeleton h-11 w-full"></div></div>
          }
        </div>
      }
    }
  `,
})
export class EditProfilePage {
  private readonly profiles = inject(ProfilesApi);
  private readonly meApi = inject(MeApi);
  private readonly media = inject(MediaApi);
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly compressor = inject(ImageCompressor);
  private readonly auth = inject(AuthService);
  private readonly session = inject(SessionStore);
  private readonly router = inject(Router);
  private readonly errors = inject(ErrorMessages);
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly document = inject(DOCUMENT);
  private readonly injector = inject(Injector);
  private readonly fileInput = viewChild<ElementRef<HTMLInputElement>>('fileInput');

  protected readonly icons = PROFILE_ICONS;
  protected readonly maxBio = MAX_BIO;
  protected readonly avatarTypes = AVATAR_TYPES;

  protected readonly status = signal<'loading' | 'ready' | 'error'>('loading');
  protected readonly fieldsStatus = signal<'loading' | 'ready' | 'error'>('loading');
  protected readonly fields = signal<FieldDto[]>([]);
  private readonly expertise = signal<string[]>([]);
  /** The picked fields that are still offered: a field turned off since is neither shown, counted nor sent. */
  protected readonly pickedExpertise = computed(() => {
    const offered = new Set(this.fields().map((f) => f.id));
    return this.expertise().filter((id) => offered.has(id));
  });
  private original: ProfileDto | null = null;

  protected readonly form = inject(FormBuilder).nonNullable.group({
    displayName: [''],
    username: [''],
    headline: [''],
    bio: [''],
  });
  private readonly value = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });
  /** The social links being edited (F14), in order; sent whole on save. */
  protected readonly links = signal<LinkRow[]>([]);
  /** What the server said about the links (`links[2].url` → translation key), until they change. */
  private readonly serverLinkErrors = signal<Record<string, string>>({});
  /** The server's link errors, else (after the first submit) the local checks. */
  protected readonly linkErrors = computed<Record<string, string>>(() => {
    const server = this.serverLinkErrors();
    if (Object.keys(server).length) return server;
    return this.submitted() ? localLinkErrors(this.links()) : {};
  });

  protected readonly avatarUrl = signal<string | null>(null);
  /** undefined = unchanged; a new upload's id, or null to remove the photo. */
  private readonly avatarAssetId = signal<string | null | undefined>(undefined);
  protected readonly uploading = signal(false);
  protected readonly progress = signal(0);
  protected readonly avatarError = signal<string | null>(null);
  private upload: Subscription | null = null;

  protected readonly busy = signal(false);
  private readonly submitted = signal(false);
  private readonly serverErrors = signal<ProfileFieldErrors>({});
  protected readonly generalError = computed(() => this.serverErrors().general ?? null);

  protected readonly usernameStatus = toSignal(
    usernameStatus(this.form.controls.username.valueChanges.pipe(startWith(this.form.controls.username.value)), (u) => this.meApi.usernameAvailable(u)),
    { initialValue: 'idle' as UsernameStatus },
  );
  protected readonly usernameChanged = computed(() => this.value().username !== this.original?.username);
  protected readonly bioLength = computed(() => (this.value().bio ?? '').length);
  protected readonly initial = computed(() => ((this.value().displayName ?? '').trim()[0] ?? '?').toUpperCase());
  protected readonly profileLink = computed(() => `/@${this.session.username() ?? ''}`);

  /** Client-side checks, shown after the first submit; the server's errors win until the next edit. */
  private readonly localErrors = computed<ProfileFieldErrors>(() => {
    const v = this.value();
    const errors: ProfileFieldErrors = {};
    const name = v.displayName?.trim() ?? '';
    if (name.length < 2 || name.length > 60) errors.displayName = 'profile.edit.displayNameError';
    const headline = headlineProblem(v.headline);
    if (headline) errors.headline = `errors.${headline}`;
    if ((v.bio ?? '').length > MAX_BIO) errors.bio = 'profile.edit.bioTooLong';
    if (this.pickedExpertise().length > MAX_EXPERTISE) errors.expertise = 'errors.profile.expertise_invalid';
    return errors;
  });
  protected readonly usernameError = computed(() => {
    const server = this.serverErrors().username;
    if (server) return server;
    const status = this.usernameStatus();
    if (status === 'taken') return 'errors.user.username_taken';
    if (status === 'invalid') return 'errors.user.username_invalid';
    if (this.submitted() && status === 'idle') return 'auth.validation.usernameRequired';
    return null;
  });
  protected readonly usernameMessage = computed(() => {
    const error = this.usernameError();
    if (error) return error;
    switch (this.usernameStatus()) {
      case 'checking':
        return 'auth.completeProfile.checking';
      case 'available':
        return this.usernameChanged() ? 'auth.completeProfile.available' : 'auth.completeProfile.usernameHint';
      case 'error':
        return 'auth.completeProfile.checkFailed';
      default:
        return 'auth.completeProfile.usernameHint';
    }
  });

  constructor() {
    inject(Title).setTitle(`${this.transloco.translate('profile.edit.title')} — ReadIn`);
    // Editing a field clears what the server said about the form; any change to the links (an index can move) clears
    // what it said about them.
    this.form.valueChanges.pipe(takeUntilDestroyed()).subscribe(() => this.serverErrors.set({}));
    effect(() => {
      this.links();
      untracked(() => this.serverLinkErrors.set({}));
    });
    inject(DestroyRef).onDestroy(() => this.upload?.unsubscribe());
    void this.load();
    void this.loadFields();
  }

  /** Translation key of the error to show on `field`, if any. */
  protected errorFor(field: Exclude<ProfileField, 'username' | 'avatar'>): string | null {
    const server = this.serverErrors()[field];
    if (server) return server;
    return this.submitted() ? (this.localErrors()[field] ?? null) : null;
  }

  /** Your profile as the public sees it: the form starts from it (it also has your fields of expertise). */
  protected async load(): Promise<void> {
    const username = this.session.username();
    if (!username) return;
    this.status.set('loading');
    try {
      const profile = await firstValueFrom(this.profiles.profile(username));
      this.original = profile;
      this.form.reset({
        displayName: profile.displayName,
        username: profile.username,
        headline: profile.headline ?? '',
        bio: profile.bio ?? '',
      });
      this.links.set(linkRows(profileLinksOf(profile.links)));
      this.expertise.set(profile.expertise.map((f) => f.id));
      this.avatarUrl.set(profile.avatarUrl);
      this.avatarAssetId.set(undefined);
      this.status.set('ready');
    } catch {
      this.status.set('error');
    }
  }

  protected async loadFields(): Promise<void> {
    this.fieldsStatus.set('loading');
    try {
      this.fields.set(await firstValueFrom(this.taxonomy.fields()));
      this.fieldsStatus.set('ready');
    } catch {
      this.fieldsStatus.set('error');
    }
  }

  protected setExpertise(ids: string[]): void {
    this.expertise.set(ids);
    this.clearServerError('expertise');
  }

  /** Keeps the handle to `[a-z0-9_]` while typing. */
  protected cleanUsername(event: Event): void {
    const element = event.target as HTMLInputElement;
    const clean = normalizeUsername(element.value);
    if (clean !== element.value) {
      element.value = clean;
      this.form.controls.username.setValue(clean);
    }
  }

  protected async pickAvatar(event: Event): Promise<void> {
    const element = event.target as HTMLInputElement;
    const file = element.files?.[0];
    element.value = '';
    if (!file) return;
    this.avatarError.set(null);
    this.uploading.set(true);
    this.progress.set(0);
    try {
      const blob = await this.compressor.compress(file);
      this.upload?.unsubscribe();
      this.upload = this.media.uploadImage(blob, file.name, 'avatar').subscribe({
        next: (httpEvent) => {
          if (httpEvent.type === HttpEventType.UploadProgress && httpEvent.total) {
            this.progress.set(Math.round((100 * httpEvent.loaded) / httpEvent.total));
          } else if (httpEvent.type === HttpEventType.Response && httpEvent.body) {
            this.avatarUrl.set(avatarUrlOf(httpEvent.body));
            this.avatarAssetId.set(httpEvent.body.id);
            this.clearServerError('avatar');
            this.uploading.set(false);
          }
        },
        error: (error: unknown) => {
          this.avatarError.set(this.errors.forError(error));
          this.uploading.set(false);
        },
      });
    } catch (error) {
      this.avatarError.set(this.errors.forError(error));
      this.uploading.set(false);
    }
  }

  protected removeAvatar(): void {
    this.avatarUrl.set(null);
    this.avatarAssetId.set(null);
    this.avatarError.set(null);
    const input = this.fileInput()?.nativeElement;
    if (input) input.value = '';
  }

  protected async save(): Promise<void> {
    if (this.busy() || this.uploading() || !this.original) return;
    this.submitted.set(true);
    // A link typed without a scheme is shown (and sent) with https://.
    if (this.links().some((row) => normalizeLinkUrl(row.url) !== row.url)) {
      this.links.update((rows) => rows.map((row) => ({ ...row, url: normalizeLinkUrl(row.url) })));
    }
    const status = this.usernameStatus();
    const local = this.localErrors();
    const linkErrors = localLinkErrors(this.links());
    if (Object.keys(local).length || Object.keys(linkErrors).length || this.usernameError() || status === 'checking') {
      if (Object.keys(local).length || !Object.keys(linkErrors).length) this.focusFirstError(Object.keys(local)[0] as ProfileField | undefined);
      else this.focusFirstLinkError(linkErrors);
      return;
    }

    const v = this.form.getRawValue();
    const assetId = this.avatarAssetId();
    const body: UpdateProfileRequest = {
      displayName: v.displayName.trim(),
      username: v.username.trim(),
      // Blank clears the title.
      headline: normalizeHeadline(v.headline),
      bio: v.bio.trim() || null,
      // The whole list, in order ([] removes them all).
      links: toLinkInputs(this.links()),
      // Left out while the fields couldn't load (the picker wasn't shown): the server keeps them.
      ...(this.fieldsStatus() === 'ready' ? { expertiseFieldIds: this.pickedExpertise() } : {}),
      // avatarAssetId: left out = keep the photo, null = remove it, an id = the new upload.
      ...(assetId !== undefined ? { avatarAssetId: assetId } : {}),
    };

    this.busy.set(true);
    try {
      await firstValueFrom(this.profiles.updateProfile(body));
      await this.auth.refreshMe();
      this.toasts.success(this.transloco.translate('profile.edit.saved'));
      await this.router.navigateByUrl(`/@${body.username}`);
    } catch (error) {
      const errors = profileFieldErrors(error, (e) => this.errors.forError(e));
      const linkErrors = linkFieldErrors(error);
      this.serverErrors.set(errors);
      this.serverLinkErrors.set(linkErrors);
      if (errors.avatar) this.avatarError.set(this.transloco.translate(errors.avatar));
      const field = Object.keys(errors).find((k) => k !== 'general') as ProfileField | undefined;
      if (field || !Object.keys(linkErrors).length) this.focusFirstError(field);
      else this.focusFirstLinkError(linkErrors);
    } finally {
      this.busy.set(false);
    }
  }

  private clearServerError(field: ProfileField): void {
    this.serverErrors.update((errors) => {
      const next = { ...errors };
      delete next[field];
      return next;
    });
  }

  /** Moves the focus to the first field that needs fixing (or the username, when only it is wrong). */
  private focusFirstError(field: ProfileField | undefined): void {
    const target = field ?? (this.usernameError() ? 'username' : null);
    const id = target ? INPUT_IDS[target] : null;
    if (id) afterNextRender(() => this.document.getElementById(id)?.focus(), { injector: this.injector });
  }

  /** Moves the focus to the first link field with an error (its name for Other, else its URL), or "Add link". */
  private focusFirstLinkError(errors: Record<string, string>): void {
    const rows = this.links();
    const index = rows.findIndex((_, i) => errors[`links[${i}].label`] || errors[`links[${i}].url`] || errors[`links[${i}].platform`]);
    const row = rows[index];
    const id = row ? `link-${row.id}-${errors[`links[${index}].label`] ? 'label' : 'url'}` : 'link-add';
    afterNextRender(() => this.document.getElementById(id)?.focus(), { injector: this.injector });
  }
}
