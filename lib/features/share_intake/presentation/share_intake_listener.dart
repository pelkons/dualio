import 'dart:async';

import 'package:dualio/features/share_intake/application/share_intake_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShareIntakeListener extends ConsumerStatefulWidget {
  const ShareIntakeListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<ShareIntakeListener> createState() => _ShareIntakeListenerState();
}

class _ShareIntakeListenerState extends ConsumerState<ShareIntakeListener> {
  StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(shareIntakeControllerProvider);
      unawaited(controller.handleInitialShare());
      _subscription = controller.listen();
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
}
