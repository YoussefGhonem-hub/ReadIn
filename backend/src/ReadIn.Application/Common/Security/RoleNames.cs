using P = ReadIn.Application.Common.Security.Permissions;

namespace ReadIn.Application.Common.Security;

/// <summary>
/// Roles and their permission bundles (SPEC §10): an account is a <c>Member</c> or the <c>SuperAdmin</c>, and
/// <c>Guest</c> is a caller without a token. Verified is a badge (<c>Users.IsVerified</c>), not a role. Endpoints check
/// permissions, never these names, so a staff role can be added later by adding a row here.
/// </summary>
public static class RoleNames
{
    public const string Guest = "Guest";
    public const string Member = "Member";
    public const string SuperAdmin = "SuperAdmin";
}

/// <summary>Fixed role ids, the same in every database. a003 (VerifiedWriter), a005 (Moderator) and a006 (Admin) were removed.</summary>
public static class RoleIds
{
    public static readonly Guid Guest = new("0195f3a0-0000-7000-8000-00000000a001");
    public static readonly Guid Member = new("0195f3a0-0000-7000-8000-00000000a002");
    public static readonly Guid SuperAdmin = new("0195f3a0-0000-7000-8000-00000000a007");
}

public sealed record RoleDefinition(Guid Id, string Name, string Description, IReadOnlyList<string> Permissions);

public static class RoleMatrix
{
    /// <summary>The permission matrix from SPEC §10.2, row for row. Startup seeding makes the database match it exactly.</summary>
    public static readonly IReadOnlyList<RoleDefinition> Roles =
    [
        new(RoleIds.Guest, RoleNames.Guest, "Not signed in. Can browse and read published articles.", [P.Articles.Read]),
        new(RoleIds.Member, RoleNames.Member, "Default for every signed-up user, with or without the Verified badge.",
        [
            P.Articles.Read, P.Articles.Create, P.Articles.ExportPdf, P.Comments.Create, P.Reactions.Create, P.Reposts.Create,
            P.Highlights.Create, P.Follows.Manage, P.Saved.Manage, P.Reports.Create,
        ]),
        new(RoleIds.SuperAdmin, RoleNames.SuperAdmin, "The app's owner. Full access, moderation and verification included.", [.. P.All.Keys]),
    ];
}
