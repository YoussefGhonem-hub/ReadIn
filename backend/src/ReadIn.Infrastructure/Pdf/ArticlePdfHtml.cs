using System.Globalization;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Text.Unicode;
using ReadIn.Application.Features.Articles.Pdf;

namespace ReadIn.Infrastructure.Pdf;

/// <summary>
/// Turns an article into the print HTML Chromium makes the PDF from (SPEC F33). Every piece of text and every attribute
/// is HTML-encoded; the page has no script, and its only resources are <c>data:</c> URLs (fonts, logo, images read from
/// the uploads folder), so printing it fetches nothing. Directions follow the article language and each block's own text
/// (§14.2), exactly like the web reader.
/// </summary>
internal static partial class ArticlePdfHtml
{
    private static readonly HtmlEncoder Html = HtmlEncoder.Create(UnicodeRanges.All);

    /// <summary>
    /// The full page, with the emoji font and the symbol fonts only when the printed text has a character for them (they
    /// are large, and Chromium embeds only the glyphs it uses anyway).
    /// </summary>
    public static string Build(ArticlePdfDocument document, ArticlePdfAssets assets, string webBaseUrl)
    {
        var writer = new Writer(document, assets, webBaseUrl.TrimEnd('/'));
        var body = writer.Body();

        var page = new StringBuilder(body.Length + 1024 * 1024 * 3);
        page.Append("<!DOCTYPE html><html lang=\"").Append(Attr(document.Language)).Append("\" dir=\"").Append(writer.Dir).Append("\"><head>")
            .Append("<meta charset=\"utf-8\">")
            // A second wall next to the browser's own blocking: no script, nothing but data: URLs.
            .Append("<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; img-src data:; font-src data:; style-src 'unsafe-inline'\">")
            .Append("<title>").Append(Text(document.Title)).Append("</title>")
            .Append("<meta name=\"author\" content=\"").Append(Attr(document.Author.DisplayName)).Append("\">")
            .Append("<style>").Append(assets.FontFaces);
        // Found from the text before it was encoded: the encoder writes every character outside the BMP (most emoji and
        // every flag) as an entity, so the HTML itself can't tell.
        if (writer.Fallbacks.HasFlag(PdfFallbacks.Emoji)) page.Append(assets.EmojiFontFace);
        if (writer.Fallbacks.HasFlag(PdfFallbacks.Symbols)) page.Append(assets.SymbolFontFaces);
        page.Append(assets.Stylesheet).Append("</style></head>")
            .Append("<body class=\"").Append(writer.Dir == BidiText.Rtl ? "ar" : "en").Append("\">")
            .Append(body)
            .Append("</body></html>");
        return page.ToString();
    }

    /// <summary>
    /// The footer on every page: a thin line, the logo, the web host and "2 / 5". Chromium renders it apart from the page,
    /// so it carries its own font and logo.
    /// </summary>
    public static string Footer(string language, ArticlePdfAssets assets, string host)
    {
        var dir = BidiText.LanguageDir(language);
        return "<style>" + assets.FooterFontFace +
               ".f{box-sizing:border-box;width:100%;padding:0 18mm 5mm;font-family:\"ReadIn Footer\";font-size:8pt;line-height:1;color:#6B6B6B;" +
               "-webkit-print-color-adjust:exact;print-color-adjust:exact}" +
               ".r{display:flex;align-items:center;justify-content:space-between;border-top:.5pt solid #E8E4DC;padding-top:2.5mm}" +
               ".l{display:block;width:18mm;height:auto}.n{direction:ltr;unicode-bidi:isolate}</style>" +
               $"<div class=\"f\" dir=\"{dir}\"><div class=\"r\"><img class=\"l\" src=\"{assets.FooterLogoDataUri}\" alt=\"ReadIn\">" +
               $"<span class=\"n\">{Text(host)}</span>" +
               "<span class=\"n\"><span class=\"pageNumber\"></span> / <span class=\"totalPages\"></span></span></div></div>";
    }

    /// <summary>The H2/H3 texts in document order, in reading order: the bookmarks (No-bug rule 6).</summary>
    public static IReadOnlyList<string> Headings(JsonElement content) =>
        content.TryGetProperty("blocks", out var blocks) && blocks.ValueKind == JsonValueKind.Array
            ? [.. blocks.EnumerateArray().Where(b => Type(b) == "heading").Select(b => BidiText.InlineText(b.GetProperty("content"), includeCode: true).Trim())]
            : [];

