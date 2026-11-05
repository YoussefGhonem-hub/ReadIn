/**
 * Writer verification (F19) for the mock API, per the F19 contract: your own request (`GET` / `DELETE
 * /me/verification`, `POST /verification-requests` as multipart, with the contract's checks: magic bytes, 10 MB, https
 * links, lengths) and the admins' review (`/admin/verification-requests`: list by status, one request, its proof file,
 * approve, reject with a reason; `DELETE /admin/users/{id}/verification` removes a writer's badge).
 *
 * Verified is a badge, not a role (SPEC §10): approving sets `isVerified` and never touches `roles`.
 *
 * Requesters: `u-verify-*` viewers start with nothing; `u-verify-rejected-*` with a rejected request (and its reason);
 * `u-verify-approved-*` with an approved one, so they are verified (`GET /me` says so too: `decorateMe`). Admins are
 * viewers whose id starts with `u-admin` (`verification.manage`); each works on their own copy of the seeded requests
 * (2 pending, 1 approved, 1 rejected) and of who has the badge, so parallel tests never see each other's decisions.
 * Everyone else gets `403`.
 */

const NOW = '2026-11-04T10:00:00Z';
const MAX_BYTES = 10 * 1024 * 1024;
const PAGE_LIMIT = 50;
const SEED_ADMIN = { id: 'u-admin-seed', username: 'nour_admin' };

/** The proof's real type, from its first bytes (like the API): PDF, JPEG, PNG or WebP, else null. */
function sniff(buffer) {
  if (buffer.length >= 5 && buffer.subarray(0, 5).toString('latin1') === '%PDF-') return { type: 'application/pdf', ext: '.pdf' };
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return { type: 'image/jpeg', ext: '.jpg' };
  if (buffer.length >= 8 && buffer.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) return { type: 'image/png', ext: '.png' };
  if (buffer.length >= 12 && buffer.subarray(0, 4).toString('latin1') === 'RIFF' && buffer.subarray(8, 12).toString('latin1') === 'WEBP') return { type: 'image/webp', ext: '.webp' };
  return null;
}

const isHttps = (url) => {
  if (typeof url !== 'string' || url.length > 500) return false;
  try {
    return new URL(url).protocol === 'https:';
  } catch {
    return false;
  }
};

