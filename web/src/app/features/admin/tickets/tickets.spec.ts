import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { AdminSummaryStore } from '../../../core/admin/admin-summary.store';
import { renderAdmin, testAdminTicket, testPage, testTicketRow } from '../../../../testing/admin-testing';
import { testMe } from '../../../../testing/auth-testing';
import { TEST_API, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { AdminTicketPage } from './ticket.page';
import { AdminTicketsPage } from './tickets.page';

const params = (req: TestRequest) => Object.fromEntries(req.request.params.keys().map((k) => [k, req.request.params.get(k)]));

describe('Admin console: Tickets (F35)', () => {
  let http: HttpTestingController;
  let refresh: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    TestBed.resetTestingModule();
    refresh = vi.fn(() => Promise.resolve());
    const testing = setupSocialTesting({ providers: [{ provide: AdminSummaryStore, useValue: { refresh } }] });
    http = testing.http;
    testing.session.setMe(testMe({ permissions: ['admin.access', 'support.manage', 'users.read', 'moderation.manage'] }));
    URL.createObjectURL = vi.fn(() => 'blob:http://localhost/att');
    URL.revokeObjectURL = vi.fn();
  });

  afterEach(() => http.verify());

  it('the queue: Open by default (waiting longest first), with category and search from the URL', async () => {
    const t = renderAdmin(AdminTicketsPage, { category: 'account', q: '#12', status: 'nope' });
    const req = http.expectOne((r) => r.url === `${TEST_API}/admin/support/tickets`);
    expect(params(req)).toEqual({ status: 'open', category: 'account', q: '#12', page: '1', pageSize: '50' });
    req.flush(testPage([testTicketRow(), testTicketRow({ id: 't2', number: 13, lastMessage: { fromSupport: true, isInternalNote: true, excerpt: 'Asked the dev team', createdAt: '2026-11-07T09:00:00Z' } })]));
    await t.stable();
    expect(t.$('[data-admin-ticket="t1"]')!.getAttribute('href')).toBe('/admin/tickets/t1');
    expect(t.$('[data-admin-ticket="t1"] [data-ticket-when]')!.textContent).toContain('تنتظر');
    expect(t.$('[data-admin-ticket="t2"]')!.textContent).toContain('ملاحظة داخلية');
    expect(t.$('[data-ticket-tab="open"]')!.getAttribute('aria-current')).toBe('page');
  });

  async function ticket(data = testAdminTicket()) {
    const t = renderAdmin(AdminTicketPage, { id: data.id });
    http.expectOne(`${TEST_API}/admin/support/tickets/${data.id}`).flush(data);
    await t.stable();
    for (const req of http.match((r) => r.url.startsWith(`${TEST_API}/support/attachments/`))) req.flush(new Blob(['x'], { type: 'image/png' }));
    await t.stable();
    return t;
  }

  it('the ticket: conversation, member card linking to their console page, device details', async () => {
    const t = await ticket();
    expect(t.$('[data-member-link]')!.getAttribute('href')).toBe('/admin/users/u-salma');
    expect(t.$('[data-ticket-device]')!.textContent).toContain('Android 15');
    expect(t.$('[data-message="m1"]')!.getAttribute('data-kind')).toBe('member');
    expect(t.$('[data-attachment="att-1"]')).not.toBeNull();
  });

  it('a reply makes it Answered; an internal note shows apart and changes nothing', async () => {
    const t = await ticket();
    t.type('[data-admin-reply-text]', 'Please update to 1.2.1.');
    t.$('[data-admin-reply-send]')!.click();
    const reply = http.expectOne({ method: 'POST', url: `${TEST_API}/admin/support/tickets/t1/messages` });
    expect(reply.request.body).toEqual({ body: 'Please update to 1.2.1.', internal: false });
    reply.flush(
      { id: 'm2', fromSupport: true, isInternalNote: false, body: 'Please update to 1.2.1.', attachments: [], createdAt: '2026-11-07T10:00:00Z', author: { id: 'admin', displayName: 'Youssef', username: 'readin_admin' } },
      { status: 201, statusText: 'Created' },
    );
    await t.stable();
    expect(t.$('[data-ticket-status]')!.getAttribute('data-ticket-status')).toBe('answered');
    expect(refresh).toHaveBeenCalled();

    t.$('[data-mode="note"]')!.click();
    await t.stable();
    t.type('[data-admin-reply-text]', 'Known crash on Android 15.');
    t.$('[data-admin-reply-send]')!.click();
    const note = http.expectOne(`${TEST_API}/admin/support/tickets/t1/messages`);
    expect(note.request.body).toEqual({ body: 'Known crash on Android 15.', internal: true });
    note.flush(
      { id: 'm3', fromSupport: true, isInternalNote: true, body: 'Known crash on Android 15.', attachments: [], createdAt: '2026-11-07T10:05:00Z', author: { id: 'admin', displayName: 'Youssef', username: 'readin_admin' } },
      { status: 201, statusText: 'Created' },
    );
    await t.stable();
    expect(t.$('[data-message="m3"]')!.getAttribute('data-kind')).toBe('note');
    expect(t.$('[data-message="m3"] [data-note-tag]')).not.toBeNull();
    expect(t.$('[data-ticket-status]')!.getAttribute('data-ticket-status')).toBe('answered');
  });

  it('changes the category, and closes after a dialog; a closed ticket takes notes but no reply until reopened', async () => {
    const t = await ticket();
    t.type('[data-ticket-category]', 'account', 'change');
    const patch = http.expectOne({ method: 'PATCH', url: `${TEST_API}/admin/support/tickets/t1` });
    expect(patch.request.body).toEqual({ category: 'account' });
    patch.flush(testAdminTicket({ category: 'account' }));
    await t.stable();

    t.$('[data-ticket-close]')!.click();
    await t.stable();
    t.$('[data-confirm-ok]')!.click();
    const close = http.expectOne({ method: 'PATCH', url: `${TEST_API}/admin/support/tickets/t1` });
    expect(close.request.body).toEqual({ status: 'closed' });
    close.flush(testAdminTicket({ status: 'closed', closedBy: 'support', closedAt: '2026-11-07T12:00:00Z', waitingSince: null }));
    await t.stable();
    expect(t.$('[data-admin-confirm]')).toBeNull();
    expect(t.$('[data-reopen-first]')).not.toBeNull();
    t.type('[data-admin-reply-text]', 'Hello');
    expect(t.$<HTMLButtonElement>('[data-admin-reply-send]')!.disabled).toBe(true);
    t.$('[data-mode="note"]')!.click();
    await t.stable();
    expect(t.$<HTMLButtonElement>('[data-admin-reply-send]')!.disabled).toBe(false);

    t.$('[data-ticket-reopen]')!.click();
    http.expectOne({ method: 'PATCH', url: `${TEST_API}/admin/support/tickets/t1` }).flush(testAdminTicket());
    await t.stable();
  });

  it('an unknown ticket is "not found"', async () => {
    const t = renderAdmin(AdminTicketPage, { id: 'gone' });
    http.expectOne(`${TEST_API}/admin/support/tickets/gone`).flush(problem(404, 'support.ticket_not_found'), { status: 404, statusText: 'Not Found' });
    await t.stable();
    expect(t.$('[data-ticket-not-found]')).not.toBeNull();
  });
});
