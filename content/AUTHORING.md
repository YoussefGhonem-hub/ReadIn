# Writing a ReadIn article

How seeded articles are written, checked and committed (SPEC §13, §14, §19, §20). Every rule below is enforced by
`ContentStudio validate`, so a batch that passes validation follows this guide.

## Files

```text
content/articles/{field}/{topic}/{slug}/
  meta.json     # committed: status, plan fields, titles, tags, sources, compile settings
  en.md         # draft (git-ignored) → compose → en.json
  ar-EG.md      # draft (git-ignored) → compose → ar-EG.json
  en.json       # committed: RDoc v1, English, the SOURCE OF TRUTH
  ar-EG.json    # committed: RDoc v1, Egyptian Arabic + English terms, same structure as en.json
  cover.webp    # committed: 1200×630, rendered by tools/content-covers
content/glossary/{field}.yaml   # glossary terms used as [[term-id|Text]]
```

The article must be in the plan first (`plannedArticles` in [`taxonomy.yaml`](taxonomy.yaml)). Its slug, field, topic,
titles, level, learning path and version badge come from there.

## Commands

```bash
cd backend
dotnet run --project src/ReadIn.ContentStudio -- plan-status                  # what's written, per learning path
dotnet run --project src/ReadIn.ContentStudio -- compose --slug <slug>        # drafts → en.json / ar-EG.json
dotnet run --project src/ReadIn.ContentStudio -- validate --slug <slug>       # every check, links + compile included
dotnet run --project src/ReadIn.ContentStudio -- validate --field dotnet --no-links   # quicker loop while writing
dotnet run --project src/ReadIn.ContentStudio -- validate --plan              # the plan itself
node tools/content-covers/render.mjs --slug <slug>                            # cover.webp (from the repo root)
```

