import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/editor_backup.dart';
import '../../domain/entities/editor_entities.dart';
import '../../domain/repositories/article_editor_repository.dart';
import '../models/article_editor_models.dart';

/// Unsaved editor changes in a Hive box, one JSON entry per article (SPEC F05: local backup, offline-safe). The
/// document is kept whole, as the editor had it, so a restore brings back exactly what was typed.
@LazySingleton(as: EditorBackupStore)
class HiveEditorBackupStore implements EditorBackupStore {
  HiveEditorBackupStore() : this.withBox(() => Hive.openLazyBox<String>(boxName));

  /// [open] is a test seam (a box in a temporary folder).
  @visibleForTesting
  HiveEditorBackupStore.withBox(Future<LazyBox<String>> Function() open) : _open = open;

  static const boxName = 'readin.editor_backups';

  final Future<LazyBox<String>> Function() _open;
  Future<LazyBox<String>>? _box;

  Future<LazyBox<String>> get _ready => _box ??= _open();

  @override
  Future<EditorBackup?> read(String key) async {
    try {
      final raw = await (await _ready).get(key);
      return raw == null ? null : decode(key, jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null; // A copy this version can't read is no copy.
    }
  }

  @override
  Future<void> write(EditorBackup backup) async => (await _ready).put(backup.key, jsonEncode(encode(backup)));

  @override
  Future<void> delete(String key) async => (await _ready).delete(key);

  static Map<String, dynamic> encode(EditorBackup b) => {
        'articleId': b.articleId,
        'baseVersion': b.baseVersion,
        'status': b.status.name,
        'slug': b.slug,
        'editedAt': b.editedAt.toUtc().toIso8601String(),
        'document': ArticleDraftDocumentModel.fromEntity(b.document).toJson(),
      };

  static EditorBackup decode(String key, Map<String, dynamic> json) => EditorBackup(
        key: key,
        articleId: json['articleId'] as String?,
        baseVersion: (json['baseVersion'] as num?)?.toInt(),
        status: json['status'] == 'published' ? ArticleLifecycle.published : ArticleLifecycle.draft,
        slug: json['slug'] as String?,
        editedAt: DateTime.parse(json['editedAt'] as String),
        document: ArticleDraftDocumentModel.fromJson(json['document'] as Map<String, dynamic>).toEntity(),
      );
}

/// For tests and previews.
class InMemoryEditorBackupStore implements EditorBackupStore {
  final backups = <String, EditorBackup>{};

  @override
  Future<EditorBackup?> read(String key) async => backups[key];

  @override
  Future<void> write(EditorBackup backup) async => backups[backup.key] = backup;

  @override
  Future<void> delete(String key) async => backups.remove(key);
}
