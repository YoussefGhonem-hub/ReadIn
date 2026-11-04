import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoService } from '@jsverse/transloco';
import { environment } from '../../../environments/environment';
import { ArticleLanguage } from '../../core/api/models';
import { urlLangFor } from '../ui/article-link';
import { ToastService } from '../ui/toast/toast.service';

/** The web's canonical URL of an article version, `{siteUrl}/{ar|en}/a/{slug}` (F24). */
export function articleShareUrl(article: { slug: string; language: ArticleLanguage }): string {
  return `${environment.siteUrl}/${urlLangFor(article.language)}/a/${encodeURIComponent(article.slug)}`;
}

/** Share an article link (F24 basics): the Web Share API when available, otherwise copy the link with a toast. */
@Injectable({ providedIn: 'root' })
export class ShareService {
  private readonly toasts = inject(ToastService);
  private readonly transloco = inject(TranslocoService);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  async share(data: { title: string; url: string }): Promise<void> {
    if (!this.isBrowser) return;
    try {
      if (navigator.share) {
        await navigator.share(data);
        return;
      }
      await navigator.clipboard.writeText(data.url);
      this.toasts.success(this.transloco.translate('common.linkCopied'));
    } catch {
      /* share sheet dismissed */
    }
  }
}
