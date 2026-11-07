import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { firstValueFrom } from 'rxjs';
import { AdminApi } from '../../../core/api/admin.api';
import { isApiError } from '../../../core/api/api.config';
import { AnnouncementPreviewDto, AnnouncementRequest, AnnouncementsDto, ArticleLanguage, FieldDto, PathCardDto } from '../../../core/api/models';
import { PathsApi } from '../../../core/api/paths.api';
import { TaxonomyApi } from '../../../core/api/taxonomy.api';
import { ErrorMessages } from '../../../core/i18n/error-messages';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { LocalizedDatePipe, RelativeTimePipe } from '../../../shared/pipes/format.pipes';
import { translatePlural } from '../../../shared/pipes/intl';
import { EmptyState, ErrorState } from '../../../shared/ui/states';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { ADMIN_CARD, AdminConfirm, AdminPageHeader } from '../admin-ui';
import { ArticlePicker, PickedArticle } from '../paths/article-picker';
import { provideAdminIcons } from '../admin-icons';

export const ANNOUNCEMENT_TITLE_MAX = 60;
export const ANNOUNCEMENT_BODY_MAX = 180;

export interface AnnouncementForm {
  titleAr: string;
  titleEn: string;
  bodyAr: string;
  bodyEn: string;
  audience: 'all' | 'field' | 'language';
  fieldId: string;
  language: ArticleLanguage;
  linkType: 'none' | 'article' | 'path';
  article: PickedArticle | null;
  pathId: string;
}

const EMPTY: AnnouncementForm = {
  titleAr: '',
  titleEn: '',
  bodyAr: '',
  bodyEn: '',
  audience: 'all',
  fieldId: '',
  language: 'ar-EG',
  linkType: 'none',
  article: null,
  pathId: '',
};

/** The request the form describes, or null while it is incomplete (contract: titles 1–60, bodies 1–180, all four). */
export function announcementRequest(f: AnnouncementForm): AnnouncementRequest | null {
  const texts = { titleAr: f.titleAr.trim(), titleEn: f.titleEn.trim(), bodyAr: f.bodyAr.trim(), bodyEn: f.bodyEn.trim() };
  if (!texts.titleAr || !texts.titleEn || !texts.bodyAr || !texts.bodyEn) return null;
  if (texts.titleAr.length > ANNOUNCEMENT_TITLE_MAX || texts.titleEn.length > ANNOUNCEMENT_TITLE_MAX) return null;
  if (texts.bodyAr.length > ANNOUNCEMENT_BODY_MAX || texts.bodyEn.length > ANNOUNCEMENT_BODY_MAX) return null;
  let audience: AnnouncementRequest['audience'];
  if (f.audience === 'field') {
    if (!f.fieldId) return null;
    audience = { type: 'field', fieldId: f.fieldId };
  } else if (f.audience === 'language') audience = { type: 'language', language: f.language };
  else audience = { type: 'all' };
  let link: AnnouncementRequest['link'] = null;
  if (f.linkType === 'article') {
    if (!f.article) return null;
    link = { type: 'article', id: f.article.id };
  } else if (f.linkType === 'path') {
    if (!f.pathId) return null;
    link = { type: 'path', id: f.pathId };
  }
  return { ...texts, link, audience };
}

/**
 * Announcements (F23, `notifications.broadcast`, web only), `/admin/announcements`: a push and an in-app notification to
 * everyone, the readers of one field or one article language; a title (≤ 60) and body (≤ 180) in both languages and an
 * optional link to an article or a path. Preview it (who it reaches now), send a test to yourself, then send it after a
 * dialog that shows the number of recipients. One a day; the latest 50 are listed below.
 */
