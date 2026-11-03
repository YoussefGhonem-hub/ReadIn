import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/phone/countries.dart';
import '../../../../core/push/push_service.dart';
import '../../../../shared/media/media_cache_manager.dart';
import 'google_sign_in_data_source.dart';

/// What this device keeps for the signed-in account besides its session, forgotten once the account is deleted
/// (SPEC F01): the push token (deleted at FCM), the Google account picked in the sheet, the phone country taken from the
/// account's number, every cached and decoded image, and the files the app left in its temporary directory (photos and
/// PDFs picked for an unsent article, downloaded PDFs). Display preferences (theme, languages, font size) belong to the
/// device, as for guests, and stay.
///
/// Best effort: every step runs even when another one fails, so the session can always be forgotten afterwards.
@lazySingleton
class AccountDeviceData {
  AccountDeviceData(
    this._push,
    this._google,
    this._countries, {
    @ignoreParam Future<void> Function()? clearImages,
    @ignoreParam Future<Directory> Function()? temporaryDirectory,
  })  : _clearImages = clearImages ?? _clearAllImages,
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final PushService _push;
  final GoogleSignInDataSource _google;
  final PhoneCountryMemory _countries;
  final Future<void> Function() _clearImages;
  final Future<Directory> Function() _temporaryDirectory;

  Future<void> forget() async {
    await _step('push token', _push.forgetDevice);
    await _step('Google account', _google.signOut);
    await _step('phone country', _countries.forget);
    await _step('images', _clearImages); // before the temporary files: the image cache keeps its files there
    await _step('temporary files', _clearTemporaryFiles);
  }

  /// The OS may empty this directory at any time, so nothing in it is needed later.
  Future<void> _clearTemporaryFiles() async {
    final directory = await _temporaryDirectory();
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      try {
        await entity.delete(recursive: true);
      } on FileSystemException catch (error) {
        debugPrint('Could not delete ${entity.path}: $error');
      }
    }
  }

  /// Decoded images in memory, then the disk cache of every network image (avatars, covers, article images).
  static Future<void> _clearAllImages() async {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await MediaCacheManager.instance.emptyCache();
  }

  static Future<void> _step(String name, Future<void> Function() step) async {
    try {
      await step();
    } catch (error) {
      debugPrint('Could not forget the $name: $error');
    }
  }
}
