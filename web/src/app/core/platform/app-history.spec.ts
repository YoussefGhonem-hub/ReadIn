import { ApplicationRef, Component } from '@angular/core';
import { Location } from '@angular/common';
import { provideLocationMocks } from '@angular/common/testing';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { AppHistory } from './app-history';

@Component({ selector: 'rd-test-page', template: '' })
class TestPage {}

/** Lets the router finish a navigation (a popstate one starts on a timer). */
async function settle(): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve));
  await TestBed.inject(ApplicationRef).whenStable();
}

describe('AppHistory (in-app Back, F04)', () => {
  let router: Router;
  let location: Location;
  let history: AppHistory;

  beforeEach(() => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      providers: [
        provideRouter(['', 'saved', 'ar/a/one', 'en/a/one', 'ar/a/two'].map((path) => ({ path, component: TestPage }))),
        provideLocationMocks(),
      ],
    });
    // Created before the first navigation, as app.config.ts does.
    history = TestBed.inject(AppHistory);
    router = TestBed.inject(Router);
    location = TestBed.inject(Location);
  });

  /** The tab opens on `path` (a link, a new tab, a reload): the app's first navigation. */
  async function open(path: string): Promise<void> {
    location.replaceState(path);
    router.initialNavigation();
    await settle();
    expect(location.path()).toBe(path);
  }

  it('the page the app opened on has nothing of the app before it: Back goes to the fallback', async () => {
    await open('/ar/a/one');
    expect(history.canGoBack()).toBe(false);
    history.back('/');
    await settle();
    expect(location.path()).toBe('/');
  });

  it('counts the pages you went through, and follows browser Back and Forward', async () => {
    await open('/');
    await router.navigateByUrl('/saved');
    expect(history.canGoBack()).toBe(true);
    await router.navigateByUrl('/ar/a/one');
    expect(history.canGoBack()).toBe(true);

    history.back();
    await settle();
    expect(location.path()).toBe('/saved');
    expect(history.canGoBack()).toBe(true);

    location.back();
    await settle();
    expect(location.path()).toBe('/');
    expect(history.canGoBack()).toBe(false);

    location.forward();
    await settle();
    expect(location.path()).toBe('/saved');
    expect(history.canGoBack()).toBe(true);
  });

  it('a replaced entry keeps its depth (the reader’s language switch)', async () => {
    await open('/ar/a/one');
    await router.navigateByUrl('/en/a/one', { replaceUrl: true });
    expect(history.canGoBack()).toBe(false);

    await router.navigateByUrl('/ar/a/two');
    expect(history.canGoBack()).toBe(true);
    history.back();
    await settle();
    expect(location.path()).toBe('/en/a/one');
    expect(history.canGoBack()).toBe(false);
  });
});
