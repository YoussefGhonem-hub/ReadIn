using System.Reflection;
using Mediator;
using NetArchTest.Rules;

namespace ReadIn.ArchitectureTests;

/// <summary>Clean Architecture rules from SPEC §6.1–§6.4, enforced on every build.</summary>
public sealed class LayerTests
{
    private static readonly Assembly Domain = typeof(Domain.Common.Entity).Assembly;
    private static readonly Assembly Application = typeof(Application.DependencyInjection).Assembly;
    private static readonly Assembly Infrastructure = typeof(Infrastructure.DependencyInjection).Assembly;
    private static readonly Assembly Api = typeof(Api.ApiSetup).Assembly;

    private static void ShouldPass(NetArchTest.Rules.TestResult result) =>
        result.IsSuccessful.Should().BeTrue("violations: " + string.Join(", ", result.FailingTypeNames ?? []));

    [Fact]
    public void Domain_depends_on_nothing() => ShouldPass(Types.InAssembly(Domain).ShouldNot()
        .HaveDependencyOnAny("ReadIn.Application", "ReadIn.Infrastructure", "ReadIn.Api",
            "Microsoft.EntityFrameworkCore", "Mapster", "Mediator", "FluentValidation", "Microsoft.AspNetCore")
        .GetResult());

    [Fact]
    public void Application_does_not_depend_on_infrastructure_or_api() => ShouldPass(Types.InAssembly(Application).ShouldNot()
        .HaveDependencyOnAny("ReadIn.Infrastructure", "ReadIn.Api", "Microsoft.AspNetCore", "Hangfire", "FirebaseAdmin", "Dapper")
        .GetResult());

    [Fact]
    public void Infrastructure_does_not_depend_on_api() => ShouldPass(Types.InAssembly(Infrastructure).ShouldNot()
        .HaveDependencyOn("ReadIn.Api")
        .GetResult());

    [Fact]
    public void Mapping_lives_only_in_application() // SPEC §6.4: no mapping in Api or Domain
    {
        ShouldPass(Types.InAssembly(Api).ShouldNot().HaveDependencyOn("Mapster").GetResult());
        ShouldPass(Types.InAssembly(Domain).ShouldNot().HaveDependencyOn("Mapster").GetResult());
    }

    [Fact]
    public void Handlers_are_internal_and_sealed() // SPEC §6.3
    {
        var handlers = Types.InAssembly(Application).That()
            .ImplementInterface(typeof(ICommandHandler<,>)).Or().ImplementInterface(typeof(IQueryHandler<,>));

        handlers.GetTypes().Should().HaveCountGreaterThan(10, "the rule must actually select the handlers");
        ShouldPass(handlers.Should().BeSealed().GetResult());
        ShouldPass(handlers.Should().NotBePublic().GetResult());
    }

    [Fact]
    public void Handlers_follow_naming_conventions() => ShouldPass(Types.InAssembly(Application).That()
        .ImplementInterface(typeof(ICommandHandler<,>)).Or().ImplementInterface(typeof(IQueryHandler<,>))
        .Should().HaveNameEndingWith("CommandHandler").Or().HaveNameEndingWith("QueryHandler")
        .GetResult());

    [Fact]
    public void Commands_and_queries_are_named_for_what_they_are()
    {
        ShouldPass(Types.InAssembly(Application).That().ImplementInterface(typeof(ICommand<>))
            .Should().HaveNameEndingWith("Command").GetResult());
        ShouldPass(Types.InAssembly(Application).That().ImplementInterface(typeof(IQuery<>))
            .Should().HaveNameEndingWith("Query").GetResult());
    }

    [Fact]
    public void Validators_are_internal_and_sealed()
    {
        var validators = Types.InAssembly(Application).That().Inherit(typeof(FluentValidation.AbstractValidator<>));

        validators.GetTypes().Should().HaveCountGreaterThan(3, "the rule must actually select the validators");
        ShouldPass(validators.Should().BeSealed().And().NotBePublic().GetResult());
    }

    [Fact]
    public void Domain_entities_do_not_expose_public_setters()
    {
        var offenders = Domain.GetTypes()
            .Where(t => t.Namespace?.StartsWith("ReadIn.Domain", StringComparison.Ordinal) == true && t is { IsClass: true, IsAbstract: false })
            .Where(t => !t.IsDefined(typeof(System.Runtime.CompilerServices.CompilerGeneratedAttribute)) && !IsRecord(t))
            .SelectMany(t => t.GetProperties(BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly)
                .Where(p => p.SetMethod is { IsPublic: true } setter && !IsInitOnly(setter))
                .Select(p => $"{t.Name}.{p.Name}"))
            .ToList();

        offenders.Should().BeEmpty("entities change state only through domain methods (SPEC §6.4)");
    }

    private static bool IsRecord(Type type) => type.GetMethod("<Clone>$") is not null;

    private static bool IsInitOnly(MethodInfo setter) =>
        setter.ReturnParameter.GetRequiredCustomModifiers().Contains(typeof(System.Runtime.CompilerServices.IsExternalInit));
}
