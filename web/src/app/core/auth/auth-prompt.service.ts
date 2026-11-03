import { Injectable, inject, signal } from '@angular/core';
import { SessionStore } from './session.store';

/** Guest browsing with a soft prompt to sign in when trying to interact (F01). */
@Injectable({ providedIn: 'root' })
export class AuthPromptService {
  private readonly session = inject(SessionStore);
  readonly isOpen = signal(false);

  /** Returns true when the user may interact; otherwise opens the sign-in prompt. */
  requireAuth(): boolean {
    if (this.session.isAuthenticated()) return true;
    this.isOpen.set(true);
    return false;
  }

  close(): void {
    this.isOpen.set(false);
  }
}
