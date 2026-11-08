using ReadIn.Application.Features.ContentFilter;
using ReadIn.Application.Features.Users.Commands.UpdateProfile;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users;

/// <summary>
/// The profile texts the content filter reads (SPEC F37): only what a request changes, so an untouched text is never
/// refused or reported again. Display name, @username, bio (with spam signs), title and the social links' labels.
/// </summary>
internal static class ProfileScreening
{
    public static IEnumerable<ScreenedField> Changed(User user, UpdateProfileCommand command) =>
        Changed(user, command.DisplayName, command.Username, command.Bio, command.Headline, command.Links);

    public static IEnumerable<ScreenedField> Changed(
        User user, string? displayName, string? username, string? bio, HeadlineChange? headline, IReadOnlyList<ProfileLinkInput>? links)
    {
        if (displayName is not null && displayName.Trim() != user.DisplayName) yield return new ScreenedField("displayName", displayName);
        // A username is one word (letters, digits, _): the matcher also reads its parts between underscores.
        if (username is not null && username != user.Username) yield return new ScreenedField("username", username);
        if (bio is not null && bio != user.Bio) yield return new ScreenedField("bio", bio, SpamSignals: true);
        if (headline is { Value: { } title } && title.Trim() != user.Headline) yield return new ScreenedField("headline", title);
        if (links is not null)
        {
            foreach (var label in links.Select(l => l?.Label).Where(l => !string.IsNullOrWhiteSpace(l)))
            {
                if (user.Links.All(existing => existing.Label != label!.Trim())) yield return new ScreenedField("links", label);
            }
        }
    }
}
