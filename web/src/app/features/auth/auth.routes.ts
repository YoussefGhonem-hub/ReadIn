import { Routes } from '@angular/router';

export default [
  { path: '', pathMatch: 'full', redirectTo: 'sign-in' },
  { path: 'sign-in', loadComponent: () => import('./sign-in.page').then((m) => m.SignInPage), title: 'ReadIn' },
  { path: 'sign-up', loadComponent: () => import('./sign-up.page').then((m) => m.SignUpPage), title: 'ReadIn' },
  { path: 'forgot-password', loadComponent: () => import('./forgot-password.page').then((m) => m.ForgotPasswordPage), title: 'ReadIn' },
] satisfies Routes;
