import { FIELD_ICONS } from './field-icon';
import { APP_ICONS } from './icons';

/** The `icon` of every field in content/taxonomy.yaml (keep in sync when a field is added). */
const TAXONOMY_ICONS = [
  'bot',
  'boxes',
  'brain-circuit',
  'cloud',
  'code-xml',
  'cog',
  'database',
  'flask-conical',
  'heart-pulse',
  'layout-template',
  'network',
  'shield-check',
  'smartphone',
  'sparkles',
  'stethoscope',
];

describe('FieldIcon', () => {
  it('has an icon for every taxonomy field (none falls back to the book)', () => {
    expect(TAXONOMY_ICONS.filter((name) => !FIELD_ICONS[name])).toEqual([]);
  });

  it('only maps to registered icons', () => {
    expect(Object.values(FIELD_ICONS).filter((icon) => !(icon in APP_ICONS))).toEqual([]);
  });
});
