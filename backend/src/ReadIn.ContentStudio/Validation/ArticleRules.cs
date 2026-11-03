using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using ReadIn.Application.Common.Content;
using ReadIn.Infrastructure.Content;

namespace ReadIn.ContentStudio.Validation;

/// <summary>One article as the validator sees it: meta, its plan entry and both processed RDoc versions.</summary>
public sealed record ArticleUnderTest(
    string Folder,
    ArticleMeta Meta,
    PlannedArticleEntry? Plan,
    IReadOnlyDictionary<string, JsonElement> Documents,
    IReadOnlyDictionary<string, ProcessedRDoc> Processed);

/// <summary>
/// The editorial rules for seeded articles (SPEC §19.3, content/AUTHORING.md): required structure, length and
/// reading time, en/ar-EG parity, text lint (emoji, raw HTML, Arabic punctuation and digits, BiDi), meta vs plan, cover.
/// </summary>
public static partial class ArticleRules
{
    public const int MinWords = 900;
    public const int MaxWords = 1800;
    public const int MinMinutes = 5;
    public const int MaxMinutes = 9;
    public const int MinSources = 2;
    public const int MaxSources = 5;
    public const int MaxCodeLineLength = 100;
    public const int CoverWidth = 1200;
    public const int CoverHeight = 630;

    private static readonly HashSet<string> Levels = ["beginner", "intermediate", "advanced"];
    private static readonly HashSet<string> TabLabelEmoji = ["❌", "✅"];

    public static IEnumerable<(Severity, string Check, string Message)> Check(ArticleUnderTest a, IReadOnlySet<string> glossary)
    {
        foreach (var f in CheckMeta(a)) yield return f;
        foreach (var f in CheckCover(a.Folder)) yield return f;

        foreach (var (language, document) in a.Documents)
        {
            var blocks = RDocWalker.Blocks(document);
            foreach (var (s, c, m) in CheckStructure(blocks)) yield return (s, c, $"{language}: {m}");
            foreach (var (s, c, m) in CheckLength(a.Processed[language])) yield return (s, c, $"{language}: {m}");
            foreach (var (s, c, m) in CheckText(blocks, language, glossary)) yield return (s, c, $"{language}: {m}");
            foreach (var (s, c, m) in CheckCode(blocks)) yield return (s, c, $"{language}: {m}");
        }

        if (a.Documents.TryGetValue("en", out var en) && a.Documents.TryGetValue("ar-EG", out var ar))
            foreach (var f in CheckParity(RDocWalker.Blocks(en), RDocWalker.Blocks(ar))) yield return f;
    }

    // ── Meta and plan ───────────────────────────────────────────

