import 'dart:async';

import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final pendingShareDraftProvider = StateProvider<ShareDraft?>((ref) => null);

final shareIntakeControllerProvider = Provider<ShareIntakeController>((ref) {
  return const ShareIntakeController();
});

class ShareDraft {
  const ShareDraft({required this.content, required this.sourceType});

  final String content;
  final SourceType sourceType;
}

class ShareIntakeController {
  const ShareIntakeController();

  Future<ShareDraft?> handleInitialShare() async {
    final media = await ReceiveSharingIntent.instance.getInitialMedia();
    if (media.isEmpty) {
      return null;
    }

    final draft = _draftFromMedia(media);
    await ReceiveSharingIntent.instance.reset();
    return draft;
  }

  StreamSubscription<List<SharedMediaFile>> listen(
    void Function(ShareDraft draft) onDraft,
  ) {
    return ReceiveSharingIntent.instance.getMediaStream().listen((media) {
      final draft = _draftFromMedia(media);
      if (draft != null) {
        onDraft(draft);
      }
    });
  }

  ShareDraft? _draftFromMedia(List<SharedMediaFile> media) {
    for (final file in media) {
      final content = file.message?.trim().isNotEmpty == true
          ? file.message!.trim()
          : file.path.trim();
      if (content.isEmpty) {
        continue;
      }

      return ShareDraft(
        content: content,
        sourceType: _sourceTypeFor(file, content),
      );
    }
    return null;
  }

  SourceType _sourceTypeFor(SharedMediaFile file, String content) {
    return switch (file.type) {
      SharedMediaType.url => SourceType.link,
      SharedMediaType.text =>
        _looksLikeUrl(content) ? SourceType.link : SourceType.text,
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
