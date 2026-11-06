import { TestBed } from '@angular/core/testing';
import { HttpResponse } from '@angular/common/http';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { of } from 'rxjs';
import { TEST_FIELDS, testProfile } from '../../../testing/profile-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ApiError } from '../../core/api/api.config';
import { MediaApi } from '../../core/api/media.api';
import { MediaAssetDto } from '../../core/api/models';
import { AuthService } from '../../core/auth/auth.service';
import { ImageCompressor } from '../../shared/media/image-compressor';
import { USERNAME_DEBOUNCE_MS } from '../../shared/utils/username';
import { EditProfilePage, linkFieldErrors, profileFieldErrors } from './edit-profile.page';
import { ExpertisePicker, MAX_EXPERTISE, toggleExpertise } from './expertise-picker';

const AVATAR: MediaAssetDto = {
  id: 'asset-9',
  kind: 'image',
  purpose: 'avatar',
  status: 'ready',
  failureReason: null,
  width: 512,
  height: 512,
  blurHash: null,
  sizeBytes: 20_000,
  variants: [64, 128, 256, 512].map((w) => ({ width: w, height: w, url: `https://cdn.test/a_${w}.webp`, bytes: w * 40 })),
  title: null,
  pageCount: null,
  pagesReady: 0,
  pages: [],
  allowDownload: false,
  createdAt: '2026-11-03T08:00:00Z',
};

/** Mona edits her own profile (the session is `testMe()`, @mona). */
const MINE = testProfile({
  id: 'user-1',
  displayName: 'Mona Adel',
  username: 'mona',
  avatarUrl: 'https://cdn.test/old_256.webp',
  bio: 'Backend engineer.',
  headline: 'Backend engineer | .NET',
  links: [{ platform: 'github', url: 'https://github.com/mona', label: null }],
  expertise: [{ id: 'f1', slug: 'software', name: 'Software', icon: 'code', color: 'primary' }],
  isMe: true,
  followsYou: false,
});

