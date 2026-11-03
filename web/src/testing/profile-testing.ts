import { FieldDto, ProfileDto } from '../app/core/api/models';

/** Someone else's public profile as a signed-in viewer sees it (F14): verified, with a mixed ar/en bio. */
export function testProfile(patch: Partial<ProfileDto> = {}): ProfileDto {
  return {
    id: 'writer-1',
    displayName: 'Karim Hassan',
    username: 'karim',
    avatarUrl: null,
    avatarVariants: null,
    isVerified: true,
    bio: 'Frontend lead. بكتب عن Angular والـ performance.',
    links: { github: 'https://github.com/karim', linkedin: null, website: 'https://karim.dev/' },
    expertise: [{ id: 'f1', slug: 'software', name: 'البرمجيات', icon: 'code', color: 'primary' }],
    joinedAt: '2026-02-14T09:00:00Z',
    stats: { articles: 12, followers: 340, following: 21, totalReads: 5120 },
    isMe: false,
    isFollowing: false,
    followsYou: true,
    readingStatsVisible: false,
    ...patch,
  };
}

export function testField(id: string, slug: string, nameEn: string, nameAr = nameEn): FieldDto {
  return { id, slug, name: nameEn, nameAr, nameEn, icon: 'code', color: 'primary', isSensitive: false, requiresSources: false, topicCount: 0 };
}

/** Seven fields, so the five-field limit can be reached. */
export const TEST_FIELDS: FieldDto[] = [
  testField('f1', 'software', 'Software', 'البرمجيات'),
  testField('f2', 'medicine', 'Medicine', 'الطب'),
  testField('f3', 'data', 'Data', 'البيانات'),
  testField('f4', 'design', 'Design', 'التصميم'),
  testField('f5', 'security', 'Security', 'الأمن'),
  testField('f6', 'cloud', 'Cloud', 'السحابة'),
  testField('f7', 'ai', 'AI', 'الذكاء الاصطناعي'),
];
