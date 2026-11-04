import { TextDir } from '../../../shared/directives/bidi';

/** An uploaded image block picture (`POST /uploads/images`, purpose=image). */
export interface UploadedImage {
  src: string;
  width: number | null;
  height: number | null;
}

export interface MentionCandidate {
  id: string;
  displayName: string;
  username: string;
  avatarUrl: string | null;
  isVerified: boolean;
}

/**
 * What the Tiptap extensions and node views need from the Angular side. Node views are plain DOM (no Angular), so
 * they get translated strings, uploads and asset URLs through this object.
 */
export interface RDocEditorHost {
  /** A UI string in the current UI language. */
  t(key: string, params?: Record<string, unknown>): string;
  /** Uploads a picture for an image block; `onProgress` gets 0..1. Rejects with an error code string. */
  uploadImage(file: File, onProgress: (fraction: number) => void, signal: AbortSignal): Promise<UploadedImage>;
  /** Called with +1 when an upload starts and -1 when it ends (Publish waits for uploads). */
  uploadsChanged(delta: number): void;
  /** `rdoc-asset://` → URL; http(s) URLs pass through; anything else is null. */
  resolveAsset(src: string): string | null;
  /** Direction of blocks without strong characters: the article language's. */
  fallbackDir(): TextDir;
}
