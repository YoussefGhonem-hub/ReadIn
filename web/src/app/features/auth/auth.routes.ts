import { Routes } from '@angular/router';
import { guestOnlyGuard, setupStepGuard } from '../../core/auth/guards';

/** Auth screens (SPEC §9.2). All of them render in the browser only (app.routes.server.ts). */
export default [
  // Guests
  { path: '', pathMatch: 'full', canActivate: [guestOnlyGuard], loadComponent: () => import('./welcome.page').then((m) => m.WelcomePage), title: 'ReadIn' },
  { path: 'sign-in', canActivate: [guestOnlyGuard], loadComponent: () => import('./sign-in.page').then((m) => m.SignInPage), title: 'ReadIn' },
  { path: 'sign-up', canActivate: [guestOnlyGuard], loadComponent: () => import('./sign-up.page').then((m) => m.SignUpPage), title: 'ReadIn' },
  {
    path: 'forgot-password',
    canActivate: [guestOnlyGuard],
    loadComponent: () => import('./forgot-password.page').then((m) => m.ForgotPasswordPage),
    title: 'ReadIn',
  },
  // Mandatory steps for signed-in accounts, in the order of SPEC §9.2 (onboarding is /onboarding)
  {
    path: 'change-password',
    canActivate: [setupStepGuard('password')],
    loadComponent: () => import('./change-password.page').then((m) => m.ChangePasswordPage),
    title: 'ReadIn',
  },
  {
    path: 'recovery-pin',
    canActivate: [setupStepGuard('pin')],
    loadComponent: () => import('./set-recovery-pin.page').then((m) => m.SetRecoveryPinPage),
    title: 'ReadIn',
  },
  {
    path: 'complete-profile',
    canActivate: [setupStepGuard('profile')],
    loadComponent: () => import('./complete-profile.page').then((m) => m.CompleteProfilePage),
    title: 'ReadIn',
  },
] satisfies Routes;
