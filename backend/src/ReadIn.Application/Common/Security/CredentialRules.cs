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
/// Recovery PIN rules (SPEC §9.4): exactly <c>Recovery:PinLength</c> digits (default 4) and not weak: one repeated digit,
/// an ascending/descending run, one of the 100 most common PINs, a year 1950–2030, the last digits of the phone number or
/// the first digits of the password.
/// </summary>
public static class RecoveryPinRules
{
    public const string WrongLength = "pin.length";
    public const string DigitsOnly = "pin.digits_only";
    public const string Weak = "pin.weak";

    /// <summary>Converts Arabic-Indic/Persian digits, like the PIN input on every client.</summary>
    public static string Normalize(string? pin) =>
        pin is null ? string.Empty : new string(pin.Trim().Select(PhoneNumberRules.ToAsciiDigit).ToArray());

    /// <param name="pin">Already <see cref="Normalize"/>d.</param>
    /// <param name="password">Null when the password isn't part of the request (it's never readable afterwards).</param>
    public static IReadOnlyList<string> Check(string pin, int length, string? phoneNumberE164, string? password)
    {
        if (!pin.All(char.IsAsciiDigit)) return [DigitsOnly];
        if (pin.Length != length) return [WrongLength];
        return IsWeak(pin, phoneNumberE164, password) ? [Weak] : [];
    }

    public static bool IsWeak(string pin, string? phoneNumberE164, string? password)
    {
        if (pin.Distinct().Count() == 1) return true;
        if (IsRun(pin, +1) || IsRun(pin, -1)) return true;

        if (pin.Length == 4)
        {
            if (CommonSecrets.Pins.Contains(pin)) return true;
            var year = int.Parse(pin, System.Globalization.CultureInfo.InvariantCulture);
            if (year is >= 1950 and <= 2030) return true;
        }

        if (phoneNumberE164 is not null && phoneNumberE164.EndsWith(pin, StringComparison.Ordinal)) return true;

        if (password is not null)
        {
            var passwordDigits = new string(password.Select(PhoneNumberRules.ToAsciiDigit).Where(char.IsAsciiDigit).ToArray());
            if (passwordDigits.Length >= pin.Length && passwordDigits.StartsWith(pin, StringComparison.Ordinal)) return true;
        }

        return false;
    }

    private static bool IsRun(string pin, int step)
    {
        for (var i = 1; i < pin.Length; i++)
            if (pin[i] - pin[i - 1] != step) return false;
        return true;
    }
}

/// <summary>
/// The lists in <c>shared/security</c> (from SecLists, MIT): common passwords that would otherwise pass the rules, and
/// the 100 most common 4-digit PINs. Embedded so the API never depends on files next to it.
/// </summary>
internal static class CommonSecrets
{
    public static readonly IReadOnlySet<string> Passwords = Load("ReadIn.common-passwords.txt");
    public static readonly IReadOnlySet<string> Pins = Load("ReadIn.common-pins.txt");

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
