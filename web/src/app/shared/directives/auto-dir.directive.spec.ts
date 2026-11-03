import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import fixturesFile from '../../../../../shared/bidi/fixtures.json';
import { AutoDir } from './auto-dir.directive';
import { BdiText } from './bdi-text';
import { detectDir, segmentBidi } from './bidi';

/** Shared mixed Arabic/English fixtures (SPEC §14.2 rule 7) — the same file drives backend and mobile tests. */
interface BidiFixture {
  id: string;
  text: string;
  expectedDir: 'rtl' | 'ltr';
  /** Runs that must be isolated, in order (when the fixture pins them down). */
  isolated?: string[];
}
const fixtures = (fixturesFile as { fixtures: BidiFixture[] }).fixtures;

@Component({
  imports: [AutoDir],
  template: `<p [rdAutoDir]="text()">{{ text() }}</p>`,
})
class Host {
  readonly text = signal('');
}

describe('AutoDir directive', () => {
  it('has fixtures to test', () => {
    expect(fixtures.length).toBeGreaterThan(10);
  });

  for (const fixture of fixtures) {
    it(`resolves ${fixture.id} → ${fixture.expectedDir}`, async () => {
      const host = TestBed.createComponent(Host);
      host.componentInstance.text.set(fixture.text);
      await host.whenStable();
      const p = host.nativeElement.querySelector('p') as HTMLElement;
      expect(p.getAttribute('dir')).toBe(fixture.expectedDir);
    });
  }

  it('falls back to "auto" when there is no strong character', async () => {
    const host = TestBed.createComponent(Host);
    host.componentInstance.text.set('12 — 30 ☕');
    await host.whenStable();
    expect(host.nativeElement.querySelector('p').getAttribute('dir')).toBe('auto');
  });
});

@Component({
  imports: [BdiText],
  template: `<span dir="rtl"><rd-bdi-text [text]="text()" /></span>`,
})
class BdiHost {
  readonly text = signal('');
}

describe('BdiText', () => {
  it('isolates a pure-English label inside the Arabic UI so ".NET" keeps its dot', async () => {
    const host = TestBed.createComponent(BdiHost);
    host.componentInstance.text.set('.NET');
    await host.whenStable();
    const el = host.nativeElement.querySelector('rd-bdi-text') as HTMLElement;
    expect(el.getAttribute('dir')).toBe('ltr');
    expect(el.textContent).toBe('.NET');
  });

  it('wraps Latin runs of an Arabic title in <bdi>', async () => {
    const host = TestBed.createComponent(BdiHost);
    host.componentInstance.text.set('يعني إيه Dependency Injection في .NET؟');
    await host.whenStable();
    const el = host.nativeElement.querySelector('rd-bdi-text') as HTMLElement;
    expect(el.getAttribute('dir')).toBe('rtl');
    expect([...el.querySelectorAll('bdi')].map((b) => b.textContent)).toEqual(['Dependency Injection', '.NET']);
    expect(el.textContent).toBe('يعني إيه Dependency Injection في .NET؟');
  });
});

describe('detectDir', () => {
  for (const fixture of fixtures) {
    it(`${fixture.id}`, () => expect(detectDir(fixture.text)).toBe(fixture.expectedDir));
  }
});

describe('segmentBidi', () => {
  const isolated = (text: string, base: 'rtl' | 'ltr') =>
    segmentBidi(text, base)
      .filter((s) => s.isolate)
      .map((s) => s.text);

  it('isolates English terms and leaves trailing Arabic punctuation outside', () => {
    expect(isolated('يعني إيه Dependency Injection؟', 'rtl')).toEqual(['Dependency Injection']);
  });

  it('keeps a leading dot with .NET and a trailing period outside', () => {
    expect(isolated('اتعمل upgrade لـ .NET 10 و Angular 21.', 'rtl')).toEqual(['upgrade', '.NET 10', 'Angular 21']);
  });

  it('keeps balanced parentheses and generics inside code-like runs', () => {
    expect(isolated('استخدم services.AddScoped<IFoo, Foo>() هنا.', 'rtl')).toEqual(['services.AddScoped<IFoo, Foo>()']);
  });

  it('drops unbalanced closing brackets', () => {
    expect(isolated('الـ lifetime (Scoped) مهم جداً.', 'rtl')).toEqual(['lifetime (Scoped)']);
  });

  it('leaves a bracket the run opens but never closes to the Arabic text', () => {
    // Text before inline code ("الـ render (" + `Math.random()`) and a plain-text call list.
    expect(isolated('أثناء الـ render (', 'rtl')).toEqual(['render']);
    expect(isolated('الـ render (Math.random()، Date.now())، وبس', 'rtl')).toEqual(['render', 'Math.random()', 'Date.now()']);
  });

  it('isolates mentions and URLs', () => {
    expect(isolated('شكراً @youssef_dev على الشرح!', 'rtl')).toEqual(['@youssef_dev']);
    expect(isolated('شوف https://learn.microsoft.com/dotnet/ للتفاصيل.', 'rtl')).toEqual(['https://learn.microsoft.com/dotnet/']);
  });

  it('isolates Arabic runs inside English text', () => {
    expect(isolated('Use DI (الحقن) everywhere.', 'ltr')).toEqual(['الحقن']);
  });

  // Sentences from seeded articles that pin down exactly which runs are isolated (same expectation on mobile).
  for (const f of fixtures.filter((f) => f.isolated)) {
    it(`isolates the English runs of ${f.id}`, () => {
      expect(isolated(f.text, f.expectedDir)).toEqual(f.isolated);
    });
  }

  it('round-trips the original text', () => {
    for (const f of fixtures) {
      const base = detectDir(f.text) ?? 'ltr';
      expect(
        segmentBidi(f.text, base)
          .map((s) => s.text)
          .join(''),
      ).toBe(f.text);
    }
  });
});