    private static IEnumerable<(Severity, string, string)> CheckMeta(ArticleUnderTest a)
    {
        var m = a.Meta;
        var plan = a.Plan;
        if (plan is null)
        {
            yield return (Severity.Error, "plan", "Slug is not in the plan (content/taxonomy.yaml plannedArticles).");
        }
        else
        {
            if (m.Field != plan.Field || m.Topic != plan.Topic)
                yield return (Severity.Error, "plan", $"field/topic {m.Field}/{m.Topic} differ from the plan ({plan.Field}/{plan.Topic}).");
            if (m.Level != plan.Level) yield return (Severity.Error, "plan", $"level '{m.Level}' differs from the plan ('{plan.Level}').");
            if (m.VersionBadge != plan.VersionBadge)
                yield return (Severity.Error, "plan", $"versionBadge '{m.VersionBadge}' differs from the plan ('{plan.VersionBadge}').");
            if (m.LearningPath?.Slug != plan.LearningPath || m.LearningPath?.Order != plan.Order)
                yield return (Severity.Error, "plan", $"learningPath must be {{ slug: {plan.LearningPath}, order: {plan.Order} }} as in the plan.");
            if (m.Translations.GetValueOrDefault("en")?.Title != plan.TitleEn)
                yield return (Severity.Error, "plan", "en title differs from the plan's titleEn (change both together).");
            if (m.Translations.GetValueOrDefault("ar-EG")?.Title != plan.TitleAr)
                yield return (Severity.Error, "plan", "ar-EG title differs from the plan's titleAr (change both together).");
        }

        var expectedFolder = Path.Combine(m.Field, m.Topic ?? "", m.Slug);
        if (!a.Folder.Replace('\\', '/').EndsWith(expectedFolder.Replace('\\', '/'), StringComparison.Ordinal))
            yield return (Severity.Error, "meta", $"Folder must be content/articles/{expectedFolder.Replace('\\', '/')}/.");

        if (m.Status != "published") yield return (Severity.Error, "meta", "status must be \"published\".");
        if (m.ReviewStatus != "pending") yield return (Severity.Error, "trust", "reviewStatus must be \"pending\" (no human review yet).");
        if (m.Reviewer is not null || m.ReviewedAt is not null)
            yield return (Severity.Error, "trust", "Seeded articles must not name a reviewer: a \"Reviewed by\" badge is never faked.");
        if (!m.IsAiAssisted) yield return (Severity.Error, "trust", "isAiAssisted must be true.");
        if (m.LastReviewedAt is null) yield return (Severity.Error, "trust", "lastReviewedAt (generation date) is required.");
        if (!Levels.Contains(m.Level)) yield return (Severity.Error, "meta", $"level must be beginner, intermediate or advanced.");
        if (m.SourceLanguage != "en") yield return (Severity.Error, "meta", "sourceLanguage must be \"en\" (English is the source of truth).");

        foreach (var language in new[] { "en", "ar-EG" })
        {
            var t = m.Translations.GetValueOrDefault(language);
            if (string.IsNullOrWhiteSpace(t?.Title)) yield return (Severity.Error, "meta", $"No {language} title.");
            else if (t.Title.Length > 150) yield return (Severity.Error, "meta", $"{language} title is longer than 150 characters.");
            if (string.IsNullOrWhiteSpace(t?.Subtitle)) yield return (Severity.Warning, "meta", $"No {language} subtitle.");
        }

        if (m.Tags.Count is < 2 or > 5) yield return (Severity.Error, "meta", "Use 2–5 tags.");

        if (m.Sources.Count is < MinSources or > MaxSources)
            yield return (Severity.Error, "sources", $"{m.Sources.Count} sources (need {MinSources}–{MaxSources}).");
        foreach (var source in m.Sources)
        {
            if (string.IsNullOrWhiteSpace(source.Title)) yield return (Severity.Error, "sources", $"Source without a title: {source.Url}");
            if (!Uri.TryCreate(source.Url, UriKind.Absolute, out var uri) || uri.Scheme != Uri.UriSchemeHttps)
                yield return (Severity.Error, "sources", $"Source URL must be https: {source.Url}");
        }
        foreach (var dup in m.Sources.GroupBy(s => s.Url.TrimEnd('/')).Where(g => g.Count() > 1))
            yield return (Severity.Error, "sources", $"Duplicate source: {dup.Key}");
    }

    private static IEnumerable<(Severity, string, string)> CheckCover(string folder)
    {
        var path = Path.Combine(folder, "cover.webp");
        if (!File.Exists(path))
        {
            yield return (Severity.Error, "cover", "cover.webp is missing (render it with tools/content-covers).");
            yield break;
        }
        var size = WebpSize(File.ReadAllBytes(path));
        if (size is null) yield return (Severity.Error, "cover", "cover.webp is not a WebP image.");
        else if (size != (CoverWidth, CoverHeight))
            yield return (Severity.Error, "cover", $"cover.webp is {size.Value.Width}×{size.Value.Height}; it must be {CoverWidth}×{CoverHeight}.");
    }

