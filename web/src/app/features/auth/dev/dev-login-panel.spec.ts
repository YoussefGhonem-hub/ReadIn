import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { translocoTesting } from '../../../../testing/transloco-testing';
import { provideAppIcons } from '../../../shared/ui/icons';
import { DEV_SEED_USERS, DevLoginPanel } from './dev-login-panel';

/** The dev login panel (SPEC §18.3) after the roles change (SPEC §10): Member or SuperAdmin, Verified is a badge. */
describe('DevLoginPanel', () => {
  const DEMO_PASSWORD_KEY = 'readin.dev.demoPassword';

  function render(lang: 'ar' | 'en' = 'ar') {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ imports: [translocoTesting()], providers: [provideAppIcons()] });
    TestBed.inject(TranslocoService).setActiveLang(lang);
    const pick = vi.fn();
    const fixture = TestBed.createComponent(DevLoginPanel);
    fixture.componentRef.setInput('pick', pick);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const user = (phone: string) => root.querySelector<HTMLButtonElement>(`[data-dev-user="${phone}"]`);
    const role = (phone: string) => user(phone)!.querySelector('[data-dev-user-role]')!;
    return { root, user, role, pick };
  }

  afterEach(() => localStorage.removeItem(DEMO_PASSWORD_KEY));

  it('lists only Member and SuperAdmin accounts: no demo admin or moderator, no old role names', () => {
    const t = render();
    expect(DEV_SEED_USERS.map((u) => u.role).every((r) => r === 'Member' || r === 'SuperAdmin')).toBe(true);
    expect(DEV_SEED_USERS.filter((u) => u.role === 'SuperAdmin').map((u) => u.phone)).toEqual(['+12025550101']);
    expect(t.user('+12025550102')).toBeNull();
    expect(t.user('+12025550103')).toBeNull();
    expect(t.root.textContent).not.toMatch(/VerifiedWriter|Moderator|Admin User/);
    expect(t.role('+12025550101').textContent!.trim()).toBe('SuperAdmin');
    expect(t.role('+12025550107').textContent!.trim()).toBe('Member');
    expect(t.role('+12025550107').querySelector('[data-dev-user-verified]')).toBeNull();
  });

  it('the demo "Verified Writer" (+12025550106) is gone: no seed account has that number any more', () => {
    const t = render('en');
    expect(DEV_SEED_USERS.map((u) => u.phone)).not.toContain('+12025550106');
    expect(DEV_SEED_USERS.map((u) => u.name)).not.toContain('Verified Writer');
    expect(t.user('+12025550106')).toBeNull();
    expect(t.root.textContent).not.toContain('Verified Writer');
    // The two verified writers that stay, then writers 1–3 from .107.
    expect(DEV_SEED_USERS.filter((u) => u.verified).map((u) => u.phone)).toEqual(['+12025550104', '+12025550105']);
    expect(DEV_SEED_USERS.slice(3, 6).map((u) => [u.phone, u.name])).toEqual([
      ['+12025550107', 'Writer 1'],
      ['+12025550108', 'Writer 2'],
      ['+12025550109', 'Writer 3'],
    ]);
  });

  it('the verified writers are Members with the Verified badge, translated', () => {
    const ar = render('ar');
    for (const phone of ['+12025550104', '+12025550105']) {
      expect(ar.role(phone).querySelector('bdi')!.textContent).toBe('Member');
      const badge = ar.role(phone).querySelector('[data-dev-user-verified]')!;
      expect(badge.querySelector('svg')).not.toBeNull();
      expect(badge.textContent).toContain('كاتب موثّق');
    }
    expect(render('en').role('+12025550104').querySelector('[data-dev-user-verified]')!.textContent).toContain('Verified writer');
  });

  it('the suspended account is a Member, marked suspended', () => {
    const t = render('en');
    expect(t.role('+12025550120').querySelector('bdi')!.textContent).toBe('Member');
    expect(t.role('+12025550120').querySelector('[data-dev-user-suspended]')!.textContent).toContain('suspended');
  });

  it('picking an account passes its number and the saved demo password, which is never shown', () => {
    localStorage.setItem(DEMO_PASSWORD_KEY, 'not-the-real-one');
    const t = render();
    expect(t.root.textContent).not.toContain('not-the-real-one');
    expect(t.root.querySelector<HTMLInputElement>('#dev-demo-password')!.type).toBe('password');
    t.user('+12025550104')!.click();
    expect(t.pick).toHaveBeenCalledWith('+12025550104', 'not-the-real-one');
  });
});
