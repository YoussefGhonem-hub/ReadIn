using System.Text.Json;
using System.Text.RegularExpressions;

namespace ReadIn.Infrastructure.Pdf;

/// <summary>
/// The web reader's BiDi rules (SPEC §14.2, <c>web/src/app/shared/directives/bidi.ts</c> and <c>rdoc.utils.ts</c>), so
/// the PDF resolves block directions and isolates mixed runs exactly like the screen: a block's direction comes from its
/// first strong character (inline code skipped), and runs in the opposite direction become <c>&lt;bdi&gt;</c>.
/// </summary>
internal static partial class BidiText
{
    public const string Rtl = "rtl";
    public const string Ltr = "ltr";

    /// <summary>A run of the text and whether it is isolated (<c>&lt;bdi&gt;</c>).</summary>
    public readonly record struct Run(string Text, bool Isolate);

    public static string LanguageDir(string language) => language == "en" ? Ltr : Rtl;

    /// <summary>Direction from the first strong character (what <c>dir="auto"</c> does), or null when there is none.</summary>
    public static string? DetectDir(string? text)
    {
        if (string.IsNullOrEmpty(text)) return null;
        foreach (var ch in text)
        {
            if (IsRtl(ch)) return Rtl;
            if (IsLtr(ch)) return Ltr;
        }
        return null;
    }

    /// <summary>An explicit <c>rtl</c>/<c>ltr</c> wins; <c>auto</c> (the default) follows the block's text, then the article.</summary>
    public static string ResolveBlockDir(JsonElement block, string fallback)
    {
        var dir = block.TryGetProperty("dir", out var d) && d.ValueKind == JsonValueKind.String ? d.GetString() : null;
        if (dir is Rtl or Ltr) return dir;
        return DetectDir(BlockText(block)) ?? fallback;
    }

    /// <summary>
    /// Splits <paramref name="text"/> into runs; runs in the opposite direction of <paramref name="baseDir"/> are marked
    /// for isolation so punctuation and word order never break (e.g. <c>يعني إيه Dependency Injection؟</c>).
    /// </summary>
    public static IReadOnlyList<Run> Segment(string text, string baseDir)
    {
        var rtl = baseDir == Rtl;
        if (rtl ? !LtrChar().IsMatch(text) : !RtlChar().IsMatch(text)) return [new Run(text, false)];

        var pattern = rtl ? LatinRun() : RtlRun();
        var segments = new List<Run>();
        var cursor = 0;
        var match = pattern.Match(text, 0);
        while (match.Success)
        {
            var run = TrimRun(match.Value);
            var next = match.Index + match.Length;
            if (run.Length > 0)
            {
                if (match.Index > cursor) segments.Add(new Run(text[cursor..match.Index], false));
                segments.Add(new Run(run, true));
                cursor = match.Index + run.Length;
                next = cursor;
            }
            if (next >= text.Length) break;
            match = pattern.Match(text, Math.Max(next, match.Index + 1));
        }
        if (cursor < text.Length) segments.Add(new Run(text[cursor..], false));
        return segments;
    }

    /// <summary>Plain text of inline content; inline code is skipped so a leading <c>AddScoped</c> doesn't flip an Arabic block.</summary>
    public static string InlineText(JsonElement content, bool includeCode = false)
    {
        if (content.ValueKind != JsonValueKind.Array) return string.Empty;
        var text = new System.Text.StringBuilder();
        foreach (var node in content.EnumerateArray())
        {
            var type = node.TryGetProperty("type", out var t) ? t.GetString() : null;
            switch (type)
            {
                case "text":
                    if (!includeCode && HasMark(node, "code")) continue;
                    text.Append(node.GetProperty("text").GetString());
                    break;
                case "term" or "mention":
                    text.Append(node.GetProperty("text").GetString());
                    break;
                default:
                    text.Append('\n');
                    break;
            }
        }
        return text.ToString();
    }

    public static bool HasMark(JsonElement node, string mark)
    {
        if (!node.TryGetProperty("marks", out var marks) || marks.ValueKind != JsonValueKind.Array) return false;
        foreach (var m in marks.EnumerateArray())
            if (m.TryGetProperty("type", out var type) && type.GetString() == mark) return true;
        return false;
    }

