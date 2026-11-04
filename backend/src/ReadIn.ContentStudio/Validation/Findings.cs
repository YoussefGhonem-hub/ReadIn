namespace ReadIn.ContentStudio.Validation;

public enum Severity { Error, Warning }

public sealed record Finding(string Slug, Severity Severity, string Check, string Message);

/// <summary>What one validation run did, for the summary and the batch report.</summary>
public sealed class ValidationStats
{
    public int Articles { get; set; }
    public int LinksChecked { get; set; }
    public int LinksFromCache { get; set; }
    public List<string> LinkFailures { get; } = [];

    /// <summary>Links whose host answered 429 after the retries: warnings, not failures.</summary>
    public List<string> LinksRateLimited { get; } = [];

    /// <summary>Words and reading time per article and language (the reader's formula, SPEC §13.5).</summary>
    public List<(string Slug, string Language, int Words, int Minutes)> Lengths { get; } = [];

    /// <summary>Compiled (or run) snippets per language.</summary>
    public SortedDictionary<string, int> Compiled { get; } = new(StringComparer.Ordinal);

    /// <summary>Snippets not compiled: language without a checker, or <c>"compile": false</c> with its reason.</summary>
    public List<(string Slug, string Block, string Lang, string Reason)> Skipped { get; } = [];
}
