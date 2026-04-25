import 'package:freezed_annotation/freezed_annotation.dart';

part 'semantic_item.freezed.dart';
part 'semantic_item.g.dart';

enum ItemType {
  recipe,
  film,
  place,
  article,
  product,
  video,
  manual,
  note,
  unknown,
}

enum SourceType { link, screenshot, photo, text }

enum ProcessingStatus { pending, processing, ready, needsClarification, failed }

@freezed
abstract class SemanticItem with _$SemanticItem {
  const factory SemanticItem({
    required String id,
    required ItemType type,
    required SourceType sourceType,
    required String title,
    required String createdLabel,
    required String searchableSummary,
    required Map<String, Object?> parsedContent,
    String? sourceUrl,
    String? thumbnailUrl,
    @Default('en') String language,
    @Default(<String>[]) List<String> searchableAliases,
    @Default(ProcessingStatus.ready) ProcessingStatus processingStatus,
    String? clarificationQuestion,
  }) = _SemanticItem;

  factory SemanticItem.fromJson(Map<String, Object?> json) =>
      _$SemanticItemFromJson(json);
}

extension SemanticItemClassification on SemanticItem {
  bool get usesGenericLinkPresentation =>
      parsedContent['kind'] == 'link_preview' &&
      (type == ItemType.article || type == ItemType.unknown);

  bool get usesImageAnalysisPresentation =>
      parsedContent['kind'] == 'image_analysis' &&
      (sourceType == SourceType.photo || sourceType == SourceType.screenshot) &&
      (type == ItemType.unknown || type == ItemType.note);

  bool get usesActionStepsPresentation {
    final steps = parsedContent['steps'];
    return type != ItemType.recipe &&
        type != ItemType.manual &&
        steps is List<Object?> &&
        steps.isNotEmpty;
  }
}
