# ReadIn Web (Angular 22, SSR)

Web client for ReadIn. Spec: [`docs/SPEC.md`](../docs/SPEC.md) (§7 Web, §13 RDoc, §14 BiDi, §15 design system, §23 SEO). API contract: [`docs/api/contract-v1.md`](../docs/api/contract-v1.md).

## Run

```bash
npm install
npm start                 # http://localhost:4200 (dev server with SSR)
npm run build             # production SSR build → dist/readin-web
npm run serve:ssr         # serve the production build (PORT, default 4000)
npm test                  # unit tests (Vitest, headless)
npm run e2e               # Playwright visual tests: ar/en × light/dark
npm run tokens            # regenerate src/styles/tokens*.css from design/tokens.json
npm run tokens:check      # CI: fail if generated tokens are stale
```

Local dependencies: the API on `http://localhost:5080` and the Firebase Auth emulator (`firebase emulators:start` at the repo root, project `demo-readin`). Both URLs live in `src/environments/environment.development.ts`.

SSR can call the API over an internal address with `READIN_API_INTERNAL_URL` (e.g. `http://readin-api:8080/api/v1`); the transfer cache maps it back to the public origin. Allowed SSR hosts are set in `angular.json` → `security.allowedHosts`.

## Structure (SPEC §7.1)

```text
src/app/
├── core/       auth (Firebase, session Signal Store, guards) · http (interceptors) · i18n (Transloco)
│               theme (ThemeService, reader prefs) · api (typed contract-v1 services) · realtime · platform
├── shared/     ui (cards, sheets, states, icons) · rdoc (renderer, one component per block) · directives (BiDi) · pipes
├── layout/     shell, top bar, side nav (desktop), bottom nav (narrow screens)
└── features/   auth · onboarding · home · article · settings · placeholders for later phases
```

## Rules this codebase follows

- **Tokens only.** Colors come from `design/tokens.json` through `src/styles/tokens*.css` (Tailwind utilities like `bg-surface`, `text-text-secondary`). Never edit the generated files; never use hex colors in components.
- **No theme flash.** The `theme` and `lang` cookies drive `<html data-theme lang dir>` during SSR; an inline script in `index.html` does the same for client-rendered routes.
- **Every string in `public/i18n/{ar,en}.json`.** API errors are translated from their ProblemDetails `code` under `errors.*`.
- **BiDi.** RDoc blocks resolve their own direction; opposite-direction runs are isolated with `<bdi>`; code is always LTR. Use `rd-bdi-text` / `[rdAutoDir]` for user text outside articles. Test fixtures: `shared/bidi/fixtures.json`.
- **Icons.** Register Lucide icons in `shared/ui/icons.ts` and render them with `<svg lucideIcon="Name">`. A single shared template keeps the bundle small.
- **Hydration.** GETs made while hydrating are sent without a token so they're served from the SSR transfer cache. Pages that personalize (Home) refresh once the session is known.
