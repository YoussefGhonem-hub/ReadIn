namespace ReadIn.Infrastructure.UnitTests.Media;

/// <summary>Files in backend/tests/fixtures/media (see its README for how each one was made).</summary>
internal static class MediaFixtures
{
    public static byte[] Read(string name) => File.ReadAllBytes(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", name));

    public static bool Contains(byte[] haystack, string text) =>
        haystack.AsSpan().IndexOf(System.Text.Encoding.ASCII.GetBytes(text)) >= 0;
}
