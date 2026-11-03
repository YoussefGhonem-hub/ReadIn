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
| `auto-checked` | Imported and submitted to the reviewer queue |
| `approved`, `published` | Published. With `reviewStatus: pending` it also waits in the reviewer queue; the "Reviewed by" badge only appears once a human reviewer approves it, it is never faked. |

`publishAt` in the future schedules the article (drip publishing, SPEC §19.4). Otherwise new articles get staggered
publish dates over the last ~120 days, following the plan.

## Validate before committing

```bash
cd backend
dotnet run --project src/ReadIn.ContentStudio -- validate --plan
dotnet run --project src/ReadIn.ContentStudio -- validate --all
```

This checks the plan, schema, structure, en/ar-EG parity, length, text and BiDi rules, compiles every snippet, checks
every source link and looks for duplicates (SPEC §19.3). The `content` CI workflow runs the same commands.
