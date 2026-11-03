using System.Diagnostics;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using ReadIn.Infrastructure.Content;
using YamlDotNet.RepresentationModel;

namespace ReadIn.ContentStudio.Validation;

/// <summary>One code block or code tab. <see cref="Key"/> is the block id, plus <c>/n</c> for a tab (as in meta.json).</summary>
public sealed record Snippet(string Slug, string Key, string Lang, string Code, bool Compile, string? Stub);

public sealed record SnippetError(Snippet Snippet, string Message);

/// <summary>Result of one checker run; <see cref="Toolchain"/> is set when the checker could not run at all.</summary>
public sealed record CheckRun(IReadOnlyList<SnippetError> Errors, int Checked, string? Toolchain = null);

public interface ISnippetChecker
{
    /// <summary>Checker id, also the key of <c>code.stubs</c> in meta.json (csharp, typescript, dart, python…).</summary>
    string Id { get; }

    bool Handles(string lang);

    Task<CheckRun> CheckAsync(IReadOnlyList<Snippet> snippets, CancellationToken ct);
}

/// <summary>
/// Compile checks (SPEC §19.3): every snippet compiles with the real toolchain of its language. Fragments are marked
/// <c>"compile": false</c> with a reason in meta.json <c>code.skip</c>; anything else that can't be checked is reported.
/// </summary>
public static class CodeChecks
{
    public static List<ISnippetChecker> Checkers(string toolsRoot) =>
    [
        new CSharpChecker(),
        new TypeScriptChecker(Path.Combine(toolsRoot, "content-check")),
        new DartChecker(Path.Combine(toolsRoot, "content-check", "dart")),
        new PythonChecker(Path.Combine(toolsRoot, "content-check", "python")),
        new JavaScriptChecker(),
        new BashChecker(),
        new DataChecker(),
    ];

    public static IEnumerable<Snippet> Extract(string slug, JsonElement document, CodeMeta? code, IReadOnlyList<ISnippetChecker> checkers)
    {
        foreach (var block in RDocWalker.Blocks(document))
        {
            if (block.Type == "code")
                yield return Make(block.Id, block.Element);
            else if (block.Type == "codeTabs")
            {
                var i = 0;
                foreach (var tab in block.Element.GetProperty("tabs").EnumerateArray()) yield return Make($"{block.Id}/{i++}", tab);
            }
        }

        Snippet Make(string key, JsonElement e)
        {
            var lang = e.GetProperty("lang").GetString()!;
            var compile = !e.TryGetProperty("compile", out var c) || c.GetBoolean();
            var checker = checkers.FirstOrDefault(k => k.Handles(lang));
            var stub = checker is null ? null : code?.Stubs.GetValueOrDefault(checker.Id);
            return new Snippet(slug, key, lang, e.GetProperty("code").GetString()!, compile, stub);
        }
    }
}

