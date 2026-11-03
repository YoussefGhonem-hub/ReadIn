namespace ReadIn.Application.Features.Uploads;

/// <summary>
/// Quotas and processing limits of the media pipeline, bound from the <c>Media</c> configuration section (ADR 0011).
/// The byte limits are constants in <see cref="Common.Uploads.UploadLimits"/> because request-size limits need them.
/// </summary>
public sealed class MediaOptions
{
    public const string Section = "Media";

    public int MaxDocumentPages { get; set; } = 100;

    /// <summary>Uploads (images + documents) one user may start per rolling 24 hours.</summary>
    public int MaxUploadsPerDay { get; set; } = 50;

    /// <summary>Bytes one user may keep in storage across all their assets.</summary>
    public long MaxStoredBytesPerUser { get; set; } = 200L * 1024 * 1024;

    /// <summary>A PDF job that runs longer is stopped and the asset fails with <c>media.processing_timeout</c>.</summary>
    public TimeSpan DocumentJobTimeout { get; set; } = TimeSpan.FromMinutes(2);

    /// <summary>PDF jobs that may render at the same time (a dedicated Hangfire queue with this many workers).</summary>
    public int MaxConcurrentDocumentJobs { get; set; } = 2;

    /// <summary>Feed cards carry at most this many page thumbs; the reader gets all pages.</summary>
    public int FeedDocumentPages { get; set; } = 10;
}
