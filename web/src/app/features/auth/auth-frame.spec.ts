import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { setupAuthTesting } from '../../../testing/auth-testing';
import { provideAppIcons } from '../../shared/ui/icons';
import { AuthShowcase } from './auth-frame';
import { AuthCard, AuthSteps } from './auth-shared';

@Component({
  imports: [AuthCard, AuthSteps],
  template: `
    <rd-auth-card title="Sign in" subtitle="With your number">
      <rd-auth-steps rdAuthCardTop [current]="step()" />
      <form data-form><button type="submit">Go</button></form>
    </rd-auth-card>
  `,
})
class Host {
  readonly step = signal(2);
}

function stubMotion(reduce: boolean): void {
  vi.stubGlobal('matchMedia', (query: string) => ({
    matches: reduce && query.includes('reduce'),
    media: query,
    addEventListener: () => undefined,
    removeEventListener: () => undefined,
  }));
  vi.stubGlobal('requestAnimationFrame', (run: FrameRequestCallback) => {
    run(0);
    return 1;
  });
  vi.stubGlobal('cancelAnimationFrame', () => undefined);
}

function pointer(type: string, x: number, y: number, pointerType = 'mouse'): Event {
  const event = new MouseEvent(type, { clientX: x, clientY: y, bubbles: type !== 'pointerleave' });
  Object.defineProperty(event, 'pointerType', { value: pointerType });
  return event;
}

describe('Auth frame', () => {
  beforeEach(() => setupAuthTesting({ providers: [provideRouter([]), provideAppIcons()] }));
  afterEach(() => vi.unstubAllGlobals());

  it('frames the form: the wordmark to Home, the language switch, the title, and the decorative showcase', () => {
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;

    expect(root.querySelector('[data-auth-home]')!.getAttribute('href')).toBe('/');
    expect(root.querySelector('[data-auth-home]')!.getAttribute('aria-label')).toBe('الرئيسية');
    expect(root.querySelector('rd-language-switch')).not.toBeNull();
    expect(root.querySelector('main h1')!.textContent!.trim()).toBe('Sign in');
    expect(root.querySelector('main .rd-auth-body [data-form]')).not.toBeNull();

    // Screen readers skip the showcase: it only shows what the app looks like.
    const showcase = root.querySelector('[data-auth-showcase]')!;
    expect(showcase.getAttribute('aria-hidden')).toBe('true');
    expect(showcase.querySelector('a, button, input, [tabindex]')).toBeNull();
    expect(showcase.textContent).toContain('مقال جديد كل صباح');
    expect(showcase.textContent).toContain('تعلّم كل يوم شيئًا جديدًا في');
    // The headline cycles through the topics and ends where it began.
    const topics = [...showcase.querySelectorAll('.rd-sc-words > span')].map((s) => s.textContent!.trim());
    expect(topics).toEqual(['التقنية', 'الطب', 'الأعمال', 'علم النفس', 'التقنية']);
  });

  it('fills the steps done so far; the step you just reached grows in', () => {
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const fills = () => [...root.querySelectorAll('rd-auth-steps [aria-hidden] > span > span')].map((s) => s.classList.contains('rd-auth-step-on'));
    expect(fills()).toEqual([true, true, false]);
    expect(root.querySelectorAll('rd-auth-steps .invisible')).toHaveLength(1);

    fixture.componentInstance.step.set(3);
    fixture.detectChanges();
    expect(fills()).toEqual([true, true, true]);
  });

  it('with a mouse, the cards lean toward the pointer and settle when it leaves', async () => {
    stubMotion(false);
    const fixture = TestBed.createComponent(AuthShowcase);
    fixture.detectChanges();
    await fixture.whenStable();
    const host = fixture.nativeElement as HTMLElement;
    host.getBoundingClientRect = () => ({ left: 100, top: 0, width: 400, height: 600, right: 500, bottom: 600, x: 100, y: 0, toJSON: () => ({}) });

    host.dispatchEvent(pointer('pointermove', 500, 150));
    expect(host.style.getPropertyValue('--px')).toBe('1.000');
    expect(host.style.getPropertyValue('--py')).toBe('-0.500');

    host.dispatchEvent(pointer('pointermove', 100, 600, 'touch')); // touch never leans
    expect(host.style.getPropertyValue('--px')).toBe('1.000');

    host.dispatchEvent(pointer('pointerleave', 0, 0));
    expect(host.style.getPropertyValue('--px')).toBe('0.000');
    expect(host.style.getPropertyValue('--py')).toBe('0.000');
  });

  it('with reduce motion, nothing follows the pointer', async () => {
    stubMotion(true);
    const fixture = TestBed.createComponent(AuthShowcase);
    fixture.detectChanges();
    await fixture.whenStable();
    const host = fixture.nativeElement as HTMLElement;
    host.dispatchEvent(pointer('pointermove', 500, 150));
    expect(host.style.getPropertyValue('--px')).toBe('');
  });
});
