import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/phone/phone_numbers.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';

/// A local seed user (SPEC §18.3). The numbers are in the reserved fictional range +1 202 555 01XX.
class SeedUser {
  const SeedUser(
    this.phone,
    this.name,
    this.role, {
    required this.hasPin,
    this.verified = false,
    this.suspended = false,
  });

  final String phone;
  final String name;

  /// The account's one role (SPEC §10): `Member` or `SuperAdmin`.
  final String role;
  final bool hasPin;

  /// Has the Verified badge (`isVerified`, F19): a badge, not a role, so the account stays a Member.
  final bool verified;

  /// Suspended (F22): a state, not a role, shown as "· موقوف" / "· suspended" after the role, as on the web.
  final bool suspended;
}

/// The dev login panel (SPEC §18.3): debug builds of the dev flavor only. [kReleaseMode] is a compile-time constant,
/// so release builds tree-shake this code and the demo password define with it.
abstract final class DevLogin {
  static bool get available => !kReleaseMode && AppConfig.fromEnvironment().flavor == Flavor.dev;

  /// `--dart-define=DEV_DEMO_PASSWORD=…` (the API's `Seed:DemoPassword`): a tap signs in. Never pass it to a release.
  static const demoPassword = String.fromEnvironment('DEV_DEMO_PASSWORD');

  static const users = [
    SeedUser('+12025550101', 'Super Admin', 'SuperAdmin', hasPin: true),
    SeedUser('+12025550104', '.NET Writer', 'Member', hasPin: true, verified: true),
    SeedUser('+12025550105', 'AI Writer', 'Member', hasPin: true, verified: true),
    SeedUser('+12025550106', 'Verified Writer', 'Member', hasPin: true, verified: true),
    SeedUser('+12025550107', 'Writer 1', 'Member', hasPin: true),
    SeedUser('+12025550108', 'Writer 2', 'Member', hasPin: true),
    SeedUser('+12025550109', 'Writer 3', 'Member', hasPin: true),
    SeedUser('+12025550110', 'Reader 1', 'Member', hasPin: true),
    SeedUser('+12025550111', 'Reader 2', 'Member', hasPin: true),
    SeedUser('+12025550112', 'Reader 3', 'Member', hasPin: true),
    SeedUser('+12025550113', 'Reader 4', 'Member', hasPin: true),
    SeedUser('+12025550114', 'Reader 5', 'Member', hasPin: true),
    SeedUser('+12025550115', 'Reader 6', 'Member', hasPin: true),
    SeedUser('+12025550116', 'Reader 7', 'Member', hasPin: true),
    SeedUser('+12025550117', 'Reader 8', 'Member', hasPin: true),
    SeedUser('+12025550118', 'Reader 9', 'Member', hasPin: true),
    SeedUser('+12025550119', 'Reader 10', 'Member', hasPin: false),
    SeedUser('+12025550120', 'Suspended User', 'Member', hasPin: false, suspended: true),
  ];
}

Future<SeedUser?> showDevLoginSheet(BuildContext context) => showModalBottomSheet<SeedUser>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const FractionallySizedBox(heightFactor: 0.85, child: DevLoginSheet()),
    );

class DevLoginSheet extends StatelessWidget {
  const DevLoginSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(l10n.devLoginTitle, style: context.textTheme.titleLarge)),
              const SizedBox(height: ReadInSpace.s1),
              Text(l10n.devLoginBody, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: DevLogin.users.length,
            itemBuilder: (context, index) {
              final user = DevLogin.users[index];
              return ListTile(
                onTap: () => Navigator.of(context).pop(user),
                title: Text(user.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                subtitle: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${PhoneNumbers.formatE164(user.phone)} · ${user.role}'),
                      if (user.suspended) TextSpan(text: ' · ${l10n.devLoginSuspended}'),
                      if (user.verified) ...[
                        const TextSpan(text: ' '),
                        // One piece, so a wrapped line moves "✓ Verified writer" down whole.
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.ltr,
                            children: [
                              // The label next to it says the same, so screen readers hear it once.
                              const ExcludeSemantics(child: VerifiedMark()),
                              const SizedBox(width: 4),
                              Text(l10n.verifiedWriter),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ExcludeSemantics(child: Text('PIN')),
                    const SizedBox(width: ReadInSpace.s1),
                    Icon(
                      user.hasPin ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: user.hasPin ? colors.success : colors.error,
                      semanticLabel: user.hasPin ? l10n.devLoginHasPin : l10n.devLoginNoPin,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
