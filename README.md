# ReadIn

> **ReadIn — مقال كل يوم يفرق معاك**
> *Read daily. Grow daily.*

ReadIn منصة لنشر وقراءة المقالات المعرفية بالعربي والإنجليزي، بتساعدك تقرا كل يوم مقال في المجال اللي بتحبه وتزود معلوماتك.

ReadIn is a bilingual (Arabic + English) knowledge platform that helps you read one valuable article every day in the field you love.

## Highlights
- Mixed Arabic/English articles that never break the layout (per-block direction, code always LTR).
- Daily article at your chosen time, streaks and learning paths.
- Verified writers, reviewed articles, sources and tested code.
- Every article in two versions: Egyptian Arabic + English terms, and English only.
- Every feature on **Web and Mobile**, in **Arabic and English**, in **Light and Dark** mode.

## Tech Stack
| Part | Stack |
|---|---|
| Backend | .NET 10 · ASP.NET Core · Clean Architecture · CQRS (Mediator) · Mapster · EF Core · SQL Server |
| Web | Angular (SSR) · Signals · Tailwind CSS · Transloco · Tiptap |
| Mobile | Flutter · flutter_bloc · go_router · dio |
| Platform | Firebase Auth · Cloud Messaging · Storage |

## Repository Structure
| Folder | Content |
|---|---|
| [`docs/`](docs) | [Product & Technical Specification](docs/SPEC.md), ADRs, approved designs |
| [`design/`](design) | Design tokens (light + dark) shared by web and mobile |
| [`shared/`](shared) | RDoc article format schema and examples |
| [`backend/`](backend) | ASP.NET Core API (Clean Architecture) |
| [`web/`](web) | Angular web app |
| [`mobile/`](mobile) | Flutter mobile app |
| [`content/`](content) | Taxonomy, glossary, learning paths and seeded articles |

📄 **Start here:** [docs/SPEC.md](docs/SPEC.md)
