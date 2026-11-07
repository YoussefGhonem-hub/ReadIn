import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { renderAdmin, testPage } from '../../../../testing/admin-testing';
import { testMe } from '../../../../testing/auth-testing';
import { TEST_API, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { AdminFieldDto, AdminTagDto, AdminTaxonomyDto } from '../../../core/api/models';
import { FieldsTab, move } from './fields-tab';
import { TagsTab } from './tags-tab';

function field(id: string, patch: Partial<AdminFieldDto> = {}): AdminFieldDto {
  return {
    id,
    slug: id,
    nameAr: `مجال ${id}`,
    nameEn: `Field ${id}`,
    icon: 'code',
    color: 'primary',
    sortOrder: 1,
    isSensitive: false,
    requiresSources: false,
    isEnabled: true,
    inTaxonomyFile: true,
    customizedAt: null,
    articleCount: 14,
    topics: [
      { id: `${id}-t1`, fieldId: id, slug: 'one', nameAr: 'أول', nameEn: 'One', sortOrder: 1, isEnabled: true, inTaxonomyFile: true, customizedAt: null, articleCount: 3 },
      { id: `${id}-t2`, fieldId: id, slug: 'two', nameAr: 'ثان', nameEn: 'Two', sortOrder: 2, isEnabled: true, inTaxonomyFile: false, customizedAt: '2026-11-01T00:00:00Z', articleCount: 0 },
    ],
    ...patch,
  };
}

const TAXONOMY: AdminTaxonomyDto = { fields: [field('software'), field('medicine', { isSensitive: true })], icons: ['code', 'stethoscope'], colors: ['primary', 'accent'] };

function tag(id: string, patch: Partial<AdminTagDto> = {}): AdminTagDto {
  return { id, slug: id, name: id, articleCount: 5, taggedCount: 6, isHidden: false, isSystem: false, createdAt: '2026-10-01T00:00:00Z', createdBy: { id: 'u1', username: 'mona' }, emptySince: null, aliases: [], ...patch };
}

describe('Admin console: Taxonomy & tags (F23)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    const testing = setupSocialTesting();
    http = testing.http;
    testing.session.setMe(testMe({ permissions: ['admin.access', 'taxonomy.manage'] }));
  });

  afterEach(() => http.verify());

  it('move() swaps neighbours and never moves past the ends', () => {
    expect(move(['a', 'b', 'c'], 1, -1)).toEqual(['b', 'a', 'c']);
    expect(move(['a', 'b', 'c'], 2, 1)).toEqual(['a', 'b', 'c']);
  });

  async function fields() {
    const t = renderAdmin(FieldsTab);
    http.expectOne(`${TEST_API}/admin/fields`).flush(structuredClone(TAXONOMY));
    await t.stable();
    return t;
  }

  it('fields in order; moving one saves the whole order (a refusal reloads)', async () => {
    const t = await fields();
    expect(t.$$('[data-field-row]').map((r) => r.getAttribute('data-field-row'))).toEqual(['software', 'medicine']);
    t.$$('[data-field-down]')[0].click();
    await t.stable();
    expect(t.$$('[data-field-row]').map((r) => r.getAttribute('data-field-row'))).toEqual(['medicine', 'software']);
    const order = http.expectOne({ method: 'PUT', url: `${TEST_API}/admin/fields/order` });
    expect(order.request.body).toEqual({ ids: ['medicine', 'software'] });
    order.flush(problem(400, 'admin.order_invalid'), { status: 400, statusText: 'Bad Request' });
    await t.stable();
    http.expectOne(`${TEST_API}/admin/fields`).flush(structuredClone(TAXONOMY));
    await t.stable();
    expect(t.$$('[data-field-row]').map((r) => r.getAttribute('data-field-row'))).toEqual(['software', 'medicine']);
  });

  it('topics open under their field and reorder within it', async () => {
    const t = await fields();
    t.$$('[data-field-topics]')[0].click();
    await t.stable();
    expect(t.$$('[data-topic-row]').map((r) => r.getAttribute('data-topic-row'))).toEqual(['one', 'two']);
    t.$$('[data-topic-up]')[1].click();
    http.expectOne(`${TEST_API}/admin/fields/software/topics/order`).flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.$$('[data-topic-row]').map((r) => r.getAttribute('data-topic-row'))).toEqual(['two', 'one']);
  });

  it('adding a field checks the slug and both names, then saves', async () => {
    const t = await fields();
    t.$('[data-add-field]')!.click();
    await t.stable();
    const save = t.$<HTMLButtonElement>('[data-taxonomy-save]')!;
    t.type('[data-tax-slug]', 'Data Science');
    t.type('[data-tax-name-ar]', 'علم البيانات');
    t.type('[data-tax-name-en]', 'Data science');
    expect(save.disabled).toBe(true);
    t.type('[data-tax-slug]', 'data-science');
    expect(save.disabled).toBe(false);
    save.click();
    const req = http.expectOne({ method: 'POST', url: `${TEST_API}/admin/fields` });
    expect(req.request.body).toEqual({ slug: 'data-science', nameAr: 'علم البيانات', nameEn: 'Data science', icon: 'code', color: 'primary', isSensitive: false, requiresSources: false, isEnabled: true });
    req.flush(problem(409, 'field.slug_taken'), { status: 409, statusText: 'Conflict' });
    await t.stable();
    expect(t.$('[data-taxonomy-error]')!.textContent).toContain('يوجد مجال آخر بهذا المعرّف');
  });

  it('disabling a field asks first, with the articles it hides', async () => {
    const t = await fields();
    t.$$('[data-field-edit]')[0].click();
    await t.stable();
    expect(t.$<HTMLInputElement>('[data-tax-slug]')!.disabled).toBe(true);
    t.$<HTMLInputElement>('[data-tax-enabled]')!.click();
    await t.stable();
    t.$('[data-taxonomy-save]')!.click();
    await t.stable();
    expect(t.$('[data-admin-confirm]')!.textContent).toContain('14');
    t.$('[data-confirm-ok]')!.click();
    const req = http.expectOne({ method: 'PUT', url: `${TEST_API}/admin/fields/software` });
    expect(req.request.body.isEnabled).toBe(false);
    req.flush(field('software', { isEnabled: false }));
    await t.stable();
    http.expectOne(`${TEST_API}/admin/fields`).flush(structuredClone(TAXONOMY));
    await t.stable();
  });

  async function tags(inputs: Record<string, unknown> = {}) {
    const t = renderAdmin(TagsTab, inputs);
    const req = http.expectOne((r) => r.url === `${TEST_API}/admin/tags`);
    req.flush(testPage([tag('dotnet', { name: '.NET', aliases: ['dot-net'] }), tag('csharp', { name: 'C#', isHidden: true })]));
    await t.stable();
    return { t, req };
  }

  it('tags: the query from the URL; renaming to a taken name offers the merge', async () => {
    const { t, req } = await tags({ q: 'net', status: 'hidden', sort: 'name' });
    expect(req.request.params.toString()).toBe('q=net&status=hidden&sort=name&page=1&pageSize=50');
    expect(t.$('[data-tag-row="dotnet"] [data-tag-aliases]')!.textContent).toContain('dot-net');

    t.$('[data-tag-row="dotnet"] [data-tag-action="rename"]')!.click();
    await t.stable();
    t.type('[data-tag-name]', 'csharp');
    t.$<HTMLFormElement>('[data-tag-rename]')!.dispatchEvent(new Event('submit'));
    const rename = http.expectOne({ method: 'PUT', url: `${TEST_API}/admin/tags/dotnet` });
    expect(rename.request.body).toEqual({ name: 'csharp' });
    rename.flush({ ...problem(409, 'tag.name_taken'), tagId: 'csharp', tagSlug: 'csharp' }, { status: 409, statusText: 'Conflict' });
    await t.stable();
    expect(t.$('[data-tag-error]')!.textContent).toContain('دمج');

    t.$('[data-merge-into-taken]')!.click();
    await t.stable();
    expect(t.$('[data-merge-target]')!.textContent).toContain('#csharp');
    t.$('[data-tag-merge-confirm]')!.click();
    const merge = http.expectOne({ method: 'POST', url: `${TEST_API}/admin/tags/dotnet/merge` });
    expect(merge.request.body).toEqual({ intoTagId: 'csharp' });
    merge.flush(tag('csharp'));
    await t.stable();
    http.expectOne((r) => r.url === `${TEST_API}/admin/tags`).flush(testPage([tag('csharp')]));
    await t.stable();
  });

  it('hiding asks first; unhiding does not', async () => {
    const { t } = await tags();
    t.$('[data-tag-row="dotnet"] [data-tag-action="hide"]')!.click();
    await t.stable();
    t.$('[data-confirm-ok]')!.click();
    http.expectOne({ method: 'PUT', url: `${TEST_API}/admin/tags/dotnet/hidden` }).flush(tag('dotnet', { name: '.NET', isHidden: true }));
    await t.stable();
    expect(t.$('[data-tag-row="dotnet"] [data-tag-hidden]')).not.toBeNull();

    t.$('[data-tag-row="csharp"] [data-tag-action="unhide"]')!.click();
    http.expectOne({ method: 'DELETE', url: `${TEST_API}/admin/tags/csharp/hidden` }).flush(tag('csharp', { name: 'C#' }));
    await t.stable();
    expect(t.$('[data-tag-row="csharp"] [data-tag-hidden]')).toBeNull();
  });
});
