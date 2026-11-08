import { CommentDto, CommentMentionDto } from '../../core/api/models';
import { TextDir, detectDir } from '../../shared/directives/bidi';

/** Text rules of the API (contract "Comments"): 1–2000 characters after trimming. */
export const COMMENT_MAX_LENGTH = 2000;
/** The character counter appears for the last 200 characters. */
export const COMMENT_COUNTER_FROM = COMMENT_MAX_LENGTH - 200;

/**
 * The API's mention rule (CommentText.Mention): `@` + 3–30 of a–z 0–9 _, not right after a Latin letter, digit, `_`,
 * `@` or `.` (so e-mails aren't mentions) and not followed by another handle character. Fine after an Arabic letter
 * ("و@writer1").
 */
const MENTION = /(?<![A-Za-z0-9_@.])@([A-Za-z0-9_]{3,30})(?![A-Za-z0-9_])/g;

export type CommentSegment = { kind: 'text'; text: string } | { kind: 'mention'; text: string; username: string };

/**
 * A comment's base direction (SPEC §14): its first strong letter, ignoring @handles. `dir="auto"` would pick LTR for
 * "@reader1 شكرًا على المقال" because of the Latin handle, and lay the Arabic sentence out backwards. Text with no strong
 * letter outside handles follows the handles; empty text follows the UI.
 */
export function commentDir(body: string | null | undefined): TextDir | null {
  if (!body) return null;
  return detectDir(body.replace(MENTION, ' ')) ?? detectDir(body);
}

/**
 * Splits a comment body into plain text and the mentions the API resolved (`mentions`). Only those handles become
 * links; any other "@word" stays text. Never produces HTML: the template renders each segment as text.
 */
export function commentSegments(body: string | null | undefined, mentions: readonly CommentMentionDto[] = []): CommentSegment[] {
  if (!body) return [];
  const resolved = new Map(mentions.map((m) => [m.username.toLowerCase(), m.username]));
  const segments: CommentSegment[] = [];
  let cursor = 0;
  if (resolved.size) {
    for (const match of body.matchAll(MENTION)) {
      const username = resolved.get(match[1].toLowerCase());
      if (!username) continue;
      const start = match.index;
      if (start > cursor) segments.push({ kind: 'text', text: body.slice(cursor, start) });
      segments.push({ kind: 'mention', text: match[0], username });
      cursor = start + match[0].length;
    }
  }
  if (cursor < body.length) segments.push({ kind: 'text', text: body.slice(cursor) });
  return segments;
}

/** The `@handle` being typed at the caret: what to search for and the range a picked username replaces. */
export interface MentionQuery {
  /** Without the `@`; may be empty right after typing `@`. */
  query: string;
  /** Index of the `@`. */
  start: number;
  /** End of the handle (the caret, or later when the caret sits inside a word). */
  end: number;
}

/** A handle being typed may hold letters of any script, so "@كريم" finds people by display name too. */
const TYPED_HANDLE = /(?:^|[^A-Za-z0-9_@.])@([\p{L}\p{N}_]{0,30})$/u;
const HANDLE_REST = /^[\p{L}\p{N}_]*/u;

export function mentionAt(text: string, caret: number): MentionQuery | null {
  const match = TYPED_HANDLE.exec(text.slice(0, caret));
  if (!match) return null;
  const typed = match[1];
  const rest = HANDLE_REST.exec(text.slice(caret))?.[0] ?? '';
  return { query: typed, start: caret - typed.length - 1, end: caret + rest.length };
}

/** Replaces the typed `@handle` with `@username ` and returns the new text and caret. */
export function insertMention(text: string, at: MentionQuery, username: string): { text: string; caret: number } {
  const inserted = `@${username} `;
  const after = text.slice(at.end);
  const before = text.slice(0, at.start) + inserted;
  return { text: before + (after.startsWith(' ') ? after.slice(1) : after), caret: before.length };
}

/** A deleted comment, or one hidden from you: no body, no author, no actions. */
export function isPlaceholder(comment: Pick<CommentDto, 'isDeleted' | 'isHidden' | 'body' | 'isUnavailable'>): boolean {
  // F36: a blocked person's comment kept for others' replies is a placeholder too.
  return comment.isDeleted || !!comment.isUnavailable || (comment.isHidden && comment.body === null);
}
