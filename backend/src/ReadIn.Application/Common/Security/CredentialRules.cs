using System.Reflection;

namespace ReadIn.Application.Common.Security;

/// <summary>
/// Password rules (SPEC §9.4): 8–128 characters, at least one letter and one digit, not one of the 10,000 most common
/// passwords, and not containing the phone number. Returns validation codes that clients translate.
/// </summary>
public static class PasswordRules
{
    public const int MinLength = 8;
    public const int MaxLength = 128;

    public const string TooShort = "password.too_short";
    public const string TooLong = "password.too_long";
    public const string LetterRequired = "password.letter_required";
    public const string DigitRequired = "password.digit_required";
    public const string TooCommon = "password.too_common";
    public const string ContainsPhone = "password.contains_phone";

    public static IReadOnlyList<string> Check(string? password, string? phoneNumberE164)
    {
        if (string.IsNullOrEmpty(password)) return [TooShort];

        var errors = new List<string>();
        if (password.Length < MinLength) errors.Add(TooShort);
        if (password.Length > MaxLength) errors.Add(TooLong);
        if (!password.Any(char.IsLetter)) errors.Add(LetterRequired);
        if (!password.Any(c => char.IsDigit(PhoneNumberRules.ToAsciiDigit(c)))) errors.Add(DigitRequired);
        if (errors.Count == 0 && CommonSecrets.Passwords.Contains(password.ToLowerInvariant())) errors.Add(TooCommon);
        if (phoneNumberE164 is not null && ContainsPhoneNumber(password, phoneNumberE164)) errors.Add(ContainsPhone);
        return errors;
    }

    private static bool ContainsPhoneNumber(string password, string e164)
    {
        var digits = new string(password.Select(PhoneNumberRules.ToAsciiDigit).Where(char.IsAsciiDigit).ToArray());
        var national = PhoneNumberRules.NationalNumber(e164);
        return national.Length >= 6 && (digits.Contains(national, StringComparison.Ordinal) || digits.Contains(e164[1..], StringComparison.Ordinal));
    }
}

/// <summary>
/// Recovery PIN rules (SPEC §9.4): digits only and exactly <c>Recovery:PinLength</c> of them (default 4). Any digits
/// pass: 1111, 1234, a year, the end of the phone number or the start of the password are all accepted (user decision,
/// 2026-11-07).
/// </summary>
public static class RecoveryPinRules
{
    public const string WrongLength = "pin.length";
    public const string DigitsOnly = "pin.digits_only";

    /// <summary>Converts Arabic-Indic/Persian digits, like the PIN input on every client.</summary>
    public static string Normalize(string? pin) =>
        pin is null ? string.Empty : new string(pin.Trim().Select(PhoneNumberRules.ToAsciiDigit).ToArray());

    /// <param name="pin">Already <see cref="Normalize"/>d.</param>
    /// <param name="length"><c>Recovery:PinLength</c>.</param>
    public static IReadOnlyList<string> Check(string pin, int length)
    {
        if (!pin.All(char.IsAsciiDigit)) return [DigitsOnly];
        return pin.Length == length ? [] : [WrongLength];
    }
}

/// <summary>
/// The list in <c>shared/security</c> (from SecLists, MIT) of common passwords that would otherwise pass the rules.
/// Embedded so the API never depends on files next to it.
/// </summary>
internal static class CommonSecrets
{
    public static readonly IReadOnlySet<string> Passwords = Load("ReadIn.common-passwords.txt");

    private static HashSet<string> Load(string resource)
    {
        using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resource)
            ?? throw new InvalidOperationException($"Embedded resource '{resource}' is missing.");
        using var reader = new StreamReader(stream);

        var set = new HashSet<string>(StringComparer.Ordinal);
        while (reader.ReadLine() is { } line)
        {
            if (line.Trim() is { Length: > 0 } value) set.Add(value);
        }
        return set;
    }
}
