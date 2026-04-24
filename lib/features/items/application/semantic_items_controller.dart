import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:dualio/mock/mock_semantic_items.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final semanticItemsProvider = NotifierProvider<SemanticItemsController, List<SemanticItem>>(SemanticItemsController.new);

class SemanticItemsController extends Notifier<List<SemanticItem>> {
  @override
  List<SemanticItem> build() {
    return mockSemanticItems;
  }

  void addPendingText({
    required String content,
    required SourceType sourceType,
  }) {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      return;
    }

    final item = SemanticItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      type: _inferLocalType(normalized),
      sourceType: sourceType,
      title: _titleFromContent(normalized),
      sourceUrl: sourceType == SourceType.link ? normalized : null,
      language: 'en',
      searchableSummary: normalized,
      searchableAliases: _aliasesFromContent(normalized),
      parsedContent: <String, Object?>{
        'rawText': normalized,
        'createdLocally': true,
      },
      processingStatus: ProcessingStatus.pending,
      createdLabel: 'Just now',
    );

    state = <SemanticItem>[item, ...state];
  }

  ItemType _inferLocalType(String content) {
    final lower = content.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return ItemType.unknown;
    }
    return ItemType.note;
  }

  String _titleFromContent(String content) {
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
}
