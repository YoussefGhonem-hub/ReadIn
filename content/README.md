# ReadIn — Content

Seed content for the platform, versioned in Git and imported by the seeders.

```text
content/
├── taxonomy.yaml        # fields → topics → planned articles
├── glossary/            # technical terms (ar + en)
├── paths/               # learning paths
└── articles/
    └── {field}/{topic}/{slug}/
        ├── meta.json    # status, version badge, sources, reviewer
        ├── en.json      # RDoc, English only (source of truth)
        └── ar-EG.json   # RDoc, Egyptian Arabic + English terms
```

Only articles with status `approved` are published. See [SPEC §19](../docs/SPEC.md#19-content-pipeline-1000-trusted-articles).
