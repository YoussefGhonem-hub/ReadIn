using Mapster;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Articles;

namespace ReadIn.Application.Features.Articles;

/// <summary>
/// Language-aware article projections (SPEC §6.4): the requested translation is chosen in SQL,
/// falling back to the source language when it doesn't exist.
/// </summary>
public sealed class ArticleMappings : IRegister
{
    public void Register(TypeAdapterConfig config)
    {
        config.NewConfig<Article, ArticleCardDto>()
            .Map(d => d.Language, s => s.Translations.Any(t => t.Language == LocalizedProjection.Lang)
                ? LocalizedProjection.Lang
                : s.SourceLanguage)
            .Map(d => d.Title, s => s.Translations
                .Where(t => t.Language == LocalizedProjection.Lang)
                .Select(t => t.Title).FirstOrDefault()
                ?? s.Translations.Where(t => t.IsSource).Select(t => t.Title).FirstOrDefault())
            .Map(d => d.Subtitle, s => s.Translations.Any(t => t.Language == LocalizedProjection.Lang)
                ? s.Translations.Where(t => t.Language == LocalizedProjection.Lang).Select(t => t.Subtitle).FirstOrDefault()
                : s.Translations.Where(t => t.IsSource).Select(t => t.Subtitle).FirstOrDefault())
            .Map(d => d.ReadingTimeMinutes, s => s.Translations.Any(t => t.Language == LocalizedProjection.Lang)
                ? s.Translations.Where(t => t.Language == LocalizedProjection.Lang).Select(t => t.ReadingTimeMinutes).FirstOrDefault()
                : s.Translations.Where(t => t.IsSource).Select(t => t.ReadingTimeMinutes).FirstOrDefault())
            .Map(d => d.Field, s => new FieldRefDto(
                s.Field.Id, s.Field.Slug,
                LocalizedProjection.Ui == "en" ? s.Field.NameEn : s.Field.NameAr,
                s.Field.NameAr, s.Field.NameEn))
            .Map(d => d.Author, s => new AuthorDto(
                s.Author.Id, s.Author.DisplayName, s.Author.Username, s.Author.AvatarUrl,
                s.Author.Roles.Any(r => r.RoleId == RoleIds.VerifiedWriter)))
            .Map(d => d.IsReviewed, s => s.ReviewStatus == ReviewStatus.Approved)
            // The denormalized counters on Articles (F27); ReactionCount and SaveCount map by name.
            .Map(d => d.Reactions, s => new ReactionCountsDto(s.InsightfulCount, s.LoveCount, s.FireCount, s.MindBlownCount))
            // Loaded after the projection: attachments by ArticleAttachmentsReader (absolute URLs, page limits), the
            // viewer's own state by ArticleViewerStateReader (signed-in viewers only).
            .Ignore(d => d.Attachments!)
            .Ignore(d => d.MyReaction!)
            .Ignore(d => d.IsSaved);

        config.NewConfig<Article, ArticleDetailsDto>()
            .Inherits<Article, ArticleCardDto>()
            .Map(d => d.AvailableLanguages, s => s.Translations.Select(t => t.Language).ToList())
            .Map(d => d.Summary, s => s.Translations.Any(t => t.Language == LocalizedProjection.Lang)
                ? s.Translations.Where(t => t.Language == LocalizedProjection.Lang).Select(t => t.Summary).FirstOrDefault()
                : s.Translations.Where(t => t.IsSource).Select(t => t.Summary).FirstOrDefault())
            .Map(d => d.ContentJson, s => s.Translations
                .Where(t => t.Language == LocalizedProjection.Lang)
                .Select(t => t.ContentJson).FirstOrDefault()
                ?? s.Translations.Where(t => t.IsSource).Select(t => t.ContentJson).FirstOrDefault())
            .Map(d => d.Topic, s => s.Topic == null
                ? null
                : new FieldRefDto(
                    s.Topic.Id, s.Topic.Slug,
                    LocalizedProjection.Ui == "en" ? s.Topic.NameEn : s.Topic.NameAr,
                    s.Topic.NameAr, s.Topic.NameEn))
            .Map(d => d.Tags, s => s.Tags.Select(t => t.Tag.Name).ToList())
            .Map(d => d.Sources, s => s.Sources.OrderBy(x => x.SortOrder).Select(x => new SourceDto(x.Title, x.Url)).ToList())
            .Map(d => d.ReviewedBy, s => s.ReviewStatus == ReviewStatus.Approved && s.ReviewedBy != null
                ? new ReviewerDto(s.ReviewedBy.DisplayName, s.ReviewedBy.Username)
                : null)
            // The hide note is loaded by the handler (latest article.hide in ModerationActions).
            .Map(d => d.Moderation, s => s.HiddenAt == null ? null : new ArticleModerationDto(s.HiddenAt.Value, null))
            .Ignore(d => d.Content)
            .Ignore(d => d.IsFollowingAuthor)
            .Ignore(d => d.CollectionIds);
    }
}