describe('EditProfilePage (F14)', () => {
  let http: HttpTestingController;
  let refreshMe: ReturnType<typeof vi.fn>;
  let navigate: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    TestBed.resetTestingModule();
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout', 'setInterval', 'clearInterval'] });
    refreshMe = vi.fn(async () => null);
    ({ http } = setupSocialTesting({
      providers: [
        { provide: AuthService, useValue: { refreshMe } },
        { provide: ImageCompressor, useValue: { compress: vi.fn(async (file: File) => file) } },
        { provide: MediaApi, useValue: { uploadImage: vi.fn(() => of(new HttpResponse({ status: 201, body: AVATAR }))) } },
      ],
    }));
    navigate = vi.spyOn(TestBed.inject(Router), 'navigateByUrl').mockResolvedValue(true);
  });

  afterEach(() => {
    vi.useRealTimers();
    http.verify();
  });

  async function render() {
    const fixture = TestBed.createComponent(EditProfilePage);
    fixture.detectChanges();
    http.expectOne(`${TEST_API}/users/mona`).flush(MINE);
    http.expectOne(`${TEST_API}/fields`).flush(TEST_FIELDS);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
    };
    await stable();
    /** Answers the debounced availability check for the current handle. */
    const checkUsername = async (available = true) => {
      vi.advanceTimersByTime(USERNAME_DEBOUNCE_MS);
      const req = http.expectOne((r) => r.url === `${TEST_API}/users/username-available`);
      req.flush({ username: req.request.params.get('u'), valid: true, available });
      await stable();
    };
    await checkUsername();
    const input = (selector: string) => root.querySelector<HTMLInputElement | HTMLTextAreaElement>(selector)!;
    const type = async (selector: string, value: string) => {
      const el = input(selector);
      el.value = value;
      el.dispatchEvent(new Event('input'));
      await stable();
    };
    const submit = async () => {
      root.querySelector<HTMLFormElement>('[data-edit-profile-form]')!.dispatchEvent(new Event('submit'));
      await stable();
    };
    const patch = (): TestRequest => http.expectOne((r) => r.method === 'PATCH' && r.url === `${TEST_API}/me`);
    return { fixture, root, stable, checkUsername, input, type, submit, patch };
  }

  it('starts from your public profile: name, @username, title, bio with its counter, links, expertise', async () => {
    const { root, input } = await render();
    expect(input('#edit-name').value).toBe('Mona Adel');
    expect(input('#edit-username').value).toBe('mona');
    expect(input('#edit-headline').value).toBe('Backend engineer | .NET');
    expect(input('#edit-headline').getAttribute('dir')).toBe('auto');
    // Far from the limit: no counter yet.
    expect(root.querySelector('[data-headline-count]')).toBeNull();
    expect(input('#edit-bio').value).toBe('Backend engineer.');
    expect(root.querySelector('[data-bio-count]')!.textContent!.trim()).toBe('17 / 300');
    expect([...root.querySelectorAll('[data-link-row]')].map((r) => r.getAttribute('data-platform'))).toEqual(['github']);
    expect(input('[data-link-row="0"] [data-link-url]').value).toBe('https://github.com/mona');
    expect(root.querySelector('[data-expertise="software"]')!.getAttribute('aria-pressed')).toBe('true');
    expect(root.querySelector('[data-avatar-preview] img')!.getAttribute('src')).toBe('https://cdn.test/old_256.webp');
    // Your own handle is fine: no "available" success message for it.
    expect(root.querySelector('[data-username-status]')!.textContent).toContain('من 3 إلى 30 حرفًا');
  });

  it('saves without touching the photo: avatarAssetId left out, the title trimmed, the whole link list in order', async () => {
    const { root, type, submit, patch, stable } = await render();
    await type('#edit-headline', '  Senior .NET Engineer  ');
    // Add LinkedIn, typed without https://, then move it first.
    (root.querySelector('[data-add-link]') as HTMLElement).click();
    await stable();
    (root.querySelector('[data-pick-platform="linkedin"]') as HTMLElement).click();
    await stable();
    await type('[data-link-row="1"] [data-link-url]', 'linkedin.com/in/mona');
    (root.querySelector('[data-link-row="1"] [data-link-up]') as HTMLElement).click();
    await stable();
    (root.querySelector('[data-expertise="medicine"]') as HTMLElement).click();
    await stable();
    await submit();
    const req = patch();
    expect(req.request.body).toEqual({
      displayName: 'Mona Adel',
      username: 'mona',
      headline: 'Senior .NET Engineer',
      bio: 'Backend engineer.',
      links: [
        { platform: 'linkedin', url: 'https://linkedin.com/in/mona' },
        { platform: 'github', url: 'https://github.com/mona' },
      ],
      expertiseFieldIds: ['f1', 'f2'],
    });
    // The link is shown as it was sent.
    expect((root.querySelector('[data-link-row="0"] [data-link-url]') as HTMLInputElement).value).toBe('https://linkedin.com/in/mona');
    expect('avatarAssetId' in req.request.body).toBe(false);
    expect('avatarUrl' in req.request.body).toBe(false);
    req.flush(null, { status: 204, statusText: 'No Content' });
    await stable();
    expect(refreshMe).toHaveBeenCalledOnce();
    expect(navigate).toHaveBeenCalledWith('/@mona');
  });

  it('a new photo is uploaded as an avatar, previewed at 256 px and sent by id; Remove sends null', async () => {
    const { root, submit, patch, stable } = await render();
    const file = new File([new Uint8Array([1, 2, 3])], 'me.png', { type: 'image/png' });
    const picker = root.querySelector<HTMLInputElement>('[data-avatar-input]')!;
    Object.defineProperty(picker, 'files', { value: [file], configurable: true });
    picker.dispatchEvent(new Event('change'));
    await stable();
    expect(TestBed.inject(MediaApi).uploadImage).toHaveBeenCalledWith(file, 'me.png', 'avatar');
    expect(root.querySelector('[data-avatar-preview] img')!.getAttribute('src')).toBe('https://cdn.test/a_256.webp');
    await submit();
    let req = patch();
    expect(req.request.body.avatarAssetId).toBe('asset-9');
    req.flush(null, { status: 204, statusText: 'No Content' });
    await stable();

    (root.querySelector('[data-avatar-remove]') as HTMLElement).click();
    await stable();
    expect(root.querySelector('[data-avatar-preview] img')).toBeNull();
    await submit();
    req = patch();
    expect(req.request.body.avatarAssetId).toBeNull();
    req.flush(null, { status: 204, statusText: 'No Content' });
  });

  it('checks the form first: a long bio or title, a link that isn’t https or not on its platform never reaches the server', async () => {
    const { root, type, submit, stable } = await render();
    await type('#edit-bio', 'x'.repeat(301));
    expect(root.querySelector('[data-bio-count]')!.className).toContain('text-error');
    // The title's counter shows near the limit, in the error color past it.
    await type('#edit-headline', 'x'.repeat(101));
    expect(root.querySelector('[data-headline-count]')!.textContent!.trim()).toBe('101 / 120');
    await type('#edit-headline', 'x'.repeat(121));
    expect(root.querySelector('[data-headline-count]')!.className).toContain('text-error');
    (root.querySelector('[data-add-link]') as HTMLElement).click();
    await stable();
    (root.querySelector('[data-pick-platform="website"]') as HTMLElement).click();
    await stable();
    await type('[data-link-row="1"] [data-link-url]', 'http://mona.dev');
    await type('[data-link-row="0"] [data-link-url]', 'https://gitlab.com/mona');
    await submit();
    expect(root.querySelector('[data-field-error="bio"]')!.textContent).toContain('300');
    expect(root.querySelector('[data-field-error="headline"]')!.textContent).toContain('يجب ألا يتجاوز المسمى 120 حرفًا');
    expect(root.querySelector('[data-link-row="0"] [data-link-error="url"]')!.textContent).toContain('هذا الرابط لا ينتمي إلى المنصة التي اخترتها.');
    expect(root.querySelector('[data-link-row="1"] [data-link-error="url"]')!.textContent).toContain('يجب أن يبدأ الرابط بـ https.');
    http.expectNone((r) => r.method === 'PATCH');
  });

  it('an empty title is sent as null (it clears the title), and no links as []', async () => {
    const { root, type, submit, patch, stable } = await render();
    await type('#edit-headline', '   ');
    (root.querySelector('[data-link-row="0"] [data-link-remove]') as HTMLElement).click();
    await stable();
    await submit();
    const req = patch();
    expect(req.request.body.headline).toBeNull();
    expect(req.request.body.links).toEqual([]);
    req.flush(null, { status: 204, statusText: 'No Content' });
    await stable();
  });

  it('the server’s link errors land under their links by index, and go once the links change', async () => {
    const { root, submit, patch, stable } = await render();
    await submit();
    patch().flush(problem(400, 'validation.failed', { 'links[0].url': ['link.host_mismatch'], headline: ['profile.headline_invalid'] }), {
      status: 400,
      statusText: 'Bad Request',
    });
    await flushMicrotasks(10);
    TestBed.tick();
    expect(root.querySelector('[data-link-row="0"] [data-link-error="url"]')!.textContent).toContain('هذا الرابط لا ينتمي إلى المنصة التي اخترتها.');
    expect(root.querySelector('[data-field-error="headline"]')!.textContent).toContain('سطرًا واحدًا');
    expect(root.querySelector('[data-error]')).toBeNull(); // no general message
    expect(navigate).not.toHaveBeenCalled();

    const url = root.querySelector<HTMLInputElement>('[data-link-row="0"] [data-link-url]')!;
    url.value = 'https://github.com/mona-adel';
    url.dispatchEvent(new Event('input'));
    await stable();
    expect(root.querySelector('[data-link-row="0"] [data-link-error="url"]')).toBeNull();
  });

  it('server errors land on their fields', async () => {
    const { root, type, checkUsername, submit, patch } = await render();
    await type('#edit-username', 'Karim!');
    expect((root.querySelector('#edit-username') as HTMLInputElement).value).toBe('karim');
    await checkUsername();
    await submit();
    patch().flush(problem(409, 'user.username_taken'), { status: 409, statusText: 'Conflict' });
    await flushMicrotasks(10);
    TestBed.tick();
    expect(root.querySelector('[data-username-status]')!.textContent).toContain('اسم المستخدم هذا محجوز');
    // It stays until the handle changes: submitting again sends nothing.
    await submit();
    http.expectNone((r) => r.method === 'PATCH');

    await type('#edit-username', 'mona');
    await checkUsername();
    await submit();
    patch().flush(problem(400, 'validation.failed', { bio: ['validation.max_length'], 'links[0].url': ['link.https_required'] }), {
      status: 400,
      statusText: 'Bad Request',
    });
    await flushMicrotasks(10);
    TestBed.tick();
    expect(root.querySelector('[data-field-error="bio"]')).not.toBeNull();
    expect(root.querySelector('[data-link-row="0"] [data-link-error="url"]')).not.toBeNull();
    expect(navigate).not.toHaveBeenCalled();
  });

  it('can’t be sent twice while saving', async () => {
    const { submit, patch, stable } = await render();
    await submit();
    await submit();
    const req = patch(); // exactly one
    req.flush(null, { status: 204, statusText: 'No Content' });
    await stable();
  });
});

