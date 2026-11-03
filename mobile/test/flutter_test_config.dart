import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/theme/theme_x.dart';
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
  await _loadFont('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
  AppNetworkImage.providerFactory = NetworkImage.new;
  // Media: no disk cache, and a plain token-colored placeholder instead of
  // asynchronous BlurHash decoding. Goldens install FakeMedia on top.
  MediaImages.networkProvider = NetworkImage.new;
  MediaImages.placeholder = (context, _) => ColoredBox(color: context.colors.surfaceVariant, child: const SizedBox.expand());
  await testMain();
}

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
