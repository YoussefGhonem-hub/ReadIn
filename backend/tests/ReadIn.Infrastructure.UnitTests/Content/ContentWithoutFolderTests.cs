using AwesomeAssertions;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using NSubstitute;
using ReadIn.Application.Features.Admin.Taxonomy;
using ReadIn.Infrastructure.Content;

namespace ReadIn.Infrastructure.UnitTests.Content;

/// <summary>
/// Production ships the API without the repo's <c>content/</c> folder (only the seed command reads it), so the admin
/// console's read-only views must load without it: the dashboard's content pipeline returned 500 on the server
/// (2026-11-12) because it asked <see cref="ContentRepository.Root"/>.
/// </summary>
public sealed class ContentWithoutFolderTests : IDisposable
{
    private readonly string _dir = Path.Combine(Path.GetTempPath(), "readin-content-tests", Guid.NewGuid().ToString("N"));

    public ContentWithoutFolderTests() => Directory.CreateDirectory(_dir);

    public void Dispose() => Directory.Delete(_dir, recursive: true);

    private ContentRepository Repository()
    {
        var environment = Substitute.For<IHostEnvironment>();
        environment.ContentRootPath.Returns(_dir);
        // A configured folder without taxonomy.yaml: the same "no content/" failure, whatever the machine's parents hold.
        return new ContentRepository(Options.Create(new ContentOptions { RootPath = _dir }), environment);
    }

    [Fact]
    public void Root_still_fails_loudly_for_the_seed_and_the_tools()
    {
        var act = () => Repository().Root;

        act.Should().Throw<DirectoryNotFoundException>();
    }

    [Fact]
    public void RootOrNull_is_null_without_a_content_folder_and_the_folder_with_one()
    {
        Repository().RootOrNull.Should().BeNull();

        File.WriteAllText(Path.Combine(_dir, "taxonomy.yaml"), "fields: []\n");
        Repository().RootOrNull.Should().Be(Path.GetFullPath(_dir));
    }

    [Fact]
    public async Task The_console_taxonomy_lists_nothing_instead_of_failing()
    {
        var slugs = await new ContentTaxonomyReader(Repository()).ReadSlugsAsync(TestContext.Current.CancellationToken);

        slugs.Should().Be(ContentTaxonomySlugs.Empty);
    }
}
