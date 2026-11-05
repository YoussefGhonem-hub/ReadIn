import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/profile/domain/entities/profile.dart';

/// `ProfileDto` JSON as `GET /users/{username}` sends it (docs/api/contract-v1.md "Profile (F14)").
Map<String, dynamic> profileJson({
  String username = 'mona',
  bool isMe = false,
  bool readingStatsVisible = false,
  bool withAvatar = true,
}) =>
    {
      'id': 'u-mona',
      'displayName': 'Mona Adel',
      'username': username,
      'avatarUrl': withAvatar ? 'https://api.test/uploads/avatars/mona_256.webp' : null,
      'avatarVariants': withAvatar
          ? {
              '64': 'https://api.test/uploads/avatars/mona_64.webp',
              '128': 'https://api.test/uploads/avatars/mona_128.webp',
              '256': 'https://api.test/uploads/avatars/mona_256.webp',
              // A small upload is never upscaled: the largest key repeats the 256 variant.
              '512': 'https://api.test/uploads/avatars/mona_256.webp',
            }
          : null,
      'isVerified': true,
      'bio': 'Backend engineer · .NET و SQL Server',
      'headline': 'Senior Backend Engineer | .NET و SQL Server',
      'links': [
        {'platform': 'github', 'url': 'https://github.com/mona', 'label': null},
        {'platform': 'other', 'url': 'https://mona.dev/podcast', 'label': 'بودكاست منى'},
      ],
      'expertise': [
        {'id': 'f-dotnet', 'slug': 'dotnet', 'name': '.NET', 'icon': 'code-xml', 'color': 'callout-info-accent'},
        {'id': 'f-db', 'slug': 'databases', 'name': 'Databases', 'icon': 'database', 'color': 'accent'},
      ],
      'joinedAt': '2026-01-10T09:00:00Z',
      'stats': {'articles': 12, 'followers': 340, 'following': 21, 'totalReads': 5120},
      'isMe': isMe,
      'isFollowing': false,
      'followsYou': !isMe,
      'readingStatsVisible': isMe || readingStatsVisible,
    };

/// Someone else's profile: mixed-text bio, links, two fields, follows the viewer.
final otherProfile = UserProfile(
  id: 'u-mona',
  displayName: 'منى عادل',
  username: 'mona_dev',
  isVerified: true,
  bio: 'Backend engineer بكتب عن ASP.NET Core و SQL Server (EF Core 10).',
  headline: 'Senior Backend Engineer | ASP.NET Core و Azure',
  links: const [
    ProfileLink(platform: LinkPlatform.linkedin, url: 'https://www.linkedin.com/in/mona-dev'),
    ProfileLink(platform: LinkPlatform.github, url: 'https://github.com/mona-dev'),
    ProfileLink(platform: LinkPlatform.x, url: 'https://x.com/mona_dev'),
    ProfileLink(platform: LinkPlatform.website, url: 'https://mona.dev/'),
    ProfileLink(platform: LinkPlatform.other, url: 'https://mona.dev/podcast', label: 'بودكاست منى'),
  ],
  expertise: const [
    ExpertiseField(id: 'f-dotnet', slug: 'dotnet', name: '.NET', icon: 'code-xml', color: 'callout-info-accent'),
    ExpertiseField(id: 'f-db', slug: 'databases', name: 'Databases', icon: 'database', color: 'accent'),
  ],
  joinedAt: DateTime.utc(2026, 1, 10),
  stats: const ProfileStats(articles: 12, followers: 340, following: 21, totalReads: 12500),
  followsYou: true,
  readingStatsVisible: true,
);

/// The viewer's own profile (`isMe`): no avatar, no expertise yet.
final ownProfile = UserProfile(
  id: 'u-1',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  bio: 'بقرا كل يوم عن Flutter و Clean Architecture.',
  links: const [ProfileLink(platform: LinkPlatform.linkedin, url: 'https://www.linkedin.com/in/youssef')],
  joinedAt: DateTime.utc(2026, 3, 2),
  stats: const ProfileStats(articles: 3, followers: 48, following: 9, totalReads: 860),
  isMe: true,
  readingStatsVisible: true,
);

const sampleFollowers = [
  UserSummary(
    id: 'w-1',
    displayName: 'منى عبد الله',
    username: 'mona_dev',
    isVerified: true,
    bio: 'بكتب عن ASP.NET Core و Clean Architecture',
    followsYou: true,
  ),
  UserSummary(id: 'w-2', displayName: 'Omar Khaled', username: 'omar_k', bio: 'Flutter & mobile performance', isFollowing: true),
  UserSummary(id: 'w-3', displayName: 'Sara (.NET)', username: 'sara_net', bio: 'C# 14, .NET 10 و Azure'),
  UserSummary(id: 'a-1', displayName: 'ReadIn Editorial', username: 'readin', isVerified: true, isFollowing: true),
];
