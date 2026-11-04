using P = ReadIn.Application.Common.Security.Permissions;

namespace ReadIn.Application.Common.Security;

/// <summary>
/// Roles and their permission bundles (SPEC §10). Role ids are fixed so read models can test role
/// membership in SQL (e.g. "is the author verified") without a lookup.
/// </summary>
public static class RoleNames
{
    public const string Guest = "Guest";
    public const string Member = "Member";
    public const string VerifiedWriter = "VerifiedWriter";
    public const string Moderator = "Moderator";
    public const string Admin = "Admin";
    public const string SuperAdmin = "SuperAdmin";
}

public static class RoleIds
{
    public static readonly Guid Guest = new("0195f3a0-0000-7000-8000-00000000a001");
    public static readonly Guid Member = new("0195f3a0-0000-7000-8000-00000000a002");
    public static readonly Guid VerifiedWriter = new("0195f3a0-0000-7000-8000-00000000a003");
    public static readonly Guid Moderator = new("0195f3a0-0000-7000-8000-00000000a005");
    public static readonly Guid Admin = new("0195f3a0-0000-7000-8000-00000000a006");
    public static readonly Guid SuperAdmin = new("0195f3a0-0000-7000-8000-00000000a007");
}

public sealed record RoleDefinition(Guid Id, string Name, string Description, IReadOnlyList<string> Permissions);

public static class RoleMatrix
{
    private static readonly string[] MemberPermissions =
    [
        P.Articles.Read, P.Articles.Create, P.Comments.Create, P.Reactions.Create,
        P.Follows.Manage, P.Saved.Manage, P.Reports.Create,
    ];

    /// <summary>The permission matrix from SPEC §10.2, row for row.</summary>
    public static readonly IReadOnlyList<RoleDefinition> Roles =
    [
        new(RoleIds.Guest, RoleNames.Guest, "Not signed in. Can browse and read published articles.", [P.Articles.Read]),
        new(RoleIds.Member, RoleNames.Member, "Default for every signed-up user.", MemberPermissions),
        new(RoleIds.VerifiedWriter, RoleNames.VerifiedWriter, "Identity/expertise verified writer (badge only; anyone may publish).", MemberPermissions),
        new(RoleIds.Moderator, RoleNames.Moderator, "Handles reports, hides content, suspends users.",
            [.. MemberPermissions, P.Moderation.Manage, P.Users.Suspend]),
        new(RoleIds.Admin, RoleNames.Admin, "Manages taxonomy, paths, verification, featured content and roles.",
            [.. P.All.Keys.Where(p => p != P.System.Settings)]),
        new(RoleIds.SuperAdmin, RoleNames.SuperAdmin, "Full access.", [.. P.All.Keys]),
    ];

    /// <summary>Roles an Admin may not grant or revoke (SPEC §10.2 footnote).</summary>
    public static readonly IReadOnlySet<string> ProtectedRoles = new HashSet<string> { RoleNames.Admin, RoleNames.SuperAdmin };
}
