using System.Text;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace ReadIn.ContentStudio.Authoring;

/// <summary>A problem in an authoring draft, with its 1-based line number.</summary>
public sealed record DraftError(int Line, string Message);

/// <summary>
/// Converts an authoring draft (a small, strict Markdown dialect, see content/AUTHORING.md) into an RDoc v1 document.
/// Drafts are a writing aid only; the generated <c>en.json</c> / <c>ar-EG.json</c> are what gets committed and imported.
/// Block ids are positional (<c>tldr</c>, <c>b1</c>, <c>b2</c>…), so two drafts with the same structure produce the same
/// ids, which is what the en/ar-EG parity check compares. Arabic blocks get an explicit <c>dir: "rtl"</c> so a paragraph
/// that happens to start with an English term never flips to LTR (SPEC §14.2).
/// </summary>
public static partial class RDocMarkdown
{
    private static readonly HashSet<string> CalloutVariants = ["tip", "info", "warning", "danger"];

    public static (JsonObject? Document, IReadOnlyList<DraftError> Errors) Convert(string markdown, string language)
    {
        var parser = new Parser(markdown.Replace("\r\n", "\n").Split('\n'), language);
        var blocks = parser.ParseBlocks();
        if (parser.Errors.Count > 0) return (null, parser.Errors);

        var document = new JsonObject { ["version"] = 1, ["language"] = language, ["blocks"] = blocks };
        return (document, parser.Errors);
    }

    private sealed class Parser(string[] lines, string language)
    {
        private int _i;
        private int _nextId = 1;
        private readonly bool _rtl = language == "ar-EG";

        public List<DraftError> Errors { get; } = [];

        public JsonArray ParseBlocks()
        {
            var blocks = new JsonArray();
            while (_i < lines.Length)
            {
                var line = lines[_i];
                if (string.IsNullOrWhiteSpace(line)) { _i++; continue; }

                var block = ParseBlock(line);
                if (block is not null) blocks.Add(block);
            }
            return blocks;
        }

        private JsonObject? ParseBlock(string line)
        {
            var start = _i + 1;

            if (line.StartsWith("```", StringComparison.Ordinal)) return ParseCode(line);
            if (line.StartsWith(":::", StringComparison.Ordinal)) return ParseContainer(line);

            if (line.StartsWith("### ", StringComparison.Ordinal) || line.StartsWith("## ", StringComparison.Ordinal))
            {
                _i++;
                var level = line.StartsWith("### ", StringComparison.Ordinal) ? 3 : 2;
                return Block("heading", ("level", level), ("content", Inline(line[(level + 1)..].Trim(), start)));
            }
            if (line.StartsWith("# ", StringComparison.Ordinal))
            {
                _i++;
                Error(start, "H1 is the article title (meta.json), not a block. Use ## or ###.");
                return null;
            }
            if (line.Trim() == "---")
            {
                _i++;
                return Block("divider");
            }
            if (line.StartsWith('|')) return ParseTable();
            if (BulletItem().IsMatch(line)) return ParseList("bulletList", BulletItem());
            if (OrderedItem().IsMatch(line)) return ParseList("orderedList", OrderedItem());
            if (line.StartsWith('>')) return ParseQuote();
            if (Image().Match(line) is { Success: true } image)
            {
                _i++;
                var block = Block("image", ("src", image.Groups["src"].Value), ("alt", image.Groups["alt"].Value));
                if (image.Groups["caption"].Success) block["caption"] = image.Groups["caption"].Value;
                return block;
            }

            return Block("paragraph", ("content", Inline(ReadParagraph(), start)));
        }

        /// <summary>Consecutive non-blank lines that don't start another block, joined with spaces.</summary>
        private string ReadParagraph()
        {
            var sb = new StringBuilder();
            while (_i < lines.Length && !string.IsNullOrWhiteSpace(lines[_i]) && (sb.Length == 0 || !StartsBlock(lines[_i])))
            {
                if (sb.Length > 0) sb.Append(' ');
                sb.Append(lines[_i].Trim());
                _i++;
            }
            return sb.ToString();
        }

        private static bool StartsBlock(string line) =>
            line.StartsWith("```", StringComparison.Ordinal) || line.StartsWith(":::", StringComparison.Ordinal) ||
            line.StartsWith('#') || line.StartsWith('|') || line.StartsWith('>') ||
            BulletItem().IsMatch(line) || OrderedItem().IsMatch(line);

