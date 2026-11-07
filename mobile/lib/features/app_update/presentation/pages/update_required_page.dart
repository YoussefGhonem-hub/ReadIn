import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../domain/entities/update_policy.dart';
import '../widgets/update_motion.dart';

/// Opens a store page; tests pass a fake.
typedef StoreLauncher = Future<bool> Function(Uri uri);

/// The store app (or the browser), outside ReadIn.
Future<bool> openStoreExternally(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false; // no app can open it
  }
}

/// "Update ReadIn": this version is no longer supported (`GET /app/update-policy`). It replaces the whole app and
/// nothing leads past it; "Update now" opens the store page, and on iOS without one it only asks to update. A phone
/// takes the update in the picture while the text and the button rise in ([UpdateMotion]).
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key, required this.requirement, this.launchStore = openStoreExternally});

  final UpdateRequirement requirement;
  final StoreLauncher launchStore;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: UpdateMotionScope(
        child: Stack(
          children: [
            const Positioned.fill(child: UpdateBackdrop()),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  // Centered, and scrolls only when large text doesn't fit.
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s6),
                          child: _content(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final storeUri = switch (requirement.storeUrl) {
      final url? => Uri.tryParse(url),
      null => null,
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UpdateRise(delay: 0, child: Center(child: AppLogo(size: 32))),
        const SizedBox(height: ReadInSpace.s5),
        const Center(child: UpdateHero()),
        const SizedBox(height: ReadInSpace.s4),
        UpdateRise(
          delay: 0.45,
          child: Semantics(
            header: true,
            child: Text(l10n.updateRequiredTitle, textAlign: TextAlign.center, style: context.textTheme.headlineSmall),
          ),
        ),
        const SizedBox(height: ReadInSpace.s3),
        UpdateRise(
          delay: 0.55,
          child: Text(
            l10n.updateRequiredBody,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
          ),
        ),
        if (storeUri != null) ...[
          const SizedBox(height: ReadInSpace.s6),
          UpdateRise(
            delay: 0.65,
            child: UpdateButtonMotion(
              child: FilledButton(onPressed: () => launchStore(storeUri), child: Text(l10n.updateRequiredAction)),
            ),
          ),
        ],
      ],
    );
  }
}
