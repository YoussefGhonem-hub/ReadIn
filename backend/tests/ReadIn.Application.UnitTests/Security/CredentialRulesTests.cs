using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Application.Features.Auth.Commands.Register;

namespace ReadIn.Application.UnitTests.Security;

public sealed class PhoneNumberRulesTests
{
    [Theory]
    [InlineData("+201001234567", "+201001234567")]
    [InlineData("+20 100 123 4567", "+201001234567")]
    [InlineData("+٢٠١٠٠١٢٣٤٥٦٧", "+201001234567")] // Arabic-Indic digits
    [InlineData("+۹۶۶۵۰۱۲۳۴۵۶۷", "+966501234567")] // Persian digits, Saudi mobile
    [InlineData("+12025550101", "+12025550101")] // fictional US 555-01XX
    public void Valid_mobile_numbers_are_normalized_to_e164(string input, string expected)
    {
        PhoneNumberRules.TryNormalize(input, out var e164).Should().BeTrue();
        e164.Should().Be(expected);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("01001234567")] // no country code
    [InlineData("+2010012")] // too short
    [InlineData("+20223456789")] // Cairo landline, not a mobile
    [InlineData("+01229391155")] // country code 0 does not exist
    [InlineData("+20+1001234567")]
    public void Invalid_or_landline_numbers_are_rejected(string? input) => PhoneNumberRules.IsValid(input).Should().BeFalse();

    [Fact]
    public void Numbers_are_masked_in_logs() => PhoneNumberRules.Mask("+201001234567").Should().Be("+20******4567");
}

public sealed class PasswordRulesTests
{
    [Fact]
    public void A_good_password_passes() => PasswordRules.Check("Nile-river-2026", "+201001234567").Should().BeEmpty();

    [Theory]
    [InlineData("short1", PasswordRules.TooShort)]
    [InlineData("onlyletters", PasswordRules.DigitRequired)]
    [InlineData("1234567890", PasswordRules.LetterRequired)]
    [InlineData("qwerty123", PasswordRules.TooCommon)]
    [InlineData("Password1", PasswordRules.TooCommon)]
    [InlineData("me1001234567x", PasswordRules.ContainsPhone)]
    [InlineData("x٠١٠٠١٢٣٤٥٦٧", PasswordRules.ContainsPhone)]
    public void Weak_passwords_are_rejected_with_a_code(string password, string code) =>
        PasswordRules.Check(password, "+201001234567").Should().Contain(code);

    [Fact]
    public void Passwords_longer_than_128_are_rejected() =>
        PasswordRules.Check(new string('a', 128) + "1", null).Should().Contain(PasswordRules.TooLong);
}

public sealed class RecoveryPinRulesTests
{
    private const string Phone = "+201001234567";

    /// <summary>The sign-up validator, which sees the phone number and the password next to the PIN.</summary>
    private static IEnumerable<string> SignUpErrors(string password, string pin) =>
        new RegisterCommandValidator(Options.Create(new RecoveryOptions()))
            .Validate(new RegisterCommand(Phone, password, pin)).Errors.Select(e => $"{e.PropertyName}: {e.ErrorCode}");

    [Fact]
    public void A_good_pin_passes() => RecoveryPinRules.Check("4826", 4).Should().BeEmpty();

    /// <summary>The PINs that were once rejected as weak (user decision, 2026-11-07: any digits of the right length).</summary>
    [Theory]
    [InlineData("1111")] // one digit
    [InlineData("5566")] // pairs
    [InlineData("1234")] // ascending
    [InlineData("8765")] // descending
    [InlineData("2580")] // common (keypad column)
    [InlineData("1987")] // a year
    [InlineData("2030")]
    [InlineData("4567")] // last digits of the phone number
    [InlineData("2026")] // first digits of the password (also a year)
    public void Any_four_digits_pass_sign_up(string pin)
    {
        RecoveryPinRules.Check(pin, 4).Should().BeEmpty();
        SignUpErrors("Nile-river-2026", pin).Should().BeEmpty();
    }

    [Fact]
    public void The_first_digits_of_the_password_pass() => SignUpErrors("my-pass-8264-x", "8264").Should().BeEmpty();

    [Theory]
    [InlineData("482", RecoveryPinRules.WrongLength)]
    [InlineData("48261", RecoveryPinRules.WrongLength)]
    [InlineData("48a6", RecoveryPinRules.DigitsOnly)]
    public void Malformed_pins_are_rejected(string pin, string code)
    {
        RecoveryPinRules.Check(pin, 4).Should().Equal(code);
        SignUpErrors("Nile-river-2026", pin).Should().Equal($"RecoveryPin: {code}");
    }

    [Fact]
    public void Arabic_indic_digits_are_converted()
    {
        RecoveryPinRules.Normalize(" ٤٨٢٦ ").Should().Be("4826");
        SignUpErrors("Nile-river-2026", "١١١١").Should().BeEmpty();
    }

    [Fact]
    public void The_length_comes_from_the_setting()
    {
        RecoveryPinRules.Check("482619", 6).Should().BeEmpty();
        RecoveryPinRules.Check("111111", 6).Should().BeEmpty();
        RecoveryPinRules.Check("4826", 6).Should().Equal(RecoveryPinRules.WrongLength);
    }
}
