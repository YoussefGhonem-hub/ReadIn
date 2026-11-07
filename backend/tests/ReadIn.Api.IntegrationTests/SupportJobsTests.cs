using System.Net;
using System.Net.Http.Headers;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Support;
using ReadIn.Infrastructure.Jobs;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F35 jobs against SQL Server: auto-close 14 days after the last support reply (only Answered tickets with nothing from the
/// member since), and retention: tickets closed more than a year ago go with their screenshots, and orphaned screenshots
/// older than a day go too.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class SupportJobsTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private async Task<(Guid Id, Guid MessageId)> TicketAsync(HttpClient client, bool withScreenshot = false)
    {
        var form = new MultipartFormDataContent
        {
            { new StringContent("other"), "category" },
            { new StringContent("A job test ticket"), "subject" },
            { new StringContent("Something to keep for a while."), "message" },
        };
        if (withScreenshot)
        {
            var file = new ByteArrayContent(File.ReadAllBytes(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", "small.png")));
            file.Headers.ContentType = new MediaTypeHeaderValue("image/png");
            form.Add(file, "screenshots", "s.png");
        }
        var response = await client.PostAsync("/api/v1/support/tickets", form, Ct);
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        var ticket = JsonNode.Parse(body)!;
        return (ticket["id"]!.GetValue<Guid>(), ticket["messages"]![0]!["id"]!.GetValue<Guid>());
    }

    private Task ChangeTicketAsync(Guid id, Action<SupportTicket> change) => api.InDbAsync(async db =>
    {
        var ticket = await db.SupportTickets.SingleAsync(t => t.Id == id, Ct);
        change(ticket);
        await db.SaveChangesAsync(Ct);
    });

    private async Task<T> RunAsync<TJob, T>(Func<TJob, Task<T>> run) where TJob : notnull
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await run(scope.ServiceProvider.GetRequiredService<TJob>());
    }

    [Fact]
    public async Task Answered_tickets_close_14_days_after_the_last_reply_with_nothing_from_the_member()
    {
        var member = await api.UserAsync("Quiet Member");
        var adminId = (await api.SuperAdminAsync("Job Agent")).Id;
        var (due, _) = await TicketAsync(member.Client);
        var (recent, _) = await TicketAsync(member.Client);
        var (wroteBack, _) = await TicketAsync(member.Client);
        var (unanswered, _) = await TicketAsync(member.Client);
        await ChangeTicketAsync(due, t => t.Reply(adminId, "Fixed.", DateTime.UtcNow.AddDays(-15)));
        await ChangeTicketAsync(recent, t => t.Reply(adminId, "Fixed.", DateTime.UtcNow.AddDays(-13)));
        await ChangeTicketAsync(wroteBack, t =>
        {
            t.Reply(adminId, "Fixed.", DateTime.UtcNow.AddDays(-20));
            t.AddMemberMessage("Not for me.", DateTime.UtcNow.AddDays(-19));
        });
        // The members' first messages were sent a month ago, before the (backdated) replies.
        var monthAgo = DateTime.UtcNow.AddDays(-30);
        await api.InDbAsync(db => db.SupportTickets.Where(t => t.UserId == member.Id && t.Id != wroteBack)
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.CreatedAt, monthAgo).SetProperty(t => t.LastUserMessageAt, monthAgo), Ct));

        (await RunAsync<SupportAutoCloseJob, int>(job => job.RunAsync(Ct))).Should().BeGreaterThanOrEqualTo(1);

        var statuses = await api.InDbAsync(db => db.SupportTickets.AsNoTracking().Where(t => t.UserId == member.Id)
            .ToDictionaryAsync(t => t.Id, t => (t.Status, t.ClosedBy), Ct));
        statuses[due].Should().Be((SupportTicketStatus.Closed, SupportClosedBy.Auto));
        statuses[recent].Should().Be((SupportTicketStatus.Answered, (SupportClosedBy?)null));
        statuses[wroteBack].Should().Be((SupportTicketStatus.Open, (SupportClosedBy?)null));
        statuses[unanswered].Should().Be((SupportTicketStatus.Open, (SupportClosedBy?)null));

        // Auto-closed: the member can still reopen it.
        (await member.Client.PostAsync($"/api/v1/support/tickets/{due}/reopen", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task Tickets_closed_over_a_year_ago_go_with_their_screenshots_and_orphans_are_swept()
    {
        var member = await api.UserAsync("Old Member");
        var (old, oldMessage) = await TicketAsync(member.Client, withScreenshot: true);
        var (young, youngMessage) = await TicketAsync(member.Client, withScreenshot: true);
        var (open, _) = await TicketAsync(member.Client);
        foreach (var id in new[] { old, young }) await ChangeTicketAsync(id, t => t.CloseByMember(DateTime.UtcNow));
        var yearAgo = DateTime.UtcNow.AddDays(-366);
        var monthsAgo = DateTime.UtcNow.AddDays(-300);
        await api.InDbAsync(db => db.SupportTickets.Where(t => t.Id == old).ExecuteUpdateAsync(s => s.SetProperty(t => t.ClosedAt, yearAgo), Ct));
        await api.InDbAsync(db => db.SupportTickets.Where(t => t.Id == young).ExecuteUpdateAsync(s => s.SetProperty(t => t.ClosedAt, monthsAgo), Ct));

        // An orphan from a request that died after writing (two days old) and one being written right now.
        var staleOrphan = Path.Combine(api.PrivatePath, "support", Guid.NewGuid().ToString(), "1.png");
        var freshOrphan = Path.Combine(api.PrivatePath, "support", Guid.NewGuid().ToString(), "1.png");
        foreach (var orphan in new[] { staleOrphan, freshOrphan })
        {
            Directory.CreateDirectory(Path.GetDirectoryName(orphan)!);
            await File.WriteAllBytesAsync(orphan, [1, 2, 3], Ct);
        }
        File.SetLastWriteTimeUtc(staleOrphan, DateTime.UtcNow.AddDays(-2));

        var (tickets, orphans) = await RunAsync<SupportRetentionJob, (int, int)>(job => job.RunAsync(Ct));
        tickets.Should().BeGreaterThanOrEqualTo(1);
        orphans.Should().BeGreaterThanOrEqualTo(1);

        var left = await api.InDbAsync(db => db.SupportTickets.AsNoTracking().Where(t => t.UserId == member.Id).Select(t => t.Id).ToListAsync(Ct));
        left.Should().BeEquivalentTo([young, open]);
        (await api.InDbAsync(db => db.SupportMessages.AnyAsync(m => m.TicketId == old, Ct))).Should().BeFalse();
        Directory.Exists(Path.Combine(api.PrivatePath, "support", oldMessage.ToString())).Should().BeFalse();
        File.Exists(Path.Combine(api.PrivatePath, "support", youngMessage.ToString(), "1.png")).Should().BeTrue();
        File.Exists(staleOrphan).Should().BeFalse();
        File.Exists(freshOrphan).Should().BeTrue("a file a request is still saving stays");
        File.Delete(freshOrphan);
    }
}