    /// <summary>
    /// The fallback fonts plain text needs beyond the text fonts: Noto Color Emoji for an emoji (pictographs, dingbats,
    /// flags, keycaps, the emoji variation selector), Noto Sans Symbols 2 and Noto Sans Math for the arrows, maths,
    /// technical signs, shapes and dingbats the text fonts lack (★, ⇒, ◆, ☐, ⌘ …). Takes raw text, never HTML.
    /// </summary>
    public static PdfFallbacks FallbacksFor(string text)
    {
        var found = PdfFallbacks.None;
        for (var i = 0; i < text.Length && found != PdfFallbacks.All; i++)
        {
            int cp = text[i];
            if (char.IsSurrogatePair(text, i)) cp = char.ConvertToUtf32(text[i], text[++i]);

            if (cp is >= 0x1F000 and <= 0x1FAFF or >= 0x2600 and <= 0x27BF or >= 0x2B00 and <= 0x2BFF or 0xFE0F or 0x20E3 or 0x203C or 0x2049)
                found |= PdfFallbacks.Emoji;
            if (cp is >= 0x2100 and <= 0x2BFF or >= 0x1D400 and <= 0x1D7FF or >= 0x1F780 and <= 0x1F8FF)
                found |= PdfFallbacks.Symbols;
        }
        return found;
    }

    private static string Text(string? value) => value is null ? string.Empty : Html.Encode(value);

    private static string Attr(string? value) => value is null ? string.Empty : Html.Encode(value);

    /// <summary>Only http(s) links, as everywhere in RDoc (SPEC §13.3).</summary>
    private static string? SafeUrl(string? url) => url is not null && SafeUrlPattern().IsMatch(url) ? url : null;

    [GeneratedRegex(@"^https?://[^\s<>""']+$", RegexOptions.IgnoreCase)]
    private static partial Regex SafeUrlPattern();

    private static readonly Dictionary<string, string> CodeLanguages = new(StringComparer.OrdinalIgnoreCase)
    {
        ["csharp"] = "C#", ["cs"] = "C#", ["typescript"] = "TypeScript", ["ts"] = "TypeScript", ["tsx"] = "TSX",
        ["javascript"] = "JavaScript", ["js"] = "JavaScript", ["dart"] = "Dart", ["json"] = "JSON", ["bash"] = "Bash",
        ["sh"] = "Shell", ["shell"] = "Shell", ["powershell"] = "PowerShell", ["sql"] = "SQL", ["html"] = "HTML",
        ["css"] = "CSS", ["scss"] = "SCSS", ["yaml"] = "YAML", ["yml"] = "YAML", ["python"] = "Python", ["py"] = "Python",
        ["kotlin"] = "Kotlin", ["swift"] = "Swift", ["xml"] = "XML", ["dockerfile"] = "Dockerfile", ["java"] = "Java",
        ["go"] = "Go", ["rust"] = "Rust", ["markdown"] = "Markdown", ["razor"] = "Razor",
    };

    /// <summary>Code of up to this many lines never splits across pages (No-bug rule 4).</summary>
    public const int ShortCodeLines = 20;

    /// <summary>A wrapped code line continues under its indentation up to this many columns (about half the line).</summary>
    public const int MaxCodeIndent = 40;

    private sealed class Writer(ArticlePdfDocument document, ArticlePdfAssets assets, string web)
    {
        private readonly StringBuilder _html = new(64 * 1024);
        private readonly Labels _labels = Labels.For(document.Language);

        public string Dir { get; } = BidiText.LanguageDir(document.Language);

        /// <summary>The fallback fonts the printed text needs (see <see cref="FallbacksFor"/>).</summary>
        public PdfFallbacks Fallbacks { get; private set; }

        /// <summary>
        /// Every printed string goes through here (it hides the outer <c>Text</c> inside the writer), so the raw text
        /// tells which fallback fonts the page needs before it is encoded.
        /// </summary>
        private string Text(string? value)
        {
            if (!string.IsNullOrEmpty(value)) Fallbacks |= FallbacksFor(value);
            return ArticlePdfHtml.Text(value);
        }

