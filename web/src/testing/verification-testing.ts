import { AdminVerificationRequestDto, MyVerificationRequestDto, VerificationStatusDto } from '../app/core/api/models';

/** Your pending request: Software, a LinkedIn link and a syndicate card (F19), as `GET /me/verification` sends it. */
export function testVerificationRequest(patch: Partial<MyVerificationRequestDto> = {}): MyVerificationRequestDto {
  return {
    id: 'vr-1',
    status: 'pending',
    field: { id: 'f-software', slug: 'software', name: 'البرمجيات' },
    jobTitle: 'Backend engineer في Vodafone',
    proofUrl: 'https://www.linkedin.com/in/mona',
    proofFileName: 'كارنيه النقابة.pdf',
    note: null,
    submittedAt: '2026-11-02T10:00:00Z',
    decidedAt: null,
    rejectionReason: null,
    ...patch,
  };
}

export function testVerificationStatus(patch: Partial<VerificationStatusDto> = {}): VerificationStatusDto {
  return { isVerified: false, canRequest: true, request: null, ...patch };
}

/** A pending request in the admins' review: Salma, Software, a link and a PNG certificate. */
export function testAdminRequest(id = 'vr-salma', patch: Partial<AdminVerificationRequestDto> = {}): AdminVerificationRequestDto {
  return {
    id,
    status: 'pending',
    user: { id: `u-${id}`, displayName: 'سلمى إبراهيم', username: 'salma', avatarUrl: null, isVerified: false },
    field: { id: 'f-software', slug: 'software', name: 'البرمجيات' },
    jobTitle: 'ML engineer في Instabug',
    proofUrl: 'https://www.linkedin.com/in/salma-ibrahim',
    proof: { fileName: 'aws-ml-certificate.png', contentType: 'image/png', sizeBytes: 48_213 },
    note: 'شهادة AWS Machine Learning Specialty.',
    submittedAt: '2026-11-02T10:00:00Z',
    decidedAt: null,
    decidedBy: null,
    rejectionReason: null,
    ...patch,
  };
}
