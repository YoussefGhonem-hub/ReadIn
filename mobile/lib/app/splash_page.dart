import 'package:flutter/material.dart';

import '../core/l10n/l10n_x.dart';
import '../core/theme/theme_x.dart';
import '../core/theme/tokens.g.dart';
import '../shared/widgets/app_logo.dart';

/// Shown while the stored session is restored (`POST /auth/refresh`, SPEC §9.3).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 40),
              const SizedBox(height: ReadInSpace.s2),
              Text(context.l10n.tagline, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
            ],
          ),
        ),
      );
}
