using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Verification;
using ReadIn.Domain.Common;
using ReadIn.Domain.Verification;
using SkiaSharp;
using UglyToad.PdfPig.Content;
using UglyToad.PdfPig.Core;
using UglyToad.PdfPig.Fonts.Standard14Fonts;
using UglyToad.PdfPig.Writer;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Development only (SPEC F19, §18.2): an admin verification queue that isn't empty locally. Three pending requests:
/// writer1 (a LinkedIn URL and a PNG certificate), writer2 (a GitHub URL only) and writer3 (a PDF syndicate card only);
/// reader5's request was rejected with a reason and the verified writer's was approved, both by the demo SuperAdmin, so every
/// tab and the user page's states have data. The proof files are drawn here and go to the private store. Writes no outbox
/// events, so nothing is notified or pushed. A re-run replaces the requests of these users, with their files.
/// </summary>
internal sealed class DemoVerificationSeeder(AppDbContext db, IPrivateFileStorage storage, TimeProvider clock) : ISeeder
{
    private enum Proof
    {
        None,
        Png,
        Pdf,
    }

    private sealed record DemoRequest(
        string Handle,
        string Field,
        string JobTitle,
        string? ProofUrl,
        Proof File,
        string? FileName,
        string? Note,
        double HoursAgo,
        VerificationStatus Status = VerificationStatus.Pending,
        string? Reason = null,
        double DecidedHoursAgo = 0);

    private static readonly DemoRequest[] Requests =
    [
        new("writer1", "frontend", "Senior Frontend Engineer (Angular)", "https://www.linkedin.com/in/readin-demo-writer1", Proof.Png,
            "Angular certificate.png", "شغال بـ Angular من 6 سنين، ومعايا شهادة Google Developer Expert.", 30),
        new("writer2", "dotnet", "Backend Developer — .NET", "https://github.com/readin-demo-writer2", Proof.None, null, null, 20),
        new("writer3", "databases", "Data Engineer", null, Proof.Pdf, "كارنيه النقابة.pdf", "كارنيه نقابة المهندسين مرفق.", 5),
        new("reader5", "frontend", "Junior Developer", "https://github.com/readin-demo-reader5", Proof.None, null, null, 96,
            VerificationStatus.Rejected, "اللينك مش بيوضّح خبرة في المجال ده. ضيف شغلك أو شهادة وابعت الطلب تاني.", 72),
        new("writer.verified", "mobile", "Flutter Developer", "https://github.com/readin-demo-writer-verified", Proof.None, null, null, 400,
            VerificationStatus.Approved, DecidedHoursAgo: 380),
    ];

    public string Name => "demo-verification";
    public int Order => 14;
    public int Version => 2; // 2: decided by the SuperAdmin (there is no demo admin any more)

