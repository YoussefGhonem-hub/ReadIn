using FluentValidation;
using FluentValidation.Results;

namespace ReadIn.Application.Common.Security;

/// <summary>FluentValidation rules for the shared input components (SPEC §9.4). Each failure carries a stable code.</summary>
public static class CredentialValidators
{
    public const string PhoneInvalid = "phone.invalid";

    public static IRuleBuilderOptions<T, string> PhoneNumber<T>(this IRuleBuilder<T, string> rule) =>
        rule.Must(PhoneNumberRules.IsValid).WithErrorCode(PhoneInvalid);

    /// <param name="phoneNumber">The account's number, so the password can't contain it.</param>
    public static IRuleBuilderOptionsConditions<T, string> Password<T>(this IRuleBuilder<T, string> rule, Func<T, string?> phoneNumber) =>
        rule.Custom((password, context) =>
        {
            var e164 = PhoneNumberRules.TryNormalize(phoneNumber(context.InstanceToValidate), out var normalized) ? normalized : null;
            foreach (var code in PasswordRules.Check(password, e164)) context.AddFailure(Failure(context.PropertyPath, code));
        });

    public static IRuleBuilderOptionsConditions<T, string> RecoveryPin<T>(
        this IRuleBuilder<T, string> rule, int length, Func<T, string?> phoneNumber, Func<T, string?> password) =>
        rule.Custom((pin, context) =>
        {
            var instance = context.InstanceToValidate;
            var e164 = PhoneNumberRules.TryNormalize(phoneNumber(instance), out var normalized) ? normalized : null;
            foreach (var code in RecoveryPinRules.Check(RecoveryPinRules.Normalize(pin), length, e164, password(instance)))
                context.AddFailure(Failure(context.PropertyPath, code));
        });

    private static ValidationFailure Failure(string property, string code) => new(property, code) { ErrorCode = code };
}
