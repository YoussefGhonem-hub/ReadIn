using ReadIn.Domain.Support;

namespace ReadIn.Domain.UnitTests.Support;

/// <summary>
/// SPEC F35 statuses: a member's message moves Answered → Open, a support reply makes it Answered, notes and category changes
/// change nothing; a closed ticket takes no message; the member reopens within 30 days, support any time; the auto-close
/// rule (14 days after the last reply, nothing from the member since).
/// </summary>
public sealed class SupportTicketTests
{
    private static readonly DateTime Now = new(2026, 11, 7, 12, 0, 0, DateTimeKind.Utc);
    private static readonly Guid Member = Guid.NewGuid();
    private static readonly Guid Admin = Guid.NewGuid();

    private static SupportTicket NewTicket() =>
        SupportTicket.Open(Member, SupportCategories.AppProblem, "The app crashes", "It crashes when I open a PDF.", SupportDevice.None, Now);

    [Fact]
    public void A_new_ticket_is_open_with_the_members_first_message_and_tells_support()
    {
        var ticket = NewTicket();

        ticket.Status.Should().Be(SupportTicketStatus.Open);
        ticket.Messages.Should().ContainSingle().Which.Should().Match<SupportMessage>(m => !m.FromSupport && !m.IsInternalNote && m.AuthorId == Member);
        (ticket.CreatedAt, ticket.UpdatedAt, ticket.LastUserMessageAt).Should().Be((Now, Now, Now));
        ticket.DomainEvents.Should().ContainSingle().Which.Should().BeOfType<SupportMessagePostedDomainEvent>()
            .Which.Should().Match<SupportMessagePostedDomainEvent>(e => e.IsNewTicket && !e.FromSupport && e.UserId == Member);
    }

    [Fact]
    public void Replies_and_member_messages_move_the_status_and_notes_change_nothing()
    {
        var ticket = NewTicket();

        ticket.Reply(Admin, "Which phone?", Now.AddHours(1)).IsSuccess.Should().BeTrue();
        ticket.Status.Should().Be(SupportTicketStatus.Answered);
        ticket.LastAdminReplyAt.Should().Be(Now.AddHours(1));

        ticket.Reply(Admin, "And which version?", Now.AddHours(2)).IsSuccess.Should().BeTrue();
        ticket.Status.Should().Be(SupportTicketStatus.Answered, "another reply keeps it Answered");

        var note = ticket.AddNote(Admin, "Probably the PDF viewer.", Now.AddHours(3));
        note.IsInternalNote.Should().BeTrue();
        (ticket.Status, ticket.UpdatedAt).Should().Be((SupportTicketStatus.Answered, Now.AddHours(2)), "a note changes neither");

        ticket.AddMemberMessage("A Pixel 8.", Now.AddHours(4)).IsSuccess.Should().BeTrue();
        (ticket.Status, ticket.LastUserMessageAt, ticket.UpdatedAt).Should().Be((SupportTicketStatus.Open, Now.AddHours(4), Now.AddHours(4)));

        ticket.ChangeCategory(SupportCategories.Content).Should().BeTrue();
        ticket.ChangeCategory(SupportCategories.Content).Should().BeFalse();
        ticket.Status.Should().Be(SupportTicketStatus.Open);

        // The note raised nothing: one event per message of the member or support.
        ticket.DomainEvents.OfType<SupportMessagePostedDomainEvent>().Should().HaveCount(4);
    }

    [Fact]
    public void A_closed_ticket_takes_no_message_until_it_is_reopened()
    {
        var ticket = NewTicket();
        ticket.CloseByMember(Now).Should().BeTrue();
        ticket.CloseByMember(Now).Should().BeFalse("closing twice changes nothing");
        (ticket.ClosedBy, ticket.ClosedById).Should().Be((SupportClosedBy.Member, Member));

        ticket.AddMemberMessage("Hello?", Now).Error.Should().Be(SupportErrors.TicketClosed);
        ticket.Reply(Admin, "Hi", Now).Error.Should().Be(SupportErrors.TicketClosed);
        ticket.AddNote(Admin, "Notes still work.", Now).IsInternalNote.Should().BeTrue();

        ticket.ReopenByMember(Now.AddDays(29)).IsSuccess.Should().BeTrue();
        (ticket.Status, ticket.ClosedAt, ticket.ClosedBy).Should().Be((SupportTicketStatus.Open, (DateTime?)null, (SupportClosedBy?)null));
        ticket.ReopenByMember(Now.AddDays(29)).IsSuccess.Should().BeTrue("reopening an open ticket changes nothing");
    }

    [Fact]
    public void The_member_reopens_within_30_days_and_support_any_time()
    {
        var ticket = NewTicket();
        ticket.CloseBySupport(Admin, Now).Should().BeTrue();
        ticket.DomainEvents.OfType<SupportTicketClosedDomainEvent>().Should().ContainSingle().Which.ClosedBy.Should().Be(SupportClosedBy.Support);

        ticket.CanReopen(Now.AddDays(30)).Should().BeTrue();
        ticket.CanReopen(Now.AddDays(31)).Should().BeFalse();
        ticket.ReopenByMember(Now.AddDays(31)).Error.Should().Be(SupportErrors.ReopenExpired);
        ticket.Status.Should().Be(SupportTicketStatus.Closed);

        ticket.ReopenBySupport().Should().BeTrue();
        ticket.Status.Should().Be(SupportTicketStatus.Open);
        ticket.ReopenBySupport().Should().BeFalse();
    }

    [Fact]
    public void Auto_close_needs_an_answered_ticket_14_days_after_the_last_reply_with_nothing_from_the_member_since()
    {
        var open = NewTicket();
        open.AutoClose(Now.AddDays(30)).Should().BeFalse("nobody answered yet");

        var answered = NewTicket();
        answered.Reply(Admin, "Fixed in 1.2.", Now);
        answered.AutoClose(Now.AddDays(13)).Should().BeFalse();
        answered.AutoClose(Now.AddDays(14)).Should().BeTrue();
        (answered.ClosedBy, answered.ClosedById).Should().Be((SupportClosedBy.Auto, (Guid?)null));

        var replied = NewTicket();
        replied.Reply(Admin, "Fixed in 1.2.", Now);
        replied.AddMemberMessage("Still broken.", Now.AddDays(1));
        replied.AutoClose(Now.AddDays(20)).Should().BeFalse("the member wrote after the reply: it is Open");
    }

    [Fact]
    public void Device_details_are_cleaned_never_refused()
    {
        var device = SupportDevice.Clean(" IOS ", $"  iOS 18.1‮{new string('x', 80)}", "1.2.0+57", "FR", "  /settings/support  ");
        device.Platform.Should().Be("ios");
        device.OsVersion.Should().StartWith("iOS 18.1x").And.HaveLength(SupportDevice.MaxOsVersionLength).And.NotContain("‮");
        device.AppVersion.Should().Be("1.2.0+57");
        device.Language.Should().BeNull("only ar and en are UI languages");
        device.Screen.Should().Be("/settings/support");

        SupportDevice.Clean("windows-phone", "   ", null, "ar", "").Should().Be(new SupportDevice(null, null, null, "ar", null));
    }

    [Fact]
    public void Screenshot_paths_are_one_folder_per_message()
    {
        var id = Guid.Parse("0195f3a0-0000-7000-8000-000000000001");
        SupportAttachment.PathFor(id, 2, ".png").Should().Be("support/0195f3a0-0000-7000-8000-000000000001/2.png");
    }
}
