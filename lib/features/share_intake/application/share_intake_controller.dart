import 'dart:async';

import 'package:dualio/features/items/application/semantic_items_controller.dart';
import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final shareIntakeControllerProvider = Provider<ShareIntakeController>((ref) {
  return ShareIntakeController(ref);
});

class ShareIntakeController {
  const ShareIntakeController(this._ref);

  final Ref _ref;

  Future<void> handleInitialShare() async {
    final media = await ReceiveSharingIntent.instance.getInitialMedia();
    if (media.isEmpty) {
      return;
    }

    _handleMedia(media);
    await ReceiveSharingIntent.instance.reset();
  }

  StreamSubscription<List<SharedMediaFile>> listen() {
    return ReceiveSharingIntent.instance.getMediaStream().listen(_handleMedia);
  }

  void _handleMedia(List<SharedMediaFile> media) {
    for (final file in media) {
      final content = file.message?.trim().isNotEmpty == true ? file.message!.trim() : file.path.trim();
      if (content.isEmpty) {
        continue;
      }

      _ref.read(semanticItemsProvider.notifier).addPendingText(
            content: content,
            sourceType: _sourceTypeFor(file),
          );
    }
  }

  SourceType _sourceTypeFor(SharedMediaFile file) {
    return switch (file.type) {
      SharedMediaType.url => SourceType.link,
      SharedMediaType.text => _looksLikeUrl(file.path) ? SourceType.link : SourceType.text,
      SharedMediaType.image => SourceType.screenshot,
      SharedMediaType.video => SourceType.link,
      SharedMediaType.file => SourceType.photo,
    };
  }

  bool _looksLikeUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }
}
