namespace ReadIn.Application.UnitTests;

/// <summary>Locates shared fixtures in the monorepo (shared/, content/) from the test output folder.</summary>
internal static class RepoPaths
{
    public static string Root { get; } = FindRoot();

    public static string Shared(params string[] parts) => Path.Combine([Root, "shared", .. parts]);

    public static string Content(params string[] parts) => Path.Combine([Root, "content", .. parts]);

    private static string FindRoot()
    {
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir is not null; dir = dir.Parent)
        {
            if (File.Exists(Path.Combine(dir.FullName, "shared", "rdoc", "rdoc.schema.json"))) return dir.FullName;
        }
        throw new DirectoryNotFoundException("Repository root (with shared/rdoc) not found.");
    }
}
