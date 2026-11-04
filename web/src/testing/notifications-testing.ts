import { NotificationDto } from '../app/core/api/models';

/** An unread comment on your English article by Ahmed Samir (one actor), as `GET /me/notifications` sends it. */
export function testNotification(patch: Partial<NotificationDto> = {}): NotificationDto {
  return {
    id: 'n1',
    type: 'article_comment',
    createdAt: '2026-11-04T09:00:00Z',
    updatedAt: '2026-11-04T09:00:00Z',
    isRead: false,
    actor: { id: 'u-ahmed', displayName: 'Ahmed Samir', username: 'ahmed', avatarUrl: null, isVerified: false },
    actorCount: 1,
    article: { id: 'a1', slug: 'clean-code', title: 'Clean code in practice', language: 'en' },
    comment: { id: 'c9', parentId: null, excerpt: 'Great read!' },
    data: {},
    link: 'readin://a/clean-code#comment-c9',
    ...patch,
  };
}
