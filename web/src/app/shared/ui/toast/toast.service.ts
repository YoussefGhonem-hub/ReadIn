import { Injectable, signal } from '@angular/core';

export type ToastKind = 'info' | 'success' | 'error';

/** A button on the toast (e.g. "Start over" after the reader resumed your position). */
export interface ToastAction {
  label: string;
  run: () => void;
}

export interface Toast {
  id: number;
  kind: ToastKind;
  message: string;
  /** In-app path the toast opens when tapped (e.g. a push received in the foreground). */
  link: string | null;
  action: ToastAction | null;
  /** Called when the toast's link is tapped (e.g. marks the push's notification read, F17). */
  opened: (() => void) | null;
}

const DURATION_MS = 4500;
/** A toast with an action stays longer, so there is time to reach its button. */
const ACTION_DURATION_MS = 8000;

@Injectable({ providedIn: 'root' })
export class ToastService {
  private nextId = 1;
  private readonly _toasts = signal<Toast[]>([]);
  readonly toasts = this._toasts.asReadonly();

  info(message: string, link: string | null = null, action: ToastAction | null = null, opened: (() => void) | null = null): void {
    this.show('info', message, link, action, opened);
  }

  success(message: string): void {
    this.show('success', message, null, null, null);
  }

  /** `action`: e.g. "حاول تاني" after a failed PDF download (F33). */
  error(message: string, action: ToastAction | null = null): void {
    this.show('error', message, null, action, null);
  }

  dismiss(id: number): void {
    this._toasts.update((list) => list.filter((t) => t.id !== id));
  }

  private show(kind: ToastKind, message: string, link: string | null, action: ToastAction | null, opened: (() => void) | null): void {
    const id = this.nextId++;
    // Same message twice in a row (e.g. parallel failing requests) shows once.
    if (this._toasts().some((t) => t.message === message)) return;
    this._toasts.update((list) => [...list.slice(-2), { id, kind, message, link, action, opened }]);
    setTimeout(() => this.dismiss(id), action ? ACTION_DURATION_MS : DURATION_MS);
  }
}
