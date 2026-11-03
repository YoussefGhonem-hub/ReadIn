using FluentValidation;
using FluentValidation.Results;
using Mediator;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Behaviors;

internal sealed class ValidationBehavior<TMessage, TResponse>(IEnumerable<IValidator<TMessage>> validators)
    : IPipelineBehavior<TMessage, TResponse>
    where TMessage : notnull, IMessage
{
    public async ValueTask<TResponse> Handle(TMessage message, MessageHandlerDelegate<TMessage, TResponse> next, CancellationToken cancellationToken)
    {
        var failures = new List<ValidationFailure>();
        foreach (var validator in validators)
        {
            var result = await validator.ValidateAsync(message, cancellationToken);
            failures.AddRange(result.Errors);
        }

        if (failures.Count == 0) return await next(message, cancellationToken);

        return ResultFailure<TResponse>.Create(ValidationErrors.From(failures));
    }
}

public static class ValidationErrors
{
    public const string Code = "validation.failed";

    /// <summary>
    /// Maps FluentValidation failures to <c>{ "camelCaseProperty": ["error.code", ...] }</c>; clients translate the codes.
    /// </summary>
    public static Error From(IEnumerable<ValidationFailure> failures)
    {
        var details = failures
            .GroupBy(f => ToCamelCase(f.PropertyName))
            .ToDictionary(g => g.Key, g => g.Select(ToCode).Distinct().ToArray());

        return Error.Validation(Code, "Validation failed.") with { Details = details };
    }

    private static string ToCode(ValidationFailure failure) => failure.ErrorCode switch
    {
        { } code when code.Contains('.', StringComparison.Ordinal) => code,
        "NotEmptyValidator" or "NotNullValidator" => "validation.required",
        "MaximumLengthValidator" => "validation.max_length",
        "MinimumLengthValidator" => "validation.min_length",
        "LengthValidator" => "validation.length",
        "RegularExpressionValidator" => "validation.format",
        "EmailValidator" => "validation.email",
        "InclusiveBetweenValidator" or "ExclusiveBetweenValidator" => "validation.range",
        _ => "validation.invalid",
    };

    private static string ToCamelCase(string propertyName) =>
        string.Join('.', propertyName.Split('.').Select(p => p.Length == 0 ? p : char.ToLowerInvariant(p[0]) + p[1..]));
}