describe('profileFieldErrors', () => {
  const translate = () => 'translated';

  it('maps the profile codes and the per-field validation codes (case-insensitively) to the form', () => {
    expect(profileFieldErrors(new ApiError(409, 'user.username_taken', null), translate)).toEqual({ username: 'errors.user.username_taken' });
    expect(profileFieldErrors(new ApiError(400, 'profile.avatar_invalid', problem(400, 'profile.avatar_invalid', { avatarAssetId: ['profile.avatar_invalid'] })), translate)).toEqual({
      avatar: 'errors.profile.avatar_invalid',
    });
    expect(profileFieldErrors(new ApiError(400, 'profile.expertise_invalid', null), translate)).toEqual({ expertise: 'errors.profile.expertise_invalid' });
    const validation = new ApiError(
      400,
      'validation.failed',
      problem(400, 'validation.failed', {
        displayName: ['validation.length'],
        headline: ['profile.headline_too_long'],
        'links[1].url': ['link.https_required'],
        'expertiseFieldIds[5]': ['x'],
        username: ['user.username_taken'],
      }),
    );
    expect(profileFieldErrors(validation, translate)).toEqual({
      displayName: 'profile.edit.displayNameError',
      headline: 'errors.profile.headline_too_long',
      expertise: 'errors.profile.expertise_invalid',
      username: 'errors.user.username_taken',
    });
    // Only link errors: shown under the links, never as a general message.
    const links = new ApiError(400, 'validation.failed', problem(400, 'validation.failed', { 'links[0].label': ['link.label_required'] }));
    expect(profileFieldErrors(links, translate)).toEqual({});
  });

  it('maps the link errors by index and part (case-insensitively), the list’s under `links`', () => {
    const error = new ApiError(
      400,
      'validation.failed',
      problem(400, 'validation.failed', {
        links: ['link.too_many'],
        'Links[0].Platform': ['link.duplicate_platform'],
        'links[2].url': ['validation.required'],
        'links[3].url': ['link.host_mismatch'],
        'links[3].label': ['link.label_not_allowed'],
        bio: ['validation.max_length'],
      }),
    );
    expect(linkFieldErrors(error)).toEqual({
      links: 'errors.link.too_many',
      'links[0].platform': 'errors.link.duplicate_platform',
      'links[2].url': 'profile.linksEditor.urlRequired',
      'links[3].url': 'errors.link.host_mismatch',
      'links[3].label': 'errors.link.label_not_allowed',
    });
    expect(linkFieldErrors(new Error('offline'))).toEqual({});
  });

  it('anything else is a general, translated message', () => {
    expect(profileFieldErrors(new ApiError(500, 'server.error', null), translate)).toEqual({ general: 'translated' });
    expect(profileFieldErrors(new Error('offline'), translate)).toEqual({ general: 'translated' });
  });
});