        private string ArticleUrl =>
            $"{web}/{(document.Language == "en" ? "en" : "ar")}/a/{Uri.EscapeDataString(document.Slug)}";

        /// <summary>The same link as people read it (an Arabic slug stays Arabic); the href is percent-encoded.</summary>
        private string ArticleUrlText => $"{web}/{(document.Language == "en" ? "en" : "ar")}/a/{document.Slug}";

        private string ProfileUrl(string username) => $"{web}/@{Uri.EscapeDataString(username)}";

        public string Body()
        {
            Masthead();
            _html.Append("<main class=\"content\">");
            var blocks = document.Content.TryGetProperty("blocks", out var b) && b.ValueKind == JsonValueKind.Array ? b.EnumerateArray().ToList() : [];
            // The summary is a tinted box at the top of the content, wherever the writer put it.
            foreach (var block in blocks.Where(IsSummary)) Block(block);
            foreach (var block in blocks.Where(x => !IsSummary(x))) Block(block);
            _html.Append("</main>");
            End();
            return _html.ToString();

            static bool IsSummary(JsonElement block) => Type(block) == "summary";
        }

        // ---- First page ----

        private void Masthead()
        {
            var titleDir = BidiText.DetectDir(document.Title) ?? Dir;
            _html.Append("<header class=\"masthead\">")
                .Append("<img class=\"logo\" src=\"").Append(assets.LogoDataUri).Append("\" alt=\"ReadIn\">")
                // Not a heading: the bookmarks are the article's H2/H3 only, and the title is in the metadata (rule 6).
                .Append("<div class=\"title\" dir=\"").Append(titleDir).Append("\">");
            Plain(document.Title, titleDir);
            _html.Append("</div>");

            if (!string.IsNullOrWhiteSpace(document.Subtitle))
            {
                var subtitleDir = BidiText.DetectDir(document.Subtitle) ?? Dir;
                _html.Append("<p class=\"subtitle\" dir=\"").Append(subtitleDir).Append("\">");
                Plain(document.Subtitle, subtitleDir);
                _html.Append("</p>");
            }

            // A deleted account has no profile to link to (SPEC §9.6).
            if (document.Author.Username is { } username)
            {
                _html.Append("<p class=\"byline\"><a href=\"").Append(Attr(ProfileUrl(username))).Append("\"><bdi>")
                    .Append(Text(document.Author.DisplayName)).Append("</bdi></a>");
            }
            else
            {
                _html.Append("<p class=\"byline\"><bdi>").Append(Text(document.Author.DisplayName)).Append("</bdi>");
            }
            if (document.Author.IsVerified)
            {
                _html.Append("<span class=\"verified\" role=\"img\" aria-label=\"").Append(Attr(_labels.Verified)).Append("\" title=\"")
                    .Append(Attr(_labels.Verified)).Append("\">").Append(assets.Icons["verified"]).Append("</span>");
            }
            _html.Append("</p>");

            _html.Append("<p class=\"meta\">").Append(Text(_labels.Date(document.PublishedOn))).Append(" · ")
                .Append(Text(_labels.ReadingTime(document.ReadingTimeMinutes)));
            // SPEC §20: every AI-assisted article carries the label, the file too; in the article's language.
            if (document.IsAiAssisted)
            {
                _html.Append(" · <span class=\"ai-label\">");
                Plain(_labels.AiAssisted, Dir);
                _html.Append("</span>");
            }
            _html.Append("</p>");

            _html.Append("<p class=\"meta\"><bdi>").Append(Text(document.FieldName)).Append("</bdi>");
            if (!string.IsNullOrWhiteSpace(document.TopicName)) _html.Append(" · <bdi>").Append(Text(document.TopicName)).Append("</bdi>");
            _html.Append("</p>");

            if (document.Tags.Count > 0)
            {
                _html.Append("<ul class=\"tags\">");
                foreach (var tag in document.Tags) _html.Append("<li><bdi>#").Append(Text(tag)).Append("</bdi></li>");
                _html.Append("</ul>");
            }

            if (document.ShowHealthDisclaimer)
                _html.Append("<p class=\"disclaimer\" role=\"note\">").Append(Text(_labels.HealthDisclaimer)).Append("</p>");

            if (document.Cover is { } cover)
            {
                _html.Append("<figure class=\"cover\"><img src=\"").Append(ArticlePdfAssets.DataUri(cover.MediaType, cover.Bytes))
                    .Append("\" alt=\"").Append(Attr(document.Title)).Append("\"></figure>");
            }
            _html.Append("</header>");
        }

