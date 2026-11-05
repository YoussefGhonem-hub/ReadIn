import { TagRefDto } from '../../core/api/models';

/**
 * A tag page's route (F32): `/tags/{slug}`. The router percent-encodes the segment, so Arabic slugs work. The slug
 * comes from the server; a client never builds one from a name.
 */
export function tagLink(tag: Pick<TagRefDto, 'slug'>): string[] {
  return ['/tags', tag.slug];
}
