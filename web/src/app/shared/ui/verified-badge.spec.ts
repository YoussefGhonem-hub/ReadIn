import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { translocoTesting } from '../../../testing/transloco-testing';
import { provideAppIcons } from './icons';
import { VerifiedBadge } from './verified-badge';

@Component({
  imports: [VerifiedBadge],
  template: `<h1 style="display: flex; gap: 6px">Karim Hassan <rd-verified-badge [size]="20" /></h1>`,
})
class Host {}

async function render(lang: 'ar' | 'en') {
  TestBed.resetTestingModule();
  TestBed.configureTestingModule({ imports: [translocoTesting()], providers: [provideAppIcons()] });
  TestBed.inject(TranslocoService).setActiveLang(lang);
  const fixture = TestBed.createComponent(Host);
  fixture.detectChanges();
  await fixture.whenStable();
  fixture.detectChanges();
  const root = fixture.nativeElement as HTMLElement;
  return { root, svg: root.querySelector<SVGElement>('svg[data-verified-badge]')! };
}

describe('VerifiedBadge (F19, SPEC §26)', () => {
  it('is an image named «كاتب موثّق» / "Verified writer" that screen readers announce (not aria-hidden)', async () => {
    for (const [lang, name] of [
      ['ar', 'كاتب موثّق'],
      ['en', 'Verified writer'],
    ] as const) {
      const { svg } = await render(lang);
      expect(svg.getAttribute('role')).toBe('img');
      expect(svg.getAttribute('aria-label')).toBe(name);
      // Lucide hides untitled icons; this one must stay in the accessibility tree.
      expect(svg.getAttribute('aria-hidden')).not.toBe('true');
      expect(svg.closest('[aria-hidden="true"]')).toBeNull();
    }
  });

  it('draws the check badge at the given size, with no <title> (no browser tooltip) and no box of its own', async () => {
    const { root, svg } = await render('ar');
    expect(svg.classList).toContain('lucide-badge-check');
    expect(svg.getAttribute('width')).toBe('20');
    expect(svg.getAttribute('height')).toBe('20');
    expect(svg.classList).toContain('text-primary');
    expect(svg.classList).toContain('shrink-0');
    expect(svg.querySelector('title')).toBeNull();
    expect(svg.hasAttribute('title')).toBe(false);
    expect(root.querySelector('rd-verified-badge')!.classList).toContain('contents');
  });
});
