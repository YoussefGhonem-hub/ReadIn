/**
 * One Lucide icon per file (`lucide/dist/esm/icons/heart.mjs`). Lazy features import their icons this way: through the
 * `lucide` barrel, which the initial bundle already uses, they would land in the initial bundle (see
 * features/comments/comment-icons.ts).
 */
declare module 'lucide/dist/esm/icons/*.mjs' {
  const icon: typeof import('lucide').Heart;
  export default icon;
}
