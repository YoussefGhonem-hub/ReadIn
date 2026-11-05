import { ChangeDetectionStrategy, Component } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { environment } from '../../../environments/environment';

/**
 * Home's footer links: the public pages next to the account deletion page, and the support email. They sit under the
 * end column's cards, or under the start column's when the end column has none (it never stands alone at the top).
 */
@Component({
  selector: 'rd-home-footer',
  imports: [TranslocoPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'block px-2 py-3 text-center text-xs text-text-secondary' },
  template: `
    <nav [attr.aria-label]="'home.footer.label' | transloco" data-home-footer>
      <ul class="m-0 flex list-none flex-wrap justify-center gap-x-3 gap-y-1 p-0">
        <li><a [href]="site + '/'" target="_blank" rel="noopener" class="text-text-secondary no-underline hover:underline">{{ 'home.footer.about' | transloco }}</a></li>
        <li><a [href]="site + '/privacy'" target="_blank" rel="noopener" class="text-text-secondary no-underline hover:underline">{{ 'home.footer.privacy' | transloco }}</a></li>
        <li><a [href]="site + '/terms'" target="_blank" rel="noopener" class="text-text-secondary no-underline hover:underline">{{ 'home.footer.terms' | transloco }}</a></li>
        <li><a [href]="'mailto:' + email" class="text-text-secondary no-underline hover:underline">{{ 'home.footer.help' | transloco }}</a></li>
      </ul>
    </nav>
    <p class="m-0 mt-2"><span dir="ltr">ReadIn © {{ year }}</span></p>
  `,
})
export class HomeFooter {
  /** The public pages (`public/` on Firebase Hosting) live next to the account deletion page. */
  protected readonly site = new URL(environment.accountDeletionUrl).origin;
  protected readonly email = environment.supportEmail;
  protected readonly year = new Date().getFullYear();
}
