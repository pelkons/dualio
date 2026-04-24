import 'dart:io';

import 'package:dualio/core/supabase/supabase_bootstrap.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final itemsRepositoryProvider = Provider<ItemsRepository?>((ref) {
  final client = SupabaseBootstrap.client;
  if (client == null) {
    return null;
  }
  return ItemsRepository(client);
});

class ItemsRepository {
  const ItemsRepository(this._client);

  final SupabaseClient _client;

  bool get hasSignedInUser {
    return _client.auth.currentUser != null;
  }

  Future<List<SemanticItem>> fetchLatestItems({int limit = 50}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return <SemanticItem>[];
    }

    final rows = await _client
        .from('items')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map(_itemFromRow).toList(growable: false);
  }

  Future<SemanticItem?> createPendingInput({
    required String content,
    required SourceType sourceType,
    String personalNote = '',
  }) async {
    final user = _client.auth.currentUser;
    final normalized = content.trim();
    if (user == null || normalized.isEmpty) {
      return null;
    }

    final itemType = _inferLocalType(normalized, sourceType);
    final sourceUrl = sourceType == SourceType.link ? normalized : null;
    final localImagePath = _isImageSource(sourceType) ? normalized : null;
    final title = _titleFromContent(normalized);
    final summary = normalized;
    final note = personalNote.trim();

    final processingStatus = sourceType == SourceType.link
        ? 'pending'
        : 'ready';
    var row = await _client
        .from('items')
        .insert(<String, Object?>{
          'user_id': user.id,
          'type': _itemTypeToDb(itemType),
          'source_type': _sourceTypeToDb(sourceType),
          'source_url': sourceUrl,
          'thumbnail_url': localImagePath,
          'raw_content': <String, Object?>{
            'input': normalized,
            'sourceType': _sourceTypeToDb(sourceType),
            if (localImagePath != null) 'localImagePath': localImagePath,
          },
          'parsed_content': <String, Object?>{
            'rawText': normalized,
            if (note.isNotEmpty) 'userNote': note,
          },
          'title': title,
          'language': 'en',
          'searchable_summary': summary,
          'searchable_aliases': _aliasesFromContent(normalized),
          'processing_status': processingStatus,
        })
        .select()
        .single();

    if (sourceType == SourceType.link) {
      final processed = await _invokeProcessItem(row['id']! as String);
      if (!processed) {
        row = await _markProcessingFailed(row['id']! as String);
      }
    } else if (localImagePath != null) {
      row = await _uploadImageAsset(
        row: row,
        localImagePath: localImagePath,
        sourceType: sourceType,
      );
    }

    return _itemFromRow(row);
  }

  Future<Map<String, Object?>> _uploadImageAsset({
    required Map<String, Object?> row,
    required String localImagePath,
    required SourceType sourceType,
  }) async {
    final user = _client.auth.currentUser;
    final itemId = row['id'] as String?;
    if (user == null || itemId == null) {
      return row;
    }

    final file = File(localImagePath);
    if (!await file.exists()) {
      return row;
    }

    try {
      final filename = localImagePath.split(RegExp(r'[/\\]')).last;
      final contentType = _contentTypeForPath(localImagePath);
      final response = await _client.functions.invoke(
        'create-asset-upload',
        body: <String, Object?>{
          'item_id': itemId,
          'filename': filename,
          'content_type': contentType,
        },
      );
      final payload = Map<String, Object?>.from(response.data as Map);
      final uploadUrl = payload['upload_url'] as String?;
      final readUrl = payload['read_url'] as String?;
      final bucket = payload['bucket'] as String?;
      final key = payload['key'] as String?;
      if (uploadUrl == null ||
          readUrl == null ||
          bucket == null ||
          key == null) {
        return _markAssetUploadFailed(row, itemId, 'missing_upload_payload');
      }

        final bytes = await file.readAsBytes();
        final uploadRequest = await HttpClient().putUrl(Uri.parse(uploadUrl));
        uploadRequest.headers.contentType = ContentType.parse(contentType);
        uploadRequest.contentLength = bytes.length;
        uploadRequest.add(bytes);
      final uploadResponse = await uploadRequest.close();
      if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
        return _markAssetUploadFailed(
          row,
          itemId,
          'r2_upload_${uploadResponse.statusCode}',
        );
      }

      await _client.from('item_assets').insert(<String, Object?>{
        'item_id': itemId,
        'user_id': user.id,
        'asset_type': 'image',
        'storage_provider': 'cloudflare_r2',
        'storage_bucket': bucket,
        'storage_key': key,
        'original_filename': filename,
        'content_type': contentType,
        'byte_size': bytes.length,
      });

      final rawContent = <String, Object?>{
        ..._objectMap(row['raw_content']),
        'localImagePath': localImagePath,
        'asset': <String, Object?>{
          'provider': 'cloudflare_r2',
          'bucket': bucket,
          'key': key,
          'contentType': contentType,
          'byteSize': bytes.length,
        },
      };
      return await _client
          .from('items')
          .update(<String, Object?>{
            'thumbnail_url': readUrl,
            'raw_content': rawContent,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', itemId)
          .eq('user_id', user.id)
          .select()
          .single();
    } on Object {
      return _markAssetUploadFailed(row, itemId, 'asset_upload_failed');
    }
  }

  Future<Map<String, Object?>> _markAssetUploadFailed(
    Map<String, Object?> row,
    String itemId,
    String reason,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return row;
    }

    try {
      final rawContent = <String, Object?>{
        ..._objectMap(row['raw_content']),
        'assetUpload': <String, Object?>{
          'status': 'failed',
          'reason': reason,
          'failedAt': DateTime.now().toUtc().toIso8601String(),
        },
      };
      return await _client
          .from('items')
          .update(<String, Object?>{
            'raw_content': rawContent,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', itemId)
          .eq('user_id', user.id)
          .select()
          .single();
    } on Object {
      return row;
    }
  }

  Future<bool> retryProcessing(String itemId) async {
    final user = _client.auth.currentUser;
    if (user == null || itemId.startsWith('local-')) {
      return false;
    }

    await _client
        .from('items')
        .update(<String, Object?>{
          'processing_status': 'processing',
          'clarification_question': null,
        })
        .eq('id', itemId)
        .eq('user_id', user.id);

    final processed = await _invokeProcessItem(itemId, retry: true);
    if (!processed) {
      await _markProcessingFailed(itemId);
    }
    return processed;
  }

  Future<SemanticItem?> updateUserNote(SemanticItem item, String note) async {
    final user = _client.auth.currentUser;
    if (user == null || item.id.startsWith('local-')) {
      return null;
    }

    final parsedContent = <String, Object?>{
      ...item.parsedContent,
      'userNote': note.trim(),
    };
    final row = await _client
        .from('items')
        .update(<String, Object?>{
          'parsed_content': parsedContent,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', item.id)
        .eq('user_id', user.id)
        .select()
        .single();
    return _itemFromRow(row);
  }

  Future<bool> _invokeProcessItem(String itemId, {bool retry = false}) async {
    try {
      await _client.functions.invoke(
        'process-item',
        body: <String, Object?>{'item_id': itemId, 'retry': retry},
      );
      return true;
    } on Object {
      return false;
    }
  }

  Future<Map<String, Object?>> _markProcessingFailed(String itemId) async {
    return await _client
        .from('items')
        .update(<String, Object?>{
          'processing_status': 'failed',
          'clarification_question': 'Could not process this link.',
        })
        .eq('id', itemId)
        .select()
        .single();
  }

  Future<void> deleteItem(String itemId) async {
    final user = _client.auth.currentUser;
    if (user == null || itemId.startsWith('local-')) {
      return;
    }

    await _client
        .from('items')
        .delete()
        .eq('id', itemId)
        .eq('user_id', user.id);
  }

  SemanticItem _itemFromRow(Map<String, Object?> row) {
    final sourceType = _sourceTypeFromDb(row['source_type'] as String?);
    final rawContent = _objectMap(row['raw_content']);
    final thumbnailUrl =
        row['thumbnail_url'] as String? ??
        (_isImageSource(sourceType)
            ? rawContent['localImagePath'] as String?
            : null) ??
        (_isImageSource(sourceType) ? rawContent['input'] as String? : null);
    final rowTitle = (row['title'] as String?) ?? 'Untitled';
    return SemanticItem(
      id: row['id']! as String,
      type: _itemTypeFromDb(row['type'] as String?),
      sourceType: sourceType,
      title: _isImageSource(sourceType)
          ? _titleFromContent(rowTitle)
          : rowTitle,
      sourceUrl: row['source_url'] as String?,
      thumbnailUrl: thumbnailUrl,
      language: (row['language'] as String?) ?? 'en',
      searchableSummary: (row['searchable_summary'] as String?) ?? '',
      searchableAliases: _stringList(row['searchable_aliases']),
      parsedContent: _objectMap(row['parsed_content']),
      processingStatus: _processingStatusFromDb(
        row['processing_status'] as String?,
      ),
      clarificationQuestion: row['clarification_question'] as String?,
      createdLabel: _createdLabel(row['created_at'] as String?),
    );
  }

  Map<String, Object?> _objectMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map<String, Object?>) {
      return value;
    }
    return <String, Object?>{};
  }

  List<String> _stringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return <String>[];
  }

  ItemType _inferLocalType(String content, SourceType sourceType) {
    if (sourceType == SourceType.text) {
      return ItemType.note;
    }
    return ItemType.unknown;
  }

  String _titleFromContent(String content) {
    final filename = content.split(RegExp(r'[/\\]')).last;
    if (_isImagePath(content) && filename.isNotEmpty) {
      return filename;
    }
    final compact = content.replaceAll(RegExp(r'\s+'), ' ');
    if (compact.length <= 64) {
      return compact;
    }
    return '${compact.substring(0, 61)}...';
  }

  List<String> _aliasesFromContent(String content) {
    return content
        .split(RegExp(r'[\s,.;:!?]+'))
        .where((word) => word.length > 3)
        .take(8)
        .map((word) => word.toLowerCase())
        .toList(growable: false);
  }

  String _createdLabel(String? value) {
    if (value == null) {
      return '';
    }
    final createdAt = DateTime.tryParse(value);
    if (createdAt == null) {
      return '';
    }

    final age = DateTime.now().toUtc().difference(createdAt.toUtc());
    if (age.inMinutes < 1) {
      return 'Just now';
    }
    if (age.inHours < 1) {
      return '${age.inMinutes}m ago';
    }
    if (age.inDays < 1) {
      return '${age.inHours}h ago';
    }
    return '${age.inDays}d ago';
  }

  ItemType _itemTypeFromDb(String? value) {
    return switch (value) {
      'recipe' => ItemType.recipe,
      'film' => ItemType.film,
      'place' => ItemType.place,
      'article' => ItemType.article,
      'product' => ItemType.product,
      'video' => ItemType.video,
      'note' => ItemType.note,
      _ => ItemType.unknown,
    };
  }

  String _itemTypeToDb(ItemType value) {
    return switch (value) {
      ItemType.recipe => 'recipe',
      ItemType.film => 'film',
      ItemType.place => 'place',
      ItemType.article => 'article',
      ItemType.product => 'product',
      ItemType.video => 'video',
      ItemType.note => 'note',
      ItemType.unknown => 'unknown',
    };
  }

  SourceType _sourceTypeFromDb(String? value) {
    return switch (value) {
      'link' => SourceType.link,
      'screenshot' => SourceType.screenshot,
      'photo' => SourceType.photo,
      _ => SourceType.text,
    };
  }

  String _sourceTypeToDb(SourceType value) {
    return switch (value) {
      SourceType.link => 'link',
      SourceType.screenshot => 'screenshot',
      SourceType.photo => 'photo',
      SourceType.text => 'text',
    };
  }

  bool _isImageSource(SourceType sourceType) {
    return sourceType == SourceType.photo ||
        sourceType == SourceType.screenshot;
  }

  bool _isImagePath(String content) {
    final lower = content.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic');
  }

  String _contentTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.heic')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  ProcessingStatus _processingStatusFromDb(String? value) {
    return switch (value) {
      'pending' => ProcessingStatus.pending,
      'processing' => ProcessingStatus.processing,
      'needs_clarification' => ProcessingStatus.needsClarification,
      'failed' => ProcessingStatus.failed,
      _ => ProcessingStatus.ready,
    };
  }
}
