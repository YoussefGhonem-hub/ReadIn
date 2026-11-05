import { expect, test } from '@playwright/test';
import { VARIANTS, useVariant } from './support/mock-api';

/**
 * The demo sign-in panel (SPEC §18.3; e2e builds are development builds, so it is there): the demo account "Verified
 * Writer" (+12025550106) is gone with every demo article (pre-production step E); the two verified writers that stay
 * are .NET Writer and AI Writer, with the Verified badge.
 */
for (const variant of VARIANTS) {
  test(`demo sign-in panel: no "Verified Writer" — ${variant.lang}-${variant.theme}`, async ({ page, context, baseURL }) => {
    await useVariant(context, baseURL!, variant);
    await page.goto('/auth/sign-in');
    const panel = page.locator('[data-dev-login]');
    await panel.locator('summary').click({ timeout: 30_000 });
    const users = panel.locator('[data-dev-user]');
    await expect(users.first()).toBeVisible();
    expect(await users.evaluateAll((all) => all.map((b) => b.getAttribute('data-dev-user')))).not.toContain('+12025550106');
    await expect(panel.locator('[data-dev-user="+12025550106"]')).toHaveCount(0);
    await expect(panel).not.toContainText('Verified Writer');
    await expect(panel.locator('[data-dev-user-verified]')).toHaveCount(2);
    await expect(panel.locator('[data-dev-user="+12025550104"]')).toContainText('.NET Writer');
    await expect(panel.locator('[data-dev-user="+12025550105"]')).toContainText('AI Writer');
    // Writers 1–3 still start at +12025550107.
    await expect(panel.locator('[data-dev-user="+12025550107"]')).toContainText('Writer 1');
  });
}
