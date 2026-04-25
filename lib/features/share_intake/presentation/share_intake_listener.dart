import 'dart:async';

import 'package:dualio/features/share_intake/application/share_intake_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShareIntakeListener extends ConsumerStatefulWidget {
  const ShareIntakeListener({
    required this.child,
    required this.onDraft,
    super.key,
  });

  final Widget child;
  final ValueChanged<ShareDraft> onDraft;

  @override
  ConsumerState<ShareIntakeListener> createState() =>
      _ShareIntakeListenerState();
}

class _ShareIntakeListenerState extends ConsumerState<ShareIntakeListener> {
  StreamSubscription<Object?>? _subscription;
  String? _lastDraftKey;
  DateTime? _lastDraftAt;
  static const _duplicateWindow = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final controller = ref.read(shareIntakeControllerProvider);
      unawaited(_openInitialDraft(controller));
      _subscription = controller.listen(_openDraft);
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Future<void> _openInitialDraft(ShareIntakeController controller) async {
    final draft = await controller.handleInitialShare();
    if (draft != null) {
      _openDraft(draft);
    }
  }

  void _openDraft(ShareDraft draft) {
    if (!mounted) {
      return;
    }

    // Guard against the share intent plugin replaying the same media via both
    // getInitialMedia() and getMediaStream() — a known issue that doubles
    // capture events on cold start.
    final key = '${draft.sourceType.name}:${draft.content}';
    final now = DateTime.now();
    if (_lastDraftKey == key &&
        _lastDraftAt != null &&
        now.difference(_lastDraftAt!) < _duplicateWindow) {
      return;
    }
    _lastDraftKey = key;
    _lastDraftAt = now;

    widget.onDraft(draft);
  }
}
