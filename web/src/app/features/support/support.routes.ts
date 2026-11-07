import { Routes } from '@angular/router';
import { authGuard } from '../../core/auth/guards';

/**
 * Help & support (F35): `/support`, public and server-rendered (the App Store support URL), with the new-ticket form for
 * members; `/support/tickets` (My tickets) and `/support/tickets/{id}` (a ticket, where `readin://support/{id}` lands),
 * signed in only and rendered in the browser (app.routes.server.ts). Titles are i18n keys.
 */
export default [
  { path: '', pathMatch: 'full', title: 'support.title', loadComponent: () => import('./support.page').then((m) => m.SupportPage) },
  { path: 'tickets', canActivate: [authGuard], title: 'support.myTickets', loadComponent: () => import('./my-tickets.page').then((m) => m.MyTicketsPage) },
  { path: 'tickets/:id', canActivate: [authGuard], loadComponent: () => import('./ticket.page').then((m) => m.TicketPage) },
] satisfies Routes;
