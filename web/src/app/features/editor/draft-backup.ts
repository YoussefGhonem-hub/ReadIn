import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { ArticleDraftDocument } from '../../core/api/models';

/** Backup key of an article that has no server id yet (`/write/new`). */
export const NEW_ARTICLE_KEY = 'new';
const PREFIX = 'readin.editor.backup';

/** Unsaved changes kept on this device until the server has them (F05 "local backup, offline-safe"). */
export interface DraftBackup {
  /** Null for an article not created on the server yet. */
  articleId: string | null;
  /** The server version the changes were made on (null before the first save). */
  baseVersion: number | null;
  /** When the last change was made (this device's clock, ISO). */
  updatedAt: string;
  document: ArticleDraftDocument;
}

function isBackup(value: unknown): value is DraftBackup {
  if (!value || typeof value !== 'object') return false;
  const backup = value as Partial<DraftBackup>;
  return (
    typeof backup.updatedAt === 'string' &&
    !!backup.document &&
    typeof backup.document === 'object' &&
    Array.isArray(backup.document.translations) &&
    backup.document.translations.length > 0
  );
}

/**
 * Local backups of the editor in `localStorage`, one per user and article (a temporary key for a new article). Every
 * access is wrapped: storage may be missing, full or blocked (private mode), and the editor works without it.
 */
@Injectable({ providedIn: 'root' })
export class DraftBackupStore {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  private storage(): Storage | null {
    if (!this.isBrowser) return null;
    try {
      return typeof localStorage === 'undefined' ? null : localStorage;
    } catch {
      return null;
    }
  }

  key(userId: string, articleKey: string): string {
    return `${PREFIX}.${userId}.${articleKey}`;
  }

  read(userId: string, articleKey: string): DraftBackup | null {
    try {
      const raw = this.storage()?.getItem(this.key(userId, articleKey));
      if (!raw) return null;
      const value = JSON.parse(raw) as unknown;
      return isBackup(value) ? value : null;
    } catch {
      return null;
    }
  }

  /** False when the backup could not be written (no storage, quota exceeded). */
  write(userId: string, articleKey: string, backup: DraftBackup): boolean {
    try {
      const storage = this.storage();
      if (!storage) return false;
      storage.setItem(this.key(userId, articleKey), JSON.stringify(backup));
      return true;
    } catch {
      return false;
    }
  }

  clear(userId: string, articleKey: string): void {
    try {
      this.storage()?.removeItem(this.key(userId, articleKey));
    } catch {
      // nothing to clean up
    }
  }
}
