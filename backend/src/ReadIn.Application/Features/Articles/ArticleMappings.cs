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
        // A card has the article's first three tags (F34). Not Inherits: Mapster would give the details the card's map.
        // Tags come in the writer's order; hidden ones (F32) are left out but stay on the article.
        CardMembers(config.NewConfig<Article, ArticleCardDto>())
            .Map(d => d.Tags, s => s.Tags.Where(t => !t.Tag.IsHidden).OrderBy(t => t.Position).ThenBy(t => t.TagId)
                .Select(t => new TagRefDto(t.Tag.Slug, t.Tag.Name)).Take(ArticleCardDto.MaxCardTags).ToList());

        CardMembers(config.NewConfig<Article, ArticleDetailsDto>())
            .Map(d => d.Tags, s => s.Tags.Where(t => !t.Tag.IsHidden).OrderBy(t => t.Position).ThenBy(t => t.TagId)
                .Select(t => new TagRefDto(t.Tag.Slug, t.Tag.Name)).ToList())
            .Map(d => d.AvailableLanguages, s => s.Translations.Select(t => t.Language).ToList())
            .Map(d => d.Summary, s => s.Translations.Any(t => t.Language == LocalizedProjection.Lang)
                ? s.Translations.Where(t => t.Language == LocalizedProjection.Lang).Select(t => t.Summary).FirstOrDefault()
                : s.Translations.Where(t => t.IsSource).Select(t => t.Summary).FirstOrDefault())
            .Map(d => d.ContentJson, s => s.Translations
                .Where(t => t.Language == LocalizedProjection.Lang)
                .Select(t => t.ContentJson).FirstOrDefault()
                ?? s.Translations.Where(t => t.IsSource).Select(t => t.ContentJson).FirstOrDefault())
            .Map(d => d.Sources, s => s.Sources.OrderBy(x => x.SortOrder).Select(x => new SourceDto(x.Title, x.Url)).ToList())
            // The hide note is loaded by the handler (latest article.hide in ModerationActions).
            .Map(d => d.Moderation, s => s.HiddenAt == null ? null : new ArticleModerationDto(s.HiddenAt.Value, null))
            // The writer's category (F31): the reader's "في قسم {name}".
            .Map(d => d.Category, s => s.WriterCategory == null ? null : new WriterCategoryRefDto(s.WriterCategory.Slug, s.WriterCategory.Name))
            .Ignore(d => d.Content)
            .Ignore(d => d.CollectionIds);
    }

    /// <summary>What cards and details share; <see cref="ArticleCardDto.Tags"/> is mapped by each (three or all).</summary>
    private static TypeAdapterSetter<Article, TCard> CardMembers<TCard>(TypeAdapterSetter<Article, TCard> setter)
        where TCard : ArticleCardDto =>
        setter
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
            // The post card's text (F34); a version not backfilled yet has no excerpt, so all of it is "more".
            .Map(d => d.Excerpt, s => s.Translations.Any(t => t.Language == LocalizedProjection.Lang)
                ? s.Translations.Where(t => t.Language == LocalizedProjection.Lang).Select(t => t.Excerpt).FirstOrDefault()
                : s.Translations.Where(t => t.IsSource).Select(t => t.Excerpt).FirstOrDefault())
            .Map(d => d.HasMore, s => s.Translations.Any(t => t.Language == LocalizedProjection.Lang)
                ? s.Translations.Where(t => t.Language == LocalizedProjection.Lang).Select(t => t.Excerpt == null || t.ExcerptHasMore).FirstOrDefault()
                : s.Translations.Where(t => t.IsSource).Select(t => t.Excerpt == null || t.ExcerptHasMore).FirstOrDefault())
            .Map(d => d.TagCount, s => s.Tags.Count(t => !t.Tag.IsHidden))
            .Map(d => d.Field, s => new FieldRefDto(
                s.Field.Id, s.Field.Slug,
                LocalizedProjection.Ui == "en" ? s.Field.NameEn : s.Field.NameAr,
                s.Field.NameAr, s.Field.NameEn, s.Field.IsSensitive))
            // Cards carry the topic too since F28 (the "كتم المواضيع" sheet); a topic carries its field's flag.
            .Map(d => d.Topic, s => s.Topic == null
                ? null
                : new FieldRefDto(
                    s.Topic.Id, s.Topic.Slug,
                    LocalizedProjection.Ui == "en" ? s.Topic.NameEn : s.Topic.NameAr,
                    s.Topic.NameAr, s.Topic.NameEn, s.Field.IsSensitive))
            .Map(d => d.Author, s => s.Author == null ? null : new AuthorDto(
                s.Author.Id, s.Author.DisplayName, s.Author.Username, s.Author.AvatarUrl,
                s.Author.Roles.Any(r => r.RoleId == RoleIds.VerifiedWriter)))
            // The denormalized counters on Articles (F27); ReactionCount and SaveCount map by name.
            .Map(d => d.Reactions, s => new ReactionCountsDto(s.InsightfulCount, s.LoveCount, s.FireCount, s.MindBlownCount))
            // Loaded after the projection: attachments by ArticleAttachmentsReader (absolute URLs, page limits), the
            // viewer's own state by ArticleViewerStateReader (signed-in viewers only).
            .Ignore(d => d.Attachments!)
            .Ignore(d => d.MyReaction!)
            .Ignore(d => d.IsSaved)
            .Ignore(d => d.IsFollowingAuthor)
            .Ignore(d => d.IsAuthorMuted)
            .Ignore(d => d.IsFieldMuted)
            .Ignore(d => d.IsTopicMuted);
}
