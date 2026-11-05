namespace ReadIn.Infrastructure.Pdf;

/// <summary>
/// Finds the Chrome/Chromium executable that prints article PDFs (SPEC F33). It is installed with the server or the
/// image (docs/setup/deployment.md) and never downloaded at runtime: <see cref="ArticlePdfOptions.ChromiumPath"/>, then
/// <c>PUPPETEER_EXECUTABLE_PATH</c>, then the usual install paths.
/// </summary>
internal static class ChromiumLocator
{
    public const string EnvironmentVariable = "PUPPETEER_EXECUTABLE_PATH";

    public static string? Find(string? configured)
    {
        if (!string.IsNullOrWhiteSpace(configured)) return configured;
        if (Environment.GetEnvironmentVariable(EnvironmentVariable) is { Length: > 0 } fromEnvironment) return fromEnvironment;
        return KnownPaths().FirstOrDefault(File.Exists);
    }

    private static IEnumerable<string> KnownPaths()
    {
        if (OperatingSystem.IsWindows())
        {
            foreach (var root in new[]
                     {
                         Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                         Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
                         Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                     })
            {
                if (string.IsNullOrEmpty(root)) continue;
                yield return Path.Combine(root, "Google", "Chrome", "Application", "chrome.exe");
                yield return Path.Combine(root, "Chromium", "Application", "chrome.exe");
            }
        }
        else if (OperatingSystem.IsMacOS())
        {
            yield return "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
            yield return "/Applications/Chromium.app/Contents/MacOS/Chromium";
        }
        else
        {
            yield return "/usr/bin/chromium";
            yield return "/usr/bin/chromium-browser";
            yield return "/usr/bin/google-chrome";
            yield return "/usr/bin/google-chrome-stable";
            yield return "/opt/google/chrome/chrome";
        }
    }
}