    /// <summary>The text a block's direction is resolved from (the web's <c>blockText</c>).</summary>
    private static string BlockText(JsonElement block)
    {
        var type = block.TryGetProperty("type", out var t) ? t.GetString() : null;
        switch (type)
        {
            case "paragraph" or "heading" or "quote" or "callout" or "summary":
                var title = type == "callout" && block.TryGetProperty("title", out var ct) && ct.GetString() is { Length: > 0 } calloutTitle
                    ? calloutTitle + " "
                    : string.Empty;
                return title + InlineText(block.GetProperty("content"));
            case "bulletList" or "orderedList":
                return string.Join(' ', block.GetProperty("items").EnumerateArray().Select(item => InlineText(item)));
            case "steps":
                return string.Join(' ', block.GetProperty("items").EnumerateArray()
                    .Select(item => $"{item.GetProperty("title").GetString()} {InlineText(item.GetProperty("content"))}"));
            case "table":
                return string.Join(' ', block.GetProperty("header").EnumerateArray()
                    .Concat(block.GetProperty("rows").EnumerateArray().SelectMany(row => row.EnumerateArray()))
                    .Select(cell => InlineText(cell)));
            case "image":
                return block.TryGetProperty("caption", out var caption) && caption.GetString() is { } c
                    ? c
                    : block.TryGetProperty("alt", out var alt) ? alt.GetString() ?? string.Empty : string.Empty;
            default:
                return string.Empty;
        }
    }

    /// <summary>
    /// Removes trailing punctuation and unbalanced closing brackets so they stay with the surrounding text, and ends the
    /// run before a bracket it opens but never closes.
    /// </summary>
    private static string TrimRun(string run)
    {
        var result = run;
        while (true)
        {
            var before = result;
            var unclosed = FirstUnclosedBracket(result);
            if (unclosed > 0) result = result[..unclosed];
            result = TrailingPunctuation().Replace(result, string.Empty);
            foreach (var (open, close) in new[] { ('(', ')'), ('[', ']'), ('{', '}'), ('<', '>') })
            {
                while (result.EndsWith(close) && Count(result, close) > Count(result, open)) result = result[..^1];
            }
            if (result == before) return result;
        }
    }

    private static int FirstUnclosedBracket(string text)
    {
        var open = new Stack<int>();
        for (var i = 0; i < text.Length; i++)
        {
            var c = text[i];
            if (c is '(' or '[' or '{') open.Push(i);
            else if (c is ')' or ']' or '}' && open.Count > 0) open.Pop();
        }
        return open.Count > 0 ? open.Min() : -1;
    }

    private static int Count(string text, char ch) => text.Count(c => c == ch);

    private static bool IsRtl(char ch) => ch is >= '֐' and <= 'ࣿ' or >= 'יִ' and <= '﷿' or >= 'ﹰ' and <= '﻿';

    private static bool IsLtr(char ch) =>
        ch is >= 'A' and <= 'Z' or >= 'a' and <= 'z' or >= 'À' and <= 'ʸ' or >= 'Ͱ' and <= 'Ͽ' or >= 'Ѐ' and <= 'ӿ';

    [GeneratedRegex(@"[֐-ࣿיִ-﷿ﹰ-﻿]")]
    private static partial Regex RtlChar();

    [GeneratedRegex(@"[A-Za-zÀ-ʸͰ-ϿЀ-ӿ]")]
    private static partial Regex LtrChar();

    // JS \w is ASCII only; spelled out here because .NET's \w also matches Arabic letters.
    [GeneratedRegex(@"[.@#]?[A-Za-zÀ-ɏ][A-Za-z0-9_À-ɏ.+#\-/:@<>(),'&=*\[\]{}?%~]*(?:[ \t]+[A-Za-z0-9_À-ɏ.+#\-/:@<>(),'&=*\[\]{}?%~]+)*")]
    private static partial Regex LatinRun();

    [GeneratedRegex(@"[֐-ࣿיִ-﷿ﹰ-﻿][֐-ࣿיִ-﷿ﹰ-﻿0-9\s،؛؟]*")]
    private static partial Regex RtlRun();

    [GeneratedRegex(@"[\s.,:;!?،؛؟'""-]+\z")]
    private static partial Regex TrailingPunctuation();
}
