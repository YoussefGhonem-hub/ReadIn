using System.Globalization;
using Mapster;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users;

public sealed class UserMappings : IRegister
{
    public void Register(TypeAdapterConfig config)
    {
        // Roles and permissions come from IUserAccessService (cached), not from the entity. IsVerified is the entity's badge.
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
            .Map(d => d.Privacy, s => new PrivacyDto(s.PublicReadingStats, s.WhoCanMention))
            .Map(d => d.Links, s => s.Links.Select(l => new ProfileLinkDto(l.Platform, l.Url, l.Label)).ToList())
            .Ignore(d => d.Roles, d => d.Permissions);
    }
}
