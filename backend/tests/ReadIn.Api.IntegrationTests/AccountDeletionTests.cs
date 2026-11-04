using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using AwesomeAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Delete account (SPEC F01): immediate hard delete of the data map (SPEC §9.6), Apple revocation, idempotent retries.</summary>
[Collection(ApiCollection.Name)]
public sealed class AccountDeletionTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;
    private const string AppleClient = FakeExternalIdentityVerifier.AppleClientId;

    private FakeAppleTokenService Apple => (FakeAppleTokenService)api.Services.GetRequiredService<IAppleTokenService>();
    private FakeRealtimeAccountData Firebase => (FakeRealtimeAccountData)api.Services.GetRequiredService<IRealtimeAccountData>();

    private static Task<HttpResponseMessage> DeleteAccountAsync(HttpClient client, object body) =>
        client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me") { Content = JsonContent.Create(body) }, Ct);

    private static async Task<string> CodeOf(HttpResponseMessage response) =>
        (await TaxonomyAndContentTests.Problem(response))["code"]!.GetValue<string>();

    private static object AppleCredential(string subject, string? code = null) =>
        new { provider = "apple", idToken = subject, nonce = FakeExternalIdentityVerifier.AppleNonce, authorizationCode = code };

    private static string Unique(string prefix) => $"{prefix}-{Guid.NewGuid():N}";

    private async Task<(HttpClient Client, Guid Id)> ExternalAccountAsync(string provider, string subject, string? code = null)
    {
        var response = await api.GuestClient().PostAsJsonAsync("/api/v1/auth/external", new
        {
            provider,
            idToken = subject,
            nonce = provider == "apple" ? FakeExternalIdentityVerifier.AppleNonce : null,
            authorizationCode = code,
            createAccount = true,
        }, Ct);
        var session = await ApiFactory.ReadSessionAsync(response);
        return (api.ClientWithToken(session["accessToken"]!.GetValue<string>()), session["user"]!["id"]!.GetValue<Guid>());
    }

    private async Task<T> InDbAsync<T>(Func<AppDbContext, Task<T>> query)
    {
        using var scope = api.Services.CreateScope();
        return await query(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    [Fact]
    public async Task Deleting_removes_everything_in_the_data_map_at_once()
    {
        var user = await api.SignUpAsync();
        var client = user.Client;
        var fields = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!;
        (await client.PutAsJsonAsync("/api/v1/me/interests",
            new { fieldIds = fields.Take(3).Select(f => f!["id"]!.GetValue<Guid>()), topicIds = Array.Empty<Guid>() }, Ct)).EnsureSuccessStatusCode();
        (await client.PostAsJsonAsync("/api/v1/me/devices", new { token = Unique("fcm"), platform = "android" }, Ct)).EnsureSuccessStatusCode();

        using var form = new MultipartFormDataContent { { new StringContent("image"), "purpose" } };
        var image = new ByteArrayContent(await File.ReadAllBytesAsync(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", "medium.webp"), Ct));
        image.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
        form.Add(image, "file", "medium.webp");
        (await client.PostAsync("/api/v1/uploads/images", form, Ct)).StatusCode.Should().Be(HttpStatusCode.Created);

        var dotnet = fields.Single(f => f!["slug"]!.GetValue<string>() == "dotnet")!;
        await client.CreateDraftAsync(ArticleTestKit.Document(
            dotnet["id"]!.GetValue<Guid>(), "A draft that goes with its author", blocks: [ArticleTestKit.Paragraph("Draft.")]));

        // F17: a notification for the account, the account as the actor of someone else's, and a notification setting.
        var other = await api.UserAsync();
        await other.Client.PutEmptyAsync($"/api/v1/users/{user.Id}/follow").OkJsonAsync();
        await client.PutEmptyAsync($"/api/v1/users/{other.Id}/follow").OkJsonAsync();
        (await client.PutAsJsonAsync("/api/v1/me/notification-settings", new { types = new Dictionary<string, string> { ["mention"] = "off" } }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await InDbAsync(db => db.Notifications.CountAsync(n => n.UserId == user.Id, Ct))).Should().Be(1);
        (await InDbAsync(db => db.NotificationActors.CountAsync(a => a.ActorId == user.Id, Ct))).Should().Be(1);

        var files = await InDbAsync(async db => (await db.MediaAssets.AsNoTracking().Include(a => a.Pages)
                .Where(a => a.OwnerId == user.Id).ToListAsync(Ct))
            .SelectMany(a => a.StoredPaths())
            .Select(p => Path.Combine(api.UploadsPath, p["/uploads/".Length..].Replace('/', Path.DirectorySeparatorChar))).ToList());
        files.Should().NotBeEmpty().And.OnlyContain(f => File.Exists(f));

        var response = await DeleteAccountAsync(client, new { password = ApiFactory.TestPassword });
        response.StatusCode.Should().Be(HttpStatusCode.NoContent, await response.Content.ReadAsStringAsync(Ct));

        var left = await InDbAsync(async db => new
        {
            Users = await db.Users.IgnoreQueryFilters().CountAsync(u => u.Id == user.Id || u.PhoneNumber == user.PhoneNumber, Ct),
            Interests = await db.Set<UserInterest>().CountAsync(i => i.UserId == user.Id, Ct),
            Devices = await db.Set<UserDevice>().CountAsync(d => d.UserId == user.Id, Ct),
            Roles = await db.Set<UserRole>().CountAsync(r => r.UserId == user.Id, Ct),
            Sessions = await db.RefreshTokens.CountAsync(t => t.UserId == user.Id, Ct),
            Articles = await db.Articles.IgnoreQueryFilters().CountAsync(a => a.AuthorId == user.Id, Ct),
            Media = await db.MediaAssets.CountAsync(a => a.OwnerId == user.Id, Ct),
            Audit = await db.AuditLogs.Where(l => l.UserId == user.Id || l.ActorId == user.Id).ToListAsync(Ct),
            Notifications = await db.Notifications.CountAsync(n => n.UserId == user.Id, Ct),
            AsActor = await db.NotificationActors.CountAsync(a => a.ActorId == user.Id, Ct),
            NotificationSettings = await db.UserNotificationSettings.CountAsync(s => s.UserId == user.Id, Ct),
        });
        left.Users.Should().Be(0);
        left.Interests.Should().Be(0);
        left.Devices.Should().Be(0, "no push can reach a deleted account");
        left.Roles.Should().Be(0);
        left.Sessions.Should().Be(0);
        left.Articles.Should().Be(0, "drafts go with their author, and nothing keeps the account id");
        left.Media.Should().Be(0);
        left.Notifications.Should().Be(0);
        left.AsActor.Should().Be(0, "other people's notifications no longer name the account");
        left.NotificationSettings.Should().Be(0);
        files.Should().OnlyContain(f => !File.Exists(f), "uploaded files are deleted right after the commit");
        left.Audit.Should().ContainSingle("only the deletion record stays, with no personal data")
            .Which.Should().Match<AuditLog>(l => l.Action == AuditActions.AccountDeleted && l.Ip == null && l.ActorId == null);
        Firebase.DeletedIdentities.Should().Contain(user.Id, "the Firebase Auth record of the realtime token goes too");
        Firebase.DeletedLiveData.Should().Contain(user.Id);
    }

    [Fact]
    public async Task Published_articles_stay_as_by_a_deleted_user_with_the_images_they_show()
    {
        var leaving = await api.UserAsync("Leaving Writer");
        var reader = await api.UserAsync();
        var (otherArticle, _) = await reader.Client.PublishAsync();

        var shown = await UploadImageAsync(leaving.Client);
        var drafted = await UploadImageAsync(leaving.Client);
        var unused = await UploadImageAsync(leaving.Client);
        var fieldId = await leaving.Client.FieldIdAsync("dotnet");
        var (published, slug) = await leaving.Client.WriteAndPublishAsync(ArticleTestKit.Document(
            fieldId, "Stays after its author leaves", attachments: [new { mediaAssetId = shown["id"], order = 0, altText = "A photo" }]));
        var draft = (await leaving.Client.CreateDraftAsync(ArticleTestKit.Document(
            fieldId, "A draft that goes with its author", attachments: [new { mediaAssetId = drafted["id"], order = 0, altText = "A photo" }])))["id"]!
            .GetValue<Guid>();

        await reader.Client.ReactAsync(published, "love").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/users/{leaving.Id}/follow").OkJsonAsync();
        await leaving.Client.PutEmptyAsync($"/api/v1/users/{reader.Id}/follow").OkJsonAsync();
        await leaving.Client.ReactAsync(otherArticle, "fire").OkJsonAsync();
        (await leaving.Client.PutEmptyAsync($"/api/v1/me/saved/{otherArticle}")).EnsureSuccessStatusCode();
        (await leaving.Client.PatchAsJsonAsync("/api/v1/me", new
        {
            displayName = "Leaving Writer",
            username = leaving.Me["username"]!.GetValue<string>(),
            expertiseFieldIds = new[] { await leaving.Client.FieldIdAsync("dotnet") },
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var files = await InDbAsync(async db => (await db.MediaAssets.AsNoTracking().Include(a => a.Pages)
                .Where(a => a.OwnerId == leaving.Id).ToListAsync(Ct))
            .ToDictionary(a => a.Id, a => a.StoredPaths().Select(OnDisk).ToList()));
        files.Values.SelectMany(f => f).Should().OnlyContain(f => File.Exists(f));

        (await DeleteAccountAsync(leaving.Client, new { password = ApiFactory.TestPassword })).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var article = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!;
        article["author"].Should().BeNull("readers see \"Deleted user\"");
        article["attachments"]!["images"]!.AsArray().Should().ContainSingle();
        article["reactions"]!["love"]!.GetValue<int>().Should().Be(1, "other people's reactions stay");
        (await reader.Client.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["isFollowingAuthor"]!.GetValue<bool>().Should().BeFalse();

        var shownId = shown["id"]!.GetValue<Guid>();
        files[shownId].Should().OnlyContain(f => File.Exists(f), "the published article still shows it");
        files.Where(f => f.Key != shownId).SelectMany(f => f.Value).Should().OnlyContain(f => !File.Exists(f), "the draft's image and the unused upload go");

        var left = await InDbAsync(async db => new
        {
            Draft = await db.Articles.IgnoreQueryFilters().AnyAsync(a => a.Id == draft, Ct),
            Kept = await db.Articles.IgnoreQueryFilters().AsNoTracking().SingleAsync(a => a.Id == published, Ct),
            WorkingCopy = await db.ArticleDrafts.AnyAsync(d => d.ArticleId == published, Ct),
            Media = await db.MediaAssets.AsNoTracking().Where(a => a.Id == shownId || a.OwnerId == leaving.Id
                || a.Id == drafted["id"]!.GetValue<Guid>() || a.Id == unused["id"]!.GetValue<Guid>()).ToListAsync(Ct),
            Follows = await db.UserFollows.CountAsync(f => f.FollowerId == leaving.Id || f.FolloweeId == leaving.Id, Ct),
            Expertise = await db.Set<UserExpertiseField>().CountAsync(e => e.UserId == leaving.Id, Ct),
            Other = await db.Articles.AsNoTracking().SingleAsync(a => a.Id == otherArticle, Ct),
        });
        left.Draft.Should().BeFalse();
        left.WorkingCopy.Should().BeFalse("the kept article's private working copy (F05) is unpublished work");
        (left.Kept.AuthorId, left.Kept.CreatedBy, left.Kept.UpdatedBy).Should().Be((null, null, null), "nothing links it to the account any more");
        left.Media.Should().ContainSingle().Which.Should().Match<Domain.Media.MediaAsset>(a => a.Id == shownId && a.OwnerId == null && a.CreatedBy == null);
        left.Follows.Should().Be(0, "both directions go");
        left.Expertise.Should().Be(0);
        (left.Other.FireCount, left.Other.ReactionCount, left.Other.SaveCount).Should().Be((0, 0, 0), "counters are recomputed without the account");
        api.Realtime.CountersFor(otherArticle)[^1].Should().Be(new ArticleLiveCounters(0, 0, 0, 0, 0, 0));
    }

    [Fact]
    public async Task Comments_stay_as_by_a_deleted_user_while_its_likes_reports_and_moderator_links_go()
    {
        var leaving = await api.UserAsync("Leaving Commenter");
        var reader = await api.UserAsync();
        var (article, _) = await reader.Client.PublishAsync();
        var (hidden, _) = await reader.Client.PublishAsync();

        var kept = await CommentAsync(leaving.Client, article, "A comment that stays");
        var removed = await CommentAsync(leaving.Client, article, "A comment its author deleted");
        (await leaving.Client.DeleteAsync($"/api/v1/comments/{removed}", Ct)).EnsureSuccessStatusCode();
        var liked = await CommentAsync(reader.Client, article, "A comment the leaving account liked");
        (await leaving.Client.PutAsync($"/api/v1/comments/{liked}/like", null, Ct)).EnsureSuccessStatusCode();
        (await leaving.Client.PostAsJsonAsync("/api/v1/reports", new { targetType = "comment", targetId = liked, reason = "spam" }, Ct)).EnsureSuccessStatusCode();
        (await reader.Client.PostAsJsonAsync("/api/v1/reports", new { targetType = "comment", targetId = kept, reason = "spam" }, Ct)).EnsureSuccessStatusCode();
        // As if the account were a moderator: it hid the reader's comment and article and resolved the report on its own
        // comment. The moderation log (F22) names it both as the moderator and as a warned user.
        await InDbAsync(async db =>
        {
            await db.Comments.Where(c => c.Id == liked).ExecuteUpdateAsync(s => s.SetProperty(c => c.HiddenById, leaving.Id), Ct);
            var now = DateTime.UtcNow;
            (await db.Articles.SingleAsync(a => a.Id == hidden, Ct)).Hide(leaving.Id, now);
            db.ModerationActions.Add(Domain.Moderation.ModerationAction.OnArticle(
                Domain.Moderation.ModerationActionTypes.ArticleHide, hidden, reader.Id, "Hidden", leaving.Id, null, 0, now));
            db.ModerationActions.Add(Domain.Moderation.ModerationAction.Warning(leaving.Id, "leaving", reader.Id, "Be kind", 0, now));
            await db.SaveChangesAsync(Ct);
            return await db.Reports.Where(r => r.TargetId == kept).ExecuteUpdateAsync(s => s.SetProperty(r => r.ResolvedById, leaving.Id), Ct);
        });
        (await InDbAsync(db => db.Comments.Where(c => c.Id == kept).Select(c => c.CreatedBy).SingleAsync(Ct))).Should().Be(leaving.Id);

        (await DeleteAccountAsync(leaving.Client, new { password = ApiFactory.TestPassword })).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var items = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{article}/comments?sort=new", Ct))!["items"]!.AsArray();
        var shown = items.Should().ContainSingle(c => c!["id"]!.GetValue<Guid>() == kept).Subject!;
        shown["author"].Should().BeNull("readers see \"Deleted user\"");
        shown["body"]!.GetValue<string>().Should().Be("A comment that stays");

        var left = await InDbAsync(async db => new
        {
            Comments = await db.Comments.IgnoreQueryFilters().AsNoTracking()
                .Where(c => c.Id == kept || c.Id == removed || c.Id == liked).ToDictionaryAsync(c => c.Id, Ct),
            Likes = await db.CommentLikes.CountAsync(l => l.UserId == leaving.Id, Ct),
            Reports = await db.Reports.AsNoTracking().Where(r => r.ReporterId == leaving.Id || r.TargetId == kept).ToListAsync(Ct),
            Hidden = await db.Articles.IgnoreQueryFilters().AsNoTracking().Where(a => a.Id == hidden)
                .Select(a => new { a.HiddenAt, a.HiddenById }).SingleAsync(Ct),
            Log = await db.ModerationActions.AsNoTracking().Where(m => m.TargetId == hidden || m.TargetId == leaving.Id).ToListAsync(Ct),
        });
        (left.Comments[kept].AuthorId, left.Comments[kept].CreatedBy, left.Comments[kept].UpdatedBy).Should().Be((null, null, null));
        left.Comments[removed].Body.Should().BeEmpty("a comment its author deleted keeps no text");
        (left.Comments[liked].LikeCount, left.Comments[liked].HiddenById).Should().Be((0, null));
        left.Likes.Should().Be(0);
        left.Reports.Should().ContainSingle("the account's own reports go, reports on what stays stay")
            .Which.Should().Match<Domain.Moderation.Report>(r => r.TargetId == kept && r.ResolvedById == null);
        left.Hidden.HiddenAt.Should().NotBeNull("the article stays hidden");
        left.Hidden.HiddenById.Should().BeNull();
        left.Log.Should().HaveCount(2, "the moderation log keeps its entries")
            .And.OnlyContain(m => m.ModeratorId != leaving.Id && m.TargetUserId != leaving.Id);
        left.Log.Should().ContainSingle(m => m.ModeratorId == null).And.ContainSingle(m => m.TargetUserId == null);
    }

    private static async Task<Guid> CommentAsync(HttpClient client, Guid articleId, string body)
    {
        var response = await client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
    }

    private static async Task<JsonObject> UploadImageAsync(HttpClient client)
    {
        using var form = new MultipartFormDataContent { { new StringContent("image"), "purpose" } };
        var image = new ByteArrayContent(await File.ReadAllBytesAsync(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", "medium.webp"), Ct));
        image.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
        form.Add(image, "file", "medium.webp");
        var response = await client.PostAsync("/api/v1/uploads/images", form, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
    }

    private string OnDisk(string path) =>
        Path.Combine(api.UploadsPath, path["/uploads/".Length..].Replace('/', Path.DirectorySeparatorChar));

    [Fact]
    public async Task Verification_requests_and_their_private_files_go_and_decisions_lose_the_reviewer()
    {
        // F19: the leaving account is an admin who decided someone's request, and has requests of its own.
        var leaving = await api.UserAsync("Leaving Admin");
        await InDbAsync(async db =>
        {
            (await db.Users.Include(u => u.Roles).SingleAsync(u => u.Id == leaving.Id, Ct)).GrantRole(Application.Common.Security.RoleIds.Admin);
            return await db.SaveChangesAsync(Ct);
        });
        using (var scope = api.Services.CreateScope())
            await scope.ServiceProvider.GetRequiredService<Application.Common.Security.IUserAccessService>().InvalidateAsync(leaving.Id, Ct);
        var writer = await api.UserAsync();
        var fieldId = await writer.Client.FieldIdAsync("dotnet");

        var decided = await SubmitVerificationAsync(writer.Client, fieldId, file: null);
        (await leaving.Client.PostAsync($"/api/v1/admin/verification-requests/{decided}/approve", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var own = await SubmitVerificationAsync(leaving.Client, fieldId,
            await File.ReadAllBytesAsync(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", "small.png"), Ct));
        var proof = Path.Combine(api.PrivatePath, "verification", $"{own}.png");
        File.Exists(proof).Should().BeTrue();

        (await DeleteAccountAsync(leaving.Client, new { password = ApiFactory.TestPassword })).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await InDbAsync(db => db.VerificationRequests.CountAsync(r => r.UserId == leaving.Id, Ct))).Should().Be(0, "its requests go with it");
        File.Exists(proof).Should().BeFalse("its proof files are deleted right after the commit");
        var kept = await InDbAsync(db => db.VerificationRequests.AsNoTracking().SingleAsync(r => r.Id == decided, Ct));
        (kept.Status, kept.DecidedById, kept.DecidedAt is null).Should().Be((Domain.Verification.VerificationStatus.Approved, null, false),
            "the decision stays without the reviewer");
        (await writer.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["isVerified"]!.GetValue<bool>().Should().BeTrue();
    }

    private static async Task<Guid> SubmitVerificationAsync(HttpClient client, Guid fieldId, byte[]? file)
    {
        using var form = new MultipartFormDataContent
        {
            { new StringContent(fieldId.ToString()), "fieldId" },
            { new StringContent("Engineer"), "jobTitle" },
            { new StringContent("https://github.com/someone"), "proofUrl" },
        };
        if (file is not null) form.Add(new ByteArrayContent(file), "proof", "card.png");
        var response = await client.PostAsync("/api/v1/verification-requests", form, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
    }

    [Fact]
    public async Task The_old_token_stops_working_and_a_retry_still_answers_204()
    {
        var user = await api.SignUpAsync();

        (await DeleteAccountAsync(user.Client, new { password = ApiFactory.TestPassword })).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await user.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await user.Client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds = Array.Empty<Guid>(), topicIds = Array.Empty<Guid>() }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await api.GuestClient().PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = user.RefreshToken }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.Unauthorized, "the refresh token went with the account");

        var retry = await DeleteAccountAsync(user.Client, new { password = ApiFactory.TestPassword });
        retry.StatusCode.Should().Be(HttpStatusCode.NoContent, "a retry after a lost response gets the same answer, never a 500");
        (await DeleteAccountAsync(user.Client, new { password = "anything" })).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await DeleteAccountAsync(api.GuestClient(), new { password = ApiFactory.TestPassword }))
            .StatusCode.Should().Be(HttpStatusCode.Unauthorized, "without a token nothing is confirmed");
    }

    [Fact]
    public async Task A_wrong_password_deletes_nothing()
    {
        var user = await api.SignUpAsync();

        var response = await DeleteAccountAsync(user.Client, new { password = "not-the-password-1" });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await CodeOf(response)).Should().Be("auth.wrong_password");
        (await user.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await DeleteAccountAsync(user.Client, new { })).StatusCode.Should().Be(HttpStatusCode.BadRequest, "confirmation is required");
    }

    [Fact]
    public async Task The_same_phone_number_signs_up_again_as_a_clean_new_account()
    {
        var user = await api.SignUpAsync();
        var fields = (await user.Client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!;
        (await user.Client.PutAsJsonAsync("/api/v1/me/interests",
            new { fieldIds = fields.Take(3).Select(f => f!["id"]!.GetValue<Guid>()), topicIds = Array.Empty<Guid>() }, Ct)).EnsureSuccessStatusCode();
        (await DeleteAccountAsync(user.Client, new { password = ApiFactory.TestPassword })).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var again = await ApiFactory.ReadSessionAsync(await api.GuestClient().PostAsJsonAsync("/api/v1/auth/register", new
        {
            phoneNumber = user.PhoneNumber, password = ApiFactory.TestPassword, recoveryPin = ApiFactory.TestPin, uiLanguage = "en", timeZone = "Africa/Cairo",
        }, Ct));

        var me = again["user"]!.AsObject();
        me["id"]!.GetValue<Guid>().Should().NotBe(user.Id);
        me["onboardingCompleted"]!.GetValue<bool>().Should().BeFalse("nothing carries over from the deleted account");
        me["interests"]!["fieldIds"]!.AsArray().Should().BeEmpty();
        me["isProfileComplete"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task Apple_tokens_are_revoked_first_and_the_Apple_ID_can_sign_up_again()
    {
        var subject = Unique("apple");
        var signInCode = Unique("code");
        var (client, id) = await ExternalAccountAsync("apple", subject, signInCode);

        var stored = await InDbAsync(db => db.Set<ExternalLogin>().AsNoTracking().SingleAsync(l => l.UserId == id, Ct));
        stored.ProviderClientId.Should().Be(AppleClient);
        stored.ProviderRefreshToken.Should().StartWith("v1.").And.NotContain(signInCode, "it is stored encrypted");

        var confirmCode = Unique("code");
        var response = await DeleteAccountAsync(client, new { external = AppleCredential(subject, confirmCode) });

        response.StatusCode.Should().Be(HttpStatusCode.NoContent, await response.Content.ReadAsStringAsync(Ct));
        Apple.Revoked.Should().Contain((AppleClient, $"refresh-{confirmCode}")).And.Contain((AppleClient, $"refresh-{signInCode}"));
        (await InDbAsync(db => db.Set<ExternalLogin>().AnyAsync(l => l.Subject == subject, Ct))).Should().BeFalse("no orphan row keyed by the sub");

        var (_, newId) = await ExternalAccountAsync("apple", subject);
        newId.Should().NotBe(id, "the same Apple sub starts a fresh account");
    }

    [Fact]
    public async Task A_password_confirmation_revokes_the_stored_Apple_token()
    {
        var phoneUser = await api.SignUpAsync();
        var subject = Unique("apple");
        var linkCode = Unique("code");
        (await phoneUser.Client.PostAsJsonAsync("/api/v1/me/external-logins",
            new { credential = AppleCredential(subject, linkCode), password = ApiFactory.TestPassword }, Ct)).EnsureSuccessStatusCode();

        (await DeleteAccountAsync(phoneUser.Client, new { password = ApiFactory.TestPassword })).StatusCode.Should().Be(HttpStatusCode.NoContent);

        Apple.Revoked.Should().Contain((AppleClient, $"refresh-{linkCode}"));
    }

    [Fact]
    public async Task When_Apple_is_unreachable_nothing_is_deleted()
    {
        var subject = Unique("apple");
        var (client, _) = await ExternalAccountAsync("apple", subject, Unique("apple-down"));

        var response = await DeleteAccountAsync(client, new { external = AppleCredential(subject) });

        response.StatusCode.Should().Be(HttpStatusCode.ServiceUnavailable);
        (await CodeOf(response)).Should().Be("account.deletion_unavailable");
        (await client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK, "a failure is never reported as success");
    }

    [Fact]
    public async Task When_Firebase_is_unreachable_nothing_is_deleted()
    {
        var user = await api.SignUpAsync();
        Firebase.Unreachable[user.Id] = true;

        var response = await DeleteAccountAsync(user.Client, new { password = ApiFactory.TestPassword });

        response.StatusCode.Should().Be(HttpStatusCode.ServiceUnavailable);
        (await CodeOf(response)).Should().Be("account.deletion_unavailable");
        (await user.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK, "a failure is never reported as success");
    }

    [Fact]
    public async Task Without_a_stored_Apple_token_the_account_confirms_with_Apple()
    {
        var subject = Unique("apple");
        var (client, _) = await ExternalAccountAsync("apple", subject); // signed in without a code: nothing to revoke yet

        var withoutCode = await DeleteAccountAsync(client, new { external = AppleCredential(subject) });
        withoutCode.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await CodeOf(withoutCode)).Should().Be("auth.apple_confirmation_required");
        (await client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);

        var code = Unique("code");
        (await DeleteAccountAsync(client, new { external = AppleCredential(subject, code) })).StatusCode.Should().Be(HttpStatusCode.NoContent);
        Apple.Revoked.Should().Contain((AppleClient, $"refresh-{code}"));
    }

    [Fact]
    public async Task Deleting_removes_both_linked_providers()
    {
        var appleSubject = Unique("apple");
        var googleSubject = Unique("google");
        var appleCode = Unique("code");
        var (client, id) = await ExternalAccountAsync("apple", appleSubject, appleCode);
        (await client.PostAsJsonAsync("/api/v1/me/external-logins",
            new { credential = new { provider = "google", idToken = googleSubject }, external = AppleCredential(appleSubject) }, Ct)).EnsureSuccessStatusCode();

        (await DeleteAccountAsync(client, new { external = new { provider = "google", idToken = googleSubject } }))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        Apple.Revoked.Should().Contain((AppleClient, $"refresh-{appleCode}"), "the stored Apple token is revoked whichever provider confirmed");
        (await InDbAsync(db => db.Set<ExternalLogin>().AnyAsync(l => l.UserId == id, Ct))).Should().BeFalse();
        (await ExternalAccountAsync("google", googleSubject)).Id.Should().NotBe(id);
        (await ExternalAccountAsync("apple", appleSubject)).Id.Should().NotBe(id);
    }
}
