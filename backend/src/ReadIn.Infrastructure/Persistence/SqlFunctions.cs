using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Query.SqlExpressions;
using ReadIn.Application.Common.Content;

namespace ReadIn.Infrastructure.Persistence;

/// <summary>SQL translations of Application methods that only run inside EF Core queries.</summary>
internal static class SqlFunctions
{
    /// <summary>
    /// TRANSLATE and REPLACE compare characters with the collation of their input, and under Arabic_100_CI_AI they match
    /// diacritics unpredictably, so they run on a binary collation and the result goes back to the search collation.
    /// </summary>
    private const string BinaryCollation = "Latin1_General_100_BIN2";

    public static void Map(ModelBuilder modelBuilder) =>
        // ArabicNormalizer.InSql(x) →
        // REPLACE(TRANSLATE(x COLLATE BIN2, N'<from>', N'<to>'), N'ـ', N'') COLLATE Arabic_100_CI_AI (SQL Server 2017+).
        modelBuilder.HasDbFunction(typeof(ArabicNormalizer).GetMethod(nameof(ArabicNormalizer.InSql))!)
            .HasTranslation(args =>
            {
                var mapping = args[0].TypeMapping;
                var (from, to) = ArabicNormalizer.SqlTranslation;
                var translated = Function(
                    "TRANSLATE",
                    new CollateExpression(args[0], BinaryCollation),
                    new SqlConstantExpression(from, mapping),
                    new SqlConstantExpression(to, mapping));
                var removed = Function(
                    "REPLACE",
                    translated,
                    new SqlConstantExpression(ArabicNormalizer.Tatweel.ToString(), mapping),
                    new SqlConstantExpression(string.Empty, mapping));
                return new CollateExpression(removed, AppDbContext.SearchCollation);

                SqlFunctionExpression Function(string name, SqlExpression text, SqlExpression a, SqlExpression b) => new(
                    name, [text, a, b], nullable: true, argumentsPropagateNullability: [true, false, false], typeof(string), mapping);
            });
}
