# ReadIn — Content

Seed content for the platform, versioned in Git and imported by the seeders in every environment (SPEC §18–§19).

```text
content/
├── taxonomy.yaml        # fields → topics, learning paths, and the plan (plannedArticles)
├── AUTHORING.md         # how an article is written, checked and committed
├── glossary/            # glossary terms, one file per field ([[term-id|Text]] in drafts)
├── assets/              # readin-avatar.png: the official ReadIn account's avatar
└── articles/
    └── {field}/{topic}/{slug}/
        ├── meta.json    # status, plan fields, titles per language, tags, sources, compile settings
        ├── en.json      # RDoc, English only (source of truth)
        ├── ar-EG.json   # RDoc, Egyptian Arabic + English terms, same structure
        └── cover.webp   # 1200×630, rendered by tools/content-covers
```

Every article is published by the official **ReadIn** account with the "AI-assisted" label. Start with
[AUTHORING.md](AUTHORING.md).

## Article status (`meta.json`)

| Status | What the importer does |
|---|---|
| `generated`, `failed` | Skipped |
| `auto-checked` | Imported as a draft of the official account, not published |
| `approved`, `published` | Published with the "AI-assisted" label. There is no review ([ADR 0015](../docs/adr/0015-open-publishing-and-the-editor.md)): `reviewStatus`, `reviewer` and `reviewedAt` are ignored, and the validator rejects any claimed review. |

`publishAt` in the past keeps that date, and one in the future publishes now: there is no scheduling (ADR 0015). Otherwise
new articles get staggered publish dates over the last ~120 days, following the plan.

## Validate before committing

```bash
cd backend
dotnet run --project src/ReadIn.ContentStudio -- validate --plan
dotnet run --project src/ReadIn.ContentStudio -- validate --all
```

This checks the plan, schema, structure, en/ar-EG parity, length, text and BiDi rules, compiles every snippet, checks
every source link and looks for duplicates (SPEC §19.3). The `content` CI workflow runs the same commands.
