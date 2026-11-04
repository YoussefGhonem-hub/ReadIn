import { Injectable, Injector, PLATFORM_ID, computed, effect, inject, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { MeApi } from '../api/me.api';
import { SessionStore } from '../auth/session.store';
import { LanguageService } from '../i18n/language.service';
import { ModerationNotices } from '../moderation/moderation-notices';
import { NotificationBadge } from '../notifications/notification-badge';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { PUSH_CLIENT, PushPermission } from './push-client';
import { NOTIFICATION_PARAM, pushLinkToPath, pushType, toPushMessage } from './push-message';

/**
 * Web push through Firebase Cloud Messaging (SPEC §21.1). Once the user has granted permission, this browser's
 * FCM token is registered with `POST /me/devices` on every sign-in and page load (which also picks up rotated
 * tokens) and deleted on sign-out and when the account is deleted. Pushes that arrive while a tab is visible become an
 * in-app toast; a moderation notice (F22) opens its dialog instead, which the user acknowledges. Tapping a push or its
 * toast marks its notification read (F17, `data.notificationId`), also when the tap opened a new tab.
 */
@Injectable({ providedIn: 'root' })
export class PushService {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly client = inject(PUSH_CLIENT);
  private readonly session = inject(SessionStore);
  private readonly meApi = inject(MeApi);
  private readonly toasts = inject(ToastService);
  private readonly language = inject(LanguageService);
  private readonly router = inject(Router);
  private readonly injector = inject(Injector);
  private readonly badge = inject(NotificationBadge);

  private readonly userId = computed(() => (this.session.isAuthenticated() ? (this.session.me()?.id ?? null) : null));
  /** The user and token last sent to the API from this page. */
  private registered: { userId: string; token: string } | null = null;

  private readonly _permission = signal<PushPermission>('unsupported');
  readonly permission = this._permission.asReadonly();

  /** Called once from an app initializer. Never asks for permission by itself. */
  init(): Promise<void> {
    if (!this.isBrowser) return Promise.resolve();
    this.takeTappedNotification();
    return this.client.isSupported().then((supported) => {
      if (!supported) return;
      this._permission.set(this.client.permission());
      this.client.onWorkerMessage((message) => {
        if (message.type === 'push') this.showInApp(message.payload);
        else this.open(message.path, message.notificationId);
      });
      effect(
        () => {
          const userId = this.userId();
          const permission = this._permission();
          untracked(() => void this.sync(userId, permission));
        },
        { injector: this.injector },
      );
    });
  }

  /** Asks for permission in context (onboarding, settings), never on first launch (SPEC §21.1). */
  async enable(): Promise<PushPermission> {
    if (this._permission() === 'unsupported') return 'unsupported';
    const permission = await this.client.requestPermission();
    this._permission.set(permission);
    return permission;
  }

  /**
   * Called on sign out while the access token still works: `DELETE /me/devices/{token}` so the API stops sending
   * this account's pushes here, then the FCM token itself is dropped. A no-op when nothing was registered.
   */
  async unregisterDevice(): Promise<void> {
    const registered = this.registered;
    if (!registered) return;
    try {
      await firstValueFrom(this.meApi.unregisterDevice(registered.token));
    } catch {
      /* offline: the API drops the token once FCM reports it invalid */
    }
    await this.unregister();
  }

  /**
   * The account was deleted: the API already dropped its devices, so nothing is sent to it (the token couldn't call it
   * anyway). The FCM token on this browser is deleted too, also one registered by an earlier page load, so no push
   * for the deleted account can reach it.
   */
  async forgetDevice(): Promise<void> {
    if (this.registered || this._permission() === 'granted') await this.unregister();
  }

  private async sync(userId: string | null, permission: PushPermission): Promise<void> {
    if (userId && permission === 'granted') await this.register(userId);
    else if (!userId && this.registered) await this.unregister();
  }

  private async register(userId: string): Promise<void> {
    try {
      const token = await this.client.getToken();
      if (this.userId() !== userId) return; // signed out or switched while the token was created
      if (this.registered?.userId === userId && this.registered.token === token) return;
      await firstValueFrom(this.meApi.registerDevice({ token, platform: 'web' }, { silent: true }));
      this.registered = { userId, token };
    } catch {
      /* blocked, offline or permission revoked: retried on the next sign-in or page load */
    }
  }

  private async unregister(): Promise<void> {
    this.registered = null;
    try {
      await this.client.deleteToken();
    } catch {
      /* the API drops the token when FCM reports it invalid */
    }
  }

  private showInApp(payload: unknown): void {
    void this.badge.refresh(); // the live badge updates by itself; the REST fallback has to ask
    if (pushType(payload) === 'moderation_notice') {
      this.injector.get(ModerationNotices).reload();
      return;
    }
    const message = toPushMessage(payload, location.origin, this.language.lang());
    if (!message) return;
    const text = message.title && message.body ? `${message.title} — ${message.body}` : message.title || message.body;
    const id = message.notificationId;
    this.toasts.info(text, message.path, null, id ? () => void this.badge.markRead(id) : null);
  }

  /** A notification was tapped while this tab was open. */
  private open(path: string, notificationId: string | null): void {
    if (notificationId) void this.badge.markRead(notificationId);
    const safe = pushLinkToPath(path, location.origin, this.language.lang());
    if (safe) void this.router.navigateByUrl(safe);
  }

  /**
   * A tapped push opened this tab (the worker adds `?notification={id}`): the parameter leaves the address before the
   * router reads it, and the notification is marked read once the session is restored (nothing to do for a guest).
   */
  private takeTappedNotification(): void {
    const url = new URL(location.href);
    if (!url.searchParams.has(NOTIFICATION_PARAM)) return;
    const id = url.searchParams.get(NOTIFICATION_PARAM)?.trim();
    url.searchParams.delete(NOTIFICATION_PARAM);
    history.replaceState(history.state, '', `${url.pathname}${url.search}${url.hash}`);
    if (!id) return;
    let done = false;
    const watcher = effect(
      () => {
        const resolved = this.session.isResolved();
        const userId = this.userId();
        if (!resolved || done) return;
        done = true;
        untracked(() => {
          watcher.destroy();
          if (userId) void this.badge.markRead(id);
        });
      },
      { injector: this.injector, manualCleanup: true },
    );
  }
}
