import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/profile/domain/entities/profile_link.dart';

/// The editor's copy of the server's link and title rules (contract "Title and social links", SPEC F14).
void main() {
  group('LinkPlatform', () {
    test('the 14 platforms, in the SPEC order, with their wire names', () {
      expect(LinkPlatform.values.map((p) => p.wire), [
        'linkedin',
        'x',
        'instagram',
        'facebook',
        'youtube',
        'tiktok',
        'snapchat',
        'threads',
        'telegram',
        'github',
        'medium',
        'behance',
        'website',
        'other',
      ]);
      expect(LinkPlatform.fromWire('github'), LinkPlatform.github);
      expect(LinkPlatform.fromWire('GitHub'), isNull);
      expect(LinkPlatform.fromWire('mastodon'), isNull);
    });

    test("a named platform's hosts and their subdomains; Website and Other take any host", () {
      expect(LinkPlatform.x.allowsHost('twitter.com'), isTrue);
      expect(LinkPlatform.x.allowsHost('mobile.twitter.com'), isTrue);
      expect(LinkPlatform.x.allowsHost('X.COM.'), isTrue);
      expect(LinkPlatform.x.allowsHost('notx.com'), isFalse);
      expect(LinkPlatform.x.allowsHost('x.com.evil.io'), isFalse);
      expect(LinkPlatform.medium.allowsHost('mona.medium.com'), isTrue);
      expect(LinkPlatform.youtube.allowsHost('youtu.be'), isTrue);
      expect(LinkPlatform.telegram.allowsHost('t.me'), isTrue);
      expect(LinkPlatform.linkedin.allowsHost('eg.linkedin.com'), isTrue);
      expect(LinkPlatform.website.allowsHost('anything.example'), isTrue);
      expect(LinkPlatform.other.allowsHost('anything.example'), isTrue);
    });
  });

  group('ProfileLinkRules', () {
    String? url(LinkPlatform platform, String value) => ProfileLinkRules.urlProblem(platform, ProfileLinkRules.normalizeUrl(value));

    test('no scheme gets https://; trimmed; empty stays empty', () {
      expect(ProfileLinkRules.normalizeUrl(' instagram.com/mona '), 'https://instagram.com/mona');
      expect(ProfileLinkRules.normalizeUrl('https://x.com/a'), 'https://x.com/a');
      expect(ProfileLinkRules.normalizeUrl('http://x.com/a'), 'http://x.com/a');
      expect(ProfileLinkRules.normalizeUrl('   '), '');
    });

    test('each URL rule, in the server order', () {
      expect(url(LinkPlatform.instagram, 'instagram.com/mona'), isNull);
      expect(url(LinkPlatform.website, ''), FailureCodes.validationRequired);
      expect(url(LinkPlatform.website, 'https://a.dev/${'x' * 490}'), FailureCodes.linkTooLong);
      expect(url(LinkPlatform.github, 'http://github.com/mona'), FailureCodes.linkHttpsRequired);
      expect(url(LinkPlatform.website, 'ftp://files.mona.dev'), FailureCodes.linkHttpsRequired);
      expect(url(LinkPlatform.website, 'https://mona dev.com'), FailureCodes.linkUrlInvalid);
      expect(url(LinkPlatform.website, 'https://localhost/x'), FailureCodes.linkUrlInvalid);
      expect(url(LinkPlatform.website, 'https://192.168.1.10/x'), FailureCodes.linkUrlInvalid);
      expect(url(LinkPlatform.website, 'https://mona.dev:8443/x'), FailureCodes.linkUrlInvalid);
      expect(url(LinkPlatform.website, 'https://mona.dev:443/x'), isNull);
      expect(url(LinkPlatform.github, 'https://user:secret@github.com/mona'), FailureCodes.linkUrlInvalid);
      expect(url(LinkPlatform.instagram, 'https://instagram.evil.com/mona'), FailureCodes.linkHostMismatch);
      expect(url(LinkPlatform.facebook, 'https://fb.me/mona'), isNull);
      expect(url(LinkPlatform.other, 'https://مثال.مصر/صفحة'), isNull);
    });

    test('labels: Other only, 2–30 characters on one line', () {
      expect(ProfileLinkRules.labelProblem(LinkPlatform.other, null), FailureCodes.linkLabelRequired);
      expect(ProfileLinkRules.labelProblem(LinkPlatform.other, '  '), FailureCodes.linkLabelRequired);
      expect(ProfileLinkRules.labelProblem(LinkPlatform.other, 'x'), FailureCodes.linkLabelInvalid);
      expect(ProfileLinkRules.labelProblem(LinkPlatform.other, 'x' * 31), FailureCodes.linkLabelInvalid);
      expect(ProfileLinkRules.labelProblem(LinkPlatform.other, 'My\npodcast'), FailureCodes.linkLabelInvalid);
      expect(ProfileLinkRules.labelProblem(LinkPlatform.other, 'بودكاست\u202E'), FailureCodes.linkLabelInvalid);
      expect(ProfileLinkRules.labelProblem(LinkPlatform.other, ' بودكاست منى '), isNull);
      expect(ProfileLinkRules.labelProblem(LinkPlatform.github, 'Code'), FailureCodes.linkLabelNotAllowed);
      expect(ProfileLinkRules.labelProblem(LinkPlatform.github, null), isNull);
    });

    test('the whole list: at most 8, one per named platform (Other repeats), keyed by index', () {
      final links = [
        const ProfileLink(platform: LinkPlatform.github, url: 'github.com/a'),
        const ProfileLink(platform: LinkPlatform.other, url: 'https://a.dev', label: 'Blog'),
        const ProfileLink(platform: LinkPlatform.github, url: 'github.com/b'),
        const ProfileLink(platform: LinkPlatform.other, url: 'https://b.dev', label: 'Talks'),
        for (var i = 0; i < 5; i++) ProfileLink(platform: LinkPlatform.other, url: 'https://c$i.dev', label: 'Site $i'),
      ];

      expect(ProfileLinkRules.check(links), {
        'links': FailureCodes.linkTooMany,
        'links[2].platform': FailureCodes.linkDuplicatePlatform,
      });
      expect(ProfileLinkRules.check(links.take(4).where((l) => l.url != 'github.com/b').toList()), isEmpty);
    });
  });

  group('HeadlineRules', () {
    test('optional, trimmed, at most 120, one line without direction overrides', () {
      expect(HeadlineRules.normalize('  '), isNull);
      expect(HeadlineRules.normalize(' Senior .NET Engineer '), 'Senior .NET Engineer');
      expect(HeadlineRules.problem(null), isNull);
      expect(HeadlineRules.problem('   '), isNull);
      expect(HeadlineRules.problem('مهندس Backend | .NET و Azure'), isNull);
      expect(HeadlineRules.problem('x' * 120), isNull);
      expect(HeadlineRules.problem('x' * 121), FailureCodes.profileHeadlineTooLong);
      expect(HeadlineRules.problem(' ${'x' * 120} '), isNull, reason: 'counted after trimming');
      expect(HeadlineRules.problem('one\ttwo'), FailureCodes.profileHeadlineInvalid);
      expect(HeadlineRules.problem('one\u2067two'), FailureCodes.profileHeadlineInvalid);
      expect(HeadlineRules.problem('one\u200Ftwo'), FailureCodes.profileHeadlineInvalid);
    });
  });
}
