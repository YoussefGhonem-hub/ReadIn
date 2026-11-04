import { Component, Type, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { translocoTesting } from '../testing/transloco-testing';
import { App } from './app';
import { ModerationNotices } from './core/moderation/moderation-notices';
import { provideAppIcons } from './shared/ui/icons';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App, translocoTesting()],
      providers: [provideRouter([]), provideAppIcons()],
    }).compileComponents();
  });

  it('creates the root with toast host, sign-in prompt and term sheet', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    const el = fixture.nativeElement as HTMLElement;
    expect(el.querySelector('rd-toast-host')).not.toBeNull();
    expect(el.querySelector('rd-sign-in-prompt')).not.toBeNull();
    expect(el.querySelector('rd-term-sheet')).not.toBeNull();
  });

  it('applies the theme attribute on startup', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    expect(document.documentElement.getAttribute('data-theme')).toMatch(/^(system|light|dark)$/);
  });

  it('shows the moderation notice dialog once its chunk is there (F22)', async () => {
    @Component({ selector: 'rd-fake-notice', template: '<p data-fake-notice>notice</p>' })
    class FakeNotice {}
    const dialog = signal<Type<unknown> | null>(null);
    TestBed.overrideProvider(ModerationNotices, { useValue: { dialog } });
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    const el = fixture.nativeElement as HTMLElement;
    expect(el.querySelector('[data-fake-notice]')).toBeNull();
    dialog.set(FakeNotice);
    await fixture.whenStable();
    fixture.detectChanges();
    expect(el.querySelectorAll('[data-fake-notice]')).toHaveLength(1);
    // Once: it stays the same dialog for every notice.
    dialog.set(FakeNotice);
    await fixture.whenStable();
    expect(el.querySelectorAll('[data-fake-notice]')).toHaveLength(1);
  });
});
