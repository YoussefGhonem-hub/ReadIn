namespace ReadIn.Domain.Users;

/// <summary>"Who can mention me" (SPEC F18 privacy): who may @mention the user in comments and articles. Stored by name.</summary>
public enum MentionPolicy
{
    /// <summary>Anyone (the default).</summary>
    Everyone = 0,

    /// <summary>Only people the user follows.</summary>
    Following = 1,

    /// <summary>Nobody but the user.</summary>
    Nobody = 2,
}

/// <summary>The "who can mention me" rule (SPEC F18), the same for comments (F11) and articles (F05).</summary>
public static class MentionRules
{
    /// <summary>
    /// An author may @mention a user who is the author, allows <see cref="MentionPolicy.Everyone"/>, or allows
    /// <see cref="MentionPolicy.Following"/> and follows the author. A link also needs an active account
    /// (<see cref="User.CanBeMentionedBy"/>).
    /// </summary>
    /// <param name="whoCanMention">The mentioned user's setting.</param>
    /// <param name="isSelf">The author mentions themselves.</param>
    /// <param name="followsAuthor">The mentioned user follows the author.</param>
    public static bool Allows(MentionPolicy whoCanMention, bool isSelf, bool followsAuthor) => isSelf || whoCanMention switch
    {
        MentionPolicy.Everyone => true,
        MentionPolicy.Following => followsAuthor,
        _ => false,
    };
}
