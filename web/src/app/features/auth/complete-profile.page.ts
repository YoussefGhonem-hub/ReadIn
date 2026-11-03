import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, computed, inject, input, signal, viewChild } from '@angular/core';
import { takeUntilDestroyed, toSignal } from '@angular/core/rxjs-interop';
import { HttpEventType } from '@angular/common/http';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { Subscription, firstValueFrom, startWith } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { MeApi } from '../../core/api/me.api';
import { MediaApi } from '../../core/api/media.api';
import { postAuthUrl } from '../../core/auth/account-setup';
import { AuthService } from '../../core/auth/auth.service';
import { SessionStore } from '../../core/auth/session.store';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { AVATAR_TYPES, avatarUrlOf } from '../../shared/media/avatar-variant';
import { ImageCompressor } from '../../shared/media/image-compressor';
import { Avatar } from '../../shared/ui/avatar';
import { UsernameStatus, normalizeUsername, usernameStatus } from '../../shared/utils/username';
import { AuthCard, SubmitButton, fieldErrors } from './auth-shared';

/** Placeholder handles from sign up (`@reader_xxxxxxxxxx`) are not offered as the user's choice. */
const PLACEHOLDER_USERNAME = /^reader_[a-z0-9]{10}$/;

/**
 * Complete profile (SPEC §9.2), right after Create account: display name, a unique @username with a live
 * availability check, and an optional avatar (uploaded with `POST /uploads/images`, purpose `avatar`).
 */
