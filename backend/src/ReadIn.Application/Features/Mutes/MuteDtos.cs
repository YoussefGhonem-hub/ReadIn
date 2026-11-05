using ReadIn.Application.Features.Follows;

namespace ReadIn.Application.Features.Mutes;

/// <summary>
/// PUT / DELETE /users/{id}/mute (SPEC F28): your mute and follow of the writer right after the change.
/// </summary>
/// <param name="IsFollowing">Muting always ends your follow; unmuting with <c>restoreFollow</c> follows again.</param>
/// <param name="FollowerCount">The writer's followers after the change.</param>
/// <param name="FollowRemoved">PUT only: this mute ended your follow, so the toast's Undo sends <c>restoreFollow=true</c>.</param>
public sealed record UserMuteStateDto(bool IsMuted, bool IsFollowing, int FollowerCount, bool FollowRemoved);

/// <summary>
/// PUT / DELETE /me/mutes/fields/{id} and /me/mutes/topics/{id}: every field and topic you muted after the change, so
/// the "كتم المواضيع" sheet sets its toggles from it.
/// </summary>
public sealed record ContentMutesDto(IReadOnlyList<Guid> FieldIds, IReadOnlyList<Guid> TopicIds);

/// <summary>A muted field in Settings → Muted; <see cref="Name"/> in the UI language.</summary>
public sealed record MutedFieldDto(Guid Id, string Slug, string Name, string NameAr, string NameEn, string Icon, string Color);

/// <summary>A muted topic in Settings → Muted, with its field (for the subtitle and the icon).</summary>
public sealed record MutedTopicDto(Guid Id, string Slug, string Name, string NameAr, string NameEn, MutedFieldDto Field);

/// <summary>GET /me/mutes: Settings → Muted (SPEC F18, F28). Each list newest mute first.</summary>
public sealed record MutesDto(
    IReadOnlyList<UserSummaryDto> Users,
    IReadOnlyList<MutedFieldDto> Fields,
    IReadOnlyList<MutedTopicDto> Topics);
