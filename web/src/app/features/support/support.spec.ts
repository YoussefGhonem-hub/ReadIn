import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { renderAdmin, testTicket } from '../../../testing/admin-testing';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { SupportConfigDto, SupportTicketSummaryDto } from '../../core/api/models';
import { MyTicketsPage } from './my-tickets.page';
import { NewTicketForm } from './new-ticket-form';
import { SupportPage } from './support.page';
import { ScreenshotPicker, browserSummary, checkScreenshot, imageKind, webDevice } from './support-ui';
import { TicketPage } from './ticket.page';

const CONFIG: SupportConfigDto = {
  email: 'support@readin.online',
  categories: ['app_problem', 'account', 'content', 'verification', 'suggestion', 'other'],
  maxAttachments: 3,
  maxAttachmentBytes: 5 * 1024 * 1024,
  attachmentTypes: ['image/jpeg', 'image/png', 'image/webp'],
};
const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0]);
const png = (name = 'shot.png', bytes = PNG) => new File([bytes], name, { type: 'image/png' });

function summary(id: string, patch: Partial<SupportTicketSummaryDto> = {}): SupportTicketSummaryDto {
  const ticket: Partial<ReturnType<typeof testTicket>> = testTicket({ id, ...patch });
  delete ticket.device;
  delete ticket.messages;
  return ticket as SupportTicketSummaryDto;
}

