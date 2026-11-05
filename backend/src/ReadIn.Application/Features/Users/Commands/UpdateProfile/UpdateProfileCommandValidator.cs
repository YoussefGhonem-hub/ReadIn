using FluentValidation;
using FluentValidation.Results;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Users.Commands.UpdateProfile;

internal sealed class UpdateProfileCommandValidator : AbstractValidator<UpdateProfileCommand>
{
    public UpdateProfileCommandValidator(IFileStorage storage)
    {
        RuleFor(c => c.DisplayName).NotEmpty().Length(2, 60);
        RuleFor(c => c.Username)
            .Must(User.IsValidUsername)
            .WithErrorCode("user.username_invalid");
        RuleFor(c => c.Bio).MaximumLength(300);
        // An uploaded avatar (relative path or its public URL), or any external https image (e.g. the sign-in provider's photo).
        RuleFor(c => c.Avatar!.Url)
            .Must(url => storage.TryGetUploadPath(url, out var path) ? path.Purpose == UploadPurpose.Avatar : BeHttpsUrl(url!))
            .When(c => c.Avatar?.Url is not null)
            .WithErrorCode("validation.url")
            .OverridePropertyName("avatarUrl");

        // The title and the social links (F14): the domain's rules, reported under `headline` and `links[i].url` etc.
        RuleFor(c => c.Headline).Custom((change, context) => AddHeadlineFailures(change, context));
        RuleFor(c => c.Links).Custom((links, context) =>
        {
            if (links is null) return;
            var result = ProfileLinkRules.Check(links.ToDomain());
            if (result.IsFailure) AddFailures(result.Error.Details!, context);
        });
    }

    /// <summary>Shared with PUT /me/profile/complete.</summary>
    public static void AddHeadlineFailures<T>(HeadlineChange? change, ValidationContext<T> context)
    {
        if (change is null) return;
        if (HeadlineRules.Problem(HeadlineRules.Normalize(change.Value)) is { } code)
            context.AddFailure(new ValidationFailure("headline", code) { ErrorCode = code });
    }

    private static void AddFailures<T>(IReadOnlyDictionary<string, string[]> errors, ValidationContext<T> context)
    {
        foreach (var (property, codes) in errors)
        {
            foreach (var code in codes) context.AddFailure(new ValidationFailure(property, code) { ErrorCode = code });
        }
    }

    private static bool BeHttpsUrl(string value) =>
        value.Length <= 2048 && Uri.TryCreate(value, UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps;
}
