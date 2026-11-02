# ReadIn — Mobile

Flutter app (Android & iOS) with Clean Architecture (feature-first), flutter_bloc, get_it + injectable, go_router, dio + retrofit.

```text
mobile/lib/
├── app/        # app widget, router, theme, localization
├── core/       # di, network, theme tokens, l10n, storage, errors
├── shared/     # widgets, RDoc renderer
└── features/
    └── <feature>/
        ├── data/          # datasources, models, repository impl
        ├── domain/        # entities, repository contracts, use cases
        └── presentation/  # blocs, pages, widgets
```

See [SPEC §8](../docs/SPEC.md#8-mobile-flutter).
