using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Feed.DailyArticle;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.Queries.GetTodayArticle;

internal sealed class GetTodayArticleQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    TimeProvider clock,
    ArticleCards cards,
    DailyArticlePicker picker)
    : IQueryHandler<GetTodayArticleQuery, Result<ArticleCardDto?>>
{
    public async ValueTask<Result<ArticleCardDto?>> Handle(GetTodayArticleQuery query, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;

        if (currentUser.UserId is not { } userId)
        {
            var guestPick = await picker.PickForGuestAsync(now, ct);
            return Result.Success(guestPick is null ? null : await CardAsync(guestPick.Value, query.UiLanguage, null, ct));
        }

        var user = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.TimeZone, u.ArticleLanguagePref })
            .FirstAsync(ct);

        // The daily job stores the pick 30 minutes before the reminder time; before that (or without a device) it is made
        // here. Either way there is one pick per local date, so the pushed article is the hero card all day.
        var articleId = await picker.GetOrPickAsync(userId, DailySchedule.LocalDate(now, user.TimeZone), ct);
        if (articleId is null) return Result.Success<ArticleCardDto?>(null);

        return Result.Success(await CardAsync(articleId.Value, query.UiLanguage, user.ArticleLanguagePref, ct));
    }

    private async Task<ArticleCardDto?> CardAsync(Guid articleId, string uiLanguage, string? articleLanguage, CancellationToken ct)
    {
        using var _ = LocalizedProjection.Begin(uiLanguage, articleLanguage);
        var card = await db.Articles.AsNoTracking()
            .Where(a => a.Id == articleId)
            .ProjectToType<ArticleCardDto>(mapping)
            .FirstOrDefaultAsync(ct);
        if (card is null) return null;

        return (await cards.CompleteAsync([card], ct))[0];
    }
}
