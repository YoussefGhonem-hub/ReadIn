import { Routes } from '@angular/router';
import { guestOnlyGuard, setupStepGuard } from '../../core/auth/guards';

/**
 * Auth screens (SPEC §9.2). All of them render in the browser only (app.routes.server.ts). Each `title` is an i18n key
 * (core/i18n/page-title.strategy.ts).
 */
export default [
  // Guests
  {
    path: '',
    pathMatch: 'full',
    canActivate: [guestOnlyGuard],
    loadComponent: () => import('./welcome.page').then((m) => m.WelcomePage),
    title: 'pageTitles.welcome',
  },
  { path: 'sign-in', canActivate: [guestOnlyGuard], loadComponent: () => import('./sign-in.page').then((m) => m.SignInPage), title: 'pageTitles.signIn' },
  { path: 'sign-up', canActivate: [guestOnlyGuard], loadComponent: () => import('./sign-up.page').then((m) => m.SignUpPage), title: 'pageTitles.signUp' },
  {
    path: 'forgot-password',
    canActivate: [guestOnlyGuard],
    loadComponent: () => import('./forgot-password.page').then((m) => m.ForgotPasswordPage),
    title: 'pageTitles.forgotPassword',
  },
  // Mandatory steps for signed-in accounts, in the order of SPEC §9.2 (onboarding is /onboarding)
  {
    path: 'change-password',
    canActivate: [setupStepGuard('password')],
    loadComponent: () => import('./change-password.page').then((m) => m.ChangePasswordPage),
    title: 'pageTitles.changePassword',
  },
  {
    path: 'recovery-pin',
    canActivate: [setupStepGuard('pin')],
    loadComponent: () => import('./set-recovery-pin.page').then((m) => m.SetRecoveryPinPage),
    title: 'pageTitles.recoveryPin',
  },
  {
    path: 'complete-profile',
    canActivate: [setupStepGuard('profile')],
    loadComponent: () => import('./complete-profile.page').then((m) => m.CompleteProfilePage),
    title: 'pageTitles.completeProfile',
  },
] satisfies Routes;
