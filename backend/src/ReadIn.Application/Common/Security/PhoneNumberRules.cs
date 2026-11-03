using System.Diagnostics.CodeAnalysis;
using PhoneNumbers;

namespace ReadIn.Application.Common.Security;

/// <summary>
/// Phone numbers are validated with libphonenumber (mobile numbers only) and always stored as E.164, e.g.
/// <c>+201001234567</c> (SPEC §9.4). Clients send E.164 already; the API re-validates it.
/// </summary>
public static class PhoneNumberRules
{
    public const int MaxLength = 16; // "+" and up to 15 digits

    private static readonly PhoneNumberUtil Util = PhoneNumberUtil.GetInstance();

    /// <summary>Accepts E.164 input (Arabic-Indic and Persian digits, spaces and dashes are tolerated).</summary>
    public static bool TryNormalize(string? input, [NotNullWhen(true)] out string? e164)
    {
        e164 = null;
        if (string.IsNullOrWhiteSpace(input) || input.Length > 32) return false;

        var cleaned = new string(input.Select(ToAsciiDigit).Where(c => char.IsAsciiDigit(c) || c == '+').ToArray());
        if (!cleaned.StartsWith('+') || cleaned.LastIndexOf('+') != 0) return false;

        PhoneNumber number;
        try
        {
            number = Util.Parse(cleaned, null);
        }
        catch (NumberParseException)
        {
            return false;
        }

        if (!Util.IsValidNumber(number)) return false;
        if (Util.GetNumberType(number) is not (PhoneNumberType.MOBILE or PhoneNumberType.FIXED_LINE_OR_MOBILE)) return false;

        e164 = Util.Format(number, PhoneNumberFormat.E164);
        return true;
    }

    public static bool IsValid(string? input) => TryNormalize(input, out _);

    /// <summary>The national significant number (<c>1001234567</c> for <c>+201001234567</c>).</summary>
    public static string NationalNumber(string e164)
    {
        try
        {
            return Util.Parse(e164, null).NationalNumber.ToString(System.Globalization.CultureInfo.InvariantCulture);
        }
        catch (NumberParseException)
        {
            return e164.TrimStart('+');
        }
    }

    /// <summary>For logs: <c>+20******4567</c> (SPEC §9.5).</summary>
    public static string Mask(string? e164) => e164 switch
    {
        null or "" => "(none)",
        { Length: <= 7 } => "****",
        _ => $"{e164[..3]}{new string('*', e164.Length - 7)}{e164[^4..]}",
    };

    internal static char ToAsciiDigit(char c) => c switch
    {
        >= '٠' and <= '٩' => (char)('0' + (c - '٠')), // Arabic-Indic
        >= '۰' and <= '۹' => (char)('0' + (c - '۰')), // Persian
        _ => c,
    };
}
