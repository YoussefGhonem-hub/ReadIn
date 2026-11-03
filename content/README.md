# ReadIn — Content

Seed content for the platform, versioned in Git and imported by the seeders.

```text
content/
├── taxonomy.yaml        # fields → topics → planned articles
├── glossary/            # technical terms (ar + en)
├── paths/               # learning paths
└── articles/
    └── {field}/{topic}/{slug}/
        ├── meta.json    # status, titles per language, version badge, tags, sources, reviewer
        ├── en.json      # RDoc, English only (source of truth)
        └── ar-EG.json   # RDoc, Egyptian Arabic + English terms
```

## Article status (`meta.json`)

| Status | What the importer does |
|---|---|
| `generated`, `failed` | Skipped |
| `auto-checked` | Imported and submitted to the reviewer queue |
| `approved`, `published` | Published under **ReadIn Editorial** with the AI-assisted label. The "Reviewed by" badge only appears when the `reviewer` account exists in that environment; it is never faked. |

`publishAt` in the future schedules the article (drip publishing, SPEC §19.4).

## Validate before opening a PR

```bash
cd backend
dotnet run --project src/ReadIn.ContentStudio -- validate --all
```

This checks the schema, en/ar-EG structure parity (same headings, code blocks and tables, with identical code), sources, length/reading time and version badges (SPEC §19.3). The `content` CI workflow runs the same command.

See [SPEC §19](../docs/SPEC.md#19-content-pipeline-1000-trusted-articles).
