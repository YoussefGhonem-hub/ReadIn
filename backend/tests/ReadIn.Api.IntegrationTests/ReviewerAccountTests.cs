using System.Net;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Application.Features.Legal;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The App Review account seeder (SPEC §18.3, §32): it adopts the account that has <c>Seed:ReviewerPhone</c> or creates it
/// ready to use, running it again changes nothing, and the account stays out of search and follower counts. The suite's
/// configuration has no reviewer, so each test runs the seeder with its own options.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ReviewerAccountTests(ApiFactory api)
{
    private const string ReviewPassword = "Review-pass-2026";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private ReviewerAccountSeeder Seeder(IServiceProvider services, string? phone, string? password, string? pin = null) => new(
        services.GetRequiredService<AppDbContext>(),
        Options.Create(new SeedOptions { ReviewerPhone = phone, ReviewerPassword = password, ReviewerPin = pin }),
        services.GetRequiredService<IOptions<RecoveryOptions>>(),
        services.GetRequiredService<IPasswordHasher>(),
        services.GetRequiredService<IRecoveryPinHasher>(),
        services.GetRequiredService<TermsOfUse>(),
        TimeProvider.System);

    private async Task SeedAsync(string? phone, string? password, string? pin = null)
    {
        await using var scope = api.Services.CreateAsyncScope();
        (await Seeder(scope.ServiceProvider, phone, password, pin).SeedAsync(Ct)).Should().BeTrue();
    }

    private string Current => api.Services.GetRequiredService<TermsOfUse>().CurrentVersion;

    private Task<List<User>> AccountsAsync(string phone) => api.InDbAsync(db =>
        db.Users.IgnoreQueryFilters().AsNoTracking().Include(u => u.Interests).Include(u => u.Roles).Where(u => u.PhoneNumber == phone).ToListAsync(Ct));

    /// <summary>What a second run must leave exactly as it was.</summary>
    private static object Snapshot(User u) => new
    {
        u.Id, u.PasswordHash, u.SecurityStamp, u.RecoveryPinHash, u.RecoveryPinSetAt, u.Username, u.DisplayName, u.Bio,
        u.TermsVersion, u.TermsAcceptedAt, u.IsReviewAccount, u.MustChangePassword, u.MustSetRecoveryPin,
        Interests = u.Interests.Count, Roles = u.Roles.Count,
    };

    private Task<HttpResponseMessage> LoginAsync(string phone, string password) =>
        api.GuestClient().PostAsJsonAsync("/api/v1/auth/login", new { phoneNumber = phone, password }, Ct);

    [Fact]
    public async Task An_existing_account_is_adopted_without_touching_its_profile_and_a_second_run_changes_nothing()
    {
        var unique = $"Rv{Guid.NewGuid():N}"[..12];
        var person = await api.UserAsync($"{unique} Reviewer");
        (await person.Client.PatchAsJsonAsync("/api/v1/me", new
        {
            displayName = person.Me["displayName"]!.GetValue<string>(), username = person.Me["username"]!.GetValue<string>(), bio = "My own bio.",
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var searcher = await api.UserAsync("Reviewer Searcher");
        (await SuggestedUsersAsync(searcher, unique)).Should().Contain(person.Id, "found before it becomes the review account");

        // Everything that could stop a reviewer from signing in: a temporary password, the PIN screen, older terms.
        await api.InScopeAsync(async services =>
        {
            var db = services.GetRequiredService<AppDbContext>();
            var user = await db.Users.SingleAsync(u => u.Id == person.Id, Ct);
            user.ResetByAdmin(services.GetRequiredService<IPasswordHasher>().Hash("Temporary-pass-1"));
            user.RequireRecoveryPin();
            user.AcceptTerms("2020-01-01", DateTime.UtcNow.AddYears(-1));
            await db.SaveChangesAsync(Ct);
        });
        var before = (await AccountsAsync(person.PhoneNumber)).Single();

        await SeedAsync(person.PhoneNumber, ReviewPassword);

        var adopted = (await AccountsAsync(person.PhoneNumber)).Should().ContainSingle("never a second account").Subject;
        adopted.Id.Should().Be(person.Id);
        adopted.IsReviewAccount.Should().BeTrue();
        adopted.MustChangePassword.Should().BeFalse();
        adopted.MustSetRecoveryPin.Should().BeFalse();
        adopted.TermsVersion.Should().Be(Current);
        adopted.PasswordHash.Should().NotBe(before.PasswordHash, "the password differed, so it was reset");
        adopted.SecurityStamp.Should().NotBe(before.SecurityStamp, "a reset password ends the old sessions");
        adopted.DisplayName.Should().Be(before.DisplayName);
        adopted.Username.Should().Be(before.Username);
        adopted.Bio.Should().Be("My own bio.");
        adopted.Interests.Should().HaveCount(before.Interests.Count, "interests are never touched");

        (await LoginAsync(person.PhoneNumber, ReviewPassword)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await LoginAsync(person.PhoneNumber, "Temporary-pass-1")).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await SuggestedUsersAsync(searcher, unique)).Should().NotContain(person.Id, "the review account is never found");

        // Idempotent: the same configuration again leaves every column as it was.
        var once = Snapshot(adopted);
        await SeedAsync(person.PhoneNumber, ReviewPassword);
        Snapshot((await AccountsAsync(person.PhoneNumber)).Single()).Should().BeEquivalentTo(once);
    }

    [Fact]
    public async Task The_password_is_kept_when_it_already_matches()
    {
        var person = await api.UserAsync("Matching Reviewer");
        var before = (await AccountsAsync(person.PhoneNumber)).Single();

        await SeedAsync(person.PhoneNumber, ApiFactory.TestPassword);

        var adopted = (await AccountsAsync(person.PhoneNumber)).Single();
        adopted.IsReviewAccount.Should().BeTrue();
        adopted.PasswordHash.Should().Be(before.PasswordHash);
        adopted.SecurityStamp.Should().Be(before.SecurityStamp, "nothing changed, so the sessions go on");
        adopted.RecoveryPinHash.Should().Be(before.RecoveryPinHash);
        (await person.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task A_missing_account_is_created_ready_to_use_and_a_second_run_changes_nothing()
    {
        var phone = ApiFactory.NewPhoneNumber();

        await SeedAsync(phone, ReviewPassword, pin: "2468");

        var created = (await AccountsAsync(phone)).Should().ContainSingle().Subject;
        created.DisplayName.Should().Be(ReviewerAccountSeeder.DisplayName);
        created.Username.Should().MatchRegex("^readin_demo[0-9]*$");
        created.IsProfileComplete.Should().BeTrue();
        created.Interests.Count.Should().BeGreaterThanOrEqualTo(User.MinInterests);
        created.OnboardingCompleted.Should().BeTrue();
        created.TermsVersion.Should().Be(Current);
        created.IsReviewAccount.Should().BeTrue();
        created.MustChangePassword.Should().BeFalse();
        created.MustSetRecoveryPin.Should().BeFalse();
        created.Roles.Select(r => r.RoleId).Should().Equal(RoleIds.Member);
        api.Services.GetRequiredService<IRecoveryPinHasher>().Verify(created.Id, created.RecoveryPinHash!, "2468")
            .Should().BeTrue("Seed:ReviewerPin is the recovery PIN");

        var session = await ApiFactory.ReadSessionAsync(await LoginAsync(phone, ReviewPassword));
        session["user"]!["mustAcceptTerms"]!.GetValue<bool>().Should().BeFalse();
        session["user"]!["username"]!.GetValue<string>().Should().Be(created.Username);

        var once = Snapshot(created);
        await SeedAsync(phone, ReviewPassword, pin: "2468");
        Snapshot((await AccountsAsync(phone)).Should().ContainSingle().Subject).Should().BeEquivalentTo(once);

        // Another number gets a free variant of the username (only one review account is configured at a time).
        var other = ApiFactory.NewPhoneNumber();
        await SeedAsync(other, ReviewPassword);
        var second = (await AccountsAsync(other)).Single();
        second.Username.Should().NotBe(created.Username).And.MatchRegex("^readin_demo[0-9]*$");
        second.RecoveryPinHash.Should().NotBeNullOrEmpty("a random PIN when none is configured");
    }

    [Fact]
    public async Task Its_follows_are_left_out_of_counts_and_followers_lists()
    {
        var phone = ApiFactory.NewPhoneNumber();
        await SeedAsync(phone, ReviewPassword);
        var session = await ApiFactory.ReadSessionAsync(await LoginAsync(phone, ReviewPassword));
        var reviewer = api.ClientWithToken(session["accessToken"]!.GetValue<string>());
        var writer = await api.UserAsync("Followed Writer");
        var fan = await api.UserAsync("Real Fan");

        (await reviewer.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync())["followerCount"]!.GetValue<int>().Should().Be(0);
        (await fan.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync())["followerCount"]!.GetValue<int>().Should().Be(1);

        var profile = await api.GuestClient().GetAsync($"/api/v1/users/{writer.Me["username"]!.GetValue<string>()}", Ct).OkJsonAsync();
        profile["stats"]!["followers"]!.GetValue<int>().Should().Be(1);
        var followers = (await api.GuestClient().GetAsync($"/api/v1/users/{writer.Id}/followers", Ct).OkJsonAsync())["items"]!.AsArray();
        followers.Select(f => f!["id"]!.GetValue<Guid>()).Should().Equal(fan.Id);
    }

    [Fact]
    public async Task Without_a_phone_and_a_password_it_does_nothing_and_is_registered()
    {
        await using var scope = api.Services.CreateAsyncScope();
        scope.ServiceProvider.GetServices<ISeeder>().Should().Contain(s => s.Name == "reviewer-account");

        var reviewAccounts = await api.InDbAsync(db => db.Users.IgnoreQueryFilters().CountAsync(u => u.IsReviewAccount, Ct));
        await SeedAsync(null, null);
        await SeedAsync(ApiFactory.NewPhoneNumber(), "");
        await SeedAsync("not a number", ReviewPassword);
        (await api.InDbAsync(db => db.Users.IgnoreQueryFilters().CountAsync(u => u.IsReviewAccount, Ct))).Should().Be(reviewAccounts);

        // Unset: the same checksum every time, so the runner skips it; set: a new one, so every seed run checks the account.
        var unset = Seeder(scope.ServiceProvider, null, null);
        (await unset.ComputeChecksumAsync(Ct)).Should().Be(await unset.ComputeChecksumAsync(Ct));
        var configured = Seeder(scope.ServiceProvider, ApiFactory.NewPhoneNumber(), ReviewPassword);
        var first = await configured.ComputeChecksumAsync(Ct);
        await Task.Delay(5, Ct);
        (await configured.ComputeChecksumAsync(Ct)).Should().NotBe(first);
        first.Should().NotContain(ReviewPassword);
    }

    private static async Task<List<Guid>> SuggestedUsersAsync(SignedInUser viewer, string query) =>
        (await viewer.Client.GetAsync($"/api/v1/search/suggest?q={Uri.EscapeDataString(query)}", Ct).OkJsonAsync())["users"]!.AsArray()
            .Select(u => u!["id"]!.GetValue<Guid>()).ToList();
}
