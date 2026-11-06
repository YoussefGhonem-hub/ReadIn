import { Component, Type, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideRouter } from '@angular/router';
import { translocoTesting } from '../testing/transloco-testing';
import { App } from './app';
import { AuthPromptService } from './core/auth/auth-prompt.service';
import { ModerationNotices } from './core/moderation/moderation-notices';
import { TermSheetService } from './shared/rdoc/rdoc-context';
import { provideAppIcons } from './shared/ui/icons';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App, translocoTesting()],
      providers: [provideRouter([]), provideAppIcons(), provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();
  });

  it('creates the root; the toast host and the tooltip come after the first render, the sign-in prompt and the term sheet when first opened', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    const el = fixture.nativeElement as HTMLElement;
    // Chunks of their own (not in the initial bundle), created in the browser once the app has rendered.
    await vi.waitFor(() => {
      expect(el.querySelector('rd-toast-host')).not.toBeNull();
      expect(el.querySelector('rd-tooltip-host')).not.toBeNull();
    });
    expect(el.querySelector('rd-sign-in-prompt')).toBeNull();
    expect(el.querySelector('rd-term-sheet')).toBeNull();

    TestBed.inject(AuthPromptService).requireAuth(); // a guest tries to interact
    await vi.waitFor(() => {
      fixture.detectChanges();
      expect(el.querySelector('rd-sign-in-prompt [role="dialog"]')).not.toBeNull();
    });

    TestBed.inject(TermSheetService).open({ termId: 'dependency-injection', text: 'DI', language: 'en', articleId: null });
    await vi.waitFor(() => {
      fixture.detectChanges();
      expect(el.querySelector('rd-term-sheet [role="dialog"]')).not.toBeNull();
    });
    const http = TestBed.inject(HttpTestingController);
    http.expectOne((r) => r.url.endsWith('/glossary/dependency-injection')).flush(null, { status: 404, statusText: 'Not Found' });
    http.verify();
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
    // ModerationNotices itself is a chunk the app loads after its first render.
    await vi.waitFor(() => {
      fixture.detectChanges();
      expect(el.querySelectorAll('[data-fake-notice]')).toHaveLength(1);
    });
    // Once: it stays the same dialog for every notice.
    dialog.set(FakeNotice);
    await fixture.whenStable();
    expect(el.querySelectorAll('[data-fake-notice]')).toHaveLength(1);
  });
});
