import { MediaAssetDto } from '../../core/api/models';

/** What the avatar pickers accept (the API re-encodes to WebP, SPEC §24). */
export const AVATAR_TYPES = 'image/jpeg,image/png,image/webp,image/heic,image/heif';

/** The avatar variant to show and store: 256 px when there is one (avatars are 64/128/256/512). */
export function avatarUrlOf(asset: MediaAssetDto): string | null {
  const variants = [...asset.variants].sort((a, b) => a.width - b.width);
  return (variants.find((v) => v.width >= 256) ?? variants.at(-1))?.url ?? null;
}
