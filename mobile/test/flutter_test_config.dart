import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
  await testMain();
}

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
