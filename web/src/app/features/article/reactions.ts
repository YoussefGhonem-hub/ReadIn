import { REACTION_TYPES, ReactionCountsDto, ReactionType } from '../../core/api/models';

/** 💡 مفيد · ❤️ · 🔥 · 🤯 (SPEC F10), in the order the picker shows them. */
export const REACTION_EMOJI: Readonly<Record<ReactionType, string>> = {
  insightful: '💡',
  love: '❤️',
  fire: '🔥',
  mindBlown: '🤯',
};

/** The most used reactions first, at most `limit`, for the "who reacted" buttons (reader bar and post card). */
export function topReactions(reactions: ReactionCountsDto, limit = 3): ReactionType[] {
  return REACTION_TYPES.filter((t) => reactions[t] > 0)
    .sort((a, b) => reactions[b] - reactions[a])
    .slice(0, limit);
}
