import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { LucideDynamicIcon } from '@lucide/angular';
import type { AppIconName } from './icons';

/** Lucide names used by `FieldDto.icon` (content/taxonomy.yaml). Unknown names fall back to a book. */
const FIELD_ICONS: Record<string, AppIconName> = {
  binary: 'Binary',
  bot: 'Bot',
  brain: 'Brain',
  cloud: 'Cloud',
  code: 'Code',
  cpu: 'Cpu',
  database: 'Database',
  'flask-conical': 'FlaskConical',
  'git-branch': 'GitBranch',
  'heart-pulse': 'HeartPulse',
  layers: 'Layers',
  'layout-dashboard': 'LayoutDashboard',
  monitor: 'Monitor',
  network: 'Network',
  server: 'Server',
  shield: 'Shield',
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