    /// <summary>Width and height from a WebP header (VP8, VP8L or VP8X), or null when it isn't WebP.</summary>
    public static (int Width, int Height)? WebpSize(byte[] b)
    {
        if (b.Length < 30 || b[0] != 'R' || b[1] != 'I' || b[2] != 'F' || b[3] != 'F' || b[8] != 'W' || b[9] != 'E' || b[10] != 'B' || b[11] != 'P')
            return null;
        var chunk = System.Text.Encoding.ASCII.GetString(b, 12, 4);
        return chunk switch
        {
            "VP8X" => (1 + (b[24] | b[25] << 8 | b[26] << 16), 1 + (b[27] | b[28] << 8 | b[29] << 16)),
            "VP8L" => (1 + ((b[21] | b[22] << 8) & 0x3FFF), 1 + ((b[22] >> 6 | b[23] << 2 | b[24] << 10) & 0x3FFF)),
            "VP8 " => ((b[26] | b[27] << 8) & 0x3FFF, (b[28] | b[29] << 8) & 0x3FFF),
            _ => null,
        };
    }

    // ── Structure (Part 4 of the content brief) ─────────────────

    private static IEnumerable<(Severity, string, string)> CheckStructure(List<BlockView> blocks)
    {
        if (blocks.Count == 0 || blocks[0].Type != "summary")
            yield return (Severity.Error, "structure", "The first block must be the TL;DR summary.");
        if (blocks.Count < 2 || blocks[1].Type != "paragraph")
            yield return (Severity.Error, "structure", "The summary must be followed by the hook paragraph.");

        var h2 = blocks.Where(b => b.Type == "heading" && b.Element.GetProperty("level").GetInt32() == 2).ToList();
        if (h2.Count < 3) yield return (Severity.Error, "structure", $"{h2.Count} H2 sections; need the misconception, what actually happens and the takeaways (≥ 3).");

        bool Has(string variant) => blocks.Any(b => b.Type == "callout" && b.Element.GetProperty("variant").GetString() == variant);
        if (!Has("tip")) yield return (Severity.Error, "structure", "Needs at least one tip callout.");
        if (!Has("warning") && !Has("danger")) yield return (Severity.Error, "structure", "Needs at least one warning (or danger) callout.");
        if (!blocks.Any(b => b.Type == "table")) yield return (Severity.Error, "structure", "Needs a comparison table (e.g. myth vs reality).");
        if (!blocks.Any(b => b.Type is "code" or "codeTabs" or "steps"))
            yield return (Severity.Error, "structure", "Needs a code example (code/codeTabs) or, for non-code topics, a steps block.");

        var last = blocks.LastOrDefault();
        if (last is null || last.Type != "bulletList" || blocks.Count < 2 || blocks[^2].Type != "heading" ||
            blocks[^2].Element.GetProperty("level").GetInt32() != 2)
        {
            yield return (Severity.Error, "structure", "The article must end with an H2 (key takeaways) followed by one bullet list.");
        }
        else
        {
            var items = last.Element.GetProperty("items").GetArrayLength();
            if (items is < 3 or > 5) yield return (Severity.Error, "structure", $"Key takeaways have {items} bullets (need 3–5).");
        }

        foreach (var dup in h2.GroupBy(h => RDocWalker.DirectionText(h).Trim()).Where(g => g.Count() > 1))
            yield return (Severity.Error, "structure", $"Duplicate H2 \"{dup.Key}\".");
    }

    private static IEnumerable<(Severity, string, string)> CheckLength(ProcessedRDoc processed)
    {
        var c = processed.Content;
        if (c.WordCount is < MinWords or > MaxWords)
            yield return (Severity.Error, "length", $"{c.WordCount} words (need {MinWords}–{MaxWords}).");
        if (c.ReadingTimeMinutes is < MinMinutes or > MaxMinutes)
            yield return (Severity.Error, "length", $"reading time {c.ReadingTimeMinutes} min (need {MinMinutes}–{MaxMinutes}; code lines count 4 s each).");
    }

    // ── Text lint ───────────────────────────────────────────────

