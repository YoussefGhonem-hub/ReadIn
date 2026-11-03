import { Injectable, signal } from '@angular/core';

export type ToastKind = 'info' | 'success' | 'error';

export interface Toast {
  id: number;
  kind: ToastKind;
  message: string;
}

const DURATION_MS = 4500;

@Injectable({ providedIn: 'root' })
export class ToastService {
  private nextId = 1;
  private readonly _toasts = signal<Toast[]>([]);
  readonly toasts = this._toasts.asReadonly();

  info(message: string): void {
    this.show('info', message);
  }

  success(message: string): void {
    this.show('success', message);
  }

  error(message: string): void {
    this.show('error', message);
  }

  dismiss(id: number): void {
    this._toasts.update((list) => list.filter((t) => t.id !== id));
  }

  private show(kind: ToastKind, message: string): void {
    const id = this.nextId++;
    // Same message twice in a row (e.g. parallel failing requests) shows once.
    if (this._toasts().some((t) => t.message === message)) return;
    this._toasts.update((list) => [...list.slice(-2), { id, kind, message }]);
    setTimeout(() => this.dismiss(id), DURATION_MS);
  }
}
