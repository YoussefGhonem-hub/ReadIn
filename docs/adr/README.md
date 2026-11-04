# Architecture Decision Records

One file per decision: `NNNN-short-title.md` (Context, Decision, Consequences).

- [0001 — Firebase Authentication for identity, SQL Server for roles](0001-firebase-auth-sql-server-roles.md) (superseded by 0007)
- [0002 — RDoc: structured JSON blocks as the only article format](0002-rdoc-content-format.md)
- [0003 — Mediator (source-generated) instead of MediatR](0003-mediator-over-mediatr.md)
- [0004 — Firebase JS SDK directly on web (instead of `@angular/fire`)](0004-firebase-js-sdk-on-web.md)
- [0005 — One real Firebase project; the Emulator Suite for everything else](0005-single-firebase-project.md)
- [0006 — EF Core sequential GUIDs for primary keys (instead of `Guid.CreateVersion7()`)](0006-sequential-guids.md)
- [0007 — Phone number + password, with the API's own JWT sessions](0007-phone-password-authentication.md) (amended by 0012, 0016)
- [0008 — Firebase only for Cloud Messaging and the Realtime Database](0008-firebase-scope-fcm-and-rtdb.md)
- [0009 — Recovery PIN instead of SMS for forgotten passwords](0009-recovery-pin.md)
- [0010 — Uploads stored on the API server (`wwwroot/uploads`)](0010-uploads-in-wwwroot.md)
- [0011 — Media pipeline: responsive images and PDF attachments with page previews](0011-media-pipeline-and-pdf-preview.md)
- [0012 — Google and Apple sign in, verified by the API](0012-google-and-apple-sign-in.md) (amended by 0016)
- [0013 — Reading days, streaks and freezes](0013-reading-days-and-streaks.md)
- [0014 — Open topics, and review is always optional](0014-open-topics-and-optional-review.md) (review part superseded by 0015)
- [0015 — Open publishing, the editor's working copy, and the quality score](0015-open-publishing-and-the-editor.md)
- [0016 — Immediate account deletion, with Apple token revocation](0016-immediate-account-deletion.md)
