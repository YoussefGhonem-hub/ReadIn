import { Params } from '@angular/router';
import { MeDto } from '../api/models';
import { LANG_PARAM_PATHS } from '../i18n/language.service';

/**
 * What a signed-in account has to finish before using the app, in the order SPEC §9.2 applies them: change the
 * password (after an Admin reset), set a recovery PIN (cannot be skipped), accept newer terms (F37), complete the
 * profile, then onboarding.
 */
export type SetupStep = 'password' | 'pin' | 'terms' | 'profile' | 'onboarding';

export const SETUP_ORDER: readonly SetupStep[] = ['password', 'pin', 'terms', 'profile', 'onboarding'];

export const SETUP_PATHS: Record<SetupStep, string> = {
  password: '/auth/change-password',
  pin: '/auth/recovery-pin',
  terms: '/auth/terms',
  profile: '/auth/complete-profile',
  onboarding: '/onboarding',
};

export function nextSetupStep(me: MeDto): SetupStep | null {
  if (me.mustChangePassword) return 'password';
  if (me.mustSetRecoveryPin) return 'pin';
  if (me.mustAcceptTerms) return 'terms';
  if (!me.isProfileComplete) return 'profile';
  if (!me.onboardingCompleted) return 'onboarding';
  return null;
}

/**
 * Pages a member who still has to accept newer terms can open (F37): the texts themselves, help, and deleting the
 * account ("Declining offers sign out or delete account").
 */
export const TERMS_STEP_OPEN_PATHS: readonly string[] = [...LANG_PARAM_PATHS, '/settings/delete-account'];

/** Only same-origin app paths are accepted as a redirect target (no open redirects, never back into auth screens). */
export function safeReturnUrl(value: string | null | undefined): string {
  if (!value || !value.startsWith('/') || value.startsWith('//') || value.startsWith('/\\')) return '/';
  if (value.startsWith('/auth') || value.startsWith('/onboarding')) return '/';
  return value;
}

/** Where to go after signing in or finishing a step: the next mandatory step (keeping `returnUrl`), else `returnUrl`. */
export function postAuthTarget(me: MeDto | null, returnUrl: string | null | undefined): { path: string; queryParams: Params } {
  const target = safeReturnUrl(returnUrl);
  const step = me ? nextSetupStep(me) : null;
  if (!step) return { path: target, queryParams: {} };
  return { path: SETUP_PATHS[step], queryParams: target === '/' ? {} : { returnUrl: target } };
}

/** `postAuthTarget` as one URL string, for `router.navigateByUrl`. */
export function postAuthUrl(me: MeDto | null, returnUrl: string | null | undefined): string {
  const { path, queryParams } = postAuthTarget(me, returnUrl);
  const query = new URLSearchParams(queryParams as Record<string, string>).toString();
  return query ? `${path}?${query}` : path;
}