        private JsonObject? ParseCode(string fence)
        {
            var start = _i + 1;
            var info = ParseInfo(fence[3..], start);
            var code = ReadFence(start);
            if (code is null) return null;
            if (info.Lang is null)
            {
                Error(start, "A code block needs a language: ```csharp, ```ts, ```dart, ```python …");
                return null;
            }

            var block = Block("code", ("lang", info.Lang));
            if (info.Filename is not null) block["filename"] = info.Filename;
            block["code"] = code;
            if (info.Highlight is not null) block["highlightLines"] = info.Highlight;
            if (info.Compile is false) block["compile"] = false;
            if (info.Label is not null) Error(start, "label= only applies to tabs inside :::codetabs.");
            return block;
        }

        /// <summary>Reads a fenced body up to the closing ``` (the fence line itself must be the current line).</summary>
        private string? ReadFence(int start)
        {
            _i++;
            var body = new List<string>();
            while (_i < lines.Length && !lines[_i].StartsWith("```", StringComparison.Ordinal))
            {
                body.Add(lines[_i]);
                _i++;
            }
            if (_i >= lines.Length)
            {
                Error(start, "Unclosed code fence.");
                return null;
            }
            _i++; // closing fence
            return string.Join('\n', body);
        }

        private JsonObject? ParseContainer(string line)
        {
            var start = _i + 1;
            var header = line[3..].Trim();
            var kind = header.Split(' ', 2)[0].ToLowerInvariant();
            var argument = header.Length > kind.Length ? header[kind.Length..].Trim() : null;
            _i++;

            var body = new List<(string Text, int Line)>();
            var inFence = false;
            while (_i < lines.Length && (inFence || lines[_i].Trim() != ":::"))
            {
                if (lines[_i].StartsWith("```", StringComparison.Ordinal)) inFence = !inFence;
                body.Add((lines[_i], _i + 1));
                _i++;
            }
            if (_i >= lines.Length)
            {
                Error(start, $"Unclosed :::{kind} (close it with a line containing only :::).");
                return null;
            }
            _i++; // closing :::

            switch (kind)
            {
                case "summary":
                    return Block("summary", ("content", Inline(JoinText(body), start)), id: "tldr");

                case var v when CalloutVariants.Contains(v):
                    var callout = Block("callout", ("variant", v));
                    if (!string.IsNullOrWhiteSpace(argument)) callout["title"] = argument;
                    callout["content"] = Inline(JoinText(body), start);
                    return callout;

                case "steps":
                    return ParseSteps(body, start);

                case "codetabs":
                    return ParseCodeTabs(body, start);

                default:
                    Error(start, $"Unknown container :::{kind}. Use summary, tip, info, warning, danger, steps or codetabs.");
                    return null;
            }
        }

        private string JoinText(List<(string Text, int Line)> body)
        {
            var text = string.Join(' ', body.Select(b => b.Text.Trim()).Where(t => t.Length > 0));
            return text;
        }

        /// <summary>Steps: each <c>### Title</c> starts a step; the lines after it (until the next ###) are its content.</summary>
        private JsonObject? ParseSteps(List<(string Text, int Line)> body, int start)
        {
            var items = new JsonArray();
            string? title = null;
            var titleLine = start;
            var content = new List<(string, int)>();

            void Flush()
            {
                if (title is null) return;
                items.Add(new JsonObject { ["title"] = title, ["content"] = Inline(JoinText(content), titleLine) });
                content.Clear();
            }

            foreach (var (text, line) in body)
            {
                if (text.StartsWith("### ", StringComparison.Ordinal))
                {
                    Flush();
                    title = text[4..].Trim();
                    titleLine = line;
                }
                else if (!string.IsNullOrWhiteSpace(text))
                {
                    if (title is null) Error(line, "Text inside :::steps must follow a '### Step title' line.");
                    else content.Add((text, line));
                }
            }
            Flush();

            if (items.Count == 0) Error(start, ":::steps needs at least one '### Step title'.");
            return Block("steps", ("items", items));
        }

