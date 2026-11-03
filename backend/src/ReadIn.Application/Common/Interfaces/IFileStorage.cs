namespace ReadIn.Application.Common.Interfaces;

/// <summary>
/// Stores uploaded files (SPEC §24, ADR 0010). Paths are relative to the public site root, e.g.
/// <c>/uploads/covers/2026/11/{id}_1200.webp</c>. The database stores only these relative paths, so changing the
/// public domain or the storage provider never needs a data migration.
/// </summary>
public interface IFileStorage
{
    /// <summary>Writes <paramref name="content"/> to <paramref name="relativePath"/>. The file is visible only once fully written.</summary>
    Task SaveAsync(string relativePath, Stream content, CancellationToken cancellationToken = default);

    /// <summary>Opens a stored file for reading (e.g. the original PDF for the rendering job or a download, ADR 0011).</summary>
    /// <exception cref="FileNotFoundException">The file does not exist.</exception>
    Task<Stream> OpenReadAsync(string relativePath, CancellationToken cancellationToken = default);

    /// <summary>Deletes the file. A missing file is not an error.</summary>
    Task DeleteAsync(string relativePath, CancellationToken cancellationToken = default);

    /// <summary>The absolute URL clients use for a stored relative path, built from the configured public base URL.</summary>
    string GetPublicUrl(string relativePath);
}
