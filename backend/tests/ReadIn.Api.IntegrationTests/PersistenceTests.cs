using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting.Internal;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Key generation and outbox behaviour on a real SQL Server (ADR 0006).</summary>
[Collection(ApiCollection.Name)]
public sealed class PersistenceTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Ef_core_keys_sort_in_insertion_order_on_sql_server()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var run = Guid.NewGuid().ToString("N")[..6];
        var slugs = Enumerable.Range(0, 25).Select(i => $"seq-{run}-{i:D2}").ToList();

        foreach (var slug in slugs)
        {
            db.Tags.Add(new Tag(slug, slug, slug, createdById: null, DateTime.UtcNow));
            await db.SaveChangesAsync(Ct);
        }

        // ORDER BY on a uniqueidentifier uses SQL Server's byte order, the order the clustered index uses.
        var byKey = await db.Tags.AsNoTracking()
            .Where(t => t.Slug.StartsWith($"seq-{run}-"))
            .OrderBy(t => t.Id)
            .Select(t => t.Slug)
            .ToListAsync(Ct);

        byKey.Should().Equal(slugs);
    }

    [Fact]
    public async Task Domain_events_carry_the_key_ef_core_assigned()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var user = User.Register(ApiFactory.NewPhoneNumber(), "not-a-real-hash", $"events_{Guid.NewGuid():N}"[..20], RoleIds.Member);
        user.Id.Should().Be(Guid.Empty, "the domain no longer generates keys");

        db.Users.Add(user);
        await db.SaveChangesAsync(Ct);

        user.Id.Should().NotBe(Guid.Empty);
        user.Roles.Should().ContainSingle().Which.UserId.Should().Be(user.Id, "EF Core fixes up the child's foreign key");
        var message = await db.OutboxMessages.AsNoTracking()
            .Where(m => m.Type == typeof(UserRegisteredDomainEvent).FullName && m.Content.Contains(user.Id.ToString()))
            .SingleAsync(Ct);
        JsonDocument.Parse(message.Content).RootElement.GetProperty(nameof(UserRegisteredDomainEvent.UserId)).GetGuid()
            .Should().Be(user.Id);
    }
}

/// <summary>Demo data is seeded only into local databases (SPEC §18.1).</summary>
public sealed class SeedingRulesTests
{
    [Theory]
    [InlineData("Development", true)]
    [InlineData("Testing", true)]
    [InlineData("Production", false)]
    [InlineData("Staging", false)]
    public void Demo_data_needs_a_local_environment(string environment, bool allowed)
    {
        var env = new HostingEnvironment { EnvironmentName = environment };

        SeedEnvironments.AllowsDemoData(env).Should().Be(allowed);
    }
}
