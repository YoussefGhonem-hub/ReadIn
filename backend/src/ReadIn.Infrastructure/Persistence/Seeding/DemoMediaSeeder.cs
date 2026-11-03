using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Media;
using ReadIn.Infrastructure.Identity;
using ReadIn.Infrastructure.Media;
using SkiaSharp;
using UglyToad.PdfPig.Content;
using UglyToad.PdfPig.Core;
using UglyToad.PdfPig.Fonts.Standard14Fonts;
using UglyToad.PdfPig.Writer;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Local only (demo data, ADR 0005): two demo posts that show the media pipeline in development (ADR 0011). Writer 1
/// posts three photos (carousel); the verified writer posts a 12-page PDF (page carousel). The images are drawn here
/// and go through the real processor; the PDF is rendered by the real job. Idempotent by article slug.
/// </summary>
internal sealed partial class DemoMediaSeeder(
    AppDbContext db,
    IImageProcessor images,
    IFileStorage storage,
    IRDocProcessor rdoc,
    DocumentProcessingJob documents,
    IOptions<FirebaseOptions> firebase,
    TimeProvider clock,
    ILogger<DemoMediaSeeder> logger) : ISeeder
{
    private const string ImagesSlug = "demo-media-angular-workshop";
    private const string DocumentSlug = "demo-media-clean-architecture-pdf";

    public string Name => "demo-media";
    public int Order => 9;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => SeedEnvironments.AllowsDemoData(environment, firebase.Value);

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        Task.FromResult(SeedChecksum.Of([ImagesSlug, DocumentSlug, "v1"]));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        await SeedImagesPostAsync(now, cancellationToken);
        await SeedDocumentPostAsync(now, cancellationToken);
        return true;
    }

    private async Task SeedImagesPostAsync(DateTime now, CancellationToken ct)
    {
        if (await db.Articles.IgnoreQueryFilters().AnyAsync(a => a.Slug == ImagesSlug, ct)) return;
        if (await WriterAsync("writer1@readin.test", ct) is not { } writerId) return;

        (string Alt, string Caption, SKColor From, SKColor To)[] photos =
        [
            ("Speakers on stage at an Angular workshop", "ورشة Angular Signals", new SKColor(0x0F, 0x5E, 0x52), new SKColor(0x3F, 0xB8, 0xA3)),
            ("Attendees pairing on laptops", "Pair programming على Signal Store", new SKColor(0xF2, 0xA9, 0x3B), new SKColor(0xC0, 0x39, 0x2B)),
            ("Whiteboard with a component diagram", "Standalone components diagram", new SKColor(0x1E, 0x25, 0x30), new SKColor(0x3F, 0xB8, 0xA3)),
        ];

        var assets = new List<MediaAsset>();
        foreach (var (photo, index) in photos.Select((p, i) => (p, i)))
        {
            var bytes = DrawPhoto(photo.From, photo.To, index + 1);
            var processed = images.Process(new MemoryStream(bytes), ImageFormat.Png, UploadPurpose.ArticleImage);
            if (processed.IsFailure) return;

            var id = Guid.NewGuid();
            var variants = new List<MediaVariant>();
            foreach (var image in processed.Value.Variants)
            {
                var path = UploadPath.Create(UploadPurpose.ArticleImage, now, id, image.Size).Value;
                await storage.SaveAsync(path, new MemoryStream(image.Content), ct);
                variants.Add(new MediaVariant(image.Width, image.Height, path, image.Content.Length));
            }

            var asset = MediaAsset.StartImage(writerId, MediaPurpose.Image, bytes.Length);
            asset.CompleteImage(processed.Value.Width, processed.Value.Height, processed.Value.BlurHash, variants);
            db.MediaAssets.Add(asset);
            assets.Add(asset);
        }
        await db.SaveChangesAsync(ct);

        await PublishAsync(writerId, "frontend", ImagesSlug, "ar-EG",
            "صور من ورشة Angular Signals",
            "كانت ورشة جميلة عن Signals و Standalone components. دي شوية صور من اليوم، اسحب عشان تشوف الباقي.",
            [.. assets.Select((a, i) => new AttachmentCandidate(a.Id, a.Kind, a.Status, a.OwnerId, i, photos[i].Caption, photos[i].Alt))],
            now, ct);
    }

    private async Task SeedDocumentPostAsync(DateTime now, CancellationToken ct)
    {
        if (await db.Articles.IgnoreQueryFilters().AnyAsync(a => a.Slug == DocumentSlug, ct)) return;
        if (await WriterAsync("writer.verified@readin.test", ct) is not { } writerId) return;

        var pdf = BuildPdf(pages: 12);
        var asset = MediaAsset.StartDocument(writerId, "Clean Architecture cheat sheet", allowDownload: true, pdf.Length, pageCount: 12);
        var path = DocumentPath.Create(now, Guid.NewGuid());
        await storage.SaveAsync(path.Original, new MemoryStream(pdf), ct);
        asset.StartProcessing(path.Original);
        db.MediaAssets.Add(asset);
        await db.SaveChangesAsync(ct);

        await documents.RunAsync(asset.Id, ct);
        if (asset.Status != MediaStatus.Ready)
        {
            LogDocumentNotReady(logger, asset.FailureReason);
            return;
        }

        await PublishAsync(writerId, "dotnet", DocumentSlug, "en",
            "Clean Architecture in 12 slides",
            "A one-page-per-idea summary of Clean Architecture + CQRS in ASP.NET Core. Swipe through the slides or download the PDF.",
            [new AttachmentCandidate(asset.Id, asset.Kind, asset.Status, asset.OwnerId, 0, null, null)],
            now, ct);
    }

    private async Task<Guid?> WriterAsync(string email, CancellationToken ct) =>
        await db.Users.Where(u => u.Email == email).Select(u => (Guid?)u.Id).FirstOrDefaultAsync(ct);

    private async Task PublishAsync(Guid authorId, string fieldSlug, string slug, string language, string title, string text,
        IReadOnlyList<AttachmentCandidate> attachments, DateTime now, CancellationToken ct)
    {
        var field = await db.Fields.FirstOrDefaultAsync(f => f.Slug == fieldSlug && f.IsEnabled, ct)
                    ?? await db.Fields.FirstAsync(f => f.IsEnabled, ct);

        var document = JsonSerializer.SerializeToElement(new
        {
            version = 1,
            language,
            blocks = new object[] { new { id = "p1", type = "paragraph", dir = "auto", content = new[] { new { type = "text", text } } } },
        });
        var content = rdoc.Process(document, language, title);
        if (content.IsFailure) return;

        var article = Article.CreateDraft(authorId, field.Id, topicId: null, slug);
        article.AddTranslation(language, title, null, content.Value.Content);
        article.SetSources([("ReadIn demo", "https://readin.app")]);
        db.Articles.Add(article);
        await db.SaveChangesAsync(ct);

        if (article.SetAttachments(attachments).IsFailure || article.Publish(field, now).IsFailure) return;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>A photo-like picture: a gradient, soft shapes and a label, so carousels show distinct slides.</summary>
    private static byte[] DrawPhoto(SKColor from, SKColor to, int number)
    {
        using var bitmap = new SKBitmap(1800, 1200);
        using var canvas = new SKCanvas(bitmap);
        using var shader = SKShader.CreateLinearGradient(new SKPoint(0, 0), new SKPoint(1800, 1200), [from, to], SKShaderTileMode.Clamp);
        using var background = new SKPaint { Shader = shader };
        canvas.DrawRect(0, 0, 1800, 1200, background);

        using var circles = new SKPaint { Color = SKColors.White.WithAlpha(40), IsAntialias = true };
        for (var i = 0; i < 6; i++) canvas.DrawCircle(250 + i * 260, 300 + (i % 3) * 250, 140 + i * 15, circles);

        using var font = new SKFont(SKTypeface.Default, 160);
        using var label = new SKPaint { Color = SKColors.White, IsAntialias = true };
        canvas.DrawText($"ReadIn #{number}", 120, 1050, SKTextAlign.Left, font, label);

        using var data = bitmap.Encode(SKEncodedImageFormat.Png, 100);
        return data.ToArray();
    }

    /// <summary>A slide-deck-like PDF with one idea per page (Standard 14 fonts only, so no font file is needed).</summary>
    private static byte[] BuildPdf(int pages)
    {
        string[] ideas =
        [
            "Clean Architecture", "Dependency rule", "Domain: entities and value objects", "Application: commands and queries",
            "Infrastructure: EF Core, storage, jobs", "Api: minimal endpoints", "CQRS with Mediator", "Validation pipeline",
            "Mapster projections", "Outbox for domain events", "Testing each layer", "Summary",
        ];

        var builder = new PdfDocumentBuilder();
        var bold = builder.AddStandard14Font(Standard14Font.HelveticaBold);
        var regular = builder.AddStandard14Font(Standard14Font.Helvetica);
        for (var i = 1; i <= pages; i++)
        {
            var page = builder.AddPage(PageSize.A4);
            page.SetTextAndFillColor(15, 94, 82);
            page.DrawRectangle(new PdfPoint(0, 742), 595, 100, 0, fill: true);
            page.SetTextAndFillColor(255, 255, 255);
            page.AddText($"{i} / {pages}", 14, new PdfPoint(500, 800), regular);
            page.AddText(ideas[(i - 1) % ideas.Length], 26, new PdfPoint(40, 770), bold);
            page.SetTextAndFillColor(26, 26, 26);
            page.AddText("ReadIn demo document: swipe through the pages in the feed.", 13, new PdfPoint(40, 690), regular);
            page.SetTextAndFillColor(242, 169, 59);
            page.DrawRectangle(new PdfPoint(40, 200 + i * 10), 515, 300, 0, fill: true);
        }
        return builder.Build();
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "The demo PDF could not be processed ({Reason}); the demo document post is skipped")]
    private static partial void LogDocumentNotReady(ILogger logger, string? reason);
}
