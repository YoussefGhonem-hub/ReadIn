import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { translocoTesting } from '../../../testing/transloco-testing';
import { provideAppIcons } from '../../shared/ui/icons';
import { LinkRow, LinksEditor, linkRows } from './links-editor';

@Component({
  imports: [LinksEditor],
  template: `<rd-links-editor [(rows)]="rows" [errors]="errors()" />`,
})
class Host {
  readonly rows = signal<LinkRow[]>([]);
  readonly errors = signal<Record<string, string>>({});
}

/** The Links section of Edit profile (F14): add from the picker, edit, reorder and remove, keyboard first. */
describe('LinksEditor (F14)', () => {
  async function render(rows: LinkRow[] = [], lang: 'ar' | 'en' = 'ar') {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ imports: [translocoTesting()], providers: [provideAppIcons()] });
    TestBed.inject(TranslocoService).setActiveLang(lang);
    const fixture = TestBed.createComponent(Host);
    fixture.componentInstance.rows.set(rows);
    fixture.autoDetectChanges();
    await fixture.whenStable();
    const root = fixture.nativeElement as HTMLElement;
    const host = fixture.componentInstance;
    const stable = async () => {
      fixture.detectChanges();
      await fixture.whenStable();
    };
    const rowEls = () => [...root.querySelectorAll<HTMLElement>('[data-link-row]')];
    return { fixture, root, host, stable, rowEls };
  }

  it('adds a link: + Add link opens the platform picker, the pick adds a row and focuses its field', async () => {
    const { root, host, stable, rowEls } = await render(linkRows([{ platform: 'github', url: 'https://github.com/mona' }]));
    const add = root.querySelector<HTMLButtonElement>('[data-add-link]')!;
    expect(add.textContent).toContain('إضافة رابط');
    add.click();
    await stable();
    const picker = root.querySelector('[data-link-picker]')!;
    expect(picker.getAttribute('role')).toBe('group');
    expect([...picker.querySelectorAll('[data-pick-platform]')].map((b) => b.getAttribute('data-pick-platform'))).toHaveLength(14);
    // One link per named platform: GitHub is taken; Other can always be added.
    expect(picker.querySelector<HTMLButtonElement>('[data-pick-platform="github"]')!.disabled).toBe(true);
    expect(picker.querySelector<HTMLButtonElement>('[data-pick-platform="other"]')!.disabled).toBe(false);
    expect(document.activeElement).toBe(picker.querySelector('[data-pick-platform="linkedin"]'));

    picker.querySelector<HTMLButtonElement>('[data-pick-platform="instagram"]')!.click();
    await stable();
    expect(host.rows().map((r) => r.platform)).toEqual(['github', 'instagram']);
    expect(rowEls()[1].querySelector('[data-link-url]')!.getAttribute('placeholder')).toBe('https://instagram.com/you');
    expect(document.activeElement).toBe(rowEls()[1].querySelector('[data-link-url]'));
    expect(root.querySelector('[data-link-picker]')).toBeNull();

    // Typing, then leaving the field: a link without a scheme gets https://.
    const url = rowEls()[1].querySelector<HTMLInputElement>('[data-link-url]')!;
    url.value = 'instagram.com/mona';
    url.dispatchEvent(new Event('input'));
    url.dispatchEvent(new Event('blur'));
    await stable();
    expect(host.rows()[1].url).toBe('https://instagram.com/mona');
    expect(url.value).toBe('https://instagram.com/mona');
    // The URL field is always LTR, and named after its platform.
    expect(url.getAttribute('dir')).toBe('ltr');
    expect(root.querySelector(`label[for="${url.id}"]`)!.textContent).toContain('رابط Instagram');
  });

  it('Other asks for a name first; its name names the row’s buttons', async () => {
    const { root, host, stable, rowEls } = await render([], 'en');
    root.querySelector<HTMLButtonElement>('[data-add-link]')!.click();
    await stable();
    root.querySelector<HTMLButtonElement>('[data-pick-platform="other"]')!.click();
    await stable();
    const label = rowEls()[0].querySelector<HTMLInputElement>('[data-link-label]')!;
    expect(document.activeElement).toBe(label);
    expect(label.getAttribute('dir')).toBe('auto');
    expect(label.maxLength).toBe(30);
    label.value = 'My podcast';
    label.dispatchEvent(new Event('input'));
    await stable();
    expect(host.rows()[0].label).toBe('My podcast');
    expect(rowEls()[0].querySelector('[data-link-remove]')!.getAttribute('aria-label')).toBe('Remove the My podcast link');
  });

  it('moves a link up and down (the focus stays on it) and removes one', async () => {
    const rows = linkRows([
      { platform: 'github', url: 'https://github.com/mona' },
      { platform: 'x', url: 'https://x.com/mona' },
      { platform: 'website', url: 'https://mona.dev' },
    ]);
    const { host, stable, rowEls } = await render(rows, 'en');
    expect(rowEls()[0].querySelector<HTMLButtonElement>('[data-link-up]')!.disabled).toBe(true);
    expect(rowEls()[2].querySelector<HTMLButtonElement>('[data-link-down]')!.disabled).toBe(true);
    expect(rowEls()[1].querySelector('[data-link-up]')!.getAttribute('aria-label')).toBe('Move X up');

    rowEls()[2].querySelector<HTMLButtonElement>('[data-link-up]')!.click();
    await stable();
    expect(host.rows().map((r) => r.platform)).toEqual(['github', 'website', 'x']);
    expect(document.activeElement).toBe(rowEls()[1].querySelector('[data-link-up]'));

    rowEls()[1].querySelector<HTMLButtonElement>('[data-link-up]')!.click();
    await stable();
    expect(host.rows().map((r) => r.platform)).toEqual(['website', 'github', 'x']);
    // At the top, "up" is disabled: the focus moves to its "down".
    expect(document.activeElement).toBe(rowEls()[0].querySelector('[data-link-down]'));

    rowEls()[0].querySelector<HTMLButtonElement>('[data-link-remove]')!.click();
    await stable();
    expect(host.rows().map((r) => r.platform)).toEqual(['github', 'x']);
    expect(document.activeElement).toBe(rowEls()[0].querySelector('[data-link-url]'));
  });

  it('at 8 links there is no Add link, only the limit', async () => {
    const eight = linkRows(Array.from({ length: 8 }, (_, i) => ({ platform: 'other' as const, url: `https://site${i}.dev`, label: `Site ${i}` })));
    const { root } = await render(eight);
    expect(root.querySelector('[data-add-link]')).toBeNull();
    expect(root.querySelector('[data-links-full]')!.textContent).toContain('8');
  });

  it('shows each error under its own field, by index, and the list’s error under the list', async () => {
    const rows = linkRows([
      { platform: 'instagram', url: 'https://facebook.com/mona' },
      { platform: 'other', url: 'https://mona.dev', label: 'A' },
    ]);
    const { fixture, root, stable, rowEls } = await render(rows);
    fixture.componentInstance.errors.set({
      'links[0].url': 'errors.link.host_mismatch',
      'links[1].label': 'errors.link.label_invalid',
      links: 'errors.link.too_many',
    });
    await stable();
    const url = rowEls()[0].querySelector<HTMLInputElement>('[data-link-url]')!;
    expect(url.getAttribute('aria-invalid')).toBe('true');
    expect(root.querySelector(`#${url.getAttribute('aria-describedby')}`)!.textContent).toContain('الرابط ده مش على موقع المنصة اللي اخترتها.');
    expect(rowEls()[1].querySelector('[data-link-error="label"]')!.textContent).toContain('من 2 لـ 30 حرف');
    expect(rowEls()[1].querySelector('[data-link-error="url"]')).toBeNull();
    expect(root.querySelector('[data-link-error="list"]')!.textContent).toContain('8 روابط');
  });
});