@Component({
  selector: 'rd-admin-announcements-page',
  imports: [TranslocoPipe, LucideDynamicIcon, BdiText, LocalizedDatePipe, RelativeTimePipe, EmptyState, ErrorState, AdminConfirm, AdminPageHeader, ArticlePicker],
  providers: [provideAdminIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col gap-2', 'data-admin-announcements': '' },
  template: `
    <rd-admin-page-header [title]="'admin.nav.announcements' | transloco" [subtitle]="'admin.announcements.subtitle' | transloco" />

    @if (data(); as d) {
      @if (!d.canSend) {
        <p class="rd-alert rd-alert-info m-0" role="status" data-announcement-limit>
          {{ 'admin.announcements.limit' | transloco }}
          @if (d.nextAllowedAt; as next) {
            {{ 'admin.announcements.nextAt' | transloco: { time: (next | rdRelativeTime: lang()) } }}
          }
        </p>
      }
    }

    <form [class]="card + ' flex flex-col gap-4 p-4 lg:p-5'" (submit)="$event.preventDefault()" data-announcement-form>
      <h2 class="m-0 text-base font-semibold">{{ 'admin.announcements.new' | transloco }}</h2>
      <div class="grid gap-4 md:grid-cols-2">
        <fieldset class="m-0 flex flex-col gap-2 border-0 p-0" lang="ar" dir="rtl">
          <legend class="rd-label p-0">{{ 'admin.announcements.arabic' | transloco }}</legend>
          <label for="ann-title-ar" class="sr-only">{{ 'admin.announcements.titleAr' | transloco }}</label>
          <input id="ann-title-ar" class="rd-input" [attr.maxlength]="titleMax" [value]="form().titleAr" [placeholder]="'admin.announcements.titleAr' | transloco" (input)="patch({ titleAr: $any($event.target).value })" data-ann-title-ar />
          <span class="text-xs text-text-secondary tabular-nums" dir="ltr">{{ form().titleAr.length }}/{{ titleMax }}</span>
          <label for="ann-body-ar" class="sr-only">{{ 'admin.announcements.bodyAr' | transloco }}</label>
          <textarea id="ann-body-ar" class="rd-input" rows="3" [attr.maxlength]="bodyMax" [value]="form().bodyAr" [placeholder]="'admin.announcements.bodyAr' | transloco" (input)="patch({ bodyAr: $any($event.target).value })" data-ann-body-ar></textarea>
          <span class="text-xs text-text-secondary tabular-nums" dir="ltr">{{ form().bodyAr.length }}/{{ bodyMax }}</span>
        </fieldset>
        <fieldset class="m-0 flex flex-col gap-2 border-0 p-0" lang="en" dir="ltr">
          <legend class="rd-label p-0">{{ 'admin.announcements.english' | transloco }}</legend>
          <label for="ann-title-en" class="sr-only">{{ 'admin.announcements.titleEn' | transloco }}</label>
          <input id="ann-title-en" class="rd-input" [attr.maxlength]="titleMax" [value]="form().titleEn" [placeholder]="'admin.announcements.titleEn' | transloco" (input)="patch({ titleEn: $any($event.target).value })" data-ann-title-en />
          <span class="text-xs text-text-secondary tabular-nums">{{ form().titleEn.length }}/{{ titleMax }}</span>
          <label for="ann-body-en" class="sr-only">{{ 'admin.announcements.bodyEn' | transloco }}</label>
          <textarea id="ann-body-en" class="rd-input" rows="3" [attr.maxlength]="bodyMax" [value]="form().bodyEn" [placeholder]="'admin.announcements.bodyEn' | transloco" (input)="patch({ bodyEn: $any($event.target).value })" data-ann-body-en></textarea>
          <span class="text-xs text-text-secondary tabular-nums">{{ form().bodyEn.length }}/{{ bodyMax }}</span>
        </fieldset>
      </div>

      <fieldset class="m-0 flex flex-col gap-2 border-0 p-0" data-ann-audience>
        <legend class="rd-label p-0">{{ 'admin.announcements.audience' | transloco }}</legend>
        <div class="flex flex-wrap items-center gap-3 text-sm">
          @for (a of audiences; track a) {
            <label class="flex min-h-10 items-center gap-2">
              <input type="radio" name="ann-audience" class="h-4 w-4" [checked]="form().audience === a" (change)="patch({ audience: a })" [attr.data-audience]="a" />
              {{ 'admin.announcements.audiences.' + a | transloco }}
            </label>
          }
        </div>
        @if (form().audience === 'field') {
          <label for="ann-field" class="sr-only">{{ 'admin.content.field' | transloco }}</label>
          <select id="ann-field" class="rd-input" [value]="form().fieldId" (change)="patch({ fieldId: $any($event.target).value })" data-ann-field>
            <option value="" disabled>{{ 'admin.paths.pickField' | transloco }}</option>
            @for (f of fields(); track f.id) {
              <option [value]="f.id">{{ lang() === 'ar' ? f.nameAr : f.nameEn }}</option>
            }
          </select>
        }
        @if (form().audience === 'language') {
          <label for="ann-language" class="sr-only">{{ 'admin.announcements.audiences.language' | transloco }}</label>
          <select id="ann-language" class="rd-input" [value]="form().language" (change)="patch({ language: $any($event.target).value })" data-ann-language>
            <option value="ar-EG">العربية</option>
            <option value="en">English</option>
          </select>
        }
      </fieldset>

      <fieldset class="m-0 flex flex-col gap-2 border-0 p-0" data-ann-link>
        <legend class="rd-label p-0">{{ 'admin.announcements.link' | transloco }}</legend>
        <div class="flex flex-wrap items-center gap-3 text-sm">
          @for (l of linkTypes; track l) {
            <label class="flex min-h-10 items-center gap-2">
              <input type="radio" name="ann-link" class="h-4 w-4" [checked]="form().linkType === l" (change)="patch({ linkType: l })" [attr.data-link-type]="l" />
              {{ 'admin.announcements.links.' + l | transloco }}
            </label>
          }
        </div>
        @if (form().linkType === 'article') {
          @if (form().article; as article) {
            <p class="m-0 flex items-center gap-2 rounded-md bg-surface-variant p-2 text-sm" data-ann-article>
              <span class="min-w-0 flex-1 truncate" [attr.lang]="article.language"><rd-bdi-text [text]="article.title ?? article.id" /></span>
              <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-2 text-xs" (click)="patch({ article: null })">{{ 'admin.change' | transloco }}</button>
            </p>
          } @else {
            <rd-admin-article-picker inputId="ann-article" (picked)="patch({ article: $event })" />
          }
        }
        @if (form().linkType === 'path') {
          <label for="ann-path" class="sr-only">{{ 'admin.announcements.links.path' | transloco }}</label>
          <select id="ann-path" class="rd-input" [value]="form().pathId" (change)="patch({ pathId: $any($event.target).value })" data-ann-path>
            <option value="" disabled>{{ 'admin.announcements.pickPath' | transloco }}</option>
            @for (p of paths(); track p.id) {
              <option [value]="p.id">{{ p.title }}</option>
            }
          </select>
        }
      </fieldset>

      @if (preview(); as p) {
        <!-- What readers will see, in both languages -->
        <div class="grid gap-2 md:grid-cols-2" data-ann-preview>
          @for (lang of ['ar', 'en']; track lang) {
            <div class="flex gap-3 rounded-md border border-border p-3" [attr.lang]="lang" [attr.dir]="lang === 'ar' ? 'rtl' : 'ltr'">
              <span class="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-primary-container text-on-primary-container" aria-hidden="true">
                <svg lucideIcon="Megaphone" [size]="18"></svg>
              </span>
              <span class="min-w-0 text-sm">
                <span class="block font-semibold">{{ lang === 'ar' ? form().titleAr : form().titleEn }}</span>
                <span class="block text-text-secondary">{{ lang === 'ar' ? form().bodyAr : form().bodyEn }}</span>
              </span>
            </div>
          }
          <p class="m-0 text-sm md:col-span-2" data-ann-reach>{{ reachLabel(p) }}</p>
        </div>
      }

      @if (error()) {
        <p class="rd-alert rd-alert-error m-0" role="alert" data-ann-error>{{ error() }}</p>
      }

      <div class="flex flex-wrap gap-2">
        <button type="button" class="rd-btn rd-btn-outline min-h-11 px-4" [disabled]="!request() || busy()" (click)="runPreview()" data-ann-preview-button>
          <svg lucideIcon="Eye" [size]="16" aria-hidden="true"></svg>
          {{ 'admin.announcements.preview' | transloco }}
        </button>
        <button type="button" class="rd-btn rd-btn-outline min-h-11 px-4" [disabled]="!request() || busy()" (click)="sendTest()" data-ann-test>
          <svg lucideIcon="Bell" [size]="16" aria-hidden="true"></svg>
          {{ 'admin.announcements.test' | transloco }}
        </button>
        <button type="button" class="rd-btn rd-btn-primary min-h-11 px-4" [disabled]="!canSend() || busy()" (click)="confirming.set(true)" data-ann-send>
          <svg lucideIcon="Send" [size]="16" aria-hidden="true"></svg>
          {{ 'admin.announcements.send' | transloco }}
        </button>
      </div>
      @if (request() && !previewed()) {
        <p class="m-0 text-xs text-text-secondary">{{ 'admin.announcements.previewFirst' | transloco }}</p>
      }
    </form>

    <!-- The latest 50 -->
    <section [class]="card" aria-labelledby="ann-history">
      <h2 id="ann-history" class="m-0 px-4 pb-2 pt-4 text-base font-semibold">{{ 'admin.announcements.history' | transloco }}</h2>
      @switch (status()) {
        @case ('error') {
          <rd-error-state [message]="'admin.loadError' | transloco" (retry)="load()" />
        }
        @case ('loaded') {
          @if (data()?.items?.length) {
            <ol class="m-0 list-none divide-y divide-border p-0" data-ann-list>
              @for (a of data()!.items; track a.id) {
                <li class="px-4 py-3 text-sm" [attr.data-announcement]="a.id">
                  <p class="m-0 font-semibold" dir="auto">{{ lang() === 'ar' ? a.titleAr : a.titleEn }}</p>
                  <p class="m-0 text-text-secondary" dir="auto">{{ lang() === 'ar' ? a.bodyAr : a.bodyEn }}</p>
                  <p class="m-0 mt-1 flex flex-wrap items-center gap-1.5 text-xs text-text-secondary">
                    <span class="rd-tag" [class]="a.status === 'sent' ? 'rd-tag-neutral' : 'rd-tag-accent'">{{ 'admin.announcements.statuses.' + a.status | transloco }}</span>
                    {{ recipientsLabel(a.recipientCount) }} ·
                    @switch (a.audience.type) {
                      @case ('field') {
                        {{ 'admin.announcements.toField' | transloco: { name: a.audience.field?.name ?? '' } }}
                      }
                      @case ('language') {
                        {{ 'admin.announcements.toLanguage' | transloco: { language: a.audience.language === 'en' ? 'English' : 'العربية' } }}
                      }
                      @default {
                        {{ 'admin.announcements.audiences.all' | transloco }}
                      }
                    }
                    @if (a.link; as link) {
                      · <bdi dir="auto">{{ link.title }}</bdi>
                    }
                    · <time [attr.datetime]="a.createdAt" [title]="a.createdAt | rdDate: lang() : 'long'">{{ a.createdAt | rdRelativeTime: lang() }}</time>
                    @if (a.sentBy; as by) {
                      · <bdi dir="ltr">&#64;{{ by.username }}</bdi>
                    }
                  </p>
                </li>
              }
            </ol>
          } @else {
            <rd-empty-state [title]="'admin.announcements.empty' | transloco" />
          }
        }
        @default {
          <div class="flex flex-col gap-3 p-4" aria-busy="true">
            <div class="rd-skeleton h-12 w-full" aria-hidden="true"></div>
          </div>
        }
      }
    </section>

    <rd-admin-confirm
      [open]="confirming()"
      [title]="'admin.announcements.confirmTitle' | transloco"
      [body]="confirmBody()"
      [busy]="busy()"
      [error]="error()"
      (confirmed)="send()"
      (closed)="confirming.set(false)"
    />
  `,
})
export class AdminAnnouncementsPage {
  private readonly api = inject(AdminApi);
  private readonly taxonomy = inject(TaxonomyApi);
  private readonly pathsApi = inject(PathsApi);
  private readonly toasts = inject(ToastService);
  private readonly errors = inject(ErrorMessages);
  private readonly transloco = inject(TranslocoService);
  protected readonly lang = inject(LanguageService).lang;

  protected readonly card = ADMIN_CARD;
  protected readonly titleMax = ANNOUNCEMENT_TITLE_MAX;
  protected readonly bodyMax = ANNOUNCEMENT_BODY_MAX;
  protected readonly audiences = ['all', 'field', 'language'] as const;
  protected readonly linkTypes = ['none', 'article', 'path'] as const;

  protected readonly status = signal<'loading' | 'loaded' | 'error'>('loading');
  protected readonly data = signal<AnnouncementsDto | null>(null);
  protected readonly fields = signal<FieldDto[]>([]);
  protected readonly paths = signal<PathCardDto[]>([]);
  protected readonly form = signal<AnnouncementForm>({ ...EMPTY });
  protected readonly preview = signal<AnnouncementPreviewDto | null>(null);
  /** The request the preview was made for: changing the form asks for a new preview before sending. */
  private readonly previewedFor = signal<string | null>(null);
  protected readonly busy = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly confirming = signal(false);

  protected readonly request = computed(() => announcementRequest(this.form()));
  protected readonly previewed = computed(() => {
    const request = this.request();
    return !!request && this.previewedFor() === JSON.stringify(request);
  });
  protected readonly canSend = computed(() => this.previewed() && !!this.preview()?.canSend && (this.preview()?.recipientCount ?? 0) > 0);
  protected readonly confirmBody = computed(() => {
    const p = this.preview();
    return p ? this.reachLabel(p) : '';
  });

  constructor() {
    void this.load();
    void firstValueFrom(this.taxonomy.fields()).then(
      (fields) => this.fields.set(fields),
      () => undefined,
    );
    void firstValueFrom(this.pathsApi.list()).then(
      (paths) => this.paths.set(paths),
      () => undefined,
    );
  }

  async load(): Promise<void> {
    if (!this.data()) this.status.set('loading');
    try {
      this.data.set(await firstValueFrom(this.api.announcements()));
      this.status.set('loaded');
    } catch {
      if (!this.data()) this.status.set('error');
    }
  }

  protected patch(change: Partial<AnnouncementForm>): void {
    this.form.update((f) => ({ ...f, ...change }));
    this.error.set(null);
  }

  protected reachLabel(p: AnnouncementPreviewDto): string {
    return translatePlural(this.transloco, 'admin.announcements.reach', p.recipientCount, this.lang(), { push: p.pushCount });
  }

  protected recipientsLabel(count: number): string {
    return translatePlural(this.transloco, 'admin.announcements.recipients', count, this.lang());
  }

  protected async runPreview(): Promise<void> {
    const request = this.request();
    if (!request || this.busy()) return;
    await this.run(async () => {
      const preview = await firstValueFrom(this.api.previewAnnouncement(request));
      this.preview.set(preview);
      this.previewedFor.set(JSON.stringify(request));
    });
  }

  protected async sendTest(): Promise<void> {
    const request = this.request();
    if (!request || this.busy()) return;
    await this.run(async () => {
      await firstValueFrom(this.api.testAnnouncement(request));
      this.toasts.success(this.transloco.translate('admin.announcements.testSent'));
    });
  }

  protected async send(): Promise<void> {
    const request = this.request();
    if (!request || this.busy()) return;
    await this.run(async () => {
      await firstValueFrom(this.api.sendAnnouncement(request));
      this.toasts.success(this.transloco.translate('admin.announcements.sent'));
      this.confirming.set(false);
      this.form.set({ ...EMPTY });
      this.preview.set(null);
      this.previewedFor.set(null);
      await this.load();
    });
  }

  private async run(action: () => Promise<void>): Promise<void> {
    this.busy.set(true);
    this.error.set(null);
    try {
      await action();
    } catch (error) {
      this.error.set(this.message(error));
    } finally {
      this.busy.set(false);
    }
  }

  private message(error: unknown): string {
    if (isApiError(error) && error.code === 'validation.failed') {
      const first = Object.values(error.validationErrors).flat()[0];
      if (first) return this.errors.forCode(first);
    }
    return this.errors.forError(error);
  }
}
