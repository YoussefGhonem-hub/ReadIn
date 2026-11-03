import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

/// Welcome (SPEC §9.2): logo + tagline, create account, sign in, browse as a guest, and the UI language switcher.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _go(BuildContext context, String location, {bool push = true}) async {
    await context.read<SettingsCubit>().markWelcomeSeen();
    if (!context.mounted) return;
    if (push) {
      await context.push<void>(location);
    } else {
      context.go(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final otherLanguage = isArabic ? l10n.languageEnglish : l10n.languageArabic;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(ReadInSpace.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Semantics(
                      button: true,
                      label: l10n.switchLanguageTo(otherLanguage),
                      excludeSemantics: true,
                      child: TextButton.icon(
                        icon: const Icon(Icons.translate_rounded, size: 20),
                        label: Text(otherLanguage),
                        onPressed: () => context.read<SettingsCubit>().setUiLanguage(isArabic ? 'en' : 'ar'),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Center(child: AppLogo(size: 44)),
                  const SizedBox(height: ReadInSpace.s3),
                  Text(
                    l10n.tagline,
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleMedium?.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: ReadInSpace.s6),
                  Container(
                    padding: const EdgeInsets.all(ReadInSpace.s5),
                    decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.sheet)),
                    child: Column(
                      children: [
                        ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_cafe_outlined, size: 32, color: colors.primary),
                              const SizedBox(width: ReadInSpace.s3),
                              Icon(Icons.menu_book_rounded, size: 32, color: colors.primary),
                              const SizedBox(width: ReadInSpace.s3),
                              Icon(Icons.local_fire_department_rounded, size: 32, color: colors.accent),
                            ],
                          ),
                        ),
                        const SizedBox(height: ReadInSpace.s3),
                        Text(
                          l10n.onboardingWelcomeBody,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyLarge?.copyWith(color: colors.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FilledButton(onPressed: () => _go(context, '/auth/sign-up'), child: Text(l10n.signUp)),
                  const SizedBox(height: ReadInSpace.s3),
                  OutlinedButton(onPressed: () => _go(context, '/auth/sign-in'), child: Text(l10n.welcomeSignIn)),
                  const SizedBox(height: ReadInSpace.s2),
                  TextButton(onPressed: () => _go(context, '/home', push: false), child: Text(l10n.browseAsGuest)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