        // ---- Blocks ----

        private void Block(JsonElement block)
        {
            switch (Type(block))
            {
                case "paragraph":
                {
                    var dir = BidiText.ResolveBlockDir(block, Dir);
                    _html.Append("<p dir=\"").Append(dir).Append("\">");
                    Inline(block.GetProperty("content"), dir);
                    _html.Append("</p>");
                    break;
                }
                case "heading":
                {
                    var dir = BidiText.ResolveBlockDir(block, Dir);
                    var tag = block.TryGetProperty("level", out var level) && level.GetInt32() == 3 ? "h3" : "h2";
                    // The label is the heading's text in reading order: Chromium names the bookmark after it.
                    _html.Append('<').Append(tag).Append(" id=\"h-").Append(Attr(Id(block))).Append("\" dir=\"").Append(dir)
                        .Append("\" aria-label=\"").Append(Attr(BidiText.InlineText(block.GetProperty("content"), includeCode: true).Trim())).Append("\">");
                    Inline(block.GetProperty("content"), dir);
                    _html.Append("</").Append(tag).Append('>');
                    break;
                }
                case "bulletList" or "orderedList":
                {
                    var dir = BidiText.ResolveBlockDir(block, Dir);
                    var tag = Type(block) == "orderedList" ? "ol" : "ul";
                    _html.Append('<').Append(tag).Append(" dir=\"").Append(dir).Append("\">");
                    foreach (var item in block.GetProperty("items").EnumerateArray())
                    {
                        _html.Append("<li>");
                        Inline(item, dir);
                        _html.Append("</li>");
                    }
                    _html.Append("</").Append(tag).Append('>');
                    break;
                }
                case "steps":
                {
                    var dir = BidiText.ResolveBlockDir(block, Dir);
                    _html.Append("<ol class=\"steps\" dir=\"").Append(dir).Append("\">");
                    var number = 0;
                    foreach (var step in block.GetProperty("items").EnumerateArray())
                    {
                        number++;
                        _html.Append("<li class=\"step\"><span class=\"step-number\" aria-hidden=\"true\">")
                            .Append(number.ToString(CultureInfo.InvariantCulture)).Append("</span><div class=\"step-body\"><span class=\"step-title\">");
                        Plain(step.GetProperty("title").GetString(), dir);
                        _html.Append("</span>");
                        Inline(step.GetProperty("content"), dir);
                        _html.Append("</div></li>");
                    }
                    _html.Append("</ol>");
                    break;
                }
                case "quote":
                {
                    var dir = BidiText.ResolveBlockDir(block, Dir);
                    _html.Append("<blockquote dir=\"").Append(dir).Append("\"><p>");
                    Inline(block.GetProperty("content"), dir);
                    _html.Append("</p>");
                    if (block.TryGetProperty("cite", out var cite) && cite.GetString() is { Length: > 0 } source)
                    {
                        _html.Append("<span class=\"cite\">— ");
                        Plain(source, dir);
                        _html.Append("</span>");
                    }
                    _html.Append("</blockquote>");
                    break;
                }
                case "callout":
                {
                    var dir = BidiText.ResolveBlockDir(block, Dir);
                    var variant = block.TryGetProperty("variant", out var v) && v.GetString() is "tip" or "info" or "warning" or "danger"
                        ? v.GetString()!
                        : "info";
                    _html.Append("<div class=\"callout callout-").Append(variant).Append("\" role=\"note\" dir=\"").Append(dir).Append("\">")
                        .Append("<span class=\"callout-icon\" aria-hidden=\"true\">").Append(assets.Icons[variant]).Append("</span>")
                        .Append("<div class=\"callout-body\"><span class=\"callout-title\">");
                    var title = block.TryGetProperty("title", out var t) && t.GetString() is { Length: > 0 } custom ? custom : _labels.Callout(variant);
                    Plain(title, dir);
                    _html.Append("</span>");
                    Inline(block.GetProperty("content"), dir);
                    _html.Append("</div></div>");
                    break;
                }
                case "code":
                    Code(block.GetProperty("code").GetString() ?? string.Empty, Str(block, "lang"), Str(block, "filename"), label: null,
                        HighlightLines(block));
                    break;
                case "codeTabs":
                    // Paper has no tabs: every tab, one after the other, under its label.
                    _html.Append("<div class=\"tabs\">");
                    foreach (var tab in block.GetProperty("tabs").EnumerateArray())
                        Code(tab.GetProperty("code").GetString() ?? string.Empty, Str(tab, "lang"), Str(tab, "filename"), Str(tab, "label"), new HashSet<int>());
                    _html.Append("</div>");
                    break;
                case "table":
                    Table(block);
                    break;
                case "image":
                    Image(block);
                    break;
                case "divider":
                    _html.Append("<hr>");
                    break;
                case "embed":
                {
                    // A card with the provider and the full link; the server fetches nothing from it.
                    var provider = Str(block, "provider") == "github-gist" ? _labels.Gist : _labels.YouTube;
                    _html.Append("<div class=\"card\" dir=\"").Append(Dir).Append("\"><span class=\"card-label\">").Append(Text(provider)).Append("</span>");
                    Link(Str(block, "url"));
                    _html.Append("</div>");
                    break;
                }
                case "summary":
                {
                    var dir = BidiText.ResolveBlockDir(block, Dir);
                    _html.Append("<section class=\"summary\" dir=\"").Append(dir).Append("\"><span class=\"summary-label\">")
                        .Append(Text(_labels.Summary)).Append("</span><p>");
                    Inline(block.GetProperty("content"), dir);
                    _html.Append("</p></section>");
                    break;
                }
            }
        }

