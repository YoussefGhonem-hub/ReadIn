/**
 * The verification request's rules (F19), checked before anything is sent; the API checks them again (the file by its
 * magic bytes, which the browser can't).
 */
export const JOB_TITLE_MIN = 2;
export const JOB_TITLE_MAX = 100;
export const PROOF_URL_MAX = 500;
export const NOTE_MAX = 500;
export const REASON_MIN = 5;
export const REASON_MAX = 500;
export const PROOF_MAX_BYTES = 10 * 1024 * 1024;

/** PDF, JPEG, PNG or WebP. */
export const PROOF_TYPES: readonly string[] = ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];
const PROOF_EXTENSION = /\.(pdf|jpe?g|png|webp)$/i;
/** For `<input type="file" accept>`. */
export const PROOF_ACCEPT = 'application/pdf,image/jpeg,image/png,image/webp,.pdf,.jpg,.jpeg,.png,.webp';

/** The `verification.form.errors.*` key of a problem with one input. */
export type FormErrorKey = 'fieldRequired' | 'jobTitleLength' | 'proofUrlInvalid' | 'proofRequired' | 'fileType' | 'fileSize' | 'noteTooLong';

export interface VerificationDraft {
  fieldId: string;
  jobTitle: string;
  proofUrl: string;
  note: string;
  file: File | null;
}

export type DraftErrors = Partial<Record<'fieldId' | 'jobTitle' | 'proofUrl' | 'proof' | 'note', FormErrorKey>>;

/** An absolute `https://` URL of at most 500 characters (after trimming). */
export function isProofUrl(value: string): boolean {
  const url = value.trim();
  if (!url || url.length > PROOF_URL_MAX) return false;
  try {
    const parsed = new URL(url);
    return parsed.protocol === 'https:' && !!parsed.hostname;
  } catch {
    return false;
  }
}

/**
 * A file the API may accept: a known type (or, when the browser reports none, a known extension) and ≤ 10 MB. Null
 * when it is fine.
 */
export function fileError(file: Pick<File, 'name' | 'type' | 'size'>): 'fileType' | 'fileSize' | null {
  const type = file.type.toLowerCase();
  const known = type ? PROOF_TYPES.includes(type) : PROOF_EXTENSION.test(file.name);
  if (!known) return 'fileType';
  return file.size > PROOF_MAX_BYTES ? 'fileSize' : null;
}

/** Every problem of the draft, by input; empty when it can be sent. */
export function draftErrors(draft: VerificationDraft): DraftErrors {
  const errors: DraftErrors = {};
  if (!draft.fieldId) errors.fieldId = 'fieldRequired';
  const title = draft.jobTitle.trim().length;
  if (title < JOB_TITLE_MIN || title > JOB_TITLE_MAX) errors.jobTitle = 'jobTitleLength';
  const url = draft.proofUrl.trim();
  if (url && !isProofUrl(url)) errors.proofUrl = 'proofUrlInvalid';
  const file = draft.file ? fileError(draft.file) : null;
  if (file) errors.proof = file;
  else if (!url && !draft.file) errors.proof = 'proofRequired';
  if (draft.note.trim().length > NOTE_MAX) errors.note = 'noteTooLong';
  return errors;
}
