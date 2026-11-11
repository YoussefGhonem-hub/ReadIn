using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Devotions;

namespace ReadIn.Application.Features.Devotions;

/// <summary>
/// POST /me/duas (SPEC F38): a new du'a, added last. At most 200 per account (<c>409 dua.limit</c>). No content filter:
/// nobody else ever sees it.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Devotions.Access)]
/// <param name="Repeat">How many times it is said, 1–1,000; null is 1.</param>
public sealed record CreatePersonalDuaCommand(string? Title, string? Text, int? Repeat = null) : ICommand<Result<PersonalDuaDto>>;

/// <summary>PATCH /me/duas/{id}: replaces the title, the text and the repeat count; a missing or empty title clears it, a
/// missing repeat count is 1.</summary>
[Authenticated]
[RequirePermission(Permissions.Devotions.Access)]
public sealed record EditPersonalDuaCommand(Guid DuaId, string? Title, string? Text, int? Repeat = null) : ICommand<Result<PersonalDuaDto>>;

/// <summary>DELETE /me/duas/{id}.</summary>
[Authenticated]
[RequirePermission(Permissions.Devotions.Access)]
public sealed record DeletePersonalDuaCommand(Guid DuaId) : ICommand<Result>;

internal static class PersonalDuaRules
{
    /// <summary>The cleaned text: empty is <c>validation.required</c>, over 2,000 characters <c>validation.length</c> (<c>errors.text</c>).</summary>
    public static IRuleBuilderOptions<T, string?> DuaText<T>(this IRuleBuilderInitial<T, string?> rule) => rule
        .Cascade(CascadeMode.Stop)
        .Must(text => PersonalDuaText.Text(text).Length > 0).WithErrorCode("validation.required")
        .Must(text => PersonalDuaText.Text(text).Length <= PersonalDua.MaxTextLength).WithErrorCode("validation.length");

    /// <summary>The cleaned title: over 100 characters is <c>validation.length</c> (<c>errors.title</c>); empty is fine (null).</summary>
    public static IRuleBuilderOptions<T, string?> DuaTitle<T>(this IRuleBuilderInitial<T, string?> rule) => rule
        .Must(title => (PersonalDuaText.Title(title)?.Length ?? 0) <= PersonalDua.MaxTitleLength).WithErrorCode("validation.length");

    /// <summary>The repeat count: null is 1, otherwise 1–1,000 or <c>validation.range</c> (<c>errors.repeat</c>).</summary>
    public static IRuleBuilderOptions<T, int?> DuaRepeat<T>(this IRuleBuilderInitial<T, int?> rule) => rule
        .Must(repeat => repeat is null or >= 1 and <= PersonalDua.MaxRepeat).WithErrorCode("validation.range");

    public static int RepeatOf(int? repeat) => repeat ?? PersonalDua.DefaultRepeat;
}

internal sealed class CreatePersonalDuaCommandValidator : AbstractValidator<CreatePersonalDuaCommand>
{
    public CreatePersonalDuaCommandValidator()
    {
        RuleFor(c => c.Title).DuaTitle();
        RuleFor(c => c.Text).DuaText();
        RuleFor(c => c.Repeat).DuaRepeat();
    }
}

internal sealed class EditPersonalDuaCommandValidator : AbstractValidator<EditPersonalDuaCommand>
{
    public EditPersonalDuaCommandValidator()
    {
        RuleFor(c => c.Title).DuaTitle();
        RuleFor(c => c.Text).DuaText();
        RuleFor(c => c.Repeat).DuaRepeat();
    }
}

internal sealed class CreatePersonalDuaCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<CreatePersonalDuaCommand, Result<PersonalDuaDto>>
{
    public async ValueTask<Result<PersonalDuaDto>> Handle(CreatePersonalDuaCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var title = PersonalDuaText.Title(command.Title);
        var text = PersonalDuaText.Text(command.Text);

        // Two creates at the same moment (two devices, a double tap) run one after the other under the account's row
        // lock, so the count below is never stale and the 200 limit holds.
        return await db.LockedForUserAsync<Result<PersonalDuaDto>>(userId, async ct =>
        {
            if (await db.PersonalDuas.CountAsync(d => d.UserId == userId, ct) >= PersonalDua.MaxPerUser) return PersonalDuaErrors.Limit;

            var dua = new PersonalDua(userId, title, text, PersonalDuaRules.RepeatOf(command.Repeat), clock.GetUtcNow().UtcDateTime);
            db.PersonalDuas.Add(dua);
            await db.SaveChangesAsync(ct);
            return PersonalDuaDto.From(dua);
        }, cancellationToken);
    }
}

internal sealed class EditPersonalDuaCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<EditPersonalDuaCommand, Result<PersonalDuaDto>>
{
    public async ValueTask<Result<PersonalDuaDto>> Handle(EditPersonalDuaCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        // Another account's du'a answers like one that doesn't exist.
        var dua = await db.PersonalDuas.FirstOrDefaultAsync(d => d.Id == command.DuaId && d.UserId == userId, cancellationToken);
        if (dua is null) return PersonalDuaErrors.NotFound;

        dua.Edit(
            PersonalDuaText.Title(command.Title), PersonalDuaText.Text(command.Text), PersonalDuaRules.RepeatOf(command.Repeat),
            clock.GetUtcNow().UtcDateTime);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException)
        {
            // Deleted on another device meanwhile.
            return PersonalDuaErrors.NotFound;
        }
        return PersonalDuaDto.From(dua);
    }
}

internal sealed class DeletePersonalDuaCommandHandler(IAppDbContext db, ICurrentUser currentUser)
    : ICommandHandler<DeletePersonalDuaCommand, Result>
{
    public async ValueTask<Result> Handle(DeletePersonalDuaCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var deleted = await db.PersonalDuas
            .Where(d => d.Id == command.DuaId && d.UserId == userId)
            .ExecuteDeleteAsync(cancellationToken);
        return deleted == 0 ? PersonalDuaErrors.NotFound : Result.Success();
    }
}
