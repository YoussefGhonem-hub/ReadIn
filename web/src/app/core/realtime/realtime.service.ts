import { Injectable, signal } from '@angular/core';

export type RealtimeState = 'disconnected' | 'connecting' | 'connected';

/**
 * SignalR connection to `/hubs/notifications` (SPEC §17.2, F17).
 * Phase 2: connect with the Firebase ID token after sign-in and push unread counts into the notifications store.
 * Kept as an explicit seam so features can depend on it now without pulling in `@microsoft/signalr` yet.
 */
@Injectable({ providedIn: 'root' })
export class RealtimeService {
  readonly state = signal<RealtimeState>('disconnected');
  readonly unreadNotifications = signal(0);
}