        private void Code(string code, string? language, string? filename, string? label, IReadOnlySet<int> highlighted)
        {
            var lines = code.Replace("\r\n", "\n", StringComparison.Ordinal).Split('\n');
            var head = string.Join(" · ", new[] { label, filename ?? (label is null && language is not null ? LanguageLabel(language) : null) }
                .Where(part => !string.IsNullOrWhiteSpace(part)));

            _html.Append("<div class=\"code").Append(lines.Length <= ShortCodeLines ? " code-short" : string.Empty).Append("\" dir=\"ltr\">");
            if (head.Length > 0) _html.Append("<div class=\"code-head mono\">").Append(Text(head)).Append("</div>");
            _html.Append("<pre><code>");
            for (var i = 0; i < lines.Length; i++)
            {
                _html.Append("<span class=\"line").Append(highlighted.Contains(i + 1) ? " hl" : string.Empty).Append('"');
                // A long line wraps under its own indentation (article.css .line), so it never reads as a new line.
                if (CodeIndent(lines[i]) is > 0 and var indent)
                    _html.Append(" style=\"--indent:").Append(indent.ToString(CultureInfo.InvariantCulture)).Append("ch\"");
                _html.Append('>').Append(Text(lines[i])).Append("</span>");
            }
            _html.Append("</code></pre></div>");
        }

        private void Table(JsonElement block)
        {
            var dir = BidiText.ResolveBlockDir(block, Dir);
            // Fixed column widths from the measured words, and a smaller font for a table too wide for the page: text
            // wraps at spaces only and the table never leaves the margins (No-bug rules 1 and 3).
            var layout = PdfTableLayout.For(block, Dir == BidiText.Rtl);
            _html.Append("<div class=\"table\" dir=\"").Append(dir).Append("\"><table");
            if (layout.FontSize < PdfTableLayout.BaseFontSize)
                _html.Append(" style=\"font-size:").Append(layout.FontSize.ToString("0.0", CultureInfo.InvariantCulture)).Append("pt\"");
            _html.Append('>');
            if (layout.ColumnPercents.Count > 0)
            {
                _html.Append("<colgroup>");
                foreach (var percent in layout.ColumnPercents)
                    _html.Append("<col style=\"width:").Append(percent.ToString("0.00", CultureInfo.InvariantCulture)).Append("%\">");
                _html.Append("</colgroup>");
            }
            _html.Append("<thead><tr>");
            foreach (var cell in block.GetProperty("header").EnumerateArray())
            {
                _html.Append("<th>");
                Inline(cell, dir);
                _html.Append("</th>");
            }
            _html.Append("</tr></thead><tbody>");
            foreach (var row in block.GetProperty("rows").EnumerateArray())
            {
                _html.Append("<tr>");
                foreach (var cell in row.EnumerateArray())
                {
                    _html.Append("<td>");
                    Inline(cell, dir);
                    _html.Append("</td>");
                }
                _html.Append("</tr>");
            }
            _html.Append("</tbody></table></div>");
        }

