using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.UnitTests.Notifications;

/// <summary>
/// <c>support_reply</c> and <c>support_ticket</c> (SPEC F35, F17): the push texts (support stays anonymous to the member), the
/// links to the member's ticket and the console's, the data clients get, and who can set them.
/// </summary>
public sealed class SupportNotificationTests
{
    private static readonly Guid TicketId = Guid.Parse("0195f3a0-0000-7000-8000-0000000000f5");

    private static readonly NotificationData Data = new() { TicketId = TicketId, TicketNumber = 12, Subject = "Can't sign in", SourceKey = "m:x" };

    [Fact]
    public void A_reply_is_from_support_with_the_ticket_as_its_body()
    {
        var input = new NotificationTexts.Input(null, 0, null, null, Data);

        NotificationTexts.For(NotificationTypes.SupportReply, english: false, input)
            .Should().Be(("ردّ فريق الدعم على تذكرتك", "#12 · ⁨Can't sign in⁩"));
        NotificationTexts.For(NotificationTypes.SupportReply, english: true, input)
            .Should().Be(("Support replied to your ticket", "#12 · ⁨Can't sign in⁩"));
    }

    [Fact]
    public void Closing_has_its_own_title()
    {
        var input = new NotificationTexts.Input(null, 0, null, null, Data with { Closed = true });

        NotificationTexts.For(NotificationTypes.SupportReply, english: false, input).Title.Should().Be("أُغلقت تذكرتك");
        NotificationTexts.For(NotificationTypes.SupportReply, english: true, input).Title.Should().Be("Your ticket was closed");
    }

    [Fact]
    public void A_new_support_message_names_the_member_in_an_isolate()
    {
        var input = new NotificationTexts.Input("Ahmed", 1, null, null, Data);

        NotificationTexts.For(NotificationTypes.SupportTicket, english: false, input)
            .Should().Be(("رسالة دعم جديدة من ⁨Ahmed⁩", "#12 · ⁨Can't sign in⁩"));
        NotificationTexts.For(NotificationTypes.SupportTicket, english: true, input).Title.Should().Be("New support message from ⁨Ahmed⁩");
    }

    [Fact]
    public void Links_open_the_members_ticket_or_the_consoles()
    {
        NotificationLinks.For(NotificationTypes.SupportReply, 0, null, "me", null, null, ticketId: TicketId)
            .Should().Be($"readin://support/{TicketId}");
        NotificationLinks.For(NotificationTypes.SupportTicket, 1, "ahmed", "admin", null, null, ticketId: TicketId)
            .Should().Be($"readin://admin/support/{TicketId}");
        NotificationLinks.For(NotificationTypes.SupportReply, 0, null, "me", null, null).Should().Be(NotificationLinks.Center);
    }

    [Fact]
    public void Clients_get_the_ticket_but_never_the_source_key()
    {
        var round = NotificationData.Parse(Data.Serialize());
        round.SourceKey.Should().Be("m:x");

        var dto = round.ToDto("en");
        (dto.TicketId, dto.TicketNumber, dto.Subject, dto.Closed).Should().Be((TicketId, 12, "Can't sign in", null));
        System.Text.Json.JsonSerializer.Serialize(dto, new System.Text.Json.JsonSerializerOptions(System.Text.Json.JsonSerializerDefaults.Web))
            .Should().NotContain("source", "the source key stays on the server");
    }

    [Fact]
    public void Support_replies_always_come_and_new_tickets_are_a_setting_of_support_staff_only()
    {
        NotificationTypes.IsConfigurable(NotificationTypes.SupportReply).Should().BeFalse();
        NotificationTypes.ConfigurableFor(managesSupport: true).Should().Contain(NotificationTypes.SupportTicket);
        NotificationTypes.ConfigurableFor(managesSupport: false).Should().NotContain(NotificationTypes.SupportTicket);
        NotificationTypes.IgnoresQuietHours(NotificationTypes.SupportReply).Should().BeFalse();
    }
}
