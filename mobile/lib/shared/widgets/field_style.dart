import 'package:flutter/material.dart';

import '../../core/theme/tokens.g.dart';

/// How a field looks (content/taxonomy.yaml): the API sends a Lucide icon name and a design token name as its color.
/// Unknown values fall back to a book and the primary color.
abstract final class FieldStyle {
  static IconData icon(String lucideName) => switch (lucideName) {
        'sparkles' => Icons.auto_awesome_rounded,
        'brain-circuit' => Icons.psychology_rounded,
        'network' => Icons.hub_rounded,
        'bot' => Icons.smart_toy_rounded,
        'code-xml' || 'code' => Icons.code_rounded,
        'boxes' => Icons.widgets_rounded,
        'cloud' => Icons.cloud_rounded,
        'cog' => Icons.settings_rounded,
        'database' => Icons.storage_rounded,
        'flask-conical' => Icons.science_rounded,
        'heart-pulse' => Icons.monitor_heart_rounded,
        'layout-template' => Icons.dashboard_rounded,
        'shield-check' => Icons.verified_user_rounded,
        'smartphone' => Icons.smartphone_rounded,
        'stethoscope' => Icons.medical_services_rounded,
        _ => Icons.menu_book_rounded,
      };

  static Color color(ReadInColors colors, String token) => switch (token) {
        'accent' => colors.accent,
        'success' => colors.success,
        'callout-tip-accent' => colors.calloutTipAccent,
        'callout-info-accent' => colors.calloutInfoAccent,
        'callout-warning-accent' => colors.calloutWarningAccent,
        'callout-danger-accent' => colors.calloutDangerAccent,
        _ => colors.primary,
      };
}