    private static IEnumerable<(Severity, string, string)> CheckText(List<BlockView> blocks, string language, IReadOnlySet<string> glossary)
    {
        var arabic = language == "ar-EG";
        foreach (var block in blocks)
        {
            foreach (var run in RDocWalker.TextRuns(block))
            {
                var text = run.Text;
                if (FirstEmoji(text) is { } emoji)
                    yield return (Severity.Error, "text", $"Emoji '{emoji}' in {block.Id}: callout icons come from the renderer, body text has none.");
                if (RawHtml().Match(text) is { Success: true } html)
                    yield return (Severity.Error, "text", $"Raw HTML '{html.Value}' in {block.Id}: write tags as inline code.");
                if (arabic && ArabicIndicDigit().IsMatch(text))
                    yield return (Severity.Error, "text", $"Arabic-Indic digits in {block.Id}: use Western digits (0-9).");
                if (arabic && LatinPunctuationAfterArabic().Match(text) is { Success: true } p)
                    yield return (Severity.Error, "text", $"Latin punctuation in Arabic text in {block.Id} (\"{p.Value}\"): use ، ؛ ؟");
                if (!arabic && ArabicLetter().IsMatch(text))
                    yield return (Severity.Error, "text", $"Arabic text in the English version ({block.Id}).");
            }

            foreach (var node in RDocWalker.InlineNodes(block))
            {
                if (node.GetProperty("type").GetString() != "term") continue;
                var termId = node.GetProperty("termId").GetString()!;
                if (!glossary.Contains(termId))
                    yield return (Severity.Error, "glossary", $"Term '{termId}' in {block.Id} is not in content/glossary/*.yaml.");
            }

            if (arabic && block.Type is not ("code" or "codeTabs" or "divider" or "image") && block.Dir != "rtl")
            {
                // dir=auto resolves from the first strong character; an English start would flip the block to LTR.
                var first = RDocWalker.DirectionText(block).FirstOrDefault(ch => char.IsLetter(ch));
                if (first != default && !ArabicLetter().IsMatch(first.ToString()))
                    yield return (Severity.Error, "bidi", $"{block.Id} starts with an English word and has no dir \"rtl\" (it would render LTR).");
            }

            if (block.Type == "image" && string.IsNullOrWhiteSpace(block.Element.GetProperty("alt").GetString()))
                yield return (Severity.Error, "text", $"Image {block.Id} has no alt text.");
        }
    }

    private static string? FirstEmoji(string text)
    {
        for (var i = 0; i < text.Length; i++)
        {
            var cp = char.ConvertToUtf32(text, i);
            if (char.IsSurrogatePair(text, i)) i++;
            if (cp is >= 0x1F000 and <= 0x1FAFF or >= 0x2600 and <= 0x27BF or 0xFE0F or >= 0x2B50 and <= 0x2B55 or >= 0x231A and <= 0x23FF)
                return char.ConvertFromUtf32(cp);
        }
        return null;
    }

    // ── Code blocks ─────────────────────────────────────────────

    private static IEnumerable<(Severity, string, string)> CheckCode(List<BlockView> blocks)
    {
        foreach (var block in blocks)
        {
            if (block.Type == "codeTabs")
            {
                foreach (var tab in block.Element.GetProperty("tabs").EnumerateArray())
                {
                    var label = tab.GetProperty("label").GetString()!;
                    var stripped = TabLabelEmoji.Aggregate(label, (s, e) => s.Replace(e, "", StringComparison.Ordinal));
                    if (FirstEmoji(stripped) is { } emoji) yield return (Severity.Error, "text", $"Emoji '{emoji}' in tab label of {block.Id} (only ❌ / ✅ are allowed).");
                    foreach (var f in CheckCodeText(block.Id, tab.GetProperty("code").GetString()!)) yield return f;
                }
            }
            else if (block.Type == "code")
            {
                foreach (var f in CheckCodeText(block.Id, block.Element.GetProperty("code").GetString()!)) yield return f;
            }
        }
    }

    private static IEnumerable<(Severity, string, string)> CheckCodeText(string blockId, string code)
    {
        var lines = code.Split('\n');
        if (code.Trim().Length == 0) yield return (Severity.Error, "code", $"{blockId} is empty.");
        if (lines.Length > 40) yield return (Severity.Error, "code", $"{blockId} has {lines.Length} lines (keep snippets ≤ 25, never > 40).");
        else if (lines.Length > 25) yield return (Severity.Warning, "code", $"{blockId} has {lines.Length} lines (ideally ≤ 25).");
        var longest = lines.Select((l, i) => (Length: l.Length, Line: i + 1)).MaxBy(l => l.Length);
        if (longest.Length > MaxCodeLineLength)
            yield return (Severity.Error, "code", $"{blockId} line {longest.Line} is {longest.Length} characters (wrap at {MaxCodeLineLength}).");
        if (code.Contains('\t')) yield return (Severity.Error, "code", $"{blockId} uses tabs; indent with spaces.");
    }

