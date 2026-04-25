import 'package:dualio/features/items/domain/semantic_item.dart';
import 'package:dualio/features/share_intake/application/share_intake_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  test(
    'shared text with URL becomes link draft with first clean URL',
    () async {
      ReceiveSharingIntent.setMockValues(
        initialMedia: <SharedMediaFile>[
          SharedMediaFile(
            path: 'Read this: https://example.com/article/123). Thanks',
            type: SharedMediaType.text,
          ),
        ],
        mediaStream: const Stream<List<SharedMediaFile>>.empty(),
      );

      final draft = await const ShareIntakeController().handleInitialShare();

      expect(draft?.sourceType, SourceType.link);
      expect(draft?.content, 'https://example.com/article/123');
    },
  );

  test('shared text without URL remains text draft', () async {
    ReceiveSharingIntent.setMockValues(
      initialMedia: <SharedMediaFile>[
        SharedMediaFile(
          path: 'Remember to compare these two jackets later',
          type: SharedMediaType.text,
        ),
      ],
      mediaStream: const Stream<List<SharedMediaFile>>.empty(),
    );

    final draft = await const ShareIntakeController().handleInitialShare();

    expect(draft?.sourceType, SourceType.text);
    expect(draft?.content, 'Remember to compare these two jackets later');
  });
}
