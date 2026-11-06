using ReadIn.Domain.Common;

namespace ReadIn.Domain.Media;

/// <summary>
/// One upload the API accepted (an image or a PDF), kept for the daily upload quota (SPEC §24 "Quotas", contract-v1
/// "Media"): the quota counts these rows, not the assets, so an upload deleted since still counts and deleting doesn't
/// free the allowance. Rows older than <see cref="KeepFor"/> are pruned by the daily uploads cleanup; deleting the
/// account deletes them (cascade).
/// </summary>
public sealed class MediaUpload : Entity
{
    /// <summary>Longer than the rolling day the quota looks at.</summary>
    public static readonly TimeSpan KeepFor = TimeSpan.FromDays(2);

    private MediaUpload() { } // EF

    public MediaUpload(Guid userId, DateTime createdAt)
    {
        UserId = userId;
        CreatedAt = createdAt;
    }

    public Guid UserId { get; private set; }
    public DateTime CreatedAt { get; private set; }
}
