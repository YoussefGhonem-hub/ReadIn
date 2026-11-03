using System.Collections.Concurrent;
using System.Reflection.PortableExecutable;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace ReadIn.ContentStudio.Validation;

/// <summary>
/// Compiles C# snippets in-process with Roslyn, like a <c>dotnet new web</c> project on .NET 10: the Web SDK's implicit
/// usings, nullable enabled, the latest C# version, and every assembly this tool runs with as references (the
/// ASP.NET Core shared framework, EF Core, Mapster, Mediator, FluentValidation). A snippet with top-level statements
/// is compiled as a program, anything else as a library. Only errors fail; warnings are part of what articles teach.
/// </summary>
internal sealed class CSharpChecker : ISnippetChecker
{
    private const string ImplicitUsings = """
        global using System;
        global using System.Collections.Generic;
        global using System.IO;
        global using System.Linq;
        global using System.Net.Http;
        global using System.Net.Http.Json;
        global using System.Threading;
        global using System.Threading.Tasks;
        global using Microsoft.AspNetCore.Builder;
        global using Microsoft.AspNetCore.Hosting;
        global using Microsoft.AspNetCore.Http;
        global using Microsoft.AspNetCore.Routing;
        global using Microsoft.Extensions.Configuration;
        global using Microsoft.Extensions.DependencyInjection;
        global using Microsoft.Extensions.Hosting;
        global using Microsoft.Extensions.Logging;
        """;

    private static readonly CSharpParseOptions Parse = new(LanguageVersion.Latest);

    private static readonly Lazy<MetadataReference[]> References = new(() =>
        [.. ((string)AppContext.GetData("TRUSTED_PLATFORM_ASSEMBLIES")!)
            .Split(Path.PathSeparator)
            .Where(IsManaged)
            .Select(p => (MetadataReference)MetadataReference.CreateFromFile(p))]);

    public string Id => "csharp";

    public bool Handles(string lang) => lang is "csharp" or "cs" or "c#";

    public Task<CheckRun> CheckAsync(IReadOnlyList<Snippet> snippets, CancellationToken ct)
    {
        var errors = new ConcurrentBag<SnippetError>();
        var usings = CSharpSyntaxTree.ParseText(ImplicitUsings, Parse, "GlobalUsings.g.cs", cancellationToken: ct);

        Parallel.ForEach(snippets, new ParallelOptions { CancellationToken = ct }, snippet =>
        {
            var tree = CSharpSyntaxTree.ParseText(snippet.Code, Parse, $"{snippet.Key}.cs", cancellationToken: ct);
            List<SyntaxTree> trees = [usings, tree];
            if (snippet.Stub is not null) trees.Add(CSharpSyntaxTree.ParseText(snippet.Stub, Parse, "Stubs.cs", cancellationToken: ct));

            var isProgram = tree.GetCompilationUnitRoot(ct).Members.OfType<GlobalStatementSyntax>().Any();
            var compilation = CSharpCompilation.Create(
                "Snippet",
                trees,
                References.Value,
                new CSharpCompilationOptions(
                    isProgram ? OutputKind.ConsoleApplication : OutputKind.DynamicallyLinkedLibrary,
                    nullableContextOptions: NullableContextOptions.Enable));

            foreach (var d in compilation.GetDiagnostics(ct).Where(d => d.Severity == DiagnosticSeverity.Error))
            {
                var span = d.Location.GetLineSpan();
                var where = span.Path == "Stubs.cs" ? "stub " : "";
                errors.Add(new SnippetError(snippet, $"{where}line {span.StartLinePosition.Line + 1}: {d.Id} {d.GetMessage()}"));
            }
        });

        return Task.FromResult(new CheckRun([.. errors.OrderBy(e => e.Snippet.Slug).ThenBy(e => e.Snippet.Key)], snippets.Count));
    }

    private static bool IsManaged(string path)
    {
        try
        {
            using var reader = new PEReader(File.OpenRead(path));
            return reader.HasMetadata;
        }
        catch (BadImageFormatException)
        {
            return false;
        }
    }
}