        private JsonObject? ParseCodeTabs(List<(string Text, int Line)> body, int start)
        {
            var tabs = new JsonArray();
            for (var k = 0; k < body.Count; k++)
            {
                var (text, line) = body[k];
                if (string.IsNullOrWhiteSpace(text)) continue;
                if (!text.StartsWith("```", StringComparison.Ordinal))
                {
                    Error(line, "Only fenced code blocks may appear inside :::codetabs.");
                    continue;
                }

                var info = ParseInfo(text[3..], line);
                var code = new List<string>();
                k++;
                while (k < body.Count && !body[k].Text.StartsWith("```", StringComparison.Ordinal)) code.Add(body[k++].Text);

                if (info.Lang is null || info.Label is null)
                {
                    Error(line, "Each tab needs a language and a label: ```csharp label=\"❌ Wrong\"");
                    continue;
                }
                var tab = new JsonObject { ["label"] = info.Label, ["lang"] = info.Lang };
                if (info.Filename is not null) tab["filename"] = info.Filename;
                tab["code"] = string.Join('\n', code);
                if (info.Compile is false) tab["compile"] = false;
                tabs.Add(tab);
            }

            if (tabs.Count < 2) Error(start, ":::codetabs needs at least two tabs.");
            return Block("codeTabs", ("tabs", tabs));
        }

        private sealed record FenceInfo(string? Lang, string? Filename, string? Label, bool? Compile, JsonArray? Highlight);

        /// <summary>Parses <c>lang key="value" key=value</c> after a fence.</summary>
        private FenceInfo ParseInfo(string info, int line)
        {
            info = info.Trim();
            var langMatch = FenceLang().Match(info);
            var lang = langMatch.Success && langMatch.Value.Length > 0 ? langMatch.Value : null;
            string? filename = null, label = null;
            bool? compile = null;
            JsonArray? highlight = null;

            foreach (Match attr in FenceAttribute().Matches(info[(lang?.Length ?? 0)..]))
            {
                var value = attr.Groups["quoted"].Success ? attr.Groups["quoted"].Value : attr.Groups["bare"].Value;
                switch (attr.Groups["key"].Value)
                {
                    case "filename": filename = value; break;
                    case "label": label = value; break;
                    case "compile": compile = value != "false"; break;
                    case "highlight":
                        highlight = [.. value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                            .Select(v => (JsonNode)JsonValue.Create(int.Parse(v, System.Globalization.CultureInfo.InvariantCulture))!)];
                        break;
                    default: Error(line, $"Unknown fence attribute '{attr.Groups["key"].Value}'."); break;
                }
            }
            return new FenceInfo(lang, filename, label, compile, highlight);
        }

        private JsonObject ParseTable()
        {
            var start = _i + 1;
            var rows = new List<(List<string> Cells, int Line)>();
            while (_i < lines.Length && lines[_i].StartsWith('|'))
            {
                rows.Add((SplitRow(lines[_i]), _i + 1));
                _i++;
            }

            if (rows.Count < 2 || !rows[1].Cells.All(c => TableSeparator().IsMatch(c)))
            {
                Error(start, "A table needs a header row and a separator row (| --- | --- |).");
                return Block("table", ("header", new JsonArray()), ("rows", new JsonArray()));
            }

            var width = rows[0].Cells.Count;
            var header = new JsonArray([.. rows[0].Cells.Select(c => (JsonNode)Inline(c, start))]);
            var body = new JsonArray();
            foreach (var (cells, line) in rows.Skip(2))
            {
                if (cells.Count != width) Error(line, $"This row has {cells.Count} cells; the header has {width}.");
                body.Add(new JsonArray([.. cells.Select(c => (JsonNode)Inline(c, line))]));
            }
            return Block("table", ("header", header), ("rows", body));
        }

        /// <summary>Splits a <c>| a | b |</c> row; <c>\|</c> is a literal pipe (also inside inline code).</summary>
        private static List<string> SplitRow(string row)
        {
            var trimmed = row.Trim();
            if (trimmed.StartsWith('|')) trimmed = trimmed[1..];
            if (trimmed.EndsWith('|') && !trimmed.EndsWith("\\|", StringComparison.Ordinal)) trimmed = trimmed[..^1];

            var cells = new List<string>();
            var cell = new StringBuilder();
            for (var k = 0; k < trimmed.Length; k++)
            {
                if (trimmed[k] == '\\' && k + 1 < trimmed.Length && trimmed[k + 1] == '|')
                {
                    cell.Append('|');
                    k++;
                }
                else if (trimmed[k] == '|')
                {
                    cells.Add(cell.ToString().Trim());
                    cell.Clear();
                }
                else cell.Append(trimmed[k]);
            }
            cells.Add(cell.ToString().Trim());
            return cells;
        }

