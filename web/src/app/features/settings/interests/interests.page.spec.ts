import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { testMe } from '../../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { FieldDto, InterestsDto, MeDto, TopicDto } from '../../../core/api/models';
import { AuthService } from '../../../core/auth/auth.service';
import { SessionStore } from '../../../core/auth/session.store';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { InterestsPage } from './interests.page';

function field(id: string, slug: string, nameAr: string, nameEn: string, topicCount = 0): FieldDto {
  return { id, slug, name: nameEn, nameAr, nameEn, icon: 'code', color: 'primary', isSensitive: false, requiresSources: false, topicCount };
}

const FIELDS = [field('f-software', 'software', 'البرمجيات', 'Software', 2), field('f-medicine', 'medicine', 'الطب', 'Medicine'), field('f-ai', 'ai', 'الذكاء الاصطناعي', 'AI', 1)];
const TOPICS: Record<string, TopicDto[]> = {
  software: [
    { id: 't-dotnet', fieldId: 'f-software', slug: 'dotnet', name: '.NET', nameAr: '.NET', nameEn: '.NET' },
    { id: 't-architecture', fieldId: 'f-software', slug: 'architecture', name: 'Architecture', nameAr: 'المعمارية', nameEn: 'Architecture' },
  ],
  ai: [{ id: 't-llm', fieldId: 'f-ai', slug: 'llm', name: 'LLMs', nameAr: 'LLMs', nameEn: 'LLMs' }],
};