    // ── Parity ──────────────────────────────────────────────────

    private static IEnumerable<(Severity, string, string)> CheckParity(List<BlockView> en, List<BlockView> ar)
    {
        if (en.Count != ar.Count)
        {
            yield return (Severity.Error, "parity", $"Block count differs: en={en.Count}, ar-EG={ar.Count}.");
            yield break;
        }

        for (var i = 0; i < en.Count; i++)
        {
            var (e, a) = (en[i], ar[i]);
            if (e.Type != a.Type || e.Id != a.Id)
            {
                yield return (Severity.Error, "parity", $"Block #{i + 1}: en has {e.Type}#{e.Id}, ar-EG has {a.Type}#{a.Id}.");
                yield break;
            }

            var mismatch = e.Type switch
            {
                "heading" => Same(e, a, "level") ? null : "heading levels differ",
                "callout" => Same(e, a, "variant") ? null : "callout variants differ",
                "code" => Same(e, a, "lang") && Same(e, a, "code") && Same(e, a, "filename") ? null : "code must be identical (lang, filename, code)",
                "codeTabs" => TabsMatch(e, a) ? null : "code tabs must have the same count, lang, filename and code",
                "bulletList" or "orderedList" or "steps" => Count(e, "items") == Count(a, "items") ? null : "item counts differ",
                "table" => TableShape(e) == TableShape(a) ? null : $"table shape differs (en {TableShape(e)}, ar-EG {TableShape(a)})",
                "image" => Same(e, a, "src") ? null : "image sources differ",
                _ => null,
            };
            if (mismatch is not null) yield return (Severity.Error, "parity", $"{e.Id}: {mismatch}.");
        }
    }

    private static bool Same(BlockView a, BlockView b, string key)
    {
        var hasA = a.Element.TryGetProperty(key, out var x);
        var hasB = b.Element.TryGetProperty(key, out var y);
        return hasA == hasB && (!hasA || x.GetRawText() == y.GetRawText());
    }

    private static int Count(BlockView b, string key) => b.Element.GetProperty(key).GetArrayLength();

    private static string TableShape(BlockView b)
    {
        var rows = b.Element.GetProperty("rows").EnumerateArray().Select(r => r.GetArrayLength().ToString(CultureInfo.InvariantCulture));
        return $"{b.Element.GetProperty("header").GetArrayLength()}×[{string.Join(',', rows)}]";
    }

    private static bool TabsMatch(BlockView a, BlockView b)
    {
        var x = a.Element.GetProperty("tabs").EnumerateArray().ToList();
        var y = b.Element.GetProperty("tabs").EnumerateArray().ToList();
        return x.Count == y.Count && x.Zip(y).All(p =>
            p.First.GetProperty("lang").GetString() == p.Second.GetProperty("lang").GetString() &&
            p.First.GetProperty("code").GetString() == p.Second.GetProperty("code").GetString() &&
            (p.First.TryGetProperty("filename", out var f1) ? f1.GetString() : null) ==
            (p.Second.TryGetProperty("filename", out var f2) ? f2.GetString() : null));
    }

    [GeneratedRegex(@"</?[A-Za-z][A-Za-z0-9-]*(\s[^<>]*)?/?>")]
    private static partial Regex RawHtml();

    [GeneratedRegex(@"[٠-٩۰-۹]")]
    private static partial Regex ArabicIndicDigit();

    /// <summary><c>?</c> and <c>;</c> anywhere in Arabic prose, or a <c>,</c> touching an Arabic letter.</summary>
    [GeneratedRegex(@"[?;]|[ء-ي]\s?,|,\s?[ء-ي]")]
    private static partial Regex LatinPunctuationAfterArabic();

    [GeneratedRegex(@"[؀-ۿ]")]
    private static partial Regex ArabicLetter();
}
