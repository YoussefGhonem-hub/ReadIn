using System.Text.Json;
using FluentValidation;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Commands.CreateArticle;

internal sealed class CreateArticleCommandValidator : AbstractValidator<CreateArticleCommand>
{
    public CreateArticleCommandValidator()
    {
        RuleFor(c => c.FieldId).NotEmpty();
        RuleFor(c => c.Language).Must(ArticleLanguages.IsValid).WithErrorCode("article.language_invalid");
        RuleFor(c => c.Title).NotEmpty().Length(5, 150);
        RuleFor(c => c.Subtitle).MaximumLength(250);
        RuleFor(c => c.Content.ValueKind).Equal(JsonValueKind.Object)
            .OverridePropertyName("content").WithErrorCode("article.content_invalid");
        RuleFor(c => c.Tags).Must(t => t is null || t.Count <= Article.MaxTags).WithErrorCode("article.tags.max_five");
        RuleForEach(c => c.Tags).NotEmpty().MaximumLength(40);
        RuleFor(c => c.Sources).Must(s => s is null || s.Count <= 30).WithErrorCode("validation.max_length");
        RuleForEach(c => c.Sources).ChildRules(source =>
        {
            source.RuleFor(s => s.Title).NotEmpty().MaximumLength(200);
            source.RuleFor(s => s.Url).Must(BeHttpUrl).WithErrorCode("validation.url");
        });
        RuleFor(c => c.CoverUrl).Must(u => u is null || BeHttpUrl(u)).WithErrorCode("validation.url");
        RuleFor(c => c.VersionBadge).MaximumLength(30);
    }

    private static bool BeHttpUrl(string url) =>
        url.Length <= 2048 && Uri.TryCreate(url, UriKind.Absolute, out var uri) && uri.Scheme is "http" or "https";
}
