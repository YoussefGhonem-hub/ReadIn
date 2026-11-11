using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.WriterCategories;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Media;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Reading;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Content;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// SPEC §18.1 "Articles are real content in every environment": every seeded article is @readin's and comes from
/// <c>content/articles</c> (here the fixture content), as text with only its own cover; demo accounts have no articles of
/// any status and no demo seeder runs in production. Local databases made before the rule lose exactly the old demo
/// articles and the removed "Verified Writer" account (<see cref="DemoArticlesCleanupSeeder"/>, Development only).
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class SeedRulesTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Every_seeded_article_is_readins_text_and_demo_accounts_have_none()
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var content = scope.ServiceProvider.GetRequiredService<ContentRepository>();
        var slugs = new List<string>();
        foreach (var folder in content.ArticleFolders()) slugs.Add((await content.ReadMetaAsync(folder, Ct)).Slug);

        var seeded = await db.Articles.IgnoreQueryFilters().AsNoTracking().Where(a => slugs.Contains(a.Slug))
            .Select(a => new { a.Id, a.AuthorId }).ToListAsync(Ct);
        seeded.Should().HaveCount(slugs.Count).And.OnlyContain(a => a.AuthorId == SystemUsers.EditorialId);
        (await db.Articles.IgnoreQueryFilters().CountAsync(a => a.AuthorId == SystemUsers.SuperAdminId
            || (a.Author!.Email != null && a.Author.Email.EndsWith("@readin.test")), Ct))
            .Should().Be(0, "demo accounts and the SuperAdmin have no articles of any status, drafts included");
        var oldSlugs = DemoArticlesCleanupSeeder.OldArticles.Select(o => o.Slug).ToList();
        (await db.Articles.IgnoreQueryFilters().AnyAsync(a => oldSlugs.Contains(a.Slug), Ct)).Should().BeFalse("no demo article is seeded");
        (await db.Users.IgnoreQueryFilters().AnyAsync(u => u.PhoneNumber == "+12025550106" || u.Username == "writer_verified", Ct))
            .Should().BeFalse("the \"Verified Writer\" demo account is gone");

        // Text only: no attachments, and the seed accounts' uploads are avatars and the articles' own covers.
        var ids = seeded.Select(a => a.Id).ToList();
        (await db.ArticleAttachments.CountAsync(x => ids.Contains(x.ArticleId), Ct)).Should().Be(0);
        var seedAccounts = db.Users.IgnoreQueryFilters()
            .Where(u => u.Id == SystemUsers.EditorialId || u.Id == SystemUsers.SuperAdminId || (u.Email != null && u.Email.EndsWith("@readin.test")))
            .Select(u => u.Id);
        (await db.MediaAssets.Where(m => m.OwnerId != null && seedAccounts.Contains(m.OwnerId.Value)).Select(m => m.Purpose).Distinct().ToListAsync(Ct))
            .Should().BeSubsetOf([MediaPurpose.Avatar, MediaPurpose.Cover], "no demo photos or PDFs");
        (await db.MediaAssets.CountAsync(m => m.OwnerId == SystemUsers.EditorialId && m.Purpose == MediaPurpose.Cover, Ct))
            .Should().BeLessThanOrEqualTo(slugs.Count, "one cover per article at most");

        // Demo interactions are on @readin's articles only.
        var demoUsers = db.Users.Where(u => u.Email != null && u.Email.EndsWith("@readin.test")).Select(u => u.Id);
        var notReadins = db.Articles.IgnoreQueryFilters().Where(a => a.AuthorId != SystemUsers.EditorialId).Select(a => a.Id);
        (await db.Reactions.CountAsync(r => demoUsers.Contains(r.UserId) && notReadins.Contains(r.ArticleId), Ct)).Should().Be(0);
        (await db.SavedArticles.CountAsync(s => demoUsers.Contains(s.UserId) && notReadins.Contains(s.ArticleId), Ct)).Should().Be(0);
        (await db.ReadingProgress.CountAsync(r => demoUsers.Contains(r.UserId) && notReadins.Contains(r.ArticleId), Ct)).Should().Be(0);
        (await db.Comments.IgnoreQueryFilters().CountAsync(c => c.AuthorId != null && demoUsers.Contains(c.AuthorId.Value)
            && notReadins.Contains(c.ArticleId), Ct)).Should().Be(0);
        (await db.Comments.CountAsync(c => c.AuthorId != null && demoUsers.Contains(c.AuthorId.Value), Ct))
            .Should().BeGreaterThan(0, "the demo comments are there, on @readin's articles");
    }

    [Fact]
    public async Task Readin_has_its_headline_and_every_demo_writer_a_headline_and_one_to_three_links()
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var official = await db.Users.AsNoTracking().SingleAsync(u => u.Id == SystemUsers.EditorialId, Ct);
        official.Headline.Should().Be("مقال كل يوم يفرق معاك", "@readin's title, in every environment (system seed)");
        official.Links.Should().BeEmpty("@readin has no social accounts");

        string[] writers = ["reviewer.dotnet@readin.test", "reviewer.ai@readin.test", "writer1@readin.test", "writer2@readin.test", "writer3@readin.test"];
        var demo = await db.Users.AsNoTracking().Where(u => u.Email != null && writers.Contains(u.Email)).ToListAsync(Ct);
        demo.Should().HaveCount(writers.Length);
        foreach (var writer in demo)
        {
            writer.Headline.Should().NotBeNullOrWhiteSpace($"{writer.Username} has a title");
            HeadlineRules.Problem(writer.Headline).Should().BeNull("a one-line title of at most 120 characters");
            writer.Links.Should().HaveCountGreaterThanOrEqualTo(1).And.HaveCountLessThanOrEqualTo(3);
            ProfileLinkRules.Check(writer.Links).IsSuccess.Should().BeTrue($"{writer.Username}'s links follow the F14 rules");
        }
        demo.SelectMany(u => u.Links).Select(l => l.Platform).Distinct().Should().HaveCountGreaterThan(3, "the demo shows several platforms, Other included")
            .And.Contain(LinkPlatforms.Other);
        (await db.Users.AsNoTracking().SingleAsync(u => u.Email == "reader10@readin.test", Ct)).Headline.Should().BeNull();
    }

    [Fact]
    public async Task No_demo_seeder_runs_in_production_and_the_removed_ones_are_gone()
    {
        await using var scope = api.Services.CreateAsyncScope();
        var seeders = scope.ServiceProvider.GetServices<ISeeder>().ToList();

        seeders.Where(s => s.AppliesTo(new TestEnvironment(Environments.Production))).Select(s => s.Name).Should().BeEquivalentTo(
            ["roles-and-permissions", "taxonomy", "system-accounts", "official-account-avatar", "articles", "learning-paths", "glossary",
             "content-filter", "terms-acceptance", "reviewer-account", "starter-duas"],
            "production gets the reference data, the system accounts, @readin's articles, the content filter's word lists, the " +
            "system accounts' terms acceptance, the App Review account and the SuperAdmin's starter du'as (SPEC F37, F38, " +
            "§18.3), nothing else");
        seeders.Where(s => s.Name.StartsWith("demo-", StringComparison.Ordinal))
            .Should().OnlyContain(s => !s.AppliesTo(new TestEnvironment(Environments.Production)) && !s.AppliesTo(new TestEnvironment(Environments.Staging)));
        seeders.Select(s => s.Name).Should().NotContain(["demo-writers", "demo-media", "demo-editor", "demo-categories"],
            "demo accounts have no articles, so nothing seeds articles or categories for them");
    }

    [Fact]
    public async Task The_development_cleanup_deletes_exactly_the_old_demo_articles_and_account_and_keeps_everything_else()
    {
        await using var scope = api.Services.CreateAsyncScope();
        var services = scope.ServiceProvider;
        var db = services.GetRequiredService<AppDbContext>();
        var seeder = services.GetServices<ISeeder>().Single(s => s.Name == "demo-articles-cleanup");
        seeder.AppliesTo(new TestEnvironment(Environments.Development)).Should().BeTrue();
        seeder.AppliesTo(new TestEnvironment("Testing")).Should().BeFalse("only local Development databases still have the old demo articles");
        seeder.AppliesTo(new TestEnvironment(Environments.Production)).Should().BeFalse();
        var nothingToDo = await seeder.ComputeChecksumAsync(Ct);

        var now = DateTime.UtcNow;
        var u = $"{Guid.NewGuid():N}"[..8];
        var field = await db.Fields.FirstAsync(f => f.Slug == "dotnet", Ct);
        var users = await db.Users.Where(x => x.Email != null && x.Email.EndsWith("@readin.test"))
            .ToDictionaryAsync(x => x.Email!.Replace("@readin.test", string.Empty), x => x.Id, Ct);
        var stranger = (await api.UserAsync("Not a demo writer")).Id;
        var created = new List<Guid>();
        var categories = new List<Guid>();
        var verified = User.CreateSeeded(DemoArticlesCleanupSeeder.RemovedAccountPhone, "Verified Writer", "writer_verified",
            email: DemoArticlesCleanupSeeder.RemovedAccountEmail);

        try
        {
            // An older local database: the removed "Verified Writer" and everything the removed demo seeders made.
            db.Users.Add(verified);
            await db.SaveChangesAsync(Ct);
            users["writer.verified"] = verified.Id;

            var photo = await SeedImages.ImportAsync(services.GetRequiredService<IImageProcessor>(), services.GetRequiredService<IFileStorage>(), db,
                users["writer1"], UploadPurpose.ArticleImage, File.ReadAllBytes(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", "small.png")),
                now, Ct);
            await db.SaveChangesAsync(Ct);
            var photoFiles = photo.Value.StoredPaths().ToList();

            var old = new Dictionary<string, Guid>();
            foreach (var plan in DemoArticlesCleanupSeeder.OldArticles.Where(o => o.Slug != "flutter-feature-first-folders"))
            {
                var draft = plan.Slug.EndsWith("-draft", StringComparison.Ordinal);
                old[plan.Slug] = await ArticleAsync(users[plan.Handle], plan.Slug, publish: !draft,
                    plan.Slug == "demo-media-angular-workshop" ? photo.Value : null);
            }
            created.AddRange(old.Values);
            // Soft-deleted by an older test run: found all the same.
            await db.Articles.Where(a => a.Id == old["demo-writers-asnotracking"])
                .ExecuteUpdateAsync(s => s.SetProperty(a => a.IsDeleted, true).SetProperty(a => a.DeletedAt, now), Ct);

            // What must stay: an old seed slug by someone else, other articles of demo writers, @readin's articles.
            var sameSlug = await ArticleAsync(stranger, "flutter-feature-first-folders", publish: true);
            var writer1Kept = await ArticleAsync(users["writer1"], $"kept-{u}", publish: true);
            var writer2Kept = await ArticleAsync(users["writer2"], $"kept2-{u}", publish: true);
            created.AddRange([sameSlug, writer1Kept, writer2Kept]);
            var readinArticle = await db.Articles.Where(a => a.AuthorId == SystemUsers.EditorialId && a.Status == ArticleStatus.Published)
                .Select(a => a.Id).FirstAsync(Ct);

            // Dependants of an old article, and the same kinds on articles that stay (@readin's keep their demo interactions).
            var covering = old["demo-writers-covering-indexes"];
            foreach (var articleId in new[] { covering, writer1Kept, sameSlug })
            {
                var comment = Comment.Post(articleId, users["reader1"], $"Cleanup test {u}", [], now);
                db.Comments.Add(comment);
                var reply = Comment.Reply(comment, users["reader2"], $"Cleanup reply {u}", [], now).Value;
                db.Comments.Add(reply);
                db.Add(Reaction.Set(null, users["reader3"], articleId, ReactionType.Love, now));
                db.Add(SavedArticle.Create(users["reader4"], articleId, now));
                db.ReadingProgress.Add(ReadingProgress.SeededCompleted(users["reader7"], articleId, "en", 60, now));
                await SaveWithoutEventsAsync();
                db.Notifications.Add(Notification.Create(users["writer2"], NotificationTypes.ArticleComment, now, null, null, $"cleanup:{u}:{articleId}:c",
                    articleId, comment.Id, null, users["reader1"], now));
                db.Notifications.Add(Notification.Create(users["reader1"], NotificationTypes.CommentReply, now, null, null, $"cleanup:{u}:{articleId}:r",
                    null, reply.Id, null, users["reader2"], now));
                db.Reports.Add(Report.File(ReportTargetType.Article, articleId, users["reader5"], ReportReason.Spam, null, now));
                db.Reports.Add(Report.File(ReportTargetType.Comment, comment.Id, users["reader6"], ReportReason.Spam, null, now));
                await SaveWithoutEventsAsync();
            }

            // The removed account's own rows on what stays: a reaction, a save, a comment, follows both ways, a notification.
            db.Add(Reaction.Set(null, verified.Id, writer1Kept, ReactionType.Love, now));
            db.Add(SavedArticle.Create(verified.Id, writer1Kept, now));
            var verifiedComment = Comment.Post(writer1Kept, verified.Id, $"Verified writer's comment {u}", [], now);
            db.Comments.Add(verifiedComment);
            db.Add(UserFollow.Create(users["reader1"], verified.Id, now).Value);
            db.Add(UserFollow.Create(verified.Id, users["reader2"], now).Value);
            await SaveWithoutEventsAsync();
            db.Notifications.Add(Notification.Create(verified.Id, NotificationTypes.CommentReply, now, null, null, $"cleanup:{u}:verified",
                null, verifiedComment.Id, null, users["reader1"], now));
            await SaveWithoutEventsAsync();

            // The old demo categories, and categories that must stay: one that still holds another article, other names, other people.
            var angular = await CategoryAsync(users["writer1"], "ورش Angular", old["demo-media-angular-workshop"]);
            var typescript = await CategoryAsync(users["writer1"], "TypeScript");
            var cheatSheets = await CategoryAsync(users["writer.verified"], "Cheat sheets", old["demo-media-clean-architecture-pdf"]);
            var databases = await CategoryAsync(users["writer2"], "قواعد البيانات", covering, writer2Kept);
            var rag = await CategoryAsync(users["reviewer.ai"], "RAG", old["demo-writers-rag-retrieval-first"]);
            var prompts = await CategoryAsync(users["reviewer.ai"], "Prompt engineering", old["demo-writers-prompt-examples"]);
            var otherRag = await CategoryAsync(stranger, "RAG");
            var otherName = await CategoryAsync(users["writer3"], "TypeScript");

            var oldIds = old.Values.ToList();
            var before = await SnapshotAsync(oldIds);
            (await seeder.ComputeChecksumAsync(Ct)).Should().NotBe(nothingToDo, "there is something to delete");

            (await seeder.SeedAsync(Ct)).Should().BeTrue();
            db.ChangeTracker.Clear();

            (await db.Articles.IgnoreQueryFilters().CountAsync(a => oldIds.Contains(a.Id), Ct)).Should().Be(0, "every old demo article goes, drafts and deleted ones too");
            (await db.Articles.IgnoreQueryFilters().CountAsync(a => new[] { sameSlug, writer1Kept, writer2Kept, readinArticle }.Contains(a.Id), Ct)).Should().Be(4);
            var after = await SnapshotAsync(oldIds);
            after.Should().Be(before with
            {
                Articles = before.Articles - oldIds.Count,
                OldDependants = 0,
                OtherReactions = before.OtherReactions - 1,
                OtherSaves = before.OtherSaves - 1,
                OtherNotifications = before.OtherNotifications - 1,
                Media = before.Media - 1,
                Categories = before.Categories - 5,
                Users = before.Users - 1,
            }, "only the old demo articles, their dependants, their photo, the demo categories left empty and the removed account "
               + "with its reaction, save and notification go");
            (await db.MediaAssets.AnyAsync(m => m.Id == photo.Value.Id, Ct)).Should().BeFalse();
            photoFiles.Should().NotBeEmpty().And.OnlyContain(p => !File.Exists(DiskPath(p)), "the photo's files are deleted too");
            (await db.WriterCategories.Where(c => categories.Contains(c.Id)).Select(c => c.Id).ToListAsync(Ct))
                .Should().BeEquivalentTo([databases, otherRag, otherName]);
            Guid[] emptied = [angular, typescript, cheatSheets, rag, prompts];
            (await db.WriterCategories.CountAsync(c => emptied.Contains(c.Id), Ct)).Should().Be(0, "the old demo categories left empty go");
            // The removed account goes through account deletion (SPEC §9.6), like DELETE /me; no other account is touched.
            (await db.Users.IgnoreQueryFilters().AnyAsync(x => x.Id == verified.Id, Ct)).Should().BeFalse("the removed \"Verified Writer\" goes");
            (await db.Users.CountAsync(x => x.Email != null && x.Email.EndsWith("@readin.test"), Ct)).Should().Be(users.Count - 1,
                "every other demo account stays");
            (await db.UserFollows.CountAsync(f => f.FollowerId == verified.Id || f.FolloweeId == verified.Id, Ct)).Should().Be(0);
            (await db.Comments.IgnoreQueryFilters().Where(c => c.Id == verifiedComment.Id).Select(c => c.AuthorId).SingleAsync(Ct))
                .Should().BeNull("its comment stays, as by \"Deleted user\"");

            // Idempotent: nothing left to do, and a second run changes nothing.
            (await seeder.ComputeChecksumAsync(Ct)).Should().Be(nothingToDo);
            (await seeder.SeedAsync(Ct)).Should().BeTrue();
            db.ChangeTracker.Clear();
            (await SnapshotAsync(oldIds)).Should().Be(after);
        }
        finally
        {
            db.ChangeTracker.Clear();
            var comments = db.Comments.IgnoreQueryFilters().Where(c => created.Contains(c.ArticleId) || c.Body.EndsWith(u)).Select(c => c.Id);
            await db.Reports.Where(r => created.Contains(r.TargetId) || comments.Contains(r.TargetId)).ExecuteDeleteAsync(Ct);
            await db.Notifications.Where(n => n.DedupeKey != null && n.DedupeKey.StartsWith($"cleanup:{u}")).ExecuteDeleteAsync(Ct);
            // The articles' comments, reactions, saves and reads go with them (cascades).
            await db.Articles.IgnoreQueryFilters().Where(a => created.Contains(a.Id)).ExecuteDeleteAsync(Ct);
            await db.WriterCategories.Where(c => categories.Contains(c.Id)).ExecuteDeleteAsync(Ct);
            await db.MediaAssets.Where(m => m.OwnerId == users["writer1"] && m.Purpose == MediaPurpose.Image).ExecuteDeleteAsync(Ct);
            // Left only when the test failed before the cleanup ran (FolloweeId doesn't cascade).
            await db.UserFollows.Where(f => f.FollowerId == verified.Id || f.FolloweeId == verified.Id).ExecuteDeleteAsync(Ct);
            await db.Users.IgnoreQueryFilters().Where(x => x.Id == verified.Id).ExecuteDeleteAsync(Ct);
        }

        async Task<Guid> ArticleAsync(Guid authorId, string slug, bool publish, MediaAsset? image = null)
        {
            var title = $"Old demo article {slug}";
            var document = JsonSerializer.SerializeToElement(new
            {
                version = 1,
                language = "en",
                blocks = new object[] { new { id = "p1", type = "paragraph", dir = "auto", content = new[] { new { type = "text", text = "Demo text." } } } },
            });
            var article = Article.CreateDraft(authorId, field.Id, topicId: null, slug, sourceLanguage: "en");
            article.AddTranslation("en", title, null, services.GetRequiredService<IRDocProcessor>().Process(document, "en", title).Value.Content)
                .IsSuccess.Should().BeTrue();
            article.SetSources([("ReadIn", "https://readin.app")]);
            if (image is not null)
            {
                article.SetAttachments([new AttachmentCandidate(image.Id, image.Kind, image.Status, image.OwnerId, 0, null, "A photo")])
                    .IsSuccess.Should().BeTrue();
            }
            db.Articles.Add(article);
            await SaveWithoutEventsAsync();
            if (publish)
            {
                article.Publish(field, now.AddDays(-3)).IsSuccess.Should().BeTrue();
                await SaveWithoutEventsAsync();
            }
            return article.Id;
        }

        async Task<Guid> CategoryAsync(Guid ownerId, string name, params Guid[] articleIds)
        {
            var cleaned = WriterCategoryNames.Clean(name);
            var category = new WriterCategory(ownerId, cleaned, WriterCategoryNames.Normalize(cleaned), $"c-{u}-{categories.Count}", categories.Count + 1, now);
            db.WriterCategories.Add(category);
            await db.SaveChangesAsync(Ct);
            categories.Add(category.Id);
            await db.Articles.IgnoreQueryFilters().Where(a => articleIds.Contains(a.Id))
                .ExecuteUpdateAsync(s => s.SetProperty(a => a.WriterCategoryId, category.Id), Ct);
            return category.Id;
        }

        // Test data raises no events: nothing is notified or pushed.
        Task SaveWithoutEventsAsync()
        {
            foreach (var entry in db.ChangeTracker.Entries<Domain.Common.AggregateRoot>()) entry.Entity.ClearDomainEvents();
            return db.SaveChangesAsync(Ct);
        }

        // Row counts of everything the cleanup may touch, and the rows that point at the old articles.
        async Task<Snapshot> SnapshotAsync(List<Guid> oldIds)
        {
            var oldComments = db.Comments.IgnoreQueryFilters().Where(c => oldIds.Contains(c.ArticleId)).Select(c => c.Id);
            var dependants = await db.Comments.IgnoreQueryFilters().CountAsync(c => oldIds.Contains(c.ArticleId), Ct)
                + await db.Reactions.CountAsync(r => oldIds.Contains(r.ArticleId), Ct)
                + await db.SavedArticles.CountAsync(s => oldIds.Contains(s.ArticleId), Ct)
                + await db.ReadingProgress.CountAsync(r => oldIds.Contains(r.ArticleId), Ct)
                + await db.ArticleAttachments.CountAsync(x => oldIds.Contains(x.ArticleId), Ct)
                + await db.Notifications.CountAsync(n => (n.ArticleId != null && oldIds.Contains(n.ArticleId.Value))
                    || (n.CommentId != null && oldComments.Contains(n.CommentId.Value)), Ct)
                + await db.Reports.CountAsync(r => oldIds.Contains(r.TargetId) || oldComments.Contains(r.TargetId), Ct);
            return new Snapshot(
                await db.Articles.IgnoreQueryFilters().CountAsync(Ct),
                dependants,
                await db.Comments.IgnoreQueryFilters().CountAsync(c => !oldIds.Contains(c.ArticleId), Ct),
                await db.Reactions.CountAsync(r => !oldIds.Contains(r.ArticleId), Ct),
                await db.SavedArticles.CountAsync(s => !oldIds.Contains(s.ArticleId), Ct),
                await db.ReadingProgress.CountAsync(r => !oldIds.Contains(r.ArticleId), Ct),
                await db.Notifications.CountAsync(n => !(n.ArticleId != null && oldIds.Contains(n.ArticleId.Value))
                    && !(n.CommentId != null && oldComments.Contains(n.CommentId.Value)), Ct),
                await db.Reports.CountAsync(r => !oldIds.Contains(r.TargetId) && !oldComments.Contains(r.TargetId), Ct),
                await db.MediaAssets.CountAsync(Ct),
                await db.WriterCategories.CountAsync(Ct),
                await db.Users.IgnoreQueryFilters().CountAsync(Ct));
        }
    }

    private string DiskPath(string stored) =>
        Path.Combine(api.UploadsPath, stored["/uploads/".Length..].Replace('/', Path.DirectorySeparatorChar));

    /// <param name="OldDependants">Rows that point at the old articles or their comments (all must go).</param>
    private sealed record Snapshot(
        int Articles, int OldDependants, int OtherComments, int OtherReactions, int OtherSaves, int OtherReads, int OtherNotifications,
        int OtherReports, int Media, int Categories, int Users);

    private sealed class TestEnvironment(string name) : IHostEnvironment
    {
        public string EnvironmentName { get; set; } = name;
        public string ApplicationName { get; set; } = "ReadIn.Api";
        public string ContentRootPath { get; set; } = AppContext.BaseDirectory;
        public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
    }
}
