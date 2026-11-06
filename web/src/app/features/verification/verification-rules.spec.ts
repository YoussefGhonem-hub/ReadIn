import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { VerificationStatusDto } from '../../core/api/models';
import { formatFileSize } from '../../shared/pipes/format.pipes';
import { translocoTesting } from '../../../testing/transloco-testing';
import { PROOF_MAX_BYTES, VerificationDraft, draftErrors, fileError, isProofUrl } from './verification-rules';
import { verificationView } from './verification-status';

const draft = (patch: Partial<VerificationDraft> = {}): VerificationDraft => ({
  fieldId: 'f-software',
  jobTitle: 'Backend engineer',
  proofUrl: 'https://www.linkedin.com/in/mona',
  note: '',
  file: null,
  ...patch,
});

const file = (name: string, type: string, size = 1000) => ({ name, type, size }) as File;

describe('verification request rules (F19)', () => {
  it('a proof link is an absolute https URL of at most 500 characters', () => {
    expect(isProofUrl('https://github.com/mona')).toBe(true);
    expect(isProofUrl('  https://www.linkedin.com/in/mona  ')).toBe(true);
    expect(isProofUrl('http://github.com/mona')).toBe(false);
    expect(isProofUrl('github.com/mona')).toBe(false);
    expect(isProofUrl('javascript:alert(1)')).toBe(false);
    expect(isProofUrl('')).toBe(false);
    expect(isProofUrl(`https://example.com/${'a'.repeat(480)}`)).toBe(true);
    expect(isProofUrl(`https://example.com/${'a'.repeat(481)}`)).toBe(false);
  });

  it('a proof file is a PDF, JPEG, PNG or WebP of up to 10 MB', () => {
    expect(fileError(file('card.pdf', 'application/pdf'))).toBeNull();
    expect(fileError(file('card.jpg', 'image/jpeg'))).toBeNull();
    expect(fileError(file('card.png', 'image/png', PROOF_MAX_BYTES))).toBeNull();
    expect(fileError(file('card.webp', 'image/webp'))).toBeNull();
    expect(fileError(file('card.png', 'image/png', PROOF_MAX_BYTES + 1))).toBe('fileSize');
    expect(fileError(file('card.gif', 'image/gif'))).toBe('fileType');
    expect(fileError(file('card.svg', 'image/svg+xml'))).toBe('fileType');
    expect(fileError(file('card.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'))).toBe('fileType');
    // No type from the browser: the extension decides (the API checks the bytes anyway).
    expect(fileError(file('CARD.JPEG', ''))).toBeNull();
    expect(fileError(file('card.heic', ''))).toBe('fileType');
  });

  it('needs a field, a job title of 2–100 characters and at least one proof; the note is optional (≤ 500)', () => {
    expect(draftErrors(draft())).toEqual({});
    expect(draftErrors(draft({ proofUrl: '', file: file('card.pdf', 'application/pdf') }))).toEqual({});
    expect(draftErrors(draft({ fieldId: '' }))).toEqual({ fieldId: 'fieldRequired' });
    expect(draftErrors(draft({ jobTitle: ' a ' }))).toEqual({ jobTitle: 'jobTitleLength' });
    expect(draftErrors(draft({ jobTitle: 'a'.repeat(101) }))).toEqual({ jobTitle: 'jobTitleLength' });
    expect(draftErrors(draft({ jobTitle: 'a'.repeat(100) }))).toEqual({});
    expect(draftErrors(draft({ proofUrl: '' }))).toEqual({ proof: 'proofRequired' });
    expect(draftErrors(draft({ proofUrl: 'http://x.com' }))).toEqual({ proofUrl: 'proofUrlInvalid' });
    expect(draftErrors(draft({ file: file('card.gif', 'image/gif') }))).toEqual({ proof: 'fileType' });
    expect(draftErrors(draft({ note: 'n'.repeat(501) }))).toEqual({ note: 'noteTooLong' });
    expect(draftErrors(draft({ note: 'n'.repeat(500) }))).toEqual({});
  });

  // The form and the admin's proof preview use the app's formatter: no "KB/MB" literals in Arabic (6.6 leftover).
  it('sizes read "830 ك.ب" / "2.4 م.ب" in Arabic and "830 KB" / "2.4 MB" in English', () => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ imports: [translocoTesting()] });
    const transloco = TestBed.inject(TranslocoService);
    expect(formatFileSize(transloco, 850_000, 'ar')).toBe('830 ك.ب');
    expect(formatFileSize(transloco, 2_500_000, 'ar')).toBe('2.4 م.ب');
    expect(formatFileSize(transloco, 10, 'ar')).toBe('1 ك.ب');
    expect(formatFileSize(transloco, 850_000, 'en')).toBe('830 KB');
    expect(formatFileSize(transloco, 2_500_000, 'en')).toBe('2.4 MB');
    expect(formatFileSize(transloco, 10, 'en')).toBe('1 KB');
  });

  it('where a request stands', () => {
    const request = (status: 'pending' | 'approved' | 'rejected') => ({ status }) as VerificationStatusDto['request'];
    const view = (patch: Partial<VerificationStatusDto>) => verificationView({ isVerified: false, canRequest: true, request: null, ...patch });
    expect(view({})).toBe('none');
    expect(view({ isVerified: true, canRequest: false, request: request('approved') })).toBe('verified');
    expect(view({ canRequest: false, request: request('pending') })).toBe('pending');
    expect(view({ request: request('rejected') })).toBe('rejected');
    // Suspended (or otherwise not allowed), with nothing pending.
    expect(view({ canRequest: false })).toBe('unavailable');
    expect(view({ canRequest: false, request: request('rejected') })).toBe('unavailable');
    // Approved once, but no longer verified: a new request is possible.
    expect(view({ request: request('approved') })).toBe('none');
  });
});
