import { Injectable, effect, inject, signal, untracked } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { RouterStateSnapshot, TitleStrategy } from '@angular/router';
import { TranslocoService } from '@jsverse/transloco';
import { LanguageService } from './language.service';

/**
 * A route's `title` is an i18n key (`title: 'pageTitles.signIn'`): the tab reads "{translation} — ReadIn" and follows
 * the UI language. Routes without a title are left alone: those pages set their own (articles, profiles, Settings…).
 */
@Injectable({ providedIn: 'root' })
export class PageTitleStrategy extends TitleStrategy {
  private readonly title = inject(Title);
  private readonly transloco = inject(TranslocoService);
  private readonly key = signal<string | null>(null);

  constructor() {
    super();
    const lang = inject(LanguageService).lang;
    // Again when the UI language changes (its translations are loaded by then).
    effect(() => {
      lang();
      const key = this.key();
      if (key) untracked(() => this.apply(key));
    });
  }

  override updateTitle(snapshot: RouterStateSnapshot): void {
    const key = this.buildTitle(snapshot) ?? null;
    this.key.set(key);
    if (key) this.apply(key);
  }

  private apply(key: string): void {
    this.title.setTitle(`${this.transloco.translate(key)} — ReadIn`);
  }
}
