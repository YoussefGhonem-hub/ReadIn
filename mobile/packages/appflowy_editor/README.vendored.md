# appflowy_editor (vendored)

The block editor of the ReadIn article editor (SPEC F05, §3.3). Drop this folder and depend on the pub.dev package
again once upstream publishes a release that compiles with the app's Flutter and plugin versions.

## Source

- Upstream: <https://github.com/AppFlowy-IO/appflowy-editor>
- Commit: `01eccc6ee36bd07698bd80915289fe7070478cd2` (main, 2026-08-06; its pubspec says 6.1.0)
- License: dual AGPL-3.0 / MPL-2.0, see `LICENSE` (unchanged). ReadIn uses it under the **MPL-2.0**: the patched
  files below stay under the MPL-2.0 and their source is this folder.

## Why vendored

The latest pub.dev release (6.2.0, 2025-12-08) doesn't compile on Flutter 3.44: `DeltaTextInputService` lacks
`TextInputClient.onFocusReceived`, which Flutter 3.44 added. Main fixes that (commit `41335c54ae`), but it is
unpublished and still pins `file_picker ^10.3.10` and `device_info_plus ^12.3.0`; the app uses file_picker 13.3.2 and
device_info_plus 13.3.0, and file_picker 10 can't be resolved next to the app's `share_plus` and `device_info_plus`
(win32 ^5 vs ^6).

## Patch (the only changes to upstream)

1. `pubspec.yaml`
   - `file_picker: ^10.3.10` → `^13.3.2`, `device_info_plus: ^12.3.0` → `^13.3.0`.
   - Left out: `dev_dependencies`, `flutter_intl`, `topics`, `platforms` (none is needed to build).
2. `lib/src/editor/util/file_picker/file_picker_impl.dart` — file_picker 13 replaced `FilePicker.platform` with static
   methods and returns `List<PlatformFile>`:
   - `getDirectoryPath` → `fp.FilePicker.getDirectoryPath(dialogTitle: title)`.
   - `pickFiles` → `fp.FilePicker.pickFiles(dialogTitle, initialDirectory, type, allowedExtensions, onFileLoading)`;
     `allowMultiple: false` keeps the first file only; `withData`, `withReadStream`, `lockParentWindow` no longer exist.
   - `saveFile` returns `null` (file_picker 13 needs the bytes up front; the editor never calls it).
3. `lib/src/editor/block_component/image_block_component/image_upload_widget.dart` — `PlatformFile.bytes` is gone in
   file_picker 13: the web branch reads `await result.files.first.readAsBytes()` before `setState`.

`device_info_plus` 13 needed no code change (`androidInfo.version.sdkInt` is unchanged).

## Left out of the upstream checkout

`example/`, `test/`, `documentation/`, `CHANGELOG.md`, `README.md`, `analysis_options.yaml`, `codecov.yml`. Kept:
`lib/`, the icon `assets/` the toolbar and selection menu load at runtime, and `LICENSE`.

The app's `analysis_options.yaml` excludes `packages/**`, so `flutter analyze` doesn't lint this code.
