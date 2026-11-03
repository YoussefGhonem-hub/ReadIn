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
import { EditProfilePage, profileFieldErrors } from './edit-profile.page';
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
  links: { github: 'https://github.com/mona', linkedin: null, website: null },
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

  it('starts from your public profile: name, @username, bio with its counter, links, expertise', async () => {
    const { root, input } = await render();
    expect(input('#edit-name').value).toBe('Mona Adel');
    expect(input('#edit-username').value).toBe('mona');
    expect(input('#edit-bio').value).toBe('Backend engineer.');
    expect(root.querySelector('[data-bio-count]')!.textContent!.trim()).toBe('17 / 300');
    expect(input('[data-link-input="github"]').value).toBe('https://github.com/mona');
    expect(root.querySelector('[data-expertise="software"]')!.getAttribute('aria-pressed')).toBe('true');
    expect(root.querySelector('[data-avatar-preview] img')!.getAttribute('src')).toBe('https://cdn.test/old_256.webp');
    // Your own handle is fine: no "available" success message for it.
    expect(root.querySelector('[data-username-status]')!.textContent).toContain('من 3 لـ 30 حرف');
  });

  it('saves without touching the photo: avatarAssetId left out, links normalized, fields in order', async () => {
    const { root, type, submit, patch, stable } = await render();
    await type('[data-link-input="linkedin"]', 'linkedin.com/in/mona');
    (root.querySelector('[data-expertise="medicine"]') as HTMLElement).click();
    await stable();
    await submit();
    const req = patch();
    expect(req.request.body).toEqual({
      displayName: 'Mona Adel',
      username: 'mona',
      bio: 'Backend engineer.',
      links: { github: 'https://github.com/mona', linkedin: 'https://linkedin.com/in/mona', website: null },
      expertiseFieldIds: ['f1', 'f2'],
    });
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

  it('checks the form first: a bio over 300 characters or a link that isn’t https never reaches the server', async () => {
    const { root, type, submit } = await render();
    await type('#edit-bio', 'x'.repeat(301));
    expect(root.querySelector('[data-bio-count]')!.className).toContain('text-error');
    await type('[data-link-input="website"]', 'http://mona.dev');
    await submit();
    expect(root.querySelector('[data-field-error="bio"]')!.textContent).toContain('300');
    expect(root.querySelector('[data-field-error="website"]')!.textContent).toContain('https://');
    http.expectNone((r) => r.method === 'PATCH');
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
    expect(root.querySelector('[data-username-status]')!.textContent).toContain('اسم المستخدم ده محجوز');
    // It stays until the handle changes: submitting again sends nothing.
    await submit();
    http.expectNone((r) => r.method === 'PATCH');

    await type('#edit-username', 'mona');
    await checkUsername();
    await submit();
    patch().flush(problem(400, 'validation.failed', { bio: ['validation.max_length'], 'links.gitHub': ['validation.url'] }), {
      status: 400,
      statusText: 'Bad Request',
    });
    await flushMicrotasks(10);
    TestBed.tick();
    expect(root.querySelector('[data-field-error="bio"]')).not.toBeNull();
    expect(root.querySelector('[data-field-error="github"]')).not.toBeNull();
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
      problem(400, 'validation.failed', { displayName: ['validation.length'], 'links.linkedIn': ['validation.url'], 'expertiseFieldIds[5]': ['x'], username: ['user.username_taken'] }),
    );
    expect(profileFieldErrors(validation, translate)).toEqual({
      displayName: 'profile.edit.displayNameError',
      linkedin: 'profile.edit.linkInvalid',
      expertise: 'errors.profile.expertise_invalid',
      username: 'errors.user.username_taken',
    });
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