    public bool AppliesTo(IHostEnvironment environment) => environment.IsDevelopment();

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) => Task.FromResult(SeedChecksum.Of(
    [
        $"v{Version}",
        .. Requests.Select(r => $"{r.Handle}|{r.Field}|{r.JobTitle}|{r.ProofUrl}|{r.File}|{r.FileName}|{r.Note}|{r.HoursAgo}|{r.Status}|{r.Reason}|{r.DecidedHoursAgo}"),
    ]));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var emails = Requests.Select(r => r.Handle).Select(h => $"{h}@readin.test").ToList();
        var users = await db.Users.AsNoTracking()
            .Where(u => u.Email != null && emails.Contains(u.Email))
            .ToDictionaryAsync(u => u.Email!.Replace("@readin.test", string.Empty), u => u.Id, cancellationToken);
        var fields = await db.Fields.AsNoTracking().ToDictionaryAsync(f => f.Slug, f => f.Id, cancellationToken);
        var adminId = await db.Users.AsNoTracking().Where(u => u.Id == SystemUsers.SuperAdminId).Select(u => u.Id).FirstOrDefaultAsync(cancellationToken);

        // A re-run replaces these users' requests, files included.
        var userIds = Requests.Select(r => users.GetValueOrDefault(r.Handle)).Where(id => id != Guid.Empty).ToList();
        var oldFiles = await db.VerificationRequests
            .Where(r => userIds.Contains(r.UserId) && r.ProofFilePath != null)
            .Select(r => r.ProofFilePath!)
            .ToListAsync(cancellationToken);
        await db.VerificationRequests.Where(r => userIds.Contains(r.UserId)).ExecuteDeleteAsync(cancellationToken);
        foreach (var file in oldFiles) await storage.DeleteAsync(file, cancellationToken);

        var now = clock.GetUtcNow().UtcDateTime;
        foreach (var demo in Requests)
        {
            if (!users.TryGetValue(demo.Handle, out var userId) || !fields.TryGetValue(demo.Field, out var fieldId)) continue;
            if (demo.Status != VerificationStatus.Pending && adminId == Guid.Empty) continue;

            var request = VerificationRequest.Submit(userId, fieldId, demo.JobTitle, demo.ProofUrl, demo.File != Proof.None, demo.Note,
                now.AddHours(-demo.HoursAgo)).Value;
            db.VerificationRequests.Add(request); // assigns the id the file is named after

            if (demo.File != Proof.None)
            {
                var (bytes, format) = demo.File == Proof.Png ? (DrawCertificate(), VerificationProofFormat.Png) : (BuildCard(), VerificationProofFormat.Pdf);
                var path = VerificationProofs.PathFor(request.Id, format);
                using (var content = new MemoryStream(bytes, writable: false))
                    await storage.SaveAsync(path, content, cancellationToken);
                request.AttachProofFile(path, format.ContentType, bytes.Length, VerificationProofs.DisplayName(demo.FileName, format));
            }

            var decidedAt = now.AddHours(-demo.DecidedHoursAgo);
            if (demo.Status == VerificationStatus.Approved) request.Approve(adminId, decidedAt);
            if (demo.Status == VerificationStatus.Rejected) request.Reject(adminId, demo.Reason!, decidedAt);
        }

        // Demo data never goes through the outbox: no verification_result notification or push.
        foreach (var entry in db.ChangeTracker.Entries<AggregateRoot>()) entry.Entity.ClearDomainEvents();
        await db.SaveChangesAsync(cancellationToken);
        return true;
    }

    /// <summary>A certificate-like picture: a frame, a title and a seal.</summary>
    private static byte[] DrawCertificate()
    {
        using var bitmap = new SKBitmap(900, 600);
        using var canvas = new SKCanvas(bitmap);
        canvas.Clear(new SKColor(252, 248, 238));

        using var frame = new SKPaint { Color = new SKColor(15, 94, 82), IsAntialias = true, Style = SKPaintStyle.Stroke, StrokeWidth = 14 };
        canvas.DrawRect(30, 30, 840, 540, frame);

        using var title = new SKFont(SKTypeface.Default, 54);
        using var text = new SKFont(SKTypeface.Default, 28);
        using var ink = new SKPaint { Color = new SKColor(26, 26, 26), IsAntialias = true };
        canvas.DrawText("Certificate of Expertise", 450, 190, SKTextAlign.Center, title, ink);
        canvas.DrawText("Angular — Google Developer Expert", 450, 280, SKTextAlign.Center, text, ink);
        canvas.DrawText("ReadIn demo proof (not a real document)", 450, 340, SKTextAlign.Center, text, ink);

        using var seal = new SKPaint { Color = new SKColor(242, 169, 59), IsAntialias = true };
        canvas.DrawCircle(450, 455, 60, seal);

        using var data = bitmap.Encode(SKEncodedImageFormat.Png, 100);
        return data.ToArray();
    }

    /// <summary>A one-page, card-like PDF (Standard 14 fonts only, so no font file is needed).</summary>
    private static byte[] BuildCard()
    {
        var builder = new PdfDocumentBuilder();
        var bold = builder.AddStandard14Font(Standard14Font.HelveticaBold);
        var regular = builder.AddStandard14Font(Standard14Font.Helvetica);
        var page = builder.AddPage(PageSize.A6, isPortrait: false);
        page.SetTextAndFillColor(15, 94, 82);
        page.DrawRectangle(new PdfPoint(0, 230), 420, 68, 0, fill: true);
        page.SetTextAndFillColor(255, 255, 255);
        page.AddText("Engineers Syndicate", 18, new PdfPoint(20, 255), bold);
        page.SetTextAndFillColor(26, 26, 26);
        page.AddText("Member: Writer 3", 13, new PdfPoint(20, 190), regular);
        page.AddText("Data engineering", 13, new PdfPoint(20, 168), regular);
        page.AddText("ReadIn demo proof (not a real document)", 10, new PdfPoint(20, 30), regular);
        return builder.Build();
    }
}
