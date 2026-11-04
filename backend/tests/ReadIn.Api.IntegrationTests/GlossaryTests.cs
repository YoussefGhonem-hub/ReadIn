using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The glossary (SPEC F21) against the fixture content: terms from content/glossary/*.yaml, the articles that use them
/// (ArticleTerms, rebuilt by the seeder and on publish), and the search behind the editor's term picker.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class GlossaryTests(ApiFactory api)
{
    private const string DiArticle = "dependency-injection-in-aspnet-core";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task A_term_has_both_definitions_and_the_articles_that_use_it()
    {
        var term = await api.GuestClient().GetAsync("/api/v1/glossary/dependency-injection?lang=en", Ct).OkJsonAsync();

        term["slug"]!.GetValue<string>().Should().Be("dependency-injection");
        term["term"]!.GetValue<string>().Should().Be("Dependency Injection");
        term["definitionEn"]!.GetValue<string>().Should().StartWith("A design where a class receives");
        term["explanationAr"]!.GetValue<string>().Should().Contain("الـ class");
        var article = term["articles"]!.AsArray().Should().ContainSingle(a => a!["slug"]!.GetValue<string>() == DiArticle).Which!;
        article["language"]!.GetValue<string>().Should().Be("en");
        article["title"]!.GetValue<string>().Should().StartWith("Dependency Injection in ASP.NET Core");
        article["readingTimeMinutes"]!.GetValue<int>().Should().BePositive();
        article["field"]!["slug"]!.GetValue<string>().Should().Be("dotnet");
    }

    [Fact]
    public async Task Lang_picks_the_titles_of_the_articles()
    {
        var term = await api.GuestClient("ar").GetAsync("/api/v1/glossary/dependency-injection?lang=ar-EG", Ct).OkJsonAsync();

        var article = term["articles"]!.AsArray().Single(a => a!["slug"]!.GetValue<string>() == DiArticle)!;
        article["language"]!.GetValue<string>().Should().Be("ar-EG");
        article["title"]!.GetValue<string>().Should().StartWith("يعني إيه Dependency Injection");
    }

    [Fact]
    public async Task An_unknown_term_is_not_found()
    {
        await api.GuestClient().GetAsync("/api/v1/glossary/no-such-term", Ct).ProblemAsync(HttpStatusCode.NotFound, "glossary.term_not_found");
        await api.GuestClient().GetAsync($"/api/v1/glossary/{new string('x', 101)}", Ct).ProblemAsync(HttpStatusCode.NotFound, "glossary.term_not_found");
    }

    [Fact]
    public async Task Search_puts_terms_that_start_with_the_query_first()
    {
        var all = await api.GuestClient().GetAsync("/api/v1/glossary", Ct).OkArrayAsync();
        all.Select(t => t!["term"]!.GetValue<string>()).Should().BeInAscendingOrder(StringComparer.OrdinalIgnoreCase)
            .And.Contain(["Dependency Injection", "Service lifetime"]);

        var service = await api.GuestClient().GetAsync("/api/v1/glossary?q=serv", Ct).OkArrayAsync();
        service.Select(t => t!["slug"]!.GetValue<string>()).Should().Equal("service-lifetime");
        service[0]!["definitionEn"]!.GetValue<string>().Should().StartWith("How long the DI container");

        // "injection" is inside "Dependency Injection" but starts nothing.
        (await api.GuestClient().GetAsync("/api/v1/glossary?q=INJECTION", Ct).OkArrayAsync())
            .Select(t => t!["slug"]!.GetValue<string>()).Should().Equal("dependency-injection");

        (await api.GuestClient().GetAsync("/api/v1/glossary?limit=1", Ct).OkArrayAsync()).Should().HaveCount(1);
        (await api.GuestClient().GetAsync("/api/v1/glossary?q=nothing-matches", Ct).OkArrayAsync()).Should().BeEmpty();
    }

    [Fact]
    public async Task A_published_article_shows_up_under_the_terms_it_uses()
    {
        var before = await api.GuestClient().GetAsync("/api/v1/glossary/service-lifetime?lang=en", Ct).OkJsonAsync();
        var writer = await api.UserAsync("Glossary Writer");

        var published = await PublishWithTermAsync(writer.Client, "service-lifetime", "Lifetimes");
        await PublishWithTermAsync(writer.Client, "not-in-the-glossary", "Unknown term");

        var after = await api.GuestClient().GetAsync("/api/v1/glossary/service-lifetime?lang=en", Ct).OkJsonAsync();
        after["articles"]!.AsArray().Select(a => a!["id"]!.GetValue<Guid>()).Should()
            .Contain(published.Id, "publishing indexes the terms and clears the cached term")
            .And.HaveCount(before["articles"]!.AsArray().Count + 1);

        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        (await db.ArticleTerms.CountAsync(t => t.ArticleId == published.Id, Ct)).Should().Be(1);
    }

    [Fact]
    public async Task Updating_a_published_article_updates_its_terms()
    {
        var writer = await api.UserAsync("Glossary Editor");
        var article = await PublishWithTermAsync(writer.Client, "service-lifetime", "Lifetimes");
        (await Listed(article.Id, "service-lifetime")).Should().BeTrue();

        // Swap the term in the working copy and publish the update ("already published" path, F05).
        var edit = await writer.Client.EditAsync(article.Id);
        var document = edit["document"]!.AsObject();
        document["translations"]![0]!["content"]!["blocks"] = JsonSerializerHelper.ToNode(new[] { TermParagraph("dependency-injection", "DI") });
        (await writer.Client.SaveDraftAsync(article.Id, edit["version"]!.GetValue<int>(), document)).EnsureSuccessStatusCode();
        await (await writer.Client.PublishCurrentAsync(article.Id)).PublishedSlugAsync();

        (await Listed(article.Id, "service-lifetime")).Should().BeFalse("the update dropped the term and cleared the cached term");
        (await Listed(article.Id, "dependency-injection")).Should().BeTrue();
    }

    /// <summary>Whether the term lists the article (fetched as a guest, so through the cache).</summary>
    private async Task<bool> Listed(Guid articleId, string term) =>
        (await api.GuestClient().GetAsync($"/api/v1/glossary/{term}?lang=en", Ct).OkJsonAsync())["articles"]!.AsArray()
            .Any(a => a!["id"]!.GetValue<Guid>() == articleId);

    [Fact]
    public async Task Re_running_the_seeder_keeps_the_index()
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var before = await db.ArticleTerms.AsNoTracking().OrderBy(t => t.ArticleId).ThenBy(t => t.TermId).ToListAsync(Ct);
        var terms = await db.GlossaryTerms.CountAsync(Ct);
        before.Should().NotBeEmpty();

        await scope.ServiceProvider.GetRequiredService<SeedRunner>().RunAsync(force: true, Ct);

        db.ChangeTracker.Clear();
        (await db.GlossaryTerms.CountAsync(Ct)).Should().Be(terms);
        (await db.ArticleTerms.AsNoTracking().OrderBy(t => t.ArticleId).ThenBy(t => t.TermId).ToListAsync(Ct))
            .Should().BeEquivalentTo(before, "the seeder rebuilds the same rows, including those of articles published through the API");
    }

    /// <summary>Publishes an English article whose only paragraph uses the glossary term <paramref name="termId"/>.</summary>
    private static async Task<(Guid Id, string Slug)> PublishWithTermAsync(HttpClient author, string termId, string text) =>
        await author.WriteAndPublishAsync(ArticleTestKit.Document(
            await author.FieldIdAsync("dotnet"),
            $"Glossary test {Guid.NewGuid():N}",
            blocks: [TermParagraph(termId, text)],
            sources: [new { title = "Example", url = "https://example.com" }]));

    private static object TermParagraph(string termId, string text) => new
    {
        id = "p1", type = "paragraph", dir = "auto",
        content = new object[] { new { type = "text", text = "About " }, new { type = "term", termId, text } },
    };
}
