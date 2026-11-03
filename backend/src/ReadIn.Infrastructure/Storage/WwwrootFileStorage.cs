using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;

namespace ReadIn.Infrastructure.Storage;

public sealed class StorageOptions
{
    public const string Section = "Storage";

    /// <summary>
    /// Folder that holds the uploads, served at <c>/uploads</c>. Relative paths resolve against the content root.
    /// It must survive deployments (docs/setup/deployment.md).
    /// </summary>
    public string UploadsPath { get; set; } = "wwwroot/uploads";

    /// <summary>Public origin of the API that serves <c>/uploads</c>, e.g. <c>https://api.readin.app</c>.</summary>
    public string PublicBaseUrl { get; set; } = string.Empty;
}

/// <summary>A file below the uploads folder.</summary>
public sealed record StoredFile(string RelativePath, DateTime LastWriteUtc);

/// <summary>
/// Stores uploads on the API server's disk, by default in <c>wwwroot/uploads</c> (ADR 0010). Single-server only:
/// scaling out means swapping this for a shared or cloud <see cref="IFileStorage"/>.
/// </summary>
public sealed class WwwrootFileStorage : IFileStorage
{
    private static readonly StringComparison PathComparison =
        OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal;

    private readonly string _publicBaseUrl;

    public WwwrootFileStorage(IOptions<StorageOptions> options, IHostEnvironment environment)
    {
        var settings = options.Value;
        if (string.IsNullOrWhiteSpace(settings.UploadsPath))
            throw new InvalidOperationException("Storage:UploadsPath is not set.");
        if (!Uri.TryCreate(settings.PublicBaseUrl, UriKind.Absolute, out var publicBase) || publicBase.Scheme is not ("http" or "https"))
            throw new InvalidOperationException("Storage:PublicBaseUrl must be an absolute http(s) URL, e.g. https://api.readin.app.");

        RootPath = Path.TrimEndingDirectorySeparator(Path.GetFullPath(Path.Combine(environment.ContentRootPath, settings.UploadsPath)));
        _publicBaseUrl = settings.PublicBaseUrl.TrimEnd('/');
    }

    /// <summary>Absolute path of the uploads folder.</summary>
    public string RootPath { get; }

    public async Task SaveAsync(string relativePath, Stream content, CancellationToken cancellationToken = default)
    {
        var target = Resolve(relativePath);
        Directory.CreateDirectory(Path.GetDirectoryName(target)!);

        // Write to a temporary name first: .tmp files are never served, and the rename makes the file appear complete.
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
        Stream stream = new FileStream(target, FileMode.Open, FileAccess.Read, FileShare.Read, 81920, useAsync: true);
        return Task.FromResult(stream);
    }

    public Task DeleteAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        var target = Resolve(relativePath);
        if (File.Exists(target)) File.Delete(target);
        return Task.CompletedTask;
    }

    public string GetPublicUrl(string relativePath)
    {
        Resolve(relativePath); // same rules as for disk access: only plain paths below /uploads
        return _publicBaseUrl + relativePath;
    }

    /// <summary>Every file below the uploads folder, for the orphan cleanup job.</summary>
    public IEnumerable<StoredFile> EnumerateFiles()
    {
        if (!Directory.Exists(RootPath)) yield break;

        foreach (var file in Directory.EnumerateFiles(RootPath, "*", SearchOption.AllDirectories))
        {
            var relative = Path.GetRelativePath(RootPath, file).Replace(Path.DirectorySeparatorChar, '/');
            yield return new StoredFile($"{UploadPath.Root}/{relative}", File.GetLastWriteTimeUtc(file));
        }
    }

    /// <summary>
    /// Creates the uploads folder and its purpose sub-folders, then proves the process can write there.
    /// Throws when it cannot, so a misconfigured server fails at startup instead of on the first upload.
    /// </summary>
    public void EnsureWritable()
    {
        foreach (var purpose in UploadPurpose.All)
            Directory.CreateDirectory(Path.Combine(RootPath, purpose.Folder));

        var probe = Path.Combine(RootPath, $".write-check.{Guid.NewGuid():N}.tmp");
        File.WriteAllBytes(probe, []);
        File.Delete(probe);
    }

    /// <summary>
    /// Maps <c>/uploads/…</c> to a file inside <see cref="RootPath"/>. Rejects anything else: other roots, empty,
    /// "." or ".." segments, backslashes, drive letters, and any path that would resolve outside the folder.
    /// </summary>
    public string Resolve(string relativePath)
    {
        ArgumentNullException.ThrowIfNull(relativePath);
        const string prefix = UploadPath.Root + "/";
        if (!relativePath.StartsWith(prefix, StringComparison.Ordinal))
            throw new ArgumentException($"Upload paths must start with {prefix}.", nameof(relativePath));

        var subPath = relativePath[prefix.Length..];
        if (subPath.Length == 0
            || subPath.Contains('\\', StringComparison.Ordinal)
            || subPath.Contains(':', StringComparison.Ordinal)
            || subPath.Any(char.IsControl)
            || subPath.Split('/').Any(segment => segment is "" or "." or ".."))
            throw new ArgumentException("The upload path is not a plain relative path.", nameof(relativePath));

        var fullPath = Path.GetFullPath(Path.Combine(RootPath, subPath));
        if (!fullPath.StartsWith(RootPath + Path.DirectorySeparatorChar, PathComparison))
            throw new ArgumentException("The upload path resolves outside the uploads folder.", nameof(relativePath));
        return fullPath;
    }
}
