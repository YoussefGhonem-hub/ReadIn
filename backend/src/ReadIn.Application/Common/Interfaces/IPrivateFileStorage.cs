namespace ReadIn.Application.Common.Interfaces;

/// <summary>
/// Files that must never be public (SPEC F19: writer verification proofs). Unlike <see cref="IFileStorage"/> there is no
/// public URL: the store lives outside the web root and the uploads folder (the API refuses to start otherwise), and its
/// files are read only by endpoints that check permissions. Paths are relative to the store's root, e.g.
/// <c>verification/{requestId}.pdf</c>.
/// </summary>
public interface IPrivateFileStorage
{
    /// <summary>Writes <paramref name="content"/> to <paramref name="relativePath"/>; never overwrites. Visible only once fully written.</summary>
    Task SaveAsync(string relativePath, Stream content, CancellationToken cancellationToken = default);

    /// <exception cref="FileNotFoundException">The file does not exist.</exception>
    Task<Stream> OpenReadAsync(string relativePath, CancellationToken cancellationToken = default);

    /// <summary>Deletes the file. A missing file is not an error.</summary>
    Task DeleteAsync(string relativePath, CancellationToken cancellationToken = default);
}