`validate` needs Node 24 (TypeScript), the Flutter SDK (Dart) and [uv](https://docs.astral.sh/uv/) (Python). It sets
up `tools/content-check` on first use. A missing toolchain is an error, never a silent skip.

## Draft syntax

Drafts are a small, strict Markdown. One blank line separates blocks.

| Draft | RDoc block |
|---|---|
| `:::summary` … `:::` | `summary` (TL;DR), must be first |
| a paragraph (lines joined with spaces) | `paragraph` |
| `## Heading` / `### Heading` | `heading` level 2 / 3 (H1 is the title in meta.json) |
| `- item` / `1. item` (indent continuation lines by 2 spaces) | `bulletList` / `orderedList` |
| `:::tip Optional title` … `:::` (also `info`, `warning`, `danger`) | `callout` |
| `:::steps` then `### Step title` + its text, … `:::` | `steps` |
| ` ```csharp filename="Program.cs" ` … ` ``` ` | `code` (`highlight="2,3"`, `compile=false` also allowed) |
| `:::codetabs` + fenced blocks with `label="❌ Wrong"` / `label="✅ Right"` … `:::` | `codeTabs` |
| `\| a \| b \|` + `\| --- \| --- \|` + rows | `table` (`\|` is a literal pipe) |
| `> text` (and `> -- Author` for the cite) | `quote` |
| `---` | `divider` |
| `![alt text](rdoc-asset://… "caption")` | `image` (alt text required) |

Inline: `` `code` ``, `**bold**`, `*italic*`, `[text](https://url)`, `[[term-id|Shown text]]` (glossary term), and `\`
to escape `* ` [ ] \ |`. Marks nest: `` **`AddScoped`** `` is bold code.

Block ids are positional (`tldr`, `b1`, `b2`…), so **en.md and ar-EG.md must have exactly the same blocks in the same
order**. `compose` gives every Arabic text block `dir: "rtl"`, so a paragraph that starts with an English term never
flips to LTR.

## Required structure

Same order in both languages; headings adapted to the topic.

1. `:::summary`: 2–3 sentences with the key takeaway.
2. Hook paragraph: a real situation where the misconception bites.
3. `## The common misconception` / `## الفكرة الغلط الشائعة`: the wrong belief, stated fairly (why smart people believe it).
4. `## What actually happens` / `## اللي بيحصل فعلًا`: the correct mental model, with `###` sub-sections as needed.
5. Code: at least one `code` or `:::codetabs` for programming topics, showing the wrong way, then the right way
   (`❌ Wrong` / `✅ Right` tabs, or two blocks with a `:::warning`). Non-code topics (e.g. ML theory) use `:::steps`.
6. A table comparing options, or "Myth vs Reality" / "الفكرة الغلط vs الحقيقة".
7. Callouts: at least one `tip` and one `warning` (`danger` for security). `info` for side notes.
8. `## How to apply it in your project` / `## تطبقها إزاي في مشروعك`: `:::steps` or a list.
9. Last: `## Key takeaways` / `## الخلاصة` followed by ONE bullet list of 3–5 points. Nothing after it.

Sources are NOT written in the body: they live in `meta.json` and the reader shows them at the bottom.

**Length:** 900–1,800 words per language and 5–9 minutes of reading time. Reading time = words ÷ 230 (en) or
÷ 180 (ar-EG) + 4 seconds per code line (only the first tab of a `codeTabs` counts). Aim for ~1,100–1,400 English
words, ~950–1,250 Arabic words and ≤ 45 code lines in total.

**No emoji in body text** (callout icons come from the renderer); only the `❌` / `✅` tab labels. No raw HTML: write
tags as inline code (`` `<bdi>` ``).

## Egyptian Arabic version (`ar-EG.md`)

- Clear, friendly Egyptian Arabic that every Arab can read: no heavy slang, no stiff MSA.
- A natural adaptation of en.md, not a literal translation: same sections, same code, same tables (cells translated),
  same callouts, same number of list items and steps.
- Technical terms stay in English (`Dependency Injection`, `Garbage Collector`, `Overfitting`), with a short Arabic
  explanation on first use when it isn't obvious. Never "حقن الاعتماديات".
- Identifiers, API names, keywords, file names and commands use inline code (`` `AddScoped` ``, `` `useEffect` ``).
  Other English terms are plain text; the readers isolate every English run automatically (`<bdi>` on web, Unicode
  isolates on Flutter).
- Arabic punctuation in Arabic sentences (`،` `؛` `؟`), never `,` `;` `?` right after an Arabic letter. Western digits
  (0–9) only.
- Prefer starting sentences and paragraphs with Arabic words; don't end a paragraph with an English term followed by
  punctuation when you can rephrase.
- Mark key terms on first use with `[[term-id|Term]]` when the term is in `content/glossary/` (add missing terms to your
  field's file). Code comments stay in English and code is byte-for-byte identical to en.md.

## Code

- Correct, idiomatic, minimal (ideally ≤ 25 lines, never > 40), lines ≤ 100 characters, spaces not tabs, comments in
  English. Use the APIs of the article's version badge; deprecated APIs only when the article is about them (say so).
- Give every block a `lang` and, where meaningful, a `filename` (`Program.cs`, `UserList.tsx`, `main.dart`).
- Every snippet compiles:

  | Language | Check |
  |---|---|
  | `csharp` | Roslyn, C# latest, nullable on, like `dotnet new web` on .NET 10 (implicit usings: System, Linq, Collections.Generic, IO, Threading.Tasks, Net.Http, AspNetCore.Builder/Http/Routing/Hosting, Extensions.DependencyInjection/Configuration/Hosting/Logging). ASP.NET Core, EF Core 10, Mapster, Mediator (martinothamar) and FluentValidation are referenced; add any other `using` yourself. Top-level statements compile as a program, anything else as a library. |
  | `ts` / `typescript` / `tsx` | `tsc --noEmit`, strict, with React 19, Angular 22, RxJS and Node types (`tools/content-check`) |
  | `dart` | `dart analyze` in a Flutter package with `flutter_bloc` and `equatable`; a snippet must be a complete file (`void main() {}` or declarations) |
  | `python` | byte-compiled and **run** (60 s) with scikit-learn 1.9.1, numpy, pandas; no network, no files |
  | `javascript` | `node --check` |
  | `bash` | `bash -n` |
  | `json` / `yaml` | must parse |
  | anything else (`sql`, `html`, `css`, `dockerfile`…) | not compiled; listed in the report |

- A snippet may use types it doesn't show through hidden **stubs** in meta.json (`code.stubs.csharp`, `.typescript`,
  `.dart`, `.python`), e.g. `public record Order(int Id, decimal Total);`.
- A real fragment (a lone method, a Razor/template excerpt, a snippet that shows a compile error on purpose) gets
  `compile=false` in the draft and a reason in `meta.json` → `code.skip` keyed by block id (`b7`) or tab (`b7/1`).

## Trust and sources

- 2–5 sources per article, official or primary (learn.microsoft.com, react.dev, angular.dev, docs.flutter.dev,
  dart.dev, developer.mozilla.org, scikit-learn.org, pytorch.org, Google's ML Crash Course, Anthropic's docs,
  owasp.org, original papers on arxiv.org…). Every URL must answer HTTP 200 after redirects; never invent one.
- No invented statistics, benchmarks or quotes; a number appears only if a cited source has it. Original explanations,
  no text copied from the sources.
- Claude / AI-tools articles match the current official docs; community tools are labeled "community, not official".
- `meta.json`: `"status": "published"`, `"reviewStatus": "pending"`, `"isAiAssisted": true`, `lastReviewedAt` = the
  generation date, no `reviewer` (a "Reviewed by" badge is never faked).

## meta.json

```json
{
  "slug": "async-await-is-not-threads",
  "field": "dotnet",
  "topic": "csharp",
  "status": "published",
  "reviewStatus": "pending",
  "sourceLanguage": "en",
  "translations": {
    "en": { "title": "<titleEn from the plan>", "subtitle": "One line under the title" },
    "ar-EG": { "title": "<titleAr from the plan>", "subtitle": "سطر واحد تحت العنوان" }
  },
  "level": "intermediate",
  "versionBadge": ".NET 10",
  "learningPath": { "slug": "csharp-under-the-hood", "order": 1 },
  "tags": ["C#", "async/await", "Threads"],
  "sources": [
    { "title": "Asynchronous programming with async and await — Microsoft Learn", "url": "https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/" }
  ],
  "isAiAssisted": true,
  "lastReviewedAt": "2026-11-03T00:00:00Z",
  "code": {
    "stubs": { "csharp": "public record Order(int Id, decimal Total);" },
    "skip": { "b9/0": "Fragment of a Razor view" }
  }
}
```

## Glossary (`content/glossary/{field}.yaml`)

```yaml
terms:
  - id: dependency-injection
    term: Dependency Injection
    definitionEn: A technique where a class receives the objects it depends on instead of creating them.
    definitionAr: إن الـ class تستلم الحاجات اللي محتاجاها من برّه بدل ما تعملها بنفسها.
```

Ids are unique across all files. Use a term in articles as `[[dependency-injection|Dependency Injection]]`.