        private JsonObject ParseList(string type, Regex marker)
        {
            var items = new JsonArray();
            while (_i < lines.Length && marker.Match(lines[_i]) is { Success: true } m)
            {
                var start = _i + 1;
                var text = new StringBuilder(lines[_i][m.Length..].Trim());
                _i++;
                // Continuation lines are indented.
                while (_i < lines.Length && lines[_i].StartsWith("  ", StringComparison.Ordinal) && !string.IsNullOrWhiteSpace(lines[_i]))
                {
                    text.Append(' ').Append(lines[_i].Trim());
                    _i++;
                }
                items.Add(Inline(text.ToString(), start));
            }
            return Block(type, ("items", items));
        }

        private JsonObject ParseQuote()
        {
            var start = _i + 1;
            var text = new StringBuilder();
            string? cite = null;
            while (_i < lines.Length && lines[_i].StartsWith('>'))
            {
                var content = lines[_i].TrimStart('>').Trim();
                if (content.StartsWith("-- ", StringComparison.Ordinal)) cite = content[3..].Trim();
                else
                {
                    if (text.Length > 0) text.Append(' ');
                    text.Append(content);
                }
                _i++;
            }
            var block = Block("quote", ("content", Inline(text.ToString(), start)));
            if (cite is not null) block["cite"] = cite;
            return block;
        }

        private JsonObject Block(string type, params (string Key, JsonNode? Value)[] properties) => Block(type, properties, null);

        private JsonObject Block(string type, (string Key, JsonNode? Value) property, string id) => Block(type, [property], id);

        private JsonObject Block(string type, (string Key, JsonNode? Value)[] properties, string? id)
        {
            var block = new JsonObject { ["id"] = id ?? $"b{_nextId++}", ["type"] = type };
            if (_rtl && type is not ("code" or "codeTabs" or "divider" or "image")) block["dir"] = "rtl";
            foreach (var (key, value) in properties) block[key] = value;
            return block;
        }

        private JsonArray Inline(string text, int line)
        {
            var result = InlineParser.Parse(text, out var error);
            if (error is not null) Error(line, error);
            return result;
        }

        private void Error(int line, string message) => Errors.Add(new DraftError(line, message));
    }

    [GeneratedRegex(@"^- ")]
    private static partial Regex BulletItem();

    [GeneratedRegex(@"^\d+\. ")]
    private static partial Regex OrderedItem();

    [GeneratedRegex(@"^:?-{3,}:?$")]
    private static partial Regex TableSeparator();

    [GeneratedRegex(@"^[a-z0-9+#.-]*")]
    private static partial Regex FenceLang();

    [GeneratedRegex(@"(?<key>[a-z]+)=(?:""(?<quoted>[^""]*)""|(?<bare>[^\s""]+))")]
    private static partial Regex FenceAttribute();

    [GeneratedRegex(@"^!\[(?<alt>[^\]]+)\]\((?<src>[^\s)]+)(?:\s+""(?<caption>[^""]*)"")?\)\s*$")]
    private static partial Regex Image();
}

/// <summary>
/// Inline syntax: <c>`code`</c>, <c>**bold**</c>, <c>*italic*</c>, <c>[text](https://url)</c>, <c>[[term-id|Shown text]]</c>,
/// and <c>\</c> to escape <c>* ` [ ] \ |</c>. Marks nest (<c>**`AddScoped`**</c> is bold code).
/// </summary>
internal static class InlineParser
{
    public static JsonArray Parse(string text, out string? error)
    {
        error = null;
        var nodes = new JsonArray();
        var pos = 0;
        ParseInto(text, ref pos, nodes, [], terminator: null, ref error);
        return Merge(nodes);
    }

