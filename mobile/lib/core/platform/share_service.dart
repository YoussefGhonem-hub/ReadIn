import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

/// The system share sheet (`share_plus`), behind a small seam so cubits stay
/// unit-testable. [origin] anchors the popover on iPad.
@lazySingleton
class ShareService {
  Future<void> shareLink(String url, {String? subject, Rect? origin}) =>
      SharePlus.instance.share(ShareParams(text: url, subject: subject, sharePositionOrigin: origin));

  Future<void> shareFile(String path, {required String mimeType, String? fileName, Rect? origin}) =>
      SharePlus.instance.share(ShareParams(
        files: [XFile(path, mimeType: mimeType)],
        fileNameOverrides: fileName == null ? null : [fileName],
        sharePositionOrigin: origin,
      ));

  /// A file with a message beside it (the F24 quote card: its PNG and the article's link).
  Future<void> shareFileWithText(
    String path, {
    required String mimeType,
    required String text,
    String? subject,
    String? fileName,
    Rect? origin,
  }) =>
      SharePlus.instance.share(ShareParams(
        files: [XFile(path, mimeType: mimeType)],
        text: text,
        subject: subject,
        fileNameOverrides: fileName == null ? null : [fileName],
        sharePositionOrigin: origin,
      ));
}
