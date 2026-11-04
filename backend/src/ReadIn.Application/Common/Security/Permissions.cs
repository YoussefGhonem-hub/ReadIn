namespace ReadIn.Application.Common.Security;

/// <summary>Permission codes (SPEC §10.2). Endpoints require permissions, never roles.</summary>
public static class Permissions
{
    public static class Articles
    {
        public const string Read = "articles.read";
        public const string Create = "articles.create";
        public const string Review = "articles.review";
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

    public static class Follows
    {
        public const string Manage = "follows.manage";
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

    public static class Roles
    {
        public const string Manage = "roles.manage";
    }

    public static class System
    {
        public const string Settings = "system.settings";
    }

    public static readonly IReadOnlyDictionary<string, string> All = new Dictionary<string, string>
    {
        [Articles.Read] = "Read published articles",
        [Articles.Create] = "Write and publish own articles",
        [Articles.Review] = "Review articles in assigned fields",
        [Articles.Feature] = "Feature articles",
        [Comments.Create] = "Comment and reply",
        [Reactions.Create] = "React to articles",
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
        [Roles.Manage] = "Grant and revoke roles",
        [System.Settings] = "Change system settings",
    };
}
