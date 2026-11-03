import { ReactionType } from '../../core/api/models';

/** 💡 مفيد · ❤️ · 🔥 · 🤯 (SPEC F10), in the order the picker shows them. */
export const REACTION_EMOJI: Readonly<Record<ReactionType, string>> = {
  insightful: '💡',
  love: '❤️',
  fire: '🔥',
  mindBlown: '🤯',
};