        private void Image(JsonElement block)
        {
            var dir = BidiText.ResolveBlockDir(block, Dir);
            var src = Str(block, "src");
            var alt = Str(block, "alt") ?? string.Empty;
            var caption = Str(block, "caption");

            if (src is not null && document.Images.TryGetValue(src, out var image))
            {
                // darkSrc is ignored: the file is always light. alt becomes the PDF's alternative text.
                _html.Append("<figure dir=\"").Append(dir).Append("\"><img src=\"").Append(ArticlePdfAssets.DataUri(image.MediaType, image.Bytes))
                    .Append("\" alt=\"").Append(Attr(alt)).Append("\">");
                if (!string.IsNullOrWhiteSpace(caption))
                {
                    _html.Append("<figcaption>");
                    Plain(caption, dir);
                    _html.Append("</figcaption>");
                }
                _html.Append("</figure>");
                return;
            }

            // Not one of our uploads (or its file is gone): never fetched, so a card with what it shows and its link.
            _html.Append("<div class=\"card\" dir=\"").Append(dir).Append("\"><span class=\"card-label\">").Append(Text(_labels.Image)).Append("</span>")
                .Append("<span class=\"card-text\">");
            Plain(caption is { Length: > 0 } ? caption : alt, dir);
            _html.Append("</span>");
            Link(src);
            _html.Append("</div>");
        }

        // ---- End of the article ----

        private void End()
        {
            _html.Append("<footer class=\"end\">");

            if (document.ImageAttachments.Count > 0 || document.DocumentAttachment is not null)
            {
                _html.Append("<section class=\"end-section\"><span class=\"end-label\">").Append(Text(_labels.Attachments)).Append("</span>");
                foreach (var attachment in document.ImageAttachments)
                {
                    var dir = BidiText.DetectDir(attachment.Caption ?? attachment.AltText) ?? Dir;
                    _html.Append("<figure dir=\"").Append(dir).Append("\"><img src=\"")
                        .Append(ArticlePdfAssets.DataUri(attachment.Image.MediaType, attachment.Image.Bytes))
                        .Append("\" alt=\"").Append(Attr(attachment.AltText)).Append("\">");
                    if (!string.IsNullOrWhiteSpace(attachment.Caption))
                    {
                        _html.Append("<figcaption>");
                        Plain(attachment.Caption, dir);
                        _html.Append("</figcaption>");
                    }
                    _html.Append("</figure>");
                }
                if (document.DocumentAttachment is { } pdf)
                {
                    // Its pages are never merged into the file: a card that sends readers to the article.
                    var dir = BidiText.DetectDir(pdf.Title) ?? Dir;
                    _html.Append("<div class=\"card\" dir=\"").Append(dir).Append("\"><span class=\"card-label\">");
                    Plain(pdf.Title.Length > 0 ? pdf.Title : "PDF", dir);
                    _html.Append("</span><span class=\"card-text\">").Append(Text(_labels.Pages(pdf.PageCount))).Append("</span>");
                    Link(ArticleUrl, ArticleUrlText);
                    _html.Append("</div>");
                }
                _html.Append("</section>");
            }

            if (document.Sources.Count > 0)
            {
                _html.Append("<section class=\"end-section\"><span class=\"end-label\">").Append(Text(_labels.Sources)).Append("</span><ol class=\"sources\">");
                foreach (var source in document.Sources)
                {
                    var dir = BidiText.DetectDir(source.Title) ?? Dir;
                    _html.Append("<li><span dir=\"").Append(dir).Append("\">");
                    Plain(source.Title, dir);
                    _html.Append("</span><br>");
                    Link(source.Url);
                    _html.Append("</li>");
                }
                _html.Append("</ol></section>");
            }

            _html.Append("<div class=\"published\"><strong>").Append(Text(_labels.PublishedOn)).Append("</strong>");
            Link(ArticleUrl, ArticleUrlText);
            _html.Append("</div></footer>");
        }

