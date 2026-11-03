using FirebaseAdmin.Messaging;
using Microsoft.Extensions.Hosting;
using NSubstitute;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Feed.DailyArticle;
using ReadIn.Infrastructure.Identity;
using ReadIn.Infrastructure.Push;

namespace ReadIn.Infrastructure.UnitTests.Push;

public sealed class FcmPushSenderTests
{
    private static readonly PushNotification Daily = DailyArticlePush.Create(
        ["token-1"], "ar", Guid.Parse("0a1b2c3d-0000-0000-0000-000000000001"), "rag-vs-fine-tuning", "RAG ولا Fine-tuning؟", "ar-EG",
        TimeSpan.FromHours(6));

    [Theory]
    [InlineData(MessagingErrorCode.Unregistered, "Requested entity was not found.", true)]
    [InlineData(MessagingErrorCode.SenderIdMismatch, "SenderId mismatch", true)]
    [InlineData(MessagingErrorCode.InvalidArgument, "The registration token is not a valid FCM registration token", true)]
    [InlineData(MessagingErrorCode.InvalidArgument, "Request contains an invalid argument: data too large", false)]
    [InlineData(MessagingErrorCode.Unavailable, "The service is currently unavailable.", false)]
    [InlineData(MessagingErrorCode.QuotaExceeded, "Quota exceeded", false)]
    [InlineData(null, null, false)]
    public void Only_dead_or_malformed_tokens_are_deleted(MessagingErrorCode? code, string? message, bool invalid) =>
        FcmPushSender.IsInvalidToken(code, message).Should().Be(invalid);

    [Fact]
    public void The_message_targets_the_app_channel_and_collapses_per_kind()
    {
        var message = FcmPushSender.ToMessage(Daily, "token-1");

        message.Notification.Title.Should().Be("مقال النهارده جاهز ☕");
        message.Notification.Body.Should().Be("RAG ولا Fine-tuning؟");
        message.Data["type"].Should().Be("daily_article");
        message.Data["link"].Should().Be("readin://a/rag-vs-fine-tuning");

        message.Android.Notification.ChannelId.Should().Be("readin_default", "the channel the mobile app creates");
        message.Android.CollapseKey.Should().Be("daily_article");
        message.Android.TimeToLive.Should().Be(TimeSpan.FromHours(6));
        message.Apns.Headers["apns-collapse-id"].Should().Be("daily_article");
        message.Apns.Headers["apns-push-type"].Should().Be("alert");
        message.Apns.Aps.Sound.Should().Be("default");
        message.Webpush.Headers["TTL"].Should().Be("21600");
        message.Webpush.Data["tag"].Should().Be("daily_article", "the service worker replaces an older daily push");
        message.Webpush.Data["slug"].Should().Be("rag-vs-fine-tuning");
    }

    [Theory]
    [InlineData("Development", true, null, false)] // the emulator has no FCM
    [InlineData("Testing", true, null, false)]
    [InlineData("Development", false, null, false)] // no key: log instead of failing on every run
    [InlineData("Development", false, "{\"type\":\"service_account\"}", true)]
    [InlineData("Production", false, null, true)] // Application Default Credentials
    [InlineData("Production", false, "e30=", true)]
    public void Fcm_is_used_unless_there_is_nothing_to_send_with(string environment, bool emulator, string? key, bool fcm)
    {
        var host = Substitute.For<IHostEnvironment>();
        host.EnvironmentName.Returns(environment);

        PushRegistration.UsesFcm(new FirebaseOptions { UseEmulator = emulator, ServiceAccountJson = key }, host).Should().Be(fcm);
    }
}
