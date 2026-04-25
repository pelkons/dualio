import 'dart:io';

import 'package:dualio/core/supabase/supabase_bootstrap.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:dualio/features/items/data/local_image_optimizer.dart';
import 'package:dualio/features/search/presentation/search_models.dart';
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
    final clientCaptureKey = await _clientCaptureKeyFor(normalized, sourceType);
    final duplicateRow = await _findRecentDuplicateInput(
      sourceType: sourceType,
      clientCaptureKey: clientCaptureKey,
    );
    if (duplicateRow != null) {
      return _itemFromRow(duplicateRow);
    }

    final shouldProcess =
        sourceType == SourceType.link ||
        sourceType == SourceType.text ||
        _isImageSource(sourceType);
    final processingStatus = shouldProcess ? 'pending' : 'ready';
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
            'clientCaptureKey': clientCaptureKey,
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

    if (sourceType == SourceType.link || sourceType == SourceType.text) {
      final processed = await _invokeProcessItem(row['id']! as String);
      if (!processed) {
        row = await _markProcessingFailed(row['id']! as String);
      } else {
        row = await _fetchItemRow(row['id']! as String) ?? row;
      }
    } else if (localImagePath != null) {
      row = await _uploadImageAsset(
        row: row,
        localImagePath: localImagePath,
        sourceType: sourceType,
      );
      final processed = await _invokeProcessItem(row['id']! as String);
      if (!processed) {
        row = await _markProcessingFailed(row['id']! as String);
      } else {
        row = await _fetchItemRow(row['id']! as String) ?? row;
      }
    }

    return _itemFromRow(row);
  }

  Future<List<SemanticSearchResult>> searchItems({
    required String query,
    required String locale,
    int limit = 20,
  }) async {
    final user = _client.auth.currentUser;
    final normalized = query.trim();
    if (user == null || normalized.isEmpty) {
      return <SemanticSearchResult>[];
    }

    final response = await _client.functions.invoke(
      'search',
      body: <String, Object?>{
        'query': normalized,
        'locale': locale,
        'limit': limit,
        'debug': true,
      },
    );
    final payload = response.data;
    if (payload is! Map) {
      return <SemanticSearchResult>[];
    }
    final results = payload['results'];
    if (results is! List) {
      return <SemanticSearchResult>[];
    }

    return results
        .whereType<Map<Object?, Object?>>()
        .map((entry) {
          final itemRow = entry['item'];
          if (itemRow is! Map) {
            return null;
          }
          return SemanticSearchResult(
            item: _itemFromRow(Map<String, Object?>.from(itemRow)),
            score: (entry['score'] as num?)?.toDouble() ?? 0,
            matchReason: (entry['match_reason'] as String?) ?? '',
          );
        })
        .nonNulls
        .toList(growable: false);
  }

  Future<String> _clientCaptureKeyFor(
    String content,
    SourceType sourceType,
  ) async {
    final source = _sourceTypeToDb(sourceType);
    if (_isImageSource(sourceType)) {
      final file = File(content);
      if (await file.exists()) {
        final fileLength = await file.length();
        final hash = await _fnv1a32File(file);
        return '$source:image:$fileLength:$hash';
      }
    }
    if (sourceType == SourceType.link) {
      return '$source:${_dedupeUrlKey(content)}';
    }
    return '$source:${_dedupeTextKey(content)}';
  }

  Future<Map<String, Object?>?> _findRecentDuplicateInput({
    required SourceType sourceType,
    required String clientCaptureKey,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || clientCaptureKey.isEmpty) {
      return null;
    }

    final createdAfter = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 5))
        .toIso8601String();
    try {
      return await _client
          .from('items')
          .select()
          .eq('user_id', user.id)
          .eq('source_type', _sourceTypeToDb(sourceType))
          .filter('raw_content->>clientCaptureKey', 'eq', clientCaptureKey)
          .gte('created_at', createdAfter)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } on Object {
      return null;
    }
  }

  Future<Map<String, Object?>?> _fetchItemRow(String itemId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    return await _client
        .from('items')
        .select()
        .eq('id', itemId)
        .eq('user_id', user.id)
        .maybeSingle();
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
      final optimizedImage = await const LocalImageOptimizer()
          .optimizeForUpload(path: localImagePath, sourceType: sourceType);
      if (optimizedImage == null) {
        return row;
      }
      if (optimizedImage.byteSize > LocalImageOptimizer.defaultMaxUploadBytes) {
        return _markAssetUploadFailed(
          row,
          itemId,
          'image_too_large_after_optimization',
        );
      }

      final filename = optimizedImage.uploadFilename;
      final contentType = optimizedImage.contentType;
      final response = await _client.functions.invoke(
        'create-asset-upload',
        body: <String, Object?>{
          'item_id': itemId,
          'filename': filename,
          'content_type': contentType,
          'byte_size': optimizedImage.byteSize,
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

      final bytes = await optimizedImage.file.readAsBytes();
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
        'original_filename': optimizedImage.originalFilename,
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
          'originalFilename': optimizedImage.originalFilename,
          'originalByteSize': optimizedImage.originalByteSize,
          'optimized': optimizedImage.wasOptimized,
          if (optimizedImage.width != null) 'width': optimizedImage.width,
          if (optimizedImage.height != null) 'height': optimizedImage.height,
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

  Future<SemanticItem?> updateGeneratedContent(
    SemanticItem item, {
    required String title,
    required Map<String, Object?> parsedContentPatch,
    required String searchableSummary,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || item.id.startsWith('local-')) {
      return null;
    }

    final normalizedTitle = title.trim().isEmpty ? item.title : title.trim();
    final normalizedSummary = searchableSummary.trim().isEmpty
        ? item.searchableSummary
        : searchableSummary.trim();
    final parsedContent = <String, Object?>{
      ...item.parsedContent,
      ...parsedContentPatch,
      'userEditedGeneratedContent': true,
      'generatedContentEditedAt': DateTime.now().toUtc().toIso8601String(),
    };
    final aliases = <String>{
      ...item.searchableAliases,
      ..._aliasesFromContent('$normalizedTitle $normalizedSummary'),
    }.take(32).toList(growable: false);

    final row = await _client
        .from('items')
        .update(<String, Object?>{
          'title': normalizedTitle,
          'parsed_content': parsedContent,
          'searchable_summary': normalizedSummary,
          'searchable_aliases': aliases,
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
          'clarification_question': 'Could not process this item.',
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

    await _client.functions.invoke(
      'delete-item',
      body: <String, Object?>{'item_id': itemId},
    );
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

  Future<String> _fnv1a32File(File file) async {
    var hash = 0x811c9dc5;
    await for (final chunk in file.openRead()) {
      for (final byte in chunk) {
        hash ^= byte;
        hash = (hash * 0x01000193) & 0xffffffff;
      }
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _dedupeUrlKey(String content) {
    final uri = Uri.tryParse(content.trim());
    if (uri == null || uri.host.isEmpty) {
      return _dedupeTextKey(content);
    }

    var host = uri.host.toLowerCase();
    for (final prefix in const <String>['www.', 'm.', 'mobile.', 'amp.']) {
      if (host.startsWith(prefix)) {
        host = host.substring(prefix.length);
        break;
      }
    }

    var path = uri.path;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    final query = uri.query.isEmpty ? '' : '?${uri.query}';
    return '$host$path$query'.toLowerCase();
  }

  String _dedupeTextKey(String content) {
    return content.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
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
      'manual' => ItemType.manual,
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
      ItemType.manual => 'manual',
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