        // ---- Inline content ----

        private void Inline(JsonElement content, string dir)
        {
            if (content.ValueKind != JsonValueKind.Array) return;
            foreach (var node in content.EnumerateArray())
            {
                switch (Type(node))
                {
                    case "text":
                        TextNode(node, dir);
                        break;
                    case "term":
                        Plain(node.GetProperty("text").GetString(), dir);
                        break;
                    case "mention":
                    {
                        var text = node.GetProperty("text").GetString() ?? string.Empty;
                        var handle = text.TrimStart('@');
                        if (handle.Length == 0)
                        {
                            Plain(text, dir);
                            break;
                        }
                        _html.Append("<a href=\"").Append(Attr(ProfileUrl(handle))).Append("\"><bdi>").Append(Text(text)).Append("</bdi></a>");
                        break;
                    }
                    case "hardBreak":
                        _html.Append("<br>");
                        break;
                }
            }
        }

        private void TextNode(JsonElement node, string dir)
        {
            var text = node.GetProperty("text").GetString() ?? string.Empty;
            var marks = new List<(string Type, string? Href)>();
            if (node.TryGetProperty("marks", out var array) && array.ValueKind == JsonValueKind.Array)
            {
                foreach (var mark in array.EnumerateArray())
                    marks.Add((Str(mark, "type") ?? string.Empty, Str(mark, "href")));
            }

            // Inline code is isolated as a whole and goes innermost; its text is never split.
            var isCode = marks.Any(m => m.Type == "code");
            var ordered = marks.Where(m => m.Type != "code").ToList();
            var closers = new Stack<string>();
            foreach (var (type, href) in ordered)
            {
                switch (type)
                {
                    case "bold": _html.Append("<strong>"); closers.Push("</strong>"); break;
                    case "italic": _html.Append("<em>"); closers.Push("</em>"); break;
                    case "strike": _html.Append("<s>"); closers.Push("</s>"); break;
                    case "highlight": _html.Append("<mark>"); closers.Push("</mark>"); break;
                    case "link" when SafeUrl(href) is { } url:
                        _html.Append("<a href=\"").Append(Attr(url)).Append("\">");
                        closers.Push("</a>");
                        break;
                }
            }

            if (isCode) _html.Append("<code class=\"inline\" dir=\"ltr\">").Append(Text(text)).Append("</code>");
            else Plain(text, dir);

            while (closers.Count > 0) _html.Append(closers.Pop());
        }

        /// <summary>Text with runs in the opposite direction isolated in <c>&lt;bdi&gt;</c> (§14.2 rule 2).</summary>
        private void Plain(string? text, string dir)
        {
            if (string.IsNullOrEmpty(text)) return;
            foreach (var segment in BidiText.Segment(text, dir))
            {
                if (segment.Isolate) _html.Append("<bdi>").Append(Text(segment.Text)).Append("</bdi>");
                else _html.Append(Text(segment.Text));
            }
        }

        /// <summary>A full, clickable URL on its own line, always LTR; a non-http(s) value is shown as text only.</summary>
        private void Link(string? url, string? text = null)
        {
            if (string.IsNullOrEmpty(url)) return;
            if (SafeUrl(url) is { } safe)
                _html.Append("<a class=\"url\" dir=\"ltr\" href=\"").Append(Attr(safe)).Append("\"><bdi>").Append(Text(text ?? safe)).Append("</bdi></a>");
            else
                _html.Append("<span class=\"url\" dir=\"ltr\"><bdi>").Append(Text(url)).Append("</bdi></span>");
        }

        private static IReadOnlySet<int> HighlightLines(JsonElement block) =>
            block.TryGetProperty("highlightLines", out var lines) && lines.ValueKind == JsonValueKind.Array
                ? lines.EnumerateArray().Where(l => l.ValueKind == JsonValueKind.Number).Select(l => l.GetInt32()).ToHashSet()
                : new HashSet<int>();