    private static void ParseInto(string s, ref int pos, JsonArray nodes, List<JsonObject> marks, string? terminator, ref string? error)
    {
        var buffer = new StringBuilder();

        void FlushText()
        {
            if (buffer.Length == 0) return;
            nodes.Add(TextNode(buffer.ToString(), marks));
            buffer.Clear();
        }

        while (pos < s.Length)
        {
            if (terminator is not null && string.CompareOrdinal(s, pos, terminator, 0, terminator.Length) == 0)
            {
                FlushText();
                pos += terminator.Length;
                return;
            }

            var c = s[pos];
            if (c == '\\' && pos + 1 < s.Length && "*`[]\\|_".Contains(s[pos + 1]))
            {
                buffer.Append(s[pos + 1]);
                pos += 2;
                continue;
            }

            if (c == '`')
            {
                var end = s.IndexOf('`', pos + 1);
                if (end < 0)
                {
                    error ??= "Unclosed inline code (`).";
                    buffer.Append(c);
                    pos++;
                    continue;
                }
                FlushText();
                var code = s[(pos + 1)..end];
                nodes.Add(TextNode(code, [.. marks, new JsonObject { ["type"] = "code" }]));
                pos = end + 1;
                continue;
            }

            if (c == '[' && pos + 1 < s.Length && s[pos + 1] == '[')
            {
                var end = s.IndexOf("]]", pos + 2, StringComparison.Ordinal);
                var body = end < 0 ? null : s[(pos + 2)..end];
                var bar = body?.IndexOf('|') ?? -1;
                if (body is null || bar <= 0)
                {
                    error ??= "Glossary terms are written [[term-id|Shown text]].";
                    buffer.Append(c);
                    pos++;
                    continue;
                }
                FlushText();
                nodes.Add(new JsonObject { ["type"] = "term", ["termId"] = body[..bar].Trim(), ["text"] = body[(bar + 1)..].Trim() });
                pos = end + 2;
                continue;
            }

            if (c == '[')
            {
                var close = FindClosingBracket(s, pos);
                if (close > 0 && close + 1 < s.Length && s[close + 1] == '(')
                {
                    var hrefEnd = s.IndexOf(')', close + 2);
                    if (hrefEnd > 0)
                    {
                        FlushText();
                        var href = s[(close + 2)..hrefEnd].Trim();
                        var inner = s[(pos + 1)..close];
                        var innerPos = 0;
                        ParseInto(inner, ref innerPos, nodes, [.. marks, new JsonObject { ["type"] = "link", ["href"] = href }], null, ref error);
                        pos = hrefEnd + 1;
                        continue;
                    }
                }
            }

            if (c == '*')
            {
                var isBold = pos + 1 < s.Length && s[pos + 1] == '*';
                var token = isBold ? "**" : "*";
                var close = FindClosingEmphasis(s, pos + token.Length, token);
                if (close > 0)
                {
                    FlushText();
                    pos += token.Length;
                    ParseInto(s, ref pos, nodes, [.. marks, new JsonObject { ["type"] = isBold ? "bold" : "italic" }], token, ref error);
                    continue;
                }
                error ??= $"Unclosed {token} emphasis (escape a literal star as \\*).";
            }

            buffer.Append(c);
            pos++;
        }

        if (terminator is not null) error ??= $"Unclosed {terminator}.";
        FlushText();
    }

    private static int FindClosingBracket(string s, int open)
    {
        var depth = 0;
        for (var k = open; k < s.Length; k++)
        {
            if (s[k] == '\\') { k++; continue; }
            if (s[k] == '`')
            {
                var end = s.IndexOf('`', k + 1);
                if (end < 0) return -1;
                k = end;
                continue;
            }
            if (s[k] == '[') depth++;
            else if (s[k] == ']' && --depth == 0) return k;
        }
        return -1;
    }

    /// <summary>Finds the closing <paramref name="token"/>, skipping inline code and escapes.</summary>
    private static int FindClosingEmphasis(string s, int from, string token)
    {
        for (var k = from; k < s.Length; k++)
        {
            if (s[k] == '\\') { k++; continue; }
            if (s[k] == '`')
            {
                var end = s.IndexOf('`', k + 1);
                if (end < 0) return -1;
                k = end;
                continue;
            }
            if (string.CompareOrdinal(s, k, token, 0, token.Length) != 0) continue;
            // "*" must not match the first star of "**" (and vice versa).
            if (token == "*" && k + 1 < s.Length && s[k + 1] == '*') { k++; continue; }
            return k;
        }
        return -1;
    }

    private static JsonObject TextNode(string text, List<JsonObject> marks)
    {
        var node = new JsonObject { ["type"] = "text", ["text"] = text };
        if (marks.Count > 0) node["marks"] = new JsonArray([.. marks.Select(m => (JsonNode)m.DeepClone())]);
        return node;
    }

    /// <summary>Joins neighbouring text nodes with identical marks.</summary>
    private static JsonArray Merge(JsonArray nodes)
    {
        var merged = new JsonArray();
        foreach (var node in nodes.Select(n => n!.DeepClone().AsObject()))
        {
            if (merged.Count > 0 && merged[^1] is JsonObject last && last["type"]!.GetValue<string>() == "text" &&
                node["type"]!.GetValue<string>() == "text" && JsonNode.DeepEquals(last["marks"], node["marks"]))
            {
                last["text"] = last["text"]!.GetValue<string>() + node["text"]!.GetValue<string>();
                continue;
            }
            merged.Add(node);
        }
        return merged;
    }
}
