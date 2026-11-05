using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Authorization;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The roles change (SPEC §10, 2026-11-05): an account is a Member or the SuperAdmin, and Verified is a badge. The
/// migration moves an existing database over, and the role seeder keeps every database that way on each start.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class RolesSeedingTests(ApiFactory api)
{
    private const string Migration = "VerifiedBadgeAndTwoRoles";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    // The removed roles' fixed ids, as an older database has them.
    private static readonly Guid VerifiedWriterRole = new("0195f3a0-0000-7000-8000-00000000a003");
    private static readonly Guid ModeratorRole = new("0195f3a0-0000-7000-8000-00000000a005");
    private static readonly Guid AdminRole = new("0195f3a0-0000-7000-8000-00000000a006");

    [Fact]
    public async Task The_migration_turns_verified_writers_into_badges_drops_three_roles_and_leaves_nobody_without_a_role()
    {
        // Accounts made here, copied into a fresh database migrated up to the migration before this one.
        var verified = await api.UserAsync("Old Verified Writer");
        var onlyVerified = await api.UserAsync("Only Verified Writer");
        var admin = await api.UserAsync("Old Admin");
        var moderator = await api.UserAsync("Old Moderator");
        var superAdmin = await api.UserAsync("Old SuperAdmin");
        var fieldId = await verified.Client.FieldIdAsync("dotnet");
        using var form = new MultipartFormDataContent
        {
            { new StringContent(fieldId.ToString()), "fieldId" },
            { new StringContent("Engineer"), "jobTitle" },
            { new StringContent("https://github.com/old-verified"), "proofUrl" },
        };
        var submitted = await verified.Client.PostAsync("/api/v1/verification-requests", form, Ct);
        submitted.StatusCode.Should().Be(HttpStatusCode.Created);
        var requestId = (await submitted.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
        var approver = await api.SuperAdminAsync("Old Approver");
        (await approver.Client.PostAsync($"/api/v1/admin/verification-requests/{requestId}/approve", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        await using var scope = api.Services.CreateAsyncScope();
        var source = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var decidedAt = await source.VerificationRequests.Where(r => r.Id == requestId).Select(r => r.DecidedAt!.Value).SingleAsync(Ct);
        var connection = new SqlConnectionStringBuilder(source.Database.GetConnectionString());
        var sourceDb = connection.InitialCatalog;
        connection.InitialCatalog = $"ReadInRoles_{Guid.NewGuid():N}";
        await using var target = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseSqlServer(connection.ConnectionString).Options);
        try
        {
            var migrations = target.Database.GetMigrations().ToList();
            var ours = migrations.FindIndex(m => m.EndsWith('_' + Migration, StringComparison.Ordinal));
            ours.Should().BePositive();
            await target.GetService<IMigrator>().MigrateAsync(migrations[ours - 1], cancellationToken: Ct);

            // The old roles, roles.manage among the permissions (every role has every one here), and who had which role.
            await target.Database.ExecuteSqlAsync(
                $"""
                INSERT INTO [Permissions] ([Id], [Code], [Description]) VALUES
                    (NEWID(), 'articles.read', 'Read'), (NEWID(), 'moderation.manage', 'Moderate'), (NEWID(), 'roles.manage', 'Grant and revoke roles');
                INSERT INTO [Roles] ([Id], [Name], [Description]) VALUES
                    ({RoleIds.Member}, 'Member', ''), ({VerifiedWriterRole}, 'VerifiedWriter', ''), ({ModeratorRole}, 'Moderator', ''),
                    ({AdminRole}, 'Admin', ''), ({RoleIds.SuperAdmin}, 'SuperAdmin', '');
                INSERT INTO [RolePermissions] ([RoleId], [PermissionId]) SELECT r.[Id], p.[Id] FROM [Roles] r CROSS JOIN [Permissions] p;
                """, Ct);
            Guid[] users = [verified.Id, onlyVerified.Id, admin.Id, moderator.Id, superAdmin.Id, SystemUsers.EditorialId];
            await CopyAsync(target, sourceDb, "Users", $"[Id] IN ({string.Join(", ", users.Select(id => $"'{id}'"))})");
            await CopyAsync(target, sourceDb, "Fields", $"[Id] = '{fieldId}'");
            await CopyAsync(target, sourceDb, "VerificationRequests", $"[Id] = '{requestId}'");
            await target.Database.ExecuteSqlAsync(
                $"""
                INSERT INTO [UserRoles] ([UserId], [RoleId]) VALUES
                    ({verified.Id}, {RoleIds.Member}), ({verified.Id}, {VerifiedWriterRole}),
                    ({onlyVerified.Id}, {VerifiedWriterRole}),
                    ({admin.Id}, {AdminRole}),
                    ({moderator.Id}, {RoleIds.Member}), ({moderator.Id}, {ModeratorRole}),
                    ({superAdmin.Id}, {RoleIds.SuperAdmin}),
                    ({SystemUsers.EditorialId}, {RoleIds.Member});
                """, Ct);

            await target.Database.MigrateAsync(Ct);

            (await target.Roles.Select(r => r.Name).ToListAsync(Ct)).Should().BeEquivalentTo([RoleNames.Member, RoleNames.SuperAdmin]);
            (await target.Permissions.Select(p => p.Code).ToListAsync(Ct)).Should().NotContain("roles.manage");
            var after = (await target.Users.IgnoreQueryFilters().Where(u => users.Contains(u.Id))
                    .Select(u => new { u.Id, u.IsVerified, u.VerifiedAt, Roles = u.Roles.Select(r => r.RoleId).ToList() })
                    .ToListAsync(Ct))
                .ToDictionary(u => u.Id);

            (after[verified.Id].IsVerified, after[verified.Id].VerifiedAt).Should().Be((true, (DateTime?)decidedAt), "dated by the approved request");
            after[onlyVerified.Id].IsVerified.Should().BeTrue();
            after[onlyVerified.Id].VerifiedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(5), "no approved request: now");
            after[SystemUsers.EditorialId].IsVerified.Should().BeTrue("the official account always has the badge");
            foreach (var id in new[] { admin.Id, moderator.Id, superAdmin.Id })
                (after[id].IsVerified, after[id].VerifiedAt).Should().Be((false, (DateTime?)null));

            foreach (var id in new[] { verified.Id, onlyVerified.Id, admin.Id, moderator.Id, SystemUsers.EditorialId })
                after[id].Roles.Should().Equal([RoleIds.Member], "every other account is a Member");
            after[superAdmin.Id].Roles.Should().Equal([RoleIds.SuperAdmin]);
        }
        finally
        {
            await target.Database.EnsureDeletedAsync(CancellationToken.None);
        }
    }

    [Fact]
    public async Task The_role_seeder_brings_a_drifted_database_back_to_the_matrix_on_the_next_start()
    {
        var orphan = await api.UserAsync("Old Admin Account");
        (await SeedRolesAsync()).Should().BeTrue(); // other tests may have left test-only roles behind
        var settled = await RolesChecksumAsync();

        // An older database: the Admin role (with roles.manage) held by an account that has nothing else, and roles.manage
        // on the Member role too.
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var rolesManage = new Permission("roles.manage", "Grant and revoke roles");
            var oldAdmin = new Role("Admin", "Manages taxonomy, paths, verification, featured content and roles.", AdminRole);
            db.Permissions.Add(rolesManage);
            db.Roles.Add(oldAdmin);
            await db.SaveChangesAsync(Ct);
            var moderation = await db.Permissions.Where(p => p.Code == Permissions.Moderation.Manage).Select(p => p.Id).SingleAsync(Ct);
            oldAdmin.SetPermissions([rolesManage.Id, moderation]);
            var member = await db.Roles.Include(r => r.Permissions).SingleAsync(r => r.Id == RoleIds.Member, Ct);
            member.SetPermissions([.. member.Permissions.Select(p => p.PermissionId), rolesManage.Id]);
            var user = await db.Users.Include(u => u.Roles).SingleAsync(u => u.Id == orphan.Id, Ct);
            user.GrantRole(AdminRole);
            user.RevokeRole(RoleIds.Member);
            await db.SaveChangesAsync(Ct);
        }

        (await RolesChecksumAsync()).Should().NotBe(settled, "a drifted database runs the seeder on the next start");
        (await SeedRolesAsync()).Should().BeTrue();
        (await RolesChecksumAsync()).Should().Be(settled, "back to the matrix: the start after that skips it");

        await using var check = api.Services.CreateAsyncScope();
        var db2 = check.ServiceProvider.GetRequiredService<AppDbContext>();
        await check.ServiceProvider.GetRequiredService<IUserAccessService>().InvalidateAsync(orphan.Id, Ct);
        var codes = await db2.Permissions.ToDictionaryAsync(p => p.Id, p => p.Code, Ct);
        codes.Values.Should().BeEquivalentTo(Permissions.All.Keys);
        var roles = await db2.Roles.Include(r => r.Permissions).ToListAsync(Ct);
        roles.Select(r => (r.Id, r.Name)).Should().BeEquivalentTo(RoleMatrix.Roles.Select(r => (r.Id, r.Name)));
        foreach (var role in roles)
            role.Permissions.Select(p => codes[p.PermissionId]).Should().BeEquivalentTo(RoleMatrix.Roles.Single(r => r.Id == role.Id).Permissions);
        (await db2.Users.Where(u => u.Id == orphan.Id).SelectMany(u => u.Roles).Select(r => r.RoleId).ToListAsync(Ct))
            .Should().Equal([RoleIds.Member], "an account left without a role is a Member");
        (await db2.Users.IgnoreQueryFilters().AnyAsync(u => !u.Roles.Any(), Ct)).Should().BeFalse();

        var me = await orphan.Client.GetAsync("/api/v1/me", Ct).OkJsonAsync();
        me["roles"]!.AsArray().Select(r => r!.GetValue<string>()).Should().Equal(RoleNames.Member);
        me["permissions"]!.AsArray().Select(p => p!.GetValue<string>()).Should().NotContain("roles.manage");
    }

    [Fact]
    public async Task Seeded_accounts_have_one_role_and_the_badge_where_it_belongs()
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var seeded = await db.Users.IgnoreQueryFilters()
            .Where(u => u.Id == SystemUsers.EditorialId || u.Id == SystemUsers.SuperAdminId || (u.Email != null && u.Email.EndsWith("@readin.test")))
            .Select(u => new { u.Id, u.Username, u.IsVerified, Roles = u.Roles.Select(r => r.RoleId).ToList() })
            .ToListAsync(Ct);

        seeded.Select(u => u.Username).Should().NotContain(["admin", "moderator"], "there are no demo admin or moderator accounts");
        seeded.Single(u => u.Id == SystemUsers.SuperAdminId).Roles.Should().Equal([RoleIds.SuperAdmin]);
        var official = seeded.Single(u => u.Id == SystemUsers.EditorialId);
        (official.IsVerified, official.Roles.Single()).Should().Be((true, RoleIds.Member), "@readin is a Member with the badge");
        seeded.Where(u => u.Username is "reviewer_dotnet" or "reviewer_ai" or "writer_verified").Should().HaveCount(3)
            .And.OnlyContain(u => u.IsVerified && u.Roles.Count == 1 && u.Roles[0] == RoleIds.Member);
        seeded.Where(u => u.Username.StartsWith("reader", StringComparison.Ordinal)).Should().NotBeEmpty().And.OnlyContain(u => !u.IsVerified);
    }

    /// <summary>Copies rows of <paramref name="table"/> from the test database, with every column the target has.</summary>
    private static async Task CopyAsync(AppDbContext target, string sourceDb, string table, string where)
    {
        var columns = await target.Database.SqlQuery<string>(
            $"""
            SELECT c.[COLUMN_NAME] AS [Value] FROM INFORMATION_SCHEMA.COLUMNS c
            WHERE c.[TABLE_NAME] = {table} AND c.[DATA_TYPE] <> 'timestamp'
              AND COLUMNPROPERTY(OBJECT_ID(c.[TABLE_SCHEMA] + '.' + c.[TABLE_NAME]), c.[COLUMN_NAME], 'IsComputed') = 0
            """).ToListAsync(Ct);
        var list = string.Join(", ", columns.Select(c => $"[{c}]"));
        var sql = "INSERT INTO [" + table + "] (" + list + ") SELECT " + list + " FROM [" + sourceDb + "].[dbo].[" + table + "] WHERE " + where;
        await target.Database.ExecuteSqlRawAsync(sql, Ct); // test-only: the table, the columns and the ids come from this test
    }

    private async Task<bool> SeedRolesAsync()
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await RolesSeeder(scope).SeedAsync(Ct);
    }

    private async Task<string> RolesChecksumAsync()
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await RolesSeeder(scope).ComputeChecksumAsync(Ct);
    }

    private static ISeeder RolesSeeder(AsyncServiceScope scope) =>
        scope.ServiceProvider.GetServices<ISeeder>().Single(s => s.Name == "roles-and-permissions");
}