        private static string LanguageLabel(string language) => CodeLanguages.GetValueOrDefault(language, language);

        /// <summary>A code line's leading whitespace in columns (a tab goes to the next stop of 4), at most <see cref="MaxCodeIndent"/>.</summary>
        private static int CodeIndent(string line)
        {
            var columns = 0;
            foreach (var c in line)
            {
                if (c == ' ') columns++;
                else if (c == '\t') columns += 4 - columns % 4;
                else break;
            }
            return Math.Min(columns, MaxCodeIndent);
        }
    }

    private static string? Type(JsonElement node) => Str(node, "type");

    private static string Id(JsonElement block) => Str(block, "id") ?? string.Empty;

    private static string? Str(JsonElement node, string property) =>
        node.ValueKind == JsonValueKind.Object && node.TryGetProperty(property, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;

    /// <summary>The words printed in the file, in the article's language (SPEC F33: not the app's).</summary>
    private sealed record Labels(
        string Summary,
        string Sources,
        string Attachments,
        string PublishedOn,
        string HealthDisclaimer,
        string Verified,
        string AiAssisted,
        string Image,
        string YouTube,
        string Gist,
        bool Arabic)
    {
        private static readonly string[] ArabicMonths =
            ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"];

        // The AI-assisted label reads like the reader's trust row (web article.aiAssisted, mobile aiAssisted).
        private static readonly Labels ArabicLabels = new(
            "الخلاصة", "المصادر", "المرفقات", "منشور على ReadIn", "المعلومات دي للتوعية ولا تغني عن استشارة الطبيب.",
            "موثّق", "بمساعدة AI", "صورة", "فيديو YouTube", "Gist على GitHub", Arabic: true);

        private static readonly Labels EnglishLabels = new(
            "TL;DR", "Sources", "Attachments", "Published on ReadIn",
            "This information is for awareness only and is not a substitute for a doctor's advice.",
            "Verified", "AI-assisted", "Image", "YouTube video", "GitHub Gist", Arabic: false);

        public static Labels For(string language) => language == "en" ? EnglishLabels : ArabicLabels;

        /// <summary>Western digits everywhere (§14.2 rule 4).</summary>
        public string Date(DateOnly date) => Arabic
            ? string.Create(CultureInfo.InvariantCulture, $"{date.Day} {ArabicMonths[date.Month - 1]} {date.Year}")
            : date.ToString("MMMM d, yyyy", CultureInfo.InvariantCulture);

        public string ReadingTime(int minutes)
        {
            var n = Math.Max(1, minutes);
            if (!Arabic) return string.Create(CultureInfo.InvariantCulture, $"{n} min read");
            return n switch
            {
                1 => "دقيقة قراءة",
                2 => "دقيقتين قراءة",
                <= 10 => string.Create(CultureInfo.InvariantCulture, $"{n} دقايق قراءة"),
                _ => string.Create(CultureInfo.InvariantCulture, $"{n} دقيقة قراءة"),
            };
        }

        public string Pages(int count)
        {
            if (!Arabic) return string.Create(CultureInfo.InvariantCulture, $"{count} {(count == 1 ? "page" : "pages")}");
            return count switch
            {
                1 => "صفحة واحدة",
                2 => "صفحتين",
                >= 3 and <= 10 => string.Create(CultureInfo.InvariantCulture, $"{count} صفحات"),
                _ => string.Create(CultureInfo.InvariantCulture, $"{count} صفحة"),
            };
        }

        public string Callout(string variant) => (Arabic, variant) switch
        {
            (true, "tip") => "نصيحة",
            (true, "warning") => "تحذير",
            (true, "danger") => "خطر",
            (true, _) => "معلومة",
            (false, "tip") => "Tip",
            (false, "warning") => "Warning",
            (false, "danger") => "Danger",
            _ => "Info",
        };
    }
}

/// <summary>The large fallback fonts a page declares only when its text needs them (see <see cref="ArticlePdfHtml.FallbacksFor"/>).</summary>
[Flags]
internal enum PdfFallbacks
{
    None = 0,

    /// <summary>Noto Color Emoji.</summary>
    Emoji = 1,

    /// <summary>Noto Sans Symbols 2 and Noto Sans Math.</summary>
    Symbols = 2,

    All = Emoji | Symbols,
}
