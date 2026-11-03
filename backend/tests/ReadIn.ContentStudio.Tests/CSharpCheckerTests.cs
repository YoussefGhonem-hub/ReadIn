using ReadIn.ContentStudio.Validation;

namespace ReadIn.ContentStudio.Tests;

/// <summary>C# snippets compile in-process like a <c>dotnet new web</c> project (SPEC §19.3).</summary>
public sealed class CSharpCheckerTests
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static Snippet Snippet(string code, string? stub = null) => new("sample", "b1", "csharp", code, Compile: true, stub);

    [Fact]
    public async Task Minimal_api_programs_and_ef_core_types_compile()
    {
        const string code = """
            var builder = WebApplication.CreateBuilder(args);
            builder.Services.AddScoped<IOrderService, OrderService>();
            var app = builder.Build();
            app.MapGet("/orders/{id:int}", (int id, IOrderService orders) => orders.Find(id));
            app.Run();

            public interface IOrderService { Order? Find(int id); }
            public sealed class OrderService : IOrderService { public Order? Find(int id) => null; }
            public sealed class Shop(Microsoft.EntityFrameworkCore.DbContextOptions options) : Microsoft.EntityFrameworkCore.DbContext(options);
            """;

        var run = await new CSharpChecker().CheckAsync([Snippet(code, stub: "public record Order(int Id, decimal Total);")], Ct);

        run.Errors.Should().BeEmpty();
        run.Checked.Should().Be(1);
    }

    [Fact]
    public async Task Errors_are_reported_with_the_snippet_line()
    {
        var run = await new CSharpChecker().CheckAsync([Snippet("var total = 1;\nstring name = total;")], Ct);

        run.Errors.Should().ContainSingle().Which.Message.Should().StartWith("line 2: CS0029");
    }
}
