namespace ReadIn.Application.Common.Security;

/// <summary>Permission codes (SPEC §10.2). Endpoints require permissions, never roles.</summary>
public static class Permissions
{
    public static class Articles
    {
        public const string Read = "articles.read";
        public const string Create = "articles.create";

        /// <summary>
        /// Download an article you can open as a PDF (SPEC F33); the query checks the article: published and visible for
        /// every member, archived or hidden ones for their author only.
        /// </summary>
        public const string ExportPdf = "articles.export_pdf";
        public const string Feature = "articles.feature";
    }

    public static class Comments
    {
        public const string Create = "comments.create";
    }

    public static class Reactions
    {
        public const string Create = "reactions.create";
    }

    /// <summary>Repost an article to your followers (SPEC F29).</summary>
    public static class Reposts
    {
        public const string Create = "reposts.create";
    }

    /// <summary>Highlight text in articles and remove your highlights (SPEC F30).</summary>
    public static class Highlights
    {
        public const string Create = "highlights.create";
    }

    public static class Follows
    {
        public const string Manage = "follows.manage";
    }

    /// <summary>Block and unblock people (SPEC F36).</summary>
    public static class Blocks
    {
        public const string Manage = "users.block";
    }

    public static class Saved
    {
        public const string Manage = "saved.manage";
    }

    public static class Reports
    {
        public const string Create = "reports.create";
    }

    public static class Moderation
    {
        public const string Manage = "moderation.manage";
    }

    public static class Users
    {
        /// <summary>List and open any account in the admin console (SPEC F23).</summary>
        public const string Read = "users.read";
        public const string Suspend = "users.suspend";
        public const string ResetPassword = "users.reset_password";
        public const string ReadPii = "users.read.pii";
    }

    public static class Verification
    {
        public const string Manage = "verification.manage";
    }

    public static class Taxonomy
    {
        public const string Manage = "taxonomy.manage";
    }

    public static class Paths
    {
        public const string Manage = "paths.manage";
    }

    public static class System
    {
        public const string Settings = "system.settings";
    }

    /// <summary>The admin console and its dashboard (SPEC F23).</summary>
    public static class Admin
    {
        public const string Access = "admin.access";
    }

    /// <summary>Help and support tickets (SPEC F35): send and follow your own, or answer everyone's.</summary>
    public static class Support
    {
        public const string Create = "support.create";
        public const string Manage = "support.manage";
    }

    /// <summary>Announcements to every reader, or the readers of a field or a language (SPEC F23).</summary>
    public static class Notifications
    {
        public const string Broadcast = "notifications.broadcast";
    }

    /// <summary>The audit log browser (SPEC F23).</summary>
    public static class Audit
    {
        public const string Read = "audit.read";
    }

    public static readonly IReadOnlyDictionary<string, string> All = new Dictionary<string, string>
    {
        [Articles.Read] = "Read published articles",
        [Articles.Create] = "Write and publish own articles",
        [Articles.ExportPdf] = "Download articles as PDF",
        [Articles.Feature] = "Feature articles and choose the featured paths",
        [Comments.Create] = "Comment and reply",
        [Reactions.Create] = "React to articles",
        [Reposts.Create] = "Repost articles",
        [Highlights.Create] = "Highlight text in articles",
        [Follows.Manage] = "Follow writers and fields",
        [Saved.Manage] = "Save articles and manage collections",
        [Reports.Create] = "Report content",
        [Moderation.Manage] = "Hide content and resolve reports",
        [Users.Suspend] = "Suspend users",
        [Users.ResetPassword] = "Reset a user's password when the recovery PIN is lost",
        [Users.ReadPii] = "See phone numbers",
        [Verification.Manage] = "Approve or reject writer verification",
        [Taxonomy.Manage] = "Manage fields, topics and tags",
        [Paths.Manage] = "Manage learning paths",
        [System.Settings] = "Change system settings",
        [Admin.Access] = "Open the admin console and its dashboard",
        [Users.Read] = "List and open any account in the admin console",
        [Support.Create] = "Send and follow your own support tickets",
        [Support.Manage] = "Answer support tickets",
        [Notifications.Broadcast] = "Send announcements",
        [Audit.Read] = "Browse the audit log",
        [Blocks.Manage] = "Block and unblock people",
    };
}
