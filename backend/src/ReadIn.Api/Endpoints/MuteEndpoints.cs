using Mediator;
using ReadIn.Api.Errors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Mutes;
using ReadIn.Application.Features.Mutes.Commands.MuteContent;
using ReadIn.Application.Features.Mutes.Commands.MuteUser;
using ReadIn.Application.Features.Mutes.Commands.ShowLess;
using ReadIn.Application.Features.Mutes.Commands.UndoShowLess;
using ReadIn.Application.Features.Mutes.Commands.UnmuteContent;
using ReadIn.Application.Features.Mutes.Commands.UnmuteUser;
using ReadIn.Application.Features.Mutes.Queries.GetMutes;
using ReadIn.Domain.Engagement;

namespace ReadIn.Api.Endpoints;

/// <summary>F28 Mute and "show less" (SPEC F28, §17.2). Bearer only; writes need follows.manage and the writes limit.</summary>
internal sealed class MuteEndpoints : IEndpointGroup
{
    public void Map(RouteGroupBuilder api)
    {
        var users = api.MapGroup("/users").RequireAuthorization().WithTags("Mute");

        users.MapPut("/{id:guid}/mute", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new MuteUserCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Mute a writer and end your follow of them (idempotent; not yourself or the official account)")
            .Produces<UserMuteStateDto>();

        users.MapDelete("/{id:guid}/mute", async (Guid id, bool? restoreFollow, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UnmuteUserCommand(id, restoreFollow ?? false), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Unmute a writer (idempotent); restoreFollow=true follows them again (the toast's Undo)")
            .Produces<UserMuteStateDto>();

        var me = api.MapGroup("/me").RequireAuthorization().WithTags("Mute");

        me.MapGet("/mutes", async (ISender sender, ICurrentUser user, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new GetMutesQuery(user.UiLanguage), ct)).ToHttp(http))
            .WithSummary("Settings → Muted: your muted writers, fields and topics, newest first")
            .Produces<MutesDto>();

        me.MapPut("/mutes/fields/{id:guid}", (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                MuteAsync(new MuteContentCommand(ContentMuteTarget.Field, id), sender, http, ct))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Mute a field (idempotent)")
            .Produces<ContentMutesDto>();

        me.MapDelete("/mutes/fields/{id:guid}", (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                UnmuteAsync(new UnmuteContentCommand(ContentMuteTarget.Field, id), sender, http, ct))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Unmute a field (idempotent)")
            .Produces<ContentMutesDto>();

        me.MapPut("/mutes/topics/{id:guid}", (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                MuteAsync(new MuteContentCommand(ContentMuteTarget.Topic, id), sender, http, ct))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Mute a topic (idempotent)")
            .Produces<ContentMutesDto>();

        me.MapDelete("/mutes/topics/{id:guid}", (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                UnmuteAsync(new UnmuteContentCommand(ContentMuteTarget.Topic, id), sender, http, ct))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Unmute a topic (idempotent)")
            .Produces<ContentMutesDto>();

        var articles = api.MapGroup("/articles").RequireAuthorization().WithTags("Mute");

        articles.MapPut("/{id:guid}/show-less", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new ShowLessCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("\"Show less like this\": the article leaves your feeds and its topic goes lower in For you for 90 days")
            .Produces(StatusCodes.Status204NoContent);

        articles.MapDelete("/{id:guid}/show-less", async (Guid id, ISender sender, HttpContext http, CancellationToken ct) =>
                (await sender.Send(new UndoShowLessCommand(id), ct)).ToHttp(http))
            .RequireRateLimiting(RateLimitPolicies.Writes)
            .WithSummary("Undo \"show less\" (idempotent)")
            .Produces(StatusCodes.Status204NoContent);
    }

    private static async Task<IResult> MuteAsync(MuteContentCommand command, ISender sender, HttpContext http, CancellationToken ct) =>
        (await sender.Send(command, ct)).ToHttp(http);

    private static async Task<IResult> UnmuteAsync(UnmuteContentCommand command, ISender sender, HttpContext http, CancellationToken ct) =>
        (await sender.Send(command, ct)).ToHttp(http);
}