/// <summary>Runs external tools; on Windows resolves .cmd/.bat shims (npm, flutter, dart) through cmd.exe.</summary>
internal static class Tool
{
    public static string? Find(string name)
    {
        var extensions = OperatingSystem.IsWindows() ? new[] { ".exe", ".cmd", ".bat" } : [""];
        foreach (var dir in (Environment.GetEnvironmentVariable("PATH") ?? "").Split(Path.PathSeparator))
        {
            foreach (var ext in extensions)
            {
                var candidate = Path.Combine(dir.Trim('"'), name + ext);
                // System32\bash.exe is the WSL launcher, not a shell we can rely on.
                if (File.Exists(candidate) && !candidate.Contains(@"\System32\", StringComparison.OrdinalIgnoreCase)) return candidate;
            }
        }
        return null;
    }

    public static async Task<(int ExitCode, string Output)> RunAsync(string exe, IEnumerable<string> args, string cwd, CancellationToken ct, TimeSpan? timeout = null)
    {
        var info = new ProcessStartInfo { WorkingDirectory = cwd, RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false };
        if (OperatingSystem.IsWindows() &&
            (exe.EndsWith(".cmd", StringComparison.OrdinalIgnoreCase) || exe.EndsWith(".bat", StringComparison.OrdinalIgnoreCase)))
        {
            info.FileName = "cmd.exe";
            info.ArgumentList.Add("/d");
            info.ArgumentList.Add("/c");
            info.ArgumentList.Add(exe);
        }
        else info.FileName = exe;
        foreach (var arg in args) info.ArgumentList.Add(arg);
        info.Environment["NO_COLOR"] = "1";

        using var process = Process.Start(info)!;
        var stdout = process.StandardOutput.ReadToEndAsync(ct);
        var stderr = process.StandardError.ReadToEndAsync(ct);
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(ct);
        cts.CancelAfter(timeout ?? TimeSpan.FromMinutes(10));
        try
        {
            await process.WaitForExitAsync(cts.Token);
        }
        catch (OperationCanceledException)
        {
            process.Kill(entireProcessTree: true);
            return (-1, $"timed out after {(timeout ?? TimeSpan.FromMinutes(10)).TotalSeconds:0} s");
        }
        return (process.ExitCode, await stdout + await stderr);
    }

    /// <summary>One-time setup (npm ci, flutter pub get) guarded across concurrent validator processes.</summary>
    public static async Task<string?> PrepareOnceAsync(string marker, Func<Task<string?>> prepare)
    {
        if (Directory.Exists(marker) || File.Exists(marker)) return null;
        using var mutex = new Mutex(false, @"Global\ReadInContentCheckPrepare");
        mutex.WaitOne();
        try
        {
            return Directory.Exists(marker) || File.Exists(marker) ? null : await prepare();
        }
        finally
        {
            mutex.ReleaseMutex();
        }
    }

    public static string NewRunDir(string parent)
    {
        var dir = Path.Combine(parent, $"run-{Environment.ProcessId}-{Guid.NewGuid():N}"[..20]);
        Directory.CreateDirectory(dir);
        return dir;
    }

    public static void TryDelete(string dir)
    {
        try { Directory.Delete(dir, recursive: true); } catch (IOException) { } catch (UnauthorizedAccessException) { }
    }

    /// <summary>Snippet text with its stub prepended; returns how many lines the stub adds (to fix reported line numbers).</summary>
    public static (string Text, int Offset) WithStub(Snippet s) =>
        s.Stub is null ? (s.Code, 0) : ($"{s.Stub.TrimEnd()}\n{s.Code}", s.Stub.TrimEnd().Split('\n').Length);
}

internal sealed partial class TypeScriptChecker(string root) : ISnippetChecker
{
    public string Id => "typescript";

    public bool Handles(string lang) => lang is "typescript" or "ts" or "tsx";

    public async Task<CheckRun> CheckAsync(IReadOnlyList<Snippet> snippets, CancellationToken ct)
    {
        if (snippets.Count == 0) return new([], 0);
        if (Tool.Find("node") is not { } node) return new([], 0, "node is not on PATH (TypeScript checks need Node 24).");
        var setup = await Tool.PrepareOnceAsync(Path.Combine(root, "node_modules", "typescript"), async () =>
        {
            if (Tool.Find("npm") is not { } npm) return "npm is not on PATH.";
            var (code, output) = await Tool.RunAsync(npm, ["ci", "--no-audit", "--no-fund"], root, ct);
            return code == 0 ? null : $"npm ci in tools/content-check failed: {output}";
        });
        if (setup is not null) return new([], 0, setup);

        var run = Tool.NewRunDir(Path.Combine(root, "runs"));
        try
        {
            var files = new Dictionary<string, (Snippet Snippet, int Offset)>(StringComparer.OrdinalIgnoreCase);
            for (var i = 0; i < snippets.Count; i++)
            {
                var name = $"s{i}.{(snippets[i].Lang == "tsx" ? "tsx" : "ts")}";
                var (text, offset) = Tool.WithStub(snippets[i]);
                await File.WriteAllTextAsync(Path.Combine(run, name), text, ct);
                files[name] = (snippets[i], offset);
            }
            await File.WriteAllTextAsync(Path.Combine(run, "tsconfig.json"),
                """{ "extends": "../../tsconfig.base.json", "include": ["*.ts", "*.tsx"] }""", ct);

            var tsc = Path.Combine(root, "node_modules", "typescript", "bin", "tsc");
            var (_, output) = await Tool.RunAsync(node, [tsc, "-p", Path.Combine(run, "tsconfig.json"), "--pretty", "false"], run, ct);

            var errors = new List<SnippetError>();
            SnippetError? last = null;
            foreach (var line in output.Split('\n').Select(l => l.TrimEnd('\r')))
            {
                var m = TscLine().Match(line);
                if (m.Success && files.TryGetValue(Path.GetFileName(m.Groups["file"].Value), out var f))
                {
                    var at = int.Parse(m.Groups["line"].Value) - f.Offset;
                    last = new SnippetError(f.Snippet, $"line {at}: {m.Groups["code"].Value} {m.Groups["msg"].Value}");
                    errors.Add(last);
                }
                else if (last is not null && line.StartsWith("  ", StringComparison.Ordinal))
                {
                    errors[^1] = last = last with { Message = $"{last.Message} {line.Trim()}" };
                }
                else if (line.Contains("error TS", StringComparison.Ordinal))
                {
                    return new(errors, snippets.Count, $"tsc failed outside the snippets: {line}");
                }
            }
            return new(errors, snippets.Count);
        }
        finally
        {
            Tool.TryDelete(run);
        }
    }

    [GeneratedRegex(@"^(?<file>[^(]+)\((?<line>\d+),(?<col>\d+)\): error (?<code>TS\d+): (?<msg>.*)$")]
    private static partial Regex TscLine();
}

internal sealed class DartChecker(string root) : ISnippetChecker
{
    public string Id => "dart";

    public bool Handles(string lang) => lang == "dart";

    public async Task<CheckRun> CheckAsync(IReadOnlyList<Snippet> snippets, CancellationToken ct)
    {
        if (snippets.Count == 0) return new([], 0);
        if (Tool.Find("dart") is not { } dart) return new([], 0, "dart is not on PATH (Dart checks need the Flutter SDK).");
        var setup = await Tool.PrepareOnceAsync(Path.Combine(root, ".dart_tool", "package_config.json"), async () =>
        {
            if (Tool.Find("flutter") is not { } flutter) return "flutter is not on PATH.";
            var (code, output) = await Tool.RunAsync(flutter, ["pub", "get"], root, ct);
            return code == 0 ? null : $"flutter pub get in tools/content-check/dart failed: {output}";
        });
        if (setup is not null) return new([], 0, setup);

        var run = Tool.NewRunDir(Path.Combine(root, "lib"));
        try
        {
            var files = new Dictionary<string, (Snippet, int)>(StringComparer.OrdinalIgnoreCase);
            for (var i = 0; i < snippets.Count; i++)
            {
                var (text, offset) = Tool.WithStub(snippets[i]);
                await File.WriteAllTextAsync(Path.Combine(run, $"s{i}.dart"), text, ct);
                files[$"s{i}.dart"] = (snippets[i], offset);
            }

            var (_, output) = await Tool.RunAsync(dart, ["analyze", "--format=machine", run], root, ct);
            var errors = new List<SnippetError>();
            foreach (var line in output.Split('\n'))
            {
                // SEVERITY|TYPE|CODE|FILE|LINE|COLUMN|LENGTH|MESSAGE
                var parts = line.TrimEnd('\r').Split('|');
                if (parts.Length < 8 || parts[0] != "ERROR") continue;
                if (!files.TryGetValue(Path.GetFileName(parts[3]), out var f)) continue;
                errors.Add(new SnippetError(f.Item1, $"line {int.Parse(parts[4]) - f.Item2}: {parts[2]} {string.Join('|', parts[7..])}"));
            }
            return new(errors, snippets.Count);
        }
        finally
        {
            Tool.TryDelete(run);
        }
    }
}

/// <summary>
/// Python snippets are byte-compiled and then RUN (60 s each) in a uv-managed environment with the pinned
/// scikit-learn/numpy/pandas from tools/content-check/python/requirements.txt, so API misuse fails the check too.
/// </summary>
internal sealed class PythonChecker(string root) : ISnippetChecker
{
    public string Id => "python";

    public bool Handles(string lang) => lang is "python" or "py";

    public async Task<CheckRun> CheckAsync(IReadOnlyList<Snippet> snippets, CancellationToken ct)
    {
        if (snippets.Count == 0) return new([], 0);
        if (Tool.Find("uv") is not { } uv) return new([], 0, "uv is not on PATH (Python checks run in a uv-managed environment).");

        var run = Tool.NewRunDir(Path.Combine(root, "runs"));
        try
        {
            var files = new Dictionary<string, (Snippet, int)>();
            for (var i = 0; i < snippets.Count; i++)
            {
                var (text, offset) = Tool.WithStub(snippets[i]);
                await File.WriteAllTextAsync(Path.Combine(run, $"s{i}.py"), text, ct);
                files[$"s{i}.py"] = (snippets[i], offset);
            }

            var (code, output) = await Tool.RunAsync(uv,
                ["run", "--no-project", "--quiet", "--python", "3.13", "--with-requirements", Path.Combine(root, "requirements.txt"),
                 "python", "-I", Path.Combine(root, "check_snippets.py"), run], root, ct, TimeSpan.FromMinutes(30));

            var errors = new List<SnippetError>();
            var seen = 0;
            foreach (var line in output.Split('\n').Where(l => l.StartsWith('{')))
            {
                using var json = JsonDocument.Parse(line);
                seen++;
                var file = json.RootElement.GetProperty("file").GetString()!;
                if (json.RootElement.GetProperty("ok").GetBoolean() || !files.TryGetValue(file, out var f)) continue;
                errors.Add(new SnippetError(f.Item1, json.RootElement.GetProperty("error").GetString()!));
            }
            return seen == snippets.Count ? new(errors, snippets.Count) : new(errors, seen, $"uv/python did not check every snippet (exit {code}): {Tail(output)}");
        }
        finally
        {
            Tool.TryDelete(run);
        }
    }

    private static string Tail(string s) => s.Length > 600 ? s[^600..] : s;
}

internal sealed class JavaScriptChecker : ISnippetChecker
{
    public string Id => "javascript";

    public bool Handles(string lang) => lang is "javascript" or "js" or "mjs";

    public async Task<CheckRun> CheckAsync(IReadOnlyList<Snippet> snippets, CancellationToken ct)
    {
        if (snippets.Count == 0) return new([], 0);
        if (Tool.Find("node") is not { } node) return new([], 0, "node is not on PATH.");
        var dir = Tool.NewRunDir(Path.GetTempPath());
        try
        {
            var errors = new List<SnippetError>();
            foreach (var s in snippets)
            {
                var module = s.Code.Contains("import ", StringComparison.Ordinal) || s.Code.Contains("export ", StringComparison.Ordinal);
                var file = Path.Combine(dir, module ? "s.mjs" : "s.js");
                await File.WriteAllTextAsync(file, Tool.WithStub(s).Text, ct);
                var (code, output) = await Tool.RunAsync(node, ["--check", file], dir, ct);
                if (code != 0) errors.Add(new SnippetError(s, FirstLines(output)));
            }
            return new(errors, snippets.Count);
        }
        finally
        {
            Tool.TryDelete(dir);
        }
    }

    internal static string FirstLines(string s) => string.Join(" ", s.Split('\n').Select(l => l.Trim()).Where(l => l.Length > 0).Take(4));
}

internal sealed class BashChecker : ISnippetChecker
{
    public string Id => "bash";

    public bool Handles(string lang) => lang is "bash" or "sh" or "shell";

    public async Task<CheckRun> CheckAsync(IReadOnlyList<Snippet> snippets, CancellationToken ct)
    {
        if (snippets.Count == 0) return new([], 0);
        if (Tool.Find("bash") is not { } bash) return new([], 0, "bash is not on PATH (Git Bash on Windows).");
        var dir = Tool.NewRunDir(Path.GetTempPath());
        try
        {
            var errors = new List<SnippetError>();
            foreach (var s in snippets)
            {
                var file = Path.Combine(dir, "s.sh");
                await File.WriteAllTextAsync(file, s.Code.Replace("\r\n", "\n"), ct);
                var (code, output) = await Tool.RunAsync(bash, ["-n", "s.sh"], dir, ct);
                if (code != 0) errors.Add(new SnippetError(s, JavaScriptChecker.FirstLines(output)));
            }
            return new(errors, snippets.Count);
        }
        finally
        {
            Tool.TryDelete(dir);
        }
    }
}

/// <summary>JSON (comments and trailing commas allowed, as in appsettings.json) and YAML must parse.</summary>
internal sealed class DataChecker : ISnippetChecker
{
    public string Id => "data";

    public bool Handles(string lang) => lang is "json" or "jsonc" or "yaml" or "yml";

    public Task<CheckRun> CheckAsync(IReadOnlyList<Snippet> snippets, CancellationToken ct)
    {
        var errors = new List<SnippetError>();
        foreach (var s in snippets)
        {
            try
            {
                if (s.Lang.StartsWith("json", StringComparison.Ordinal))
                    JsonDocument.Parse(s.Code, new JsonDocumentOptions { CommentHandling = JsonCommentHandling.Skip, AllowTrailingCommas = true }).Dispose();
                else
                    new YamlStream().Load(new StringReader(s.Code));
            }
            catch (Exception ex) when (ex is JsonException or YamlDotNet.Core.YamlException)
            {
                errors.Add(new SnippetError(s, ex.Message));
            }
        }
        return Task.FromResult(new CheckRun(errors, snippets.Count));
    }
}
