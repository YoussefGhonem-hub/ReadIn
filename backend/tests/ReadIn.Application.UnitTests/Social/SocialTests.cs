using Mediator;
using NSubstitute;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Reactions.Commands.SetReaction;
using ReadIn.Application.Features.Reactions.Queries.GetArticleReactors;
using ReadIn.Application.Features.SavedArticles.Commands.CreateCollection;
using ReadIn.Application.Features.SavedArticles.Commands.RenameCollection;
using ReadIn.Domain.Common;

namespace ReadIn.Application.UnitTests.Social;

public sealed class SocialValidatorTests
{
    [Theory]
    [InlineData("insightful")]
    [InlineData("love")]
    [InlineData("fire")]
    [InlineData("mindBlown")]
    public void The_four_reactions_are_valid(string type) =>
        new SetReactionCommandValidator().Validate(new SetReactionCommand(Guid.NewGuid(), type)).IsValid.Should().BeTrue();

    [Theory]
    [InlineData(null)]
    [InlineData("like")]
    [InlineData("2")]
    public void Other_reactions_report_reaction_invalid(string? type)
    {
        var result = new SetReactionCommandValidator().Validate(new SetReactionCommand(Guid.NewGuid(), type));

        ValidationErrors.From(result.Errors).Details!["type"].Should().Equal("reaction.invalid");
    }

    [Fact]
    public void The_reactors_filter_is_optional_but_must_be_a_reaction()
    {
        var validator = new GetArticleReactorsQueryValidator();

        validator.Validate(new GetArticleReactorsQuery(Guid.NewGuid(), null, null, 20)).IsValid.Should().BeTrue();
        validator.Validate(new GetArticleReactorsQuery(Guid.NewGuid(), "fire", null, 20)).IsValid.Should().BeTrue();
        ValidationErrors.From(validator.Validate(new GetArticleReactorsQuery(Guid.NewGuid(), "wow", null, 20)).Errors)
            .Details!["type"].Should().Equal("reaction.invalid");
    }

    [Theory]
    [InlineData("", "validation.required")]
    [InlineData("   ", "validation.required")]
    [InlineData("1234567890123456789012345678901234567890123456789012345678901", "validation.max_length")]
    public void Collection_names_are_one_to_sixty_characters(string name, string code)
    {
        ValidationErrors.From(new CreateCollectionCommandValidator().Validate(new CreateCollectionCommand(name)).Errors)
            .Details!["name"].Should().Equal(code);
        ValidationErrors.From(new RenameCollectionCommandValidator().Validate(new RenameCollectionCommand(Guid.NewGuid(), name)).Errors)
            .Details!["name"].Should().Equal(code);
    }

    [Fact]
    public void Names_are_measured_after_trimming() =>
        new CreateCollectionCommandValidator().Validate(new CreateCollectionCommand($"  {new string('a', 60)}  ")).IsValid.Should().BeTrue();
}

public sealed class PersonalizationBehaviorTests
{
    public sealed record CachedQuery : IQuery<Result<string>>, IPersonalizedQuery<Result<string>>
    {
        public Result<string> Personalize(Result<string> response, ICurrentUser viewer) => response.Value + "+sync";
    }

    private sealed class AppendPersonalizer(string suffix) : IQueryPersonalizer<CachedQuery, Result<string>>
    {
        public ValueTask<Result<string>> PersonalizeAsync(CachedQuery message, Result<string> response, CancellationToken cancellationToken) =>
            ValueTask.FromResult<Result<string>>(response.Value + suffix);
    }

    [Fact]
    public async Task Database_personalizers_run_after_the_query_own_personalization_on_every_result()
    {
        var behavior = new PersonalizationBehavior<CachedQuery, Result<string>>(
            Substitute.For<ICurrentUser>(), [new AppendPersonalizer("+viewer")]);

        var result = await behavior.Handle(new CachedQuery(), (_, _) => ValueTask.FromResult(Result.Success("cached")), CancellationToken.None);

        result.Value.Should().Be("cached+sync+viewer");
    }
}

public sealed class ArabicSqlNormalizationTests
{
    [Fact]
    public void The_sql_rules_match_the_normalizer_character_for_character()
    {
        var (from, to) = ReadIn.Application.Common.Content.ArabicNormalizer.SqlTranslation;

        from.Length.Should().Be(to.Length, "TRANSLATE needs strings of the same length");
        from.Should().Contain("ُ").And.Contain("ّ").And.Contain("أ").And.Contain("ة");
        for (var i = 0; i < from.Length; i++)
        {
            var expected = to[i] == ReadIn.Application.Common.Content.ArabicNormalizer.Tatweel ? string.Empty : to[i].ToString();
            ReadIn.Application.Common.Content.ArabicNormalizer.Normalize($"x{from[i]}y").Should().Be($"x{expected}y");
        }
    }
}