describe('InterestsPage (F12: following fields and topics after onboarding)', () => {
  let http: HttpTestingController;
  let session: SessionStore;
  let refreshMe: ReturnType<typeof vi.fn>;
  /** What `GET /me` answers (the page starts from a fresh copy). */
  let fresh: MeDto;

  beforeEach(() => {
    TestBed.resetTestingModule();
    fresh = testMe({ interests: { fieldIds: ['f-software'], topicIds: ['t-dotnet', 't-architecture'] } });
    refreshMe = vi.fn(async () => {
      session.setMe(fresh);
      return fresh;
    });
    ({ http, session } = setupSocialTesting({ providers: [{ provide: AuthService, useValue: { refreshMe } }] }));
    // The session from sign in is older: it doesn't know the topics yet.
    session.setMe(testMe({ interests: { fieldIds: ['f-software'], topicIds: [] } }));
  });

  afterEach(() => http.verify());

  async function render() {
    const fixture = TestBed.createComponent(InterestsPage);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
    };
    http.expectOne(`${TEST_API}/fields`).flush(FIELDS);
    await stable();
    http.expectOne(`${TEST_API}/fields/software/topics`).flush(TOPICS['software']);
    await stable();
    const fieldChip = (id: string) => root.querySelector<HTMLButtonElement>(`[data-interest-field="${id}"]`)!;
    const topicChip = (id: string) => root.querySelector<HTMLButtonElement>(`[data-interest-topic="${id}"]`);
    const pressed = (chip: HTMLElement | null) => chip?.getAttribute('aria-pressed');
    const count = () => root.querySelector('[data-interest-count]')!.textContent!.trim();
    const call = (method: 'PUT' | 'DELETE', path: string): TestRequest => http.expectOne({ method, url: `${TEST_API}/me/interests/${path}` });
    return { fixture, root, stable, fieldChip, topicChip, pressed, count, call };
  }

  const saved = (interests: InterestsDto) => interests;

  it('starts from a fresh GET /me: the field chips as onboarding, with the topics of the fields you follow', async () => {
    const { root, fieldChip, topicChip, pressed, count } = await render();
    expect(refreshMe).toHaveBeenCalledOnce();
    expect(root.querySelector('h1')!.textContent).toContain('اهتماماتك');
    expect([...root.querySelectorAll('[data-interest-field]')].map((b) => b.textContent!.trim())).toEqual(['البرمجيات', 'الطب', 'الذكاء الاصطناعي']);
    expect(pressed(fieldChip('f-software'))).toBe('true');
    expect(pressed(fieldChip('f-medicine'))).toBe('false');
    expect(pressed(topicChip('t-dotnet'))).toBe('true');
    expect(pressed(topicChip('t-architecture'))).toBe('true');
    expect(root.textContent).toContain('مواضيع في البرمجيات');
    // AI isn't followed: its topics aren't listed (nor loaded).
    expect(topicChip('t-llm')).toBeNull();
    expect(count()).toBe('تتابع 3 اهتمامات');
  });

  it('a tap is shown at once and saved; the session follows what the API answers', async () => {
    const { fieldChip, topicChip, pressed, stable, call, count } = await render();
    fieldChip('f-ai').click();
    await stable();
    // Shown before the API answers; the field's topics load.
    expect(pressed(fieldChip('f-ai'))).toBe('true');
    expect(fieldChip('f-ai').getAttribute('aria-busy')).toBe('true');
    expect(count()).toBe('تتابع 4 اهتمامات');
    const put = call('PUT', 'fields/f-ai');
    http.expectOne(`${TEST_API}/fields/ai/topics`).flush(TOPICS['ai']);
    put.flush(saved({ fieldIds: ['f-software', 'f-ai'], topicIds: ['t-dotnet', 't-architecture'] }));
    await stable();
    expect(fieldChip('f-ai').hasAttribute('aria-busy')).toBe(false);
    expect(session.me()!.interests).toEqual({ fieldIds: ['f-software', 'f-ai'], topicIds: ['t-dotnet', 't-architecture'] });
    expect(pressed(topicChip('t-llm'))).toBe('false');

    topicChip('t-dotnet')!.click();
    await stable();
    expect(pressed(topicChip('t-dotnet'))).toBe('false');
    call('DELETE', 'topics/t-dotnet').flush(saved({ fieldIds: ['f-software', 'f-ai'], topicIds: ['t-architecture'] }));
    await stable();
    expect(session.me()!.interests).toEqual({ fieldIds: ['f-software', 'f-ai'], topicIds: ['t-architecture'] });
    expect(count()).toBe('تتابع 3 اهتمامات');
  });

  it('keeps at least 3: the refusal undoes the tap and says so', async () => {
    const { topicChip, pressed, stable, call, count } = await render();
    topicChip('t-architecture')!.click();
    await stable();
    expect(pressed(topicChip('t-architecture'))).toBe('false');
    call('DELETE', 'topics/t-architecture').flush(problem(400, 'user.interests.min_three'), { status: 400, statusText: 'Bad Request' });
    await stable();
    expect(pressed(topicChip('t-architecture'))).toBe('true');
    expect(count()).toBe('تتابع 3 اهتمامات');
    expect(session.me()!.interests.topicIds).toEqual(['t-dotnet', 't-architecture']);
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'error', message: 'احتفظ بـ 3 اهتمامات على الأقل' })]);
    expect(TestBed.inject(TranslocoService).translate('settings.interests.minThree', {}, 'en')).toBe('Keep at least 3 interests');
  });

  it('other failures undo the tap too, with their own message', async () => {
    const { fieldChip, pressed, stable, call } = await render();
    fieldChip('f-medicine').click();
    await stable();
    call('PUT', 'fields/f-medicine').flush(problem(404, 'field.not_found'), { status: 404, statusText: 'Not Found' });
    await stable();
    expect(pressed(fieldChip('f-medicine'))).toBe('false');
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'error', message: 'هذا المجال غير موجود.' })]);
  });

  it('a second tap on a chip being saved waits for the first', async () => {
    const { fieldChip, stable, call } = await render();
    fieldChip('f-medicine').click();
    await stable();
    fieldChip('f-medicine').click();
    await stable();
    call('PUT', 'fields/f-medicine').flush(saved({ fieldIds: ['f-software', 'f-medicine'], topicIds: ['t-dotnet', 't-architecture'] }));
    await stable();
    // verify() in afterEach: no second request.
  });

  it('lists a followed topic of a field you don’t follow, so it can be unfollowed', async () => {
    fresh = testMe({ interests: { fieldIds: ['f-software', 'f-medicine'], topicIds: ['t-dotnet', 't-llm'] } });
    const { topicChip, pressed, stable, root } = await render();
    // t-llm isn't among Software's topics: every field's topics load.
    http.expectOne(`${TEST_API}/fields/ai/topics`).flush(TOPICS['ai']);
    await stable();
    expect(pressed(topicChip('t-llm'))).toBe('true');
    expect(root.textContent).toContain('مواضيع في الذكاء الاصطناعي');
  });

  it('a failed load offers a retry', async () => {
    const fixture = TestBed.createComponent(InterestsPage);
    fixture.detectChanges();
    http.expectOne(`${TEST_API}/fields`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    await flushMicrotasks();
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    expect(root.querySelector('rd-error-state')).not.toBeNull();
    root.querySelector<HTMLButtonElement>('rd-error-state button')!.click();
    fixture.detectChanges();
    http.expectOne(`${TEST_API}/fields`).flush(FIELDS);
    await flushMicrotasks();
    fixture.detectChanges();
    http.expectOne(`${TEST_API}/fields/software/topics`).flush(TOPICS['software']);
    await flushMicrotasks();
    fixture.detectChanges();
    expect(root.querySelectorAll('[data-interest-field]')).toHaveLength(3);
  });
});