describe('ExpertisePicker', () => {
  it('keeps the pick order and refuses a sixth field', () => {
    expect(toggleExpertise(['a', 'b'], 'c')).toEqual(['a', 'b', 'c']);
    expect(toggleExpertise(['a', 'b', 'c'], 'b')).toEqual(['a', 'c']);
    expect(toggleExpertise(['a', 'b', 'c', 'd', 'e'], 'f')).toEqual(['a', 'b', 'c', 'd', 'e']);
    expect(MAX_EXPERTISE).toBe(5);
  });

  it('numbers the picked chips and marks the rest unavailable at 5', async () => {
    TestBed.resetTestingModule();
    setupSocialTesting();
    const fixture = TestBed.createComponent(ExpertisePicker);
    fixture.componentRef.setInput('fields', TEST_FIELDS);
    fixture.componentRef.setInput('selected', ['f3', 'f1', 'f2', 'f4', 'f5']);
    const changes: string[][] = [];
    fixture.componentInstance.selectedChange.subscribe((ids) => changes.push(ids));
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    expect(root.querySelector('[data-expertise="data"]')!.textContent).toContain('1');
    expect(root.querySelector('[data-expertise="software"]')!.textContent).toContain('2');
    const extra = root.querySelector<HTMLButtonElement>('[data-expertise="cloud"]')!;
    expect(extra.getAttribute('aria-disabled')).toBe('true');
    expect(root.querySelector('[data-expertise-count]')!.textContent).toContain('اخترت 5');
    extra.click();
    expect(changes).toEqual([]);
    root.querySelector<HTMLButtonElement>('[data-expertise="software"]')!.click();
    expect(changes).toEqual([['f3', 'f2', 'f4', 'f5']]);
  });
});
