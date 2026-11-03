using System.Globalization;
using Mapster;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users;

public sealed class UserMappings : IRegister
{
    public void Register(TypeAdapterConfig config)
    {
        config.NewConfig<UserLinks, UserLinksDto>()
            .MapWith(s => new UserLinksDto(s.GitHub, s.LinkedIn, s.Website));

        // Roles, permissions and IsVerified come from IUserAccessService (cached), not from the entity.
        config.NewConfig<User, MeDto>()
            .Map(d => d.ArticleLanguage, s => s.ArticleLanguagePref)
            .Map(d => d.Theme, s => s.ThemePref)
            .Map(d => d.ReminderTime, s => s.ReminderTime.ToString("HH:mm", CultureInfo.InvariantCulture))
            .Map(d => d.Interests, s => new InterestsDto(
                s.Interests.Where(i => i.FieldId != null).Select(i => i.FieldId!.Value).ToList(),
                s.Interests.Where(i => i.TopicId != null).Select(i => i.TopicId!.Value).ToList()))
            .Map(d => d.ExternalLogins, s => s.ExternalLogins
                .OrderBy(l => l.LinkedAt)
                .Select(l => new ExternalLoginDto(l.Provider, l.Email, l.LinkedAt))
                .ToList())
            .Map(d => d.Privacy, s => new PrivacyDto(s.PublicReadingStats))
            .Ignore(d => d.Roles, d => d.Permissions, d => d.IsVerified);
    }
}
