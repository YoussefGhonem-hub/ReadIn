import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/theme_x.dart';

/// A country's flag from the flags bundled with the app (`country_flags`, no network), decorative: the country name
/// or code next to it is what screen readers announce.
class CountryFlagIcon extends StatelessWidget {
  const CountryFlagIcon(this.iso2, {super.key, this.width = 28, this.height = 20});

  final String iso2;
  final double width;
  final double height;

  static bool hasFlag(String iso2) => FlagCode.fromCountryCode(iso2) != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget flag = hasFlag(iso2)
        ? CountryFlag.fromCountryCode(
            iso2,
            theme: ImageTheme(width: width, height: height, shape: const RoundedRectangle(3)),
          )
        : Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(3)),
            child: Text(iso2, style: TextStyle(fontSize: height * 0.5, color: colors.textSecondary, fontWeight: FontWeight.w600)),
          );
    return ExcludeSemantics(
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: colors.border, width: 0.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: flag,
      ),
    );
  }
}
