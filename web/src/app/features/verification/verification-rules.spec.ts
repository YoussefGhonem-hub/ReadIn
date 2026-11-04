import { VerificationStatusDto } from '../../core/api/models';
import { PROOF_MAX_BYTES, VerificationDraft, draftErrors, fileError, fileSize, isProofUrl } from './verification-rules';
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

  it('sizes read "830 KB" / "2.4 MB"', () => {
    expect(fileSize(850_000)).toBe('830 KB');
    expect(fileSize(2_500_000)).toBe('2.4 MB');
    expect(fileSize(10)).toBe('1 KB');
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