@Component({
  selector: 'rd-complete-profile-page',
  imports: [ReactiveFormsModule, TranslocoPipe, LucideDynamicIcon, AuthCard, SubmitButton, Avatar],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-auth-card [title]="'auth.completeProfile.title' | transloco" [subtitle]="'auth.completeProfile.subtitle' | transloco">
      <form [formGroup]="form" (ngSubmit)="save()" class="flex flex-col gap-5" novalidate data-complete-profile>
        <div class="flex items-center gap-4">
          <rd-avatar [name]="form.controls.displayName.value || '?'" [src]="avatarUrl()" [size]="72" />
          <div class="flex min-w-0 flex-1 flex-col items-start gap-1">
            <span class="text-sm font-semibold">{{ 'auth.completeProfile.avatar' | transloco }}</span>
            <div class="flex flex-wrap gap-2">
              <button type="button" class="rd-btn rd-btn-outline min-h-9 px-3 text-sm" [disabled]="uploading() || busy()" (click)="fileInput.click()" data-avatar-pick>
                @if (uploading()) {
                  <svg lucideIcon="LoaderCircle" [size]="16" class="animate-spin" aria-hidden="true"></svg>
                  {{ 'auth.completeProfile.avatarUploading' | transloco: { percent: progress() } }}
                } @else {
                  <svg lucideIcon="Camera" [size]="16" aria-hidden="true"></svg>
                  {{ (avatarUrl() ? 'auth.completeProfile.avatarChange' : 'auth.completeProfile.avatarAdd') | transloco }}
                }
              </button>
              @if (avatarUrl() && !uploading()) {
                <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm" (click)="removeAvatar()">{{ 'common.remove' | transloco }}</button>
              }
            </div>
            <span class="text-xs text-text-secondary">{{ 'auth.completeProfile.avatarHint' | transloco }}</span>
            @if (avatarError()) {
              <p class="rd-field-error" role="alert">{{ avatarError() }}</p>
            }
          </div>
          <input #fileInput type="file" class="hidden" [accept]="avatarTypes" (change)="pickAvatar($event)" tabindex="-1" aria-hidden="true" data-avatar-input />
        </div>

        <div>
          <label class="rd-label" for="profile-name">{{ 'auth.completeProfile.displayName' | transloco }}</label>
          <input
            id="profile-name"
            class="rd-input"
            formControlName="displayName"
            autocomplete="name"
            maxlength="60"
            dir="auto"
            [attr.aria-invalid]="!!nameError() || null"
            [attr.aria-describedby]="nameError() ? 'profile-name-error' : null"
          />
          @if (nameError()) {
            <p id="profile-name-error" class="rd-field-error">{{ nameError()! | transloco }}</p>
          }
        </div>

        <div>
          <label class="rd-label" for="profile-username">{{ 'auth.completeProfile.username' | transloco }}</label>
          <div class="rd-field-group" dir="ltr" [class.is-invalid]="!!usernameError()">
            <span class="rd-field-addon cursor-default border-0 border-e border-solid border-border" aria-hidden="true"><svg lucideIcon="AtSign" [size]="16"></svg></span>
            <input
              id="profile-username"
              class="rd-field-input"
              formControlName="username"
              dir="ltr"
              autocapitalize="off"
              autocorrect="off"
              spellcheck="false"
              autocomplete="username"
              maxlength="30"
              [placeholder]="'auth.completeProfile.usernamePlaceholder' | transloco"
              [attr.aria-invalid]="!!usernameError() || null"
              aria-describedby="profile-username-status"
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
          <p id="profile-username-status" class="m-0 mt-1 text-xs" [class]="usernameError() ? 'text-error' : usernameStatus() === 'available' ? 'text-success' : 'text-text-secondary'" aria-live="polite" data-username-status>
            {{ usernameMessage() | transloco }}
          </p>
        </div>

        @if (error()) {
          <p class="rd-alert rd-alert-error" role="alert" data-error>{{ error() }}</p>
        }
        <rd-submit-button [busy]="busy()" [disabled]="uploading()">{{ 'common.continue' | transloco }}</rd-submit-button>
      </form>
    </rd-auth-card>
  `,
})
export class CompleteProfilePage {
  private readonly auth = inject(AuthService);
  private readonly meApi = inject(MeApi);
  private readonly media = inject(MediaApi);
  private readonly compressor = inject(ImageCompressor);
  private readonly session = inject(SessionStore);
  private readonly router = inject(Router);
  private readonly errors = inject(ErrorMessages);
  private readonly destroyRef = inject(DestroyRef);
  private readonly fileInput = viewChild.required<ElementRef<HTMLInputElement>>('fileInput');

  readonly returnUrl = input<string | null>(null);

  private readonly me = this.session.me();
  protected readonly form = inject(FormBuilder).nonNullable.group({
    displayName: [this.me && !PLACEHOLDER_USERNAME.test(this.me.displayName) ? this.me.displayName : ''],
    username: [this.me && !PLACEHOLDER_USERNAME.test(this.me.username) ? this.me.username : ''],
  });
  protected readonly avatarTypes = AVATAR_TYPES;
  protected readonly avatarUrl = signal<string | null>(this.me?.avatarUrl ?? null);
  protected readonly uploading = signal(false);
  protected readonly progress = signal(0);
  protected readonly avatarError = signal<string | null>(null);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  private readonly submitted = signal(false);
  private readonly serverErrors = signal<{ displayName: string | null; username: string | null }>({ displayName: null, username: null });
  private upload: Subscription | null = null;

  private readonly value = toSignal(this.form.valueChanges, { initialValue: this.form.getRawValue() });
  protected readonly usernameStatus = toSignal(
    usernameStatus(this.form.controls.username.valueChanges.pipe(startWith(this.form.controls.username.value)), (u) => this.meApi.usernameAvailable(u)),
    { initialValue: 'idle' as UsernameStatus },
  );

  protected readonly nameError = computed(() => {
    if (this.serverErrors().displayName) return this.serverErrors().displayName;
    const name = this.value().displayName?.trim() ?? '';
    if (!this.submitted()) return null;
    return name.length < 2 || name.length > 60 ? 'auth.validation.displayName' : null;
  });
  protected readonly usernameError = computed(() => {
    if (this.serverErrors().username) return this.serverErrors().username;
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
        return 'auth.completeProfile.available';
      case 'error':
        return 'auth.completeProfile.checkFailed';
      default:
        return 'auth.completeProfile.usernameHint';
    }
  });

  constructor() {
    this.form.valueChanges.pipe(takeUntilDestroyed()).subscribe(() => {
      this.error.set(null);
      this.serverErrors.set({ displayName: null, username: null });
    });
    this.destroyRef.onDestroy(() => this.upload?.unsubscribe());
  }

  /** Keeps the handle to `[a-z0-9_]` while typing (the caret stays at the end of a short field). */
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
    this.fileInput().nativeElement.value = '';
  }

  protected async save(): Promise<void> {
    if (this.busy() || this.uploading()) return;
    this.submitted.set(true);
    const status = this.usernameStatus();
    if (this.nameError() || this.usernameError() || status === 'checking') return;

    const { displayName, username } = this.form.getRawValue();
    this.busy.set(true);
    try {
      const me = await firstValueFrom(
        this.meApi.completeProfile({ displayName: displayName.trim(), username: username.trim(), avatarUrl: this.avatarUrl() }),
      );
      this.auth.updateMe(me);
      await this.router.navigateByUrl(postAuthUrl(me, this.returnUrl()));
    } catch (error) {
      if (isApiError(error) && (error.code === 'user.username_taken' || error.code === 'user.username_invalid')) {
        this.serverErrors.set({ displayName: null, username: `errors.${error.code}` });
        return;
      }
      const name = fieldErrors(error, 'displayName');
      const handle = fieldErrors(error, 'username');
      if (name.length || handle.length) {
        this.serverErrors.set({
          displayName: name.length ? 'auth.validation.displayName' : null,
          username: handle.length ? `errors.${handle[0]}` : null,
        });
      } else if (fieldErrors(error, 'avatarUrl').length) {
        this.avatarError.set(this.errors.forCode('media.not_found'));
      } else {
        this.error.set(isApiError(error) ? this.errors.forCode(error.code) : this.errors.forError(error));
      }
    } finally {
      this.busy.set(false);
    }
  }
}
