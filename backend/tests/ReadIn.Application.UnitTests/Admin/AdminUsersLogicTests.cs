using System.Linq.Expressions;
using ReadIn.Application.Features.Admin;
using ReadIn.Application.Features.Admin.Users;

namespace ReadIn.Application.UnitTests.Admin;

/// <summary>
/// F23 users table: masked phone numbers (<c>+20***1234</c>: country code, three stars, the last four digits) and the small
/// expression helpers the list builds its filters and sorting with.
/// </summary>
public sealed class AdminUsersLogicTests
{
    [Theory]
    [InlineData("+201001234567", "+20***4567")]
    [InlineData("+966501234567", "+966***4567")]
    [InlineData("+12025550110", "+1***0110")]
    [InlineData("+97150123456", "+971***3456")]
    public void Phone_numbers_are_masked_with_their_country_code_and_last_four_digits(string e164, string masked) =>
        AdminPhones.Mask(e164).Should().Be(masked);

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    public void No_number_has_no_mask(string? e164) => AdminPhones.Mask(e164).Should().BeNull();

    [Fact]
    public void An_unparsable_number_still_hides_all_but_the_last_four_digits() =>
        AdminPhones.Mask("+0001234567").Should().EndWith("***4567").And.NotContain("123");

    [Fact]
    public void Expressions_compose_and_combine_into_one_lambda()
    {
        Expression<Func<string, int>> length = s => s.Length;
        var isLong = length.Compose(n => n > 3).Compile();
        (isLong("abcd"), isLong("ab")).Should().Be((true, false));

        Expression<Func<int, bool>> even = n => n % 2 == 0;
        Expression<Func<int, bool>> big = n => n > 10;
        var both = even.AndAlso(big).Compile();
        var either = even.OrElse(big).Compile();
        (both(12), both(8), both(11)).Should().Be((true, false, false));
        (either(8), either(11), either(3)).Should().Be((true, true, false));
    }

    [Fact]
    public void A_suspension_counts_only_while_it_lasts()
    {
        var now = new DateTime(2026, 11, 7, 12, 0, 0, DateTimeKind.Utc);
        AdminUserQueries.IsSuspendedAt(true, null, now).Should().BeTrue();
        AdminUserQueries.IsSuspendedAt(true, now.AddDays(1), now).Should().BeTrue();
        AdminUserQueries.IsSuspendedAt(true, now.AddDays(-1), now).Should().BeFalse();
        AdminUserQueries.IsSuspendedAt(false, null, now).Should().BeFalse();
    }
}
