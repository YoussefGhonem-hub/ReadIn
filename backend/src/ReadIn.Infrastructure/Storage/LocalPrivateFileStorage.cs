using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Infrastructure.Storage;

/// <summary>A file of the private store, for the cleanup job.</summary>
public sealed record PrivateFile(string RelativePath, DateTime LastWriteUtc);

/// <summary>
/// The private store on the API server's disk (SPEC F19): <c>Storage:PrivatePath</c>, by default <c>App_Data/private</c>
/// next to the app. Nothing serves it: no static-file middleware points at it, and the constructor refuses a folder that
/// overlaps the web root (<c>wwwroot</c>) or the uploads folder, so a misconfiguration stops the API at startup instead of
/// publishing someone's syndicate card. Single-server, like the uploads (ADR 0010).
/// </summary>
public sealed class LocalPrivateFileStorage : IPrivateFileStorage
{
    /// <summary>The folders created at startup, one per kind of private file.</summary>
    public static readonly IReadOnlyList<string> Folders = ["verification", "support"];

    private static readonly StringComparison PathComparison =
        OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal;

    public LocalPrivateFileStorage(IOptions<StorageOptions> options, IHostEnvironment environment)
    {
        var settings = options.Value;
        if (string.IsNullOrWhiteSpace(settings.PrivatePath))
            throw new InvalidOperationException("Storage:PrivatePath is not set. Point it at a folder outside wwwroot and the uploads folder.");

        RootPath = settings.PrivateRoot(environment.ContentRootPath);

        var webRoots = new List<string> { Path.Combine(environment.ContentRootPath, "wwwroot") };
        if (environment is IWebHostEnvironment { WebRootPath: { Length: > 0 } configured }) webRoots.Add(configured);
        foreach (var webRoot in webRoots.Select(r => Path.TrimEndingDirectorySeparator(Path.GetFullPath(r))).Distinct())
        {
            if (Overlaps(RootPath, webRoot))
                throw new InvalidOperationException(
                    $"Storage:PrivatePath '{RootPath}' overlaps the web root '{webRoot}'. Private files (verification proofs) must never be "
                    + "reachable by a public URL: point Storage:PrivatePath at a folder outside wwwroot (docs/setup/deployment.md).");
        }

        var uploads = settings.UploadsRoot(environment.ContentRootPath);
        if (Overlaps(RootPath, uploads))
            throw new InvalidOperationException(
                $"Storage:PrivatePath '{RootPath}' overlaps the uploads folder '{uploads}' (Storage:UploadsPath). Private files "
                + "(verification proofs) must never be reachable by a public URL: point Storage:PrivatePath at a folder outside it "
                + "(docs/setup/deployment.md).");
    }

    /// <summary>Absolute path of the private folder.</summary>
    public string RootPath { get; }

    public async Task SaveAsync(string relativePath, Stream content, CancellationToken cancellationToken = default)
    {
        var target = Resolve(relativePath);
        Directory.CreateDirectory(Path.GetDirectoryName(target)!);

        // A temporary name first, so a file only appears once it is complete.
        var temporary = $"{target}.{Guid.NewGuid():N}.tmp";
        try
        {
            await using (var file = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None, 81920, useAsync: true))
                await content.CopyToAsync(file, cancellationToken);
            File.Move(temporary, target, overwrite: false);
        }
        finally
        {
            if (File.Exists(temporary)) File.Delete(temporary);
        }
    }

    public Task<Stream> OpenReadAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        var target = Resolve(relativePath);
        if (!File.Exists(target)) throw new FileNotFoundException("The private file does not exist.", relativePath);
        Stream stream = new FileStream(target, FileMode.Open, FileAccess.Read, FileShare.Read, 81920, useAsync: true);
        return Task.FromResult(stream);
    }

    public Task DeleteAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        var target = Resolve(relativePath);
        if (File.Exists(target)) File.Delete(target);

        // A file in a sub-folder of a kind (support/{messageId}/1.png, F35): the sub-folder goes once it is empty.
        if (relativePath.Count(c => c == '/') >= 2)
        {
            var folder = Path.GetDirectoryName(target)!;
            try
            {
                if (Directory.Exists(folder) && !Directory.EnumerateFileSystemEntries(folder).Any()) Directory.Delete(folder);
            }
            catch (IOException)
            {
                // Another file arrived in the meantime: the folder stays.
            }
        }
        return Task.CompletedTask;
    }

    /// <summary>
    /// Every file in <paramref name="folder"/> (one of <see cref="Folders"/>), for the cleanup jobs; with
    /// <paramref name="recursive"/>, those of its sub-folders too (<c>support/{messageId}/1.png</c>, F35).
    /// </summary>
    public IEnumerable<PrivateFile> EnumerateFiles(string folder, bool recursive = false)
    {
        if (!Folders.Contains(folder)) throw new ArgumentException("Not a private folder.", nameof(folder));
        var directory = Path.Combine(RootPath, folder);
        if (!Directory.Exists(directory)) yield break;

        var option = recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;
        foreach (var file in Directory.EnumerateFiles(directory, "*", option))
        {
            var relative = Path.GetRelativePath(RootPath, file).Replace(Path.DirectorySeparatorChar, '/');
            yield return new PrivateFile(relative, File.GetLastWriteTimeUtc(file));
        }
    }

    /// <summary>
    /// Creates the folder and its sub-folders, then proves the process can write there. Throws when it cannot, so a
    /// misconfigured server fails at startup instead of on the first verification request.
    /// </summary>
    public void EnsureWritable()
    {
        foreach (var folder in Folders) Directory.CreateDirectory(Path.Combine(RootPath, folder));

        var probe = Path.Combine(RootPath, $".write-check.{Guid.NewGuid():N}.tmp");
        File.WriteAllBytes(probe, []);
        File.Delete(probe);
    }

    /// <summary>
    /// Maps a plain relative path (<c>verification/{id}.pdf</c>) to a file inside <see cref="RootPath"/>. Rejects
    /// anything else: rooted paths, empty, "." or ".." segments, backslashes, drive letters, control characters, and any
    /// path that would resolve outside the folder.
    /// </summary>
    public string Resolve(string relativePath)
    {
        ArgumentNullException.ThrowIfNull(relativePath);
        if (relativePath.Length == 0
            || relativePath.StartsWith('/')
            || relativePath.Contains('\\', StringComparison.Ordinal)
            || relativePath.Contains(':', StringComparison.Ordinal)
            || relativePath.Any(char.IsControl)
            || relativePath.Split('/').Any(segment => segment is "" or "." or ".."))
            throw new ArgumentException("The private path is not a plain relative path.", nameof(relativePath));

        var fullPath = Path.GetFullPath(Path.Combine(RootPath, relativePath));
        if (!fullPath.StartsWith(RootPath + Path.DirectorySeparatorChar, PathComparison))
            throw new ArgumentException("The private path resolves outside the private folder.", nameof(relativePath));
        return fullPath;
    }

    /// <summary>One folder is the other or inside it.</summary>
    private static bool Overlaps(string a, string b) => IsSameOrInside(a, b) || IsSameOrInside(b, a);

    private static bool IsSameOrInside(string path, string folder) =>
        string.Equals(path, folder, PathComparison) || path.StartsWith(folder + Path.DirectorySeparatorChar, PathComparison);
}