/** Display-safe file name: no path, no control characters, ≤ 120. */
const safeName = (name) =>
  String(name ?? 'proof')
    .split(/[\\/]/)
    .pop()
    .replace(/[\u0000-\u001f\u007f"]/g, '')
    .slice(0, 120) || 'proof';

/**
 * @param {{
 *   writers: any[], social: any, fields: any[], problem: (status: number, code: string, title: string) => any,
 *   proofPng: (seed: string) => Buffer, pdf: Buffer,
 * }} deps
 */
export function createVerification({ writers, social, fields, problem, proofPng, pdf }) {
  const people = new Map([...writers, ...social.readers].map((u) => [u.id, u]));
  const fieldById = new Map(fields.map((f) => [f.id, f]));
  /** viewer → { requests: [...] (newest last), verified: boolean, submissions: [...] } */
  const requesters = new Map();
  /** admin → Map(id → request) */
  const admins = new Map();
  /** admin → Map(userId → has the badge), once that admin approved a request of the user or removed their badge. */
  const badges = new Map();
  let nextId = 1;

  const unauthorized = () => [401, problem(401, 'auth.unauthorized', 'Please sign in first.')];
  const forbidden = () => [403, problem(403, 'auth.forbidden', 'You are not allowed to do this.')];
  const validation = (errors) => [400, { ...problem(400, 'validation.failed', 'Validation failed'), errors }];
  const lang = (req) => (/^ar/i.test(req.headers['accept-language'] ?? '') ? 'ar' : 'en');
  const fieldOf = (id, l) => {
    const f = fieldById.get(id);
    return { id: f.id, slug: f.slug, name: l === 'ar' ? f.nameAr : f.nameEn };
  };
  const userOf = (id) => {
    const u = people.get(id);
    return { id, displayName: u.displayName, username: u.username, avatarUrl: u.avatarUrl ?? null, isVerified: !!u.isVerified };
  };

  // ── Requesters ──

  function requesterOf(viewer) {
    if (!requesters.has(viewer)) {
      const state = { requests: [], verified: false, submissions: [] };
      if (viewer.startsWith('u-verify-rejected')) {
        state.requests.push({
          id: `vr-${viewer}-1`,
          status: 'rejected',
          fieldId: 'f-software',
          jobTitle: 'Backend developer',
          proofUrl: 'https://github.com/sara-hassan',
          proofFile: null,
          note: null,
          submittedAt: '2026-10-28T09:00:00Z',
          decidedAt: '2026-10-30T12:00:00Z',
          rejectionReason: 'The GitHub profile has no public projects yet. Add a certificate or a LinkedIn profile that shows your job.',
        });
      } else if (viewer.startsWith('u-verify-approved')) {
        state.requests.push({
          id: `vr-${viewer}-1`,
          status: 'approved',
          fieldId: 'f-software',
          jobTitle: 'Backend engineer في Vodafone',
          proofUrl: 'https://www.linkedin.com/in/sara-hassan',
          proofFile: null,
          note: null,
          submittedAt: '2026-11-01T09:00:00Z',
          decidedAt: '2026-11-03T12:00:00Z',
          rejectionReason: null,
        });
        state.verified = true;
      }
      requesters.set(viewer, state);
    }
    return requesters.get(viewer);
  }

  const mine = (r, l) => ({
    id: r.id,
    status: r.status,
    field: fieldOf(r.fieldId, l),
    jobTitle: r.jobTitle,
    proofUrl: r.proofUrl,
    proofFileName: r.status === 'pending' ? (r.proofFile?.fileName ?? null) : null,
    note: r.note,
    submittedAt: r.submittedAt,
    decidedAt: r.decidedAt,
    rejectionReason: r.rejectionReason,
  });

  function statusOf(viewer, l) {
    const state = requesterOf(viewer);
    const latest = state.requests.at(-1) ?? null;
    return { isVerified: state.verified, canRequest: !state.verified && latest?.status !== 'pending', request: latest ? mine(latest, l) : null };
  }

  /** `POST /verification-requests`: `body` is the parsed multipart form (`{ fields, files }`). */
  function submit(viewer, body, l) {
    const state = requesterOf(viewer);
    const form = body?.fields ?? {};
    const file = body?.files?.proof ?? null;
    state.submissions.push({ fields: { ...form }, file: file ? { name: file.filename, type: file.contentType, size: file.data.length } : null });
    if (state.verified) return [409, problem(409, 'verification.already_verified', 'You are already verified.')];
    if (state.requests.at(-1)?.status === 'pending') return [409, problem(409, 'verification.already_pending', 'You already have a pending request.')];

    const errors = {};
    const jobTitle = String(form.jobTitle ?? '').trim();
    if (jobTitle.length < 2 || jobTitle.length > 100) errors.jobTitle = ['validation.length'];
    const proofUrl = String(form.proofUrl ?? '').trim() || null;
    if (proofUrl && !isHttps(proofUrl)) errors.proofUrl = ['validation.url'];
    const note = String(form.note ?? '').trim() || null;
    if (note && note.length > 500) errors.note = ['validation.length'];
    if (Object.keys(errors).length) return validation(errors);
    if (!fieldById.has(form.fieldId)) return [400, problem(400, 'verification.field_invalid', 'Pick a field.')];
    if (!proofUrl && !file) return [400, problem(400, 'verification.proof_required', 'Add a link or a file.')];
    let proofFile = null;
    if (file) {
      const kind = sniff(file.data);
      if (!kind || file.data.length > MAX_BYTES) return [400, problem(400, 'verification.proof_invalid', 'The proof file is not accepted.')];
      proofFile = { fileName: safeName(file.filename), contentType: kind.type, sizeBytes: file.data.length };
    }
    const request = {
      id: `vr-new-${nextId++}`,
      status: 'pending',
      fieldId: form.fieldId,
      jobTitle,
      proofUrl,
      proofFile,
      note,
      submittedAt: NOW,
      decidedAt: null,
      rejectionReason: null,
    };
    state.requests.push(request);
    return [201, mine(request, l)];
  }

  function withdraw(viewer) {
    const state = requesterOf(viewer);
    if (state.requests.at(-1)?.status !== 'pending') return [404, problem(404, 'verification.not_found', 'No pending request.')];
    state.requests.pop();
    return [204, undefined];
  }

  // ── Admins ──

  const isAdmin = (viewer) => !!viewer && viewer.startsWith('u-admin');

  function seedRequests() {
    const proof = (fileName, contentType, sizeBytes) => ({ fileName, contentType, sizeBytes });
    return [
      {
        id: 'vr-salma',
        status: 'pending',
        userId: 'u-salma',
        fieldId: 'f-software',
        jobTitle: 'ML engineer في Instabug',
        proofUrl: 'https://www.linkedin.com/in/salma-ibrahim',
        proof: proof('aws-ml-certificate.png', 'image/png', 48_213),
        note: 'معايا شهادة AWS Machine Learning Specialty، والشغل بتاعي على LinkedIn.',
        submittedAt: '2026-11-02T10:00:00Z',
        decidedAt: null,
        decidedBy: null,
        rejectionReason: null,
      },
      {
        id: 'vr-omar',
        status: 'pending',
        userId: 'u-omar',
        fieldId: 'f-medicine',
        jobTitle: 'Medical student, Kasr Al Ainy',
        proofUrl: null,
        proof: proof('syndicate-card.pdf', 'application/pdf', 182_400),
        note: null,
        submittedAt: '2026-11-03T07:30:00Z',
        decidedAt: null,
        decidedBy: null,
        rejectionReason: null,
      },
      {
        id: 'vr-karim',
        status: 'approved',
        userId: 'u-karim',
        fieldId: 'f-software',
        jobTitle: 'Frontend lead',
        proofUrl: 'https://github.com/karim-hassan',
        proof: null,
        note: null,
        submittedAt: '2026-10-18T09:00:00Z',
        decidedAt: '2026-10-20T11:00:00Z',
        decidedBy: SEED_ADMIN,
        rejectionReason: null,
      },
      {
        id: 'vr-reader',
        status: 'rejected',
        userId: 'u-reader-05',
        fieldId: 'f-medicine',
        jobTitle: 'Nutrition coach',
        proofUrl: 'https://instagram.com/fit.with.reader',
        proof: null,
        note: null,
        submittedAt: '2026-10-22T09:00:00Z',
        decidedAt: '2026-10-25T16:00:00Z',
        decidedBy: SEED_ADMIN,
        rejectionReason: 'An Instagram page is not proof of a medical qualification.',
      },
    ];
  }

  function adminOf(viewer) {
    if (!admins.has(viewer)) admins.set(viewer, new Map(seedRequests().map((r) => [r.id, r])));
    return admins.get(viewer);
  }

  function badgesOf(viewer) {
    if (!badges.has(viewer)) badges.set(viewer, new Map());
    return badges.get(viewer);
  }

  /** Whether `userId` has the Verified badge for this admin: an approved request gives it, removing it takes it away. */
  function isVerifiedFor(viewer, userId) {
    const known = badgesOf(viewer).get(userId);
    if (known !== undefined) return known;
    return !!people.get(userId)?.isVerified || [...adminOf(viewer).values()].some((r) => r.userId === userId && r.status === 'approved');
  }

  const adminDto = (viewer, r, l) => {
    const user = userOf(r.userId);
    return {
      id: r.id,
      status: r.status,
      user: { ...user, isVerified: isVerifiedFor(viewer, r.userId) },
      field: fieldOf(r.fieldId, l),
      jobTitle: r.jobTitle,
      proofUrl: r.proofUrl,
      proof: r.proof,
      note: r.note,
      submittedAt: r.submittedAt,
      decidedAt: r.decidedAt,
      decidedBy: r.decidedBy,
      rejectionReason: r.rejectionReason,
    };
  };

  function list(viewer, q, l) {
    const status = q.get('status') ?? 'pending';
    if (!['pending', 'approved', 'rejected'].includes(status)) return validation({ status: ['validation.invalid'] });
    const all = [...adminOf(viewer).values()].filter((r) => r.status === status);
    all.sort((a, b) => (status === 'pending' ? a.submittedAt.localeCompare(b.submittedAt) : b.decidedAt.localeCompare(a.decidedAt)));
    const limit = Math.min(PAGE_LIMIT, Math.max(1, Number(q.get('limit') ?? 20) || 20));
    const start = Number(q.get('cursor') ?? 0) || 0;
    const items = all.slice(start, start + limit).map((r) => adminDto(viewer, r, l));
    return [200, { items, nextCursor: start + limit < all.length ? String(start + limit) : null }];
  }

  function decide(viewer, id, outcome, body) {
    const request = adminOf(viewer).get(decodeURIComponent(id));
    if (!request) return [404, problem(404, 'verification.not_found', 'Not found.')];
    if (request.status !== 'pending') return [409, problem(409, 'verification.already_decided', 'Already decided.')];
    let reason = null;
    if (outcome === 'rejected') {
      reason = String(body?.reason ?? '').trim();
      if (reason.length < 5 || reason.length > 500) return validation({ reason: ['validation.length'] });
    }
    Object.assign(request, { status: outcome, decidedAt: NOW, decidedBy: { id: viewer, username: 'hana_admin' }, rejectionReason: reason, proof: null });
    // The badge only: the user stays a Member.
    if (outcome === 'approved') badgesOf(viewer).set(request.userId, true);
    return [204, undefined];
  }

  /** `DELETE /admin/users/{id}/verification`: `404 user.not_found`, `409 verification.not_verified`, else `204`. */
  function removeBadge(viewer, id) {
    const userId = decodeURIComponent(id);
    if (!people.has(userId)) return [404, problem(404, 'user.not_found', 'User not found.')];
    if (!isVerifiedFor(viewer, userId)) return [409, problem(409, 'verification.not_verified', 'This user is not verified.')];
    badgesOf(viewer).set(userId, false);
    return [204, undefined];
  }

  const signedIn = (handler) => (q, match, body, req) => {
    const viewer = social.viewerOf(req);
    return viewer ? handler(viewer, q, match, body, req) : unauthorized();
  };
  const admin = (handler) => (q, match, body, req) => {
    const viewer = social.viewerOf(req);
    if (!viewer) return unauthorized();
    return isAdmin(viewer) ? handler(viewer, q, match, body, req) : forbidden();
  };

  const routes = [
    ['GET', /^\/api\/v1\/me\/verification$/, signedIn((viewer, _q, _m, _b, req) => [200, statusOf(viewer, lang(req))])],
    ['DELETE', /^\/api\/v1\/me\/verification$/, signedIn((viewer) => withdraw(viewer))],
    ['POST', /^\/api\/v1\/verification-requests$/, signedIn((viewer, _q, _m, body, req) => submit(viewer, body, lang(req)))],
    ['GET', /^\/api\/v1\/admin\/verification-requests$/, admin((viewer, q, _m, _b, req) => list(viewer, q, lang(req)))],
    [
      'GET',
      /^\/api\/v1\/admin\/verification-requests\/([^/]+)\/proof$/,
      admin((viewer, _q, [, id]) => {
        const request = adminOf(viewer).get(decodeURIComponent(id));
        if (!request) return [404, problem(404, 'verification.not_found', 'Not found.')];
        if (!request.proof) return [404, problem(404, 'verification.proof_not_found', 'No proof file.')];
        const isPdf = request.proof.contentType === 'application/pdf';
        return [
          200,
          isPdf ? pdf : proofPng(request.id),
          {
            'content-type': request.proof.contentType,
            'content-disposition': `attachment; filename="verification-proof-${request.id}${isPdf ? '.pdf' : '.png'}"`,
            'cache-control': 'no-store',
            'x-content-type-options': 'nosniff',
          },
        ];
      }),
    ],
    [
      'GET',
      /^\/api\/v1\/admin\/verification-requests\/([^/]+)$/,
      admin((viewer, _q, [, id], _b, req) => {
        const request = adminOf(viewer).get(decodeURIComponent(id));
        return request ? [200, adminDto(viewer, request, lang(req))] : [404, problem(404, 'verification.not_found', 'Not found.')];
      }),
    ],
    ['POST', /^\/api\/v1\/admin\/verification-requests\/([^/]+)\/approve$/, admin((viewer, _q, [, id]) => decide(viewer, id, 'approved'))],
    ['POST', /^\/api\/v1\/admin\/verification-requests\/([^/]+)\/reject$/, admin((viewer, _q, [, id], body) => decide(viewer, id, 'rejected', body))],
    ['DELETE', /^\/api\/v1\/admin\/users\/([^/]+)\/verification$/, admin((viewer, _q, [, id]) => removeBadge(viewer, id))],
    // For the tests: a requester's requests and every form they sent; an admin's requests by id and who has the badge.
    [
      'GET',
      /^\/__mock\/verification$/,
      (q) => {
        const viewer = q.get('viewer') ?? '';
        if (isAdmin(viewer)) {
          const requests = [...adminOf(viewer).values()];
          return [
            200,
            {
              requests: Object.fromEntries(requests.map((r) => [r.id, { status: r.status, rejectionReason: r.rejectionReason }])),
              verified: Object.fromEntries(requests.map((r) => [r.userId, isVerifiedFor(viewer, r.userId)])),
            },
          ];
        }
        const state = requesterOf(viewer);
        return [200, { verified: state.verified, requests: state.requests, submissions: state.submissions }];
      },
    ],
  ];

  /** `GET /me` follows the verification: an approved requester has the badge, and their roles stay as they are. */
  function decorateMe(me, viewer) {
    if (!viewer?.startsWith('u-verify') || !requesterOf(viewer).verified) return me;
    return { ...me, isVerified: true };
  }

  return { routes, decorateMe };
}
