import { VerificationStatusDto } from '../../core/api/models';

/**
 * Where your writer verification stands (F19): verified; under review; not approved (the reason, and you can ask
 * again); nothing yet (the form); or you can't ask now (e.g. a suspended account).
 */
export type VerificationView = 'verified' | 'pending' | 'rejected' | 'none' | 'unavailable';

export function verificationView(status: VerificationStatusDto): VerificationView {
  if (status.isVerified) return 'verified';
  if (status.request?.status === 'pending') return 'pending';
  if (!status.canRequest) return 'unavailable';
  return status.request?.status === 'rejected' ? 'rejected' : 'none';
}
