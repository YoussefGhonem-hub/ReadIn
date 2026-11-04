import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { LucideDynamicIcon } from '@lucide/angular';
import type { AppIconName } from './icons';

/** Lucide names used by `FieldDto.icon` (content/taxonomy.yaml). Unknown names fall back to a book. */
export const FIELD_ICONS: Readonly<Record<string, AppIconName>> = {
  atom: 'Atom',
  binary: 'Binary',
  'book-open': 'BookOpen',
  bot: 'Bot',
  boxes: 'Boxes',
  brain: 'Brain',
  'brain-circuit': 'BrainCircuit',
  briefcase: 'Briefcase',
  cloud: 'Cloud',
  code: 'Code',
  'code-xml': 'CodeXml',
  coffee: 'Coffee',
  cog: 'Cog',
  cpu: 'Cpu',
  database: 'Database',
  'flask-conical': 'FlaskConical',
  'git-branch': 'GitBranch',
  'graduation-cap': 'GraduationCap',
  'heart-pulse': 'HeartPulse',
  landmark: 'Landmark',
  layers: 'Layers',
  'layout-dashboard': 'LayoutDashboard',
  'layout-template': 'LayoutTemplate',
  monitor: 'Monitor',
  network: 'Network',
  palette: 'Palette',
  scale: 'Scale',
  server: 'Server',
  shield: 'Shield',
  'shield-check': 'ShieldCheck',
  smartphone: 'Smartphone',
  sparkles: 'Sparkles',
  sprout: 'Sprout',
  stethoscope: 'Stethoscope',
  trophy: 'Trophy',
  wrench: 'Wrench',
};

@Component({
  selector: 'rd-field-icon',
  imports: [LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'inline-flex', 'aria-hidden': 'true' },
  template: `<svg [lucideIcon]="icon()" [size]="size()"></svg>`,
})
export class FieldIcon {
  readonly name = input<string | null>(null);
  readonly size = input(18);
  protected readonly icon = computed(() => FIELD_ICONS[this.name() ?? ''] ?? 'BookOpen');
}
