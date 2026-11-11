import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/features/app_update/presentation/widgets/update_motion.dart';
import 'package:readin/features/auth/presentation/widgets/auth_showcase.dart';
import 'package:readin/shared/media/media_image.dart';
import 'package:readin/shared/widgets/app_network_image.dart';

/// Runs before every test file: loads the bundled fonts so golden tests render
/// real glyphs (IBM Plex + JetBrains Mono + Material Icons) deterministically,
/// and swaps the disk-cached image provider for a plain [NetworkImage].
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('IBM Plex Sans Arabic', [
    'assets/fonts/IBMPlexSansArabic-Regular.ttf',
    'assets/fonts/IBMPlexSansArabic-Medium.ttf',
    'assets/fonts/IBMPlexSansArabic-SemiBold.ttf',
    'assets/fonts/IBMPlexSansArabic-Bold.ttf',
  ]);
  await _loadFont('IBM Plex Sans', [
    'assets/fonts/IBMPlexSans-Regular.ttf',
    'assets/fonts/IBMPlexSans-Medium.ttf',
    'assets/fonts/IBMPlexSans-SemiBold.ttf',
    'assets/fonts/IBMPlexSans-Bold.ttf',
  ]);
  await _loadFont('JetBrains Mono', ['assets/fonts/JetBrainsMono-Regular.ttf', 'assets/fonts/JetBrainsMono-Medium.ttf']);
  // The private corner's surahs (F38).
  await _loadFont('Amiri Quran', ['assets/fonts/AmiriQuran-Regular.ttf']);
  await _loadFont('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
  await _loadEmojiFont();
  AppNetworkImage.providerFactory = NetworkImage.new;
  // Media: no disk cache, and a plain token-colored placeholder instead of
  // asynchronous BlurHash decoding. Goldens install FakeMedia on top.
  MediaImages.networkProvider = NetworkImage.new;
  MediaImages.placeholder = (context, _) => ColoredBox(color: context.colors.surfaceVariant, child: const SizedBox.expand());
  // Sign in's showcase loops for as long as the screen is open, so `pumpAndSettle` would never settle: tests and goldens
  // see the screen at rest. test/features/auth/auth_motion_test.dart turns the motion on.
  AuthMotion.enabled = false;
  // The same for "Update ReadIn" (test/features/app_update/update_motion_test.dart turns it on).
  UpdateMotion.enabled = false;
  await testMain();
}

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

/// Color emoji (💡 ❤️ 🔥 💬 🔖) for text styles that list `emojiFontFallback`. The app doesn't bundle an emoji
/// font: this Noto Color Emoji (SIL OFL, bitmap glyphs the test renderer can draw) is checked into the Flutter SDK
/// that CI pins, so every machine draws the same pixels. It predates 🤯, which stays an empty box, as every emoji
/// did before.
Future<void> _loadEmojiFont() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? _sdkRootOf(Platform.resolvedExecutable);
  if (root == null) return;
  final font = File(
    [root, 'engine', 'src', 'flutter', 'txt', 'third_party', 'fonts', 'NotoColorEmoji.ttf'].join(Platform.pathSeparator),
  );
  if (!font.existsSync()) return;
  await (FontLoader('Noto Color Emoji')..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
}

/// `flutter_tester` runs from `<sdk>/bin/cache/artifacts/engine/<platform>/`.
String? _sdkRootOf(String executable) {
  final marker = '${Platform.pathSeparator}bin${Platform.pathSeparator}cache${Platform.pathSeparator}';
  final at = executable.indexOf(marker);
  return at < 0 ? null : executable.substring(0, at);
}