describe('Help & support (F35)', () => {
  let http: HttpTestingController;

  afterEach(() => http?.verify());

  describe('helpers', () => {
    it('recognizes JPEG, PNG and WebP by their bytes only', async () => {
      expect(imageKind(new Uint8Array([0xff, 0xd8, 0xff, 0xe0]))).toBe('image/jpeg');
      expect(imageKind(PNG)).toBe('image/png');
      expect(imageKind(new Uint8Array([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x45, 0x42, 0x50]))).toBe('image/webp');
      expect(imageKind(new Uint8Array([0x25, 0x50, 0x44, 0x46]))).toBeNull(); // %PDF
      expect(await checkScreenshot(png())).toBeNull();
      expect(await checkScreenshot(new File([new Uint8Array([0x25, 0x50, 0x44, 0x46])], 'fake.png', { type: 'image/png' }))).toBe('type');
      expect(await checkScreenshot(new File([], 'empty.png'))).toBe('empty');
      expect(await checkScreenshot(png(), 4)).toBe('size');
    });

    it('sums up the browser and system without a device identifier', () => {
      expect(browserSummary('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36')).toBe('Windows · Chrome 131');
      expect(browserSummary('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0')).toBe('Windows · Edge 131');
      expect(browserSummary('Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Mobile/15E148 Safari/604.1')).toBe('iOS 18.1 · Safari 18.1');
      expect(browserSummary('Mozilla/5.0 (Linux; Android 15; SM-S921B) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/27.0 Chrome/125.0.0.0 Mobile Safari/537.36')).toBe(
        'Android 15 · Samsung Internet 27',
      );
      expect(webDevice('ar', '/settings?x=1', 'Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0')).toEqual({
        platform: 'web',
        osVersion: 'Linux · Firefox 133',
        language: 'ar',
        screen: '/settings',
      });
    });
  });

  describe('/support', () => {
    it('guests see the email and "Sign in to send a ticket"', async () => {
      TestBed.resetTestingModule();
      ({ http } = setupSocialTesting({ guest: true }));
      const t = renderAdmin(SupportPage);
      http.expectOne(`${TEST_API}/support/config`).flush(CONFIG);
      await t.stable();
      expect(t.$('[data-support-email] a')!.getAttribute('href')).toBe('mailto:support@readin.online');
      expect(t.$('[data-support-sign-in]')!.getAttribute('href')).toBe('/auth/sign-in?returnUrl=%2Fsupport');
      expect(t.$('[data-new-ticket]')).toBeNull();
    });

    it('members see the form and "My tickets"; no email when the API has none', async () => {
      TestBed.resetTestingModule();
      ({ http } = setupSocialTesting());
      const t = renderAdmin(SupportPage);
      http.expectOne(`${TEST_API}/support/config`).flush({ ...CONFIG, email: null });
      await t.stable();
      expect(t.$('[data-support-email]')).toBeNull();
      expect(t.$('[data-new-ticket]')).not.toBeNull();
      expect(t.$('[data-my-tickets]')!.getAttribute('href')).toBe('/support/tickets');
    });
  });

  describe('a new ticket', () => {
    async function form() {
      TestBed.resetTestingModule();
      ({ http } = setupSocialTesting());
      const navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
      const t = renderAdmin(NewTicketForm, { config: CONFIG, screen: '/settings' });
      await t.stable();
      return { t, navigate };
    }

    it('needs a category, a subject of 5–120 and a message of 10–2000; sends multipart with the device details', async () => {
      const { t, navigate } = await form();
      const send = t.$<HTMLButtonElement>('[data-ticket-send]')!;
      t.type('[data-ticket-category]', 'app_problem', 'change');
      t.type('[data-ticket-subject]', 'Bug');
      t.type('[data-ticket-message]', 'It crashes when I open a path.');
      expect(send.disabled).toBe(true);
      t.type('[data-ticket-subject]', '  The app closes  ');
      expect(send.disabled).toBe(false);

      t.$<HTMLFormElement>('[data-new-ticket]')!.dispatchEvent(new Event('submit'));
      const req = http.expectOne({ method: 'POST', url: `${TEST_API}/support/tickets` });
      const body = req.request.body as FormData;
      expect(body.get('category')).toBe('app_problem');
      expect(body.get('subject')).toBe('The app closes');
      expect(body.get('platform')).toBe('web');
      expect(body.get('language')).toBe('ar');
      expect(body.get('screen')).toBe('/settings');
      expect(body.get('appVersion')).toBeNull();
      expect(body.getAll('screenshots')).toEqual([]);
      req.flush(testTicket({ id: 't9', number: 9 }), { status: 201, statusText: 'Created' });
      await t.stable();
      expect(navigate).toHaveBeenCalledWith(['/support/tickets', 't9']);
    });

    it('says which limit was reached (429 support.limit)', async () => {
      const { t } = await form();
      t.type('[data-ticket-category]', 'other', 'change');
      t.type('[data-ticket-subject]', 'Question');
      t.type('[data-ticket-message]', 'How do I change my name?');
      t.$<HTMLFormElement>('[data-new-ticket]')!.dispatchEvent(new Event('submit'));
      http.expectOne(`${TEST_API}/support/tickets`).flush({ ...problem(429, 'support.limit'), limit: 'open' }, { status: 429, statusText: 'Too Many Requests' });
      await t.stable();
      expect(t.$('[data-ticket-error]')!.textContent).toContain('10 تذاكر مفتوحة');
    });
  });

  describe('screenshots', () => {
    it('takes up to 3 images and names a file that is not one', async () => {
      TestBed.resetTestingModule();
      ({ http } = setupSocialTesting());
      const t = renderAdmin(ScreenshotPicker);
      const emitted: File[][] = [];
      t.fixture.componentInstance.filesChange.subscribe((files) => {
        emitted.push(files);
        t.fixture.componentRef.setInput('files', files);
      });
      const input = t.$<HTMLInputElement>('[data-screenshot-input]')!;
      const pick = async (files: File[]) => {
        Object.defineProperty(input, 'files', { configurable: true, value: files });
        input.dispatchEvent(new Event('change'));
        for (let i = 0; i < 5; i++) await flushMicrotasks();
        await new Promise((resolve) => setTimeout(resolve, 0));
        await t.stable();
      };
      await pick([png('a.png'), new File([new Uint8Array([1, 2, 3])], 'notes.txt', { type: 'image/png' })]);
      expect(emitted.at(-1)!.map((f) => f.name)).toEqual(['a.png']);
      expect(t.$('[data-screenshot-error]')!.textContent).toContain('notes.txt');
      await pick([png('b.png'), png('c.png'), png('d.png')]);
      expect(emitted.at(-1)!.map((f) => f.name)).toEqual(['a.png', 'b.png', 'c.png']);
      expect(t.$('[data-screenshot-input]')).toBeNull();
    });
  });

  describe('my tickets and a ticket', () => {
    beforeEach(() => {
      TestBed.resetTestingModule();
      const testing = setupSocialTesting();
      http = testing.http;
      testing.session.setMe(testMe());
      URL.createObjectURL = vi.fn(() => 'blob:http://localhost/shot-1');
      URL.revokeObjectURL = vi.fn();
    });

    it('lists your tickets by tab, latest activity first', async () => {
      const t = renderAdmin(MyTicketsPage, { status: 'closed' });
      const req = http.expectOne((r) => r.url === `${TEST_API}/me/support/tickets`);
      expect(req.request.params.get('status')).toBe('closed');
      req.flush({ items: [summary('t1', { status: 'closed' })], nextCursor: null });
      await t.stable();
      expect(t.$('[data-ticket="t1"]')!.getAttribute('href')).toBe('/support/tickets/t1');
      expect(t.$('[data-ticket-tab="closed"]')!.getAttribute('aria-current')).toBe('page');
    });

    async function ticket(data = testTicket()) {
      const t = renderAdmin(TicketPage, { id: data.id });
      http.expectOne(`${TEST_API}/support/tickets/${data.id}`).flush(data);
      await t.stable();
      // Screenshots come through the authenticated route.
      for (const req of http.match((r) => r.url.startsWith(`${TEST_API}/support/attachments/`))) req.flush(new Blob([PNG], { type: 'image/png' }));
      await t.stable();
      return t;
    }

    it("the conversation: support as «فريق الدعم», the member's screenshots as private blobs; a reply moves it to Open", async () => {
      const t = await ticket();
      const messages = t.$$('[data-message]');
      expect(messages.map((m) => m.getAttribute('data-from'))).toEqual(['member', 'support']);
      expect(messages[1].textContent).toContain('فريق الدعم');
      expect(t.$('[data-attachment="att-1"]')!.getAttribute('href')).toBe('blob:http://localhost/shot-1');

      t.type('[data-reply-text]', 'Updated, still closes.');
      t.$<HTMLFormElement>('[data-reply]')!.dispatchEvent(new Event('submit'));
      const req = http.expectOne({ method: 'POST', url: `${TEST_API}/support/tickets/t1/messages` });
      expect((req.request.body as FormData).get('message')).toBe('Updated, still closes.');
      req.flush({ id: 'm3', fromSupport: false, body: 'Updated, still closes.', attachments: [], createdAt: '2026-11-07T11:00:00Z' }, { status: 201, statusText: 'Created' });
      await t.stable();
      expect(t.$$('[data-message]').length).toBe(3);
      expect(t.$('[data-ticket-status]')!.getAttribute('data-ticket-status')).toBe('open');
    });

    it('a closed ticket reopens within 30 days; after that it offers a new ticket', async () => {
      const t = await ticket(testTicket({ status: 'closed', closedAt: '2026-11-07T12:00:00Z', canReopen: true }));
      expect(t.$('[data-reply]')).toBeNull();
      t.$('[data-ticket-reopen]')!.click();
      http.expectOne({ method: 'POST', url: `${TEST_API}/support/tickets/t1/reopen` }).flush(problem(409, 'support.reopen_expired'), { status: 409, statusText: 'Conflict' });
      await t.stable();
      expect(t.$('[data-reply-error]')!.textContent).toContain('30 يومًا');

      const old = await ticket(testTicket({ id: 't2', status: 'closed', closedAt: '2026-09-01T12:00:00Z', canReopen: false }));
      expect(old.$('[data-ticket-reopen]')).toBeNull();
      expect(old.$('[data-ticket-new]')!.getAttribute('href')).toBe('/support');
    });

    it('close asks first', async () => {
      const t = await ticket();
      t.$('[data-ticket-close]')!.click();
      await t.stable();
      t.$('[data-close-confirm]')!.click();
      http.expectOne({ method: 'POST', url: `${TEST_API}/support/tickets/t1/close` }).flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      http.expectOne(`${TEST_API}/support/tickets/t1`).flush(testTicket({ status: 'closed', canReopen: true, closedAt: '2026-11-07T12:00:00Z' }));
      await t.stable();
      expect(t.$('[data-ticket-closed]')).not.toBeNull();
    });

    it('someone else\'s ticket is "not found"', async () => {
      const t = renderAdmin(TicketPage, { id: 'other' });
      http.expectOne(`${TEST_API}/support/tickets/other`).flush(problem(404, 'support.ticket_not_found'), { status: 404, statusText: 'Not Found' });
      await t.stable();
      expect(t.$('[data-ticket-not-found]')!.textContent).toContain('التذكرة غير موجودة');
    });
  });
});
