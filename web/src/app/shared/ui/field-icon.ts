import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { LucideDynamicIcon } from '@lucide/angular';
import type { AppIconName } from './icons';

/** Lucide names used by `FieldDto.icon` (content/taxonomy.yaml). Unknown names fall back to a book. */
export const FIELD_ICONS: Readonly<Record<string, AppIconName>> = {
  binary: 'Binary',
  bot: 'Bot',
  boxes: 'Boxes',
  brain: 'Brain',
  'brain-circuit': 'BrainCircuit',
  cloud: 'Cloud',
  code: 'Code',
  'code-xml': 'CodeXml',
  cog: 'Cog',
  cpu: 'Cpu',
  database: 'Database',
  'flask-conical': 'FlaskConical',
  'git-branch': 'GitBranch',
  'heart-pulse': 'HeartPulse',
  layers: 'Layers',
  'layout-dashboard': 'LayoutDashboard',
  'layout-template': 'LayoutTemplate',
  monitor: 'Monitor',
  network: 'Network',
  server: 'Server',
  shield: 'Shield',
  'shield-check': 'ShieldCheck',
  smartphone: 'Smartphone',
  sparkles: 'Sparkles',
  stethoscope: 'Stethoscope',
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
